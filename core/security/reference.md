# Security — Reference

## §OWASP-Matrix

OWASP Top 10 (2021) mapped to bank-specific controls and mitigations.

| # | Category | Bank Risk | Required Mitigation |
|---|---|---|---|
| A01 | Broken Access Control | Unauthorized fund transfers, account takeover | RBAC/ABAC on every endpoint; deny-by-default; resource-level ownership checks |
| A02 | Cryptographic Failures | PII exposure, regulatory violation | AES-256 at rest; TLS 1.2+ in transit; no MD5/SHA1 for passwords; use bcrypt/argon2 |
| A03 | Injection | Data exfiltration, unauthorized queries | Parameterized queries everywhere; ORM preferred; no string concatenation in queries |
| A04 | Insecure Design | Systemic vulnerabilities | Threat modeling for new features; abuse-case analysis; security review gate |
| A05 | Security Misconfiguration | Open admin panels, verbose errors | Hardened base images; no default credentials; security headers enforced |
| A06 | Vulnerable Components | Supply chain attacks | Automated dependency scanning; SLA for patching (critical: 24h, high: 7d) |
| A07 | Auth Failures | Account takeover, credential stuffing | MFA for privileged ops; account lockout after 5 attempts; secure password policy |
| A08 | Data Integrity Failures | Tampered transactions, supply chain | Signed artifacts; integrity checks on critical data; verified CI/CD pipeline |
| A09 | Logging Failures | Undetected breaches, compliance gaps | Structured logging; audit trail for all financial ops; tamper-proof log storage |
| A10 | SSRF | Internal network scanning, metadata theft | Allowlist outbound destinations; block internal IP ranges; validate URLs server-side |

---

## §Secret-Management

### Approved Secret Storage

| Method | Use Case | Example |
|---|---|---|
| Vault (HashiCorp/cloud) | Application secrets, DB credentials | `vault.read("secret/data/payments/db")` |
| Cloud KMS | Encryption keys | `kms.decrypt(encrypted_key)` |
| CI/CD secret variables | Build-time secrets | `$CI_VARIABLE` — masked, protected |

### Rotation Policy

| Secret Type | Rotation Frequency | Automation Required |
|---|---|---|
| Database passwords | 90 days | Yes |
| API keys | 90 days | Yes |
| TLS certificates | 365 days (auto-renew at 30 days) | Yes |
| Service account tokens | 30 days | Yes |
| Encryption keys | Annual | Yes — with re-encryption plan |

### Prohibited Practices

- Secrets in source code, config files, or environment files committed to VCS
- Secrets passed as command-line arguments (visible in process lists)
- Secrets in container images or build artifacts
- Shared secrets across environments (dev/staging/prod must differ)
- Plaintext secrets in CI/CD logs

---

## §Auth-Patterns

### Authentication Requirements

| Context | Minimum Requirement |
|---|---|
| Customer login | Password + MFA (TOTP or push) |
| Internal admin | SSO + MFA + IP allowlist |
| Service-to-service | mTLS or signed JWT with short expiry (5 min) |
| API consumers | OAuth 2.0 + API key + rate limiting |
| Privileged operations (transfers, settings changes) | Step-up authentication |

### Authorization Model

Enforce RBAC with attribute-based overrides (ABAC):

```
// pseudocode — authorization check pattern
function authorize(user, resource, action):
    if not has_role(user, required_role(resource, action)):
        deny("Insufficient role")
    if not owns_resource(user, resource):
        deny("Resource ownership mismatch")
    if requires_step_up(action) and not step_up_verified(user):
        deny("Step-up auth required")
    allow()
```

### Session Management Rules

| Parameter | Value |
|---|---|
| Idle timeout | 15 minutes |
| Absolute timeout | 8 hours |
| Cookie flags | Secure, HttpOnly, SameSite=Strict |
| Token storage | Never localStorage; use HttpOnly cookies or secure session store |
| Concurrent sessions | Max 3 per user; alert on anomalous patterns |

---

## §Input-Validation

### Validation Rules by Data Type

| Data Type | Validation Rule | Max Length |
|---|---|---|
| Account number | Numeric, Luhn check where applicable | 34 |
| IBAN | ISO 13616 format, checksum validation | 34 |
| Currency amount | Decimal, max 2 decimal places, positive, max value check | — |
| Email | RFC 5322 format | 254 |
| Phone | E.164 format | 15 |
| Name | Unicode letters, spaces, hyphens, apostrophes only | 100 |
| Free text | Strip HTML, enforce max length, check encoding | context-dependent |
| File uploads | Allowlist MIME types, scan for malware, max 10 MB | — |
| Date | ISO 8601 format, reasonable range (not year 9999) | 10 |
| URL | Scheme allowlist (https only), no internal IPs, domain allowlist | 2048 |

### Validation Principles

1. **Server-side is mandatory** — Client-side validation is UX only, never a security control.
2. **Allowlist over denylist** — Define what is permitted, reject everything else.
3. **Validate early** — At the API boundary, before any processing.
4. **Canonicalize first** — Decode, normalize, then validate (prevent double-encoding attacks).
5. **Reject, do not sanitize** — Return a clear error rather than silently modifying input.

---

## §Dependency-Policy

### CVE Severity SLAs

| Severity | Remediation SLA | Action |
|---|---|---|
| Critical (CVSS 9.0+) | 24 hours | Patch or remove; block deployment if unresolved |
| High (CVSS 7.0-8.9) | 7 days | Patch; block deployment after SLA expiry |
| Medium (CVSS 4.0-6.9) | 30 days | Patch in next release cycle |
| Low (CVSS < 4.0) | 90 days | Track and patch opportunistically |

### Dependency Rules

- Pin exact versions in production (no floating ranges).
- Run automated scanning on every CI build.
- Maintain a software bill of materials (SBOM) for each service.
- Review new dependencies for license compatibility (no AGPL in proprietary services).
- Prefer well-maintained libraries (last commit < 6 months, active maintainers).

### Security Headers

All HTTP responses must include:

| Header | Value |
|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `Content-Security-Policy` | Strict policy — no `unsafe-inline`, no `unsafe-eval` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Disable unused browser features |
| `Cache-Control` | `no-store` for sensitive responses |
