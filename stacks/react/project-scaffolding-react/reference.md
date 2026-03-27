# Project Scaffolding — React / Next.js Reference

## §SCAF-01: Project Initialization

```bash
# Create Next.js project with recommended options
npx create-next-app@latest bank-web \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-npm
```

### Recommended Directory Structure

```
bank-web/
├── .github/
│   └── workflows/
│       └── ci.yml
├── .husky/
│   └── pre-commit
├── e2e/
│   ├── pages/
│   └── *.spec.ts
├── messages/
│   ├── en.json
│   └── ar.json
├── public/
├── src/
│   ├── app/
│   │   ├── (auth)/
│   │   ├── dashboard/
│   │   ├── api/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── error.tsx
│   │   └── not-found.tsx
│   ├── components/
│   │   ├── ui/
│   │   ├── features/
│   │   └── layout/
│   ├── hooks/
│   ├── lib/
│   │   ├── api/
│   │   ├── domain/
│   │   ├── errors/
│   │   └── utils.ts
│   ├── stores/
│   ├── types/
│   └── styles/
│       └── globals.css
├── test/
│   ├── mocks/
│   └── setup.ts
├── scripts/
├── .env.example
├── .nvmrc
├── .prettierrc
├── eslint.config.mjs
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── vitest.config.ts
└── playwright.config.ts
```

---

## §SCAF-02: TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": false,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],
  "exclude": ["node_modules"]
}
```

---

## §SCAF-03: ESLint Flat Configuration

```js
// eslint.config.mjs
import { FlatCompat } from "@eslint/eslintrc";
import js from "@eslint/js";
import tsPlugin from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";
import importPlugin from "eslint-plugin-import";
import jsxA11y from "eslint-plugin-jsx-a11y";

const compat = new FlatCompat({ baseDirectory: import.meta.dirname });

export default [
  js.configs.recommended,
  ...compat.extends("next/core-web-vitals", "next/typescript"),
  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        project: "./tsconfig.json",
      },
    },
    plugins: {
      "@typescript-eslint": tsPlugin,
      import: importPlugin,
      "jsx-a11y": jsxA11y,
    },
    rules: {
      // TypeScript strict rules
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports" },
      ],
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/no-misused-promises": "error",
      "@typescript-eslint/strict-boolean-expressions": "warn",

      // Import ordering
      "import/order": [
        "error",
        {
          groups: [
            "builtin",
            "external",
            "internal",
            ["parent", "sibling"],
            "index",
            "type",
          ],
          "newlines-between": "always",
          alphabetize: { order: "asc" },
        },
      ],
      "import/no-duplicates": "error",

      // React / Next.js
      "react/no-danger": "error",
      "react/jsx-no-target-blank": "error",

      // Accessibility
      "jsx-a11y/alt-text": "error",
      "jsx-a11y/anchor-is-valid": "error",
      "jsx-a11y/click-events-have-key-events": "error",
      "jsx-a11y/no-static-element-interactions": "error",
      "jsx-a11y/label-has-associated-control": "error",

      // General
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "no-debugger": "error",
      eqeqeq: ["error", "always"],
    },
  },
  {
    // Test file overrides
    files: ["**/*.test.{ts,tsx}", "**/*.spec.{ts,tsx}", "test/**/*"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-floating-promises": "off",
    },
  },
  {
    ignores: [".next/", "node_modules/", "coverage/", "test-results/"],
  },
];
```

---

## §SCAF-04: Prettier Configuration

```json
// .prettierrc
{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

```
// .prettierignore
.next
node_modules
coverage
test-results
*.min.js
pnpm-lock.yaml
package-lock.json
```

---

## §SCAF-05: Git Hooks (Husky + lint-staged)

```bash
# Setup commands
npm install --save-dev husky lint-staged
npx husky init
```

```bash
# .husky/pre-commit
npx lint-staged
```

```json
// package.json (lint-staged config)
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,md,yml,yaml}": [
      "prettier --write"
    ]
  }
}
```

---

## §SCAF-06: Environment Configuration

```bash
# .env.example
# ============================================================
# National Bank Web Application — Environment Variables
# ============================================================
# Copy to .env.local and fill in values. NEVER commit .env.local.
# Variables prefixed with NEXT_PUBLIC_ are exposed to the browser.
# ============================================================

# --- Application ---
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000

# --- Authentication (NextAuth.js) ---
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=          # Generate: openssl rand -base64 32
OIDC_ISSUER_URL=          # Bank IdP issuer URL
OIDC_CLIENT_ID=           # OAuth client ID
OIDC_CLIENT_SECRET=       # OAuth client secret (server-only!)

# --- API ---
API_BASE_URL=             # Backend API URL
API_KEY=                  # Server-only API key

# --- Monitoring ---
SENTRY_DSN=               # Sentry DSN (server)
NEXT_PUBLIC_SENTRY_DSN=   # Sentry DSN (client — safe to expose)

# --- CSRF ---
CSRF_SECRET=              # CSRF token secret: openssl rand -base64 32

# --- Database (if applicable) ---
DATABASE_URL=             # PostgreSQL connection string
```

```
# .nvmrc
20
```

### Environment Validation

```ts
// lib/env.ts
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]),
  NEXTAUTH_URL: z.string().url(),
  NEXTAUTH_SECRET: z.string().min(32),
  OIDC_ISSUER_URL: z.string().url(),
  OIDC_CLIENT_ID: z.string().min(1),
  OIDC_CLIENT_SECRET: z.string().min(1),
  API_BASE_URL: z.string().url(),
  SENTRY_DSN: z.string().url().optional(),
  CSRF_SECRET: z.string().min(32),
});

export const env = envSchema.parse(process.env);
```

---

## §SCAF-07: Required Dependencies

```json
// package.json — dependencies
{
  "dependencies": {
    "next": "^14.2.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "next-auth": "^5.0.0",
    "zod": "^3.23.0",
    "@tanstack/react-query": "^5.50.0",
    "zustand": "^4.5.0",
    "next-intl": "^3.15.0",
    "react-error-boundary": "^4.0.0",
    "server-only": "^0.0.1"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "@types/node": "^20.14.0",
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0",
    "eslint": "^9.0.0",
    "@eslint/eslintrc": "^3.1.0",
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0",
    "eslint-plugin-import": "^2.29.0",
    "eslint-plugin-jsx-a11y": "^6.9.0",
    "prettier": "^3.3.0",
    "prettier-plugin-tailwindcss": "^0.6.0",
    "husky": "^9.0.0",
    "lint-staged": "^15.2.0",
    "vitest": "^2.0.0",
    "@vitejs/plugin-react": "^4.3.0",
    "vite-tsconfig-paths": "^4.3.0",
    "@vitest/coverage-istanbul": "^2.0.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/jest-dom": "^6.4.0",
    "@testing-library/user-event": "^14.5.0",
    "msw": "^2.3.0",
    "jest-axe": "^9.0.0",
    "@playwright/test": "^1.45.0",
    "@axe-core/playwright": "^4.9.0",
    "@sentry/nextjs": "^8.0.0"
  }
}
```

### NPM Scripts

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint . --max-warnings=0",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "type-check": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "playwright test",
    "audit:check": "npm audit --audit-level=high --omit=dev",
    "env:validate": "tsx src/lib/env.ts",
    "precommit": "lint-staged"
  }
}
```
