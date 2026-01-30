#!/bin/bash
#
# Mindspace Installer for macOS
# One-command installation that bypasses Gatekeeper
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Wlvrn/mindspace-docs/main/install.sh | bash
#
# Or download and run:
#   bash install.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/Applications"
APP_NAME="Mindspace.app"
REPO="Wlvrn/mindspace-docs"
VERSION="${MINDSPACE_VERSION:-latest}"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ZIP_NAME="Mindspace-arm64-mac.zip"
elif [ "$ARCH" = "x86_64" ]; then
    ZIP_NAME="Mindspace-x64-mac.zip"
else
    echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
    echo "Mindspace only supports arm64 (Apple Silicon) and x86_64 (Intel) Macs."
    exit 1
fi

# Construct download URL
if [ "$VERSION" = "latest" ]; then
    DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$ZIP_NAME"
else
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/v$VERSION/$ZIP_NAME"
fi

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Mindspace Installer for macOS                    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is not installed${NC}"
    exit 1
fi

if ! command -v unzip &> /dev/null; then
    echo -e "${RED}❌ unzip is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# Check for existing installation
if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
    echo -e "${YELLOW}⚠️  Existing Mindspace installation found${NC}"
    echo -e "${YELLOW}   Location: $INSTALL_DIR/$APP_NAME${NC}"
    echo ""
    echo "What would you like to do?"
    echo "  [U] Upgrade (replace with new version)"
    echo "  [C] Cancel installation"
    echo ""
    read -p "Choice [U/C]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Uu]$ ]]; then
        echo -e "${YELLOW}Backing up existing installation...${NC}"
        BACKUP_PATH="$INSTALL_DIR/Mindspace.app.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$INSTALL_DIR/$APP_NAME" "$BACKUP_PATH"
        echo -e "${GREEN}✓ Backup created: $BACKUP_PATH${NC}"
    else
        echo -e "${BLUE}Installation cancelled${NC}"
        exit 0
    fi
fi

# Download
echo -e "${BLUE}⬇️  Downloading Mindspace for macOS ($ARCH)...${NC}"
TMP_ZIP="/tmp/mindspace-$$.zip"

if ! curl -L --progress-bar "$DOWNLOAD_URL" -o "$TMP_ZIP"; then
    echo -e "${RED}❌ Download failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check your internet connection"
    echo "2. Verify the release exists: https://github.com/$REPO/releases"
    echo "3. Try downloading manually: $DOWNLOAD_URL"
    exit 1
fi

# Verify download size (should be > 100MB)
FILESIZE=$(stat -f%z "$TMP_ZIP" 2>/dev/null || stat -c%s "$TMP_ZIP" 2>/dev/null)
if [ "$FILESIZE" -lt 100000000 ]; then
    echo -e "${RED}❌ Downloaded file is too small ($FILESIZE bytes)${NC}"
    echo "This likely means the release doesn't exist yet."
    rm -f "$TMP_ZIP"
    exit 1
fi

echo -e "${GREEN}✓ Download complete ($(numfmt --to=iec-i --suffix=B $FILESIZE 2>/dev/null || echo "$FILESIZE bytes"))${NC}"
echo ""

# Extract
echo -e "${BLUE}📦 Extracting to $INSTALL_DIR...${NC}"
TMP_DIR="/tmp/mindspace-install-$$"
mkdir -p "$TMP_DIR"

if ! unzip -q "$TMP_ZIP" -d "$TMP_DIR"; then
    echo -e "${RED}❌ Extraction failed${NC}"
    rm -rf "$TMP_ZIP" "$TMP_DIR"
    exit 1
fi

# Find the .app bundle (handle nested directories)
APP_BUNDLE=$(find "$TMP_DIR" -name "*.app" -type d -maxdepth 3 | head -n 1)

if [ -z "$APP_BUNDLE" ]; then
    echo -e "${RED}❌ Could not find Mindspace.app in downloaded archive${NC}"
    rm -rf "$TMP_ZIP" "$TMP_DIR"
    exit 1
fi

# Copy to Applications
if ! cp -R "$APP_BUNDLE" "$INSTALL_DIR/"; then
    echo -e "${RED}❌ Failed to copy to $INSTALL_DIR${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. You may need administrator permissions:"
    echo "   sudo bash install.sh"
    echo ""
    echo "2. Or install to your user Applications folder:"
    echo "   INSTALL_DIR=~/Applications bash install.sh"
    rm -rf "$TMP_ZIP" "$TMP_DIR"
    exit 1
fi

echo -e "${GREEN}✓ Installed to $INSTALL_DIR/$APP_NAME${NC}"
echo ""

# Remove quarantine flags (this is the key to bypassing Gatekeeper)
echo -e "${BLUE}🔓 Removing quarantine flags...${NC}"
if xattr -cr "$INSTALL_DIR/$APP_NAME" 2>/dev/null; then
    echo -e "${GREEN}✓ Quarantine removed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not remove quarantine (may need sudo)${NC}"
    echo "If the app doesn't open, run:"
    echo "  sudo xattr -cr '$INSTALL_DIR/$APP_NAME'"
fi
echo ""

# Cleanup
echo -e "${BLUE}🧹 Cleaning up...${NC}"
rm -rf "$TMP_ZIP" "$TMP_DIR"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Success
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ Installation Successful!                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Mindspace has been installed to: $INSTALL_DIR/$APP_NAME${NC}"
echo ""

# Launch app
read -p "Launch Mindspace now? [Y/n]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo -e "${BLUE}🚀 Launching Mindspace...${NC}"
    open "$INSTALL_DIR/$APP_NAME"
else
    echo "You can launch Mindspace from:"
    echo "  - Finder: Applications → Mindspace"
    echo "  - Spotlight: ⌘Space → type 'Mindspace'"
    echo "  - Terminal: open '$INSTALL_DIR/$APP_NAME'"
fi

echo ""
echo -e "${YELLOW}First-time users:${NC}"
echo "  - Mindspace will start PostgreSQL, Ollama, and other services"
echo "  - Initial setup may take 1-2 minutes"
echo "  - Check the status bar for service health"
echo ""
echo -e "${BLUE}Need help? Visit: https://github.com/Wlvrn/mindspace/issues${NC}"
