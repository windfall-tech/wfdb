#!/bin/bash
# build-distro.sh - Dead simple custom Linux distro builder
# Usage: ./build-distro.sh [config.toml]

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOML_FILE="${1:-examples/config.toml}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is required but not installed"
    fi
    
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        warning "This should be run on Linux (native or WSL2)"
        warning "Current OS: $OSTYPE"
    fi
    
    if [[ ! -f "$TOML_FILE" ]]; then
        error "TOML config file not found: $TOML_FILE"
    fi
    
    # Check if running as root (needed for some LFS operations)
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root - make sure this is intentional"
    fi
    
    success "Prerequisites OK"
}

# Generate configuration files using pure TOML system
generate_configs() {
    log "Generating TOML-based configuration from $TOML_FILE..."
    
    # All configs are now in TOML format - no XML conversion needed
    log "Using pure TOML configuration system..."
    
    # Generate jhalfs configuration
    if ! python3 tools/toml_to_configuration.py "$TOML_FILE" > configuration; then
        error "Failed to generate jhalfs configuration"
    fi
    
    # Generate custom package scripts
    if ! python3 tools/toml_to_jhalfs.py "$TOML_FILE"; then
        error "Failed to generate custom package scripts"
    fi
    
    # Generate TOML-based build system (replaces XML/XSLT)
    if ! python3 tools/toml_build_system.py "$TOML_FILE"; then
        error "Failed to generate TOML-based build system"
    fi
    
    success "TOML-based configuration generated (XML/XSLT replaced)"
}

# Patch jhalfs to remove interactive prompts
patch_jhalfs() {
    log "Removing interactive prompts from jhalfs..."
    
    # Backup original if not already backed up
    if [[ ! -f jhalfs.original ]]; then
        cp jhalfs jhalfs.original
    fi
    
    # Remove the first interactive prompt (configuration check)
    sed -i '/printf.*Do you want to run jhalfs/,/esac/c\
# Auto-confirm jhalfs run (non-interactive mode)' jhalfs
    
    # Remove the second interactive prompt (settings confirmation)
    sed -i '/echo -n.*Are you happy with these settings/,/fi/c\
# Auto-confirm settings (non-interactive mode)\
echo "Auto-confirming settings in non-interactive mode"' jhalfs
    
    success "Interactive prompts removed"
}

# Restore original jhalfs
restore_jhalfs() {
    if [[ -f jhalfs.original ]]; then
        log "Restoring original jhalfs..."
        mv jhalfs.original jhalfs
        success "Original jhalfs restored"
    fi
}

# Build the distro
build_distro() {
    log "Starting distro build..."
    
    # Show configuration summary
    if [[ -f configuration ]]; then
        echo
        log "Build configuration:"
        grep -E "^(NAME|VERSION|BUILDDIR|JHALFSDIR)" configuration || true
        echo
    fi
    
    # Run jhalfs
    if ! ./jhalfs run; then
        error "jhalfs build failed"
    fi
    
    success "Distro build completed!"
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    restore_jhalfs
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   Windfall Distro Builder                    ║"
    echo "║                     Easy Distro Builder                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_prerequisites
    generate_configs
    patch_jhalfs
    build_distro
    
    echo
    success "🎉 Your custom Linux distro is ready!"
    
    # Show build artifacts
    if [[ -f configuration ]]; then
        BUILDDIR=$(grep "^BUILDDIR=" configuration | cut -d'"' -f2)
        if [[ -n "$BUILDDIR" && -d "$BUILDDIR" ]]; then
            log "Build artifacts are in: $BUILDDIR"
        fi
    fi
}

# Show help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Windfall Distro Builder"
    echo
    echo "Usage: $0 [config.toml]"
    echo
    echo "This script builds a custom Linux distribution using your TOML configuration."
    echo "It automatically removes all interactive prompts and handles the entire build process."
    echo
    echo "Arguments:"
    echo "  config.toml          Path to TOML configuration file (default: examples/config.toml)"
    echo
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo
    echo "Example:"
    echo "  $0                   # Use examples/config.toml"
    echo "  $0 my-distro.toml    # Use custom config"
    echo
    exit 0
fi

# Run main function
main "$@"
