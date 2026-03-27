# License Compliance — Java / Spring Boot Reference

## §LIC-01 Plugin Configuration

### build.gradle

```groovy
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.3.0'
    id 'io.spring.dependency-management' version '1.1.4'
    id 'com.github.jk1.dependency-license-report' version '2.7'
    id 'org.cyclonedx.bom' version '1.8.2'
}
```

### License Report Plugin Configuration

```groovy
import com.github.jk1.license.filter.LicenseBundleNormalizer
import com.github.jk1.license.render.JsonReportRenderer
import com.github.jk1.license.render.SimpleHtmlReportRenderer

licenseReport {
    outputDir = "${project.buildDir}/reports/licenses"
    renderers = [
        new JsonReportRenderer('licenses.json'),
        new SimpleHtmlReportRenderer('licenses.html')
    ]
    filters = [
        new LicenseBundleNormalizer(bundlePath: "${projectDir}/license-normalizer-bundle.json")
    ]
    excludeGroups = ['com.bank']  // exclude internal modules
    configurations = ['runtimeClasspath']
}
```

### CycloneDX Plugin Configuration

```groovy
cyclonedxBom {
    includeConfigs = ["runtimeClasspath"]
    skipConfigs = ["testCompileClasspath", "testRuntimeClasspath"]
    projectType = "application"
    schemaVersion = "1.5"
    destination = file("${project.buildDir}/reports/sbom")
    outputName = "${project.name}-sbom"
    outputFormat = "json"
    includeBomSerialNumber = true
    includeLicenseText = false
    componentVersion = project.version.toString()
}
```

---

## §LIC-02 Allowed and Banned License Lists

### license-policy.gradle

```groovy
// Include in build.gradle via: apply from: 'license-policy.gradle'

ext {
    allowedLicenses = [
        'Apache License, Version 2.0',
        'Apache-2.0',
        'The Apache Software License, Version 2.0',
        'MIT License',
        'MIT',
        'The MIT License',
        'BSD License',
        'BSD-2-Clause',
        'BSD-3-Clause',
        'The BSD License',
        'Eclipse Public License - v 2.0',
        'EPL-2.0',
        'Eclipse Public License 1.0',
        'EPL-1.0',
        'Mozilla Public License, Version 2.0',
        'MPL-2.0',
        'Creative Commons Zero v1.0 Universal',
        'CC0-1.0',
        'The Unlicense',
        'ISC License',
        'Public Domain',
        'EDL 1.0',                          // Eclipse Distribution License
        'Eclipse Distribution License - v 1.0',
        'CDDL + GPLv2 with classpath exception',  // common for Jakarta EE
    ]

    bannedLicenses = [
        'GNU Affero General Public License v3.0',
        'AGPL-3.0',
        'AGPL-3.0-only',
        'AGPL-3.0-or-later',
        'GNU General Public License v2.0',
        'GPL-2.0',
        'GPL-2.0-only',
        'GNU General Public License v3.0',
        'GPL-3.0',
        'GPL-3.0-only',
        'GPL-3.0-or-later',
    ]

    reviewRequiredLicenses = [
        'GNU Lesser General Public License v2.1',
        'LGPL-2.1',
        'LGPL-2.1-only',
        'GNU Lesser General Public License v3.0',
        'LGPL-3.0',
        'LGPL-3.0-only',
        'Common Development and Distribution License 1.0',
        'CDDL-1.0',
        'Creative Commons Attribution Share Alike 4.0 International',
        'CC-BY-SA-4.0',
    ]
}
```

---

## §LIC-03 Custom License Audit Task

### build.gradle — checkLicense Task

```groovy
apply from: 'license-policy.gradle'

task checkLicense(dependsOn: 'generateLicenseReport') {
    group = 'verification'
    description = 'Checks all dependencies against the license policy'

    doLast {
        def reportFile = file("${project.buildDir}/reports/licenses/licenses.json")
        if (!reportFile.exists()) {
            throw new GradleException("License report not found. Run generateLicenseReport first.")
        }

        def report = new groovy.json.JsonSlurper().parse(reportFile)
        def violations = []
        def reviewNeeded = []
        def unknownLicenses = []

        report.dependencies.each { dep ->
            def depName = "${dep.moduleName}:${dep.moduleVersion}"
            def licenses = dep.moduleLicenses*.moduleLicense

            if (licenses.isEmpty() || licenses.every { it == null || it.trim().isEmpty() }) {
                unknownLicenses << depName
                return
            }

            // Check if any exception exists
            def exceptions = loadExceptions()
            if (exceptions.containsKey(dep.moduleName)) {
                logger.info("License exception for ${depName}: ${exceptions[dep.moduleName]}")
                return
            }

            licenses.each { license ->
                if (license == null) return

                if (bannedLicenses.any { banned -> license.contains(banned) }) {
                    violations << "${depName} [${license}]"
                } else if (reviewRequiredLicenses.any { review -> license.contains(review) }) {
                    reviewNeeded << "${depName} [${license}]"
                } else if (!allowedLicenses.any { allowed -> license.contains(allowed) }) {
                    unknownLicenses << "${depName} [${license}]"
                }
            }
        }

        def hasIssues = false

        if (violations) {
            logger.error("\n=== BANNED LICENSES DETECTED ===")
            violations.each { logger.error("  BANNED: ${it}") }
            hasIssues = true
        }

        if (reviewNeeded) {
            logger.warn("\n=== LICENSES REQUIRING REVIEW ===")
            reviewNeeded.each { logger.warn("  REVIEW: ${it}") }
        }

        if (unknownLicenses) {
            logger.warn("\n=== UNKNOWN/MISSING LICENSES ===")
            unknownLicenses.each { logger.warn("  UNKNOWN: ${it}") }
            hasIssues = true
        }

        if (hasIssues) {
            throw new GradleException(
                "License compliance check failed. " +
                "${violations.size()} banned, ${unknownLicenses.size()} unknown. " +
                "See output above for details.")
        }

        logger.lifecycle("\nLicense compliance check PASSED. " +
            "${report.dependencies.size()} dependencies checked.")
    }
}

def loadExceptions() {
    def exceptionsFile = file("${projectDir}/license-exceptions.yml")
    if (!exceptionsFile.exists()) return [:]
    // Simple YAML-like parsing for key: value pairs
    def exceptions = [:]
    exceptionsFile.eachLine { line ->
        if (line.trim() && !line.startsWith('#')) {
            def parts = line.split(':', 2)
            if (parts.length == 2) {
                exceptions[parts[0].trim()] = parts[1].trim()
            }
        }
    }
    return exceptions
}

check.dependsOn checkLicense
```

