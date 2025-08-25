# Windfall Linux - Custom Distro Builder

**The simplest way to build your own Linux distribution from scratch.**

Windfall Linux is a modern, TOML-based automation tool for building custom Linux distributions. It replaces complex XML/XSLT configurations with simple TOML files and Python scripts.

## 🚀 Quick Start

### 1. Create Your Configuration
```bash
cp examples/config.toml my-distro.toml
# Edit my-distro.toml to customize your distro
```

### 2. Build Your Distro
```bash
./build-distro.sh my-distro.toml
```

### 3. Wait for Your Custom Linux
The build process automatically creates a complete Linux system in your specified directory.

## ✨ Features

- **Pure TOML Configuration**: No more XML/XSLT complexity
- **Dead Simple**: Just edit a TOML file and run one command  
- **Fully Automated**: No interactive prompts or manual steps
- **Package Management**: Built-in support for dpkg, pacman, porg, or custom managers
- **Customizable**: Control every aspect of your Linux distribution

## 📁 Project Structure

```
windfall-linux/
├── build-distro.sh          # Main build script
├── examples/                # Example configurations
├── tools/                   # TOML-based build tools
├── pkgmngt/                 # Package management configs
├── LFS/                     # Linux From Scratch configs
└── docs/                    # Documentation
```

## 🔧 Configuration

Edit your TOML file to customize:

```toml
[meta]
OS_NAME = "MyAwesomeLinux"
OS_VERSION = "1.0"

[general]
BUILDDIR = "/mnt/build_dir"
MAKEFLAGS = "-j4"

[packages]
# Choose your package manager
PKGMNGT = "y"
PKGMNGT_TYPE = "porg"  # or "dpkg", "pacman", etc.
```

## 🛠️ Requirements

- **Python 3.6+** (for TOML processing)
- **Standard build tools** (gcc, make, etc.)
- **~15GB disk space** (for build directory)
- **Linux host system** (for building LFS)

## 📖 Documentation

- **Advanced Docs**: `docs/` directory - Detailed documentation on the original jhalfs system
- **Examples**: `examples/` directory - Sample configurations

## 🎯 What Makes This Different

**Before (Traditional jhalfs):**
- Complex XML configurations
- XSLT transformations
- Interactive configuration menus
- Steep learning curve

**After (Windfall Linux):**
- Simple TOML files
- Pure Python processing
- Fully automated builds
- Dead simple to use

## 🤝 Contributing

This project replaces the legacy XML/XSLT system with modern TOML-based tools. Contributions welcome!

## 📄 License

MIT / Apache 2.0
