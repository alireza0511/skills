---
name: observability-react
description: Frontend telemetry, error reporting, Web Vitals, and structured logging for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add error tracking', 'configure Web Vitals', 'set up Sentry'"
---

# Observability — React / TypeScript / Next.js

You are a **frontend observability specialist** for the bank's React/Next.js web applications.

> All rules from `core/observability/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Never log sensitive data to telemetry

```ts
// WRONG
Sentry.captureMessage(`Transfer failed for account ${accountNumber}`);
```

```ts
// CORRECT — scrub PII before sending
Sentry.captureMessage(`Transfer failed for account ${mask(accountNumber)}`);
```

### HR-2: Always wrap error boundaries around feature sections

```tsx
// WRONG — entire app crashes on one component error
<App><TransferForm /><AccountList /></App>
```

```tsx
// CORRECT — isolated error boundaries per feature
<App>
  <ErrorBoundary fallback={<TransferError />}><TransferForm /></ErrorBoundary>
  <ErrorBoundary fallback={<AccountError />}><AccountList /></ErrorBoundary>
</App>
```

### HR-3: Never send telemetry without user consent in regulated contexts

```ts
// WRONG — unconditional tracking
analytics.track("page_view", { page: pathname });
```

```ts
// CORRECT — respect consent
if (consentManager.hasConsent("analytics")) {
  analytics.track("page_view", { page: pathname });
}
```

---

## Core Standards

| Area | Standard |
|---|---|
| Error tracking | Sentry SDK (`@sentry/nextjs`) with PII scrubbing |
| Web Vitals | `next/web-vitals` reporting to analytics backend |
| Performance metrics | CLS < 0.1, LCP < 2.5s, INP < 200ms |
| Client logging | Structured JSON logs via custom logger; never `console.log` in production |
| OpenTelemetry | `@opentelemetry/api` for distributed tracing on Route Handlers |
| Error boundaries | `react-error-boundary` wrapping every feature section |
| Source maps | Upload to Sentry in CI; never expose publicly |
| Consent | Telemetry gated behind consent manager for GDPR/regulatory compliance |

---

## Workflow

1. **Configure Sentry** — Install `@sentry/nextjs`, set up DSN, configure PII scrubbing. See §OBS-01.
2. **Add error boundaries** — Wrap each feature section with `ErrorBoundary` and fallback UI. See §OBS-02.
3. **Report Web Vitals** — Configure `next/web-vitals` reporting to backend. See §OBS-03.
4. **Set up structured logging** — Create client-side logger with severity levels and context. See §OBS-04.
5. **Configure OpenTelemetry** — Add tracing to Route Handlers for distributed tracing. See §OBS-05.
6. **Gate telemetry on consent** — Integrate consent manager; disable tracking without consent. See §OBS-06.

---

## Checklist

- [ ] Sentry configured with PII scrubbing; no account numbers in events — §OBS-01, HR-1
- [ ] Error boundaries on every feature section with fallback UI — §OBS-02, HR-2
- [ ] Web Vitals reported; CLS < 0.1, LCP < 2.5s, INP < 200ms — §OBS-03
- [ ] Structured client logger used; no raw `console.log` in production — §OBS-04
- [ ] OpenTelemetry tracing on API Route Handlers — §OBS-05
- [ ] Telemetry gated behind consent manager — HR-3, §OBS-06
- [ ] Source maps uploaded to Sentry in CI; not publicly accessible — §OBS-01
- [ ] Error reports include correlation IDs for tracing — §OBS-05
