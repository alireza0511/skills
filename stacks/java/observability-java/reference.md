# Observability — Java / Spring Boot Reference

## §OBS-01 Structured JSON Logging with Logback

### Gradle Dependencies

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'net.logstash.logback:logstash-logback-encoder:7.4'
    implementation 'io.micrometer:micrometer-tracing-bridge-otel'
    implementation 'io.opentelemetry:opentelemetry-exporter-otlp'
    runtimeOnly 'io.micrometer:micrometer-registry-prometheus'
}
```

### logback-spring.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <springProperty scope="context" name="appName" source="spring.application.name"/>
    <springProperty scope="context" name="appEnv" source="spring.profiles.active" defaultValue="local"/>

    <!-- Console for local development -->
    <springProfile name="local">
        <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} [%X{traceId}/%X{spanId}] - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="CONSOLE"/>
        </root>
    </springProfile>

    <!-- Structured JSON for non-local environments -->
    <springProfile name="!local">
        <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="net.logstash.logback.encoder.LogstashEncoder">
                <includeMdcKeyName>traceId</includeMdcKeyName>
                <includeMdcKeyName>spanId</includeMdcKeyName>
                <includeMdcKeyName>requestId</includeMdcKeyName>
                <customFields>{"service":"${appName}","env":"${appEnv}"}</customFields>
                <fieldNames>
                    <timestamp>@timestamp</timestamp>
                    <version>[ignore]</version>
                </fieldNames>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="JSON"/>
        </root>
    </springProfile>

    <!-- Suppress noisy libraries -->
    <logger name="org.hibernate.SQL" level="WARN"/>
    <logger name="org.apache.kafka" level="WARN"/>
</configuration>
```

### Example JSON Output

```json
{
  "@timestamp": "2025-03-15T10:30:00.123Z",
  "level": "INFO",
  "logger_name": "com.bank.transfer.service.TransferService",
  "message": "Transfer completed [amount=200.00, currency=EUR]",
  "thread_name": "http-nio-8080-exec-1",
  "service": "account-service",
  "env": "production",
  "traceId": "64f2b8a1c3e4d5f6a7b8c9d0e1f2a3b4",
  "spanId": "a1b2c3d4e5f6a7b8"
}
```

---

## §OBS-02 Micrometer Custom Metrics

```java
package com.bank.transfer.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Service;

@Service
public class TransferService {

    private final Counter transferSuccessCounter;
    private final Counter transferFailureCounter;
    private final Timer transferTimer;

    public TransferService(MeterRegistry meterRegistry,
                           AccountRepository accountRepository) {
        this.transferSuccessCounter = Counter.builder("bank.transfers.completed")
            .description("Number of successful transfers")
            .tag("type", "domestic")
            .register(meterRegistry);

        this.transferFailureCounter = Counter.builder("bank.transfers.failed")
            .description("Number of failed transfers")
            .tag("type", "domestic")
            .register(meterRegistry);

        this.transferTimer = Timer.builder("bank.transfers.duration")
            .description("Transfer processing duration")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(meterRegistry);
    }

    public TransferResult execute(TransferRequest request) {
        return transferTimer.record(() -> {
            try {
                TransferResult result = processTransfer(request);
                transferSuccessCounter.increment();
                return result;
            } catch (Exception e) {
                transferFailureCounter.increment();
                throw e;
            }
        });
    }
}
```

### Custom Gauge Example

```java
@Component
public class AccountMetrics {

    public AccountMetrics(MeterRegistry registry, AccountRepository repository) {
        Gauge.builder("bank.accounts.active", repository, repo ->
                repo.countByStatus(AccountStatus.ACTIVE))
            .description("Number of active accounts")
            .register(registry);
    }
}
```

---

## §OBS-03 Distributed Tracing with Micrometer Tracing

### application.yml

```yaml
management:
  tracing:
    sampling:
      probability: 1.0  # 100% in dev/staging; lower in production
  otlp:
    tracing:
      endpoint: ${OTEL_EXPORTER_OTLP_ENDPOINT:http://localhost:4318/v1/traces}

logging:
  pattern:
    correlation: "[${spring.application.name:},%X{traceId:-},%X{spanId:-}]"
```

### Custom Span Example

