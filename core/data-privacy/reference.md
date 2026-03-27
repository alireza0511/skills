# Data Privacy — Reference

## GDPR Implementation

### Data Subject Access Request (DSAR) Flow

| Step | Action | SLA | Owner |
|------|--------|-----|-------|
| 1 | Receive request (web form / email / in-app) | — | Customer |
| 2 | Verify identity (MFA or document verification) | 2 business days | Identity team |
| 3 | Log request in DSAR tracker | Same day | Privacy team |
| 4 | Gather data from all systems | 10 business days | Engineering |
| 5 | Review data for third-party PII (redact if present) | 5 business days | Privacy team |
| 6 | Deliver response to data subject | Within 30 calendar days | Privacy team |
| 7 | Log completion and archive request | Same day | Privacy team |

### Right to Erasure — Deletion Cascade

```
Erasure Request Pipeline
========================

1. Receive verified erasure request
2. Check legal hold status
   - If legal hold → deny with explanation; log denial
   - If no legal hold → proceed
3. Identify all systems containing subject's data:
   | System              | Data Type        | Deletion Method         |
   |---------------------|------------------|-------------------------|
   | Primary database    | Account profile  | Hard delete + vacuum    |
   | Search index        | Indexed PII      | Remove from index       |
   | Data warehouse      | Analytics data   | Anonymize (replace PII) |
   | Backup systems      | Full backups     | Mark for expiry; crypto-erase on next rotation |
   | Third-party systems | Shared PII       | Send deletion request via API/email |
   | Logs                | Access logs      | Anonymize userId        |
4. Execute deletions across all systems
5. Verify deletion (spot-check query returns empty)
6. Send confirmation to data subject
7. Log completion with timestamp and verification
```

### Data Portability Export Format

```json
{
  "export_metadata": {
    "subject_id": "user-12345",
    "export_date": "2026-03-27T10:00:00Z",
    "format_version": "1.0",
    "requested_by": "data subject",
    "systems_included": ["core-banking", "payments", "notifications"]
  },
  "personal_data": {
    "profile": {
      "full_name": "Jane Doe",
      "email": "jane.doe@example.com",
      "phone": "+1-555-0100",
      "date_of_birth": "1990-01-15",
      "address": {
        "street": "123 Main St",
        "city": "Springfield",
        "postal_code": "62701",
        "country": "US"
      }
    },
    "accounts": [
      {
        "account_number": "****1234",
        "type": "checking",
        "opened_date": "2020-03-15",
        "status": "active"
      }
    ],
    "transactions": [
      {
        "date": "2026-03-25",
        "description": "Transfer to Savings",
        "amount": -500.00,
        "currency": "USD"
      }
    ],
    "consents": [
      {
        "purpose": "marketing_email",
        "granted": true,
        "date": "2024-06-01",
        "expires": null
      }
    ]
  }
}
```

## Data Masking Configuration

### Masking Rules by Data Type

| Data Type | Masking Strategy | Input | Output |
|-----------|-----------------|-------|--------|
| Full name | First initial + asterisks | `Jane Doe` | `J*** D**` |
| Email | Partial local + domain masked | `jane.doe@bank.com` | `j***@***.com` |
| Phone | Preserve country code + last 4 | `+1-555-867-5309` | `+1-***-***-5309` |
| SSN/National ID | Last 4 only | `123-45-6789` | `***-**-6789` |
| Date of birth | Day only | `1990-01-15` | `****-**-15` |
| Address | City + country only | `123 Main St, Springfield, US` | `Springfield, US` |
| Account number | Last 4 digits | `9876543210001234` | `****1234` |
| Card number (PAN) | Last 4 digits (PCI compliant) | `4111-1111-1111-1234` | `****-****-****-1234` |
| IP address | Last octet only | `192.168.1.100` | `***.***.***.100` |

### Masking Configuration Template

```yaml
# masking-rules.yaml — used by data masking pipeline
version: "1.0"
rules:
  - table: customers
    columns:
      - name: full_name
        strategy: partial
        config: { show_first: 1, mask_char: "*" }
      - name: email
        strategy: email_mask
      - name: phone
        strategy: preserve_last
        config: { visible_digits: 4 }
      - name: national_id
        strategy: preserve_last
        config: { visible_digits: 4 }
      - name: date_of_birth
        strategy: preserve_day
      - name: address_line_1
        strategy: redact
      - name: address_city
        strategy: preserve

  - table: accounts
    columns:
      - name: account_number
        strategy: preserve_last
        config: { visible_digits: 4 }

  - table: transactions
    columns:
      - name: description
        strategy: preserve  # not PII
      - name: counterparty_name
        strategy: partial
        config: { show_first: 1, mask_char: "*" }
```

### Synthetic Data Generation

For development and testing, prefer synthetic data over masked production data:

| Approach | When to Use | Pros | Cons |
|----------|------------|------|------|
| Synthetic generation | New features, load testing | Zero risk of PII leak; repeatable | May miss edge cases |
| Masked production | Integration testing, debugging | Realistic data distribution | Risk if masking fails; slower |
| Anonymized subset | Analytics, ML training | Real patterns preserved | Must verify irreversibility |

