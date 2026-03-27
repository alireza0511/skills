# Documentation — Java / Spring Boot Reference

## §DOC-01 Javadoc Conventions

### Class-Level Javadoc

```java
/**
 * Service responsible for executing inter-account fund transfers.
 *
 * <p>Handles validation, balance checks, and event publishing for all
 * domestic and international transfers. All operations are transactional
 * and idempotent when an idempotency key is provided.</p>
 *
 * @author Platform Engineering
 * @since 1.0.0
 * @see AccountService
 * @see TransferRepository
 */
@Service
@Transactional(readOnly = true)
public class TransferServiceImpl implements TransferService {
```

### Method-Level Javadoc

```java
/**
 * Executes a funds transfer between two accounts.
 *
 * <p>The transfer is atomic: both debit and credit occur within a single
 * transaction. If the source account has insufficient funds, the entire
 * operation is rolled back.</p>
 *
 * @param request the transfer details including source account, destination
 *                account, amount, and currency
 * @return the transfer result containing status, reference ID, and timestamp
 * @throws InsufficientFundsException if the source account balance is less
 *         than the requested transfer amount
 * @throws AccountNotFoundException if either the source or destination
 *         account does not exist
 * @throws AccountInactiveException if either account is closed or frozen
 */
@Override
@Transactional
public TransferResult execute(TransferRequest request) {
    // implementation
}
```

### Interface Javadoc

```java
/**
 * Repository for account persistence operations.
 *
 * <p>Provides parameterized queries for account lookup by various
 * identifiers. All queries use Spring Data JPA named parameters
 * to prevent SQL injection.</p>
 */
public interface AccountRepository extends JpaRepository<Account, Long> {

    /**
     * Finds an account by its IBAN.
     *
     * @param iban the International Bank Account Number (e.g., "NL91ABNA0417164300")
     * @return an {@link Optional} containing the account if found, or empty
     */
    @Query("SELECT a FROM Account a WHERE a.iban = :iban")
    Optional<Account> findByIban(@Param("iban") String iban);
}
```

### Enum Javadoc

```java
/**
 * Represents the lifecycle status of a bank account.
 */
public enum AccountStatus {

    /** Account is open and can send/receive transfers. */
    ACTIVE,

    /** Account is temporarily restricted; no outgoing transfers. */
    FROZEN,

    /** Account is permanently closed; no transactions permitted. */
    CLOSED
}
```

---

## §DOC-02 SpringDoc OpenAPI Annotations

### Controller Documentation

```java
package com.bank.transfer.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/v1/transfers")
@Tag(name = "Transfers", description = "Fund transfer operations between accounts")
public class TransferController {

    @Operation(
        summary = "Initiate a new transfer",
        description = "Creates a new fund transfer between two accounts. "
            + "The transfer is processed synchronously and the result is returned immediately.")
    @ApiResponse(responseCode = "201", description = "Transfer completed successfully",
        content = @Content(schema = @Schema(implementation = TransferResponse.class)))
    @ApiResponse(responseCode = "400", description = "Invalid request — validation failed",
        content = @Content(schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "404", description = "Source or destination account not found",
        content = @Content(schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "422", description = "Business rule violation (e.g., insufficient funds)",
        content = @Content(schema = @Schema(implementation = ProblemDetail.class)))
    @PostMapping
    public ResponseEntity<TransferResponse> createTransfer(
            @Valid @RequestBody TransferRequest request) {
        // ...
    }

    @Operation(summary = "Get transfer status by reference ID")
    @ApiResponse(responseCode = "200", description = "Transfer found")
    @ApiResponse(responseCode = "404", description = "Transfer not found")
    @GetMapping("/{referenceId}")
    public ResponseEntity<TransferResponse> getTransfer(
            @Parameter(description = "Transfer reference ID", example = "TRF-2025-000123")
            @PathVariable String referenceId) {
        // ...
    }
}
```

### DTO Schema Documentation

