# Neo4j Explorer for Athena Events

## Quick Neo4j Browser Queries

### Check if conversation events are flowing in:

```cypher
// Count all nodes
MATCH (n) RETURN count(n) as total_nodes

// Show recent conversation events
MATCH (n:ConversationEvent) 
RETURN n 
ORDER BY n.timestamp DESC 
LIMIT 10

// Event types and counts
MATCH (n) 
RETURN labels(n) as node_type, count(n) as count 
ORDER BY count DESC

// Search for our specific session
MATCH (n) 
WHERE n.session_id CONTAINS "9a25a40a" 
RETURN n
```

### Explore relationships:

```cypher
// Show the graph structure
MATCH (n)-[r]->(m) 
RETURN n, r, m 
LIMIT 50

// Find conversation participants
MATCH (c:ConversationEvent)-[:INVOLVES]->(p:Participant)
RETURN c, p

// Tools used in conversations
MATCH (c:ConversationEvent)-[:USES_TOOL]->(t:Tool)
RETURN c.session_id, collect(t.name) as tools_used
```

### Visual exploration:

```cypher
// Pretty graph of recent activity
MATCH path = (c:ConversationEvent)-[*1..2]-(related)
WHERE c.timestamp > datetime() - duration('PT1H')
RETURN path
LIMIT 25
```

## Neo4j Browser Access

Default Neo4j browser: http://localhost:7474
Default credentials: neo4j/neo4j (or check athena-ingest config)

## Event Dashboard in Terminal

To see real-time event flow in the terminal:

```bash
# Start the conversation monitor
mix run --no-halt

# In another terminal, check dashboard stats
iex -S mix
AthenaCapture.EventDashboard.get_stats()
```

The 🔔 bell will ring in the logs every time an event is captured!