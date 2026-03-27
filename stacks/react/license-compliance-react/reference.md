# License Compliance — React / Next.js Reference

## §LIC-01: License Checker Configuration

### Installation

```bash
npm install --save-dev license-checker
```

### Allowlist Configuration

```json
// .license-allowlist.json
{
  "allowedLicenses": [
    "MIT",
    "Apache-2.0",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "0BSD",
    "CC0-1.0",
    "CC-BY-3.0",
    "CC-BY-4.0",
    "Unlicense",
    "BlueOak-1.0.0",
    "Python-2.0"
  ]
}
```

### License Check Script

```ts
// scripts/check-licenses.mts
import { execSync } from "child_process";
import { readFileSync } from "fs";

interface LicenseInfo {
  licenses: string;
  repository: string;
  publisher: string;
}

const allowlist = JSON.parse(
  readFileSync(".license-allowlist.json", "utf-8")
);

const allowedLicenses = new Set<string>(allowlist.allowedLicenses);

// Get all production dependency licenses
const output = execSync(
  "npx license-checker --json --production --direct",
  { encoding: "utf-8" }
);
const licenses: Record<string, LicenseInfo> = JSON.parse(output);

const violations: Array<{ pkg: string; license: string }> = [];

for (const [pkg, info] of Object.entries(licenses)) {
  const pkgLicenses = info.licenses.split(" OR ").map((l) => l.trim().replace(/[()]/g, ""));
  const hasAllowed = pkgLicenses.some((l) => allowedLicenses.has(l));

  if (!hasAllowed) {
    violations.push({ pkg, license: info.licenses });
  }
}

if (violations.length > 0) {
  console.error("LICENSE VIOLATIONS FOUND:");
  violations.forEach(({ pkg, license }) => {
    console.error(`  ${pkg}: ${license}`);
  });
  process.exit(1);
}

console.log(`All ${Object.keys(licenses).length} production dependencies have allowed licenses.`);
```

### NPM Script

```json
{
  "scripts": {
    "license:check": "tsx scripts/check-licenses.mts",
    "license:report": "npx license-checker --production --csv --out licenses.csv"
  }
}
```

---

## §LIC-02: Vulnerability Scanning

### npm audit

```bash
# Check for high and critical vulnerabilities (production only)
npm audit --audit-level=high --omit=dev

# Generate JSON report for CI
npm audit --json --omit=dev > audit-report.json
```

### Snyk Integration

```bash
# Install Snyk CLI
npm install --save-dev snyk

# Authenticate (CI uses SNYK_TOKEN env var)
npx snyk auth

# Test for vulnerabilities
npx snyk test --severity-threshold=high

# Monitor project (adds to Snyk dashboard)
npx snyk monitor
```

### Snyk Configuration

```yaml
# .snyk
version: v1.25.0
ignore: {}
patch: {}
```

```json
// package.json scripts
{
  "scripts": {
    "audit:npm": "npm audit --audit-level=high --omit=dev",
    "audit:snyk": "snyk test --severity-threshold=high",
    "audit:all": "npm run audit:npm && npm run audit:snyk"
  }
}
```

---

## §LIC-03: Banned Packages Check

### Banned Packages List

```json
// .banned-packages.json
{
  "banned": [
    {
      "name": "moment",
      "reason": "Deprecated; use date-fns or Intl API for date formatting"
    },
    {
      "name": "lodash",
      "reason": "Use native JS methods or lodash-es for tree-shaking"
    },
    {
      "name": "request",
      "reason": "Deprecated; use native fetch API"
    },
    {
      "name": "jquery",
      "reason": "Not compatible with React rendering model"
    },
    {
      "name": "node-forge",
      "reason": "Known security issues; use Node.js native crypto"
    },
    {
      "name": "colors",
      "reason": "Compromised package (supply chain attack)"
    },
    {
      "name": "faker",
      "reason": "Compromised package; use @faker-js/faker"
    },
    {
      "name": "event-stream",
      "reason": "Compromised package (supply chain attack)"
    }
  ],
  "bannedPrefixes": [
    {
      "prefix": "crypto-",
      "reason": "Use standard crypto libraries only; review with security team"
    }
  ]
}
```

### Banned Package Checker Script

```ts
// scripts/check-banned.mts
import { execSync } from "child_process";
import { readFileSync } from "fs";

interface BannedConfig {
  banned: Array<{ name: string; reason: string }>;
  bannedPrefixes: Array<{ prefix: string; reason: string }>;
}

const config: BannedConfig = JSON.parse(
  readFileSync(".banned-packages.json", "utf-8")
);

// Get full dependency tree
const output = execSync("npm ls --all --json 2>/dev/null || true", {
  encoding: "utf-8",
});
const tree = JSON.parse(output);

function collectDeps(node: any, collected = new Set<string>()): Set<string> {
  if (node.dependencies) {
    for (const name of Object.keys(node.dependencies)) {
      collected.add(name);
      collectDeps(node.dependencies[name], collected);
    }
  }
  return collected;
}

const allDeps = collectDeps(tree);
const violations: Array<{ name: string; reason: string }> = [];

for (const dep of allDeps) {
  const banned = config.banned.find((b) => b.name === dep);
  if (banned) {
    violations.push({ name: dep, reason: banned.reason });
    continue;
  }

  const bannedPrefix = config.bannedPrefixes.find((b) =>
    dep.startsWith(b.prefix)
  );
  if (bannedPrefix) {
    violations.push({ name: dep, reason: bannedPrefix.reason });
  }
}

if (violations.length > 0) {
  console.error("BANNED PACKAGE VIOLATIONS:");
  violations.forEach(({ name, reason }) => {
    console.error(`  ${name}: ${reason}`);
  });
  process.exit(1);
}

console.log(`No banned packages found in ${allDeps.size} dependencies.`);
```

---

## §LIC-04: SBOM Generation (CycloneDX)

### Installation

```bash
npm install --save-dev @cyclonedx/cyclonedx-npm
```

### Generate SBOM

```json
{
  "scripts": {
    "sbom:generate": "cyclonedx-npm --output-file sbom.json --spec-version 1.5 --output-reproducible",
    "sbom:validate": "npx @cyclonedx/cyclonedx-cli validate --input-file sbom.json"
  }
}
```

### CI SBOM Generation

```yaml
# In CI workflow
- name: Generate SBOM
  run: npm run sbom:generate

- name: Archive SBOM
  uses: actions/upload-artifact@v4
  with:
    name: sbom-${{ github.sha }}
    path: sbom.json
    retention-days: 365
```

---

## §LIC-05: CI Pipeline Integration

```yaml
# .github/workflows/compliance.yml
name: License & Security Compliance

on:
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: "0 6 * * 1" # Weekly Monday at 6 AM UTC

jobs:
  license-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci

      - name: Check licenses
        run: npm run license:check

      - name: Check banned packages
        run: npx tsx scripts/check-banned.mts

  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci

      - name: npm audit
        run: npm audit --audit-level=high --omit=dev

      - name: Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  sbom:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    needs: [license-check, security-audit]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci

      - name: Generate SBOM
        run: npm run sbom:generate

      - name: Archive SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom-${{ github.sha }}
          path: sbom.json
          retention-days: 365
```
