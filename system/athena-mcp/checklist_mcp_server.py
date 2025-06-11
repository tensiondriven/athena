#!/usr/bin/env python3
"""
Checklist MCP Server - Nested todo list with LLM-friendly TUI interface

Provides hierarchical task management optimized for AI interaction.
"""

import json
import asyncio
from typing import Dict, List, Optional, Any
from datetime import datetime
from dataclasses import dataclass, field
from enum import Enum
import os

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.tools import Tool
from mcp.types import TextContent, ImageContent, Resource, Prompt


class CheckStatus(Enum):
    PENDING = "[ ]"
    IN_PROGRESS = "[~]"
    COMPLETED = "[x]"
    BLOCKED = "[!]"


@dataclass
class CheckItem:
    id: str
    text: str
    status: CheckStatus = CheckStatus.PENDING
    children: List['CheckItem'] = field(default_factory=list)
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    notes: Optional[str] = None
    

class ChecklistManager:
    def __init__(self):
        self.checklists: Dict[str, List[CheckItem]] = {}
        self.current_list: str = "default"
        self.next_id: int = 1
        
    def _generate_id(self) -> str:
        """Generate unique ID for items"""
        id = f"item_{self.next_id}"
        self.next_id += 1
        return id
    
    def _find_item(self, item_id: str, items: List[CheckItem] = None) -> Optional[CheckItem]:
        """Recursively find item by ID"""
        if items is None:
            items = self.checklists.get(self.current_list, [])
            
        for item in items:
            if item.id == item_id:
                return item
            found = self._find_item(item_id, item.children)
            if found:
                return found
        return None
    
    def _render_item(self, item: CheckItem, indent: int = 0) -> str:
        """Render single item with children"""
        lines = []
        prefix = "  " * indent
        status_icon = item.status.value
        
        # Main item line
        line = f"{prefix}{status_icon} {item.id}: {item.text}"
        if item.notes:
            line += f" // {item.notes}"
        lines.append(line)
        
        # Render children
        for child in item.children:
            lines.extend(self._render_item(child, indent + 1).split('\n'))
            
        return '\n'.join(lines)
    
    def create_list(self, name: str) -> str:
        """Create new checklist"""
        self.checklists[name] = []
        self.current_list = name
        return f"Created checklist: {name}"
    
    def switch_list(self, name: str) -> str:
        """Switch to different checklist"""
        if name not in self.checklists:
            return f"Checklist '{name}' not found. Available: {', '.join(self.checklists.keys())}"
        self.current_list = name
        return f"Switched to checklist: {name}"
    
    def add_item(self, text: str, parent_id: Optional[str] = None) -> str:
        """Add new item to checklist"""
        new_item = CheckItem(
            id=self._generate_id(),
            text=text
        )
        
        if parent_id:
            parent = self._find_item(parent_id)
            if not parent:
                return f"Parent item {parent_id} not found"
            parent.children.append(new_item)
            return f"Added '{text}' as child of {parent_id} (ID: {new_item.id})"
        else:
            if self.current_list not in self.checklists:
                self.checklists[self.current_list] = []
            self.checklists[self.current_list].append(new_item)
            return f"Added '{text}' to {self.current_list} (ID: {new_item.id})"
    
    def update_status(self, item_id: str, status: str) -> str:
        """Update item status"""
        item = self._find_item(item_id)
        if not item:
            return f"Item {item_id} not found"
            
        status_map = {
            "pending": CheckStatus.PENDING,
            "in_progress": CheckStatus.IN_PROGRESS,
            "completed": CheckStatus.COMPLETED,
            "blocked": CheckStatus.BLOCKED
        }
        
        if status not in status_map:
            return f"Invalid status. Use: {', '.join(status_map.keys())}"
            
        item.status = status_map[status]
        item.updated_at = datetime.utcnow().isoformat()
        return f"Updated {item_id} to {item.status.value}"
    
    def add_note(self, item_id: str, note: str) -> str:
        """Add note to item"""
        item = self._find_item(item_id)
        if not item:
            return f"Item {item_id} not found"
            
        item.notes = note
        item.updated_at = datetime.utcnow().isoformat()
        return f"Added note to {item_id}"
    
    def view_list(self, list_name: Optional[str] = None) -> str:
        """Render checklist"""
        target_list = list_name or self.current_list
        if target_list not in self.checklists:
            return f"Checklist '{target_list}' not found"
            
        items = self.checklists[target_list]
        if not items:
            return f"Checklist '{target_list}' is empty"
            
        lines = [f"=== {target_list} ==="]
        for item in items:
            lines.append(self._render_item(item))
        
        # Add summary
        total = self._count_items(items)
        completed = self._count_by_status(items, CheckStatus.COMPLETED)
        in_progress = self._count_by_status(items, CheckStatus.IN_PROGRESS)
        blocked = self._count_by_status(items, CheckStatus.BLOCKED)
        
        lines.append(f"\n--- Progress: {completed}/{total} completed, {in_progress} in progress, {blocked} blocked ---")
        
        return '\n'.join(lines)
    
    def list_all(self) -> str:
        """List all checklists with summary"""
        if not self.checklists:
            return "No checklists created yet"
            
        lines = ["=== All Checklists ==="]
        for name, items in self.checklists.items():
            total = self._count_items(items)
            completed = self._count_by_status(items, CheckStatus.COMPLETED)
            current = " (current)" if name == self.current_list else ""
            lines.append(f"- {name}{current}: {completed}/{total} completed")
            
        return '\n'.join(lines)
    
    def _count_items(self, items: List[CheckItem]) -> int:
        """Count total items including children"""
        count = len(items)
        for item in items:
            count += self._count_items(item.children)
        return count
    
    def _count_by_status(self, items: List[CheckItem], status: CheckStatus) -> int:
        """Count items with specific status"""
        count = sum(1 for item in items if item.status == status)
        for item in items:
            count += self._count_by_status(item.children, status)
        return count


