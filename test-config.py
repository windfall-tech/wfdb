#!/usr/bin/env python3
"""
Quick test script to verify configuration loading in container
"""

import sys
import traceback

try:
    print("🐧 Windfall Linux Configuration Test")
    print("====================================")

    # Try importing tomllib (Python 3.11+) or tomli
    try:
        import tomllib

        print("✅ Using tomllib (Python 3.11+)")
    except ImportError:
        try:
            import tomli as tomllib

            print("✅ Using tomli library")
        except ImportError:
            print("❌ No TOML library available")
            sys.exit(1)

    from pathlib import Path

    # Test configuration loading
    config_file = "examples/simple.toml"
    print(f"📄 Loading {config_file}...")

    with open(config_file, "rb") as f:
        config = tomllib.load(f)

    print("✅ Main config loaded successfully")
    print(f"   Distribution: {config['meta']['name']} {config['meta']['version']}")
    print(f"   Users: {len(config.get('users', {}).get('system', []))}")
    print(f"   Additional packages: {len(config.get('packages', []))}")

    # Test external config loading
    config["build"] = config.get("build", {})
    config["build"].setdefault("toolchain_config", "LFS/toolchain.toml")
    config["build"].setdefault("lfs_config", "LFS/lfs_build.toml")

    base_path = Path(config_file).parent.parent

    # Load toolchain
    toolchain_path = base_path / config["build"]["toolchain_config"]
    print(f"📄 Loading {toolchain_path}...")
    with open(toolchain_path, "rb") as f:
        toolchain_config = tomllib.load(f)

    print(
        f"✅ Toolchain config loaded: {len(toolchain_config.get('packages', []))} packages"
    )

    # Load LFS
    lfs_path = base_path / config["build"]["lfs_config"]
    print(f"📄 Loading {lfs_path}...")
    with open(lfs_path, "rb") as f:
        lfs_config = tomllib.load(f)

    print(f"✅ LFS config loaded: {len(lfs_config.get('lfs_packages', []))} packages")

    print()
    print("🎉 All configurations load successfully!")
    print("✅ Ready to build Linux distribution")

except Exception as e:
    print(f"❌ Error: {e}")
    print()
    print("Stack trace:")
    traceback.print_exc()
    sys.exit(1)
