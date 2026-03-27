# Security — Java / Spring Boot Reference

## §SEC-01 Security Filter Chain with OAuth 2.0 Resource Server

### Gradle Dependencies

```groovy
// build.gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-oauth2-resource-server'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
}
```

### Security Configuration

```java
package com.bank.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll())
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())))
            .headers(headers -> headers
                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31536000))
                .frameOptions(frame -> frame.deny())
                .contentTypeOptions(content -> {})
                .xssProtection(xss -> {}));

        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter grantedAuthorities = new JwtGrantedAuthoritiesConverter();
        grantedAuthorities.setAuthoritiesClaimName("roles");
        grantedAuthorities.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(grantedAuthorities);
        return converter;
    }
}
```

### application.yml — JWT Issuer Config

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${OAUTH2_ISSUER_URI}
          jwk-set-uri: ${OAUTH2_JWK_SET_URI}
```

---

## §SEC-02 Method-Level Security with @PreAuthorize

```java
package com.bank.account.service;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

@Service
public class AccountService {

    @PreAuthorize("hasRole('ACCOUNT_READ')")
    public AccountDto getAccount(Long accountId) {
        return accountRepository.findById(accountId)
            .map(accountMapper::toDto)
            .orElseThrow(() -> new AccountNotFoundException(accountId));
    }

    @PreAuthorize("hasRole('TRANSFER_WRITE') and @accountOwnershipChecker.isOwner(#request.sourceAccountId)")
    public TransferResult initiateTransfer(TransferRequest request) {
        // ownership verified via SpEL bean reference
        return transferService.execute(request);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'COMPLIANCE_OFFICER')")
    public List<AuditEntry> getAuditTrail(Long accountId) {
        return auditRepository.findByAccountId(accountId);
    }
}
```

### Custom Ownership Checker Bean

```java
package com.bank.account.security;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component("accountOwnershipChecker")
public class AccountOwnershipChecker {

    private final AccountRepository accountRepository;

    public AccountOwnershipChecker(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    public boolean isOwner(Long accountId) {
        String currentUserId = SecurityContextHolder.getContext()
            .getAuthentication().getName();
        return accountRepository.isOwnedBy(accountId, currentUserId);
    }
}
```

---

## §SEC-03 Vault Integration

### Gradle Dependencies

```groovy
dependencies {
    implementation 'org.springframework.cloud:spring-cloud-starter-vault-config'
}
```

### bootstrap.yml — Vault Configuration

```yaml
spring:
  cloud:
    vault:
      uri: ${VAULT_ADDR:https://vault.internal.bank.com:8200}
      authentication: KUBERNETES
      kubernetes:
        role: ${VAULT_ROLE}
        service-account-token-file: /var/run/secrets/kubernetes.io/serviceaccount/token
      kv:
        enabled: true
        backend: secret
        default-context: ${spring.application.name}
      ssl:
        trust-store: classpath:vault-truststore.jks
        trust-store-password: ${VAULT_TRUSTSTORE_PASSWORD}
```

### Using Vault Secrets

```java
package com.bank.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DataSourceConfig {

    // Injected from Vault path: secret/<app-name>/database
    @Value("${database.username}")
    private String dbUsername;

    @Value("${database.password}")
    private String dbPassword;

    @Bean
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://db.internal.bank.com:5432/accounts");
        config.setUsername(dbUsername);
        config.setPassword(dbPassword);
        config.setMaximumPoolSize(20);
        return new HikariDataSource(config);
    }
}
```

---

## §SEC-04 Jakarta Validation on Request DTOs

```java
package com.bank.transfer.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record TransferRequest(

    @NotNull(message = "Source account is required")
    @Positive(message = "Source account ID must be positive")
    Long sourceAccountId,

    @NotNull(message = "Destination account is required")
    @Positive(message = "Destination account ID must be positive")
    Long destinationAccountId,

    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Minimum transfer amount is 0.01")
    @DecimalMax(value = "1000000.00", message = "Maximum transfer amount is 1,000,000.00")
    BigDecimal amount,

    @NotBlank(message = "Currency is required")
    @Pattern(regexp = "^[A-Z]{3}$", message = "Currency must be a 3-letter ISO code")
    String currency,

    @Size(max = 140, message = "Reference must not exceed 140 characters")
    String reference
) {}
```

### Custom Validator Example

```java
package com.bank.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = IbanValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidIban {
    String message() default "Invalid IBAN format";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

```java
package com.bank.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import org.iban4j.IbanUtil;

public class IbanValidator implements ConstraintValidator<ValidIban, String> {

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || value.isBlank()) {
            return true; // use @NotBlank for null checks
        }
        try {
            IbanUtil.validate(value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
```

---

## §SEC-05 TLS Configuration

### application.yml

```yaml
server:
  port: 8443
  ssl:
    enabled: true
    protocol: TLS
    enabled-protocols: TLSv1.3
    key-store: ${SSL_KEYSTORE_PATH}
    key-store-password: ${SSL_KEYSTORE_PASSWORD}
    key-store-type: PKCS12
    ciphers:
      - TLS_AES_256_GCM_SHA384
      - TLS_AES_128_GCM_SHA256
  http2:
    enabled: true
```

---

## §SEC-06 Security Headers and CORS

### CORS Configuration

```java
@Bean
public CorsConfigurationSource corsConfigurationSource(
        @Value("${app.cors.allowed-origins}") List<String> allowedOrigins) {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(allowedOrigins); // never "*"
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Request-ID"));
    config.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```

---

## §SEC-07 Security Integration Tests

```java
package com.bank.account;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class AccountSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void should_reject_unauthenticated_request() throws Exception {
        mockMvc.perform(get("/api/v1/accounts/123"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "ACCOUNT_READ")
    void should_allow_authorized_account_read() throws Exception {
        mockMvc.perform(get("/api/v1/accounts/123"))
            .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "TRANSFER_WRITE")
    void should_deny_account_read_with_wrong_role() throws Exception {
        mockMvc.perform(get("/api/v1/accounts/123"))
            .andExpect(status().isForbidden());
    }
}
```

### Parameterized Query Repository Test

```java
@DataJpaTest
class AccountRepositoryTest {

    @Autowired
    private AccountRepository accountRepository;

    @Test
    void should_find_account_by_iban_with_parameterized_query() {
        Account account = new Account("NL91ABNA0417164300", "John Doe");
        accountRepository.save(account);

        Optional<Account> found = accountRepository.findByIban("NL91ABNA0417164300");

        assertThat(found).isPresent();
        assertThat(found.get().getOwnerName()).isEqualTo("John Doe");
    }
}
```
