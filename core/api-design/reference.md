# API Design — Reference

## §Status-Codes

### Success Codes

| Code | Meaning | Use Case |
|---|---|---|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST that creates a resource |
| 202 | Accepted | Async operation accepted (e.g., batch transfer queued) |
| 204 | No Content | Successful DELETE or action with no response body |

### Client Error Codes

| Code | Meaning | Banking Use Case |
|---|---|---|
| 400 | Bad Request | Malformed JSON, invalid field format |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | Valid auth but insufficient permissions |
| 404 | Not Found | Resource does not exist (or user has no access — to prevent enumeration) |
| 405 | Method Not Allowed | DELETE on an immutable resource |
| 409 | Conflict | Duplicate transfer (idempotency key collision), concurrent modification |
| 415 | Unsupported Media Type | Request body is not `application/json` |
| 422 | Unprocessable Entity | Valid JSON but business rule violation (insufficient funds, limit exceeded) |
| 429 | Too Many Requests | Rate limit exceeded |

### Server Error Codes

| Code | Meaning | Banking Use Case |
|---|---|---|
| 500 | Internal Server Error | Unhandled exception — generic message to client |
| 502 | Bad Gateway | Upstream service (payment processor) unreachable |
| 503 | Service Unavailable | Maintenance window or circuit breaker open |
| 504 | Gateway Timeout | Upstream service timeout |

### Status Code Rules

- Never return 200 with an error body.
- Use 404 instead of 403 when revealing resource existence is a security risk.
- Use 422 (not 400) for business rule violations with valid syntax.
- Always include `Retry-After` header with 429 and 503 responses.

---

## §Pagination

### Cursor-Based Pagination

Cursor-based pagination provides stable results even when data changes between requests.

### Request Format

```
GET /api/v1/accounts/123/transactions?cursor=eyJpZCI6MTIzfQ&limit=20
```

| Parameter | Type | Default | Max | Description |
|---|---|---|---|---|
| `cursor` | string | (empty = first page) | — | Opaque cursor from previous response |
| `limit` | integer | 20 | 100 | Items per page |

### Response Format

```
{
  "data": [ ... ],
  "pagination": {
    "next_cursor": "eyJpZCI6MTQzfQ",
    "has_more": true,
    "limit": 20
  }
}
```

### Rules

| Rule | Detail |
|---|---|
| Cursor is opaque | Client must not parse or construct cursors |
| Stable ordering | Results ordered by a stable, indexed field (e.g., created_at + id) |
| No total count | Do not return total count by default (expensive query) — provide separate count endpoint if needed |
| Forward-only by default | Support backward pagination only if required by UI |
| Encoding | Base64-encode cursor payload to keep it opaque |

### Offset Pagination (Discouraged)

Use only for small, stable datasets (e.g., reference data). Not suitable for transaction lists.

---

## §RFC7807

### Error Response Template

```
{
  "type": "https://api.bank.com/problems/{error-type}",
  "title": "Human-Readable Title",
  "status": 422,
  "detail": "Specific explanation of what went wrong.",
  "instance": "/api/v1/transfers/txn-abc-123",
  "traceId": "correlation-id-for-debugging"
}
```

### Field Definitions

| Field | Required | Description |
|---|---|---|
| `type` | Yes | URI reference identifying the problem type |
| `title` | Yes | Short human-readable summary (same for all instances of this type) |
| `status` | Yes | HTTP status code |
| `detail` | Yes | Human-readable explanation specific to this occurrence |
| `instance` | Recommended | URI of the specific resource/request that caused the problem |
| `traceId` | Bank policy | Correlation ID for log tracing |

### Validation Error Extension

For 400/422 with multiple field errors:

```
{
  "type": "https://api.bank.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The request contains 2 validation errors.",
  "errors": [
    {
      "field": "amount",
      "message": "Amount must be greater than 0",
      "code": "POSITIVE_REQUIRED"
    },
    {
      "field": "target_iban",
      "message": "Invalid IBAN checksum",
      "code": "INVALID_IBAN"
    }
  ]
}
```

