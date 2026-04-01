# Skill Development — Reference

Detailed reference material for authoring enterprise Copilot skills. See `SKILL.md` for core rules and workflow.

## Example CONTRACT.md

A contract defines the shared identity and rules for a multi-platform skill.

```markdown
# Skill Contract — Error Handling

## Identity

- **Name:** error-handling
- **One-liner:** Error taxonomy, user-facing messages, retry/backoff, and circuit breaker patterns for services
- **Platforms:** flutter, react
- **Target type:** both

## What the LLM Must Ask the User First

- What is the audit scope: full app, specific service, specific component, or PR/diff changes only?

## Hard Rules

- Never expose internal errors to users — return safe error with correlation ID
- Always use error codes from the error taxonomy
- All network calls must use exponential backoff retry (max 3 attempts)
- Circuit breaker on all downstream dependencies (open after 5 failures, half-open after 30s)

## Standards

- API errors: RFC 7807 Problem Detail format
- Every error response includes traceId
- Log full error internally, return safe message externally

## Platform-Specific Notes

### Flutter
- Use Result type pattern for error propagation
- Show SnackBar for transient errors, dialog for blocking errors
- Respect platform error conventions (MaterialBanner on Android, CupertinoAlertDialog on iOS)

### React
- Use Error Boundary components for React render errors
- Use toast notifications for transient errors, modal for blocking errors
- Server components: throw errors to trigger error.tsx boundary

## Workflow

1. Collect context — ask the mandatory question, do not proceed without answer
2. Load the platform REFERENCE.md
3. Identify error handling surface
4. Audit against hard rules and standards
5. Remediate violations
6. Write tests and verify

## Checklist

- [ ] Scope question asked and answered
- [ ] Platform reference loaded
- [ ] All API errors use RFC 7807 format
- [ ] No internal details in user-facing errors
- [ ] Retry with backoff on all network calls
- [ ] Circuit breaker on all downstream dependencies
- [ ] Error codes from error taxonomy
- [ ] traceId in every error response
- [ ] Tests written
```

## Example Platform SKILL.md — Flutter

```markdown
---
name: error-handling-flutter
description: Error taxonomy, user-facing messages, retry/backoff, and circuit breaker patterns for Flutter banking apps
allowed-tools: Read, Edit, Grep
argument-hint: "[scope] — e.g. 'full app', 'payment service', 'PR changes'"
---

# Flutter Error Handling

You are an error handling expert for the Flutter applications. When invoked, audit and fix error handling patterns against organization standards.

## Step 0 — Collect Context (MANDATORY)

Before any work, you MUST ask this question. Do not proceed until answered.

**Q1: Audit scope**
> "What should I audit: **full app**, **specific service**, **specific component**, or **PR/diff changes only**?"

### After Answer — Load Reference

Read `core/error-handling/flutter/REFERENCE.md` before proceeding.

## Hard Rules

### Never expose internal errors to users

` ``dart
// WRONG — stack trace shown to user
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));

// CORRECT — safe message with correlation ID
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong. Ref: $traceId')));
` ``

## Workflow

1. Collect context — ask Q1, stop until answered
2. Load reference
3. Identify error handling surface
4. Audit against hard rules
5. Remediate by severity
6. Write tests

## Checklist

- [ ] Scope collected and reference loaded
- [ ] No internal errors exposed to users
- [ ] Result type used for error propagation
- [ ] Retry with backoff on network calls
- [ ] Tests written
```

**Line count:** ~45 lines. Ideal range.

## Example Platform REFERENCE.md — Flutter

