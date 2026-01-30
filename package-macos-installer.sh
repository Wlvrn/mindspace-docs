#!/bin/bash
set -e

echo "📦 Building Mindspace Installer for macOS..."
echo ""

APP_NAME="Mindspace"
VERSION="2.0.3"  # Bumped for auto-update test
BUILD_DIR="build"
DIST_DIR="dist"
INSTALLER_DIR="$BUILD_DIR/$APP_NAME-Installer"

# Clean previous builds
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$INSTALLER_DIR"

# ============================================
# Step 1: Build AI OS Library
# ============================================
echo "🔧 Building AI OS library..."
cd ai-os
npm install
npm run build
cd ..

# ============================================
# Step 2: Build AI OS Service
# ============================================
echo "🔧 Building AI OS service..."
cd ai-os-service
npm install
npm run build
cd ..

# ============================================
# Step 3: Build Frontend for Production
# ============================================
echo "🏗️  Building frontend for production..."
cd frontend
npm install --legacy-peer-deps
npm run build
cd ..

# ============================================
# Step 4: Copy Application Files
# ============================================
echo "📂 Copying application files..."

# Copy backend
mkdir -p "$INSTALLER_DIR/app/backend"
cp -r backend/* "$INSTALLER_DIR/app/backend/"
# Remove __pycache__ and .pyc files
find "$INSTALLER_DIR/app/backend" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$INSTALLER_DIR/app/backend" -type f -name "*.pyc" -delete 2>/dev/null || true

# Copy frontend build
mkdir -p "$INSTALLER_DIR/app/frontend"
cp -r frontend/build/* "$INSTALLER_DIR/app/frontend/"

# Copy AI OS library (compiled)
mkdir -p "$INSTALLER_DIR/app/ai-os"
cp -r ai-os/dist "$INSTALLER_DIR/app/ai-os/"
cp ai-os/package.json "$INSTALLER_DIR/app/ai-os/"
cp ai-os/package-lock.json "$INSTALLER_DIR/app/ai-os/" 2>/dev/null || true

# Copy AI OS service (compiled)
mkdir -p "$INSTALLER_DIR/app/ai-os-service"
cp -r ai-os-service/dist "$INSTALLER_DIR/app/ai-os-service/"
cp ai-os-service/package.json "$INSTALLER_DIR/app/ai-os-service/"
cp ai-os-service/package-lock.json "$INSTALLER_DIR/app/ai-os-service/" 2>/dev/null || true

# Copy documentation
cp README.md "$INSTALLER_DIR/app/" 2>/dev/null || echo "# Mindspace" > "$INSTALLER_DIR/app/README.md"
cp CLAUDE.md "$INSTALLER_DIR/app/" 2>/dev/null || true

# ============================================
# Step 5: Create Smart Installer Script
# ============================================
echo "📝 Creating installer script..."

cat > "$INSTALLER_DIR/install.sh" << 'INSTALLER_EOF'
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Mindspace Installer v2.0.0           ║${NC}"
echo -e "${BLUE}║   AI OS Edition                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_DIR="$HOME/Applications/Mindspace"
EXISTING_INSTALL=false

# ============================================
# Check for existing installation
# ============================================
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  Existing Mindspace installation detected at:${NC}"
    echo "   $INSTALL_DIR"
    echo ""
    echo "Choose installation mode:"
    echo "  [1] Upgrade (add AI OS to existing installation)"
    echo "  [2] Fresh install (replace everything)"
    echo "  [3] Cancel"
    echo ""
    read -p "Enter choice [1-3]: " choice

    case $choice in
        1)
            echo -e "${GREEN}✓ Upgrade mode selected${NC}"
            EXISTING_INSTALL=true
            ;;
        2)
            echo -e "${YELLOW}⚠️  This will delete your existing installation!${NC}"
            read -p "Are you sure? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                echo "Installation cancelled."
                exit 0
            fi
            echo -e "${GREEN}✓ Fresh install mode selected${NC}"
            rm -rf "$INSTALL_DIR"
            ;;
        *)
            echo "Installation cancelled."
            exit 0
            ;;
    esac
fi

# ============================================
# Check for Homebrew
# ============================================
echo ""
echo -e "${BLUE}[1/7] Checking system dependencies...${NC}"

if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗ Homebrew is required but not installed.${NC}"
    echo ""
    echo "Install Homebrew by running:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Homebrew found${NC}"

# ============================================
# Install System Dependencies
# ============================================
echo ""
echo -e "${BLUE}[2/7] Installing system dependencies...${NC}"

# PostgreSQL 14
if ! brew list postgresql@14 &> /dev/null; then
    echo "  Installing PostgreSQL 14..."
    brew install postgresql@14
else
    echo -e "  ${GREEN}✓ PostgreSQL 14 already installed${NC}"
fi

# Ollama
if ! command -v ollama &> /dev/null; then
    echo "  Installing Ollama..."
    brew install ollama
else
    echo -e "  ${GREEN}✓ Ollama already installed${NC}"
fi

# Python 3
if ! command -v python3 &> /dev/null; then
    echo "  Installing Python 3..."
    brew install python@3.11
else
    echo -e "  ${GREEN}✓ Python 3 already installed${NC}"
fi

# Node.js
if ! command -v node &> /dev/null; then
    echo "  Installing Node.js..."
    brew install node
else
    echo -e "  ${GREEN}✓ Node.js already installed${NC}"
fi

# ============================================
# Copy Application Files
# ============================================
echo ""
echo -e "${BLUE}[3/7] Installing application files...${NC}"

mkdir -p "$INSTALL_DIR"

if [ "$EXISTING_INSTALL" = true ]; then
    # Upgrade mode - only copy AI OS components
    echo "  Upgrading AI OS components..."
    cp -r "$SCRIPT_DIR/app/ai-os" "$INSTALL_DIR/"
    cp -r "$SCRIPT_DIR/app/ai-os-service" "$INSTALL_DIR/"

    # Update backend files (preserve .env if exists)
    if [ -f "$INSTALL_DIR/backend/.env" ]; then
        cp "$INSTALL_DIR/backend/.env" "$INSTALL_DIR/backend/.env.backup"
    fi
    cp -r "$SCRIPT_DIR/app/backend"/* "$INSTALL_DIR/backend/"
    if [ -f "$INSTALL_DIR/backend/.env.backup" ]; then
        mv "$INSTALL_DIR/backend/.env.backup" "$INSTALL_DIR/backend/.env"
    fi

    # Update frontend
    cp -r "$SCRIPT_DIR/app/frontend" "$INSTALL_DIR/"
else
    # Fresh install - copy everything
    cp -r "$SCRIPT_DIR/app"/* "$INSTALL_DIR/"
fi

echo -e "${GREEN}✓ Application files installed${NC}"

# ============================================
# Setup PostgreSQL Database
# ============================================
echo ""
echo -e "${BLUE}[4/7] Setting up PostgreSQL database...${NC}"

# Start PostgreSQL
brew services start postgresql@14
sleep 3

# Create database and user
psql postgres -c "CREATE DATABASE mindspace;" 2>/dev/null || echo "  ℹ️  Database already exists"
psql postgres -c "CREATE USER mindspace WITH PASSWORD 'mindspace';" 2>/dev/null || echo "  ℹ️  User already exists"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE mindspace TO mindspace;" 2>/dev/null || true

# Install pgvector extension
psql -d mindspace -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null || true

echo -e "${GREEN}✓ Database configured${NC}"

# ============================================
# Install Python Dependencies
# ============================================
echo ""
echo -e "${BLUE}[5/7] Installing Python dependencies...${NC}"
cd "$INSTALL_DIR/backend"
pip3 install -r requirements.txt --quiet
cd "$SCRIPT_DIR"
echo -e "${GREEN}✓ Python dependencies installed${NC}"

# ============================================
# Install Node Dependencies (AI OS)
# ============================================
echo ""
echo -e "${BLUE}[6/7] Installing AI OS dependencies...${NC}"

# AI OS library
cd "$INSTALL_DIR/ai-os"
npm install --production --silent --legacy-peer-deps
cd "$SCRIPT_DIR"

# AI OS service
cd "$INSTALL_DIR/ai-os-service"
npm install --production --silent --legacy-peer-deps
cd "$SCRIPT_DIR"

echo -e "${GREEN}✓ AI OS dependencies installed${NC}"

# ============================================
# Create Environment Files
# ============================================
echo ""
echo -e "${BLUE}[7/7] Configuring environment...${NC}"

# Backend .env (only if not exists or fresh install)
if [ ! -f "$INSTALL_DIR/backend/.env" ] || [ "$EXISTING_INSTALL" = false ]; then
    cat > "$INSTALL_DIR/backend/.env" << ENV_EOF
DATABASE_URL=postgresql://mindspace:mindspace@localhost:5432/mindspace
EMBEDDING_MODEL=nomic-embed-text
EMBEDDING_DIM=768
EMBEDDING_PROVIDER=ollama
OLLAMA_HOST=http://localhost:11434
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
AI_OS_URL=http://localhost:3001
AI_OS_ENABLED=true
ENV_EOF
fi

# AI OS service .env (only if not exists or fresh install)
if [ ! -f "$INSTALL_DIR/ai-os-service/.env" ] || [ "$EXISTING_INSTALL" = false ]; then
    cat > "$INSTALL_DIR/ai-os-service/.env" << ENV_EOF
PORT=3001
LOG_LEVEL=info
OLLAMA_BASE_URL=http://localhost:11434
AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=
OPENROUTER_API_KEY=
ENV_EOF
fi

echo -e "${GREEN}✓ Environment configured${NC}"

# ============================================
# Start Ollama and Pull Models
# ============================================
echo ""
echo -e "${BLUE}Starting Ollama and downloading AI models...${NC}"
echo "(This may take several minutes on first install)"

brew services start ollama
sleep 3

# Pull models in background
(ollama pull llama3:latest && ollama pull nomic-embed-text) &
MODEL_PID=$!

# ============================================
# Create Launch Script
# ============================================
cat > "$INSTALL_DIR/start-mindspace.sh" << 'LAUNCH_EOF'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}🚀 Starting Mindspace...${NC}"

# Start PostgreSQL
brew services start postgresql@14 2>/dev/null

# Start Ollama
brew services start ollama 2>/dev/null
sleep 2

# Start AI OS Service
echo "  Starting AI OS service..."
cd "$INSTALL_DIR/ai-os-service"
node dist/index.js > /tmp/mindspace-ai-os.log 2>&1 &
AI_OS_PID=$!
sleep 2

# Start Backend
echo "  Starting backend..."
cd "$INSTALL_DIR/backend"
python3 -m uvicorn server:app --host 0.0.0.0 --port 8000 > /tmp/mindspace-backend.log 2>&1 &
BACKEND_PID=$!
sleep 3

# Save PIDs for cleanup
echo "$AI_OS_PID" > /tmp/mindspace-ai-os.pid
echo "$BACKEND_PID" > /tmp/mindspace-backend.pid

# Open browser
echo ""
echo -e "${GREEN}✅ Mindspace is running!${NC}"
echo ""
echo "  🌐 Web UI: http://localhost:8000"
echo "  🧠 AI OS: http://localhost:3001"
echo ""
echo "  Logs:"
echo "    Backend: /tmp/mindspace-backend.log"
echo "    AI OS:   /tmp/mindspace-ai-os.log"
echo ""

# Open in default browser
sleep 2
open "http://localhost:8000" 2>/dev/null

# Keep script running
echo "Press Ctrl+C to stop all services"
trap "kill $BACKEND_PID $AI_OS_PID 2>/dev/null; exit" INT TERM
wait $BACKEND_PID
LAUNCH_EOF

chmod +x "$INSTALL_DIR/start-mindspace.sh"

# Create stop script
cat > "$INSTALL_DIR/stop-mindspace.sh" << 'STOP_EOF'
#!/bin/bash

echo "🛑 Stopping Mindspace..."

# Kill PIDs from files
if [ -f /tmp/mindspace-backend.pid ]; then
    kill $(cat /tmp/mindspace-backend.pid) 2>/dev/null
    rm /tmp/mindspace-backend.pid
fi

if [ -f /tmp/mindspace-ai-os.pid ]; then
    kill $(cat /tmp/mindspace-ai-os.pid) 2>/dev/null
    rm /tmp/mindspace-ai-os.pid
fi

# Kill by process name as fallback
pkill -f "uvicorn server:app" 2>/dev/null
pkill -f "ai-os-service" 2>/dev/null

echo "✅ Mindspace stopped"
STOP_EOF

chmod +x "$INSTALL_DIR/stop-mindspace.sh"

# Create desktop shortcut
cat > "$HOME/Desktop/Mindspace.command" << SHORTCUT_EOF
#!/bin/bash
cd "$INSTALL_DIR"
./start-mindspace.sh
SHORTCUT_EOF

chmod +x "$HOME/Desktop/Mindspace.command"

# ============================================
# Wait for models to finish downloading
# ============================================
echo ""
echo "Waiting for AI models to download..."
wait $MODEL_PID 2>/dev/null || true

# ============================================
# Installation Complete
# ============================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Mindspace has been installed to:"
echo "  $INSTALL_DIR"
echo ""
echo "To start Mindspace:"
echo "  1. Double-click 'Mindspace.command' on your Desktop"
echo "  OR"
echo "  2. Run: $INSTALL_DIR/start-mindspace.sh"
echo ""
echo "To stop Mindspace:"
echo "  $INSTALL_DIR/stop-mindspace.sh"
echo ""
echo "Configuration files:"
echo "  Backend:  $INSTALL_DIR/backend/.env"
echo "  AI OS:    $INSTALL_DIR/ai-os-service/.env"
echo ""
echo "Add your API keys to ai-os-service/.env for cloud AI models:"
echo "  ANTHROPIC_API_KEY=sk-ant-..."
echo "  OPENAI_API_KEY=sk-..."
echo ""
echo "Enjoy! 🚀"
INSTALLER_EOF

chmod +x "$INSTALLER_DIR/install.sh"

# ============================================
# Step 6: Create README
# ============================================
echo "📝 Creating README..."

cat > "$INSTALLER_DIR/README.txt" << README_EOF
╔════════════════════════════════════════╗
║   Mindspace v$VERSION - macOS Installer   ║
║   AI OS Edition                        ║
╚════════════════════════════════════════╝

INSTALLATION INSTRUCTIONS
=========================

1. Open Terminal (Applications > Utilities > Terminal)

2. Navigate to this folder:
   cd ~/Downloads/Mindspace-Installer
   (Adjust path if you extracted elsewhere)

3. Run the installer:
   ./install.sh

4. Follow the on-screen prompts

5. When complete, launch Mindspace by:
   - Double-clicking "Mindspace.command" on your Desktop
   OR
   - Running: ~/Applications/Mindspace/start-mindspace.sh


UPGRADE FROM PREVIOUS VERSION
==============================

If you have an older Mindspace installation WITHOUT AI OS:

1. Run ./install.sh
2. Select option [1] for "Upgrade mode"
3. The installer will add AI OS while preserving your data


SYSTEM REQUIREMENTS
===================

- macOS 12.0 (Monterey) or later
- 8GB RAM minimum (16GB recommended for AI models)
- 15GB free disk space
- Internet connection (for initial setup only)


WHAT GETS INSTALLED
====================

System Dependencies (via Homebrew):
  - PostgreSQL 14 (with pgvector)
  - Ollama (local AI runtime)
  - Python 3.11
  - Node.js

Mindspace Components:
  - Backend (FastAPI server)
  - Frontend (React web UI)
  - AI OS (Kernel + Service)
  - Local AI models (llama3, nomic-embed-text)


USAGE
=====

Starting:
  - Double-click "Mindspace.command" on Desktop
  - Your browser will open to http://localhost:8000

Stopping:
  - Press Ctrl+C in Terminal
  OR
  - Run: ~/Applications/Mindspace/stop-mindspace.sh

Configuration:
  - Backend:  ~/Applications/Mindspace/backend/.env
  - AI OS:    ~/Applications/Mindspace/ai-os-service/.env

Logs:
  - Backend:  /tmp/mindspace-backend.log
  - AI OS:    /tmp/mindspace-ai-os.log
  - Ollama:   /tmp/mindspace-ollama.log


ADDING CLOUD AI PROVIDERS
==========================

Edit ~/Applications/Mindspace/ai-os-service/.env:

# For Claude (Anthropic)
ANTHROPIC_API_KEY=sk-ant-your-key-here

# For GPT-4 (OpenAI)
OPENAI_API_KEY=sk-your-key-here

# For Gemini (Google)
GOOGLE_API_KEY=your-key-here

Then restart Mindspace.


UNINSTALLING
============

1. Stop Mindspace:
   ~/Applications/Mindspace/stop-mindspace.sh

2. Remove application:
   rm -rf ~/Applications/Mindspace

3. (Optional) Remove system dependencies:
   brew uninstall postgresql@14 ollama

4. (Optional) Remove database:
   rm -rf ~/Library/Application\ Support/Postgres


TROUBLESHOOTING
===============

"command not found: brew"
  → Install Homebrew: https://brew.sh

"Database connection failed"
  → Run: brew services restart postgresql@14

"Ollama not responding"
  → Run: brew services restart ollama
  → Check: ollama list

Frontend won't load:
  → Check logs: tail -f /tmp/mindspace-backend.log
  → Verify: curl http://localhost:8000/api/health


SUPPORT
=======

Documentation: ~/Applications/Mindspace/CLAUDE.md
GitHub: https://github.com/yourusername/mindspace
Issues: https://github.com/yourusername/mindspace/issues


LICENSE
=======

Copyright © 2024 Mindspace Team
All rights reserved.
README_EOF

# ============================================
# Step 7: Create DMG, ZIP or PKG
# ============================================
echo ""
echo "📦 Creating distribution package..."

# Create PKG (Standard macOS Installer)
echo "Creating PKG installer..."
pkgbuild --identifier "com.mindspace.installer" \
         --version "$VERSION" \
         --root "$INSTALLER_DIR" \
         --install-location "/tmp/$APP_NAME-Installer" \
         "$DIST_DIR/$APP_NAME-$VERSION-macOS.pkg"
echo -e "${GREEN}✅ PKG created: $DIST_DIR/$APP_NAME-$VERSION-macOS.pkg${NC}"

# Always create ZIP for GitHub compatibility
echo "Creating ZIP archive for GitHub..."
cd "$BUILD_DIR"
zip -r -q "../$DIST_DIR/$APP_NAME-$VERSION-macOS.zip" "$APP_NAME-Installer"
cd ..
echo -e "${GREEN}✅ ZIP created: $DIST_DIR/$APP_NAME-$VERSION-macOS.zip${NC}"

# Create flat ZIP for curl installer (ARM64)
echo "Creating flat ZIP for curl installer (ARM64)..."
# Check if we have an ARM64 build
if [ -d "$SCRIPT_DIR/electron/dist/mac-arm64/Mindspace.app" ]; then
    cd "$SCRIPT_DIR/electron/dist/mac-arm64"
    zip -r -q "$DIST_DIR/Mindspace-arm64-mac.zip" "Mindspace.app"
    cd - > /dev/null
    echo -e "${GREEN}✅ ARM64 ZIP created: $DIST_DIR/Mindspace-arm64-mac.zip${NC}"
else
    echo -e "${YELLOW}⚠️  ARM64 build not found, skipping flat ZIP${NC}"
fi

# Create flat ZIP for curl installer (Intel x64)
if [ -d "$SCRIPT_DIR/electron/dist/mac-x64/Mindspace.app" ]; then
    echo "Creating flat ZIP for curl installer (x64)..."
    cd "$SCRIPT_DIR/electron/dist/mac-x64"
    zip -r -q "$DIST_DIR/Mindspace-x64-mac.zip" "Mindspace.app"
    cd - > /dev/null
    echo -e "${GREEN}✅ x64 ZIP created: $DIST_DIR/Mindspace-x64-mac.zip${NC}"
fi

# Optionally create DMG for better user experience (local distribution)
if command -v create-dmg &> /dev/null; then
    echo "Creating DMG installer (for direct distribution)..."
    create-dmg \
        --volname "Mindspace $VERSION Installer" \
        --window-pos 200 120 \
        --window-size 700 500 \
        --icon-size 100 \
        --text-size 14 \
        --hide-extension "install.sh" \
        "$DIST_DIR/$APP_NAME-$VERSION-macOS.dmg" \
        "$INSTALLER_DIR" 2>&1 && \
        echo -e "${GREEN}✅ DMG created: $DIST_DIR/$APP_NAME-$VERSION-macOS.dmg${NC}" || \
        echo "⚠️  DMG creation failed (ZIP is available)"
else
    echo "ℹ️  create-dmg not installed - only ZIP created"
    echo "   (Install with: brew install create-dmg for DMG support)"
fi

# ============================================
# Create checksums
# ============================================
echo "🔐 Generating checksums..."
cd "$DIST_DIR"

# Always create checksum for ZIP (GitHub release)
shasum -a 256 "$APP_NAME-$VERSION-macOS.zip" > "$APP_NAME-$VERSION-macOS.zip.sha256"

# Create checksum for PKG if it exists
if [ -f "$APP_NAME-$VERSION-macOS.pkg" ]; then
    shasum -a 256 "$APP_NAME-$VERSION-macOS.pkg" > "$APP_NAME-$VERSION-macOS.pkg.sha256"
fi

# Create checksum for DMG if it exists
if [ -f "$APP_NAME-$VERSION-macOS.dmg" ]; then
    shasum -a 256 "$APP_NAME-$VERSION-macOS.dmg" > "$APP_NAME-$VERSION-macOS.dmg.sha256"
fi

# Create checksums for flat ZIPs (curl installer)
if [ -f "Mindspace-arm64-mac.zip" ]; then
    shasum -a 256 "Mindspace-arm64-mac.zip" > "Mindspace-arm64-mac.zip.sha256"
    echo -e "${GREEN}✓ ARM64 ZIP checksum created${NC}"
fi

if [ -f "Mindspace-x64-mac.zip" ]; then
    shasum -a 256 "Mindspace-x64-mac.zip" > "Mindspace-x64-mac.zip.sha256"
    echo -e "${GREEN}✓ x64 ZIP checksum created${NC}"
fi

cd ..

# ============================================
# Summary
# ============================================
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              Packaging Complete! 🎉                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Distribution package created:"
ls -lh "$DIST_DIR"
echo ""
echo "To test the installer:"
echo "  1. Extract/mount the package"
echo "  2. Run: ./install.sh"
echo ""
echo "To distribute:"
echo "  - Upload to GitHub Releases"
echo "  - Share download link with users"
echo "  - Include the SHA256 checksum for verification"
echo ""
