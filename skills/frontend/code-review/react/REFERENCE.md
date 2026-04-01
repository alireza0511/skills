# Code Review — React / Next.js Reference

React and Next.js code review patterns for web applications. See `skills/frontend/code-review/react/SKILL.md` for core rules.

## React Review Patterns

### Core Principle

**Review React PRs for correctness, TypeScript safety, component design, and web accessibility.** React's component model and TypeScript's type system catch many issues — focus reviews on data flow, side effects, performance, and security.

### What to Look For

| Area | Check |
|---|---|
| Component design | Are components appropriately sized? Single responsibility? |
| Props interface | Are props well-typed? No `any`? Proper defaults? |
| Hooks | Correct dependency arrays? No hooks in conditionals? |
| Side effects | Are effects properly cleaned up? Race conditions handled? |
| State | Is state lifted appropriately? No prop drilling? |
| Rendering | Unnecessary re-renders? Missing memoization for expensive operations? |
| Accessibility | Semantic HTML? ARIA where needed? Keyboard support? |
| Security | No XSS vectors? Sanitized user input? |

## Linting and Type Safety

### Required Configuration

```json
// .eslintrc.json
{
  "extends": [
    "next/core-web-vitals",
    "plugin:@typescript-eslint/strict",
    "plugin:jsx-a11y/recommended",
    "prettier"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": "error",
    "no-console": "error",
    "react-hooks/exhaustive-deps": "error"
  }
}
```

### Review Checks

| Check | Flag If |
|---|---|
| `npm run lint` | Any errors or warnings |
| `tsc --noEmit` | Any type errors |
| `any` types | Used without justification comment |
| `console.log` | Present in production code |
| `// @ts-ignore` | Used without justification |
| `eslint-disable` | Used without justification |

## React Anti-Patterns

Flag these during review:

### Missing cleanup in useEffect

```tsx
// WRONG — memory leak, race condition
useEffect(() => {
  fetchAccounts().then(setAccounts);
}, []);

// CORRECT — cleanup with abort controller
useEffect(() => {
  const controller = new AbortController();
  fetchAccounts({ signal: controller.signal }).then(setAccounts);
  return () => controller.abort();
}, []);
```

### Hooks in conditionals

```tsx
// WRONG — violates rules of hooks
if (isLoggedIn) {
  const [accounts, setAccounts] = useState([]);
}

// CORRECT — always call hooks at top level
const [accounts, setAccounts] = useState<Account[]>([]);
```

### Direct DOM manipulation

```tsx
// WRONG — bypasses React's reconciliation
document.getElementById('balance').textContent = newBalance;

// CORRECT — use state
const [balance, setBalance] = useState(initialBalance);
<span>{balance}</span>
```

### Prop drilling through many levels

```tsx
// WRONG — passing props through 5+ levels
<App user={user}>
  <Layout user={user}>
    <Sidebar user={user}>
      <AccountMenu user={user}>
        <AccountName user={user} />

// CORRECT — use context or state management
const UserContext = createContext<User | null>(null);
```

### Inline object/function props causing re-renders

```tsx
// WRONG — new object on every render
<AccountList style={{ padding: 16 }} onSelect={(id) => handleSelect(id)} />

// CORRECT — stable references
const listStyle = useMemo(() => ({ padding: 16 }), []);
const handleListSelect = useCallback((id: string) => handleSelect(id), [handleSelect]);
<AccountList style={listStyle} onSelect={handleListSelect} />
```

## React Testing

### Test Expectations for PRs

| Change Type | Required Tests |
|---|---|
| New component | Unit test: renders, accessibility, user interaction |
| New page/route | Integration test for page behavior + E2E if critical flow |
| API integration | Unit test with mocked fetch/API client |
| Custom hook | Unit test with `renderHook` |
| Bug fix | Regression test that fails without the fix |
| Refactor | Existing tests must still pass (no new tests needed unless coverage gap) |

### Component Test Pattern

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('transfer form validates amount', async () => {
  render(<TransferForm />);

  await userEvent.type(screen.getByLabelText('Amount'), '-50');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  expect(screen.getByRole('alert')).toHaveTextContent('Amount must be positive');
});
```

### Accessibility Test Pattern

```tsx
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('transfer form has no a11y violations', async () => {
  const { container } = render(<TransferForm />);
  expect(await axe(container)).toHaveNoViolations();
});
```

## React Performance

### Review Checklist

| Check | Flag If |
|---|---|
| Re-renders | Components re-rendering without prop/state changes |
| Memoization | Missing `useMemo`/`useCallback` for expensive operations passed as props |
| List rendering | Large lists not virtualized (use `react-window` or `react-virtuoso`) |
| Images | Not using `next/image` for optimization |
| Code splitting | Large pages not using `dynamic()` or `React.lazy()` |
| Data fetching | Fetching in client when server component would suffice |

### Common Performance Issues

```tsx
// WRONG — fetches on client, shows loading spinner
'use client';
export default function AccountsPage() {
  const [accounts, setAccounts] = useState([]);
  useEffect(() => { fetchAccounts().then(setAccounts); }, []);
  // ...
}

