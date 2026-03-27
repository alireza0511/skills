# Error Handling — Reference

## §Error-Taxonomy

### Complete Error Classification

| Code | Category | Retryable | Typical Cause | Handling |
|---|---|---|---|---|
| `VALIDATION_FAILED` | Validation | No | Malformed input | Return field-level errors to client |
| `INVALID_AMOUNT` | Validation | No | Negative or zero amount | Return allowed range |
| `INVALID_IBAN` | Validation | No | Bad checksum or format | Return format hint |
| `AUTHENTICATION_REQUIRED` | Auth | No | Missing/expired token | Redirect to login |
| `AUTHENTICATION_FAILED` | Auth | No | Wrong credentials | Generic "invalid credentials" message |
| `PERMISSION_DENIED` | Authorization | No | Insufficient role | Contact support message |
| `RESOURCE_NOT_FOUND` | Not Found | No | Invalid ID or no access | Generic "not found" (prevent enumeration) |
| `INSUFFICIENT_FUNDS` | Business Rule | No | Balance too low | Show available balance |
| `TRANSFER_LIMIT_EXCEEDED` | Business Rule | No | Daily/transaction limit | Show limit and current usage |
| `ACCOUNT_FROZEN` | Business Rule | No | Regulatory or fraud hold | Contact support message |
| `DUPLICATE_REQUEST` | Conflict | No | Idempotency key reused | Return original result |
| `CONCURRENT_MODIFICATION` | Conflict | Yes (once) | Optimistic lock failure | Reload and retry |
| `RATE_LIMITED` | Rate Limit | Yes | Too many requests | Wait per `Retry-After` header |
| `SERVICE_UNAVAILABLE` | Transient | Yes | Downstream outage | Backoff and retry |
| `GATEWAY_TIMEOUT` | Transient | Yes | Downstream slow | Backoff and retry |
| `DATABASE_ERROR` | Infrastructure | Conditional | Connection pool, deadlock | Retry deadlocks; alert on connection issues |
| `MESSAGE_BROKER_ERROR` | Infrastructure | Yes | Broker unavailable | Retry with DLQ fallback |
| `INTERNAL_ERROR` | Permanent | No | Unhandled exception | Log full context, alert, generic user message |

### Error Response Structure

```
// All errors follow this internal structure
ErrorResponse:
    error_code: string          // From taxonomy above
    category: string            // "validation", "auth", "business_rule", etc.
    retryable: boolean
    user_message: string        // Safe to display to end user
    internal_message: string    // Full detail for logs only — never sent to client
    trace_id: string            // For correlation
    field_errors: []            // For validation errors only
    retry_after: number?        // Seconds — for retryable errors
```

---

## §User-Messages

### Message Templates by Category

| Category | User Message Template | Tone |
|---|---|---|
| Validation | "Please check the {field_name}: {specific_guidance}." | Helpful, specific |
| Authentication | "Your session has expired. Please sign in again." | Neutral, action-oriented |
| Auth failure | "The credentials you entered are incorrect. Please try again." | Neutral — never reveal which field is wrong |
| Authorization | "You do not have permission for this action. Contact your administrator." | Factual |
| Not found | "The requested resource could not be found." | Neutral |
| Insufficient funds | "Insufficient funds. Your available balance is {masked_balance}." | Factual, informative |
| Transfer limit | "This transfer exceeds your {limit_type} limit of {limit_amount}." | Factual |
| Account frozen | "This account is currently restricted. Please contact customer support." | Neutral, directive |
| Rate limited | "You have made too many requests. Please wait a moment and try again." | Calm |
| Service unavailable | "This service is temporarily unavailable. Please try again in a few minutes." | Reassuring |
| Timeout | "Your request is taking longer than expected. We are processing it — please do not retry." | Reassuring, cautionary |
| Internal error | "Something unexpected happened. Please try again. If the issue persists, contact support." | Apologetic, action-oriented |

### User Message Rules

| Rule | Detail |
|---|---|
| No technical jargon | No "null pointer", "timeout", "500", "exception" |
| No internal names | No service names, class names, file paths |
| Actionable | Tell the user what to do next |
| Consistent tone | Professional, calm, helpful |
| Include trace ID | "Reference: {trace_id}" — for support calls |
| Locale-aware | Messages must support internationalization |

---

## §Retry-Backoff

### Exponential Backoff Algorithm

```
function retry_with_backoff(operation, config):
    for attempt in 1 to config.max_retries:
        try:
            return operation()
        catch RetryableError as error:
            if attempt == config.max_retries:
                raise MaxRetriesExceeded(error)

            delay = min(
                config.base_delay * (2 ^ attempt),
                config.max_delay
            )
            jitter = random(0, delay * config.jitter_factor)
            sleep(delay + jitter)

    raise MaxRetriesExceeded()
```

### Configuration Defaults

| Parameter | Default | Description |
|---|---|---|
| `base_delay` | 100ms | Initial delay before first retry |
| `max_delay` | 30s | Maximum delay cap |
| `max_retries` | 3 | Maximum retry attempts |
| `jitter_factor` | 0.5 | Random jitter multiplier (0-1) |

### Retry Configuration by Dependency

| Dependency | Max Retries | Base Delay | Max Delay | Notes |
|---|---|---|---|---|
| Database (deadlock) | 3 | 50ms | 1s | Only retry deadlock/serialization errors |
| Database (connection) | 2 | 100ms | 2s | Alert if persistent |
| External HTTP API | 3 | 200ms | 10s | Only on 429, 502, 503, 504 |
| Message broker (publish) | 5 | 100ms | 30s | Critical — messages must not be lost |
| Cache | 1 | 50ms | 50ms | Fallback to source on failure |

