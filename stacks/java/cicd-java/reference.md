# CI/CD — Java / Spring Boot Reference

## §CI-01 Gradle Wrapper Setup

### Verify Wrapper

```bash
# Ensure wrapper is committed
gradle wrapper --gradle-version 8.5
git add gradlew gradlew.bat gradle/wrapper/
```

### build.gradle — Base Configuration

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
version = '1.0.0-SNAPSHOT'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    maven {
        url = uri("https://artifactory.bank.com/maven-releases")
        credentials {
            username = findProperty("artifactoryUser") ?: System.getenv("ARTIFACTORY_USER")
            password = findProperty("artifactoryPassword") ?: System.getenv("ARTIFACTORY_PASSWORD")
        }
    }
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.springframework.boot:spring-boot-starter-validation'

    runtimeOnly 'org.postgresql:postgresql'
    runtimeOnly 'io.micrometer:micrometer-registry-prometheus'

    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.security:spring-security-test'
    testImplementation 'org.testcontainers:junit-jupiter'
    testImplementation 'org.testcontainers:postgresql'
}

test {
    useJUnitPlatform()
    finalizedBy jacocoTestReport
}
```

---

## §CI-02 GitHub Actions Workflow

### .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

permissions:
  contents: read
  checks: write
  pull-requests: write

env:
  JAVA_VERSION: '21'
  GRADLE_OPTS: '-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true'

jobs:
  build:
    name: Build & Test
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
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # required for SonarQube

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ env.JAVA_VERSION }}

      - name: Cache Gradle dependencies
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: gradle-${{ runner.os }}-

      - name: Grant execute permission
        run: chmod +x gradlew

      - name: Build
        run: ./gradlew build -x test

      - name: Run tests
        run: ./gradlew test
        env:
          SPRING_DATASOURCE_URL: jdbc:postgresql://localhost:5432/bank_test
          SPRING_DATASOURCE_USERNAME: test
          SPRING_DATASOURCE_PASSWORD: test

      - name: JaCoCo coverage verification
        run: ./gradlew jacocoTestCoverageVerification

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: build/reports/tests/

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: build/reports/jacoco/

  sonar:
    name: SonarQube Analysis
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ env.JAVA_VERSION }}

      - name: SonarQube Scan
        run: ./gradlew sonar
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}

  docker:
    name: Docker Build & Push
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ env.JAVA_VERSION }}

      - name: Build JAR
        run: ./gradlew bootJar

      - name: Build Docker image
        run: |
          docker build \
            -t artifactory.bank.com/docker/account-service:${{ github.sha }} \
            -t artifactory.bank.com/docker/account-service:latest \
            .

      - name: Push to Artifactory
        run: |
          echo "${{ secrets.ARTIFACTORY_PASSWORD }}" | docker login artifactory.bank.com -u "${{ secrets.ARTIFACTORY_USER }}" --password-stdin
          docker push artifactory.bank.com/docker/account-service:${{ github.sha }}
          docker push artifactory.bank.com/docker/account-service:latest
```

---

## §CI-03 JaCoCo Coverage Configuration

```groovy
jacoco {
    toolVersion = "0.8.11"
}

jacocoTestReport {
    dependsOn test
    reports {
        xml.required = true
        html.required = true
        csv.required = false
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
            limit {
                counter = 'BRANCH'
                value = 'COVEREDRATIO'
                minimum = 0.70
            }
        }
        rule {
            element = 'CLASS'
            excludes = [
                'com.bank.config.*',
                'com.bank.*.dto.*',
                'com.bank.*.mapper.*',
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

## §CI-04 SonarQube Configuration

### build.gradle

```groovy
sonar {
    properties {
        property "sonar.projectKey", "com.bank:account-service"
        property "sonar.projectName", "Account Service"
        property "sonar.host.url", System.getenv("SONAR_HOST_URL") ?: "https://sonar.bank.com"
        property "sonar.token", System.getenv("SONAR_TOKEN") ?: ""
        property "sonar.sources", "src/main/java"
        property "sonar.tests", "src/test/java"
        property "sonar.java.binaries", "build/classes/java/main"
        property "sonar.coverage.jacoco.xmlReportPaths", "build/reports/jacoco/test/jacocoTestReport.xml"
        property "sonar.qualitygate.wait", "true"
    }
}
```

---

## §CI-05 Docker Multi-Stage Build

### Dockerfile

```dockerfile
# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

COPY gradlew .
COPY gradle/ gradle/
COPY build.gradle settings.gradle ./
COPY src/ src/

RUN chmod +x gradlew && ./gradlew bootJar --no-daemon -x test

# Stage 2: Runtime
FROM gcr.io/distroless/java21-debian12:nonroot

LABEL maintainer="platform@bank.com"
LABEL org.opencontainers.image.source="https://github.com/bank/account-service"

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8443

ENTRYPOINT ["java", \
    "-XX:+UseZGC", \
    "-XX:MaxRAMPercentage=75.0", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "app.jar"]
```

### .dockerignore

```
.git
.gradle
build/
*.md
.github/
```

---

## §CI-06 Artifact Publishing to Artifactory

### build.gradle

```groovy
publishing {
    publications {
        mavenJava(MavenPublication) {
            from components.java
            artifactId = 'account-service'
            groupId = 'com.bank'
            version = project.version

            pom {
                name = 'Account Service'
                description = 'Bank account management service'
            }
        }
    }
    repositories {
        maven {
            name = 'artifactory'
            url = uri(project.version.toString().endsWith('-SNAPSHOT')
                ? "https://artifactory.bank.com/maven-snapshots"
                : "https://artifactory.bank.com/maven-releases")
            credentials {
                username = System.getenv("ARTIFACTORY_USER")
                password = System.getenv("ARTIFACTORY_PASSWORD")
            }
        }
    }
}
```

### Publish Step in CI

```yaml
- name: Publish to Artifactory
  if: github.ref == 'refs/heads/main'
  run: ./gradlew publish
  env:
    ARTIFACTORY_USER: ${{ secrets.ARTIFACTORY_USER }}
    ARTIFACTORY_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }}
```
