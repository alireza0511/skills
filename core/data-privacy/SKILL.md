---
name: data-privacy
description: Data privacy standards — PII handling, data classification, GDPR compliance, encryption, masking, retention policy for bank services
allowed-tools: Read, Edit, Write, Glob, Grep
---

# Data Privacy Standards

You are a data privacy enforcer for bank services. When invoked, audit code and configurations for PII exposure, data classification violations, encryption gaps, and regulatory compliance.

## Hard Rules

### Never log PII or sensitive data

```
// WRONG — logging customer data
log.info("Processing transfer for user: " + email + ", amount: " + amount)

// CORRECT — log only identifiers and metadata
log.info("Processing transfer", { userId: hashedId, transactionId: txnId })
```

### Never store PII in plain text — encrypt at rest

```
// WRONG — plain text storage
db.save({ name: "John Doe", ssn: "123-45-6789" })

// CORRECT — encrypt sensitive fields before storage
db.save({ name: encrypt(name), ssn: encrypt(ssn), ssn_hash: hash(ssn) })
```

### Never expose real PII in non-production environments

```
// WRONG — copying production data to staging
copy-db --from=prod --to=staging

// CORRECT — use masked/synthetic data
copy-db --from=prod --to=staging --mask-pii --config=masking-rules.yaml
```

### Never transmit PII without TLS

```
// WRONG — HTTP endpoint accepting sensitive data
endpoint: http://api.bank.internal/customer

// CORRECT — TLS enforced; HSTS enabled
endpoint: https://api.bank.internal/customer
// + HSTS header: Strict-Transport-Security: max-age=31536000
```

## Data Classification

| Level | Label | Description | Examples |
|-------|-------|-------------|----------|
| 1 | **Public** | No restrictions | Marketing content, public API docs |
| 2 | **Internal** | Internal use only | Internal policies, team directories |
| 3 | **Confidential** | Business-sensitive | Financial reports, contracts, customer lists |
| 4 | **Restricted** | Regulated / highest sensitivity | PII, credentials, card data, health records |

### Handling Requirements by Classification

| Requirement | Public | Internal | Confidential | Restricted |
|-------------|--------|----------|--------------|------------|
| Encryption at rest | No | No | Yes | Yes |
| Encryption in transit | Recommended | Yes | Yes | Yes (TLS 1.2+) |
| Access control | None | Role-based | Need-to-know | Need-to-know + MFA |
| Logging access | No | No | Yes | Yes (tamper-proof) |
| Data masking (non-prod) | No | No | Yes | Yes |
| Retention policy | None | Yes | Yes | Yes (strict) |
| Backup encryption | No | No | Yes | Yes |
| Disposal method | None | Standard delete | Secure delete | Cryptographic erasure |

## PII Inventory

| Data Element | Classification | Storage | Masking Rule |
|-------------|---------------|---------|-------------|
| Full name | Restricted | Encrypted | First initial + `***` |
| Email address | Restricted | Encrypted | `j***@***.com` |
| Phone number | Restricted | Encrypted | `+1******1234` |
| National ID / SSN | Restricted | Encrypted + hashed | `***-**-6789` |
| Date of birth | Restricted | Encrypted | `****-**-DD` |
| Home address | Restricted | Encrypted | City only |
| Account number | Restricted | Encrypted + tokenized | `****1234` |
| Card number (PAN) | Restricted (PCI) | Tokenized | `****-****-****-1234` |
| IP address | Confidential | Hashed | `***.***.***.123` |
| Device ID | Confidential | Hashed | Truncated |
| Transaction amount | Confidential | Encrypted | No masking (not PII) |
| Account balance | Confidential | Encrypted | No masking (not PII) |

## Encryption Standards

| Context | Standard | Minimum |
|---------|----------|---------|
| At rest (database) | AES-256-GCM | AES-256 |
| At rest (file storage) | AES-256-GCM | AES-256 |
| In transit | TLS 1.3 preferred | TLS 1.2 |
| Key management | HSM or cloud KMS | Managed KMS |
| Key rotation | Automated | Every 90 days (restricted data) |
| Hashing (passwords) | bcrypt / Argon2id | bcrypt cost ≥ 12 |
| Hashing (search index) | HMAC-SHA-256 | — |
| Tokenization (PAN) | PCI-compliant vault | — |

## Data Retention Policy

| Data Category | Retention Period | After Expiry |
|---------------|-----------------|--------------|
| Transaction records | 7 years | Archive → cryptographic erasure |
| Customer PII | Duration of relationship + 5 years | Cryptographic erasure |
| Access logs | 2 years | Secure delete |
| Authentication logs | 1 year | Secure delete |
| Session data | 24 hours after session end | Automatic delete |
| Failed login attempts | 90 days | Automatic delete |
| Marketing consent | Duration of consent + 1 year | Secure delete |
| Backup data | 90 days | Automatic expiry |

## Regulatory Compliance

| Regulation | Scope | Key Requirements |
|-----------|-------|------------------|
| GDPR | EU data subjects | Consent, right to erasure, data portability, breach notification (72h) |
| Local data protection | National jurisdiction | Data residency, local storage requirements |
| PCI DSS | Card data | Tokenization, network segmentation, access logging |
| SOX | Financial reporting | Audit trails, access controls, data integrity |

### Data Subject Rights (GDPR)

| Right | Implementation |
|-------|---------------|
| Access | API to export user's data in machine-readable format |
| Rectification | API to update personal data |
| Erasure | Automated deletion pipeline; cascades across all systems |
| Portability | Export in JSON/CSV; delivered within 30 days |
| Restriction | Flag to halt processing while dispute is resolved |
| Objection | Opt-out mechanism for marketing/profiling |

For detailed GDPR implementation patterns, read `core/data-privacy/reference.md` § GDPR Implementation.

## Core Standards

| Standard | Requirement |
|----------|-------------|
| Classification | Every data field must have an assigned classification level |
| Encryption at rest | All confidential and restricted data encrypted (AES-256) |
| Encryption in transit | TLS 1.2+ for all services; TLS 1.3 preferred |
| Access control | Restricted data requires need-to-know + MFA |
| Audit logging | All access to restricted data logged with tamper-proof trail |
| Data masking | Non-production environments use masked/synthetic data only |
| Retention | Automated enforcement; data deleted/archived per retention schedule |
| Breach response | Detection → containment → notification within 72 hours |
| Privacy by design | Data minimization in all new features; collect only what is needed |
| Vendor assessment | Third-party data processors assessed for privacy compliance |

## Workflow

1. **Classify data** — identify all data elements; assign classification levels.
2. **Audit storage** — verify encryption at rest for confidential/restricted data.
3. **Audit transit** — verify TLS enforcement on all endpoints handling sensitive data.
4. **Audit logging** — confirm no PII in logs; access logs exist for restricted data.
5. **Audit non-prod** — verify masking rules applied; no real PII in dev/staging.
6. **Check retention** — verify automated retention enforcement; no expired data persisted.

## Checklist

- [ ] All data fields classified (public/internal/confidential/restricted)
- [ ] Restricted data encrypted at rest (AES-256)
- [ ] TLS 1.2+ enforced on all endpoints
- [ ] No PII in application logs
- [ ] Non-production environments use masked/synthetic data
- [ ] Retention policy automated; expired data cleaned up
- [ ] Access to restricted data requires need-to-know + MFA
- [ ] Audit trail for all restricted data access
- [ ] Data subject rights APIs implemented (if GDPR applies)
- [ ] Breach notification procedure documented and tested
- [ ] Third-party data processors assessed

For implementation patterns and masking configurations, read `core/data-privacy/reference.md`.
