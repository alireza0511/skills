---
name: documentation-react
description: TSDoc, Storybook, component prop documentation, and feature READMEs for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add TSDoc to component', 'create Storybook story', 'document props'"
---

# Documentation — React / TypeScript / Next.js

You are a **documentation specialist** for the bank's React/Next.js web applications.

> All rules from `core/documentation/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Always document component props with TypeScript interfaces

```tsx
// WRONG — inline anonymous type, no docs
export function Button(props: { label: string; onClick: () => void }) {}
```

```tsx
// CORRECT — named interface with TSDoc
/** Primary action button for form submissions and CTAs. */
interface ButtonProps {
  /** Button label text displayed to the user. */
  label: string;
  /** Callback fired when the button is clicked. */
  onClick: () => void;
}
export function Button({ label, onClick }: ButtonProps) {}
```

### HR-2: Always provide a Storybook story for shared components

```tsx
// WRONG — component in ui/ with no story
// components/ui/Button/Button.tsx exists
// components/ui/Button/Button.stories.tsx MISSING
```

```tsx
// CORRECT — story co-located with component
// components/ui/Button/Button.stories.tsx EXISTS
```

### HR-3: Never use abbreviations without explanation in docs

```tsx
// WRONG
/** Handles the ACH txn flow via the FBO acct. */
```

```tsx
// CORRECT
/** Handles the ACH (Automated Clearing House) transaction flow via the FBO (For Benefit Of) account. */
```

---

## Core Standards

| Area | Standard |
|---|---|
| Component docs | TSDoc on all exported components; `@param`, `@returns`, `@example` |
| Props documentation | Named TypeScript interfaces with TSDoc on every property |
| Storybook | Required for all `components/ui/` components; optional for feature components |
| Feature READMEs | `README.md` per feature folder documenting purpose, dependencies, usage |
| API documentation | TSDoc on all Route Handlers documenting request/response shapes |
| Changelog | Notable component API changes documented in CHANGELOG.md |
| Code comments | Explain "why" not "what"; no redundant comments |

---

## Workflow

1. **Define component interface** — Create named props interface with TSDoc on every property. See §DOC-01.
2. **Document the component** — Add TSDoc block above component with description and `@example`. See §DOC-02.
3. **Create Storybook story** — Write stories for all variants, states, and edge cases. See §DOC-03.
4. **Write feature README** — Document feature purpose, architecture decisions, and usage. See §DOC-04.
5. **Document API routes** — Add TSDoc to Route Handlers with request/response examples. See §DOC-05.

---

## Checklist

- [ ] All exported components have TSDoc documentation — §DOC-02
- [ ] All props interfaces have TSDoc on every property — HR-1
- [ ] All `components/ui/` components have Storybook stories — HR-2
- [ ] No unexplained abbreviations in documentation — HR-3
- [ ] Feature folders contain `README.md` — §DOC-04
- [ ] Route Handlers documented with request/response types — §DOC-05
- [ ] Stories cover default, variants, disabled, loading, error states — §DOC-03
- [ ] Code comments explain "why" not "what" — Core Standards
