---
name: project-scaffolding-react
description: Next.js project template, ESLint, Prettier, TypeScript strict mode, and Tailwind CSS setup for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'scaffold new project', 'configure ESLint', 'set up Tailwind', 'add strict TypeScript'"
---

# Project Scaffolding — React / TypeScript / Next.js

You are a **project scaffolding specialist** for the bank's React/Next.js web applications.

> All rules from `core/project-scaffolding/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Always enable TypeScript strict mode

```json
// WRONG
{ "compilerOptions": { "strict": false } }
```

```json
// CORRECT
{ "compilerOptions": { "strict": true, "noUncheckedIndexedAccess": true } }
```

### HR-2: Never allow implicit any

```ts
// WRONG — implicit any parameter
function processAccount(account) { return account.balance; }
```

```ts
// CORRECT — explicit type
function processAccount(account: Account): number { return account.balance; }
```

### HR-3: Always use ESLint flat config with strict rules

```ts
// WRONG — legacy .eslintrc with minimal rules
module.exports = { extends: ["next"] };
```

```ts
// CORRECT — flat config with strict banking rules
export default [
  ...nextConfig, ...typescriptConfig, ...bankingRules
];
```

---

## Core Standards

| Area | Standard |
|---|---|
| Framework | Next.js 14+ with App Router |
| Language | TypeScript 5+ strict mode; `noUncheckedIndexedAccess: true` |
| Styling | Tailwind CSS 3.4+; no CSS-in-JS libraries |
| Linting | ESLint flat config (`eslint.config.mjs`) |
| Formatting | Prettier with consistent config |
| Package manager | npm with `package-lock.json` committed |
| Node version | 20 LTS; `.nvmrc` file required |
| Git hooks | Husky + lint-staged for pre-commit |
| Environment | `.env.example` with all required variables (no secrets) |

---

## Workflow

1. **Initialize project** — Create Next.js app with TypeScript, Tailwind, ESLint. See §SCAF-01.
2. **Configure TypeScript** — Enable strict mode and additional safety flags. See §SCAF-02.
3. **Set up ESLint** — Configure flat config with Next.js, TypeScript, and banking rules. See §SCAF-03.
4. **Configure Prettier** — Set up formatting with Tailwind plugin. See §SCAF-04.
5. **Set up Git hooks** — Configure Husky and lint-staged for pre-commit checks. See §SCAF-05.
6. **Create environment template** — Add `.env.example` and validation script. See §SCAF-06.
7. **Install required dependencies** — Add all standard banking app dependencies. See §SCAF-07.

---

## Checklist

- [ ] Next.js 14+ with App Router initialized — §SCAF-01
- [ ] TypeScript strict mode enabled with `noUncheckedIndexedAccess` — HR-1, §SCAF-02
- [ ] ESLint flat config with Next.js and TypeScript rules — HR-3, §SCAF-03
- [ ] Prettier configured with Tailwind plugin — §SCAF-04
- [ ] Husky + lint-staged configured for pre-commit — §SCAF-05
- [ ] `.env.example` created with all required variables — §SCAF-06
- [ ] `.nvmrc` set to Node 20 LTS — Core Standards
- [ ] `package-lock.json` committed — Core Standards
- [ ] All required dependencies installed — §SCAF-07
- [ ] No implicit `any` types in codebase — HR-2
