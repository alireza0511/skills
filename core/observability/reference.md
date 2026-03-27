# Observability — Reference

## §Log-Schema

### Required Fields

Every log entry must include:

| Field | Type | Description | Example |
|---|---|---|---|
| `timestamp` | ISO 8601 UTC | When the event occurred | `2025-03-15T14:30:00.123Z` |
| `level` | string | Log level | `INFO` |
| `service` | string | Service name | `payment-service` |
| `trace_id` | string | W3C trace ID | `4bf92f3577b34da6a3ce929d0e0e4736` |
| `span_id` | string | Current span ID | `00f067aa0ba902b7` |
| `message` | string | Human-readable event description | `Transfer completed` |
| `logger` | string | Logger name / component | `transfer.service` |

### Optional Contextual Fields

| Field | Type | When to Include |
|---|---|---|
| `user_id` | string | Authenticated request |
| `request_id` | string | HTTP request handling |
| `operation` | string | Business operation name |
| `duration_ms` | number | Operation timing |
| `error_code` | string | Error scenarios |
| `error_message` | string | Error scenarios (redacted) |
| `http_method` | string | HTTP request handling |
| `http_path` | string | HTTP request handling |
| `http_status` | number | HTTP response |

### Log Level Usage

| Level | Meaning | Action Required | Example |
|---|---|---|---|
| ERROR | Operation failed, needs attention | Alert + investigate | Payment processing failure, DB connection lost |
| WARN | Degraded but functional | Monitor + investigate if recurring | Retry succeeded, approaching rate limit, slow query |
| INFO | Normal business events | None — audit/tracing | Transfer completed, user logged in, account created |
| DEBUG | Developer diagnostics | None — disabled in prod by default | Cache hit/miss, query parameters, intermediate state |

### Log Entry Example

```json
{
  "timestamp": "2025-03-15T14:30:00.123Z",
  "level": "INFO",
  "service": "payment-service",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "message": "Transfer completed",
  "operation": "transfer.execute",
  "user_id": "usr-abc-123",
  "transfer_id": "txn-def-456",
  "amount_currency": "EUR",
  "duration_ms": 234
}
```

Note: `amount_currency` is logged but **not** the amount value itself.

---

## §PII-Redaction

### Redaction Rules

| Data Type | Redaction Method | Example Input | Example Output |
|---|---|---|---|
| Full name | Replace entirely | `John Smith` | `[REDACTED]` |
| Email | Mask local part | `john@example.com` | `j***@example.com` |
| IBAN | Show last 4 | `DE89370400440532013000` | `DE89****3000` |
| Card number | Show last 4 | `4111111111111111` | `****1111` |
| Phone number | Show last 4 | `+31612345678` | `****5678` |
| Account number | Show last 4 | `0532013000` | `****3000` |
| IP address | Full redaction or hash | `192.168.1.1` | `[IP_HASH:abc123]` |
| Date of birth | Full redaction | `1990-05-15` | `[REDACTED]` |
| Address | Full redaction | `123 Main St` | `[REDACTED]` |
| National ID / BSN | Full redaction | `123456789` | `[REDACTED]` |

### Redaction Implementation Rules

| Rule | Detail |
|---|---|
| Server-side only | Redaction happens at the logging layer, not in business logic |
| Allowlist approach | Only explicitly allowed fields pass through unredacted |
| Nested objects | Recursively scan all fields, including nested JSON |
| Error messages | Exceptions may contain PII — redact before logging |
| Query parameters | Strip PII from logged URL query strings |
| Request bodies | Never log full request/response bodies for financial endpoints |

### Fields That Are Safe to Log

