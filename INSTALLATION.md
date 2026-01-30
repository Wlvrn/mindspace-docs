# Mindspace Installation Guide for macOS

Complete installation instructions for macOS with step-by-step screenshots and troubleshooting.

---

## Quick Install (Recommended)

The fastest way to install Mindspace is using our one-command curl installer:

```bash
curl -fsSL https://raw.githubusercontent.com/Wlvrn/mindspace-docs/main/install.sh | bash
```

**What happens:**
1. ⬇️  Downloads Mindspace for your architecture (ARM64 or Intel)
2. 📦 Extracts to `/Applications`
3. 🔓 Removes macOS quarantine flags (no Gatekeeper warnings!)
4. 🚀 Launches the app automatically

**System Requirements:**
- macOS 12.0 (Monterey) or later
- 8GB RAM minimum (16GB recommended)
- 15GB free disk space
- Internet connection (initial setup)

---

## Manual Installation (Alternative)

If you prefer not to use the curl installer, follow these detailed steps:

### Step 1: Download Mindspace

1. Visit the [latest release page](https://github.com/Wlvrn/mindspace-docs/releases/latest)
2. Download the appropriate ZIP for your Mac:
   - **Apple Silicon (M1/M2/M3)**: `Mindspace-arm64-mac.zip`
   - **Intel Mac**: `Mindspace-x64-mac.zip`

### Step 2: Verify Download (Optional but Recommended)

Check the SHA256 hash to ensure file integrity:

```bash
shasum -a 256 ~/Downloads/Mindspace-arm64-mac.zip
```

Compare the output with the `Mindspace-arm64-mac.zip.sha256` file from the release page.

### Step 3: Extract the ZIP

1. Locate the downloaded ZIP in your Downloads folder
2. Double-click to extract (Safari does this automatically)
3. You'll see `Mindspace.app`

### Step 4: Move to Applications

Drag `Mindspace.app` to your `/Applications` folder (or `~/Applications` for user-only install).

### Step 5: First Launch (Bypass Gatekeeper)

**Important:** Because Mindspace is unsigned, macOS will block it on first launch.

#### On macOS Sequoia (15.0+), Sonoma (14.x), Ventura (13.x):

1. Try to open Mindspace → You'll see: **"Mindspace can't be opened because it is from an unidentified developer"**

2. Open **System Settings** (⚙️ in Dock or  → System Settings)

3. Go to **Privacy & Security**

4. Scroll to the **Security** section at the bottom

5. You'll see: **"Mindspace was blocked from use because it is not from an identified developer"**

6. Click **"Open Anyway"** (you may need to unlock with Touch ID or password first)

7. A confirmation dialog appears → Click **"Open"**

8. Mindspace will now launch!

#### On macOS Monterey (12.x):

1. Right-click (or Control-click) on `Mindspace.app`
2. Select **"Open"** from the context menu
3. Click **"Open"** in the warning dialog
4. App launches successfully

---

## Troubleshooting

### Issue: "Mindspace can't be opened"

**Symptom:** App shows security warning and won't open.

**Solution 1 - System Settings (Recommended):**
Follow Step 5 above to authorize via System Settings → Privacy & Security.

**Solution 2 - Terminal (Advanced):**
Remove the quarantine flag manually:
```bash
xattr -cr /Applications/Mindspace.app
```
Then launch normally.

---

### Issue: "Permission denied" when copying to /Applications

**Symptom:** Can't move Mindspace.app to /Applications folder.

**Solution 1 - Use sudo with curl installer:**
```bash
curl -fsSL https://raw.githubusercontent.com/Wlvrn/mindspace-docs/main/install.sh | sudo bash
```

**Solution 2 - Install to user Applications:**
```bash
INSTALL_DIR=~/Applications curl -fsSL https://raw.githubusercontent.com/Wlvrn/mindspace-docs/main/install.sh | bash
```

**Solution 3 - Manual drag with authentication:**
When dragging to /Applications, macOS will prompt for your password.

---

### Issue: Services won't start (PostgreSQL, Ollama errors)

**Symptom:** App opens but services fail to start, or you see errors in the UI.

**Solution 1 - Check logs:**
```bash
tail -f ~/Library/Application\ Support/Mindspace/logs/main.log
```

**Solution 2 - Reset services:**
1. Quit Mindspace
2. Run:
   ```bash
   # Stop conflicting services
   pkill -f postgres
   pkill -f ollama

   # Clear data (WARNING: Deletes conversations!)
   rm -rf ~/Library/Application\ Support/Mindspace/pgdata
   ```
3. Reopen Mindspace → Services will reinitialize

**Solution 3 - Port conflicts:**
If PostgreSQL or other services fail due to port conflicts:
```bash
# Check what's using port 5432 (PostgreSQL)
lsof -i :5432

# Check port 11434 (Ollama)
lsof -i :11434

# Check port 8000 (Backend)
lsof -i :8000
```

Kill conflicting processes or change ports in Settings.

---

### Issue: Download failed / Corrupted ZIP

**Symptom:** ZIP won't extract or shows errors.

**Solution:**
1. Clear your Downloads cache:
   ```bash
   rm -rf ~/Library/Caches/com.apple.Safari/
   ```
2. Redownload from [releases page](https://github.com/Wlvrn/mindspace-docs/releases/latest)
3. Try alternative browser (Firefox, Chrome) if Safari fails

---

### Issue: "This app is damaged and can't be opened"

**Symptom:** macOS shows damaged app warning.

**Cause:** ZIP quarantine or incomplete download.

**Solution:**
```bash
# Remove quarantine and extended attributes
xattr -cr /Applications/Mindspace.app

# Verify app integrity
codesign --verify --deep --strict --verbose=2 /Applications/Mindspace.app
```

If codesign shows errors, redownload the app.

---

### Issue: Ollama models won't download

**Symptom:** Mindspace tries to pull Ollama models but fails.

**Solution 1 - Manual model pull:**
```bash
ollama pull llama3:latest
ollama pull nomic-embed-text
```

**Solution 2 - Use remote provider:**
In Settings → Provider, switch to Anthropic/OpenAI instead of Ollama.

---

### Issue: App crashes immediately on launch

**Symptom:** App opens then quits instantly.

**Solution:**
1. Check macOS version: Must be 12.0+
   ```bash
   sw_vers
   ```

2. Verify architecture match:
   ```bash
   uname -m  # Should match download (arm64 or x86_64)
   ```

3. Reset app preferences:
   ```bash
   rm -rf ~/Library/Application\ Support/Mindspace/
   rm -rf ~/Library/Preferences/com.mindspace.app.plist
   ```

4. Reinstall using curl installer (ensures correct architecture).

---

## Architecture Notes

### Apple Silicon (M1/M2/M3/M4)
- Use `Mindspace-arm64-mac.zip`
- Native performance, no Rosetta required
- Recommended for all M-series Macs

### Intel Macs
- Use `Mindspace-x64-mac.zip`
- Runs natively on Intel processors
- May be slower than Apple Silicon for AI workloads

### Rosetta Compatibility
- ARM64 build will run on Intel via Rosetta (not recommended)
- Intel build will NOT run on Apple Silicon
- Always download the correct architecture for best performance

---

## Uninstalling Mindspace

To completely remove Mindspace:

```bash
# Remove app
rm -rf /Applications/Mindspace.app

# Remove user data (conversations, settings)
rm -rf ~/Library/Application\ Support/Mindspace/

# Remove preferences
rm -rf ~/Library/Preferences/com.mindspace.app.plist

# Remove logs
rm -rf ~/Library/Logs/Mindspace/
```

---

## Security & Privacy

### What the Installer Does

The curl installer (`install.sh`) performs these actions:

1. **Downloads** Mindspace.app via HTTPS from GitHub
2. **Extracts** the ZIP to /Applications
3. **Removes** macOS quarantine flags: `xattr -cr Mindspace.app`
4. **Launches** the app

**No system modifications**, no background processes, no telemetry.

### Why Remove Quarantine?

macOS adds a `com.apple.quarantine` extended attribute to files downloaded from the internet. This triggers Gatekeeper, which blocks unsigned apps.

Removing this attribute is a standard practice for unsigned software distribution and is how tools like Homebrew, rustup, and nvm install themselves.

### Is This Safe?

**Yes, if you trust the source:**
- All code is open source on GitHub
- SHA256 checksums verify download integrity
- HTTPS enforces encryption during download
- You can build from source if paranoid

**No, if you don't verify:**
- Always check SHA256 hashes
- Review code before running installers
- Use official GitHub releases only

---

## Updating Mindspace

### Automatic Updates (Future)

We're working on built-in auto-updates. For now, updates are manual.

### Manual Update Process

1. **Method 1 - Reinstall with curl:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Wlvrn/mindspace-docs/main/install.sh | bash
   ```
   Existing installation will be backed up automatically.

2. **Method 2 - Download new release:**
   - Download latest ZIP from releases page
   - Drag to Applications (replace when prompted)
   - Your conversations/settings are preserved (stored in `~/Library/Application Support/`)

---

## Building from Source

For maximum security, build Mindspace yourself:

```bash
# Clone repository
git clone https://github.com/Wlvrn/mindspace.git
cd mindspace

# Run complete build
./build.sh --mac

# Output: electron/dist/Mindspace.app
```

See [BUILD.md](../BUILD.md) for detailed build instructions.

---

## Getting Help

**Documentation:**
- Main README: [README.md](../README.md)
- Build guide: [BUILD.md](../BUILD.md)
- Deployment: [DEPLOYMENT.md](../DEPLOYMENT.md)

**Support Channels:**
- GitHub Issues: [Report bugs](https://github.com/Wlvrn/mindspace/issues)
- Discussions: [Ask questions](https://github.com/Wlvrn/mindspace/discussions)

**Common Resources:**
- Release notes: [View changelog](https://github.com/Wlvrn/mindspace-docs/releases)
- Source code: [Browse repository](https://github.com/Wlvrn/mindspace)

---

## FAQ

### Q: Do I need an Apple Developer account?

**A:** No. Mindspace doesn't require any Apple accounts to install or use.

### Q: Will this void my Mac's warranty?

**A:** No. Installing unsigned software doesn't affect your hardware warranty.

### Q: Is my data sent to external servers?

**A:** No. Mindspace is local-first. Your conversations stay on your machine. API calls go directly to your chosen provider (Anthropic/OpenAI/etc.) but not through our servers.

### Q: Can I use Mindspace offline?

**A:** Yes, with Ollama. Configure Settings → Provider → Ollama and pull local models.

### Q: What's the difference between this and Claude.ai?

**A:** Mindspace runs locally, stores conversations in your PostgreSQL database, and gives you full control over data and models. Claude.ai is cloud-based.

### Q: Will Mindspace ever be code-signed?

**A:** Yes, we're working toward obtaining an Apple Developer certificate for future releases. This will eliminate Gatekeeper warnings.

---

## Next Steps

After installation:

1. **Configure Provider:** Settings (⌘,) → Choose Anthropic/OpenAI/Ollama
2. **Set API Key:** Or configure Ollama host if using local models
3. **Pull Ollama Models:** If using Ollama, pull `llama3:latest` and `nomic-embed-text`
4. **Start Chatting:** Create a new conversation (⌘N)
5. **Explore Features:** Try projects, search (⌘K), theming, keyboard shortcuts

Enjoy Mindspace! 🚀
