# PowerShell build script for Windfall Distro Builder in Docker
Write-Host "🐧 Windfall Distro Builder Docker Builder" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Create necessary directories
if (!(Test-Path "output")) { New-Item -ItemType Directory -Name "output" }
if (!(Test-Path "sources")) { New-Item -ItemType Directory -Name "sources" }
if (!(Test-Path "logs")) { New-Item -ItemType Directory -Name "logs" }

Write-Host "📦 Building Docker image..." -ForegroundColor Yellow
docker build -t windfall-linux .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Starting Linux build with simple.toml..." -ForegroundColor Green
docker run --rm `
    --privileged `
    -v "${PWD}/output:/mnt/lfs" `
    -v "${PWD}/sources:/sources" `
    -v "${PWD}/logs:/var/log/windfall" `
    windfall-linux

if ($LASTEXITCODE -eq 0) {
    Write-Host "🎉 Build completed successfully!" -ForegroundColor Green
    Write-Host "📁 Your Linux system is in: ./output/" -ForegroundColor Cyan
} else {
    Write-Host "❌ Build failed. Check logs in: ./logs/" -ForegroundColor Red
}