### Error Type Registry

| Type Slug | Status | Title | When Used |
|---|---|---|---|
| `validation-error` | 422 | Validation Error | Request fields fail validation |
| `insufficient-funds` | 422 | Insufficient Funds | Transfer amount exceeds balance |
| `account-not-found` | 404 | Account Not Found | Referenced account does not exist |
| `transfer-limit-exceeded` | 422 | Transfer Limit Exceeded | Daily/per-transaction limit hit |
| `duplicate-request` | 409 | Duplicate Request | Idempotency key already processed |
| `account-locked` | 403 | Account Locked | Account frozen or restricted |
| `authentication-required` | 401 | Authentication Required | No valid token |
| `permission-denied` | 403 | Permission Denied | Insufficient role/permissions |
| `rate-limit-exceeded` | 429 | Rate Limit Exceeded | Too many requests |
| `service-unavailable` | 503 | Service Unavailable | Maintenance or downstream failure |
| `server-error` | 500 | Internal Error | Unhandled server error |

---

## §Versioning

### Version Strategy

| Decision | Choice | Rationale |
|---|---|---|
| Location | URL path (`/api/v1/`) | Explicit, cacheable, easy to route |
| Granularity | Major version only | Minor changes are backward-compatible |
| Breaking change triggers | Removing field, renaming field, changing type, removing endpoint | Non-breaking: adding optional field, new endpoint |

### Version Lifecycle

| Phase | Duration | Policy |
|---|---|---|
| Active | Indefinite (current version) | Full support, new features |
| Deprecated | Minimum 12 months after successor release | Security fixes only; `Sunset` header in responses |
| Retired | After deprecation period | Returns 410 Gone with migration guide URL |

### Deprecation Headers

```
Sunset: Sat, 01 Mar 2027 00:00:00 GMT
Deprecation: true
Link: <https://api.bank.com/docs/migration/v1-to-v2>; rel="successor-version"
```

### Non-Breaking Change Rules

| Change | Breaking? | Action |
|---|---|---|
| Add optional request field | No | Document default value |
| Add response field | No | Consumers must ignore unknown fields |
| Add new endpoint | No | Document in changelog |
| Add new enum value | Potentially | Warn consumers; add to response only |
| Remove field | Yes | New major version |
| Rename field | Yes | New major version |
| Change field type | Yes | New major version |
| Change URL structure | Yes | New major version |

---

## §Rate-Limiting

### Rate Limit Tiers

| Consumer Type | Endpoint Category | Limit | Window |
|---|---|---|---|
| Public (unauthenticated) | All | 60 requests | 1 minute |
| Authenticated user | General | 300 requests | 1 minute |
| Authenticated user | Auth endpoints (login, MFA) | 10 requests | 1 minute |
| Authenticated user | Financial mutations | 30 requests | 1 minute |
| Service-to-service | General | 1000 requests | 1 minute |
| Service-to-service | Batch operations | 100 requests | 1 minute |

### Response Headers

Every API response must include:

| Header | Description | Example |
|---|---|---|
| `X-RateLimit-Limit` | Maximum requests per window | `300` |
| `X-RateLimit-Remaining` | Requests remaining in current window | `287` |
| `X-RateLimit-Reset` | Unix timestamp when window resets | `1710532800` |

### 429 Response

```
HTTP/1.1 429 Too Many Requests
Retry-After: 30
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1710532800
Content-Type: application/problem+json

{
  "type": "https://api.bank.com/problems/rate-limit-exceeded",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "You have exceeded 300 requests per minute. Retry after 30 seconds."
}
```

### Implementation Rules

| Rule | Detail |
|---|---|
| Algorithm | Sliding window or token bucket — not fixed window |
| Key | Authenticated: user ID + endpoint category. Unauthenticated: IP + endpoint |
| Distributed | Use centralized rate-limit store (e.g., Redis) across instances |
| Graceful degradation | If rate-limit store is unavailable, allow traffic (fail open) with alert |
| Monitoring | Alert on sustained high 429 rates (may indicate attack or misconfiguration) |
