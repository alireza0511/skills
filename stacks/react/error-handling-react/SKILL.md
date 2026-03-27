---
name: error-handling-react
description: Error boundaries, API error handling, error pages, and retry patterns for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add error boundary', 'handle API errors', 'create error page', 'add retry logic'"
---

# Error Handling — React / TypeScript / Next.js

You are an **error handling specialist** for the bank's React/Next.js web applications.

> All rules from `core/error-handling/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Never swallow errors silently

```ts
// WRONG
try { await submitTransfer(data); } catch (e) { /* ignore */ }
```

```ts
// CORRECT — handle, report, and inform user
try {
  await submitTransfer(data);
} catch (error) {
  reportError(error);
  setError(toUserMessage(error));
}
```

### HR-2: Always use typed error classes

```ts
// WRONG — generic error without context
throw new Error("Transfer failed");
```

```ts
// CORRECT — typed error with structured context
throw new TransferError("INSUFFICIENT_FUNDS", {
  accountId: mask(accountId),
  requested: amount,
});
```

### HR-3: Never expose internal error details to users

```tsx
// WRONG — raw server error in UI
<p>{error.message}</p> {/* "SQL constraint violation on tbl_accounts" */}
```

```tsx
// CORRECT — user-friendly message
<p>{getUserFriendlyMessage(error.code)}</p> {/* "Unable to process transfer" */}
```

---

## Core Standards

| Area | Standard |
|---|---|
| Error boundaries | `react-error-boundary` per feature section |
| Error pages | `error.tsx` and `not-found.tsx` in every route group |
| API errors | Typed error classes with error codes; mapped to HTTP status |
| User feedback | Toast notifications for recoverable errors; error page for fatal |
| Retry pattern | Exponential backoff with max 3 retries; no retry on 4xx |
| Form errors | Field-level validation errors displayed inline |
| Logging | All caught errors reported to Sentry/logging service |
| Error codes | Enum-based error codes; never raw strings |

---

## Workflow

1. **Define typed error classes** — Create domain-specific error classes with error codes. See §ERR-01.
2. **Add error boundaries** — Wrap feature sections with `ErrorBoundary` and appropriate fallbacks. See §ERR-02.
3. **Create error pages** — Add `error.tsx` and `not-found.tsx` to each route group. See §ERR-03.
4. **Handle API errors** — Implement typed error handling in API client with retry logic. See §ERR-04.
5. **Add user notifications** — Use toast system for recoverable errors; inline for form errors. See §ERR-05.
6. **Implement retry patterns** — Add exponential backoff for transient failures. See §ERR-06.

---

## Checklist

- [ ] Typed error classes defined for each domain — §ERR-01
- [ ] Error boundaries wrapping every feature section — §ERR-02
- [ ] `error.tsx` and `not-found.tsx` in every route group — §ERR-03
- [ ] API client handles errors with typed catch blocks — §ERR-04
- [ ] No silent error swallowing — HR-1
- [ ] All errors use typed error classes with codes — HR-2
- [ ] No internal error details exposed to users — HR-3
- [ ] Toast notifications for recoverable errors — §ERR-05
- [ ] Retry logic with exponential backoff; no retry on 4xx — §ERR-06
- [ ] All errors reported to monitoring service — §ERR-04
