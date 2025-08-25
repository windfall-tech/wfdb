#!/bin/bash
# Build script for Windfall Distro Builder in Docker

echo "🐧 Windfall Distro Builder Docker Builder"
echo "=========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Create necessary directories
mkdir -p output sources logs

echo "📦 Building Docker image..."
docker build -t windfall-linux .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo "🚀 Starting Linux build with simple.toml..."
docker run --rm \
    --privileged \
    -v $(pwd)/output:/mnt/lfs \
    -v $(pwd)/sources:/sources \
    -v $(pwd)/logs:/var/log/windfall \
    windfall-linux

if [ $? -eq 0 ]; then
    echo "🎉 Build completed successfully!"
    echo "📁 Your Linux system is in: ./output/"
else
    echo "❌ Build failed. Check logs in: ./logs/"
fi
