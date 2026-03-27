---
name: error-handling-java
description: Error handling and resilience patterns for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add exception handler', 'configure circuit breaker', 'add retry logic'"
---

# Error Handling — Java / Spring Boot

You are an **error handling and resilience specialist** for the bank's Java/Spring Boot services.

> All rules from `core/error-handling/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Never expose stack traces in API responses

```java
// WRONG — leaks internal details
@ExceptionHandler(Exception.class)
public ResponseEntity<String> handle(Exception ex) {
    return ResponseEntity.status(500).body(ex.toString());
}
```

```java
// CORRECT — generic message; log the trace server-side
@ExceptionHandler(Exception.class)
public ProblemDetail handle(Exception ex) {
    log.error("Unhandled exception", ex);
    return ProblemDetail.forStatusAndDetail(
        HttpStatus.INTERNAL_SERVER_ERROR, "An internal error occurred");
}
```

### HR-2: Never catch and silently swallow exceptions

```java
// WRONG
try { processTransfer(request); }
catch (Exception e) { /* ignored */ }
```

```java
// CORRECT
try { processTransfer(request); }
catch (TransferException e) {
    log.error("Transfer failed [ref={}]", request.reference(), e);
    throw e;
}
```

### HR-3: Use specific exception types, not generic Exception

```java
// WRONG
throw new RuntimeException("Account not found");
```

```java
// CORRECT
throw new AccountNotFoundException(accountId);
```

---

## Core Standards

| Area | Standard |
|---|---|
| Global handler | Single `@RestControllerAdvice` for all exceptions |
| Error format | RFC 7807 `ProblemDetail` for all error responses |
| Exception hierarchy | `BankException` (abstract) -> domain-specific subtypes |
| Retry | Spring Retry for transient failures (DB, network) |
| Circuit breaker | Resilience4j for external service calls |
| Logging | Log full stack trace server-side at ERROR; never expose to client |
| Validation errors | Map `MethodArgumentNotValidException` to 400 with field details |
| Idempotency | Retry-safe operations must be idempotent |

---

## Workflow

1. **Define exception hierarchy** — Create base `BankException` and domain subtypes. See §ERR-01.
2. **Implement @RestControllerAdvice** — Map exceptions to RFC 7807 responses. See §ERR-02.
3. **Configure Spring Retry** — Add retry for transient failures. See §ERR-03.
4. **Configure Resilience4j** — Add circuit breakers for external calls. See §ERR-04.
5. **Add structured error logging** — Log context with correlation IDs. See §ERR-05.

---

## Checklist

- [ ] Single `@RestControllerAdvice` handles all exceptions — §ERR-02
- [ ] All error responses use RFC 7807 `ProblemDetail` — §ERR-02
- [ ] Custom exceptions extend `BankException` hierarchy — §ERR-01
- [ ] No stack traces exposed in API responses — HR-1
- [ ] No silently swallowed exceptions — HR-2
- [ ] Specific exception types used, not generic `Exception` — HR-3
- [ ] Spring Retry configured for transient failures — §ERR-03
- [ ] Circuit breakers on all external service calls — §ERR-04
- [ ] All exceptions logged with correlation IDs — §ERR-05
- [ ] Validation errors return 400 with field-level details — §ERR-02
