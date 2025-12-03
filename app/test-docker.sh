#!/bin/bash

# Test script for Docker image

echo "🐳 Testing Docker Image Locally"
echo "================================="
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop"
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t nextjs-app:test .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Docker image built successfully"
echo ""

# Run container
echo "🚀 Starting container..."
docker run -d -p 3000:3000 --name nextjs-test nextjs-app:test

if [ $? -ne 0 ]; then
    echo "❌ Failed to start container"
    exit 1
fi

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 10

# Test health endpoint
echo "🏥 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)

if [[ $HEALTH_RESPONSE == *"healthy"* ]]; then
    echo "✅ Health check passed: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed: $HEALTH_RESPONSE"
    docker stop nextjs-test
    docker rm nextjs-test
    exit 1
fi

# Test main page
echo "📄 Testing main page..."
MAIN_RESPONSE=$(curl -s http://localhost:3000)

if [[ $MAIN_RESPONSE == *"Next.js"* ]]; then
    echo "✅ Main page loaded successfully"
else
    echo "❌ Main page failed"
    docker stop nextjs-test
    docker rm nextjs-test
    exit 1
fi

# Stop and remove container
echo ""
echo "🛑 Stopping container..."
docker stop nextjs-test
docker rm nextjs-test

echo ""
echo "✅ All Docker tests passed! Image is working correctly."
echo ""

