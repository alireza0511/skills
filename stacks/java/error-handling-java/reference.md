# Error Handling — Java / Spring Boot Reference

## §ERR-01 Exception Hierarchy

### Base Exception

```java
package com.bank.shared.exception;

import org.springframework.http.HttpStatus;

public abstract class BankException extends RuntimeException {

    private final String errorCode;
    private final HttpStatus httpStatus;

    protected BankException(String message, String errorCode, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }

    protected BankException(String message, String errorCode, HttpStatus httpStatus, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }

    public String getErrorCode() { return errorCode; }
    public HttpStatus getHttpStatus() { return httpStatus; }
}
```

### Resource Not Found

```java
package com.bank.shared.exception;

import org.springframework.http.HttpStatus;

public class ResourceNotFoundException extends BankException {

    private final String resourceType;
    private final Object resourceId;

    public ResourceNotFoundException(String resourceType, Object resourceId) {
        super(
            String.format("%s with ID %s was not found", resourceType, resourceId),
            "RESOURCE_NOT_FOUND",
            HttpStatus.NOT_FOUND
        );
        this.resourceType = resourceType;
        this.resourceId = resourceId;
    }

    public String getResourceType() { return resourceType; }
    public Object getResourceId() { return resourceId; }
}
```

### Business Rule Violation

```java
package com.bank.shared.exception;

import org.springframework.http.HttpStatus;

public class BusinessRuleException extends BankException {

    private final String ruleCode;

    public BusinessRuleException(String message, String ruleCode) {
        super(message, ruleCode, HttpStatus.UNPROCESSABLE_ENTITY);
        this.ruleCode = ruleCode;
    }

    public String getRuleCode() { return ruleCode; }
}
```

### Domain-Specific Exceptions

```java
package com.bank.account.exception;

import com.bank.shared.exception.ResourceNotFoundException;

public class AccountNotFoundException extends ResourceNotFoundException {
    public AccountNotFoundException(Long accountId) {
        super("Account", accountId);
    }
}
```

```java
package com.bank.transfer.exception;

import com.bank.shared.exception.BusinessRuleException;
import java.math.BigDecimal;

public class InsufficientFundsException extends BusinessRuleException {
    public InsufficientFundsException(Long accountId, BigDecimal requested) {
        super(
            String.format("Insufficient funds in account %d for amount %s", accountId, requested),
            "INSUFFICIENT_FUNDS"
        );
    }
}
```

```java
package com.bank.transfer.exception;

import com.bank.shared.exception.BusinessRuleException;

public class DuplicateTransferException extends BusinessRuleException {
    public DuplicateTransferException(String idempotencyKey) {
        super(
            String.format("Transfer with idempotency key '%s' already processed", idempotencyKey),
            "DUPLICATE_TRANSFER"
        );
    }
}
```

---

## §ERR-02 Global @RestControllerAdvice

```java
package com.bank.shared.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.net.URI;
import java.util.List;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    private static final String PROBLEM_BASE_URI = "https://api.bank.com/problems/";

    // --- Bank domain exceptions ---

    @ExceptionHandler(BankException.class)
    public ProblemDetail handleBankException(BankException ex) {
        log.warn("Business exception: [code={}] {}", ex.getErrorCode(), ex.getMessage());

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            ex.getHttpStatus(), ex.getMessage());
        problem.setType(URI.create(PROBLEM_BASE_URI + ex.getErrorCode().toLowerCase().replace('_', '-')));
        problem.setTitle(toTitle(ex.getErrorCode()));
        problem.setProperty("errorCode", ex.getErrorCode());
        return problem;
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: [type={}, id={}]", ex.getResourceType(), ex.getResourceId());

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setType(URI.create(PROBLEM_BASE_URI + "resource-not-found"));
        problem.setTitle(ex.getResourceType() + " Not Found");
        problem.setProperty("resourceType", ex.getResourceType());
        problem.setProperty("resourceId", ex.getResourceId());
        return problem;
    }

    // --- Validation exceptions ---

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        List<FieldError> fieldErrors = ex.getBindingResult()
            .getFieldErrors().stream()
            .map(fe -> new FieldError(fe.getField(), fe.getDefaultMessage(),
                fe.getRejectedValue() != null ? fe.getRejectedValue().toString() : null))
            .toList();

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, "Request validation failed");
        problem.setType(URI.create(PROBLEM_BASE_URI + "validation-error"));
        problem.setTitle("Validation Error");
        problem.setProperty("errors", fieldErrors);
        return problem;
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ProblemDetail handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST,
            String.format("Parameter '%s' must be of type %s",
                ex.getName(), ex.getRequiredType().getSimpleName()));
        problem.setType(URI.create(PROBLEM_BASE_URI + "type-mismatch"));
        problem.setTitle("Invalid Parameter Type");
        return problem;
    }

    // --- Catch-all ---

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred");
        problem.setType(URI.create(PROBLEM_BASE_URI + "internal-error"));
        problem.setTitle("Internal Server Error");
        // Never include stack trace or internal details
        return problem;
    }

    private String toTitle(String errorCode) {
        return errorCode.replace('_', ' ').substring(0, 1).toUpperCase()
            + errorCode.replace('_', ' ').substring(1).toLowerCase();
    }

    record FieldError(String field, String message, String rejectedValue) {}
}
```

### Example Error Responses

