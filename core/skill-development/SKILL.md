---
name: skill-development
description: Standards for writing SKILL.md and reference.md files — structure, token budget, compression rules, and quality guidelines for enterprise skill authoring
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
argument-hint: "[skill name] — e.g. 'security-java', 'testing-react', 'observability'"
---

# Skill Development Standards

You are a skill author for the bank's enterprise Copilot skills repository. When invoked, help create or improve SKILL.md and reference.md files that follow every rule in this document.

## Token Budget

Skills are loaded into the LLM context window on every invocation. Every line costs tokens. Write the minimum needed for correct behavior.

| Rating | Lines | When appropriate |
|--------|-------|------------------|
| Ideal | < 150 | Focused, single-concern skills |
| Acceptable | 150–300 | Multi-concern skills with examples |
| Needs justification | 300–500 | Complex domains (e.g., accessibility with platform matrix) |
| Too large | > 500 | Split into multiple skills or compress aggressively |

**Measure before committing:** `wc -l core/<name>/SKILL.md` or `stacks/<lang>/<name>/SKILL.md`.

## File Split — SKILL.md vs reference.md

Every skill directory contains two files:

```
core/<name>/           OR    stacks/<lang>/<name>/
├── SKILL.md                 ├── SKILL.md
└── reference.md             └── reference.md
```

### SKILL.md (always loaded into context)

- Frontmatter, role statement, hard rules
- Core decision logic (tables, mappings, short examples)
- Workflow steps and checklist
- **Budget: < 300 lines**

### reference.md (loaded on demand)

- Full code examples (complete classes, test suites, configs)
- Audit/report templates
- Extended mapping tables
- Platform-specific checklists
- Migration guides and walkthroughs

### How SKILL.md references it

```markdown
For full code examples, read `core/<name>/reference.md` § Section Name.
```

The agent reads reference.md only when it needs that section — not on every invocation.

### reference.md format

No frontmatter. Use clear `##` section headings so SKILL.md can point to specific sections with `§`.

```markdown
# <Skill Name> — Reference

## Section Name
[detailed content]

## Another Section
[detailed content]
```

## Required SKILL.md Structure

Every SKILL.md must have these sections in order:

### 1. Frontmatter (required)

```yaml
---
name: kebab-case-name
description: One sentence — used for skill discovery, be specific and searchable
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
argument-hint: "[what the user passes] — e.g. 'widget name', 'service name'"
---
```

| Field | Required | Rules |
|-------|----------|-------|
| `name` | Yes | Kebab-case, must match directory name |
| `description` | Yes | Search-optimized — include key terms users would type |
| `allowed-tools` | Yes | Only tools the skill needs. Don't grant tools it doesn't use |
| `argument-hint` | No | Format + 1–2 examples. Omit if skill takes no arguments |

### 2. Role Statement (1–2 lines)

```markdown
You are a [role] for [context]. When invoked, [what you do].
```

For **core skills** (language-agnostic):
```markdown
You are a security expert for bank services. When invoked, audit and fix security issues against bank policy.
```

For **stack skills** (language-specific):
```markdown
You are a security expert for the bank's Java/Spring services. When invoked, audit and fix Java-specific security issues against bank policy.
```

### 3. Hard Rules

Non-negotiable constraints. Each rule:
- One sentence stating the rule
- One WRONG/CORRECT code pair (2–4 lines each)

Do NOT duplicate rules from another skill. Reference instead:

```markdown
> All security rules from `core/security/SKILL.md` § Hard Rules apply here.
```

### 4. Core Content

Domain-specific guidance. Structure varies by skill but must follow compression rules below.

### 5. Workflow (3–7 steps)

Numbered steps the agent follows when invoked.

### 6. Checklist

Markdown checkbox list of deliverables. The agent checks these before finishing.

## Compression Rules

### Tables over prose

```markdown
<!-- WRONG — 6 lines of prose -->
When the layout mode is VERTICAL, use a Column. When it is
HORIZONTAL, use a Row. When null, use a Stack.

<!-- CORRECT — 4 lines, scannable -->
| Layout Mode | Widget |
|-------------|--------|
| `VERTICAL` | `Column` |
| `HORIZONTAL` | `Row` |
```

### One example per pattern, not per variant

Show the pattern once. Use a table for variant differences.

### Reference, don't duplicate

If content exists in another skill, point to it:

```markdown
See `core/testing/SKILL.md` § Checklist for the test coverage policy.
```

Never copy-paste sections between skills.

### Code examples: minimal and annotated

- Show only lines that illustrate the point — not full files
- Use inline comments, not paragraphs above/below
- Max **one** WRONG/CORRECT pair per rule
- Omit imports, boilerplate, and obvious setup

### Language-agnostic examples in core skills

Core skills must use pseudocode or generic patterns. Language-specific examples belong in stack skills.

```markdown
<!-- WRONG in a core skill — Java-specific -->
@PreAuthorize("hasRole('ADMIN')")

<!-- CORRECT in a core skill — language-agnostic -->
Enforce method-level authorization checks on all privileged operations.
```

### Shorthand conventions

| Instead of | Write |
|-----------|-------|
| "the user should" | imperative: "Do X" |
| "it is important to note that" | delete — just state the fact |
| "for example, you might want to" | show the example directly |
| "make sure to always" | "Always X" or just state the rule |

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Full file as example (30+ lines) | Show only relevant 3–5 lines |
| Repeating rules from another skill | Reference with `§` notation |
| Explaining language basics | State project-specific constraints only |
| Multiple examples for one rule | One WRONG/CORRECT pair max |
| Verbose prose between sections | Delete — headings are self-explanatory |
| JSON + code duplicating same content | Show once in canonical form |

## Workflow — Creating a New Skill

1. **Identify scope** — one skill = one concern. Two unrelated domains → split
2. **Check overlap** — read existing skills. Reference shared content, don't duplicate
3. **Determine tier** — core (language-agnostic) goes in `core/`, stack-specific goes in `stacks/<lang>/`
4. **Write SKILL.md** — frontmatter → role statement → hard rules → core content → workflow → checklist
5. **Split heavy content** — move full examples, templates, matrices to `reference.md`. Add `§` references
6. **Compress** — review every line. Delete anything that doesn't change agent behavior. Run `wc -l`
7. **Validate** — run `scripts/validate-frontmatter.sh` and `scripts/check-line-budget.sh`

## Quality Checklist

- [ ] Frontmatter complete — `name`, `description`, `allowed-tools` present
- [ ] `name` matches directory name (kebab-case)
- [ ] Role statement is 1–2 lines
- [ ] Hard rules use WRONG/CORRECT pairs (2–4 lines each)
- [ ] No content duplicated from other skills — uses `§` references
- [ ] Tables used instead of prose where possible
- [ ] One code example per pattern — no variant repetition
- [ ] Code examples show only relevant lines (no boilerplate)
- [ ] Core skills use language-agnostic examples; stack skills use language-specific
- [ ] Workflow has 3–7 numbered steps
- [ ] Checklist covers all deliverables
- [ ] SKILL.md under 300 lines (or justified if over)
- [ ] Heavy content moved to `reference.md` with `§` references
- [ ] `wc -l` verified before committing
- [ ] CI validation passes: `scripts/validate-frontmatter.sh`, `scripts/check-line-budget.sh`