// CORRECT — server component, no loading state needed
export default async function AccountsPage() {
  const accounts = await fetchAccounts();
  // ...
}
```

## Bundle Size

### Review Checks

| Check | Flag If |
|---|---|
| New dependencies | Added without justification in PR description |
| Large libraries | Entire library imported when only a few functions needed |
| Tree shaking | Named imports not used (`import _ from 'lodash'` vs `import { debounce } from 'lodash'`) |
| Bundle analysis | Size increase > 5% without justification |

```tsx
// WRONG — imports entire library
import _ from 'lodash';
_.debounce(fn, 300);

// CORRECT — tree-shakeable import
import { debounce } from 'lodash';
debounce(fn, 300);
```

## React Security

### Review Checklist

| Check | Flag If |
|---|---|
| XSS | `dangerouslySetInnerHTML` without DOMPurify sanitization |
| User input | Unsanitized user input rendered or interpolated into URLs |
| Auth tokens | Stored in localStorage instead of httpOnly cookies |
| API calls | Missing CSRF protection on mutations |
| Dependencies | Known vulnerabilities in new dependencies (`npm audit`) |
| Env vars | Secrets in `NEXT_PUBLIC_*` env vars (exposed to client) |
| Console | Sensitive data logged to console |

---

## §Commit-Format

### Conventional Commits Specification

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Rules

| Rule | Detail |
|---|---|
| Type | Required. One of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `revert` |
| Scope | Optional but recommended. Module or component name in kebab-case |
| Description | Required. Imperative mood, lowercase, no period at end, max 72 chars |
| Body | Optional. Explain *why*, not *what*. Wrap at 72 chars |
| Footer | Optional. `BREAKING CHANGE:`, `Closes #123`, `Co-authored-by:` |

### Good Commit Examples

```
feat(transfers): add scheduled transfer support

Allow customers to schedule one-time and recurring transfers
with a future execution date. Transfers are validated at
creation and re-validated at execution time.

Closes PAY-456

---

fix(accounts): correct interest calculation for leap years

The daily interest calculation used 365 days for all years,
causing a small discrepancy in leap years. Now checks for
leap year and uses 366 when applicable.

Fixes PAY-789

---

chore(deps): update payment-sdk from 3.1.0 to 3.2.1

Addresses CVE-2025-1234 (high severity) in XML parsing.
No breaking changes in this minor version update.

---

refactor(auth): extract token validation to dedicated service

Moves JWT validation logic from middleware into a standalone
TokenValidationService to improve testability and reuse.
No behavior change.
```

### Bad Commit Examples

| Message | Problem |
|---|---|
| `fixed bug` | No type, no scope, vague description |
| `WIP` | Not a meaningful commit; squash before PR |
| `feat: Updated the thing` | Past tense; too vague; capitalized |
| `misc changes` | No type; no information |
| `fix(transfers): fix the transfer bug that was causing issues` | Redundant "fix"; describe what was fixed |

---

## §Branch-Strategy

### Branch Naming Convention

```
<type>/<ticket-id>-<short-description>
```