---

## §LIC-04 CI Gate Configuration

### .github/workflows/ci.yml — License Check Job

```yaml
jobs:
  license-check:
    name: License Compliance
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'

      - uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*') }}

      - name: Check licenses
        run: ./gradlew checkLicense

      - name: Generate SBOM
        run: ./gradlew cyclonedxBom

      - name: Upload license report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: license-report
          path: |
            build/reports/licenses/
            build/reports/sbom/

      - name: Upload SBOM
        if: github.ref == 'refs/heads/main'
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: build/reports/sbom/*.json
```

---

## §LIC-05 CycloneDX SBOM Generation

### Generate SBOM

```bash
./gradlew cyclonedxBom
```

### Example Output — build/reports/sbom/account-service-sbom.json (truncated)

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "serialNumber": "urn:uuid:a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "version": 1,
  "metadata": {
    "timestamp": "2025-03-15T10:00:00Z",
    "component": {
      "type": "application",
      "name": "account-service",
      "version": "1.0.0",
      "group": "com.bank"
    }
  },
  "components": [
    {
      "type": "library",
      "group": "org.springframework.boot",
      "name": "spring-boot-starter-web",
      "version": "3.3.0",
      "licenses": [
        {
          "license": {
            "id": "Apache-2.0"
          }
        }
      ],
      "purl": "pkg:maven/org.springframework.boot/spring-boot-starter-web@3.3.0"
    }
  ]
}
```

### Publish SBOM to Artifactory

```groovy
publishing {
    publications {
        sbom(MavenPublication) {
            artifactId = "${project.name}-sbom"
            artifact("${project.buildDir}/reports/sbom/${project.name}-sbom.json") {
                classifier = 'sbom'
                extension = 'json'
            }
        }
    }
}
```

---

## §LIC-06 License Exceptions

### license-exceptions.yml

```yaml
# License exceptions must be approved by the Legal & Compliance team.
# Format: <group>:<artifact>: <justification> (approved by <name>, <date>)

# Oracle JDBC driver — proprietary license, approved for internal use
com.oracle.database.jdbc:ojdbc11: Oracle Technology Network License, approved by Legal (J. Smith, 2025-01-15)

# Bouncy Castle — MIT-like custom license, widely used in banking
org.bouncycastle:bcprov-jdk18on: Bouncy Castle License (MIT variant), approved by Legal (J. Smith, 2024-11-20)
```

### license-normalizer-bundle.json

```json
{
  "bundles": [
    {
      "bundleName": "Apache-2.0",
      "licenseName": "Apache License, Version 2.0",
      "licenseUrl": "https://www.apache.org/licenses/LICENSE-2.0"
    },
    {
      "bundleName": "Apache-2.0",
      "licenseName": "The Apache Software License, Version 2.0",
      "licenseUrl": "https://www.apache.org/licenses/LICENSE-2.0.txt"
    },
    {
      "bundleName": "MIT",
      "licenseName": "MIT License",
      "licenseUrl": "https://opensource.org/licenses/MIT"
    },
    {
      "bundleName": "MIT",
      "licenseName": "The MIT License",
      "licenseUrl": "https://opensource.org/licenses/MIT"
    },
    {
      "bundleName": "EPL-2.0",
      "licenseName": "Eclipse Public License - v 2.0",
      "licenseUrl": "https://www.eclipse.org/legal/epl-2.0/"
    },
    {
      "bundleName": "EPL-1.0",
      "licenseName": "Eclipse Public License 1.0",
      "licenseUrl": "https://www.eclipse.org/legal/epl-v10.html"
    },
    {
      "bundleName": "BSD-3-Clause",
      "licenseName": "The BSD License",
      "licenseUrl": "https://opensource.org/licenses/BSD-3-Clause"
    },
    {
      "bundleName": "EDL-1.0",
      "licenseName": "Eclipse Distribution License - v 1.0",
      "licenseUrl": "https://www.eclipse.org/org/documents/edl-v10.php"
    }
  ],
  "transformationRules": [
    {
      "bundleName": "Apache-2.0",
      "licenseUrlPattern": ".*apache.org/licenses/LICENSE-2.0.*"
    },
    {
      "bundleName": "MIT",
      "licenseUrlPattern": ".*opensource.org/licenses/MIT.*"
    }
  ]
}
```

### Quarterly Audit Process

1. Run `./gradlew generateLicenseReport` to produce full dependency report
2. Review `build/reports/licenses/licenses.html` in browser
3. Compare against previous quarter's report for new dependencies
4. Verify all `REVIEW` licenses have documented exceptions
5. Submit report to Legal & Compliance team
6. Update `license-exceptions.yml` with any new approvals
7. Archive the SBOM with the quarterly compliance records
