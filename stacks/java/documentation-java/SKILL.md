---
name: documentation-java
description: Documentation standards for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add Javadoc to service', 'create ADR', 'configure OpenAPI docs'"
---

# Documentation — Java / Spring Boot

You are a **documentation standards specialist** for the bank's Java/Spring Boot services.

> All rules from `core/documentation/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: All public APIs must have Javadoc

```java
// WRONG — no documentation on public method
public TransferResult execute(TransferRequest request) { }
```

```java
// CORRECT
/**
 * Executes a funds transfer between two accounts.
 *
 * @param request the transfer details including source, destination, and amount
 * @return the result containing transfer status and reference ID
 * @throws InsufficientFundsException if the source account balance is too low
 * @throws AccountNotFoundException if either account does not exist
 */
public TransferResult execute(TransferRequest request) { }
```

### HR-2: All REST endpoints must have OpenAPI annotations

```java
// WRONG — undocumented endpoint
@GetMapping("/{id}")
public ResponseEntity<AccountResponse> getAccount(@PathVariable Long id) { }
```

```java
// CORRECT
@Operation(summary = "Get account by ID",
    description = "Retrieves account details including balance and status")
@ApiResponse(responseCode = "200", description = "Account found")
@ApiResponse(responseCode = "404", description = "Account not found")
@GetMapping("/{id}")
public ResponseEntity<AccountResponse> getAccount(@PathVariable Long id) { }
```

### HR-3: Architecture decisions must have ADRs

```
// WRONG — decisions discussed in Slack, not recorded

// CORRECT — ADR in docs/adr/ with standard template
```

---

## Core Standards

| Area | Standard |
|---|---|
| Javadoc | Required on all public classes, interfaces, and methods |
| OpenAPI | SpringDoc annotations on all `@RestController` endpoints |
| ADRs | Stored in `docs/adr/` with sequential numbering |
| README | Standardized template for every service repository |
| Package docs | `package-info.java` for every feature package |
| Schema docs | `@Schema` on all DTO fields with descriptions and examples |
| Changelog | `CHANGELOG.md` following Keep a Changelog format |

---

## Workflow

1. **Add Javadoc** — Document all public classes, methods, and interfaces. See §DOC-01.
2. **Annotate endpoints** — Add `@Operation`, `@ApiResponse`, `@Schema` to REST API. See §DOC-02.
3. **Write ADR** — Record architecture decisions using the ADR template. See §DOC-03.
4. **Create README** — Use the standard service README template. See §DOC-04.
5. **Add package-info** — Create `package-info.java` for feature packages. See §DOC-05.

---

## Checklist

- [ ] All public classes and methods have Javadoc — HR-1
- [ ] All REST endpoints have `@Operation` and `@ApiResponse` — HR-2
- [ ] All DTO fields have `@Schema` with description and example — §DOC-02
- [ ] Architecture decisions recorded as ADRs in `docs/adr/` — HR-3, §DOC-03
- [ ] Service README follows standard template — §DOC-04
- [ ] `package-info.java` exists for each feature package — §DOC-05
- [ ] SpringDoc generates valid OpenAPI spec — §DOC-02
- [ ] Javadoc includes `@param`, `@return`, `@throws` where applicable — §DOC-01
