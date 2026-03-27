---
name: api-design-react
description: Next.js Route Handlers, tRPC, OpenAPI client generation, Zod validation, and Server Actions for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'create API route', 'add tRPC router', 'generate API client', 'add server action'"
---

# API Design — React / TypeScript / Next.js

You are an **API design specialist** for the bank's React/Next.js web applications.

> All rules from `core/api-design/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Always validate request bodies with Zod

```ts
// WRONG — trusting raw input
export async function POST(req: Request) {
  const data = await req.json();
  await createTransfer(data);
}
```

```ts
// CORRECT — Zod validation before processing
export async function POST(req: Request) {
  const data = TransferSchema.parse(await req.json());
  await createTransfer(data);
}
```

### HR-2: Always return consistent error response shapes

```ts
// WRONG — inconsistent error formats
return NextResponse.json({ msg: "bad" }, { status: 400 });
return NextResponse.json({ error: "fail" }, { status: 500 });
```

```ts
// CORRECT — unified error envelope
return NextResponse.json(
  { error: { code: "VALIDATION_ERROR", message: "Invalid input", details } },
  { status: 400 }
);
```

### HR-3: Always authenticate Route Handlers for protected resources

```ts
// WRONG — no auth check
export async function GET() {
  return NextResponse.json(await getAccounts());
}
```

```ts
// CORRECT — auth check first
export async function GET() {
  const session = await auth();
  if (!session) return NextResponse.json({ error: { code: "UNAUTHORIZED" } }, { status: 401 });
  return NextResponse.json(await getAccountsByUser(session.user.id));
}
```

---

## Core Standards

| Area | Standard |
|---|---|
| Route Handlers | `app/api/` directory; one `route.ts` per resource |
| Validation | Zod schemas on all inputs; shared between client and server |
| Error envelope | `{ data?, error?: { code, message, details? } }` |
| Server Actions | `"use server"` functions for form mutations; Zod validated |
| tRPC | Optional for internal APIs; typed end-to-end |
| API client gen | Orval or `openapi-typescript` from OpenAPI specs for external APIs |
| HTTP methods | GET (read), POST (create), PUT (full update), PATCH (partial), DELETE |
| Status codes | 200 OK, 201 Created, 202 Accepted, 400 Bad Request, 401, 403, 404, 422, 500 |

---

## Workflow

1. **Define Zod schemas** — Create shared validation schemas for request/response types. See §API-01.
2. **Create Route Handlers** — Implement RESTful handlers with auth, validation, error handling. See §API-02.
3. **Implement Server Actions** — Create validated server actions for form mutations. See §API-03.
4. **Set up tRPC (optional)** — Configure tRPC router for type-safe internal API. See §API-04.
5. **Generate API client** — Use Orval/openapi-typescript for external API clients. See §API-05.
6. **Add response helpers** — Create consistent response factories for success/error. See §API-06.

---

## Checklist

- [ ] All Route Handler inputs validated with Zod — HR-1
- [ ] Consistent error envelope on all error responses — HR-2
- [ ] Auth check on all protected Route Handlers — HR-3
- [ ] Zod schemas shared between client and server — §API-01
- [ ] Route Handlers follow REST conventions (methods, status codes) — §API-02
- [ ] Server Actions validated with Zod; return typed results — §API-03
- [ ] External API clients generated from OpenAPI specs — §API-05
- [ ] Response helpers used for consistent formatting — §API-06
- [ ] API routes documented with TSDoc — Core Standards
- [ ] No business logic in Route Handlers; delegated to domain layer — §API-02
