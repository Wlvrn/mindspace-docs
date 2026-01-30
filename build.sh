#!/bin/bash
set -e

# =============================================================================
# Mindspace Build Script
# Builds the complete application for macOS and Windows
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Mindspace Build System                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
BUILD_MAC=false
BUILD_WIN=false
SKIP_BACKEND=false
SKIP_AI_OS=false
SKIP_FRONTEND=false

for arg in "$@"; do
  case $arg in
    --mac)
      BUILD_MAC=true
      ;;
    --win)
      BUILD_WIN=true
      ;;
    --all)
      BUILD_MAC=true
      BUILD_WIN=true
      ;;
    --skip-backend)
      SKIP_BACKEND=true
      ;;
    --skip-ai-os)
      SKIP_AI_OS=true
      ;;
    --skip-frontend)
      SKIP_FRONTEND=true
      ;;
    --help)
      echo "Usage: ./build.sh [options]"
      echo ""
      echo "Options:"
      echo "  --mac           Build for macOS"
      echo "  --win           Build for Windows"
      echo "  --all           Build for all platforms"
      echo "  --skip-backend  Skip building Python backend"
      echo "  --skip-ai-os    Skip building AI OS service"
      echo "  --skip-frontend Skip building frontend"
      echo ""
      exit 0
      ;;
  esac
done

