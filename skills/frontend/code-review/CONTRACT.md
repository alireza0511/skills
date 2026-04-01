# Skill Contract — Code Review

## Identity

- **Name:** code-review
- **Version:** 1.0.0
- **One-liner:** PR conventions, conventional commits, branch strategy, review checklist for services
- **Platforms:** flutter, react
- **Target type:** both

## What the LLM Must Ask the User First

- Which platform/framework: Flutter or React/Next.js?
- What is the review scope: full PR, commit messages only, branch/naming conventions, or PR description?

## Hard Rules

- Commit messages must follow Conventional Commits 1.0.0: `type(scope): description`
- PRs must be scoped to a single concern — no mixing features, fixes, and refactors
- Never merge without required approvals (2 for main including code owner, 1 for feature branches)
- All CI checks must pass before merge: tests, lint, security scan, build
- Branch naming must follow `type/ticket-id-short-description` convention
- Breaking changes must be flagged with `!` after type or `BREAKING CHANGE:` footer

## Standards

- Commit format: Conventional Commits 1.0.0 — `type(scope): description`
- PR size: max 400 lines changed (excluding generated code)
- PR scope: single concern per PR
- Branch naming: `type/ticket-id-short-description`
- Required approvals: 2 for main (including code owner), 1 for feature branches
- CI gate: all checks pass before merge (tests, lint, security scan, build)
- Merge strategy: squash merge to main
- PR description: template with summary, test plan, checklist (mandatory)
- Review turnaround: first review within 4 business hours
- Draft PRs: use draft status for WIP, do not request review on drafts

## Platform-Specific Notes

### Flutter
- Dart analysis must pass with zero warnings (`dart analyze`)
- Follow Effective Dart style guide
- Widget tests required for all new UI components
- Golden tests for complex visual components
- `flutter_lints` package with custom custom lint rules
- Verify `pubspec.lock` changes are intentional

### React
- ESLint + Prettier must pass with zero errors/warnings
- TypeScript strict mode — no `any` types without justification
- React Testing Library for component tests (no Enzyme)
- Playwright or Cypress for E2E tests
- Bundle size impact checked — flag increases > 5%
- Verify `package-lock.json` changes are intentional

## Workflow

1. Check branch name — verify format: `type/ticket-id-short-description`
2. Review commits — confirm all commits follow Conventional Commits; squash fixups
3. Assess PR scope — verify single concern; flag if PR mixes features, fixes, and refactors
4. Check PR size — flag if > 400 lines changed (suggest split)
5. Verify CI status — all checks must pass: tests, lint, security scan, build
6. Review PR description — confirm summary, test plan, and checklist are complete
7. Platform-specific review — apply Flutter or React review patterns from REFERENCE.md
8. Validate approvals — ensure required approvals met, including code owner

## Checklist

- [ ] Branch name follows `type/ticket-id-short-description` convention
- [ ] All commits follow Conventional Commits format
- [ ] PR addresses a single concern (no mixed features/fixes/refactors)
- [ ] PR is within 400-line limit (or justified split plan documented)
- [ ] PR description includes summary, test plan, and checklist
- [ ] All CI checks pass (tests, lint, security scan, build)
- [ ] Required approvals obtained (2 for main, including code owner)
- [ ] No TODO/FIXME/HACK without linked ticket
- [ ] No commented-out code
- [ ] No hardcoded secrets or environment-specific values
- [ ] Breaking changes flagged with `!` or `BREAKING CHANGE:` footer
- [ ] Related documentation updated (API docs, ADRs if architectural change)
- [ ] Platform-specific checks completed

## Reference Sections Needed

### Per-Platform (flutter/REFERENCE.md, react/REFERENCE.md)

Each platform REFERENCE.md includes the core commit format, branch strategy, PR template, review guide, and merge policy — plus platform-specific content:
- Platform-specific linting and analysis rules
- Test expectations and patterns for the framework
- Build and CI pipeline considerations
- Common code review patterns specific to the framework
- Anti-patterns to flag during review
- Performance review checklist
- Security review checklist
