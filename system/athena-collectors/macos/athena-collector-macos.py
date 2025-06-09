#!/usr/bin/env python3
"""
Athena macOS Collector - Native file monitoring client
Monitors Claude Code logs, Chrome bookmarks, desktop/download events
Sends events to claude_collector server via HTTP
"""

import os
import json
import time
import sqlite3
import hashlib
import mimetypes
import uuid
import requests
from datetime import datetime, timezone
from pathlib import Path
from threading import Thread
import subprocess
import base64

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuration
DATA_DIR = Path(os.getenv('ATHENA_DATA_DIR', Path.home() / '.athena-collector'))
DB_PATH = DATA_DIR / 'collector.sqlite'
FILES_DIR = DATA_DIR / 'files'
CONFIG = {
    'claude_code_logs': Path.home() / '.claude-code' / 'logs',
    'chrome_bookmarks': Path.home() / 'Library' / 'Application Support' / 'Google' / 'Chrome' / 'Default' / 'Bookmarks',
    'ingest_folder': Path.home() / 'Downloads' / 'ingest',
    'desktop': Path.home() / 'Desktop',
    'downloads': Path.home() / 'Downloads',
    'athena_code': Path.home() / 'Code' / 'athena',  # Monitor athena development
    'max_file_size': 1024 * 1024,  # 1MB limit
    'screenshot_format': 'png',
    'claude_collector_url': os.getenv('CLAUDE_COLLECTOR_URL', 'http://localhost:4000/webhook/test'),
    'heartbeat_interval': 300  # 5 minutes
}

class EventSender:
    """HTTP client for sending events to claude_collector"""
    
    def __init__(self, endpoint_url):
        self.endpoint_url = endpoint_url
        self.session = requests.Session()
        self.session.timeout = 10
    
    def send_event(self, event_type, source_path, content=None, metadata=None):
        """Send event to claude_collector via HTTP"""
        try:
            event = {
                'id': str(uuid.uuid4()),
                'type': event_type,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'source': 'athena-collector-macos',
                'file_path': str(source_path),
                'content': content or {},
                'metadata': metadata or {}
            }
            
            response = self.session.post(self.endpoint_url, json=event)
            if response.status_code in [200, 201, 202]:
                print(f"✅ Sent event: {event_type} ({source_path})")
                return True
            else:
                print(f"⚠️ Failed to send event: HTTP {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Error sending event: {e}")
            return False

class EventSyncWorker:
    """Background worker to sync local events to claude_collector"""
    
    def __init__(self, db, event_sender, sync_interval=30):
        self.db = db
        self.event_sender = event_sender
        self.sync_interval = sync_interval
        self.running = False
    
    def start(self):
        """Start the background sync worker"""
        self.running = True
        worker_thread = Thread(target=self._sync_loop, daemon=True)
        worker_thread.start()
        print(f"✅ Started event sync worker (every {self.sync_interval}s)")
    
    def stop(self):
        """Stop the background sync worker"""
        self.running = False
    
    def _sync_loop(self):
        """Main sync loop - runs in background thread"""
        while self.running:
            try:
                self._sync_unsent_events()
            except Exception as e:
                print(f"⚠️ Sync error: {e}")
            
            time.sleep(self.sync_interval)
    
    def _sync_unsent_events(self):
        """Send unsent events to claude_collector"""
        unsent_events = self.db.get_unsent_events(limit=20)  # Process in small batches
        
        if not unsent_events:
            return  # Nothing to sync
        
        print(f"📤 Syncing {len(unsent_events)} unsent events...")
        
        for event in unsent_events:
            try:
                # Parse metadata back from JSON
                metadata = json.loads(event['metadata']) if event['metadata'] else {}
                
                # Send event to claude_collector
                # Read file content if it's small enough (10KB limit)
                file_content = None
                file_size = event['file_size'] or 0
                if file_size <= 10240:  # 10KB limit
                    try:
                        stored_path = Path(event['stored_path'])
                        if stored_path.exists():
                            with open(stored_path, 'r', encoding='utf-8', errors='ignore') as f:
                                file_content = f.read()
                    except Exception as e:
                        print(f"⚠️ Could not read file content: {e}")
                
                success = self.event_sender.send_event(
                    event_type=f"system.filesystem.{event['event_type']}",
                    source_path=event['source_path'],
                    content={
                        'file_hash': event['file_hash'],
                        'file_size': file_size,
                        'mime_type': event['mime_type'],
                        'file_content': file_content,
                        'filename': Path(event['source_path']).name,
                        'directory': str(Path(event['source_path']).parent)
                    },
                    metadata=metadata
                )
                
                if success:
                    self.db.mark_event_sent(event['id'])
                else:
                    break  # Stop on first failure to avoid overwhelming server
                    
            except Exception as e:
                print(f"❌ Failed to sync event {event['id']}: {e}")
                break

