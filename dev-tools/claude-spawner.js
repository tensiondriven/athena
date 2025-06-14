#!/usr/bin/env node
/**
 * Claude Spawner MCP Server
 * Allows spawning Claude instances for multi-agent problem solving
 * Pure Node.js - no external dependencies needed
 */

const { spawn } = require('child_process');
const readline = require('readline');

class ClaudeSpawnerMCP {
    constructor() {
        this.name = "claude-spawner";
        this.version = "1.0.0";
        
        // Safety limits
        this.maxSpawnDepth = parseInt(process.env.CLAUDE_MAX_SPAWN_DEPTH || "2");
        this.maxConcurrentSpawns = parseInt(process.env.CLAUDE_MAX_CONCURRENT || "3");
        this.maxTTLMinutes = parseInt(process.env.CLAUDE_MAX_TTL_MINUTES || "5");
        
        // Tracking
        this.activeSpawns = new Map();
        
        console.error(`Claude Spawner MCP starting - Max depth: ${this.maxSpawnDepth}, Max concurrent: ${this.maxConcurrentSpawns}`);
    }
    
    checkSafetyLimits() {
        const now = Date.now();
        
        // Clean up expired spawns
        for (const [spawnId, startTime] of this.activeSpawns.entries()) {
            if (now - startTime > (this.maxTTLMinutes * 60 * 1000)) {
                this.activeSpawns.delete(spawnId);
                console.error(`Spawn ${spawnId} expired after ${this.maxTTLMinutes} minutes`);
            }
        }
        
        // Check concurrent limit
        if (this.activeSpawns.size >= this.maxConcurrentSpawns) {
            return `Maximum concurrent spawns (${this.maxConcurrentSpawns}) reached. Active: ${Array.from(this.activeSpawns.keys()).join(', ')}`;
        }
        
        // Check depth limit
        const currentDepth = parseInt(process.env.CLAUDE_SPAWN_DEPTH || "0");
        if (currentDepth >= this.maxSpawnDepth) {
            return `Maximum spawn depth (${this.maxSpawnDepth}) reached. Current depth: ${currentDepth}`;
        }
        
        return null;
    }
    
    registerSpawn(spawnId) {
        this.activeSpawns.set(spawnId, Date.now());
        console.error(`Registered spawn ${spawnId}. Active spawns: ${this.activeSpawns.size}`);
    }
    
    unregisterSpawn(spawnId) {
        if (this.activeSpawns.has(spawnId)) {
            this.activeSpawns.delete(spawnId);
            console.error(`Unregistered spawn ${spawnId}. Active spawns: ${this.activeSpawns.size}`);
        }
    }
    
    async handleRequest(request) {
        try {
            const { method, params = {} } = request;
            
            switch (method) {
                case "initialize":
                    return this.initialize(params);
                case "tools/list":
                    return this.listTools();
                case "tools/call":
                    return this.callTool(params);
                default:
                    return {
                        error: {
                            code: -32601,
                            message: `Method not found: ${method}`
                        }
                    };
            }
        } catch (error) {
            console.error(`Error handling request: ${error.message}`);
            return {
                error: {
                    code: -32603,
                    message: `Internal error: ${error.message}`
                }
            };
        }
    }
    
    initialize(params) {
        return {
            protocolVersion: "2024-11-05",
            capabilities: {
                tools: {}
            },
            serverInfo: {
                name: this.name,
                version: this.version
            }
        };
    }
    
    listTools() {
        return {
            tools: [
                {
                    name: "spawn_claude",
                    description: "Spawn a Claude instance with a specific prompt to solve a problem",
                    inputSchema: {
                        type: "object",
                        properties: {
                            prompt: {
                                type: "string",
                                description: "The prompt/problem to give to the spawned Claude instance"
                            },
                            timeout: {
                                type: "number",
                                description: "Timeout in seconds (default: 120)",
                                default: 120
                            }
                        },
                        required: ["prompt"]
                    }
                },
                {
                    name: "spawn_status",
                    description: "Check status of the spawning system and active spawns",
                    inputSchema: {
                        type: "object",
                        properties: {}
                    }
                }
            ]
        };
    }
    
