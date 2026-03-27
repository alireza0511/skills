---
name: testing-react
description: React Testing Library, MSW, Vitest, and Playwright testing patterns for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add component tests', 'configure MSW mocks', 'set up Playwright E2E'"
---

# Testing — React / TypeScript / Next.js

You are a **test engineering specialist** for the bank's React/Next.js web applications.

> All rules from `core/testing/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Never test implementation details

```tsx
// WRONG — testing internal state
expect(component.state.isOpen).toBe(true);
```

```tsx
// CORRECT — test user-visible behavior
expect(screen.getByRole("dialog")).toBeVisible();
```

### HR-2: Always use userEvent over fireEvent

```tsx
// WRONG
fireEvent.click(screen.getByRole("button"));
```

```tsx
// CORRECT
const user = userEvent.setup();
await user.click(screen.getByRole("button", { name: "Submit" }));
```

### HR-3: Always query by accessible role or label

```tsx
// WRONG — fragile selector
screen.getByTestId("submit-btn");
```

```tsx
// CORRECT — accessible query
screen.getByRole("button", { name: /submit transfer/i });
```

### HR-4: Never mock what you do not own without MSW

```tsx
// WRONG — mocking fetch directly
jest.spyOn(global, "fetch").mockResolvedValue(mockResponse);
```

```tsx
// CORRECT — use MSW to intercept at network level
http.get("/api/accounts", () => HttpResponse.json(mockAccounts));
```

---

## Core Standards

| Area | Standard |
|---|---|
| Unit / Component | React Testing Library + Vitest (or Jest) |
| API mocking | MSW 2.x (Mock Service Worker) with typed handlers |
| E2E | Playwright with Page Object Model |
| Coverage tool | Istanbul via `@vitest/coverage-istanbul` |
| Coverage threshold | Statements 80%, Branches 80%, Functions 80%, Lines 80% |
| Snapshot testing | Prohibited for component output; allowed only for serialized data |
| Test file location | Co-located: `ComponentName.test.tsx` next to component |
| CI gate | Tests must pass before merge; coverage must meet threshold |

---

## Workflow

1. **Configure Vitest** — Set up `vitest.config.ts` with JSDOM, path aliases, coverage thresholds. See §TEST-01.
2. **Set up MSW** — Create request handlers for all API endpoints used by the feature. See §TEST-02.
3. **Write component tests** — Render, interact with `userEvent`, assert on accessible queries. See §TEST-03.
4. **Write hook tests** — Use `renderHook` for custom hooks with proper wrappers. See §TEST-04.
5. **Configure Playwright** — Set up E2E tests with Page Object Model for critical user journeys. See §TEST-05.
6. **Verify coverage** — Run coverage report and ensure all thresholds meet 80%. See §TEST-06.

---

## Checklist

- [ ] Vitest configured with JSDOM, path aliases, and coverage thresholds — §TEST-01
- [ ] MSW handlers defined for all API endpoints under test — §TEST-02
- [ ] Component tests use `screen` queries and `userEvent` — HR-1, HR-2, HR-3
- [ ] No direct `fetch` mocking; MSW used for network mocking — HR-4
- [ ] Custom hooks tested with `renderHook` — §TEST-04
- [ ] Playwright E2E covers critical banking flows (login, transfer, statements) — §TEST-05
- [ ] Coverage meets 80% across statements, branches, functions, lines — §TEST-06
- [ ] No snapshot tests on component JSX output — Core Standards
- [ ] Tests co-located with source files — Core Standards
- [ ] CI pipeline gates on test pass and coverage threshold — §TEST-06
