#!/usr/bin/env python3
"""
Windfall Linux Builder - Single Script Linux Distro Builder
Dead simple Linux distribution builder from TOML configuration.

Usage: python3 build-linux.py [config.toml]

This script replaces the entire jhalfs/ALFS system with a simple Python approach.
"""

import sys
import os
import subprocess
import shutil
import tempfile
import urllib.request
import hashlib
import tarfile
import zipfile
import gzip
import logging
from pathlib import Path
from typing import Dict, List, Optional
import json

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("ERROR: Python 3.11+ required or install tomli: pip install tomli")
        sys.exit(1)


class LinuxBuilder:
    """Complete Linux distribution builder from TOML configuration"""

    def __init__(self, config_file: Path):
        self.config_file = config_file
        # Initialize basic logging first
        self.setup_basic_logging()
        self.config = self.load_config()
        self.setup_logging()  # Setup final logging with config
        self.setup_directories()

    def load_config(self) -> dict:
        """Load and validate TOML configuration"""
        try:
            with open(self.config_file, "rb") as f:
                config = tomllib.load(f)

            # Set defaults
            config.setdefault("build", {})
            config["build"].setdefault("jobs", os.cpu_count())
            config["build"].setdefault("lfs_dir", "/mnt/lfs")
            config["build"].setdefault("sources_dir", "/sources")
            config["build"].setdefault("tools_dir", "/tools")
            config["build"].setdefault("version", "12.2")
            config["build"].setdefault("toolchain_config", "LFS/toolchain.toml")
            config["build"].setdefault("lfs_config", "LFS/lfs_build.toml")

            config.setdefault("meta", {})
            config["meta"].setdefault("name", "WindfallLinux")
            config["meta"].setdefault("version", "1.0")

            config.setdefault("users", {})
            config["users"].setdefault("lfs_user", "lfs")
            config["users"].setdefault("lfs_group", "lfs")

            # Load external configuration files
            self.load_external_configs(config)

            return config

        except Exception as e:
            print(f"ERROR: Failed to load config {self.config_file}: {e}")
            sys.exit(1)

    def load_external_configs(self, config: dict):
        """Load external TOML configuration files"""
        base_path = Path(self.config_file).parent

        # Load toolchain configuration
        toolchain_path = base_path / config["build"]["toolchain_config"]
        if toolchain_path.exists():
            try:
                with open(toolchain_path, "rb") as f:
                    toolchain_config = tomllib.load(f)
                    config["toolchain_packages"] = toolchain_config.get("packages", [])
                    self.logger.info(
                        f"Loaded {len(config['toolchain_packages'])} toolchain packages"
                    )
            except Exception as e:
                self.logger.warning(f"Failed to load toolchain config: {e}")

        # Load LFS build configuration
        lfs_path = base_path / config["build"]["lfs_config"]
        if lfs_path.exists():
            try:
                with open(lfs_path, "rb") as f:
                    lfs_config = tomllib.load(f)
                    config["lfs_build"] = lfs_config.get("lfs_build", {})
                    config["lfs_packages"] = lfs_config.get("lfs_packages", [])
                    config["chapters"] = lfs_config.get("chapters", [])
                    self.logger.info(
                        f"Loaded LFS build config with {len(config['lfs_packages'])} packages"
                    )
            except Exception as e:
                self.logger.warning(f"Failed to load LFS config: {e}")

    def setup_basic_logging(self):
        """Setup basic logging before config is loaded"""
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s [%(levelname)s] %(message)s",
            datefmt="%H:%M:%S",
        )
        self.logger = logging.getLogger(__name__)

    def setup_logging(self):
        """Setup logging"""
        log_level = logging.DEBUG if self.config.get("debug", False) else logging.INFO
        logging.basicConfig(
            level=log_level,
            format="%(asctime)s [%(levelname)s] %(message)s",
            datefmt="%H:%M:%S",
        )
        self.logger = logging.getLogger(__name__)

    def setup_directories(self):
        """Setup build directories"""
        self.lfs_dir = Path(self.config["build"]["lfs_dir"])
        self.sources_dir = Path(self.config["build"]["sources_dir"])
        self.tools_dir = Path(self.config["build"]["tools_dir"])

        # Create directories
        for dir_path in [self.lfs_dir, self.sources_dir, self.tools_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
            self.logger.info(f"Created directory: {dir_path}")

    def run_command(
        self, command: str, cwd: Optional[Path] = None, env: Optional[dict] = None
    ) -> bool:
        """Execute a shell command safely"""
        try:
            self.logger.debug(f"Running: {command}")
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                env=env or os.environ.copy(),
                capture_output=True,
                text=True,
            )

            if result.returncode != 0:
                self.logger.error(f"Command failed: {command}")
                self.logger.error(f"STDOUT: {result.stdout}")
                self.logger.error(f"STDERR: {result.stderr}")
                return False

            self.logger.debug(f"Command succeeded: {command}")
            return True

        except Exception as e:
            self.logger.error(f"Exception running command {command}: {e}")
            return False

    def download_file(
        self, url: str, dest: Path, expected_hash: Optional[str] = None
    ) -> bool:
        """Download a file with integrity checking"""
        try:
            self.logger.info(f"Downloading {url} to {dest}")

            # Download
            urllib.request.urlretrieve(url, dest)

            # Verify hash if provided
            if expected_hash:
                actual_hash = self.get_file_hash(dest)
                if actual_hash != expected_hash:
                    self.logger.error(
                        f"Hash mismatch for {dest}: expected {expected_hash}, got {actual_hash}"
                    )
                    dest.unlink()
                    return False

            self.logger.info(f"Downloaded: {dest}")
            return True

        except Exception as e:
            self.logger.error(f"Failed to download {url}: {e}")
            return False

    def get_file_hash(self, file_path: Path, algorithm: str = "md5") -> str:
        """Calculate file hash"""
        hash_obj = hashlib.new(algorithm)
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_obj.update(chunk)
        return hash_obj.hexdigest()

    def download_package(self, package: dict) -> bool:
        """Download a package source"""
        try:
            url = package["url"]
            filename = Path(url).name
            dest_path = self.sources_dir / filename

            # Skip if already downloaded
            if dest_path.exists():
                self.logger.info(f"Package already downloaded: {filename}")
                return True

            # Download the package
            return self.download_file(url, dest_path, package.get("hash"))

        except Exception as e:
            self.logger.error(
                f"Failed to download package {package.get('name', 'unknown')}: {e}"
            )
            return False

    def extract_archive(self, archive_path: Path, dest_dir: Path) -> bool:
        """Extract various archive formats"""
        try:
            self.logger.info(f"Extracting {archive_path} to {dest_dir}")

            if archive_path.suffix in [".tar", ".tgz"] or ".tar." in archive_path.name:
                with tarfile.open(archive_path, "r:*") as tar:
                    tar.extractall(dest_dir)
            elif archive_path.suffix == ".zip":
                with zipfile.ZipFile(archive_path, "r") as zip_file:
                    zip_file.extractall(dest_dir)
            else:
                self.logger.error(f"Unsupported archive format: {archive_path}")
                return False

            self.logger.info(f"Extracted: {archive_path}")
            return True

        except Exception as e:
            self.logger.error(f"Failed to extract {archive_path}: {e}")
            return False

    def build_package(self, package: dict) -> bool:
        """Build a single package"""
        name = package["name"]
        version = package["version"]
        url = package["url"]
        build_commands = package.get("build", [])

        self.logger.info(f"Building package: {name} {version}")

        # Download source
        archive_name = url.split("/")[-1]
        archive_path = self.sources_dir / archive_name

        if not archive_path.exists():
            if not self.download_file(url, archive_path, package.get("md5")):
                return False

        # Extract source
        extract_dir = self.sources_dir / f"{name}-{version}"
        if extract_dir.exists():
            shutil.rmtree(extract_dir)

        if not self.extract_archive(archive_path, self.sources_dir):
            return False

        # Find extracted directory (may have different name)
        extracted_dirs = [
            d
            for d in self.sources_dir.iterdir()
            if d.is_dir() and name in d.name and version in d.name
        ]

        if not extracted_dirs:
            # Try finding any directory that starts with package name
            extracted_dirs = [
                d
                for d in self.sources_dir.iterdir()
                if d.is_dir() and d.name.startswith(name)
            ]

        if not extracted_dirs:
            self.logger.error(f"Could not find extracted directory for {name}")
            return False

        source_dir = extracted_dirs[0]

        # Setup build environment
        build_env = os.environ.copy()
        build_env.update(
            {
                "LFS": str(self.lfs_dir),
                "LC_ALL": "POSIX",
                "LFS_TGT": f"{os.uname().machine}-lfs-linux-gnu",
                "PATH": "/usr/bin:/bin",
                "MAKEFLAGS": f"-j{self.config['build']['jobs']}",
            }
        )

        # Execute build commands
        for command in build_commands:
            if not self.run_command(command, cwd=source_dir, env=build_env):
                self.logger.error(f"Build failed for {name} at command: {command}")
                return False

        # Cleanup source directory
        shutil.rmtree(source_dir, ignore_errors=True)

        self.logger.info(f"Successfully built: {name} {version}")
        return True

    def setup_lfs_environment(self):
        """Setup LFS build environment"""
        self.logger.info("Setting up LFS build environment...")

        # Create necessary directories
        dirs = [
            "etc",
            "var",
            "usr/bin",
            "usr/lib",
            "usr/sbin",
            "lib",
            "sbin",
            "bin",
            "boot",
            "home",
            "mnt",
            "opt",
            "proc",
            "root",
            "run",
            "srv",
            "sys",
            "tmp",
            "var/log",
        ]

        for dir_name in dirs:
            dir_path = self.lfs_dir / dir_name
            dir_path.mkdir(parents=True, exist_ok=True)

        # Create essential symlinks
        symlinks = [
            ("lib", "lib64"),
            ("usr/lib", "usr/lib64"),
            ("bin", "usr/bin"),
            ("sbin", "usr/sbin"),
            ("lib", "usr/lib"),
        ]

        for target, link in symlinks:
            link_path = self.lfs_dir / link
            if not link_path.exists():
                try:
                    link_path.symlink_to(target)
                except:
                    pass  # Ignore if symlink already exists

        self.logger.info("LFS environment setup complete")

    def build_toolchain(self):
        """Build cross-compilation toolchain"""
        self.logger.info("Building cross-compilation toolchain...")

        toolchain_packages = self.config.get("toolchain_packages", [])
        if not toolchain_packages:
            self.logger.warning("No toolchain packages found in configuration")
            return False

        # Download all toolchain packages first
        for package in toolchain_packages:
            if not self.download_package(package):
                self.logger.error(
                    f"Failed to download toolchain package: {package['name']}"
                )
                return False

        # Build toolchain packages in order
        for package in toolchain_packages:
            # Skip if this is just a dependency package (no build commands)
            if "build_commands" not in package:
                continue

            self.logger.info(
                f"Building toolchain package: {package['name']} {package['version']}"
            )

            # Use build_commands instead of build for consistency with toolchain.toml
            package["build"] = package.get("build_commands", [])

            if not self.build_package(package):
                self.logger.error(
                    f"Failed to build toolchain package: {package['name']}"
                )
                return False

        self.logger.info("Toolchain build complete")
        return True

    def build_system_packages(self):
        """Build main system packages"""
        self.logger.info("Building system packages...")

        packages = self.config.get("packages", [])
        for package in packages:
            if not self.build_package(package):
                return False

        self.logger.info("System packages build complete")
        return True

    def create_bootloader(self):
        """Create bootloader configuration"""
        self.logger.info("Setting up bootloader...")

        # GRUB configuration for all purposes
        grub_cfg = f"""
set default=0
set timeout=5

menuentry "{self.config["meta"]["name"]} {self.config["meta"]["version"]}" {{
    linux   /boot/vmlinuz root=/dev/sda1 ro
    initrd  /boot/initrd.img
}}
"""

        boot_dir = self.lfs_dir / "boot" / "grub"
        boot_dir.mkdir(parents=True, exist_ok=True)

        with open(boot_dir / "grub.cfg", "w") as f:
            f.write(grub_cfg)

        self.logger.info("Bootloader configuration created")

    def create_system_config(self):
        """Create essential system configuration files"""
        self.logger.info("Creating system configuration...")

        # /etc/passwd
        passwd_content = """root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
"""

        etc_dir = self.lfs_dir / "etc"
        etc_dir.mkdir(parents=True, exist_ok=True)

        with open(etc_dir / "passwd", "w") as f:
            f.write(passwd_content)

        # /etc/group
        group_content = """root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
"""

        with open(etc_dir / "group", "w") as f:
            f.write(group_content)

        # /etc/fstab
        fstab_content = """# file system  mount-point  type   options          dump  fsck
#                                                            order
/dev/sda1      /            ext4   defaults         1     1
proc           /proc        proc   nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs  nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts gid=5,mode=620   0     0
tmpfs          /run         tmpfs  defaults         0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid 0     0
"""

        with open(etc_dir / "fstab", "w") as f:
            f.write(fstab_content)

        # /etc/os-release
        os_release_content = f"""NAME="{self.config["meta"]["name"]}"
VERSION="{self.config["meta"]["version"]}"
ID={self.config["meta"]["name"].lower().strip()}
ID_LIKE=linux
PRETTY_NAME="{self.config["meta"]["name"]} {self.config["meta"]["version"]}"
VERSION_ID="{self.config["meta"]["version"]}"
HOME_URL="https://github.com/windfall-tech/windfall-linux"
"""

        with open(etc_dir / "os-release", "w") as f:
            f.write(os_release_content)

        self.logger.info("System configuration created")

    def create_system_users(self):
        """Create system users based on configuration"""
        self.logger.info("Creating system users...")

        # Update /etc/passwd and /etc/group with configured users
        etc_dir = self.lfs_dir / "etc"

        # Base system users
        passwd_lines = [
            "root:x:0:0:root:/root:/bin/bash",
            "daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin",
            "bin:x:2:2:bin:/bin:/usr/sbin/nologin",
            "sys:x:3:3:sys:/dev:/usr/sbin/nologin",
        ]

        group_lines = [
            "root:x:0:",
            "daemon:x:1:",
            "bin:x:2:",
            "sys:x:3:",
            "wheel:x:10:",
            "sudo:x:27:",
            "users:x:100:",
        ]

        # Add configured system users
        system_users = self.config.get("users", {}).get("system", [])
        for user in system_users:
            if user["name"] != "root":  # root already exists
                passwd_lines.append(
                    f"{user['name']}:x:{user['uid']}:{user['gid']}:{user['name']}:{user['home']}:{user['shell']}"
                )

                # Create user's primary group if it doesn't exist
                group_exists = any(
                    line.startswith(f"{user['name']}:") for line in group_lines
                )
                if not group_exists:
                    group_lines.append(f"{user['name']}:x:{user['gid']}:")

                # Add user to additional groups
                for group_name in user.get("groups", []):
                    for i, line in enumerate(group_lines):
                        if line.startswith(f"{group_name}:"):
                            parts = line.split(":")
                            if len(parts) == 4:
                                users_in_group = parts[3].split(",") if parts[3] else []
                                if user["name"] not in users_in_group:
                                    users_in_group.append(user["name"])
                                    parts[3] = ",".join(filter(None, users_in_group))
                                    group_lines[i] = ":".join(parts)
                            break

        # Write updated files
        with open(etc_dir / "passwd", "w") as f:
            f.write("\n".join(passwd_lines) + "\n")

        with open(etc_dir / "group", "w") as f:
            f.write("\n".join(group_lines) + "\n")

        self.logger.info(f"Created {len(system_users)} system users")

    def build(self):
        """Main build process"""
        self.logger.info(
            f"Starting build of {self.config['meta']['name']} {self.config['meta']['version']}"
        )

        try:
            # Setup environment
            self.setup_lfs_environment()

            # Build toolchain
            if not self.build_toolchain():
                raise Exception("Toolchain build failed")

            # Build system packages
            if not self.build_system_packages():
                raise Exception("System packages build failed")

            # Create system configuration
            self.create_system_config()

            # Create system users
            self.create_system_users()

            # Create bootloader
            self.create_bootloader()

            self.logger.info(
                f"BUILD COMPLETE! Your Linux distribution is ready at: {self.lfs_dir}"
            )
            self.logger.info(
                f"Distribution: {self.config['meta']['name']} {self.config['meta']['version']}"
            )

            return True

        except Exception as e:
            self.logger.error(f"Build failed: {e}")
            return False


