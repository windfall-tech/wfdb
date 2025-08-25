# Dockerfile for building Windfall Linux in a container (Simplified for testing)
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=POSIX
ENV LFS=/mnt/lfs
ENV PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Install minimal required dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    wget \
    curl \
    build-essential \
    gcc \
    g++ \
    make \
    bison \
    gawk \
    texinfo \
    && rm -rf /var/lib/apt/lists/*

# Install Python TOML library
RUN pip3 install tomli || pip3 install tomllib-w

# Create LFS user and directories
RUN groupadd lfs && \
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs && \
    mkdir -pv /mnt/lfs /sources /tools && \
    chown -v lfs:lfs /mnt/lfs /sources /tools && \
    chmod -v a+wt /sources

# Create working directory
WORKDIR /windfall-linux

# Copy project files
COPY . .

# Set permissions
RUN chmod +x build-linux.py

# Entry point
CMD ["python3", "build-linux.py", "examples/simple.toml"]