### What to Never Retry

| Error Type | Reason |
|---|---|
| Validation errors (400, 422) | Input won't change; same result every time |
| Authentication errors (401) | Token is invalid; re-auth needed |
| Authorization errors (403) | Permissions won't change mid-request |
| Not found (404) | Resource won't appear from retrying |
| Business rule violations | Conditions won't change from retrying |
| Non-idempotent operations without idempotency key | Risk of duplicate execution |

---

## §Circuit-Breaker

### States

```
     ┌─────────┐    failure threshold    ┌──────┐
     │  CLOSED  │ ─────────────────────> │ OPEN  │
     │(normal)  │                        │(fail) │
     └─────────┘ <───────────────── ┐    └──────┘
          │                         │        │
          │                    success  timeout expires
          │                         │        │
          │                    ┌────────────┐ │
          │                    │ HALF-OPEN   │◄┘
          │                    │(testing)    │
          │                    └────────────┘
          │                         │
          └─── failure ◄────────────┘
```

| State | Behavior |
|---|---|
| **Closed** | Normal operation. Requests pass through. Track failure count. |
| **Open** | All requests fail immediately (fast-fail). Return fallback or 503. |
| **Half-Open** | Allow limited probe requests. If success → Closed. If failure → Open. |

### Configuration Defaults

| Parameter | Default | Description |
|---|---|---|
| `failure_threshold` | 5 failures | Number of failures to trip the breaker |
| `failure_window` | 60 seconds | Time window to count failures |
| `open_duration` | 30 seconds | How long to stay open before half-open |
| `half_open_max_requests` | 3 | Number of probe requests allowed in half-open |
| `success_threshold` | 3 | Consecutive successes to close from half-open |

### Configuration by Dependency

| Dependency | Failure Threshold | Open Duration | Fallback |
|---|---|---|---|
| Payment gateway | 3 in 30s | 60s | Queue for retry; show "processing" |
| Account service | 5 in 60s | 30s | Return cached balance (stale marker) |
| Notification service | 10 in 60s | 30s | Queue notifications; process later |
| Credit scoring | 5 in 60s | 60s | Defer decision; notify user of delay |
| Exchange rate API | 5 in 60s | 30s | Use last known rate with stale warning |

### Monitoring

| Metric | Alert Condition | Tier |
|---|---|---|
| Circuit breaker state changes | Any trip to Open | P2 (critical service), P3 (non-critical) |
| Time in Open state | > 5 minutes | P2 |
| Half-open failure rate | > 50% of probes fail | P3 |

---

## §Timeout-Policy

### Timeout Values by Dependency

| Dependency Type | Connect Timeout | Read Timeout | Total Timeout |
|---|---|---|---|
| Internal microservice | 1s | 5s | 10s |
| Database query | 1s | 5s | 10s |
| Database transaction | 1s | 10s | 30s |
| External payment API | 3s | 15s | 30s |
| External data API | 2s | 10s | 15s |
| Message broker publish | 1s | 3s | 5s |
| Cache (Redis) | 500ms | 1s | 2s |
| DNS resolution | 2s | — | 2s |

### Timeout Rules

| Rule | Detail |
|---|---|
| Always explicit | Never rely on library/OS defaults |
| Propagate deadlines | Pass remaining time budget to downstream calls |
| Log timeouts | Log as WARN with dependency name and configured timeout |
| Distinguish connect vs read | Connection timeout (network) vs read timeout (processing) |
| Total budget | Request has a total time budget; sum of downstream calls must fit |

### Deadline Propagation

```
// pseudocode — propagate remaining time budget
function handle_request(request):
    deadline = now() + 10s                    // total budget

    account = account_service.get(            // 3s timeout, or remaining budget
        id, timeout=min(3s, remaining(deadline))
    )

    rate = rate_service.get(                  // 2s timeout, or remaining budget
        currency, timeout=min(2s, remaining(deadline))
    )

    if remaining(deadline) <= 0:
        raise DeadlineExceeded()

    return process(account, rate)
```

---

## §Dead-Letter

### Dead Letter Queue (DLQ) Processing

| Stage | Action |
|---|---|
| Message fails | Retry per retry policy (see §Retry-Backoff) |
| Max retries exceeded | Route message to DLQ |
| DLQ arrival | Increment DLQ depth metric, log ERROR |
| Alert | Alert when DLQ depth > 0 (P3) or > 100 (P2) |
| Investigation | On-call reviews DLQ messages within SLA |
| Resolution | Fix root cause, replay messages from DLQ |
| Poison messages | After manual review, archive or discard with audit log entry |

### DLQ Message Metadata

| Field | Description |
|---|---|
| `original_topic` | Source topic/queue the message came from |
| `original_timestamp` | When the message was first published |
| `failure_count` | Number of processing attempts |
| `last_error` | Error code and message from final attempt |
| `trace_id` | Correlation ID for tracing |
| `dlq_timestamp` | When the message entered the DLQ |

### DLQ Rules

| Rule | Detail |
|---|---|
| Never auto-replay | DLQ messages require human review before replay |
| Preserve ordering | Replay in original order when order matters |
| Idempotent consumers | Consumers must handle replayed messages safely |
| Retention | Keep DLQ messages for 30 days minimum |
| Monitoring | Dashboard showing DLQ depth by topic, age of oldest message |
| PII | DLQ messages may contain PII — apply same access controls as production data |
