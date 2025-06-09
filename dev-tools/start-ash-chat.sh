#!/bin/bash

# Start AshChat server with Event resources
cd /Users/j/Code/athena/system/ash-ai/ash_chat

echo "🔧 Compiling AshChat with Event resources..."
mix compile

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful!"
    echo "🚀 Starting AshChat server on port 4000..."
    echo "📡 Event API will be available at:"
    echo "   POST http://localhost:4000/api/events"
    echo "   POST http://localhost:4000/webhook/test (collector endpoint)"
    echo "   GET  http://localhost:4000/api/events/health"
    echo "   GET  http://localhost:4000/api/events/stats"
    echo ""
    
    mix phx.server
else
    echo "❌ Compilation failed!"
    exit 1
fi