```java
package com.bank.transfer.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

@Schema(description = "Request to initiate a fund transfer between two accounts")
public record TransferRequest(

    @Schema(description = "Source account IBAN", example = "NL91ABNA0417164300", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank
    String sourceIban,

    @Schema(description = "Destination account IBAN", example = "DE89370400440532013000", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank
    String destinationIban,

    @Schema(description = "Transfer amount", example = "250.00", minimum = "0.01", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull @DecimalMin("0.01")
    BigDecimal amount,

    @Schema(description = "ISO 4217 currency code", example = "EUR", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank @Pattern(regexp = "^[A-Z]{3}$")
    String currency,

    @Schema(description = "Payment reference or description", example = "Invoice #12345", maxLength = 140)
    @Size(max = 140)
    String reference,

    @Schema(description = "Idempotency key to prevent duplicate transfers", example = "idem-2025-abc123")
    String idempotencyKey
) {}
```

---

## §DOC-03 Architecture Decision Records (ADR)

### ADR Template — docs/adr/NNNN-title.md

```markdown
# NNNN. Title of Decision

**Date:** YYYY-MM-DD

**Status:** Proposed | Accepted | Deprecated | Superseded by [NNNN]

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- ...

### Negative
- ...

### Risks
- ...
```

### Example ADR

```markdown
# 0003. Use Resilience4j for Circuit Breaking

**Date:** 2025-03-10

**Status:** Accepted

## Context

Our payment service depends on an external payment gateway that experiences
periodic outages (2-3 times per month, lasting 5-15 minutes). During these
outages, our service threads are blocked waiting for responses, leading to
cascading failures that affect account queries.

## Decision

We will use Resilience4j as our circuit breaker library, configured with:
- COUNT_BASED sliding window of 10 calls
- 50% failure rate threshold to open the circuit
- 30-second wait in open state before half-open
- Fallback to queueing failed payments for retry

We chose Resilience4j over Hystrix (end-of-life) and Spring Circuit Breaker
abstraction (too limited for our monitoring needs).

## Consequences

### Positive
- Payment gateway outages will not cascade to other service operations
- Metrics integration with Micrometer provides visibility into circuit state
- Queued payments will be automatically retried when the gateway recovers

### Negative
- Adds configuration complexity to payment service
- Queued payments introduce eventual consistency (users see "pending" status)

### Risks
- Circuit breaker thresholds may need tuning based on production traffic patterns
```

---

## §DOC-04 Service README Template

```markdown
# <Service Name>

Brief one-line description of what this service does.

## Overview

2-3 sentences describing the service's purpose, its domain, and key capabilities.

## Architecture

- **Framework:** Spring Boot 3.x, Java 21
- **Database:** PostgreSQL 16
- **Messaging:** (if applicable)
- **External Dependencies:** List downstream services

## Getting Started

### Prerequisites

- Java 21 (Temurin)
- Docker & Docker Compose
- Gradle 8.x (via wrapper)

### Local Development

    ./gradlew bootRun --args='--spring.profiles.active=local'

### Running Tests

    ./gradlew test

### Building Docker Image

    docker build -t <service-name>:local .

## API Documentation

- **Local Swagger UI:** http://localhost:8080/swagger-ui.html
- **OpenAPI Spec:** http://localhost:8080/api-docs

## Configuration

| Property | Description | Default |
|---|---|---|
| `server.port` | HTTP port | `8080` |
| `spring.datasource.url` | Database URL | (required) |

## ADRs

Architecture decisions are in [docs/adr/](docs/adr/).

## Team

Owned by **[Team Name]** — Slack: `#channel-name`
```

---

## §DOC-05 Package-Info Files

### package-info.java

```java
/**
 * Account management bounded context.
 *
 * <p>This package contains all components for the account lifecycle:
 * creation, balance management, status transitions, and closure.</p>
 *
 * <h2>Key Components</h2>
 * <ul>
 *   <li>{@link com.bank.account.controller.AccountController} — REST API</li>
 *   <li>{@link com.bank.account.service.AccountService} — Business logic</li>
 *   <li>{@link com.bank.account.domain.Account} — Aggregate root</li>
 * </ul>
 *
 * <h2>Module Boundaries</h2>
 * <p>External modules should only depend on the
 * {@link com.bank.account.service.AccountService} interface and DTOs in
 * {@code com.bank.account.dto}. Direct access to the repository or domain
 * layer is not permitted.</p>
 *
 * @since 1.0.0
 */
package com.bank.account;
```
