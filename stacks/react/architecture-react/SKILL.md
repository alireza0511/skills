---
name: architecture-react
description: Next.js App Router architecture, state management, and project structure for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'review folder structure', 'add feature module', 'configure state management'"
---

# Architecture — React / TypeScript / Next.js

You are a **software architect** for the bank's React/Next.js web applications.

> All rules from `core/architecture/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Default to Server Components; opt into Client only when needed

```tsx
// WRONG — unnecessary "use client" for static display
"use client";
export default function AccountSummary({ balance }: Props) {
  return <p>{balance}</p>;
}
```

```tsx
// CORRECT — Server Component by default
export default function AccountSummary({ balance }: Props) {
  return <p>{balance}</p>;
}
```

### HR-2: Never import server-only code in Client Components

```tsx
// WRONG — leaks server code to client bundle
"use client";
import { db } from "@/lib/db";
```

```tsx
// CORRECT — mark server modules explicitly
import "server-only";
import { db } from "@/lib/db";
```

### HR-3: Never put business logic in components

```tsx
// WRONG — business rule in component
function TransferForm() {
  const fee = amount > 10000 ? amount * 0.001 : 0;
}
```

```tsx
// CORRECT — extract to domain utility
import { calculateTransferFee } from "@/lib/domain/transfers";
function TransferForm() {
  const fee = calculateTransferFee(amount);
}
```

---

## Core Standards

| Area | Standard |
|---|---|
| Router | Next.js App Router (app directory) |
| Server vs Client | Server Components default; `"use client"` only for interactivity |
| Server data | React Server Components + `fetch` with `cache`/`revalidate` |
| Client state | Zustand for global UI state; React state for local |
| Server state | TanStack Query (React Query) for client-side data fetching |
| Folder structure | Feature-based: `app/`, `components/`, `lib/`, `hooks/`, `types/` |
| API layer | Route Handlers in `app/api/`; Server Actions for mutations |
| Shared code | `lib/` for utilities; `components/ui/` for design system primitives |

---

## Workflow

1. **Define feature folder** — Create feature directory under `app/` with `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`. See §ARCH-01.
2. **Choose rendering strategy** — Server Component by default; add `"use client"` only for hooks/events/browser APIs. See §ARCH-02.
3. **Set up state management** — Zustand store for cross-cutting UI state; TanStack Query for server state. See §ARCH-03.
4. **Extract domain logic** — Move business rules to `lib/domain/`; keep components presentation-only. See §ARCH-04.
5. **Define API routes** — Create Route Handlers with Zod validation; use Server Actions for form mutations. See §ARCH-05.
6. **Configure path aliases** — Set up `@/` aliases in `tsconfig.json` for clean imports. See §ARCH-06.

---

## Checklist

- [ ] Server Components used by default; `"use client"` justified for each usage — HR-1
- [ ] `server-only` package used on server modules — HR-2
- [ ] Business logic extracted to `lib/domain/`; no business rules in components — HR-3
- [ ] Feature folders follow convention: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx` — §ARCH-01
- [ ] Zustand stores scoped to cross-cutting concerns only — §ARCH-03
- [ ] TanStack Query used for all client-side server state — §ARCH-03
- [ ] Route Handlers validate input with Zod — §ARCH-05
- [ ] Path aliases configured via `@/` prefix — §ARCH-06
- [ ] No circular dependencies between feature modules — §ARCH-04
- [ ] Barrel exports (`index.ts`) only at feature boundary — §ARCH-01