## Encryption Implementation Guide

### Key Management Architecture

```
Key Hierarchy
=============

Master Key (HSM/KMS)
  └── Data Encryption Key (DEK) — per service/table
       └── Encrypted data

Process:
1. Service requests DEK from KMS
2. KMS returns DEK encrypted with master key
3. Service decrypts DEK in memory
4. Service encrypts/decrypts data with DEK
5. DEK never stored in plain text on disk
6. DEK rotated every 90 days (automatic)
```

### Encryption at Rest — Implementation Pattern

```
// Pseudocode — encrypt before storage, decrypt after retrieval

// WRITE PATH
function saveCustomer(customer):
    encryptedRecord = {
        id: customer.id,                          // not encrypted (primary key)
        name: encrypt(customer.name, dek),        // encrypted
        email: encrypt(customer.email, dek),      // encrypted
        email_hash: hmac(customer.email, hmacKey), // searchable hash
        classification: "restricted",              // metadata, not encrypted
        encrypted_at: now(),
        key_version: dek.version
    }
    db.insert(encryptedRecord)

// READ PATH
function getCustomer(id):
    record = db.get(id)
    return {
        id: record.id,
        name: decrypt(record.name, getKey(record.key_version)),
        email: decrypt(record.email, getKey(record.key_version)),
    }

// SEARCH PATH (by email)
function findByEmail(email):
    hash = hmac(email, hmacKey)
    record = db.findByEmailHash(hash)
    return decrypt(record, ...)
```

### TLS Configuration

| Setting | Minimum | Recommended |
|---------|---------|-------------|
| Protocol | TLS 1.2 | TLS 1.3 |
| Cipher suites | AES-128-GCM, AES-256-GCM | AES-256-GCM with ECDHE |
| Certificate | 2048-bit RSA | 4096-bit RSA or P-256 ECDSA |
| Certificate rotation | Annual | 90 days (automated) |
| HSTS | Enabled | `max-age=31536000; includeSubDomains` |
| Certificate pinning | Mobile apps | Mobile apps (with backup pins) |

## Breach Response Procedure

### Timeline

| Time | Action | Owner |
|------|--------|-------|
| T+0 | Breach detected (automated alert or report) | Security team |
| T+1h | Initial assessment: scope, affected data, affected subjects | Security + Privacy |
| T+4h | Containment: isolate affected systems, revoke compromised credentials | Security team |
| T+24h | Full impact analysis: number of subjects, data types, risk level | Privacy team |
| T+48h | Prepare notification: regulator notice, subject notice | Legal + Privacy |
| T+72h | **Regulatory notification deadline (GDPR)** | Privacy officer |
| T+72h+ | Subject notification (if high risk to rights/freedoms) | Privacy team |
| T+2w | Root cause analysis complete | Security team |
| T+4w | Remediation plan implemented | Engineering |
| T+4w | Post-incident review and process updates | All |

### Breach Notification Template (Regulatory)

```
Data Breach Notification
========================

To:           [Supervisory Authority]
From:         [Organization], Data Protection Officer
Date:         [YYYY-MM-DD]
Reference:    [Internal incident ID]

1. Nature of the breach:
   [Description: what happened, when, how discovered]

2. Categories and approximate number of data subjects:
   [e.g., 5,000 retail banking customers]

3. Categories of personal data:
   [e.g., names, email addresses, account numbers (last 4 digits)]

4. Likely consequences:
   [e.g., potential phishing risk; no financial data exposed]

5. Measures taken or proposed:
   [e.g., credentials rotated, affected accounts flagged,
    customers notified, monitoring enhanced]

6. Contact:
   Data Protection Officer: [name, email, phone]
```

## Privacy Impact Assessment (PIA) Template

| Section | Content |
|---------|---------|
| Project name | [Name] |
| Date | [YYYY-MM-DD] |
| Assessor | [Name, role] |
| Data collected | [List all personal data elements] |
| Purpose | [Why each element is needed — data minimization check] |
| Legal basis | [Consent / Contract / Legitimate interest / Legal obligation] |
| Storage location | [Where data is stored; data residency] |
| Access controls | [Who can access; what authorization is required] |
| Retention | [How long; what happens after] |
| Third-party sharing | [Who receives data; DPA in place?] |
| Data subject rights | [How each right is supported] |
| Risk assessment | [Likelihood × Impact for identified risks] |
| Mitigations | [Controls to reduce identified risks] |
| Approval | [Privacy officer sign-off] |

## Audit Log Schema

```json
{
  "event_id": "evt-20260327-001",
  "timestamp": "2026-03-27T14:30:00Z",
  "actor": {
    "user_id": "emp-12345",
    "role": "customer-service",
    "ip_address": "10.0.1.50",
    "session_id": "sess-abc123"
  },
  "action": "READ",
  "resource": {
    "type": "customer_profile",
    "id": "cust-67890",
    "classification": "restricted"
  },
  "fields_accessed": ["full_name", "email", "account_number"],
  "justification": "Customer called to update address — ticket CS-45678",
  "result": "success",
  "source_system": "customer-service-portal",
  "tamper_proof_hash": "sha256:a1b2c3..."
}
```
