---
name: observability
description: "Structured logging, RED metrics, distributed tracing, PII redaction, alerting for banking services"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
---

# Observability Skill

You are an observability reviewer for bank services.
When invoked, evaluate logging, metrics, tracing, and alerting against bank observability standards.

---

## Hard Rules

### HR-1: Never log PII or financial data in plain text

```
# WRONG
log.info("Transfer completed", customer_name="John Doe", iban="DE89370400440532013000")

# CORRECT
log.info("Transfer completed", customer_id="cust-abc", iban="DE89****3000")
```

### HR-2: Every log entry must be structured

```
# WRONG
log("Error: transfer failed for user 123 at 2025-03-15")

# CORRECT
log.error("Transfer failed", user_id="123", transfer_id="txn-456", error_code="INSUFFICIENT_FUNDS")
```

### HR-3: Every inbound request must carry a trace ID

```
# WRONG — no correlation between services
function handle_request(request):
    process(request)

# CORRECT — propagate trace context
function handle_request(request):
    trace_id = request.header("traceparent") or generate_trace_id()
    context.set_trace_id(trace_id)
    process(request)
```

---

## Core Standards

| Area | Standard | Detail |
|---|---|---|
| Log format | Structured JSON | All environments including local |
| Log levels | ERROR, WARN, INFO, DEBUG | No custom levels; ERROR = action needed |
| PII redaction | Mask all PII before logging | Names, IBANs, emails, phone numbers, card numbers |
| Trace propagation | W3C Trace Context (`traceparent` header) | All HTTP and async boundaries |
| Metrics method | RED (Rate, Errors, Duration) | Every service endpoint |
| Metric naming | `{service}_{operation}_{unit}` | `payment_transfers_total`, `payment_transfer_duration_seconds` |
| Alert thresholds | Error rate > 1%, p99 latency > 2s, availability < 99.9% | Tuned per service |
| Retention | Logs: 90 days hot, 1 year cold. Metrics: 15 months. Traces: 30 days | Compliance requirement |
| Audit trail | All financial operations logged to tamper-proof audit log | Separate from application logs |

---

## Workflow

1. **Check log structure** — Verify all log statements produce structured JSON with required fields.
2. **Audit PII** — Scan log statements for unmasked PII or financial data.
3. **Verify trace propagation** — Confirm trace context is propagated across all service boundaries.
4. **Review metrics** — Check RED metrics exist for all endpoints.
5. **Validate alerts** — Confirm alert rules exist for error rate, latency, and availability.
6. **Check audit trail** — Verify financial operations emit audit events with required fields.

---

## Checklist

- [ ] All log entries are structured JSON
- [ ] Log entries include: timestamp, level, service, trace_id, message, context fields
- [ ] No PII logged in plain text (names, emails, IBANs, card numbers, phone numbers)
- [ ] Trace context (W3C `traceparent`) propagated across HTTP and async boundaries
- [ ] RED metrics (rate, errors, duration) on every service endpoint
- [ ] Metric names follow `{service}_{operation}_{unit}` convention
- [ ] Alerts configured for error rate > 1%, p99 > 2s, availability < 99.9%
- [ ] Financial operations produce tamper-proof audit log entries
- [ ] Log levels used correctly: ERROR = needs action, WARN = degradation, INFO = business events
- [ ] No sensitive data in metric labels or trace attributes
- [ ] Dashboards exist for service health (RED metrics overview)
- [ ] Log retention meets compliance: 90 days hot, 1 year cold

---

## References

- §Log-Schema — Required log fields and structured format specification
- §PII-Redaction — Redaction rules by data type with patterns
- §RED-Metrics — Rate, Errors, Duration implementation guide
- §Tracing — Distributed tracing setup and span naming conventions
- §Alerting — Alert rule definitions and escalation policy
- §Audit-Trail — Audit event schema for financial operations

See `reference.md` for full details on each section.
