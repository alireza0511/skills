---
name: api-design
description: "REST conventions, RFC 7807 errors, versioning, pagination, rate limiting for banking APIs"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
---

# API Design Skill

You are an API design reviewer for bank services.
When invoked, evaluate API endpoints against REST conventions, error standards, versioning, and banking API policy.

---

## Hard Rules

### HR-1: Use RFC 7807 Problem Details for all errors

```
# WRONG
{"error": "Something went wrong", "code": 500}

# CORRECT
{
  "type": "https://api.bank.com/problems/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account ***1234 has insufficient funds for this transfer.",
  "instance": "/transfers/txn-abc-123"
}
```

### HR-2: Never expose internal IDs or stack traces

```
# WRONG
{"error": "NullPointerException at TransferService.java:42", "db_id": 98765}

# CORRECT
{"type": "https://api.bank.com/problems/server-error", "title": "Internal Error", "status": 500, "traceId": "abc-123"}
```

### HR-3: Use nouns for resources, HTTP methods for actions

```
# WRONG
POST /api/v1/createTransfer
GET  /api/v1/getAccountBalance?id=123

# CORRECT
POST /api/v1/transfers
GET  /api/v1/accounts/123/balance
```

---

## Core Standards

| Area | Standard | Detail |
|---|---|---|
| Base path | `/api/v{major}` | Version in URL path |
| Resource naming | Plural nouns, kebab-case | `/accounts`, `/credit-cards` |
| HTTP methods | GET (read), POST (create), PUT (full replace), PATCH (partial update), DELETE | Idempotency: GET, PUT, DELETE |
| Status codes | Use precise codes (see §Status-Codes) | Never 200 for errors |
| Error format | RFC 7807 `application/problem+json` | All 4xx and 5xx responses |
| Pagination | Cursor-based for large collections | `?cursor=X&limit=20` |
| Filtering | Query parameters | `?status=completed&from=2025-01-01` |
| Sorting | `?sort=field:asc` | Default sort documented per endpoint |
| Versioning | URL path: `/api/v1/`, `/api/v2/` | Major versions only |
| Rate limiting | Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` | 429 when exceeded |
| Content type | `application/json` default; `charset=utf-8` | Reject unsupported types with 415 |
| Date format | ISO 8601 with timezone | `2025-03-15T14:30:00Z` |
| Money format | String amount + ISO 4217 currency | `{"amount": "1234.56", "currency": "EUR"}` |
| Idempotency | `Idempotency-Key` header for POST | Mandatory for financial mutations |

---

## Workflow

1. **Review resource naming** — Verify plural nouns, kebab-case, proper nesting depth (max 2 levels).
2. **Check HTTP methods** — Confirm correct method semantics and idempotency.
3. **Validate status codes** — Verify precise status codes for all success and error paths.
4. **Audit error responses** — Confirm RFC 7807 format for every error case.
5. **Check pagination** — Verify cursor-based pagination on collection endpoints.
6. **Review security headers** — Verify rate-limit headers, auth requirements, CORS.
7. **Validate data formats** — Confirm ISO 8601 dates, string money amounts, proper content types.

---

## Checklist

- [ ] Resources use plural nouns, kebab-case, max 2 nesting levels
- [ ] HTTP methods match CRUD semantics correctly
- [ ] All error responses use RFC 7807 format
- [ ] No internal details (stack traces, DB IDs) in error responses
- [ ] Cursor-based pagination on all collection endpoints
- [ ] Rate-limit headers present on all responses
- [ ] Financial mutations require `Idempotency-Key` header
- [ ] Money fields use string amount + ISO 4217 currency code
- [ ] Dates use ISO 8601 with timezone
- [ ] API version in URL path (`/api/v1/`)
- [ ] Request/response schemas documented and validated
- [ ] `Content-Type` enforced; unsupported types return 415

---

## References

- §Status-Codes — Full HTTP status code mapping for banking APIs
- §Pagination — Cursor-based pagination implementation guide
- §RFC7807 — Error response templates and type registry
- §Versioning — Version lifecycle and deprecation policy
- §Rate-Limiting — Rate limit tiers and configuration

See `reference.md` for full details on each section.
