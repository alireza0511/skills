---
name: cicd-react
description: GitHub Actions, Vercel deployment, Lighthouse CI, and Docker build for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'create CI pipeline', 'add Lighthouse gates', 'configure Docker build', 'set up preview deployments'"
---

# CI/CD — React / TypeScript / Next.js

You are a **CI/CD pipeline specialist** for the bank's React/Next.js web applications.

> All rules from `core/cicd/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Always run type-check, lint, test, and build in CI

```yaml
# WRONG — incomplete CI
steps:
  - run: npm run build
```

```yaml
# CORRECT — full quality gate
steps:
  - run: npm run type-check
  - run: npm run lint
  - run: npm run test:coverage
  - run: npm run build
```

### HR-2: Never deploy without passing Lighthouse thresholds

```yaml
# WRONG — deploy without performance gates
deploy:
  needs: [build]
```

```yaml
# CORRECT — deploy after Lighthouse passes
deploy:
  needs: [build, lighthouse]
```

### HR-3: Never expose secrets in build logs

```yaml
# WRONG — echoing secrets
- run: echo ${{ secrets.API_KEY }}
```

```yaml
# CORRECT — secrets masked automatically; never reference in echo/log
- run: npm run build
  env:
    API_KEY: ${{ secrets.API_KEY }}
```

---

## Core Standards

| Area | Standard |
|---|---|
| CI platform | GitHub Actions |
| Deployment | Vercel (primary); Docker container (on-premise) |
| Quality gates | Type-check, lint (0 warnings), test (80% coverage), build |
| Lighthouse CI | Performance >= 90, Accessibility >= 95, Best Practices >= 95 |
| Preview deploys | Automatic on every PR via Vercel |
| Docker | Multi-stage build; distroless or Alpine base |
| Cache | npm cache + Next.js build cache in CI |
| Branch protection | `main` requires passing CI + 1 approval |

---

## Workflow

1. **Configure GitHub Actions** — Create CI workflow with type-check, lint, test, build steps. See §CI-01.
2. **Add Lighthouse CI** — Configure Lighthouse CI with performance and a11y thresholds. See §CI-02.
3. **Set up Vercel deployment** — Configure Vercel project with environment variables and preview deploys. See §CI-03.
4. **Create Docker build** — Write multi-stage Dockerfile for on-premise deployment. See §CI-04.
5. **Configure preview deployments** — Set up automatic preview deploys on PRs with comment integration. See §CI-05.
6. **Set up caching** — Configure npm and Next.js build cache for fast CI runs. See §CI-06.

---

## Checklist

- [ ] GitHub Actions CI runs type-check, lint, test, build on every PR — HR-1, §CI-01
- [ ] Lighthouse CI gates: Performance >= 90, A11y >= 95 — HR-2, §CI-02
- [ ] No secrets exposed in build logs — HR-3
- [ ] Vercel deployment configured with environment variables — §CI-03
- [ ] Docker multi-stage build produces minimal image — §CI-04
- [ ] Preview deployments active on every PR — §CI-05
- [ ] npm and Next.js build cache configured — §CI-06
- [ ] `main` branch protected: CI pass + 1 approval required — Core Standards
- [ ] Coverage report uploaded as CI artifact — §CI-01
- [ ] E2E tests run against preview deployment — §CI-05
