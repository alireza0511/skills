# Testing — Java / Spring Boot Reference

## §TEST-01 Test Slice Selection

### Gradle Dependencies

```groovy
dependencies {
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.testcontainers:junit-jupiter'
    testImplementation 'org.testcontainers:postgresql'
    testImplementation 'org.awaitility:awaitility'
}
```

### Unit Test — No Spring Context

```java
package com.bank.transfer.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class TransferServiceTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransferEventPublisher eventPublisher;

    @InjectMocks
    private TransferService transferService;

    @Test
    void should_debit_source_account_when_transfer_succeeds() {
        // Arrange
        Account source = Account.withBalance(new BigDecimal("1000.00"));
        Account destination = Account.withBalance(new BigDecimal("500.00"));
        given(accountRepository.findById(1L)).willReturn(Optional.of(source));
        given(accountRepository.findById(2L)).willReturn(Optional.of(destination));

        // Act
        TransferResult result = transferService.execute(
            new TransferRequest(1L, 2L, new BigDecimal("200.00"), "EUR", null));

        // Assert
        assertThat(source.getBalance()).isEqualByComparingTo("800.00");
        assertThat(result.status()).isEqualTo(TransferStatus.COMPLETED);
    }

    @Test
    void should_throw_insufficient_funds_when_balance_too_low() {
        // Arrange
        Account source = Account.withBalance(new BigDecimal("50.00"));
        given(accountRepository.findById(1L)).willReturn(Optional.of(source));

        // Act & Assert
        assertThatThrownBy(() -> transferService.execute(
            new TransferRequest(1L, 2L, new BigDecimal("200.00"), "EUR", null)))
            .isInstanceOf(InsufficientFundsException.class)
            .hasMessageContaining("Insufficient funds");
    }
}
```

### Controller Slice Test — @WebMvcTest

```java
package com.bank.account.controller;

import com.bank.account.service.AccountService;
import com.bank.account.dto.AccountDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.bean.MockBean;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AccountController.class)
class AccountControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AccountService accountService;

    @Test
    @WithMockUser(roles = "ACCOUNT_READ")
    void should_return_account_when_valid_id() throws Exception {
        // Arrange
        given(accountService.getAccount(123L))
            .willReturn(new AccountDto(123L, "NL91ABNA0417164300", "EUR"));

        // Act & Assert
        mockMvc.perform(get("/api/v1/accounts/123"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(123))
            .andExpect(jsonPath("$.iban").value("NL91ABNA0417164300"));
    }

    @Test
    @WithMockUser(roles = "ACCOUNT_READ")
    void should_return_404_when_account_not_found() throws Exception {
        given(accountService.getAccount(999L))
            .willThrow(new AccountNotFoundException(999L));

        mockMvc.perform(get("/api/v1/accounts/999"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.title").value("Account Not Found"));
    }
}
```

### Repository Slice Test — @DataJpaTest

```java
package com.bank.account.repository;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class AccountRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private AccountRepository accountRepository;

    @Test
    void should_find_account_by_iban_when_exists() {
        // Arrange
        Account account = new Account("NL91ABNA0417164300", "John Doe", "EUR");
        entityManager.persistAndFlush(account);

        // Act
        Optional<Account> found = accountRepository.findByIban("NL91ABNA0417164300");

        // Assert
        assertThat(found).isPresent();
        assertThat(found.get().getOwnerName()).isEqualTo("John Doe");
    }

    @Test
    void should_return_empty_when_iban_not_found() {
        Optional<Account> found = accountRepository.findByIban("INVALID");
        assertThat(found).isEmpty();
    }
}
```

---

## §TEST-02 Arrange-Act-Assert Pattern

All tests must follow the Arrange-Act-Assert (AAA) pattern with clear section separation:

```java
@Test
void should_calculate_interest_when_positive_balance() {
    // Arrange
    Account account = Account.withBalance(new BigDecimal("10000.00"));
    InterestPolicy policy = new InterestPolicy(new BigDecimal("0.035"));

    // Act
    BigDecimal interest = policy.calculate(account, Period.ofMonths(12));

    // Assert
    assertThat(interest).isEqualByComparingTo("350.00");
}
```