```json
// 404 — Resource Not Found
{
  "type": "https://api.bank.com/problems/resource-not-found",
  "title": "Account Not Found",
  "status": 404,
  "detail": "Account with ID 999 was not found",
  "resourceType": "Account",
  "resourceId": 999
}

// 400 — Validation Error
{
  "type": "https://api.bank.com/problems/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "Request validation failed",
  "errors": [
    { "field": "amount", "message": "Minimum transfer amount is 0.01", "rejectedValue": "-5.00" },
    { "field": "currency", "message": "Currency must be a 3-letter ISO code", "rejectedValue": "EU" }
  ]
}

// 422 — Business Rule Violation
{
  "type": "https://api.bank.com/problems/insufficient-funds",
  "title": "Insufficient funds",
  "status": 422,
  "detail": "Insufficient funds in account 123 for amount 10000.00",
  "errorCode": "INSUFFICIENT_FUNDS"
}
```

---

## §ERR-03 Spring Retry Configuration

### Gradle Dependencies

```groovy
dependencies {
    implementation 'org.springframework.retry:spring-retry'
    implementation 'org.springframework:spring-aspects'
}
```

### Enable Retry

```java
package com.bank.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.retry.annotation.EnableRetry;

@Configuration
@EnableRetry
public class RetryConfig {
}
```

### Service with Retry

```java
package com.bank.payment.service;

import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;

@Service
public class PaymentGatewayClient {

    @Retryable(
        retryFor = {TransientPaymentException.class, ConnectionException.class},
        noRetryFor = {PaymentRejectedException.class},
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2.0, maxDelay = 10000))
    public PaymentResult submitPayment(PaymentRequest request) {
        log.info("Submitting payment [ref={}], attempt", request.reference());
        return paymentGateway.submit(request);
    }

    @Recover
    public PaymentResult recoverPayment(TransientPaymentException ex, PaymentRequest request) {
        log.error("Payment failed after retries [ref={}]", request.reference(), ex);
        return PaymentResult.failed(request.reference(), "Gateway unavailable after retries");
    }
}
```

---

## §ERR-04 Resilience4j Circuit Breaker

### Gradle Dependencies

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-aop'
    implementation 'io.github.resilience4j:resilience4j-spring-boot3:2.2.0'
    implementation 'io.github.resilience4j:resilience4j-micrometer:2.2.0'
}
```

### application.yml

```yaml
resilience4j:
  circuitbreaker:
    instances:
      paymentGateway:
        registerHealthIndicator: true
        slidingWindowType: COUNT_BASED
        slidingWindowSize: 10
        minimumNumberOfCalls: 5
        failureRateThreshold: 50
        waitDurationInOpenState: 30s
        permittedNumberOfCallsInHalfOpenState: 3
        automaticTransitionFromOpenToHalfOpenEnabled: true
        recordExceptions:
          - java.net.ConnectException
          - java.net.SocketTimeoutException
          - com.bank.payment.exception.TransientPaymentException
        ignoreExceptions:
          - com.bank.payment.exception.PaymentRejectedException

  retry:
    instances:
      paymentGateway:
        maxAttempts: 3
        waitDuration: 1s
        enableExponentialBackoff: true
        exponentialBackoffMultiplier: 2
        retryExceptions:
          - java.net.ConnectException
          - com.bank.payment.exception.TransientPaymentException

  timelimiter:
    instances:
      paymentGateway:
        timeoutDuration: 5s
        cancelRunningFuture: true
```

### Service with Circuit Breaker

```java
package com.bank.payment.service;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.timelimiter.annotation.TimeLimiter;
import org.springframework.stereotype.Service;

@Service
public class PaymentGatewayClient {

    @CircuitBreaker(name = "paymentGateway", fallbackMethod = "paymentFallback")
    @Retry(name = "paymentGateway")
    public PaymentResult submitPayment(PaymentRequest request) {
        return paymentGateway.submit(request);
    }

    private PaymentResult paymentFallback(PaymentRequest request, Throwable throwable) {
        log.warn("Circuit breaker open for payment gateway [ref={}]: {}",
            request.reference(), throwable.getMessage());
        return PaymentResult.deferred(request.reference(),
            "Payment queued — gateway temporarily unavailable");
    }
}
```

---

## §ERR-05 Structured Error Logging

```java
package com.bank.shared.logging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class ErrorLogger {

    private ErrorLogger() {}

    /**
     * Log a business error with structured context.
     */
    public static void logBusinessError(Logger log, String operation,
                                         String errorCode, String message,
                                         Object... contextPairs) {
        StringBuilder sb = new StringBuilder()
            .append("Business error in ").append(operation)
            .append(" [code=").append(errorCode).append("]")
            .append(" ").append(message);

        for (int i = 0; i < contextPairs.length - 1; i += 2) {
            sb.append(" [").append(contextPairs[i]).append("=")
              .append(contextPairs[i + 1]).append("]");
        }

        log.warn(sb.toString());
    }
}
```

### Usage

```java
ErrorLogger.logBusinessError(log,
    "transfer",
    "INSUFFICIENT_FUNDS",
    "Transfer rejected",
    "accountId", accountId,
    "requestedAmount", amount);
// Output: Business error in transfer [code=INSUFFICIENT_FUNDS] Transfer rejected [accountId=123] [requestedAmount=10000.00]
```
