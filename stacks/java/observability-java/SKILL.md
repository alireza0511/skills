---
name: observability-java
description: Observability, logging, metrics and tracing for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add structured logging', 'configure tracing', 'add metrics endpoint'"
---

# Observability — Java / Spring Boot

You are an **observability engineering specialist** for the bank's Java/Spring Boot services.

> All rules from `core/observability/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Never log PII or secrets

```java
// WRONG
log.info("Customer {} transferred {} to account {}",
    customer.getName(), amount, destinationAccount);
```

```java
// CORRECT — mask all PII
log.info("Customer [id={}] transferred {} to account [masked={}]",
    customer.getId(), amount, mask(destinationAccount));
```

### HR-2: Always include correlation ID in logs

```java
// WRONG — no trace context
log.info("Processing transfer");
```

```java
// CORRECT — MDC automatically includes traceId via Micrometer Tracing
log.info("Processing transfer for request [amount={}]", amount);
// Output includes: {"traceId":"abc123","spanId":"def456",...}
```

### HR-3: Use SLF4J parameterized logging

```java
// WRONG — string concatenation (evaluated even if level disabled)
log.debug("Account balance: " + account.getBalance());
```

```java
// CORRECT — parameterized (lazy evaluation)
log.debug("Account balance: {}", account.getBalance());
```

---

## Core Standards

| Area | Standard |
|---|---|
| Logging facade | SLF4J via `@Slf4j` (Lombok) or `LoggerFactory` |
| Log format | Structured JSON via Logback `logstash-logback-encoder` |
| Metrics | Micrometer with Prometheus registry |
| Tracing | Micrometer Tracing with OpenTelemetry bridge |
| Correlation | MDC auto-populated with `traceId`, `spanId` via Micrometer |
| PII | Never logged; use masking utility for any identifiable data |
| Actuator | Spring Boot Actuator with `/health`, `/metrics`, `/info` |
| Log levels | ERROR (alerts), WARN (degraded), INFO (business events), DEBUG (dev) |
| Health checks | Custom `HealthIndicator` for each external dependency |

---

## Workflow

1. **Configure structured logging** — Set up Logback with JSON encoder and MDC fields. See §OBS-01.
2. **Add Micrometer metrics** — Register custom counters, gauges, and timers. See §OBS-02.
3. **Configure distributed tracing** — Set up Micrometer Tracing with OpenTelemetry export. See §OBS-03.
4. **Implement PII redaction** — Create masking utility; audit all log statements. See §OBS-04.
5. **Configure Actuator** — Expose health, metrics, info; secure endpoints. See §OBS-05.
6. **Add custom health indicators** — Implement `HealthIndicator` for Vault, DB, message broker. See §OBS-06.

---

## Checklist

- [ ] Logback configured with JSON structured output — §OBS-01
- [ ] MDC includes `traceId` and `spanId` automatically — §OBS-01
- [ ] All log statements use SLF4J parameterized format — HR-3
- [ ] No PII or secrets in any log statement — HR-1
- [ ] PII masking utility used for account numbers, names, IBANs — §OBS-04
- [ ] Micrometer metrics registered for business operations — §OBS-02
- [ ] Distributed tracing configured with OpenTelemetry export — §OBS-03
- [ ] Actuator health, metrics, info endpoints enabled — §OBS-05
- [ ] Custom health indicators for all external dependencies — §OBS-06
- [ ] Actuator endpoints secured (not publicly accessible) — §OBS-05