---

## §TEST-03 Testcontainers for Integration Tests

### PostgreSQL Testcontainer Base Class

```java
package com.bank.test;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers
public abstract class PostgresIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("bank_test")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

### Full Integration Test

```java
package com.bank.transfer;

import com.bank.test.PostgresIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class TransferIntegrationTest extends PostgresIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void should_complete_transfer_when_funds_available() {
        // Arrange — seed via repository or SQL
        TransferRequest request = new TransferRequest(1L, 2L,
            new BigDecimal("100.00"), "EUR", "Test transfer");

        // Act
        ResponseEntity<TransferResult> response = restTemplate
            .postForEntity("/api/v1/transfers", request, TransferResult.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().status()).isEqualTo(TransferStatus.COMPLETED);
    }
}
```

---

## §TEST-04 Awaitility for Async Testing

```java
package com.bank.notification;

import org.awaitility.Awaitility;
import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class NotificationIntegrationTest extends PostgresIntegrationTest {

    @Autowired
    private NotificationRepository notificationRepository;

    @Test
    void should_send_notification_when_transfer_completed() {
        // Arrange
        triggerTransfer();

        // Assert — wait for async event processing
        Awaitility.await()
            .atMost(Duration.ofSeconds(10))
            .pollInterval(Duration.ofMillis(500))
            .untilAsserted(() -> {
                List<Notification> notifications = notificationRepository
                    .findByAccountId(1L);
                assertThat(notifications).hasSize(1);
                assertThat(notifications.get(0).getType())
                    .isEqualTo(NotificationType.TRANSFER_COMPLETED);
            });
    }
}
```

---

## §TEST-05 JaCoCo Configuration

### build.gradle

```groovy
plugins {
    id 'jacoco'
}

jacoco {
    toolVersion = "0.8.11"
}

jacocoTestReport {
    dependsOn test
    reports {
        xml.required = true  // required for SonarQube
        html.required = true
    }
}

jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                counter = 'LINE'
                value = 'COVEREDRATIO'
                minimum = 0.80
            }
        }
        rule {
            element = 'CLASS'
            excludes = [
                'com.bank.config.*',
                'com.bank.*.dto.*',
                'com.bank.Application'
            ]
            limit {
                counter = 'LINE'
                value = 'COVEREDRATIO'
                minimum = 0.80
            }
        }
    }
}

check.dependsOn jacocoTestCoverageVerification
```

---

## §TEST-06 Test Quality Checklist

### Parameterized Tests

```java
@ParameterizedTest
@CsvSource({
    "100.00,  EUR, true",
    "0.00,    EUR, false",
    "-50.00,  EUR, false",
    "100.00,  '',  false"
})
void should_validate_transfer_amount(String amount, String currency, boolean valid) {
    TransferRequest request = new TransferRequest(
        1L, 2L, new BigDecimal(amount), currency, null);

    Set<ConstraintViolation<TransferRequest>> violations =
        validator.validate(request);

    assertThat(violations.isEmpty()).isEqualTo(valid);
}
```

### Custom AssertJ Assertion

```java
package com.bank.test.assertions;

import org.assertj.core.api.AbstractAssert;

public class TransferResultAssert extends AbstractAssert<TransferResultAssert, TransferResult> {

    public TransferResultAssert(TransferResult actual) {
        super(actual, TransferResultAssert.class);
    }

    public static TransferResultAssert assertThat(TransferResult actual) {
        return new TransferResultAssert(actual);
    }

    public TransferResultAssert isCompleted() {
        isNotNull();
        if (actual.status() != TransferStatus.COMPLETED) {
            failWithMessage("Expected transfer to be COMPLETED but was <%s>", actual.status());
        }
        return this;
    }

    public TransferResultAssert hasReferenceId() {
        isNotNull();
        if (actual.referenceId() == null || actual.referenceId().isBlank()) {
            failWithMessage("Expected transfer to have a reference ID");
        }
        return this;
    }
}
```