def main():
    """Main entry point"""
    print("🐧 Windfall Linux Builder - Single Script Distro Builder")
    print("=" * 60)

    if len(sys.argv) > 2 or (len(sys.argv) == 2 and sys.argv[1] in ["-h", "--help"]):
        print("Usage: python3 build-linux.py [examples/simple.toml]")
        print()
        print("Build a complete Linux distribution from TOML configuration.")
        print()
        print("Arguments:")
        print(
            "  config.toml    TOML configuration file (default: examples/simple.toml)"
        )
        print()
        print("Example:")
        print("  python3 build-linux.py")
        print("  python3 build-linux.py my-distro.toml")
        sys.exit(0)

    config_file = Path(sys.argv[1] if len(sys.argv) == 2 else "examples/simple.toml")

    if not config_file.exists():
        print(f"ERROR: Configuration file not found: {config_file}")
        print()
        print("Create a config.toml file or specify an existing one.")
        print("See examples/simple.toml for a template.")
        sys.exit(1)

    # Build the Linux distribution
    builder = LinuxBuilder(config_file)
    success = builder.build()

    if success:
        print()
        print("🎉 SUCCESS! Your Linux distribution has been built!")
        sys.exit(0)
    else:
        print()
        print("❌ BUILD FAILED! Check the logs above for details.")
        sys.exit(1)


if __name__ == "__main__":
    main()
