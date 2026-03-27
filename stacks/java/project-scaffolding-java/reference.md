# Project Scaffolding — Java / Spring Boot Reference

## §SCAFF-01 Spring Initializr Configuration

### Recommended Initializr Settings

| Setting | Value |
|---|---|
| Project | Gradle - Groovy |
| Language | Java |
| Spring Boot | 3.3.x |
| Packaging | Jar |
| Java | 21 |
| Group | com.bank |
| Artifact | \<service-name\> |

### Required Dependencies (Initializr selection)

- Spring Web
- Spring Security
- Spring Data JPA
- Spring Boot Actuator
- Validation
- PostgreSQL Driver
- Lombok (optional)

---

## §SCAFF-02 build.gradle — Complete Configuration

```groovy
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.3.0'
    id 'io.spring.dependency-management' version '1.1.4'
    id 'jacoco'
    id 'org.sonarqube' version '5.0.0.4638'
    id 'maven-publish'
}

group = 'com.bank'
version = '0.1.0-SNAPSHOT'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

configurations {
    compileOnly {
        extendsFrom annotationProcessor
    }
}

repositories {
    maven {
        name = 'bankArtifactory'
        url = uri("https://artifactory.bank.com/maven-releases")
        credentials {
            username = findProperty("artifactoryUser") ?: System.getenv("ARTIFACTORY_USER")
            password = findProperty("artifactoryPassword") ?: System.getenv("ARTIFACTORY_PASSWORD")
        }
    }
    mavenCentral()
}

dependencies {
    // Spring Boot starters
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-oauth2-resource-server'

    // Observability
    implementation 'net.logstash.logback:logstash-logback-encoder:7.4'
    implementation 'io.micrometer:micrometer-tracing-bridge-otel'
    implementation 'io.opentelemetry:opentelemetry-exporter-otlp'
    runtimeOnly 'io.micrometer:micrometer-registry-prometheus'

    // Resilience
    implementation 'io.github.resilience4j:resilience4j-spring-boot3:2.2.0'

    // Mapping
    implementation 'org.mapstruct:mapstruct:1.5.5.Final'
    annotationProcessor 'org.mapstruct:mapstruct-processor:1.5.5.Final'

    // OpenAPI
    implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.3.0'

    // Database
    runtimeOnly 'org.postgresql:postgresql'
    implementation 'org.flywaydb:flyway-core'
    runtimeOnly 'org.flywaydb:flyway-database-postgresql'

    // Test
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.security:spring-security-test'
    testImplementation 'org.testcontainers:junit-jupiter'
    testImplementation 'org.testcontainers:postgresql'
    testImplementation 'org.awaitility:awaitility'
    testImplementation 'com.tngtech.archunit:archunit-junit5:1.2.1'
}

test {
    useJUnitPlatform()
    finalizedBy jacocoTestReport
}

jacoco {
    toolVersion = "0.8.11"
}

jacocoTestReport {
    dependsOn test
    reports {
        xml.required = true
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
    }
}

check.dependsOn jacocoTestCoverageVerification
```

### settings.gradle

```groovy
rootProject.name = 'account-service'
```

---

## §SCAFF-03 application.yml Template

### src/main/resources/application.yml

```yaml
spring:
  application:
    name: account-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}

  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/bank}
    username: ${SPRING_DATASOURCE_USERNAME:bank}
    password: ${SPRING_DATASOURCE_PASSWORD:bank}
    hikari:
      maximum-pool-size: ${DB_POOL_SIZE:10}
      minimum-idle: 2
      connection-timeout: 5000

  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        default_schema: public
        format_sql: false

  flyway:
    enabled: true
    locations: classpath:db/migration

  jackson:
    default-property-inclusion: non_null
    deserialization:
      fail-on-unknown-properties: true

server:
  port: ${SERVER_PORT:8080}
  shutdown: graceful
  error:
    include-message: never
    include-stacktrace: never

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: when_authorized
      probes:
        enabled: true
  metrics:
    tags:
      application: ${spring.application.name}

logging:
  level:
    root: INFO
    com.bank: INFO
    org.springframework.security: WARN
```

### src/main/resources/application-local.yml

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/bank_local
    username: bank
    password: bank
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true

server:
  port: 8080

