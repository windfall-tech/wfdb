#!/bin/bash
# quick-start.sh - Get started building your custom Linux distro in 30 seconds

echo "   🐧 Windfall Distro Builder - Quick Start"
echo "==============================================="
echo

# Check if we're on Linux/WSL
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "⚠️  This needs to run on Linux or WSL2"
    echo "   On Windows: Enable WSL2 and run from Ubuntu/Debian"
    echo
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required"
    echo "   Install with: sudo apt install python3"
    exit 1
fi

# Check if tomli is needed (Python < 3.11)
python3 -c "import tomllib" 2>/dev/null || {
    echo "📦 Installing tomli for TOML support..."
    pip3 install tomli --user
}

echo "✅ Prerequisites OK"
echo

# Copy template
if [[ ! -f "my-distro.toml" ]]; then
    echo "📋 Creating your distro config: my-distro.toml"
    cp distro-template.toml my-distro.toml
    echo "   Edit my-distro.toml to customize your distro"
else
    echo "📋 Using existing my-distro.toml"
fi

echo
echo "🚀 Ready to build! Run:"
echo "   ./build-distro.sh my-distro.toml"
echo
echo "📖 Need help? Read: README-SIMPLE.md"
echo
