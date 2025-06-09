# Third-Party MCP Servers

This directory contains external MCP servers that should not be committed to the repository.

## Installation Instructions

### GitHub MCP Server
```bash
cd /Users/j/Code/athena/projects/third-party/
git clone https://github.com/anthropics/mcp-server-github.git github-mcp-server
cd github-mcp-server
go build -o cmd/github-mcp-server/main cmd/github-mcp-server/main.go
```

### Docker MCP Server  
```bash
cd /Users/j/Code/athena/projects/third-party/
git clone https://github.com/anthropics/mcp-server-docker.git docker-mcp
cd docker-mcp
uv sync
```

### Neo4j MCP Server
```bash
cd /Users/j/Code/athena/projects/third-party/
git clone https://github.com/neo4j-contrib/mcp-neo4j.git mcp-neo4j
cd mcp-neo4j/servers/mcp-neo4j-cypher
uv sync
```

## Configuration

Update paths in `/Users/j/Code/athena/dev-tools/mcp_settings.json` after installation.

These servers are gitignored to keep external dependencies separate from Athena code.