springdoc:
  swagger-ui:
    enabled: true

logging:
  level:
    com.bank: DEBUG
```

### src/main/resources/application-production.yml

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

spring:
  datasource:
    hikari:
      maximum-pool-size: 20

springdoc:
  swagger-ui:
    enabled: false

management:
  tracing:
    sampling:
      probability: 0.1
```

---

## §SCAFF-04 Docker Setup

### Dockerfile

```dockerfile
# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

COPY gradlew .
COPY gradle/ gradle/
RUN chmod +x gradlew

# Cache dependencies
COPY build.gradle settings.gradle ./
RUN ./gradlew dependencies --no-daemon || true

COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# Stage 2: Runtime
FROM gcr.io/distroless/java21-debian12:nonroot
WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080 8443

ENTRYPOINT ["java", \
    "-XX:+UseZGC", \
    "-XX:MaxRAMPercentage=75.0", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "app.jar"]
```

### docker-compose.yml

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: local
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/bank_local
      SPRING_DATASOURCE_USERNAME: bank
      SPRING_DATASOURCE_PASSWORD: bank
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: bank_local
      POSTGRES_USER: bank
      POSTGRES_PASSWORD: bank
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U bank -d bank_local"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  postgres_data:
```

---

## §SCAFF-05 CI Pipeline Starter

### .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  JAVA_VERSION: '21'

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: bank_test
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ env.JAVA_VERSION }}

      - uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}

      - run: chmod +x gradlew

      - name: Build and Test
        run: ./gradlew build
        env:
          SPRING_DATASOURCE_URL: jdbc:postgresql://localhost:5432/bank_test
          SPRING_DATASOURCE_USERNAME: test
          SPRING_DATASOURCE_PASSWORD: test
```

---

## §SCAFF-06 Directory Structure

```
<service-name>/
├── .github/
│   └── workflows/
│       └── ci.yml
├── docs/
│   └── adr/
│       └── 0001-initial-architecture.md
├── gradle/
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── src/
│   ├── main/
│   │   ├── java/com/bank/<service>/
│   │   │   ├── Application.java
│   │   │   ├── config/
│   │   │   │   ├── SecurityConfig.java
│   │   │   │   └── OpenApiConfig.java
│   │   │   ├── <feature>/
│   │   │   │   ├── controller/
│   │   │   │   ├── service/
│   │   │   │   ├── repository/
│   │   │   │   ├── domain/
│   │   │   │   ├── dto/
│   │   │   │   ├── mapper/
│   │   │   │   └── event/
│   │   │   └── shared/
│   │   │       ├── exception/
│   │   │       └── logging/
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-local.yml
│   │       ├── application-production.yml
│   │       ├── db/migration/
│   │       └── logback-spring.xml
│   └── test/
│       └── java/com/bank/<service>/
│           ├── <feature>/
│           │   ├── controller/
│           │   ├── service/
│           │   └── repository/
│           ├── ArchitectureTest.java
│           └── test/
│               └── PostgresIntegrationTest.java
├── .dockerignore
├── .editorconfig
├── .gitignore
├── build.gradle
├── docker-compose.yml
├── Dockerfile
├── gradlew
├── gradlew.bat
├── README.md
└── settings.gradle
```

---

## §SCAFF-07 Standard Project Files

### .gitignore

```
# Gradle
.gradle/
build/
!gradle-wrapper.jar

# IDE
.idea/
*.iml
.vscode/
.project
.classpath
.settings/

# OS
.DS_Store
Thumbs.db

# Environment
.env
*.env.local
```

### .editorconfig

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true

[*.{yml,yaml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

### Application Entry Point

```java
package com.bank.account;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### Flyway Initial Migration — src/main/resources/db/migration/V1__init.sql

```sql
CREATE TABLE IF NOT EXISTS accounts (
    id          BIGSERIAL PRIMARY KEY,
    iban        VARCHAR(34)    NOT NULL UNIQUE,
    owner_name  VARCHAR(100)   NOT NULL,
    amount      NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency    VARCHAR(3)     NOT NULL DEFAULT 'EUR',
    status      VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE',
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_accounts_iban ON accounts (iban);
CREATE INDEX idx_accounts_status ON accounts (status);
```
