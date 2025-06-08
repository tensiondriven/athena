#!/usr/bin/env python3
"""
Q&A Integration MCP Server
Interactive question and answer server for integration planning and decision making.

This server provides a structured Q&A interface to help with project integration
decisions, particularly useful for complex technical integrations like PTZ camera
systems.

Usage: Register as MCP server to get interactive Q&A capabilities for integration planning
"""

import asyncio
import json
import logging
import sys
from datetime import datetime
from typing import Any, Dict, List
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class QAServer:
    def __init__(self):
        self.questions = []
        self.session_log = []
        
    async def ask_question(self, question: str, context: str = "", category: str = "general") -> Dict[str, Any]:
        """Ask a question and wait for user response"""
        question_id = len(self.questions) + 1
        timestamp = datetime.now().isoformat()
        
        question_entry = {
            "id": question_id,
            "question": question,
            "context": context,
            "category": category,
            "timestamp": timestamp,
            "status": "pending"
        }
        
        self.questions.append(question_entry)
        
        # Format the question for display
        formatted_question = f"\n{'='*60}\n"
        formatted_question += f"Q&A SERVER - Question #{question_id}\n"
        formatted_question += f"Category: {category.upper()}\n"
        formatted_question += f"{'='*60}\n\n"
        
        if context:
            formatted_question += f"CONTEXT:\n{context}\n\n"
        
        formatted_question += f"QUESTION:\n{question}\n\n"
        formatted_question += f"Please provide your answer/decision:\n"
        formatted_question += f"{'='*60}\n"
        
        return {
            "question_id": question_id,
            "formatted_question": formatted_question,
            "success": True
        }
    
    async def record_answer(self, question_id: int, answer: str) -> Dict[str, Any]:
        """Record an answer to a question"""
        try:
            question = next((q for q in self.questions if q["id"] == question_id), None)
            if not question:
                return {"success": False, "error": f"Question {question_id} not found"}
            
            question["answer"] = answer
            question["answered_at"] = datetime.now().isoformat()
            question["status"] = "answered"
            
            self.session_log.append({
                "action": "answer_recorded",
                "question_id": question_id,
                "timestamp": datetime.now().isoformat()
            })
            
            return {
                "success": True,
                "question_id": question_id,
                "answer": answer
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def get_session_summary(self) -> Dict[str, Any]:
        """Get summary of current Q&A session"""
        answered = [q for q in self.questions if q.get("status") == "answered"]
        pending = [q for q in self.questions if q.get("status") == "pending"]
        
        return {
            "total_questions": len(self.questions),
            "answered": len(answered),
            "pending": len(pending),
            "questions": self.questions,
            "session_log": self.session_log
        }
    
    async def clear_session(self) -> Dict[str, Any]:
        """Clear current Q&A session"""
        cleared_count = len(self.questions)
        self.questions = []
        self.session_log = []
        
        return {
            "success": True,
            "cleared_questions": cleared_count
        }

    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP requests"""
        method = request.get("method")
        
        if method == "tools/list":
            return {
                "tools": [
                    {
                        "name": "ask_question",
                        "description": "Ask a question for user input/decision",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "question": {
                                    "type": "string",
                                    "description": "The question to ask"
                                },
                                "context": {
                                    "type": "string",
                                    "description": "Additional context for the question"
                                },
                                "category": {
                                    "type": "string",
                                    "description": "Question category (integration, design, technical, etc.)"
                                }
                            },
                            "required": ["question"]
                        }
                    },
                    {
                        "name": "record_answer",
                        "description": "Record an answer to a previously asked question",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "question_id": {
                                    "type": "integer",
                                    "description": "The ID of the question being answered"
                                },
                                "answer": {
                                    "type": "string",
                                    "description": "The answer/response to the question"
                                }
                            },
                            "required": ["question_id", "answer"]
                        }
                    },
                    {
                        "name": "get_session_summary",
                        "description": "Get summary of current Q&A session",
                        "inputSchema": {
                            "type": "object",
                            "properties": {},
                            "required": []
                        }
                    },
                    {
                        "name": "clear_session",
                        "description": "Clear current Q&A session",
                        "inputSchema": {
                            "type": "object",
                            "properties": {},
                            "required": []
                        }
                    }
                ]
            }
        
        elif method == "tools/call":
            tool_name = request.get("params", {}).get("name")
            arguments = request.get("params", {}).get("arguments", {})
            
            if tool_name == "ask_question":
                result = await self.ask_question(
                    question=arguments.get("question", ""),
                    context=arguments.get("context", ""),
                    category=arguments.get("category", "general")
                )
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": result["formatted_question"]
                        }
                    ]
                }
            
            elif tool_name == "record_answer":
                result = await self.record_answer(
                    question_id=arguments.get("question_id"),
                    answer=arguments.get("answer", "")
                )
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Answer recorded for question {result.get('question_id')}: {result.get('answer', 'Error')}"
                        }
                    ]
                }
            
            elif tool_name == "get_session_summary":
                result = await self.get_session_summary()
                summary_text = f"Q&A Session Summary:\n"
                summary_text += f"Total Questions: {result['total_questions']}\n"
                summary_text += f"Answered: {result['answered']}\n"
                summary_text += f"Pending: {result['pending']}\n\n"
                
                if result['questions']:
                    summary_text += "Questions:\n"
                    for q in result['questions']:
                        summary_text += f"  #{q['id']} [{q['status']}] {q['question'][:50]}...\n"
                
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": summary_text
                        }
                    ]
                }
            
            elif tool_name == "clear_session":
                result = await self.clear_session()
                return {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Session cleared. {result['cleared_questions']} questions removed."
                        }
                    ]
                }
            
            else:
                return {"error": f"Unknown tool: {tool_name}"}
        
        elif method == "initialize":
            return {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                }
            }
        
        else:
            return {"error": f"Unknown method: {method}"}

async def main():
    """Main server loop"""
    server = QAServer()
    
    logger.info("Q&A Integration MCP Server starting...")
    
    while True:
        try:
            line = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
            if not line:
                break
                
            request = json.loads(line.strip())
            response = await server.handle_request(request)
            
            print(json.dumps(response))
            sys.stdout.flush()
            
        except json.JSONDecodeError:
            print(json.dumps({"error": "Invalid JSON"}))
            sys.stdout.flush()
        except Exception as e:
            logger.error(f"Server error: {e}")
            print(json.dumps({"error": str(e)}))
            sys.stdout.flush()

if __name__ == "__main__":
    asyncio.run(main())