```java
package com.bank.transfer.service;

import io.micrometer.observation.annotation.Observed;
import io.micrometer.tracing.Tracer;
import io.micrometer.tracing.annotation.NewSpan;
import io.micrometer.tracing.annotation.SpanTag;
import org.springframework.stereotype.Service;

@Service
public class TransferValidationService {

    private final Tracer tracer;

    public TransferValidationService(Tracer tracer) {
        this.tracer = tracer;
    }

    @NewSpan("validate-transfer")
    public ValidationResult validate(
            @SpanTag("transfer.currency") String currency,
            @SpanTag("transfer.amount") BigDecimal amount) {
        // Validation logic — automatically traced
        return ValidationResult.valid();
    }

    @Observed(name = "fraud.check", contextualName = "fraud-check")
    public FraudCheckResult checkFraud(TransferRequest request) {
        // Fraud check — creates observation with metrics + trace
        return FraudCheckResult.clear();
    }
}
```

---

## §OBS-04 PII Masking Utility

```java
package com.bank.shared.logging;

public final class LogMask {

    private LogMask() {}

    /**
     * Masks an IBAN showing only last 4 characters.
     * Input:  NL91ABNA0417164300
     * Output: **************4300
     */
    public static String iban(String iban) {
        if (iban == null || iban.length() < 4) return "****";
        return "*".repeat(iban.length() - 4) + iban.substring(iban.length() - 4);
    }

    /**
     * Masks an account number showing only last 4 digits.
     */
    public static String account(String accountNumber) {
        if (accountNumber == null || accountNumber.length() < 4) return "****";
        return "****" + accountNumber.substring(accountNumber.length() - 4);
    }

    /**
     * Masks a name showing only first initial.
     * Input:  Jan de Vries
     * Output: J***
     */
    public static String name(String name) {
        if (name == null || name.isBlank()) return "****";
        return name.charAt(0) + "***";
    }

    /**
     * Masks an email.
     * Input:  jan.devries@bank.com
     * Output: j***@bank.com
     */
    public static String email(String email) {
        if (email == null || !email.contains("@")) return "****";
        int atIndex = email.indexOf('@');
        return email.charAt(0) + "***" + email.substring(atIndex);
    }
}
```

### Usage in Service

```java
import static com.bank.shared.logging.LogMask.*;

@Service
@Slf4j
public class TransferService {

    public TransferResult execute(TransferRequest request) {
        log.info("Initiating transfer from [iban={}] to [iban={}], amount={}",
            iban(request.sourceIban()),
            iban(request.destinationIban()),
            request.amount());
        // ...
    }
}
```

---

## §OBS-05 Actuator Configuration

### application.yml

```yaml
management:
  endpoints:
    web:
      base-path: /actuator
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: when_authorized
      show-components: when_authorized
      probes:
        enabled: true  # Kubernetes liveness/readiness
  info:
    env:
      enabled: true
    git:
      enabled: true
    build:
      enabled: true
  metrics:
    tags:
      application: ${spring.application.name}
      environment: ${spring.profiles.active:local}
    distribution:
      percentiles-histogram:
        http.server.requests: true
```

### Security for Actuator Endpoints

```java
// In SecurityConfig — permit health probes, secure the rest
.requestMatchers("/actuator/health/**", "/actuator/info").permitAll()
.requestMatchers("/actuator/**").hasRole("ACTUATOR_ADMIN")
```

---

## §OBS-06 Custom Health Indicators

```java
package com.bank.config.health;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;
import org.springframework.vault.core.VaultTemplate;

@Component("vault")
public class VaultHealthIndicator implements HealthIndicator {

    private final VaultTemplate vaultTemplate;

    public VaultHealthIndicator(VaultTemplate vaultTemplate) {
        this.vaultTemplate = vaultTemplate;
    }

    @Override
    public Health health() {
        try {
            var sealStatus = vaultTemplate.opsForSys().health();
            if (sealStatus.isInitialized() && !sealStatus.isSealed()) {
                return Health.up()
                    .withDetail("initialized", true)
                    .withDetail("sealed", false)
                    .build();
            }
            return Health.down()
                .withDetail("initialized", sealStatus.isInitialized())
                .withDetail("sealed", sealStatus.isSealed())
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

### Database Connection Pool Health

```java
@Component("connectionPool")
public class ConnectionPoolHealthIndicator implements HealthIndicator {

    private final DataSource dataSource;

    public ConnectionPoolHealthIndicator(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public Health health() {
        if (dataSource instanceof HikariDataSource hikari) {
            HikariPoolMXBean pool = hikari.getHikariPoolMXBean();
            int active = pool.getActiveConnections();
            int total = pool.getTotalConnections();
            int waiting = pool.getThreadsAwaitingConnection();

            Health.Builder builder = (waiting > 5)
                ? Health.down() : Health.up();

            return builder
                .withDetail("active", active)
                .withDetail("total", total)
                .withDetail("waiting", waiting)
                .withDetail("max", hikari.getMaximumPoolSize())
                .build();
        }
        return Health.unknown().build();
    }
}
```
