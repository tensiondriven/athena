#!/usr/bin/env python3
"""
Athena macOS Collector - File monitoring and screenshot service
Monitors Claude Code logs, Chrome bookmarks, desktop/download events
Provides REST API for screenshots and file ingestion
"""

import os
import json
import time
import sqlite3
import hashlib
import mimetypes
from datetime import datetime, timezone
from pathlib import Path
from threading import Thread
import subprocess
import base64

from flask import Flask, jsonify, request
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuration
DATA_DIR = Path(os.getenv('ATHENA_DATA_DIR', '/data'))
DB_PATH = DATA_DIR / 'collector.sqlite'
FILES_DIR = DATA_DIR / 'files'
CONFIG = {
    'claude_code_logs': Path.home() / '.claude-code' / 'logs',
    'chrome_bookmarks': Path.home() / 'Library' / 'Application Support' / 'Google' / 'Chrome' / 'Default' / 'Bookmarks',
    'ingest_folder': Path.home() / 'Downloads' / 'ingest',
    'desktop': Path.home() / 'Desktop',
    'downloads': Path.home() / 'Downloads',
    'max_file_size': 1024 * 1024,  # 1MB limit
    'screenshot_format': 'png',
    'port': int(os.getenv('PORT', 5001))
}

app = Flask(__name__)

class CollectorDB:
    """SQLite database for file metadata and events"""
    
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
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_timestamp ON file_events(timestamp)')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_event_type ON file_events(event_type)')
    
    def insert_event(self, event_type, source_path, file_hash=None, file_size=None, 
                    mime_type=None, metadata=None, stored_path=None):
        """Insert file event into database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                INSERT INTO file_events 
                (timestamp, event_type, source_path, file_hash, file_size, mime_type, metadata, stored_path)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                datetime.now(timezone.utc).isoformat(),
                event_type,
                str(source_path),
                file_hash,
                file_size,
                mime_type,
                json.dumps(metadata) if metadata else None,
                str(stored_path) if stored_path else None
            ))

class FileCollector(FileSystemEventHandler):
    """Handles file system events and stores relevant files"""
    
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
        """Process a file system event"""
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
        
        # Insert into database
        self.db.insert_event(
            event_type=event_type,
            source_path=file_path,
            file_hash=file_info['file_hash'],
            file_size=file_info['file_size'],
            mime_type=file_info['mime_type'],
            metadata=metadata,
            stored_path=file_info['stored_path']
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

# Flask API Routes
@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now(timezone.utc).isoformat()})

@app.route('/screenshot', methods=['GET'])
def screenshot():
    """Capture and return screenshot"""
    return jsonify(ScreenshotService.capture_screenshot())

@app.route('/events')
def events():
    """Get recent file events"""
    limit = request.args.get('limit', 50, type=int)
    event_type = request.args.get('type')
    
    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        
        query = 'SELECT * FROM file_events'
        params = []
        
        if event_type:
            query += ' WHERE event_type = ?'
            params.append(event_type)
        
        query += ' ORDER BY timestamp DESC LIMIT ?'
        params.append(limit)
        
        rows = conn.execute(query, params).fetchall()
        
        events = []
        for row in rows:
            event = dict(row)
            if event['metadata']:
                event['metadata'] = json.loads(event['metadata'])
            events.append(event)
        
        return jsonify({
            'events': events,
            'count': len(events),
            'timestamp': datetime.now(timezone.utc).isoformat()
        })

@app.route('/stats')
def stats():
    """Get collection statistics"""
    with sqlite3.connect(DB_PATH) as conn:
        total_files = conn.execute('SELECT COUNT(*) FROM file_events').fetchone()[0]
        event_types = conn.execute('''
            SELECT event_type, COUNT(*) as count 
            FROM file_events 
            GROUP BY event_type
        ''').fetchall()
        
        return jsonify({
            'total_files': total_files,
            'event_types': dict(event_types),
            'data_dir': str(DATA_DIR),
            'files_dir': str(FILES_DIR),
            'timestamp': datetime.now(timezone.utc).isoformat()
        })

def start_file_monitoring():
    """Start file system monitoring in background thread"""
    db = CollectorDB(DB_PATH)
    collector = FileCollector(db, FILES_DIR)
    
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
    return observer

if __name__ == '__main__':
    # Ensure data directories exist
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    FILES_DIR.mkdir(parents=True, exist_ok=True)
    
    print(f"Starting Athena macOS Collector")
    print(f"Data directory: {DATA_DIR}")
    print(f"Files directory: {FILES_DIR}")
    print(f"Database: {DB_PATH}")
    print(f"API port: {CONFIG['port']}")
    
    # Start file monitoring
    observer = start_file_monitoring()
    
    try:
        # Start Flask API
        app.run(host='0.0.0.0', port=CONFIG['port'], debug=False)
    finally:
        observer.stop()
        observer.join()