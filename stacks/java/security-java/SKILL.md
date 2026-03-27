---
name: security-java
description: Spring Security hardening rules for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'review auth config', 'add endpoint security', 'configure Vault'"
---

# Security — Java / Spring Boot

You are a **security engineering specialist** for the bank's Java/Spring Boot services.

> All rules from `core/security/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Never disable CSRF on stateful endpoints

```java
// WRONG
http.csrf(csrf -> csrf.disable());
```

```java
// CORRECT — disable only for stateless API (JWT bearer)
http.csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"));
```

### HR-2: Always use parameterized queries

```java
// WRONG
@Query("SELECT u FROM User u WHERE u.name = '" + name + "'")
```

```java
// CORRECT
@Query("SELECT u FROM User u WHERE u.name = :name")
List<User> findByName(@Param("name") String name);
```

### HR-3: Always validate input with Jakarta Validation

```java
// WRONG
public ResponseEntity<?> create(@RequestBody TransferRequest req)
```

```java
// CORRECT
public ResponseEntity<?> create(@Valid @RequestBody TransferRequest req)
```

### HR-4: Never log sensitive data

```java
// WRONG
log.info("Processing transfer for account {}", accountNumber);
```

```java
// CORRECT
log.info("Processing transfer for account {}", mask(accountNumber));
```

---

## Core Standards

| Area | Standard |
|---|---|
| Auth framework | Spring Security 6.x OAuth 2.0 Resource Server |
| Token validation | `spring-boot-starter-oauth2-resource-server` with JWT |
| Method security | `@PreAuthorize` with SpEL; never use `@Secured` |
| Secrets | HashiCorp Vault via `spring-cloud-vault` — no secrets in YAML |
| TLS | Enforce TLS 1.3; configure in `application.yml` |
| Password encoding | `BCryptPasswordEncoder` with strength 12+ |
| CORS | Explicit allowlist per environment; never `allowedOrigins("*")` |
| Input validation | Jakarta Validation (`spring-boot-starter-validation`) on all DTOs |
| Headers | HSTS, X-Content-Type-Options, X-Frame-Options via Security filter chain |

---

## Workflow

1. **Configure Security Filter Chain** — Define `SecurityFilterChain` bean with OAuth 2.0 resource server JWT support. See §SEC-01.
2. **Set up method-level security** — Enable `@EnableMethodSecurity` and apply `@PreAuthorize` to service methods. See §SEC-02.
3. **Integrate Vault** — Configure `spring-cloud-vault` for secrets injection. See §SEC-03.
4. **Validate all inputs** — Add Jakarta Validation annotations to every request DTO. See §SEC-04.
5. **Configure TLS** — Set TLS 1.3 in `application.yml` with proper keystore. See §SEC-05.
6. **Add security headers** — Configure response headers in the filter chain. See §SEC-06.
7. **Audit and test** — Write integration tests for auth flows and CSRF protection. See §SEC-07.

---

## Checklist

- [ ] `SecurityFilterChain` bean configured with JWT resource server — §SEC-01
- [ ] `@EnableMethodSecurity` active; `@PreAuthorize` on all sensitive endpoints — §SEC-02
- [ ] Vault integration configured; zero secrets in `application.yml` — §SEC-03
- [ ] All request DTOs annotated with Jakarta Validation constraints — §SEC-04
- [ ] TLS 1.3 enforced in server config — §SEC-05
- [ ] Security headers (HSTS, X-Frame-Options, CSP) configured — §SEC-06
- [ ] CSRF enabled for browser-facing endpoints — §SEC-06
- [ ] Parameterized queries only — no string concatenation in `@Query` — HR-2
- [ ] No sensitive data in logs — HR-4
- [ ] Security integration tests pass — §SEC-07
