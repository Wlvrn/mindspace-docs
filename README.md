# Mindspace

Local-first Claude-style chat with a FastAPI backend and a React/Tailwind frontend. Mindspace supports Anthropic/OpenAI/Gemini/OpenRouter/Ollama providers, conversation management (projects, search, exports), streaming responses, code-friendly rendering, theming, and keyboard shortcuts.

## 🚀 Quick Install

### macOS (Recommended - One Command) 💻

```bash
curl -fsSL https://raw.githubusercontent.com/Wlvrn/mindspace-docs/main/install.sh | bash
```

**What this does:**
- Downloads the latest Mindspace release
- Installs to `/Applications`
- Removes quarantine flags (no Gatekeeper warnings!)
- Launches the app automatically

**Alternative:** [Manual installation guide](docs/INSTALLATION.md) with step-by-step screenshots

⚠️ **Security Note:** Mindspace is currently distributed unsigned. See [Security Verification](#security-verification) below.

---

## 🛠️ Development Setup

Choose your preferred development method:

### Option 1: Native Installation (Best Performance) ⚡

**Runs services natively on macOS for optimal performance - no Docker overhead!**

```bash
# Install dependencies and setup services
./install-native.sh

# Start all services
./start-native.sh

# Or run as background daemons (auto-start on login)
./setup-daemons.sh
```

Access at http://localhost:3000

**Requirements:** macOS 12.0+, 8GB RAM, Homebrew

---

### Option 2: Docker (Easiest Setup) 🐳

**The easiest way to run Mindspace - just one click!**

**Prerequisites:** [Docker Desktop](https://www.docker.com/products/docker-desktop/)

**macOS / Linux:**
```bash
./start.sh
```

**Windows:**
```
start.bat
```

Access at http://localhost:3000

**Note:** For best performance with Docker, increase memory to 8GB+ in Docker Desktop Settings → Resources

---

**First time?** See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

**Need help?** Check the complete [Deployment Guide](DEPLOYMENT.md)

## Features
- Chat with streaming responses, markdown + syntax highlighting, copyable code blocks, and optional image attachments (sent as base64 to the model).
- Conversation management: create/rename/delete, project grouping, quick search (⌘/Ctrl+K), and export to Markdown/JSON.
- Provider settings UI for Anthropic/OpenAI/Gemini/OpenRouter or local Ollama (model selector, system prompt editor, masked API key handling, Ollama model pulling).
- Light/dark theme toggle, responsive sidebar, and toast notifications for key actions.

## Repository Layout
- `backend/` – FastAPI app (`server.py`) with Postgres + pgvector persistence, SSE streaming responses, provider integrations, and local RAG.
- `frontend/` – React app (Create React App + Tailwind + shadcn/ui) that consumes the API.
- `backend_test.py` – Simple API smoke tester (adjust `base_url` before running).

## Prerequisites
- Python 3.10+ and `pip`
- Node 18+ and Yarn 1.x (project uses Yarn; npm will work but Yarn avoids lockfile drift)
- Local Postgres instance with `pgvector` extension

## Local Postgres + pgvector Setup & Cheatsheet
1. Install Postgres and the `pgvector` extension.
   - macOS: `brew install postgresql` then `brew services start postgresql`
   - Create extension: `psql -d postgres -c "CREATE EXTENSION IF NOT EXISTS vector;"`
2. Create a database/user:
   ```sql
   CREATE DATABASE mindspace;
   CREATE USER mindspace WITH PASSWORD 'mindspace';
   GRANT ALL PRIVILEGES ON DATABASE mindspace TO mindspace;
   ```
3. Sample schema sketch (you’ll need to implement this in the backend):
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   -- Core tables created automatically at app startup (see backend/server.py)
   -- Example of adding IVF index (optional):
   -- CREATE INDEX ON message_embeddings USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
   ```
4. Connection envs you would add when refactoring backend to Postgres:
   ```env
   DATABASE_URL=postgresql://mindspace:mindspace@localhost:5432/mindspace
   EMBEDDING_MODEL=text-embedding-3-small
   EMBEDDING_DIM=1536
   EMBEDDING_PROVIDER=openai # or ollama
   ```
5. Cheatsheet:
   - Start service (macOS): `brew services start postgresql`
   - Connect: `psql postgres://mindspace:mindspace@localhost:5432/mindspace`
   - Inspect tables: `\\dt`, peek messages: `SELECT role, content FROM messages LIMIT 5;`
   - Drop db (careful): `DROP DATABASE mindspace;`

## Backend Setup
1. Create `backend/.env` with at least:
   ```env
   DATABASE_URL=postgresql://mindspace:mindspace@localhost:5432/mindspace
   EMBEDDING_MODEL=text-embedding-3-small
   EMBEDDING_DIM=1536
   EMBEDDING_PROVIDER=openai
   # Optional: CORS_ORIGINS=http://localhost:3000
   ```
2. Install dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```
3. Run the API:
   ```bash
   uvicorn server:app --reload --host 0.0.0.0 --port 8000
   ```
4. Configure a provider/API key via the UI (Settings) or REST:
   ```bash
   curl -X PUT http://localhost:8000/api/settings \
     -H "Content-Type: application/json" \
     -d '{"provider":"anthropic","model":"claude-sonnet-4-5-20250929","api_key":"<your-key>"}'
   ```
   For Ollama, set `provider` to `ollama`, adjust `ollama_host`, and pull a model (e.g., `llama3.2`).

Key endpoints (`/api` prefix):
- Projects: `POST /projects`, `GET /projects`, `PUT /projects/{id}`, `DELETE /projects/{id}`
- Conversations: `POST /conversations`, `GET /conversations`, `GET /conversations/search`, `PUT /conversations/{id}`, `DELETE /conversations/{id}`, `GET /conversations/{id}/export?format=markdown|json`
- Messages: `GET /conversations/{id}/messages`, `POST /conversations/{id}/messages` (SSE stream)
- Settings: `GET/PUT /settings`, `GET /settings/status`, `GET /ollama/models`, `POST /ollama/pull`
- Artifacts: `POST /artifacts`, `GET /artifacts`, `DELETE /artifacts/{id}`

## Frontend Setup
1. Create `frontend/.env.local`:
   ```env
   REACT_APP_BACKEND_URL=http://localhost:8000
   ```
2. Install and run:
   ```bash
   cd frontend
   yarn install
   yarn start
   ```
3. Open http://localhost:3000. Use the Settings dialog to choose a provider, set an API key or Ollama host/model, and tweak the system prompt. Keyboard shortcuts: ⌘/Ctrl+K (search), ⌘/Ctrl+N (new chat), ⌘/Ctrl+, (settings), ⌘/Ctrl+B (toggle sidebar).

## Development Notes
- The backend masks stored API keys on read; re-send a full key to update it.
- Streaming responses are chunked over SSE; the frontend assembles them into a single assistant message.
- `backend_test.py` hits a remote staging URL by default—change `base_url` to your server before running.
- Tailwind and shadcn components live under `frontend/src/components/ui`; theming is handled by `ThemeProvider`.

## RAG
Enabled locally via Postgres + pgvector. When a user message or artifact is created, an embedding is generated (OpenAI by default; Ollama if `EMBEDDING_PROVIDER=ollama`) and stored in `message_embeddings` / `artifact_embeddings`. On each assistant turn the backend fetches nearest messages/artifacts with `<->` similarity, injects them into the prompt, and streams the response. Ensure an embedding-capable model is available (install an Ollama embedding model like `nomic-embed-text` for offline use, or provide an OpenAI/OpenRouter API key).

## Security Verification

Mindspace is currently distributed **without Apple code signing**. This means macOS will display security warnings when opening the app for the first time.

**Why unsigned?**
- Code signing requires an Apple Developer account ($99/year)
- We're prioritizing open-source accessibility while working toward official signing

**To verify authenticity:**

1. **Check SHA256 Hash** - Compare downloaded file with release checksum:
   ```bash
   shasum -a 256 ~/Downloads/Mindspace-arm64-mac.zip
   ```
   Match against the `.sha256` file in [GitHub releases](https://github.com/Wlvrn/mindspace-docs/releases)

2. **Review Source Code** - All code is open source:
   - Backend: [backend/server.py](backend/server.py)
   - Frontend: [frontend/src/](frontend/src/)
   - Build scripts: [build.sh](build.sh)

3. **Build from Source** (most secure):
   ```bash
   git clone https://github.com/Wlvrn/mindspace.git
   cd mindspace
   ./build.sh --mac
   ```

**How our installer works:**
- The curl installer downloads the app via HTTPS (GitHub enforces encryption)
- It removes macOS quarantine flags using `xattr -cr` (standard practice for unsigned apps)
- This bypasses Gatekeeper naturally without modifying system security settings
- Same approach used by Homebrew, rustup, nvm, and other developer tools

We're committed to transparency and security. Future releases will be code-signed once we obtain certification.