| Component | Rule | Example |
|---|---|---|
| Type | Matches commit type: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf` | `feat` |
| Ticket ID | JIRA/issue tracker ID, uppercase | `PAY-123` |
| Description | Kebab-case, 2-4 words | `iban-validation` |

### Examples

| Branch Name | Purpose |
|---|---|
| `feat/PAY-123-iban-validation` | New IBAN validation feature |
| `fix/PAY-456-negative-transfer` | Fix negative transfer amount bug |
| `chore/PAY-789-update-sdk` | Dependency update |
| `refactor/PAY-101-extract-auth` | Auth refactoring |
| `docs/PAY-202-api-migration` | API migration documentation |

### Branch Lifecycle

| Phase | Action |
|---|---|
| Create | Branch from `main` (or `develop` if using Gitflow) |
| Develop | Commit often, push regularly |
| PR | Open PR when ready; request review |
| Merge | Squash merge to target branch |
| Delete | Delete branch after merge (automated) |

### Protected Branches

| Branch | Protection Rules |
|---|---|
| `main` | 2 approvals, CI pass, no force push, no direct commits, code owner review |
| `release/*` | 1 approval, CI pass, no force push |
| `develop` (if used) | 1 approval, CI pass |

---

## §PR-Template

### Pull Request Description Template

```markdown
## Summary

<!-- 1-3 sentences: what does this PR do and why? -->

## Changes

<!-- Bulleted list of key changes -->
-
-
-

## Test Plan

<!-- How did you verify this change? -->
- [ ] Unit tests added/updated (React Testing Library)
- [ ] E2E tests added/updated (Playwright)
- [ ] Manual testing performed
- [ ] Accessibility tested (keyboard nav, screen reader)
- [ ] Describe test scenarios:

## React-Specific

- [ ] ESLint + Prettier pass with zero errors
- [ ] TypeScript strict — no `any` without justification
- [ ] No `dangerouslySetInnerHTML` without sanitization
- [ ] Semantic HTML used over ARIA where possible
- [ ] Bundle size impact acceptable
- [ ] `package-lock.json` changes intentional

## Checklist

- [ ] Code follows project conventions
- [ ] Tests pass locally and in CI
- [ ] No new warnings or lint errors
- [ ] Documentation updated (if applicable)
- [ ] Security considerations reviewed
- [ ] Breaking changes flagged and communicated

## Related

<!-- Links to tickets, related PRs, documentation -->
- Ticket: [PAY-XXX](link)
- Related PR: #NNN
```

---

## §Review-Guide

### Reviewer Responsibilities

| Responsibility | Detail |
|---|---|
| Correctness | Does the code do what the PR claims? |
| Security | Any XSS vectors, auth gaps, exposed secrets, CSRF issues? |
| Performance | Unnecessary re-renders, missing code splitting, client vs server components? |
| Maintainability | Is the code readable, well-structured, appropriately documented? |
| Test coverage | Are new behaviors tested? Are edge cases covered? |
| Conventions | Does it follow project TypeScript/React conventions? |
| Accessibility | Semantic HTML, ARIA, keyboard navigation, screen reader support? |
| Bundle size | Any unjustified size increases from new dependencies? |

### Feedback Guidelines

| Do | Do Not |
|---|---|
| Comment on the code, not the person | "You always do this wrong" |
| Explain *why* something should change | "Change this" (without reason) |
| Suggest alternatives with examples | Just say "this is bad" |
| Distinguish blocking vs. non-blocking | Leave all comments as blocking |
| Acknowledge good work | Only point out negatives |

### Comment Prefixes

Use prefixes to clarify intent:

| Prefix | Meaning | Blocks Merge? |
|---|---|---|
| `blocking:` | Must be addressed before merge | Yes |
| `suggestion:` | Improvement idea, author decides | No |
| `question:` | Seeking understanding, not necessarily a change | No |
| `nit:` | Trivial style/preference issue | No |
| `praise:` | Something done well | No |

### Review Turnaround SLA

| Priority | First Review | Follow-Up |
|---|---|---|
| Critical (hotfix) | 2 hours | Same day |
| Normal | 4 business hours | 1 business day |
| Low (docs, chore) | 1 business day | 2 business days |

---

## §Merge-Policy

### Merge Strategies

| Strategy | Use When | Branch Target |
|---|---|---|
| Squash merge | Feature/fix branches to main | main |
| Merge commit | Release branches (preserve history) | main (from release) |
| Rebase | Updating feature branch from main | feature branch |
| Fast-forward | Never (always create merge record) | — |

### Squash Merge Rules

| Rule | Detail |
|---|---|
| Final message | Use PR title as squash commit message (must follow Conventional Commits) |
| Body | Include PR number: `feat(transfers): add scheduled transfers (#123)` |
| Co-authors | Preserve co-author trailers from individual commits |
| Branch cleanup | Auto-delete source branch after merge |

### Pre-Merge Checklist (Automated)

| Check | Required | Detail |
|---|---|---|
| CI pipeline | Yes | All jobs green (tests, lint, type check, build) |
| Approvals | Yes | 2 for main, 1 for feature |
| Conversations resolved | Yes | All blocking comments addressed |
| Branch up to date | Yes | Rebased on latest target branch |
| No merge conflicts | Yes | Clean merge possible |
| Security scan | Yes | No new critical/high findings |
| Bundle size | Yes | No unjustified increase > 5% |

### Hotfix Process

| Step | Action |
|---|---|
| 1 | Branch from `main`: `fix/PAY-XXX-critical-description` |
| 2 | Implement fix with tests |
| 3 | Open PR with `[HOTFIX]` prefix in title |
| 4 | Minimum 1 approval (expedited review) |
| 5 | Squash merge to `main` |
| 6 | Tag release immediately |
| 7 | Post-incident: full review within 48 hours |
