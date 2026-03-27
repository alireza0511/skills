# Observability — React / Next.js Reference

## §OBS-01: Sentry Configuration

### Installation and Setup

```ts
// sentry.client.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1, // 10% sampling in production
  replaysSessionSampleRate: 0,
  replaysOnErrorSampleRate: 1.0,

  beforeSend(event) {
    // Scrub PII from error events
    if (event.request?.headers) {
      delete event.request.headers["Authorization"];
      delete event.request.headers["Cookie"];
    }
    return scrubPII(event);
  },

  beforeBreadcrumb(breadcrumb) {
    // Remove sensitive URL params
    if (breadcrumb.category === "navigation" && breadcrumb.data?.to) {
      breadcrumb.data.to = stripSensitiveParams(breadcrumb.data.to);
    }
    return breadcrumb;
  },

  integrations: [
    Sentry.replayIntegration({
      maskAllText: true,
      maskAllInputs: true,
      blockAllMedia: true,
    }),
  ],
});
```

```ts
// sentry.server.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN, // server-only, no NEXT_PUBLIC_
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.2,

  beforeSend(event) {
    return scrubPII(event);
  },
});
```

### PII Scrubbing Utility

```ts
// lib/observability/scrub.ts
const PII_PATTERNS = [
  { pattern: /\b\d{9,18}\b/g, replacement: "***ACCOUNT***" },    // Account numbers
  { pattern: /\b\d{3}-\d{2}-\d{4}\b/g, replacement: "***SSN***" }, // SSN
  { pattern: /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, replacement: "***EMAIL***" },
];

export function scrubPII(event: any): any {
  const json = JSON.stringify(event);
  let scrubbed = json;

  for (const { pattern, replacement } of PII_PATTERNS) {
    scrubbed = scrubbed.replace(pattern, replacement);
  }

  return JSON.parse(scrubbed);
}

export function mask(value: string): string {
  if (value.length <= 4) return "****";
  return "****" + value.slice(-4);
}

export function stripSensitiveParams(url: string): string {
  try {
    const u = new URL(url, "https://placeholder");
    const sensitiveKeys = ["token", "session", "account", "ssn"];
    for (const key of sensitiveKeys) {
      if (u.searchParams.has(key)) u.searchParams.set(key, "***");
    }
    return u.pathname + u.search;
  } catch {
    return url;
  }
}
```

### Next.js Config for Sentry

```ts
// next.config.ts
import { withSentryConfig } from "@sentry/nextjs";

const nextConfig = {
  // ... existing config
};

export default withSentryConfig(nextConfig, {
  org: "national-bank",
  project: "web-banking",
  silent: true,
  widenClientFileUpload: true,
  hideSourceMaps: true, // do not expose source maps publicly
  disableLogger: true,
  tunnelRoute: "/monitoring", // proxy Sentry requests to avoid ad blockers
});
```

---

## §OBS-02: Error Boundaries

### Reusable Error Boundary Component

```tsx
// components/ErrorBoundary/FeatureErrorBoundary.tsx
"use client";

import { ErrorBoundary } from "react-error-boundary";
import * as Sentry from "@sentry/nextjs";

interface FeatureErrorBoundaryProps {
  feature: string;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

function DefaultFallback({ error, resetErrorBoundary, feature }: any) {
  return (
    <div role="alert" className="rounded border border-red-200 bg-red-50 p-4">
      <h3 className="text-lg font-semibold text-red-800">
        Something went wrong in {feature}
      </h3>
      <p className="mt-1 text-sm text-red-600">
        We encountered an unexpected error. Please try again.
      </p>
      <button
        type="button"
        onClick={resetErrorBoundary}
        className="mt-3 rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700"
      >
        Try Again
      </button>
    </div>
  );
}

export function FeatureErrorBoundary({
  feature,
  children,
  fallback,
}: FeatureErrorBoundaryProps) {
  return (
    <ErrorBoundary
      FallbackComponent={
        fallback
          ? () => <>{fallback}</>
          : (props) => <DefaultFallback {...props} feature={feature} />
      }
      onError={(error, info) => {
        Sentry.captureException(error, {
          tags: { feature },
          contexts: { react: { componentStack: info.componentStack } },
        });
      }}
      onReset={() => {
        // Optional: clear feature-specific state
      }}
    >
      {children}
    </ErrorBoundary>
  );
}
```

### Next.js error.tsx Pattern

```tsx
// app/dashboard/error.tsx
"use client";

import { useEffect } from "react";
import * as Sentry from "@sentry/nextjs";

interface ErrorPageProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function DashboardError({ error, reset }: ErrorPageProps) {
  useEffect(() => {
    Sentry.captureException(error, {
      tags: { page: "dashboard" },
    });
  }, [error]);

  return (
    <div role="alert" className="flex flex-col items-center p-8">
      <h2 className="text-xl font-bold">Dashboard Error</h2>
      <p className="mt-2 text-gray-600">
        We were unable to load your dashboard. Please try again.
      </p>
      {error.digest && (
        <p className="mt-1 text-xs text-gray-400">
          Error ID: {error.digest}
        </p>
      )}
      <button
        type="button"
        onClick={reset}
        className="mt-4 rounded bg-blue-600 px-6 py-2 text-white"
      >
        Try Again
      </button>
    </div>
  );
}
```

---

## §OBS-03: Web Vitals Reporting

```tsx
// app/layout.tsx (or a dedicated component)
import { WebVitals } from "@/components/WebVitals";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <WebVitals />
        {children}
      </body>
    </html>
  );
}
```

