---
name: error-handling
description: "Error taxonomy, user-facing messages, retry/backoff, circuit breaker patterns for banking services"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
---

# Error Handling Skill

You are an error handling reviewer for bank services.
When invoked, evaluate error classification, user messaging, retry logic, and resilience patterns.

---

## Hard Rules

### HR-1: Never expose internal details in user-facing errors

```
# WRONG
return error("NullPointerException in TransferService.java:42, DB connection pool exhausted")

# CORRECT
return error(
    user_message="We could not process your transfer. Please try again shortly.",
    internal_code="TRANSFER_PROCESSING_FAILED",
    trace_id="abc-123"
)
```

### HR-2: Always classify errors — never use generic catch-all

```
# WRONG
try:
    process_transfer()
catch Exception as e:
    return "Something went wrong"

# CORRECT
try:
    process_transfer()
catch InsufficientFundsError:
    return client_error("Insufficient funds for this transfer.")
catch ExternalServiceError:
    return server_error("Transfer service temporarily unavailable. Retrying.")
catch ValidationError as e:
    return validation_error(e.field_errors)
```

### HR-3: Retries must use exponential backoff with jitter

```
# WRONG — fixed interval, no limit
while not success:
    retry(operation)
    sleep(1)

# CORRECT — exponential backoff, jitter, max retries
for attempt in range(1, max_retries + 1):
    try:
        result = operation()
        return result
    catch RetryableError:
        delay = min(base_delay * 2^attempt, max_delay) + random_jitter()
        sleep(delay)
raise MaxRetriesExceeded()
```

---

## Core Standards

| Area | Standard | Detail |
|---|---|---|
| Error taxonomy | Classify every error into a defined category | See §Error-Taxonomy |
| User messages | Friendly, actionable, no internal details | See §User-Messages |
| Internal logging | Full context: stack trace, request data (PII-redacted), error code | Structured JSON |
| Retry policy | Exponential backoff with jitter; max 3 retries for transient errors | Never retry non-retryable errors |
| Circuit breaker | Protect against cascading failures from downstream services | Open after 5 failures in 60s |
| Timeout | Every external call must have a timeout | Connect: 3s, read: 10s (max) |
| Idempotency | Retried operations must be idempotent | Idempotency key for financial mutations |
| Error codes | Internal enum/constant — never magic strings | `INSUFFICIENT_FUNDS`, not `"err_001"` |
| Graceful degradation | Non-critical feature failure must not block critical flows | Feature flags, fallback values |
| Dead letter queue | Failed async messages go to DLQ after max retries | Alert on DLQ growth |

---

## Error Categories

| Category | Retryable | User Action | HTTP Status |
|---|---|---|---|
| Validation error | No | Fix input and resubmit | 400 / 422 |
| Authentication error | No | Re-authenticate | 401 |
| Authorization error | No | Contact support if unexpected | 403 |
| Resource not found | No | Verify resource ID | 404 |
| Business rule violation | No | Follow business rule guidance | 422 |
| Conflict / duplicate | No | Check existing resource | 409 |
| Rate limit exceeded | Yes (after delay) | Wait and retry | 429 |
| Transient infrastructure | Yes (with backoff) | Automatic retry — no user action | 503 |
| Downstream timeout | Yes (with backoff) | Automatic retry — show "processing" | 504 |
| Permanent infrastructure | No | Alert ops; show maintenance message | 500 |

---

## Workflow

1. **Classify errors** — Verify every catch block maps to a defined error category.
2. **Check user messages** — Confirm user-facing messages are friendly, actionable, and leak no internals.
3. **Review retry logic** — Verify exponential backoff with jitter, max retries, and only for retryable errors.
4. **Audit circuit breakers** — Confirm circuit breakers protect all external service calls.
5. **Check timeouts** — Verify every external call (HTTP, DB, message broker) has explicit timeouts.
6. **Validate idempotency** — Confirm retried financial operations are idempotent.

---

## Checklist

- [ ] Every error is classified into a defined category (not generic catch-all)
- [ ] User-facing messages are friendly, actionable, and contain no internal details
- [ ] Internal logs capture full context: error code, stack trace, request data (PII-redacted)
- [ ] Retries use exponential backoff with jitter and a max retry count
- [ ] Non-retryable errors are never retried
- [ ] Circuit breakers protect all external service calls
- [ ] Every external call has explicit connect and read timeouts
- [ ] Financial mutation retries are idempotent (idempotency key)
- [ ] Failed async messages route to dead letter queue with alerting
- [ ] Graceful degradation: non-critical feature failure does not block critical flows
- [ ] Error codes use named constants, not magic strings
- [ ] Trace ID is included in all error responses for correlation

---

## References

- §Error-Taxonomy — Complete error classification with codes and handling rules
- §User-Messages — User-facing message templates by error category
- §Retry-Backoff — Exponential backoff algorithm and configuration
- §Circuit-Breaker — Circuit breaker states, thresholds, and monitoring
- §Timeout-Policy — Timeout values by dependency type
- §Dead-Letter — DLQ processing and alerting setup

See `reference.md` for full details on each section.
