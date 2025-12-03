#!/bin/bash

# Test script for local Next.js application

echo "🚀 Testing Next.js Application Locally"
echo "========================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed"
echo ""

# Build application
echo "🔨 Building application..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"
echo ""

# Start server in background
echo "🌐 Starting server..."
npm start &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test health endpoint
echo "🏥 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)

if [[ $HEALTH_RESPONSE == *"healthy"* ]]; then
    echo "✅ Health check passed: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed: $HEALTH_RESPONSE"
    kill $SERVER_PID
    exit 1
fi

# Test main page
echo "📄 Testing main page..."
MAIN_RESPONSE=$(curl -s http://localhost:3000)

if [[ $MAIN_RESPONSE == *"Next.js"* ]]; then
    echo "✅ Main page loaded successfully"
else
    echo "❌ Main page failed"
    kill $SERVER_PID
    exit 1
fi

# Stop server
echo ""
echo "🛑 Stopping server..."
kill $SERVER_PID

echo ""
echo "✅ All tests passed! Application is working correctly."
echo ""