# Global manager instance
checklist_manager = ChecklistManager()


# Create MCP server
server = Server("athena-checklist")


@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available checklist tools"""
    return [
        Tool(
            name="checklist_create",
            description="Create a new checklist",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Name of the checklist"}
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="checklist_switch",
            description="Switch to a different checklist",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Name of the checklist to switch to"}
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="checklist_add",
            description="Add item to checklist",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "Item text"},
                    "parent_id": {"type": "string", "description": "Parent item ID for nesting (optional)"}
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="checklist_status",
            description="Update item status",
            inputSchema={
                "type": "object",
                "properties": {
                    "item_id": {"type": "string", "description": "Item ID"},
                    "status": {
                        "type": "string",
                        "enum": ["pending", "in_progress", "completed", "blocked"],
                        "description": "New status"
                    }
                },
                "required": ["item_id", "status"]
            }
        ),
        Tool(
            name="checklist_note",
            description="Add note to item",
            inputSchema={
                "type": "object",
                "properties": {
                    "item_id": {"type": "string", "description": "Item ID"},
                    "note": {"type": "string", "description": "Note text"}
                },
                "required": ["item_id", "note"]
            }
        ),
        Tool(
            name="checklist_view",
            description="View checklist (current or specified)",
            inputSchema={
                "type": "object",
                "properties": {
                    "list_name": {"type": "string", "description": "Checklist name (optional, defaults to current)"}
                }
            }
        ),
        Tool(
            name="checklist_list_all",
            description="List all checklists with summary",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        )
    ]


@server.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
    """Handle tool calls"""
    
    if name == "checklist_create":
        result = checklist_manager.create_list(arguments["name"])
    
    elif name == "checklist_switch":
        result = checklist_manager.switch_list(arguments["name"])
    
    elif name == "checklist_add":
        result = checklist_manager.add_item(
            arguments["text"],
            arguments.get("parent_id")
        )
    
    elif name == "checklist_status":
        result = checklist_manager.update_status(
            arguments["item_id"],
            arguments["status"]
        )
    
    elif name == "checklist_note":
        result = checklist_manager.add_note(
            arguments["item_id"],
            arguments["note"]
        )
    
    elif name == "checklist_view":
        result = checklist_manager.view_list(arguments.get("list_name"))
    
    elif name == "checklist_list_all":
        result = checklist_manager.list_all()
    
    else:
        result = f"Unknown tool: {name}"
    
    return [TextContent(type="text", text=result)]


async def main():
    """Run the server"""
    # Initialize with default checklist
    checklist_manager.create_list("default")
    
    # Run server
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream)


if __name__ == "__main__":
    asyncio.run(main())