# Default to current platform
if [ "$BUILD_MAC" = false ] && [ "$BUILD_WIN" = false ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    BUILD_MAC=true
  else
    BUILD_WIN=true
  fi
fi

# Check prerequisites
check_prereqs() {
  echo -e "${YELLOW}Checking prerequisites...${NC}"
  
  # Node.js
  if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Node.js $(node -v)${NC}"
  
  # npm
  if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ npm $(npm -v)${NC}"
  
  # Python (for backend build)
  if [ "$SKIP_BACKEND" = false ]; then
    # Try to find Python 3.10+
    PYTHON_CMD=""
    for py in python3.12 python3.11 python3.10 python3; do
      if command -v $py &> /dev/null; then
        PY_VERSION=$($py -c 'import sys; print(sys.version_info.minor)')
        if [ "$PY_VERSION" -ge 10 ]; then
          PYTHON_CMD=$py
          break
        fi
      fi
    done
    
    # Check homebrew paths
    if [ -z "$PYTHON_CMD" ]; then
      for py in /opt/homebrew/opt/python@3.12/bin/python3.12 /opt/homebrew/opt/python@3.11/bin/python3.11; do
        if [ -x "$py" ]; then
          PYTHON_CMD=$py
          break
        fi
      done
    fi
    
    if [ -z "$PYTHON_CMD" ]; then
      echo -e "${RED}❌ Python 3.10+ not found. Please install Python 3.10 or later${NC}"
      echo "   brew install python@3.11"
      exit 1
    fi
    
    echo -e "${GREEN}✓ Python $($PYTHON_CMD --version)${NC}"
    export PYTHON_CMD
    
    # PyInstaller
    if ! $PYTHON_CMD -c "import PyInstaller" 2>/dev/null; then
      echo -e "${YELLOW}Installing PyInstaller...${NC}"
      $PYTHON_CMD -m pip install pyinstaller
    fi
    echo -e "${GREEN}✓ PyInstaller available${NC}"
  fi
  
  echo ""
}

# Build Python Backend
build_backend() {
  if [ "$SKIP_BACKEND" = true ]; then
    echo -e "${YELLOW}⏩ Skipping backend build${NC}"
    return
  fi
  
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}Building Python Backend...${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  
  cd "$SCRIPT_DIR/backend"
  
  # Install dependencies using the correct Python
  echo "Installing Python dependencies with $PYTHON_CMD..."
  $PYTHON_CMD -m pip install -r requirements.txt -q
  
  # Build with PyInstaller
  echo "Running PyInstaller..."
  $PYTHON_CMD -m PyInstaller mindspace-backend.spec --clean --noconfirm
  
  if [ -f "dist/mindspace-backend" ] || [ -f "dist/mindspace-backend.exe" ]; then
    echo -e "${GREEN}✓ Backend built successfully${NC}"
    ls -lh dist/mindspace-backend* 2>/dev/null || true
  else
    echo -e "${RED}❌ Backend build failed${NC}"
    exit 1
  fi
  
  cd "$SCRIPT_DIR"
  echo ""
}

# Build AI OS Service
build_ai_os() {
  if [ "$SKIP_AI_OS" = true ]; then
    echo -e "${YELLOW}⏩ Skipping AI OS build${NC}"
    return
  fi
  
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}Building AI OS Service...${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  
  # Build AI OS library first
  cd "$SCRIPT_DIR/ai-os"
  echo "Installing AI OS library dependencies..."
  npm ci --silent
  echo "Building AI OS library..."
  npm run build
  
  # Build AI OS service
  cd "$SCRIPT_DIR/ai-os-service"
  echo "Installing AI OS service dependencies..."
  npm ci --silent
  echo "Building AI OS service..."
  npm run build
  
  # Package with pkg (if available)
  if command -v npx &> /dev/null; then
    echo "Packaging AI OS service as executable..."
    npx pkg . --targets node18-macos-arm64,node18-macos-x64,node18-win-x64 --output dist/ai-os-service 2>/dev/null || {
      echo -e "${YELLOW}⚠ pkg not available, will use Node.js at runtime${NC}"
    }
  fi
  
  cd "$SCRIPT_DIR"
  echo -e "${GREEN}✓ AI OS service built${NC}"
  echo ""
}

# Build Frontend
build_frontend() {
  if [ "$SKIP_FRONTEND" = true ]; then
    echo -e "${YELLOW}⏩ Skipping frontend build${NC}"
    return
  fi
  
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}Building Frontend...${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  
  cd "$SCRIPT_DIR/frontend"

  # Install dependencies
  echo "Installing frontend dependencies..."
  # Use npm install instead of npm ci to avoid lockfile issues
  npm install --legacy-peer-deps > /dev/null 2>&1 || npm ci --silent

  # Clean old build artifacts to prevent version mixing
  echo "Cleaning old build artifacts..."
  rm -rf build/

  # Get version and build timestamp
  VERSION=$(node -p "require('./package.json').version")
  BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Build with version metadata
  echo "Building React app v${VERSION} (${BUILD_TIMESTAMP})..."
  GENERATE_SOURCEMAP=false \
  REACT_APP_VERSION="$VERSION" \
  REACT_APP_BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
  npm run build
  
  if [ -d "build" ]; then
    echo -e "${GREEN}✓ Frontend built successfully${NC}"
    du -sh build
  else
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
  fi
  
  cd "$SCRIPT_DIR"
  echo ""
}

# Build Electron App
build_electron() {
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}Building Electron App...${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

  cd "$SCRIPT_DIR/electron"

  # Clean old dist to prevent version mixing
  echo "Cleaning old Electron dist..."
  rm -rf dist/

  # Install dependencies
  echo "Installing Electron dependencies..."
  npm ci --silent
  
  # Copy built assets to electron
  echo "Copying assets..."
  
  # Frontend
  rm -rf resources/frontend
  mkdir -p resources/frontend
  cp -r "$SCRIPT_DIR/frontend/build" resources/frontend/
  
  # Backend executable
  rm -rf resources/backend
  mkdir -p resources/backend
  if [ -f "$SCRIPT_DIR/backend/dist/mindspace-backend" ]; then
    cp "$SCRIPT_DIR/backend/dist/mindspace-backend" resources/backend/
  elif [ -f "$SCRIPT_DIR/backend/dist/mindspace-backend.exe" ]; then
    cp "$SCRIPT_DIR/backend/dist/mindspace-backend.exe" resources/backend/
  else
    echo -e "${YELLOW}⚠ Backend executable not found, copying source${NC}"
    cp -r "$SCRIPT_DIR/backend/"*.py resources/backend/
    cp "$SCRIPT_DIR/backend/requirements.txt" resources/backend/
    cp -r "$SCRIPT_DIR/backend/mcp" resources/backend/ 2>/dev/null || true
  fi
  # WhatsApp bridge (needed for WhatsApp channel)
  if [ -d "$SCRIPT_DIR/backend/whatsapp-bridge" ]; then
    rm -rf resources/backend/whatsapp-bridge
    cp -r "$SCRIPT_DIR/backend/whatsapp-bridge" resources/backend/
  fi
  
  # AI OS service
  rm -rf resources/ai-os-service
  mkdir -p resources/ai-os-service
  if [ -f "$SCRIPT_DIR/ai-os-service/dist/ai-os-service" ]; then
    cp "$SCRIPT_DIR/ai-os-service/dist/ai-os-service" resources/ai-os-service/
  else
    cp -r "$SCRIPT_DIR/ai-os-service/dist" resources/ai-os-service/ 2>/dev/null || true
    cp "$SCRIPT_DIR/ai-os-service/package.json" resources/ai-os-service/
  fi
  
  # Build for selected platforms
  if [ "$BUILD_MAC" = true ]; then
    echo ""
    echo "Building for macOS..."
    # Workaround: ensure pkg output placeholder exists to avoid electron-builder unlink ENOENT
    mkdir -p "$SCRIPT_DIR/electron/dist"
    touch "$SCRIPT_DIR/electron/dist/com.mindspace.app.pkg"
    npm run build:mac
    echo -e "${GREEN}✓ macOS build complete${NC}"
  fi
  
  if [ "$BUILD_WIN" = true ]; then
    echo ""
    echo "Building for Windows..."
    npm run build:win
    echo -e "${GREEN}✓ Windows build complete${NC}"
  fi
  
  cd "$SCRIPT_DIR"
  echo ""
}

# Create release artifacts
create_release() {
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}Creating Release Artifacts...${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  
  RELEASE_DIR="$SCRIPT_DIR/release"
  rm -rf "$RELEASE_DIR"
  mkdir -p "$RELEASE_DIR"
  
  VERSION=$(node -p "require('./electron/package.json').version")
  
  # Copy built artifacts
  if [ -d "$SCRIPT_DIR/electron/dist" ]; then
    # macOS .pkg
    if [ -f "$SCRIPT_DIR/electron/dist/Mindspace-${VERSION}.pkg" ]; then
      cp "$SCRIPT_DIR/electron/dist/Mindspace-${VERSION}.pkg" "$RELEASE_DIR/"
      echo -e "${GREEN}✓ Mindspace-${VERSION}.pkg${NC}"
    fi
    
    # macOS .dmg
    if [ -f "$SCRIPT_DIR/electron/dist/Mindspace-${VERSION}.dmg" ]; then
      cp "$SCRIPT_DIR/electron/dist/Mindspace-${VERSION}.dmg" "$RELEASE_DIR/"
      echo -e "${GREEN}✓ Mindspace-${VERSION}.dmg${NC}"
    fi
    
    # macOS ARM64
    if [ -f "$SCRIPT_DIR/electron/dist/Mindspace-${VERSION}-arm64.dmg" ]; then
      cp "$SCRIPT_DIR/electron/dist/Mindspace-${VERSION}-arm64.dmg" "$RELEASE_DIR/"
      echo -e "${GREEN}✓ Mindspace-${VERSION}-arm64.dmg${NC}"
    fi
    
    # Windows installer
    if [ -f "$SCRIPT_DIR/electron/dist/Mindspace-Setup-${VERSION}.exe" ]; then
      cp "$SCRIPT_DIR/electron/dist/Mindspace-Setup-${VERSION}.exe" "$RELEASE_DIR/"
      echo -e "${GREEN}✓ Mindspace-Setup-${VERSION}.exe${NC}"
    fi
    
    # Auto-update files
    for f in "$SCRIPT_DIR/electron/dist/"*.yml "$SCRIPT_DIR/electron/dist/"*.blockmap; do
      if [ -f "$f" ]; then
        cp "$f" "$RELEASE_DIR/"
      fi
    done
  fi
  
  echo ""
  echo -e "${BLUE}Release artifacts:${NC}"
  ls -lh "$RELEASE_DIR/"
  echo ""
}

# Main build process
main() {
  check_prereqs
  build_backend
  build_ai_os
  build_frontend
  build_electron
  create_release
  
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                   Build Complete! 🎉                          ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Release files are in: ./release/"
  echo ""
  echo "To publish a release:"
  echo "  1. Create a new release on GitHub: https://github.com/Wlvrn/mindspace-docs/releases/new"
  echo "  2. Upload the files from ./release/"
  echo "  3. The auto-updater will notify users of the new version"
  echo ""
}

main
