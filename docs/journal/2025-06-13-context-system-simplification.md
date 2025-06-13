# Context System Simplification

## The Journey

Started with a complex vision:
- Backend profiles for each agent
- Context presets with drag-and-drop
- Tool-generated context pieces  
- Dynamic context compaction

But then we found clarity through simplification.

## What We're Building Now

Just system prompts with:
- Name
- Content (the actual prompt)
- Backend (which LLM to use)
- CRUD operations

Each agent gets assigned one system prompt. Clean, simple, useful.

## What We Learned

The exploration revealed interesting needs:
- Tools generating context pieces
- Dynamic context management
- Registered/unregistered pieces

But these are solutions looking for problems we haven't hit yet. The immediate need is just: different agents need different prompts and backends.

## The Pattern

This is a familiar pattern in our work:
1. Explore the full vision
2. Find the minimal useful core
3. Build that first
4. Let real use drive complexity

The complex context system might be exactly what we need... later. For now, system prompts are enough.