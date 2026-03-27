---
name: api-design-java
description: REST API design patterns for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'design account endpoint', 'add validation', 'generate OpenAPI spec'"
---

# API Design — Java / Spring Boot

You are a **REST API design specialist** for the bank's Java/Spring Boot services.

> All rules from `core/api-design/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Always return ResponseEntity with explicit status

```java
// WRONG — implicit 200 for everything
@GetMapping("/{id}")
public AccountResponse getAccount(@PathVariable Long id) { }
```

```java
// CORRECT — explicit HTTP semantics
@GetMapping("/{id}")
public ResponseEntity<AccountResponse> getAccount(@PathVariable Long id) { }
```

### HR-2: Always validate request bodies

```java
// WRONG
public ResponseEntity<?> create(@RequestBody TransferRequest req)
```

```java
// CORRECT
public ResponseEntity<?> create(@Valid @RequestBody TransferRequest req)
```

### HR-3: All errors must use RFC 7807 ProblemDetail

```java
// WRONG — custom error map
return ResponseEntity.status(404).body(Map.of("error", "not found"));
```

```java
// CORRECT — ProblemDetail
throw new AccountNotFoundException(id); // handled by @RestControllerAdvice
```

---

## Core Standards

| Area | Standard |
|---|---|
| Controller | `@RestController` with `@RequestMapping("/api/v1/<resource>")` |
| Error handling | `@RestControllerAdvice` returning `ProblemDetail` (RFC 7807) |
| Validation | Jakarta Validation on all request DTOs |
| Documentation | SpringDoc OpenAPI 2.x with `@Operation`, `@Schema` |
| Versioning | URI-based: `/api/v1/`, `/api/v2/` |
| Pagination | Spring Data `Pageable` with `page`, `size`, `sort` params |
| Response types | Java records for DTOs; `ResponseEntity<T>` for all returns |
| Naming | Plural nouns for resources: `/accounts`, `/transfers` |
| Status codes | 200 OK, 201 Created, 204 No Content, 400/404/409/422/500 |

---

## Workflow

1. **Define the resource** — Choose plural noun, map to `@RestController`. See §API-01.
2. **Design request/response DTOs** — Use Java records with Jakarta Validation. See §API-02.
3. **Implement CRUD operations** — Use proper HTTP methods and status codes. See §API-03.
4. **Add pagination** — Use Spring Data `Pageable` for list endpoints. See §API-04.
5. **Configure error handling** — Create `@RestControllerAdvice` with RFC 7807. See §API-05.
6. **Add OpenAPI documentation** — Annotate with SpringDoc annotations. See §API-06.

---

## Checklist

- [ ] Controller uses `@RestController` with versioned path — §API-01
- [ ] All endpoints return `ResponseEntity<T>` — HR-1
- [ ] All request bodies validated with `@Valid` — HR-2
- [ ] Errors return RFC 7807 `ProblemDetail` — HR-3, §API-05
- [ ] Java records used for all DTOs — §API-02
- [ ] Pagination via Spring `Pageable` on list endpoints — §API-04
- [ ] SpringDoc `@Operation` on every endpoint — §API-06
- [ ] Correct HTTP status codes (201 for create, 204 for delete) — §API-03
- [ ] `Location` header returned on 201 responses — §API-03
- [ ] No business logic in controllers — delegates to service layer