class CollectorDB:
    """Local SQLite database for event backup and statistics"""
    
    def __init__(self, db_path):
        self.db_path = db_path
        self.init_db()
    
    def init_db(self):
        """Initialize database schema"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS file_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    source_path TEXT NOT NULL,
                    file_hash TEXT,
                    file_size INTEGER,
                    mime_type TEXT,
                    metadata TEXT,
                    stored_path TEXT,
                    sent_to_server BOOLEAN DEFAULT FALSE,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_timestamp ON file_events(timestamp)')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_event_type ON file_events(event_type)')
    
    def insert_event(self, event_type, source_path, file_hash=None, file_size=None, 
                    mime_type=None, metadata=None, stored_path=None, sent_to_server=False):
        """Insert file event into database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                INSERT INTO file_events 
                (timestamp, event_type, source_path, file_hash, file_size, mime_type, metadata, stored_path, sent_to_server)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                datetime.now(timezone.utc).isoformat(),
                event_type,
                str(source_path),
                file_hash,
                file_size,
                mime_type,
                json.dumps(metadata) if metadata else None,
                str(stored_path) if stored_path else None,
                sent_to_server
            ))
    
    def get_unsent_events(self, limit=50):
        """Get events that haven't been sent to server yet"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            return conn.execute('''
                SELECT * FROM file_events 
                WHERE sent_to_server = FALSE 
                ORDER BY timestamp ASC 
                LIMIT ?
            ''', (limit,)).fetchall()
    
    def mark_event_sent(self, event_id):
        """Mark an event as successfully sent to server"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                UPDATE file_events 
                SET sent_to_server = TRUE 
                WHERE id = ?
            ''', (event_id,))

class FileCollector(FileSystemEventHandler):
    """Handles file system events and writes them to local database"""
    
    def __init__(self, db, files_dir):
        self.db = db
        self.files_dir = Path(files_dir)
        self.files_dir.mkdir(parents=True, exist_ok=True)
    
    def should_collect(self, file_path):
        """Determine if file should be collected based on size and type"""
        try:
            if not file_path.is_file():
                return False
            
            size = file_path.stat().st_size
            if size > CONFIG['max_file_size']:
                return False
            
            # Skip common binary files we don't want
            skip_extensions = {'.dylib', '.so', '.exe', '.app', '.dmg', '.pkg'}
            if file_path.suffix.lower() in skip_extensions:
                return False
            
            return True
        except (OSError, PermissionError):
            return False
    
    def store_file(self, source_path):
        """Store file with hash-based name and return metadata"""
        try:
            with open(source_path, 'rb') as f:
                content = f.read()
            
            file_hash = hashlib.sha256(content).hexdigest()
            file_size = len(content)
            mime_type, _ = mimetypes.guess_type(str(source_path))
            
            # Store with hash-based name to avoid duplicates
            stored_name = f"{file_hash}{source_path.suffix}"
            stored_path = self.files_dir / stored_name
            
            if not stored_path.exists():
                with open(stored_path, 'wb') as f:
                    f.write(content)
            
            return {
                'file_hash': file_hash,
                'file_size': file_size,
                'mime_type': mime_type,
                'stored_path': stored_path
            }
        except Exception as e:
            print(f"Error storing file {source_path}: {e}")
            return None
    
    def on_created(self, event):
        if event.is_directory:
            return
        self.handle_file_event('created', Path(event.src_path))
    
    def on_modified(self, event):
        if event.is_directory:
            return
        self.handle_file_event('modified', Path(event.src_path))
    
    def on_moved(self, event):
        if event.is_directory:
            return
        self.handle_file_event('moved', Path(event.dest_path), 
                             metadata={'from': event.src_path})
    
    def handle_file_event(self, event_type, file_path, metadata=None):
        """Process a file system event - write to local DB immediately"""
        if not self.should_collect(file_path):
            return
        
        print(f"Collecting {event_type}: {file_path}")
        
        # Store file and get metadata
        file_info = self.store_file(file_path)
        if not file_info:
            return
        
        # Special handling for specific file types
        if file_path.name.endswith('.jsonl') and 'claude-code' in str(file_path):
            metadata = {**(metadata or {}), 'source_type': 'claude_code_log'}
        elif file_path.name == 'Bookmarks' and 'Chrome' in str(file_path):
            metadata = {**(metadata or {}), 'source_type': 'chrome_bookmarks'}
        
        # Write to local database immediately (fast, reliable)
        self.db.insert_event(
            event_type=event_type,
            source_path=file_path,
            file_hash=file_info['file_hash'],
            file_size=file_info['file_size'],
            mime_type=file_info['mime_type'],
            metadata=metadata,
            stored_path=file_info['stored_path'],
            sent_to_server=False  # Background worker will send later
        )

class ScreenshotService:
    """Handle screenshot capture via screencapture command"""
    
    @staticmethod
    def capture_screenshot():
        """Capture screenshot and return base64 encoded data"""
        try:
            # Use macOS screencapture command
            result = subprocess.run([
                'screencapture', '-t', CONFIG['screenshot_format'], '-'
            ], capture_output=True, check=True)
            
            screenshot_data = base64.b64encode(result.stdout).decode('utf-8')
            
            return {
                'success': True,
                'format': CONFIG['screenshot_format'],
                'data': screenshot_data,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'size': len(result.stdout)
            }
        except subprocess.CalledProcessError as e:
            return {
                'success': False,
                'error': f"Screenshot failed: {e}",
                'timestamp': datetime.now(timezone.utc).isoformat()
            }

# No HTTP routes - this is a client that sends data to claude_collector

def start_file_monitoring():
    """Start file system monitoring and background event syncing"""
    db = CollectorDB(DB_PATH)
    event_sender = EventSender(CONFIG['claude_collector_url'])
    collector = FileCollector(db, FILES_DIR)
    
    # Start background event sync worker
    sync_worker = EventSyncWorker(db, event_sender, sync_interval=30)
    sync_worker.start()
    
    # Log startup event locally (sync worker will send it)
    startup_metadata = {
        'version': '1.0.0',
        'pid': os.getpid(),
        'config': {
            'data_dir': str(DATA_DIR),
            'max_file_size': CONFIG['max_file_size']
        }
    }
    
    db.insert_event(
        event_type='collector_startup',
        source_path='athena-collector-macos',
        metadata=startup_metadata,
        sent_to_server=False  # Sync worker will handle it
    )
    print("✅ Logged collector startup event")
    
    observer = Observer()
    
    # Monitor key directories
    for name, path in CONFIG.items():
        if name.endswith('_logs') or name.endswith('_folder') or name in ['desktop', 'downloads']:
            if isinstance(path, Path) and path.exists():
                print(f"Monitoring: {name} -> {path}")
                observer.schedule(collector, str(path), recursive=True)
    
    # Monitor Chrome bookmarks file specifically
    bookmarks_path = CONFIG['chrome_bookmarks']
    if bookmarks_path.exists():
        print(f"Monitoring Chrome bookmarks: {bookmarks_path.parent}")
        observer.schedule(collector, str(bookmarks_path.parent), recursive=False)
    
    observer.start()
    
    # Start heartbeat thread
    heartbeat_thread = Thread(target=heartbeat_worker, args=(db,), daemon=True)
    heartbeat_thread.start()
    
    return observer

def heartbeat_worker(db):
    """Write periodic heartbeat events to local database"""
    while True:
        time.sleep(CONFIG['heartbeat_interval'])  # Configurable interval
        try:
            db.insert_event(
                event_type='heartbeat',
                source_path='athena-collector-macos',
                metadata={
                    'uptime_minutes': int(time.time() - start_time) // 60,
                    'timestamp': datetime.now(timezone.utc).isoformat()
                },
                sent_to_server=False  # Sync worker will handle it
            )
        except Exception as e:
            print(f"Heartbeat error: {e}")

if __name__ == '__main__':
    import sys
    
    # Record start time for uptime tracking
    start_time = time.time()
    
    # Test mode: run for 5 seconds then exit
    test_mode = '--test' in sys.argv
    
    # Ensure data directories exist
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    FILES_DIR.mkdir(parents=True, exist_ok=True)
    
    print(f"Starting Athena macOS Collector {'(TEST MODE)' if test_mode else ''}")
    print(f"Data directory: {DATA_DIR}")
    print(f"Files directory: {FILES_DIR}")
    print(f"Database: {DB_PATH}")
    print(f"Claude collector URL: {CONFIG['claude_collector_url']}")
    
    # Start file monitoring
    observer = start_file_monitoring()
    
    try:
        if test_mode:
            print("Test mode: Running for 5 seconds...")
            time.sleep(5)
            print("Test complete! Checking for collected events...")
            
            # Show what we collected
            db = CollectorDB(DB_PATH)
            with sqlite3.connect(DB_PATH) as conn:
                conn.row_factory = sqlite3.Row
                events = conn.execute('SELECT * FROM file_events ORDER BY timestamp DESC LIMIT 10').fetchall()
                
                if events:
                    print(f"\n✅ Collected {len(events)} events:")
                    for event in events:
                        sent_status = "✅" if event['sent_to_server'] else "📤"
                        print(f"  {sent_status} {event['event_type']}: {event['source_path']} ({event['file_size']} bytes)")
                        if event['metadata']:
                            metadata = json.loads(event['metadata'])
                            if 'source_type' in metadata:
                                print(f"    -> {metadata['source_type']}")
                else:
                    print("\n⚠️  No events collected during test")
        else:
            # Run as daemon - monitor files and sync events
            print("🔄 Running as daemon... Press Ctrl+C to stop")
            while True:
                time.sleep(1)
    except KeyboardInterrupt:
        print("\n👋 Shutting down gracefully...")
    finally:
        observer.stop()
        observer.join()