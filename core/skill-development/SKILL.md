---
name: skill-development
description: Standards for writing SKILL.md, REFERENCE.md, and CONTRACT.md files — structure, token budget, compression rules, and quality guidelines for enterprise skill authoring
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
argument-hint: "[skill name] — e.g. 'security', 'testing', 'observability'"
---

# Skill Development Standards

You are a skill author for the bank's enterprise Copilot skills repository. When invoked, help create or improve SKILL.md and REFERENCE.md files that follow every rule in this document.

## Token Budget

Skills are loaded into the LLM context window on every invocation. Every line costs tokens. Write the minimum needed for correct behavior.

| Rating | Lines | When appropriate |
|--------|-------|------------------|
| Ideal | < 150 | Focused, single-concern skills |
| Acceptable | 150–300 | Multi-concern skills with examples |
| Needs justification | 300–500 | Complex domains (e.g., accessibility with platform matrix) |
| Too large | > 500 | Split into multiple skills or compress aggressively |

**Measure before committing:** `wc -l` on SKILL.md.

## Directory Structure

Skills use a platform-specific structure. Each platform gets its own SKILL.md and REFERENCE.md. A CONTRACT.md at the skill root defines the shared contract.

### Core skills (multi-platform)

```
core/<name>/
├── CONTRACT.md                  # Shared contract — identity, rules, standards
├── flutter/
│   ├── SKILL.md                 # Flutter-specific skill (loaded into context)
│   └── REFERENCE.md             # Flutter patterns + core reference content
└── react/
    ├── SKILL.md                 # React-specific skill (loaded into context)
    └── REFERENCE.md             # React patterns + core reference content
```

### Stack skills (single platform)

```
stacks/<lang>/<name>/
├── SKILL.md                     # Loaded into context
└── REFERENCE.md                 # Loaded on demand
```

### SKILL.md (always loaded into context)

- Frontmatter, role statement, hard rules
- Core decision logic (tables, mappings, short examples)
- Workflow steps and checklist
- **Budget: < 300 lines**

### REFERENCE.md (loaded on demand)

- Full code examples (complete classes, test suites, configs)
- Audit/report templates
- Extended mapping tables
- Platform-specific checklists
- Core reference content (WCAG checklist, commit format, etc.) merged in
- Migration guides and walkthroughs

### How SKILL.md references it

```markdown
For full code examples, read `core/<name>/flutter/REFERENCE.md` § Section Name.
```

The agent reads REFERENCE.md only when it needs that section — not on every invocation.

### REFERENCE.md format

No frontmatter. Use clear `##` section headings so SKILL.md can point to specific sections with `§`.

```markdown
# <Skill Name> — <Platform> Reference

## Section Name
[detailed content]

## Another Section
[detailed content]

---

# Core <Skill Name> Reference

## Shared Section
[core content merged into each platform REFERENCE.md]
```

### CONTRACT.md

A lightweight markdown file where the skill author defines the shared contract across all platforms. The template is at `core/CONTRACT.template.md`.

A contract contains:
- **Identity** — name, one-liner, platforms, target type
- **Questions to ask** — what the LLM must collect from the user before starting
- **Hard rules** — one bullet per rule, plain English, no code
- **Standards** — policies and thresholds
- **Platform-specific notes** — brief notes per platform
- **Workflow** — steps the LLM follows
- **Checklist** — definition of done
- **Reference sections needed** — what to include in each platform's REFERENCE.md

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
| `name` | Yes | Kebab-case, must match directory path context |
| `description` | Yes | Search-optimized — include key terms users would type |
| `allowed-tools` | Yes | Only tools the skill needs. Don't grant tools it doesn't use |
| `argument-hint` | No | Format + 1–2 examples. Omit if skill takes no arguments |

### 2. Role Statement (1–2 lines)

```markdown
You are a [role] for [context]. When invoked, [what you do].
```

For **platform-specific core skills**:
```markdown
You are an accessibility expert for the bank's Flutter applications. When invoked, audit and fix accessibility issues against WCAG 2.1 AA and bank policy.
```

For **stack skills**:
```markdown
You are a security expert for the bank's Java/Spring services. When invoked, audit and fix Java-specific security issues against bank policy.
```

### 3. Step 0 — Collect Context (MANDATORY for multi-platform skills)

The SKILL.md must force the LLM to ask the contract's questions before doing any work:

```markdown
## Step 0 — Collect Context (MANDATORY)

Before any work, you MUST ask this question. Do not guess. Do not proceed until answered.

**Q1: Audit scope**
> "What should I audit: **full app**, **specific screen/page**, **specific component**, or **PR/diff changes only**?"

### After Answer — Load Reference

Read this file before proceeding:
- `core/<name>/<platform>/REFERENCE.md`
```

### 4. Hard Rules

Non-negotiable constraints. Each rule:
- One sentence stating the rule
- One WRONG/CORRECT code pair (2–4 lines each)

Do NOT duplicate rules from another skill. Reference instead:

```markdown
> All security rules from `core/security/flutter/SKILL.md` § Hard Rules apply here.
```