```tsx
// components/WebVitals.tsx
"use client";

import { useReportWebVitals } from "next/web-vitals";
import { logger } from "@/lib/observability/logger";

export function WebVitals() {
  useReportWebVitals((metric) => {
    const { name, value, rating, id } = metric;

    logger.info("web-vital", {
      metric: name,
      value: Math.round(name === "CLS" ? value * 1000 : value),
      rating,       // "good" | "needs-improvement" | "poor"
      metricId: id,
    });

    // Send to analytics endpoint
    if (navigator.sendBeacon) {
      navigator.sendBeacon(
        "/api/analytics/vitals",
        JSON.stringify({ name, value, rating, id, timestamp: Date.now() })
      );
    }
  });

  return null;
}
```

### Web Vitals Thresholds

| Metric | Good | Needs Improvement | Poor |
|---|---|---|---|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5s – 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | < 200ms | 200ms – 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1 – 0.25 | > 0.25 |

---

## §OBS-04: Structured Client Logging

```ts
// lib/observability/logger.ts
type LogLevel = "debug" | "info" | "warn" | "error";

interface LogEntry {
  level: LogLevel;
  message: string;
  context: Record<string, unknown>;
  timestamp: string;
  sessionId?: string;
}

class ClientLogger {
  private buffer: LogEntry[] = [];
  private readonly flushInterval = 5000;
  private readonly maxBufferSize = 50;

  constructor() {
    if (typeof window !== "undefined") {
      setInterval(() => this.flush(), this.flushInterval);
      window.addEventListener("beforeunload", () => this.flush());
    }
  }

  private log(level: LogLevel, message: string, context: Record<string, unknown> = {}) {
    if (process.env.NODE_ENV === "development") {
      console[level](`[${level.toUpperCase()}] ${message}`, context);
      return;
    }

    this.buffer.push({
      level,
      message,
      context,
      timestamp: new Date().toISOString(),
    });

    if (this.buffer.length >= this.maxBufferSize) {
      this.flush();
    }
  }

  debug(message: string, context?: Record<string, unknown>) {
    this.log("debug", message, context);
  }

  info(message: string, context?: Record<string, unknown>) {
    this.log("info", message, context);
  }

  warn(message: string, context?: Record<string, unknown>) {
    this.log("warn", message, context);
  }

  error(message: string, context?: Record<string, unknown>) {
    this.log("error", message, context);
  }

  private async flush() {
    if (this.buffer.length === 0) return;

    const entries = [...this.buffer];
    this.buffer = [];

    try {
      await fetch("/api/analytics/logs", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ entries }),
        keepalive: true,
      });
    } catch {
      // Re-add to buffer on failure (up to max)
      this.buffer.unshift(...entries.slice(0, this.maxBufferSize - this.buffer.length));
    }
  }
}

export const logger = new ClientLogger();
```

---

## §OBS-05: OpenTelemetry for Route Handlers

```ts
// lib/observability/tracing.ts
import { trace, SpanStatusCode, context } from "@opentelemetry/api";

const tracer = trace.getTracer("web-banking", "1.0.0");

export function withTracing<T>(
  spanName: string,
  fn: () => Promise<T>,
  attributes?: Record<string, string>
): Promise<T> {
  return tracer.startActiveSpan(spanName, async (span) => {
    try {
      if (attributes) {
        for (const [key, value] of Object.entries(attributes)) {
          span.setAttribute(key, value);
        }
      }
      const result = await fn();
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: String(error) });
      span.recordException(error as Error);
      throw error;
    } finally {
      span.end();
    }
  });
}

export function getCorrelationId(): string | undefined {
  const span = trace.getActiveSpan();
  return span?.spanContext().traceId;
}
```

### Instrumented Route Handler

```ts
// app/api/transfers/route.ts
import { NextResponse } from "next/server";
import { withTracing, getCorrelationId } from "@/lib/observability/tracing";

export async function POST(request: Request) {
  return withTracing("POST /api/transfers", async () => {
    const body = await request.json();

    const result = await withTracing("process-transfer", async () => {
      // ... business logic
      return { id: "txn-123", status: "accepted" };
    });

    return NextResponse.json(result, {
      status: 202,
      headers: { "x-correlation-id": getCorrelationId() ?? "" },
    });
  });
}
```

---

## §OBS-06: Consent-Gated Telemetry

```ts
// lib/consent.ts
type ConsentCategory = "essential" | "analytics" | "performance";

class ConsentManager {
  private consents = new Map<ConsentCategory, boolean>();

  constructor() {
    if (typeof window !== "undefined") {
      this.loadFromCookie();
    }
  }

  hasConsent(category: ConsentCategory): boolean {
    if (category === "essential") return true; // always allowed
    return this.consents.get(category) ?? false;
  }

  setConsent(category: ConsentCategory, granted: boolean) {
    this.consents.set(category, granted);
    this.saveToCookie();
  }

  private loadFromCookie() {
    try {
      const raw = document.cookie
        .split("; ")
        .find((c) => c.startsWith("consent="))
        ?.split("=")[1];
      if (raw) {
        const parsed = JSON.parse(decodeURIComponent(raw));
        for (const [key, value] of Object.entries(parsed)) {
          this.consents.set(key as ConsentCategory, value as boolean);
        }
      }
    } catch {
      // Ignore parse errors
    }
  }

  private saveToCookie() {
    const data = Object.fromEntries(this.consents);
    document.cookie = `consent=${encodeURIComponent(JSON.stringify(data))}; path=/; max-age=31536000; SameSite=Strict; Secure`;
  }
}

export const consentManager = new ConsentManager();
```