```markdown
# Error Handling — Flutter Reference

Flutter-specific error handling patterns. See `core/error-handling/flutter/SKILL.md` for core rules.

## Error Display Patterns

### Transient Errors (SnackBar)

` ``dart
void showTransientError(BuildContext context, String message, String traceId) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$message (Ref: $traceId)')),
  );
}
` ``

### Blocking Errors (Dialog)

` ``dart
Future<void> showBlockingError(BuildContext context, String message) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text('Error'),
      content: Text(message),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
    ),
  );
}
` ``

## Result Type Pattern

` ``dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}
` ``

---

# Core Error Handling Reference

## Error Code Taxonomy

| Category | Code Range | Example |
|----------|-----------|---------|
| Validation | 1000–1999 | 1001: Invalid IBAN format |
| Business | 2000–2999 | 2001: Insufficient funds |
| Infrastructure | 3000–3999 | 3001: Downstream timeout |

## Retry and Circuit Breaker

| Pattern | Configuration |
|---------|--------------|
| Retry | Exponential backoff, max 3 attempts, base 1s |
| Circuit breaker | Open after 5 failures, half-open after 30s |
```

## Naming Convention for Skill Directories

### Core skills (multi-platform)

```
core/<topic>/
├── CONTRACT.md
├── flutter/
│   ├── SKILL.md
│   └── REFERENCE.md
└── react/
    ├── SKILL.md
    └── REFERENCE.md
```

Topic names are singular, kebab-case: `security`, `testing`, `api-design`, `error-handling`, `accessibility`, `code-review`.

### Stack skills (single platform)

```
stacks/<language>/<topic>-<language>/
├── SKILL.md
└── REFERENCE.md
```

Examples:
- `stacks/java/security-java/`
- `stacks/kotlin/testing-kotlin/`

The `<topic>` in the stack skill name matches the core skill it extends.

## Cross-Referencing Between Skills

### Platform skill referencing another platform skill

```markdown
> Logging rules from `core/observability/flutter/SKILL.md` § Hard Rules apply to error logging.
```

### Stack skill referencing a core platform skill

```markdown
> All rules from `core/security/flutter/SKILL.md` apply here. This skill adds Dart-specific implementation guidance.
```

### SKILL.md referencing its own REFERENCE.md

```markdown
For full code examples, read `core/error-handling/flutter/REFERENCE.md` § Result Type Pattern.
```

### Cross-platform reference

```markdown
See `core/accessibility/react/SKILL.md` § Hard Rules for the React equivalent.
```

## CI Validation Rules

The following CI checks run on every PR that modifies skills:

| Check | Script | Fails when |
|-------|--------|-----------|
| Frontmatter validation | `scripts/validate-frontmatter.sh` | Missing `name`, `description`, or `allowed-tools` |
| Line budget | `scripts/check-line-budget.sh` | SKILL.md > 500 lines |
| Structure check | `scripts/check-structure.sh` | Missing required sections (rules, workflow, checklist) |
| REFERENCE.md existence | CI workflow | Platform directory has no `REFERENCE.md` |
| CONTRACT.md existence | CI workflow | Multi-platform skill root has no `CONTRACT.md` |
| Code block size | `scripts/check-codeblock-size.sh` | SKILL.md code block > 20 lines |
| Secrets scan | CI workflow | Detected API keys, passwords, tokens |

## Common Authoring Mistakes

| Mistake | Impact | Fix |
|---------|--------|-----|
| Shared REFERENCE.md at skill root | Extra file, content not self-contained per platform | Merge core content into each platform's REFERENCE.md |
| Shared SKILL.md at skill root | Skill not platform-specific, asks unnecessary questions | Create platform-specific SKILL.md in each subdirectory |
| Lowercase reference.md | Inconsistent naming | Use REFERENCE.md (uppercase) |
| Duplicating rules across platform SKILL.md files | Bloats token usage, diverges over time | Keep shared rules in CONTRACT.md, platform-specific rules in SKILL.md |
| Writing Java examples in a core skill | Core skill unusable for other teams | Platform-specific examples go in platform REFERENCE.md |
| Putting full class files in SKILL.md | 100+ lines consumed on every invocation | Move to REFERENCE.md, show 3–5 key lines in SKILL.md |
| Missing CONTRACT.md for multi-platform skill | No shared contract definition | Always create CONTRACT.md at skill root |
| Prose-heavy SKILL.md | Wastes tokens, hard to scan | Convert to tables, delete filler words |
