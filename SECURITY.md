# Security Policy

**Last Updated: December 30, 2025**

## Security Overview

Mindspace is designed with security and privacy as core principles. This document outlines our security practices and how to report vulnerabilities.

## Security Architecture

### Local-First Design
- **No cloud dependencies** - All data stays on your machine
- **No external servers** - We don't operate any servers that store your data
- **Open source** - Full code transparency for security auditing

### Data Protection

#### At Rest
- **PostgreSQL Security**: Data stored in local PostgreSQL database
  - Use strong passwords for database authentication
  - Default configuration: localhost-only access (127.0.0.1)
  - Enable SSL/TLS for database connections if needed

- **API Key Storage**:
  - Stored in PostgreSQL `settings` table
  - Masked in UI (displayed as `sk-...****`)
  - Never logged or exposed in client-side code

#### In Transit
- **Local Communication**: Backend ↔ Frontend over HTTP (localhost)
  - For production deployments, use HTTPS reverse proxy (nginx, Caddy)

- **External APIs**: All third-party API calls use HTTPS
  - AI providers (Anthropic, OpenAI, etc.)
  - Web search APIs (DuckDuckGo, Brave)

### Authentication & Authorization

#### No User Authentication
Mindspace runs locally with no user accounts. Security relies on:
- Operating system user authentication
- PostgreSQL database authentication
- Network isolation (localhost binding)

#### API Security
- No authentication tokens required for local API
- **Warning**: Do not expose backend port (8000) to the internet without authentication

### Input Validation

- **SQL Injection Prevention**: Using parameterized queries via asyncpg
- **XSS Prevention**: React automatically escapes user input
- **Command Injection**: No shell commands executed with user input
- **File Upload Validation**:
  - Size limits enforced
  - Content type validation
  - No executable file uploads

### Dependencies

#### Backend (Python)
- FastAPI - Modern, security-focused web framework
- asyncpg - Parameterized queries prevent SQL injection
- httpx - Secure HTTP client for external APIs
- All dependencies listed in `requirements.txt`

#### Frontend (React)
- React 18 - Built-in XSS protection
- shadcn/ui - Security-audited component library
- All dependencies locked in `yarn.lock`

#### Vulnerability Scanning
We recommend:
- `pip-audit` for Python dependencies
- `npm audit` / `yarn audit` for JavaScript dependencies
- Keep dependencies updated regularly

### Network Security

#### Default Configuration (Secure)
- Backend: `http://localhost:8000` (not accessible from network)
- Frontend: `http://localhost:3000` (development server)
- PostgreSQL: `localhost:5432` (local connections only)

#### Production Deployment Recommendations
If deploying to a server:

1. **Use HTTPS**: Set up reverse proxy with SSL/TLS
   ```nginx
   server {
       listen 443 ssl;
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       location / {
           proxy_pass http://localhost:8000;
       }
   }
   ```

2. **Add Authentication**: Implement basic auth or OAuth
3. **Firewall Rules**: Restrict access to trusted IPs
4. **Environment Variables**: Never commit `.env` files

### Third-Party Security

#### AI Providers
When using cloud AI providers:
- API keys transmitted over HTTPS only
- Providers have their own security certifications (SOC 2, ISO 27001)
- Review provider security policies before use

#### Web Search APIs
- **DuckDuckGo**: No authentication, privacy-focused, no tracking
- **Brave Search**: API key required, privacy-focused
- Search queries sent over HTTPS
- No user identifiers sent with queries

### Privacy Controls

#### Tool Permissions (AI OS)
- **Permission Levels**: `read`, `write`, `execute`, `network`
- **Network Tools**: Web search requires explicit `network` permission
- **Approval System**: Dangerous tools can require user approval
- **Policy Enforcement**: Configurable via AI OS policy engine

#### Web Search Privacy
- **Default**: Disabled (opt-in only)
- **User Consent**: Privacy notice shown before enabling
- **Query Sanitization**: Option to review queries before sending
- **Provider Choice**: Select privacy-focused providers only

## Security Best Practices

### For Users

1. **Database Security**
   ```bash
   # Use strong PostgreSQL password
   ALTER USER mindspace WITH PASSWORD 'strong-random-password';
   ```

2. **API Key Hygiene**
   - Use separate API keys for different applications
   - Rotate keys periodically
   - Revoke keys when no longer needed

3. **Network Isolation**
   - Don't expose localhost services to the internet
   - Use VPN if accessing remotely

4. **Local Models for Sensitive Data**
   - Use Ollama for maximum privacy
   - No data leaves your machine

### For Developers

1. **Code Review**
   - All changes reviewed before merging
   - Security-focused code review checklist

2. **Dependency Updates**
   ```bash
   # Python
   pip-audit
   pip install --upgrade -r requirements.txt

   # JavaScript
   yarn audit
   yarn upgrade-interactive
   ```

3. **Security Testing**
   - Test for SQL injection vulnerabilities
   - Test for XSS in message rendering
   - Validate file upload restrictions
   - Test API authentication bypass

4. **Secrets Management**
   - Never commit API keys or credentials
   - Use `.env` files (gitignored)
   - Rotate test credentials regularly

## Compliance & Certifications

### Current Status
Mindspace is designed to meet industry security standards:

✅ **Privacy-First Architecture**
- Local data storage
- No telemetry or tracking
- Minimal third-party dependencies

✅ **GDPR-Ready**
- User consent for web search
- Data portability (export feature)
- Right to erasure (delete database)
- Transparent privacy policy

✅ **CCPA-Ready**
- No sale of personal information
- Clear opt-out mechanisms
- Privacy policy disclosure

✅ **Security Best Practices**
- Input validation and sanitization
- Parameterized SQL queries
- HTTPS for external APIs
- Dependency vulnerability scanning

### What We Are NOT
❌ **SOC 2 Certified** - Requires formal third-party audit ($20k-$100k+)
❌ **ISO 27001 Certified** - Requires organizational ISMS and audit
❌ **PCI DSS Compliant** - Not applicable (no payment processing)
❌ **HIPAA Compliant** - Not designed for healthcare data

**Note**: Mindspace is a local-first application. Users are responsible for their own security posture. For regulated industries (healthcare, finance), consult with compliance experts before use.

## Reporting Security Vulnerabilities

### Responsible Disclosure

If you discover a security vulnerability:

1. **Do NOT** open a public GitHub issue
2. **Email** security concerns to: [your-email@example.com] or open a private security advisory on GitHub
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### Response Timeline
- **Initial Response**: Within 48 hours
- **Triage**: Within 1 week
- **Fix & Release**: Based on severity
  - Critical: 24-48 hours
  - High: 1 week
  - Medium: 2 weeks
  - Low: Next release cycle

### Bug Bounty
Currently, we do not offer a bug bounty program. Security researchers are acknowledged in our CHANGELOG and README.

## Security Changelog

### Version 2.0.0
- Added web search with privacy controls
- Implemented consent system for network tools
- Added Brave Search as privacy-focused option
- Enhanced API key masking in UI

### Version 1.0.0
- Initial release with local-first architecture
- PostgreSQL with parameterized queries
- API key encryption and masking
- HTTPS for all external API calls

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
- [React Security Best Practices](https://react.dev/learn/security)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)

## License & Liability

Mindspace is provided "as is" under the MIT License. Users are responsible for their own security configuration and compliance requirements. See LICENSE file for full terms.
