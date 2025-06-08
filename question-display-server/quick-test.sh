#!/bin/bash

# Quick Manual Test Script for Question Display Server
# This script starts the server and provides instructions for manual testing

echo "🚀 Question Display Server - Manual Test"
echo "========================================"

# Check if server is already running on port 2900
if lsof -i :2900 >/dev/null 2>&1; then
    echo "⚠️  Port 2900 is already in use. Please stop any existing servers first."
    exit 1
fi

echo "📋 Starting server on port 2900..."
node index.js &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Check if server started successfully
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "❌ Server failed to start"
    exit 1
fi

echo "✅ Server is running (PID: $SERVER_PID)"
echo ""
echo "🧪 Manual Testing Instructions:"
echo "==============================="
echo ""
echo "1. Open a new terminal window"
echo ""
echo "2. Test with a true/false question:"
echo "   curl -X POST -H \"Content-Type: application/json\" \\"
echo "        -d '{\"question\":\"Is the sky blue?\",\"options\":[\"True\",\"False\"]}' \\"
echo "        http://localhost:2900/display-question"
echo ""
echo "3. Test with a multiple choice question:"
echo "   curl -X POST -H \"Content-Type: application/json\" \\"
echo "        -d '{\"question\":\"What is 2 + 2?\",\"options\":[\"3\",\"4\",\"5\",\"6\"]}' \\"
echo "        http://localhost:2900/display-question"
echo ""
echo "4. Each curl command should:"
echo "   - Return: 'Question displayed'"
echo "   - Show a dialog box on your screen with the question and options"
echo "   - Print the user's selection in this terminal"
echo ""
echo "5. Test invalid endpoints:"
echo "   curl http://localhost:2900/invalid"
echo "   (Should return: 'Not Found')"
echo ""
echo "💡 Press Ctrl+C to stop the server when done testing"
echo ""

# Keep server running and wait for user to stop it
wait $SERVER_PID 2>/dev/null || echo -e "\n✅ Server stopped"