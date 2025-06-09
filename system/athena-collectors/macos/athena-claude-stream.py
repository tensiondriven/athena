#!/usr/bin/env python3
"""
Athena Claude Stream - Real-time streaming of Claude conversation events
Watches ~/.claude/projects for changes and streams new JSONL entries
"""

import os
import json
import time
import asyncio
from pathlib import Path
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import aiohttp
import logging

# Configuration
CLAUDE_PROJECTS_DIR = Path.home() / ".claude" / "projects"
ATHENA_ENDPOINT = os.getenv("ATHENA_ENDPOINT", "http://localhost:8080/events")
LOG_FILE = Path.home() / "Code" / "athena" / "data" / "claude-logs" / "stream.log"

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class ClaudeEventStreamer:
    def __init__(self):
        self.file_positions = {}  # Track position in each file
        self.session = None
        self.load_positions()
    
    def load_positions(self):
        """Load saved file positions for resuming"""
        position_file = LOG_FILE.parent / "positions.json"
        if position_file.exists():
            try:
                with open(position_file) as f:
                    self.file_positions = json.load(f)
            except Exception as e:
                logger.error(f"Failed to load positions: {e}")
    
    def save_positions(self):
        """Save current file positions"""
        position_file = LOG_FILE.parent / "positions.json"
        try:
            with open(position_file, 'w') as f:
                json.dump(self.file_positions, f)
        except Exception as e:
            logger.error(f"Failed to save positions: {e}")
    
    async def stream_new_lines(self, file_path):
        """Stream new lines from a JSONL file"""
        file_str = str(file_path)
        
        # Get last known position
        last_position = self.file_positions.get(file_str, 0)
        
        try:
            with open(file_path, 'r') as f:
                # Seek to last position
                f.seek(last_position)
                
                # Read new lines
                for line in f:
                    line = line.strip()
                    if line:
                        await self.process_event(line, file_path)
                
                # Update position
                self.file_positions[file_str] = f.tell()
                self.save_positions()
                
        except Exception as e:
            logger.error(f"Error streaming {file_path}: {e}")
    
    async def process_event(self, line, file_path):
        """Process a single JSONL event"""
        try:
            # Parse JSON
            event = json.loads(line)
            
            # Enhance with metadata
            athena_event = {
                "id": event.get("uuid", f"claude-{int(time.time()*1000)}"),
                "type": "claude_conversation",
                "timestamp": event.get("timestamp", datetime.utcnow().isoformat()),
                "source": "athena-claude-stream",
                "data": event,
                "metadata": {
                    "file_path": str(file_path),
                    "project": file_path.parent.name,
                    "event_type": event.get("type", "unknown"),
                    "session_id": event.get("sessionId"),
                    "cwd": event.get("cwd")
                }
            }
            
            # Log the event
            logger.info(f"Streaming event: {event.get('type')} from {file_path.name}")
            
            # Send to Athena
            await self.send_to_athena(athena_event)
            
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in {file_path}: {line[:100]}...")
        except Exception as e:
            logger.error(f"Error processing event: {e}")
    
    async def send_to_athena(self, event):
        """Send event to Athena endpoint"""
        if not self.session:
            self.session = aiohttp.ClientSession()
        
        try:
            async with self.session.post(ATHENA_ENDPOINT, json=event) as resp:
                if resp.status != 200:
                    logger.error(f"Failed to send event: {resp.status}")
        except aiohttp.ClientError as e:
            logger.error(f"Network error sending to Athena: {e}")
    
    async def initial_scan(self):
        """Scan all existing files for new content"""
        logger.info("Starting initial scan of Claude projects...")
        
        for jsonl_file in CLAUDE_PROJECTS_DIR.rglob("*.jsonl"):
            await self.stream_new_lines(jsonl_file)
        
        logger.info("Initial scan complete")
    
    async def close(self):
        """Cleanup"""
        if self.session:
            await self.session.close()


class ClaudeFileHandler(FileSystemEventHandler):
    """Watch for changes to Claude JSONL files"""
    
    def __init__(self, streamer):
        self.streamer = streamer
        self.loop = asyncio.get_event_loop()
    
    def on_modified(self, event):
        if event.is_directory:
            return
        
        path = Path(event.src_path)
        if path.suffix == '.jsonl':
            logger.info(f"Detected change in {path.name}")
            # Schedule streaming in the event loop
            asyncio.run_coroutine_threadsafe(
                self.streamer.stream_new_lines(path),
                self.loop
            )


async def main():
    """Main streaming loop"""
    logger.info("Starting Athena Claude Stream...")
    logger.info(f"Watching: {CLAUDE_PROJECTS_DIR}")
    logger.info(f"Endpoint: {ATHENA_ENDPOINT}")
    
    # Create streamer
    streamer = ClaudeEventStreamer()
    
    # Do initial scan
    await streamer.initial_scan()
    
    # Set up file watcher
    event_handler = ClaudeFileHandler(streamer)
    observer = Observer()
    observer.schedule(event_handler, str(CLAUDE_PROJECTS_DIR), recursive=True)
    observer.start()
    
    logger.info("Real-time streaming active. Press Ctrl+C to stop.")
    
    try:
        # Keep running
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        observer.stop()
        await streamer.close()
    
    observer.join()


if __name__ == "__main__":
    asyncio.run(main())