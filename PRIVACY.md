# Privacy Policy

**Last Updated: December 30, 2025**

## Overview

Mindspace is a privacy-first, local-first chat application designed to give you complete control over your data. This privacy policy explains how your data is handled when using Mindspace.

## Core Privacy Principles

### 1. Local-First Architecture
- **All data stays on your machine** - Conversations, messages, and settings are stored in your local PostgreSQL database
- **No cloud storage** - We do not store, transmit, or backup your data to any external servers
- **No user accounts** - No registration, no email collection, no user tracking
- **No analytics or telemetry** - We don't collect usage statistics or send telemetry data

### 2. Third-Party Data Sharing

Mindspace only shares data with third parties **when you explicitly enable features that require it**:

#### AI Model Providers
When you configure an AI provider (Anthropic, OpenAI, etc.), your:
- Chat messages
- System prompts
- File attachments

are sent to your chosen provider to generate responses. Each provider has their own privacy policy:
- [Anthropic Privacy Policy](https://www.anthropic.com/legal/privacy)
- [OpenAI Privacy Policy](https://openai.com/policies/privacy-policy)
- [Google AI Privacy Policy](https://policies.google.com/privacy)

**Local models (Ollama)**: When using Ollama, all processing happens on your machine. No data leaves your computer.

#### Web Search (Optional Feature)
When you **enable web search** in settings, search queries may be sent to:

- **DuckDuckGo** (Default) - Privacy-focused search with no user tracking. [DuckDuckGo Privacy Policy](https://duckduckgo.com/privacy)
- **Brave Search** (Optional) - Privacy-focused search requiring API key. [Brave Privacy Policy](https://brave.com/privacy/)

**What is shared**:
- Search query text only
- Your IP address (sent by your browser/network)

**What is NOT shared**:
- Your conversation history
- Message content (except the specific search query)
- Personal information or identifiers

**Control**: Web search is **disabled by default**. You must explicitly enable it in Settings → Web Search.

### 3. API Keys and Credentials

- **Storage**: API keys are stored **encrypted** in your local PostgreSQL database
- **Masking**: Keys are masked in the UI (shown as `sk-...****`)
- **Transmission**: Keys are only sent to the respective service providers to authenticate API requests
- **We never see your keys**: Your API keys are never sent to us or any third party except the provider you're authenticating with

## Data Collection

### What We Collect
**Nothing.** We don't collect any data. All information stays on your machine.

### What We Don't Collect
- Personal information (name, email, phone)
- Usage analytics or telemetry
- IP addresses or device identifiers
- Conversation history or chat logs
- Crash reports or error logs

## GDPR Compliance

Mindspace is designed to be **GDPR-ready**:

- **Right to Access**: All your data is in your local database - you have full access
- **Right to Erasure**: Delete your database to erase all data
- **Right to Portability**: Export conversations to JSON/Markdown via built-in export feature
- **Data Minimization**: We only process data necessary for functionality
- **Purpose Limitation**: Data is only used for generating chat responses

### Web Search Consent
When you enable web search:
1. You are prompted with a privacy notice explaining data sharing
2. You must explicitly opt-in (default is OFF)
3. You can disable it at any time in settings
4. Search queries are only sent when the AI determines a search is needed

This consent mechanism complies with GDPR Article 6(1)(a) - consent as lawful basis for processing.

## CCPA Compliance

For California residents:

- **Categories of Personal Information**: None collected by Mindspace directly
- **Third-Party Sharing**: Only with AI providers and search APIs you explicitly enable
- **Do Not Sell**: We do not sell your personal information
- **Right to Opt-Out**: Disable AI providers or web search in settings to stop data sharing

## Security Measures

### Local Security
- **Database Security**: Use PostgreSQL authentication (default: localhost only)
- **API Key Encryption**: Keys masked in UI, encrypted at rest
- **No Network Exposure**: Backend runs on localhost by default (127.0.0.1:8000)

### Recommendations
- Use strong PostgreSQL passwords
- Don't expose the backend port to the internet
- Keep your system and dependencies updated
- Use local models (Ollama) for maximum privacy

## Children's Privacy

Mindspace does not collect any personal information and does not knowingly collect data from children under 13.

## Changes to This Policy

We will update this policy if we add features that change data handling. Check the "Last Updated" date at the top of this document.

## Open Source Transparency

Mindspace is **open source** - you can audit our code to verify our privacy claims:
- Backend: `backend/server.py`
- Frontend: `frontend/src/`
- AI OS: `ai-os/src/`

## Contact

For privacy questions or concerns, please open an issue on our [GitHub repository](https://github.com/yourusername/mindspace).

## Summary

**Your data, your control**:
- ✅ Everything stored locally
- ✅ No user tracking
- ✅ No telemetry
- ✅ Optional third-party features (AI providers, web search)
- ✅ Full transparency via open source code
- ✅ GDPR and CCPA ready
