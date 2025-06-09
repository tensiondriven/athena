#!/bin/bash
set -e

echo "🔧 Starting AshChat server..."
cd /Users/j/Code/athena/system/ash-ai/ash_chat

echo "📦 Installing dependencies..."
mix deps.get

echo "🏗️ Compiling..."
mix compile

echo "🚀 Starting Phoenix server..."
mix phx.server