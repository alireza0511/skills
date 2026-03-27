# CI/CD — React / Next.js Reference

## §CI-01: GitHub Actions CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Type check
        run: npm run type-check

      - name: Lint
        run: npm run lint

      - name: Format check
        run: npm run format:check

      - name: Unit tests with coverage
        run: npm run test:ci

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/

      - name: Check coverage thresholds
        run: |
          npx istanbul check-coverage \
            --statements 80 --branches 80 \
            --functions 80 --lines 80

  build:
    runs-on: ubuntu-latest
    needs: [quality]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Build Next.js
        run: npm run build
        env:
          NEXT_PUBLIC_APP_URL: ${{ vars.NEXT_PUBLIC_APP_URL }}
          NEXT_PUBLIC_SENTRY_DSN: ${{ vars.NEXT_PUBLIC_SENTRY_DSN }}

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: nextjs-build
          path: .next/
          retention-days: 7

  e2e:
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Download build
        uses: actions/download-artifact@v4
        with:
          name: nextjs-build
          path: .next/

      - name: Run E2E tests
        run: npx playwright test --project=chromium

      - name: Upload E2E results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: e2e-results
          path: test-results/
```

---

## §CI-02: Lighthouse CI

### Configuration

```js
// lighthouserc.js
module.exports = {
  ci: {
    collect: {
      url: [
        "http://localhost:3000/",
        "http://localhost:3000/dashboard",
        "http://localhost:3000/dashboard/accounts",
      ],
      startServerCommand: "npm run start",
      startServerReadyPattern: "Ready in",
      numberOfRuns: 3,
      settings: {
        preset: "desktop",
      },
    },
    assert: {
      assertions: {
        "categories:performance": ["error", { minScore: 0.9 }],
        "categories:accessibility": ["error", { minScore: 0.95 }],
        "categories:best-practices": ["error", { minScore: 0.95 }],
        "categories:seo": ["warn", { minScore: 0.9 }],
        // Core Web Vitals
        "largest-contentful-paint": ["error", { maxNumericValue: 2500 }],
        "cumulative-layout-shift": ["error", { maxNumericValue: 0.1 }],
        "total-blocking-time": ["error", { maxNumericValue: 300 }],
      },
    },
    upload: {
      target: "temporary-public-storage",
    },
  },
};
```

### Lighthouse CI Workflow Job

```yaml
# Add to .github/workflows/ci.yml
  lighthouse:
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"

      - run: npm ci

      - name: Download build
        uses: actions/download-artifact@v4
        with:
          name: nextjs-build
          path: .next/

      - name: Run Lighthouse CI
        run: |
          npm install -g @lhci/cli
          lhci autorun
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
```

---

## §CI-03: Vercel Deployment Configuration

### vercel.json

```json
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "installCommand": "npm ci",
  "outputDirectory": ".next",
  "regions": ["iad1"],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=63072000; includeSubDomains; preload"
        }
      ]
    }
  ],
  "rewrites": [
    {
      "source": "/monitoring/:path*",
      "destination": "https://o0.ingest.sentry.io/:path*"
    }
  ]
}
```

### Environment Variables Setup

```bash
# Set production environment variables via Vercel CLI
vercel env add NEXTAUTH_SECRET production
vercel env add OIDC_ISSUER_URL production
vercel env add OIDC_CLIENT_ID production
vercel env add OIDC_CLIENT_SECRET production
vercel env add SENTRY_DSN production
vercel env add DATABASE_URL production

# Preview environment (uses staging credentials)
vercel env add NEXTAUTH_SECRET preview
vercel env add OIDC_ISSUER_URL preview
```

---

## §CI-04: Docker Multi-Stage Build

```dockerfile
# Dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

RUN npm run build

# Stage 3: Production
FROM node:20-alpine AS runner
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
```

### Next.js Config for Standalone Output

```ts
// next.config.ts (add to existing config)
const nextConfig: NextConfig = {
  output: "standalone", // Required for Docker deployment
  // ... other config
};
```

### Docker Compose for Local Development

```yaml
# docker-compose.yml
version: "3.9"
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - NEXTAUTH_URL=http://localhost:3000
    env_file:
      - .env.production.local
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

## §CI-05: Preview Deployments

### Vercel Preview with PR Comments

```yaml
# .github/workflows/preview.yml
name: Preview Deployment

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  deploy-preview:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Vercel Preview
        id: deploy
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}

      - name: Comment PR with preview URL
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Preview Deployment\n\nURL: ${{ steps.deploy.outputs.preview-url }}\n\nCommit: \`${context.sha.substring(0, 7)}\``
            });
```

---

## §CI-06: Caching Strategy

```yaml
# Caching steps (add to CI workflow)
- uses: actions/setup-node@v4
  with:
    node-version-file: ".nvmrc"
    cache: "npm" # Automatically caches ~/.npm

# Next.js build cache
- uses: actions/cache@v4
  with:
    path: .next/cache
    key: nextjs-${{ runner.os }}-${{ hashFiles('package-lock.json') }}-${{ hashFiles('**/*.ts', '**/*.tsx') }}
    restore-keys: |
      nextjs-${{ runner.os }}-${{ hashFiles('package-lock.json') }}-
      nextjs-${{ runner.os }}-

# Playwright browser cache
- uses: actions/cache@v4
  with:
    path: ~/.cache/ms-playwright
    key: playwright-${{ runner.os }}-${{ hashFiles('package-lock.json') }}
```

### Health Check Endpoint

```ts
// app/api/health/route.ts
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    version: process.env.NEXT_PUBLIC_APP_VERSION ?? "unknown",
  });
}
```
