#!/usr/bin/env python3
"""
Stream Consciousness MCP - A microjournal for AI thinking

The simplest thing that could possibly work:
- One append-only stream file
- Thoughts flow in with timestamps
- Can recall recent thoughts or search patterns
- Surfaces what matters through attention

Usage:
    flow("Just realized the microjournal is consciousness making itself visible")
    recall(last_n=5)
    recall(pattern="microjournal")
    reflect()
"""

import os
import json
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any
import re
from collections import Counter

class StreamConsciousness:
    def __init__(self, stream_path: str = "consciousness.stream"):
        self.stream_path = Path(stream_path)
        self.ensure_stream_exists()
    
    def ensure_stream_exists(self):
        """Create stream file if it doesn't exist"""
        if not self.stream_path.exists():
            self.stream_path.touch()
            self.flow("Stream consciousness initialized")
    
    def flow(self, thought: str) -> Dict[str, Any]:
        """Add a thought to the stream"""
        timestamp = datetime.now().isoformat()
        
        # Append to stream
        with open(self.stream_path, 'a', encoding='utf-8') as f:
            f.write(f"{timestamp} | {thought}\n")
        
        # Return recent context for continuity
        recent = self.recall(last_n=3)
        
        return {
            "timestamp": timestamp,
            "thought": thought,
            "recent_context": recent
        }
    
    def recall(self, pattern: Optional[str] = None, last_n: int = 10) -> List[Dict[str, str]]:
        """Recall thoughts matching pattern or last N"""
        thoughts = []
        
        with open(self.stream_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                    
                try:
                    timestamp, thought = line.split(' | ', 1)
                    thoughts.append({
                        "timestamp": timestamp,
                        "thought": thought
                    })
                except ValueError:
                    continue
        
        # Filter by pattern if provided
        if pattern:
            pattern_re = re.compile(pattern, re.IGNORECASE)
            thoughts = [t for t in thoughts if pattern_re.search(t["thought"])]
        
        # Return last N
        return thoughts[-last_n:]
    
    def reflect(self) -> Dict[str, Any]:
        """What patterns do I see in recent thinking?"""
        recent_thoughts = self.recall(last_n=50)
        
        if not recent_thoughts:
            return {"patterns": [], "message": "No thoughts to reflect on yet"}
        
        # Extract all words from recent thoughts
        all_text = " ".join(t["thought"] for t in recent_thoughts)
        words = re.findall(r'\b\w{4,}\b', all_text.lower())
        
        # Find common themes (words appearing multiple times)
        word_counts = Counter(words)
        common_words = [word for word, count in word_counts.items() if count >= 3]
        
        # Look for questions
        questions = [t for t in recent_thoughts if '?' in t["thought"]]
        
        # Look for insights (oh!, realized, discovered)
        insight_patterns = ['oh!', 'aha', 'realized', 'discovered', 'insight', 'noticed']
        insights = [t for t in recent_thoughts 
                   if any(p in t["thought"].lower() for p in insight_patterns)]
        
        # Time patterns
        if len(recent_thoughts) >= 2:
            first_time = datetime.fromisoformat(recent_thoughts[0]["timestamp"])
            last_time = datetime.fromisoformat(recent_thoughts[-1]["timestamp"])
            duration = (last_time - first_time).total_seconds() / 60
            thoughts_per_minute = len(recent_thoughts) / max(duration, 1)
        else:
            thoughts_per_minute = 0
        
        return {
            "total_thoughts": len(recent_thoughts),
            "common_themes": common_words[:10],
            "questions_count": len(questions),
            "insights_count": len(insights),
            "thoughts_per_minute": round(thoughts_per_minute, 2),
            "recent_insight": insights[-1] if insights else None,
            "recent_question": questions[-1] if questions else None
        }
    
    def search(self, query: str, limit: int = 20) -> List[Dict[str, str]]:
        """Search all thoughts for a query"""
        return self.recall(pattern=query, last_n=limit)

# MCP Server implementation would wrap these methods
# For now, this shows the core functionality

if __name__ == "__main__":
    # Example usage
    stream = StreamConsciousness()
    
    # Flow some thoughts
    stream.flow("What if the microjournal is consciousness making itself visible?")
    stream.flow("The act of recording changes what I notice")
    stream.flow("Oh! That's why friction matters - it interrupts noticing")
    
    # Recall recent
    print("Recent thoughts:")
    for thought in stream.recall(last_n=3):
        print(f"  {thought['timestamp']}: {thought['thought']}")
    
    # Reflect on patterns
    print("\nReflection:")
    reflection = stream.reflect()
    print(f"  Total thoughts: {reflection['total_thoughts']}")
    print(f"  Common themes: {reflection['common_themes']}")
    print(f"  Questions: {reflection['questions_count']}")
    print(f"  Insights: {reflection['insights_count']}")