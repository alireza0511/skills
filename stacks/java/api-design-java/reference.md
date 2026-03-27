# API Design — Java / Spring Boot Reference

## §API-01 RestController Convention

```java
package com.bank.account.controller;

import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/accounts")
@Tag(name = "Accounts", description = "Account management operations")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }
}
```

---

## §API-02 Request/Response DTOs with Jakarta Validation

### Request DTO

```java
package com.bank.account.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

@Schema(description = "Request to create a new bank account")
public record CreateAccountRequest(

    @NotBlank(message = "Owner name is required")
    @Size(min = 2, max = 100, message = "Owner name must be 2-100 characters")
    @Schema(description = "Full legal name of the account owner", example = "Jan de Vries")
    String ownerName,

    @NotBlank(message = "Currency is required")
    @Pattern(regexp = "^[A-Z]{3}$", message = "Currency must be a 3-letter ISO 4217 code")
    @Schema(description = "ISO 4217 currency code", example = "EUR")
    String currency,

    @NotNull(message = "Initial balance is required")
    @DecimalMin(value = "0.00", message = "Initial balance must be non-negative")
    @Schema(description = "Initial deposit amount", example = "1000.00")
    BigDecimal initialBalance
) {}
```

### Response DTO

```java
package com.bank.account.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;

@Schema(description = "Account details")
public record AccountResponse(

    @Schema(description = "Unique account identifier", example = "12345")
    Long id,

    @Schema(description = "International Bank Account Number", example = "NL91ABNA0417164300")
    String iban,

    @Schema(description = "Account owner full name", example = "Jan de Vries")
    String ownerName,

    @Schema(description = "Current balance", example = "1000.00")
    BigDecimal balance,

    @Schema(description = "ISO 4217 currency code", example = "EUR")
    String currency,

    @Schema(description = "Account status", example = "ACTIVE")
    String status,

    @Schema(description = "Account creation timestamp")
    Instant createdAt
) {}
```

---

## §API-03 CRUD Operations with Proper HTTP Semantics

```java
package com.bank.account.controller;

import com.bank.account.dto.*;
import com.bank.account.service.AccountService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

@RestController
@RequestMapping("/api/v1/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @Operation(summary = "Get account by ID")
    @ApiResponse(responseCode = "200", description = "Account found")
    @ApiResponse(responseCode = "404", description = "Account not found")
    @PreAuthorize("hasRole('ACCOUNT_READ')")
    @GetMapping("/{id}")
    public ResponseEntity<AccountResponse> getAccount(@PathVariable Long id) {
        return ResponseEntity.ok(accountService.getAccount(id));
    }

    @Operation(summary = "List accounts with pagination")
    @ApiResponse(responseCode = "200", description = "Page of accounts")
    @PreAuthorize("hasRole('ACCOUNT_READ')")
    @GetMapping
    public ResponseEntity<Page<AccountResponse>> listAccounts(Pageable pageable) {
        return ResponseEntity.ok(accountService.listAccounts(pageable));
    }

    @Operation(summary = "Create a new account")
    @ApiResponse(responseCode = "201", description = "Account created")
    @ApiResponse(responseCode = "400", description = "Invalid request")
    @PreAuthorize("hasRole('ACCOUNT_WRITE')")
    @PostMapping
    public ResponseEntity<AccountResponse> createAccount(
            @Valid @RequestBody CreateAccountRequest request) {
        AccountResponse created = accountService.createAccount(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}").buildAndExpand(created.id()).toUri();
        return ResponseEntity.created(location).body(created);
    }

    @Operation(summary = "Update account details")
    @ApiResponse(responseCode = "200", description = "Account updated")
    @ApiResponse(responseCode = "404", description = "Account not found")
    @PreAuthorize("hasRole('ACCOUNT_WRITE')")
    @PutMapping("/{id}")
    public ResponseEntity<AccountResponse> updateAccount(
            @PathVariable Long id,
            @Valid @RequestBody UpdateAccountRequest request) {
        return ResponseEntity.ok(accountService.updateAccount(id, request));
    }

    @Operation(summary = "Close an account")
    @ApiResponse(responseCode = "204", description = "Account closed")
    @ApiResponse(responseCode = "404", description = "Account not found")
    @ApiResponse(responseCode = "409", description = "Account has non-zero balance")
    @PreAuthorize("hasRole('ACCOUNT_ADMIN')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> closeAccount(@PathVariable Long id) {
        accountService.closeAccount(id);
        return ResponseEntity.noContent().build();
    }
}
```

---

## §API-04 Pagination with Spring Data

### Service Layer Pagination

```java
@Override
@Transactional(readOnly = true)
public Page<AccountResponse> listAccounts(Pageable pageable) {
    return accountRepository.findAll(pageable)
        .map(accountMapper::toResponse);
}
```

### Pagination Configuration

```java
package com.bank.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.web.config.EnableSpringDataWebSupport;

@Configuration
@EnableSpringDataWebSupport(
    pageSerializationMode = EnableSpringDataWebSupport.PageSerializationMode.VIA_DTO)
public class WebConfig {
}
```

### application.yml — Default Page Size

```yaml
spring:
  data:
    web:
      pageable:
        default-page-size: 20
        max-page-size: 100
```

### Example Request

```
GET /api/v1/accounts?page=0&size=20&sort=createdAt,desc
```

---

## §API-05 Error Handling with RFC 7807 ProblemDetail

### Global Exception Handler

```java
package com.bank.shared.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;
import java.util.List;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle(ex.getResourceType() + " Not Found");
        problem.setType(URI.create("https://api.bank.com/problems/resource-not-found"));
        problem.setProperty("resourceType", ex.getResourceType());
        problem.setProperty("resourceId", ex.getResourceId());
        return problem;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        List<FieldErrorDetail> fieldErrors = ex.getBindingResult()
            .getFieldErrors().stream()
            .map(fe -> new FieldErrorDetail(fe.getField(), fe.getDefaultMessage()))
            .toList();

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, "Validation failed");
        problem.setTitle("Validation Error");
        problem.setType(URI.create("https://api.bank.com/problems/validation-error"));
        problem.setProperty("errors", fieldErrors);
        return problem;
    }

    @ExceptionHandler(BusinessRuleException.class)
    public ProblemDetail handleBusinessRule(BusinessRuleException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());
        problem.setTitle("Business Rule Violation");
        problem.setType(URI.create("https://api.bank.com/problems/business-rule-violation"));
        problem.setProperty("ruleCode", ex.getRuleCode());
        return problem;
    }

    record FieldErrorDetail(String field, String message) {}
}
```

### Example Error Response (JSON)

```json
{
  "type": "https://api.bank.com/problems/resource-not-found",
  "title": "Account Not Found",
  "status": 404,
  "detail": "Account with ID 999 was not found",
  "instance": "/api/v1/accounts/999",
  "resourceType": "Account",
  "resourceId": 999
}
```

---

## §API-06 SpringDoc OpenAPI Configuration

### Gradle Dependency

```groovy
dependencies {
    implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.3.0'
}
```

### OpenAPI Configuration

```java
package com.bank.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI bankOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Bank Account Service API")
                .version("1.0.0")
                .description("REST API for bank account management")
                .contact(new Contact()
                    .name("Platform Engineering")
                    .email("platform@bank.com")))
            .addSecurityItem(new SecurityRequirement().addList("bearer-jwt"))
            .schemaRequirement("bearer-jwt", new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT"));
    }
}
```

### application.yml

```yaml
springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
    enabled: ${SWAGGER_ENABLED:false}  # disabled in production
  default-produces-media-type: application/json
  default-consumes-media-type: application/json
```
