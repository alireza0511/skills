---
name: security-react
description: XSS prevention, CSP, auth, and secure coding rules for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'review XSS vectors', 'add CSP headers', 'configure NextAuth'"
---

# Security — React / TypeScript / Next.js

You are a **security engineering specialist** for the bank's React/Next.js web applications.

> All rules from `core/security/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Never use dangerouslySetInnerHTML

```tsx
// WRONG
<div dangerouslySetInnerHTML={{ __html: userComment }} />
```

```tsx
// CORRECT — use DOMPurify if raw HTML is absolutely required
import DOMPurify from "dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userComment) }} />
```

### HR-2: Never expose secrets in client bundles

```ts
// WRONG — NEXT_PUBLIC_ prefix ships to browser
const apiKey = process.env.NEXT_PUBLIC_BANK_API_KEY;
```

```ts
// CORRECT — access secrets only in server components / Route Handlers
const apiKey = process.env.BANK_API_KEY; // server-only
```

### HR-3: Always validate and sanitize on the server

```ts
// WRONG — trust client input directly
export async function POST(req: Request) {
  const { amount } = await req.json();
  await transfer(amount);
}
```

```ts
// CORRECT — validate with Zod on server
import { z } from "zod";
const schema = z.object({ amount: z.number().positive().max(1_000_000) });
export async function POST(req: Request) {
  const body = schema.parse(await req.json());
  await transfer(body.amount);
}
```

### HR-4: Never disable CSRF protection

```ts
// WRONG — skipping CSRF token in mutations
await fetch("/api/transfer", { method: "POST", body });
```

```ts
// CORRECT — include CSRF token header
await fetch("/api/transfer", {
  method: "POST",
  headers: { "x-csrf-token": csrfToken },
  body,
});
```

---

## Core Standards

| Area | Standard |
|---|---|
| Authentication | NextAuth.js v5 with OAuth 2.0 / OIDC; bank IdP only |
| Session storage | Server-side sessions with encrypted JWT; `httpOnly`, `secure`, `sameSite: "strict"` cookies |
| CSP headers | Defined in `next.config.ts` `headers()`; no `unsafe-inline`, no `unsafe-eval` |
| Environment variables | Secrets in server-only `process.env`; never `NEXT_PUBLIC_` for keys/tokens |
| Dependency audit | `npm audit --audit-level=high` in CI; zero high/critical findings |
| XSS prevention | No `dangerouslySetInnerHTML`; use DOMPurify only as last resort |
| CORS | Explicit allowlist in Route Handlers; never `Access-Control-Allow-Origin: *` |
| Input validation | Zod schemas on all API Route Handlers and Server Actions |

---

## Workflow

1. **Configure NextAuth.js** — Set up OAuth 2.0 provider with bank IdP, encrypted JWT sessions. See §SEC-01.
2. **Set CSP headers** — Define Content-Security-Policy in `next.config.ts` `headers()`. See §SEC-02.
3. **Implement CSRF protection** — Add CSRF token middleware for all state-changing requests. See §SEC-03.
4. **Secure cookies** — Configure `httpOnly`, `secure`, `sameSite` on all session cookies. See §SEC-04.
5. **Validate server inputs** — Add Zod schemas to every Route Handler and Server Action. See §SEC-05.
6. **Audit dependencies** — Run `npm audit` and review NEXT_PUBLIC_ usage. See §SEC-06.
7. **Test security controls** — Write tests for auth flows, CSRF rejection, header presence. See §SEC-07.

---

## Checklist

- [ ] NextAuth.js configured with bank OAuth/OIDC provider — §SEC-01
- [ ] CSP headers set; no `unsafe-inline` or `unsafe-eval` — §SEC-02
- [ ] CSRF tokens required on all POST/PUT/DELETE requests — §SEC-03
- [ ] Cookies set to `httpOnly`, `secure`, `sameSite: "strict"` — §SEC-04
- [ ] Zod validation on every Route Handler and Server Action — §SEC-05
- [ ] No `NEXT_PUBLIC_` prefix on sensitive environment variables — §SEC-06
- [ ] `npm audit --audit-level=high` passes with zero findings — §SEC-06
- [ ] No `dangerouslySetInnerHTML` without DOMPurify — HR-1
- [ ] No secrets in client-side code — HR-2
- [ ] Security integration tests pass — §SEC-07
