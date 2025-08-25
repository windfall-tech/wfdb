# Windfall Distro Builder

**Build a complete Linux distribution with one Python script.**

Windfall Distro Builder is the simplest way to build a custom Linux distribution. No shell scripts, no XML/XSLT, no complex configuration - just edit a TOML file and run one Python command.

## 🚀 Ultra Quick Start

### 1. Edit Your Configuration
```bash
# Edit the simple TOML configuration
nano config.toml
```

### 2. Build Your Entire Linux Distro
```bash
python3 build-linux.py
```

### 3. Done!
Your complete Linux distribution is ready to use.

## ✨ What Makes This Different

**Before (Traditional LFS/jhalfs):**
- 500+ shell scripts across multiple directories
- Complex XML/XSLT transformations
- Interactive configuration menus
- Manual dependency management
- Steep learning curve

**After (Windfall Distro Builder):**
- **1 Python script** (build-linux.py)
- **1 TOML config** (config.toml)
- **1 command** to build everything
- **Dead simple**

## 📁 Project Structure

```
windfall-linux/
├── build-linux.py              # 🔥 Single script that does everything
├── config.toml                 # 📝 Your distro configuration
├── LFS/lfs_build.toml          # 📋 Linux From Scratch package definitions
├── examples/                   # 📁 Example configurations
└── docs/                       # 📚 Documentation
```

## 🔧 Configuration

Edit `config.toml` to customize everything:

```toml
[distro]
name = "My Awesome Linux"
version = "1.0"

[build]
directory = "/mnt/build"
parallel_jobs = 4

# Add any packages you want
[[packages]]
name = "nano"
version = "7.2"
url = "https://ftp.gnu.org/gnu/nano/nano-7.2.tar.xz"
commands = [
    "./configure --prefix=/usr",
    "make",
    "make install"
]
```

## 🛠️ Requirements

- **Python 3.11+** (or Python 3.6+ with `pip3 install tomli`)
- **Linux host system** 
- **~15GB disk space**
- **Standard build tools** (gcc, make - automatically checked)

## 📖 How It Works

1. **Loads your TOML config** - Simple, human-readable configuration
2. **Downloads packages** - Automatically fetches source code
3. **Builds LFS base system** - Complete Linux From Scratch foundation
4. **Adds your packages** - Installs your custom software
5. **Creates bootable system** - Ready-to-use Linux distribution

## 🎯 Example Builds

**Minimal Linux:**
```bash
# Use the default config.toml
python3 build-linux.py
```

**Developer Linux:**
```bash
# Copy and edit example
cp examples/developer.toml my-dev-linux.toml
python3 build-linux.py my-dev-linux.toml
```

**Server Linux:**
```bash
# Copy and edit example  
cp examples/server.toml my-server.toml
python3 build-linux.py my-server.toml
```

## 🤝 Contributing

This project simplifies Linux From Scratch into a single Python script. Contributions welcome!

## 📄 License

Dual licensed under the MIT and Apache 2.0 licenses.