### 5. Core Content

Domain-specific guidance. Structure varies by skill but must follow compression rules below.

### 6. Workflow (3–7 steps)

Numbered steps the agent follows when invoked.

### 7. Checklist

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
See `core/testing/flutter/SKILL.md` § Checklist for the test coverage policy.
```

Never copy-paste sections between skills.

### Code examples: minimal and annotated

- Show only lines that illustrate the point — not full files
- Use inline comments, not paragraphs above/below
- Max **one** WRONG/CORRECT pair per rule
- Omit imports, boilerplate, and obvious setup

### Core reference content merged into platform REFERENCE.md

Shared content (WCAG checklist, commit format, branch strategy, etc.) is merged directly into each platform's REFERENCE.md — not kept in a separate shared file. This ensures each platform REFERENCE.md is self-contained.

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
| Shared reference.md at skill root | Merge core content into each platform's REFERENCE.md |
| Lowercase reference.md | Use REFERENCE.md (uppercase) |

## Workflow — Generating a Skill from a Contract

### Generation Steps

When given a CONTRACT.md (e.g., `generate from core/accessibility/CONTRACT.md`):

1. **Read the contract** — load the CONTRACT.md file
2. **Create directories** — `core/<name>/flutter/` and `core/<name>/react/` (or whichever platforms are listed)
3. **Generate platform SKILL.md files** from the contract:
   - Build frontmatter with platform-specific name (e.g., `accessibility-flutter`)
   - Write role statement scoped to the platform
   - Convert "Questions to ask" into a mandatory Step 0 gate
   - Convert hard rules into numbered rules with platform-specific code examples
   - Convert standards into a Core Standards table
   - Add platform-specific constraints
   - Convert workflow into numbered steps referencing the platform's REFERENCE.md
   - Convert checklist into markdown checkboxes
   - Add section navigation table mapping needs to REFERENCE.md headings
   - Keep under 300 lines
4. **Generate platform REFERENCE.md files** — for each platform:
   - Platform-specific content: WRONG/CORRECT code examples, API mappings, testing patterns, audit templates
   - Core reference content merged in: shared standards, checklists, patterns that apply to all platforms
   - Each REFERENCE.md must be self-contained
5. **Validate** — run `wc -l` on each SKILL.md, verify < 300 lines
6. **Summary** — list all files created and their line counts

### Key Rules for Generation

- **Each platform gets its own SKILL.md and REFERENCE.md.** No shared SKILL.md or REFERENCE.md at the skill root.
- **CONTRACT.md stays at the skill root** as the shared contract definition.
- **SKILL.md must force the LLM to ask the contract's questions** before doing any work (Step 0 gate).
- **Platform REFERENCE.md files must have consistent section headings** so SKILL.md can route to them by name.
- **Core reference content is merged into each platform's REFERENCE.md** — not kept as a separate file.
- **Every hard rule in the contract becomes a numbered rule** in each platform's SKILL.md with platform-appropriate code examples.

## Workflow — Creating a Skill Manually (Without Contract)

1. **Identify scope** — one skill = one concern. Two unrelated domains -> split
2. **Check overlap** — read existing skills. Reference shared content, don't duplicate
3. **Determine platforms** — create a subdirectory per platform under `core/<name>/`
4. **Write CONTRACT.md** — define shared identity, rules, standards at skill root
5. **Write platform SKILL.md files** — frontmatter, role, Step 0, hard rules, core content, workflow, checklist
6. **Write platform REFERENCE.md files** — full examples, templates, core reference merged in
7. **Compress** — review every line. Delete anything that doesn't change agent behavior. Run `wc -l`
8. **Validate** — run `scripts/validate-frontmatter.sh` and `scripts/check-line-budget.sh`

## Quality Checklist

### Contract-based skills
- [ ] CONTRACT.md exists at the skill root
- [ ] All Identity fields filled (name, one-liner, platforms, target type)
- [ ] Each platform listed in the contract has its own `<platform>/SKILL.md` and `<platform>/REFERENCE.md`
- [ ] No SKILL.md or REFERENCE.md at the skill root (only CONTRACT.md)
- [ ] Each SKILL.md has a Step 0 gate that forces the LLM to ask contract questions
- [ ] Platform REFERENCE.md files have consistent section headings matching SKILL.md navigation table
- [ ] Core reference content merged into each platform REFERENCE.md (no shared reference file)

### All skills
- [ ] Frontmatter complete — `name`, `description`, `allowed-tools` present
- [ ] Role statement is 1–2 lines
- [ ] No content duplicated from other skills — uses `§` references
- [ ] Tables used instead of prose where possible
- [ ] Code examples only as WRONG/CORRECT pairs (2–4 lines each)
- [ ] Workflow has 3–7 numbered steps
- [ ] Checklist covers all deliverables
- [ ] SKILL.md under 300 lines (or justified if over)
- [ ] Heavy content moved to REFERENCE.md with `§` references
- [ ] `wc -l` verified before committing
- [ ] CI validation passes: `scripts/validate-frontmatter.sh`, `scripts/check-line-budget.sh`