| Field | Rationale |
|---|---|
| `user_id` (internal UUID) | Not PII — internal identifier |
| `account_id` (internal UUID) | Not PII — internal identifier |
| `transaction_id` | Not PII — internal identifier |
| `currency_code` | Not sensitive |
| `operation_type` | Not sensitive |
| `http_status` | Not sensitive |
| `error_code` | Not sensitive (if codes don't encode PII) |

---

## §RED-Metrics

### The RED Method

| Metric | What It Measures | Why It Matters |
|---|---|---|
| **R**ate | Requests per second | Traffic volume, capacity planning |
| **E**rrors | Errors per second (and error rate %) | Reliability, user impact |
| **D**uration | Latency distribution (p50, p95, p99) | Performance, user experience |

### Metric Definitions for Banking Services

| Metric Name | Type | Labels | Description |
|---|---|---|---|
| `{svc}_requests_total` | Counter | `method`, `path`, `status` | Total requests |
| `{svc}_request_errors_total` | Counter | `method`, `path`, `error_code` | Total error responses (4xx + 5xx) |
| `{svc}_request_duration_seconds` | Histogram | `method`, `path` | Request duration distribution |
| `{svc}_inflight_requests` | Gauge | `method` | Currently processing requests |

### Business Metrics for Banking

| Metric Name | Type | Labels | Description |
|---|---|---|---|
| `{svc}_transfers_total` | Counter | `type`, `status` | Transfers processed |
| `{svc}_transfer_amount_total` | Counter | `currency` | Total transfer volume (aggregated, no individual amounts) |
| `{svc}_auth_attempts_total` | Counter | `method`, `result` | Authentication attempts |
| `{svc}_session_active` | Gauge | — | Currently active sessions |

### Label Rules

| Rule | Detail |
|---|---|
| Low cardinality | Never use user ID, account ID, or transaction ID as labels |
| No PII | Never include PII in metric labels |
| Consistent naming | `snake_case`, `{service}_{operation}_{unit}` |
| Unit suffix | `_seconds`, `_bytes`, `_total` — always include unit |

### Histogram Buckets

| Endpoint Type | Suggested Buckets (seconds) |
|---|---|
| Synchronous API | 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10 |
| Database query | 0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1 |
| External API call | 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30 |
| Batch processing | 1, 5, 10, 30, 60, 120, 300 |

---

## §Tracing

### W3C Trace Context

All services must propagate the `traceparent` header:

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
              version-trace_id-parent_id-flags
```

### Span Naming Convention

| Span Type | Format | Example |
|---|---|---|
| HTTP server | `{HTTP_METHOD} {route}` | `POST /api/v1/transfers` |
| HTTP client | `{HTTP_METHOD} {service}:{route}` | `GET account-service:/accounts/123` |
| Database | `{operation} {table}` | `SELECT accounts` |
| Message publish | `{topic} send` | `transfer-events send` |
| Message consume | `{topic} receive` | `transfer-events receive` |
| Internal | `{component}.{operation}` | `transfer-service.validate` |

### Required Span Attributes

| Attribute | All Spans | HTTP Spans | DB Spans |
|---|---|---|---|
| `service.name` | Yes | Yes | Yes |
| `operation` | Yes | Yes | Yes |
| `status` | Yes | Yes | Yes |
| `http.method` | — | Yes | — |
| `http.status_code` | — | Yes | — |
| `http.url` (redacted) | — | Yes | — |
| `db.system` | — | — | Yes |
| `db.operation` | — | — | Yes |

### Trace Context Propagation

| Boundary | Mechanism |
|---|---|
| HTTP → HTTP | `traceparent` header |
| HTTP → Message queue | Message header/attribute |
| Message queue → HTTP | Extract from message, set as parent |
| Scheduled jobs | Generate new trace, link to trigger if applicable |

---

## §Alerting

### Alert Tier Definitions

| Tier | Severity | Response Time | Notification Channel | Example |
|---|---|---|---|---|
| P1 | Critical | 15 minutes | PagerDuty + phone | Payment processing down, data breach indicator |
| P2 | High | 1 hour | PagerDuty + chat | Error rate > 5%, p99 > 10s |
| P3 | Medium | Business hours | Chat channel | Error rate > 1%, p99 > 2s, disk > 80% |
| P4 | Low | Next sprint | Ticket | Deprecation warnings, non-critical CVEs |

### Standard Alert Rules

| Alert | Condition | Tier | For Duration |
|---|---|---|---|
| High error rate | Error rate > 5% | P2 | 5 minutes |
| Elevated error rate | Error rate > 1% | P3 | 10 minutes |
| High latency | p99 > 5s | P2 | 5 minutes |
| Elevated latency | p99 > 2s | P3 | 10 minutes |
| Service down | Zero successful requests | P1 | 2 minutes |
| Disk pressure | Disk usage > 80% | P3 | 15 minutes |
| Certificate expiry | TLS cert expires in < 14 days | P3 | — |
| Auth failure spike | Auth failures > 10x baseline | P2 | 5 minutes |
| Queue depth | Message backlog > threshold | P2 | 10 minutes |

### Alert Message Template

```
[P{tier}] {service}: {alert_name}
Condition: {metric} {operator} {threshold} (current: {value})
Duration: {duration}
Dashboard: {dashboard_url}
Runbook: {runbook_url}
```

### Alert Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Alerting on every error | Alert fatigue | Alert on error *rate*, not individual errors |
| No runbook link | Responder wastes time investigating | Every alert links to a runbook |
| Flapping alerts | Noise from threshold oscillation | Add hysteresis (for-duration) or rate-of-change checks |
| Alerting on causes, not symptoms | Too many alerts for one incident | Alert on user-facing symptoms (latency, errors) |

---

## §Audit-Trail

### Audit Event Schema

Financial operations must produce audit events separate from application logs.

| Field | Type | Required | Description |
|---|---|---|---|
| `event_id` | UUID | Yes | Unique event identifier |
| `timestamp` | ISO 8601 UTC | Yes | When the event occurred |
| `event_type` | string | Yes | `TRANSFER_INITIATED`, `ACCOUNT_OPENED`, etc. |
| `actor_id` | string | Yes | Who performed the action |
| `actor_type` | string | Yes | `CUSTOMER`, `EMPLOYEE`, `SYSTEM` |
| `resource_type` | string | Yes | `ACCOUNT`, `TRANSFER`, `LOAN` |
| `resource_id` | string | Yes | ID of affected resource |
| `action` | string | Yes | `CREATE`, `UPDATE`, `DELETE`, `APPROVE`, `REJECT` |
| `result` | string | Yes | `SUCCESS`, `FAILURE`, `DENIED` |
| `ip_address` | string (hashed) | Yes | Client IP (hashed for privacy) |
| `changes` | object | When applicable | Before/after values (PII redacted) |
| `reason` | string | When applicable | Business reason or denial reason |

### Audit Event Types

| Event Type | Trigger | Retention |
|---|---|---|
| `ACCOUNT_OPENED` | New account creation | 10 years |
| `ACCOUNT_CLOSED` | Account closure | 10 years |
| `TRANSFER_INITIATED` | Fund transfer request | 7 years |
| `TRANSFER_COMPLETED` | Fund transfer settlement | 7 years |
| `LOGIN_SUCCESS` | Successful authentication | 2 years |
| `LOGIN_FAILURE` | Failed authentication attempt | 2 years |
| `PERMISSION_CHANGED` | Role or access modification | 10 years |
| `SETTINGS_CHANGED` | Account settings update | 7 years |
| `STATEMENT_GENERATED` | Statement download/generation | 2 years |

### Audit Storage Rules

| Rule | Detail |
|---|---|
| Tamper-proof | Write-once storage; append-only log |
| Separate from app logs | Dedicated audit log store |
| Encrypted at rest | AES-256 |
| Access controlled | Read access limited to compliance and security teams |
| Retention | Per regulatory requirements (see event types above) |
| Searchable | Indexed by actor, resource, event type, date range |