    async callTool(params) {
        const { name: toolName, arguments: args = {} } = params;
        
        switch (toolName) {
            case "spawn_claude":
                return this.spawnClaude(args);
            case "spawn_status":
                return this.spawnStatus(args);
            default:
                return {
                    error: {
                        code: -32602,
                        message: `Unknown tool: ${toolName}`
                    }
                };
        }
    }
    
    spawnStatus(args) {
        const currentDepth = process.env.CLAUDE_SPAWN_DEPTH || "0";
        const activeSpawnIds = Array.from(this.activeSpawns.keys());
        
        return {
            content: [
                {
                    type: "text",
                    text: `Spawning System Status:
- Active spawns: ${this.activeSpawns.size}
- Max concurrent: ${this.maxConcurrentSpawns}
- Max depth: ${this.maxSpawnDepth}
- Max TTL: ${this.maxTTLMinutes} minutes
- Current depth: ${currentDepth}

Active spawn IDs: ${activeSpawnIds.join(', ') || 'none'}`
                }
            ]
        };
    }
    
    async spawnClaude(args) {
        // Check safety limits first
        const safetyError = this.checkSafetyLimits();
        if (safetyError) {
            return {
                content: [
                    {
                        type: "text",
                        text: `SPAWN BLOCKED: ${safetyError}`
                    }
                ]
            };
        }
        
        const { prompt, timeout = 120 } = args;
        
        // Generate spawn ID and register it
        const spawnId = `claude_${Date.now()}`;
        this.registerSpawn(spawnId);
        
        try {
            const currentDepth = parseInt(process.env.CLAUDE_SPAWN_DEPTH || "0");
            
            // Set up environment for spawned process
            const spawnEnv = {
                ...process.env,
                CLAUDE_SPAWN_DEPTH: String(currentDepth + 1),
                CLAUDE_SPAWN_ID: spawnId,
                CLAUDE_SPAWN_TTL: String(Math.floor(Date.now() / 1000) + (this.maxTTLMinutes * 60))
            };
            
            console.error(`Spawning Claude ${spawnId} at depth ${currentDepth + 1}`);
            
            return new Promise((resolve) => {
                const claude = spawn('claude', ['-p', prompt], {
                    env: spawnEnv,
                    stdio: ['pipe', 'pipe', 'pipe']
                });
                
                let stdout = '';
                let stderr = '';
                
                claude.stdout.on('data', (data) => {
                    stdout += data.toString();
                });
                
                claude.stderr.on('data', (data) => {
                    stderr += data.toString();
                });
                
                const timeoutId = setTimeout(() => {
                    claude.kill('SIGTERM');
                    this.unregisterSpawn(spawnId);
                    resolve({
                        content: [
                            {
                                type: "text",
                                text: `Claude spawn ${spawnId} timed out after ${timeout} seconds`
                            }
                        ]
                    });
                }, timeout * 1000);
                
                claude.on('close', (code) => {
                    clearTimeout(timeoutId);
                    this.unregisterSpawn(spawnId);
                    
                    resolve({
                        content: [
                            {
                                type: "text",
                                text: `Claude Spawn ${spawnId} Completed
Depth: ${currentDepth + 1}
Exit Code: ${code}

=== OUTPUT ===
${stdout}

=== STDERR ===
${stderr}`
                            }
                        ]
                    });
                });
                
                claude.on('error', (error) => {
                    clearTimeout(timeoutId);
                    this.unregisterSpawn(spawnId);
                    resolve({
                        content: [
                            {
                                type: "text",
                                text: `Error spawning Claude ${spawnId}: ${error.message}`
                            }
                        ]
                    });
                });
            });
            
        } catch (error) {
            this.unregisterSpawn(spawnId);
            console.error(`Error spawning Claude: ${error.message}`);
            return {
                content: [
                    {
                        type: "text",
                        text: `Error spawning Claude ${spawnId}: ${error.message}`
                    }
                ]
            };
        }
    }
}

// Main execution
async function main() {
    const server = new ClaudeSpawnerMCP();
    
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
        terminal: false
    });
    
    for await (const line of rl) {
        try {
            const request = JSON.parse(line);
            const response = await server.handleRequest(request);
            
            // Add request ID if present
            if (request.id !== undefined) {
                response.id = request.id;
            }
            
            console.log(JSON.stringify(response));
        } catch (error) {
            // Skip invalid JSON
            continue;
        }
    }
}

if (require.main === module) {
    main().catch(console.error);
}