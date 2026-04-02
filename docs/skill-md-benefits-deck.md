---
marp: true
theme: default
paginate: true
header: "SKILL.md — Structured Skills for LLM-Assisted Development"
footer: "Enterprise Copilot Skills"
---

# SKILL.md

### How Structured Skills Transform LLM-Assisted Development

---

# The Problem

### Without structured skills, every LLM interaction starts from zero

- Developers repeat the same instructions across prompts
- LLM output quality varies wildly between team members
- No enforcement of org standards (a11y, code review, security)
- Context window wasted on verbose, unstructured prompts
- Knowledge lives in people's heads, not in reusable artifacts

---

# What is SKILL.md?

A **structured, token-optimized file** that tells the LLM:

| Section | Purpose |
|---------|---------|
| **Frontmatter** | Identity, version, allowed tools |
| **Role Statement** | Who the LLM becomes when invoked |
| **Step 0 Gate** | What to ask the dev before starting |
| **Hard Rules** | Non-negotiable constraints with WRONG/CORRECT pairs |
| **Core Standards** | Tables of requirements (e.g., WCAG AA) |
| **Workflow** | Numbered steps the LLM follows |
| **Checklist** | Definition of done |

---

# Architecture

```
skills/<category>/<name>/
├── CONTRACT.md          ← Shared rules across platforms
├── flutter/
│   ├── SKILL.md         ← Loaded into LLM context (< 300 lines)
│   └── REFERENCE.md     ← Loaded on demand (heavy examples)
└── react/
    ├── SKILL.md
    └── REFERENCE.md
```

**SKILL.md** = always in context (small, decisive)
**REFERENCE.md** = loaded only when needed (detailed, examples)

---

# Impact on Token Usage

### Before: Unstructured prompts

```
"Hey can you check my Flutter code for accessibility?
Make sure it follows WCAG 2.1 AA, check contrast ratios,
make sure screen readers work, fix any issues you find,
also check keyboard navigation and touch targets..."
```

~500-2000 tokens per prompt, inconsistent, incomplete

### After: SKILL.md

- **131 lines** of SKILL.md = ~800 tokens, loaded once
- Covers **every** rule, **every** check, **every** time
- REFERENCE.md loaded on-demand = zero cost when not needed

---

# Token Budget Strategy

| Layer | When Loaded | Budget | Purpose |
|-------|-------------|--------|---------|
| SKILL.md | Every invocation | < 300 lines | Decisions & rules |
| REFERENCE.md | On demand | No hard limit | Full examples & templates |
| CONTRACT.md | Never by LLM | — | Author-facing shared spec |

### Compression rules keep SKILL.md lean:
- Tables over prose
- One WRONG/CORRECT pair per rule (2-4 lines each)
- Reference, never duplicate
- No imports, no boilerplate, no obvious setup

---

# Impact on LLM Output Quality

### Consistency

| Without SKILL.md | With SKILL.md |
|-------------------|---------------|
| Dev A gets different advice than Dev B | Same rules, same output |
| LLM forgets edge cases | Checklist enforces completeness |
| Quality depends on prompt skill | Quality depends on SKILL.md |

### Guardrails

- **Step 0 Gate** — LLM must ask scope before starting work
- **Hard Rules** — Non-negotiable constraints with code examples
- **Severity Classification** — CRITICAL > MAJOR > MINOR triage
- **Checklist** — LLM verifies its own work before finishing

---

# Impact on Developer Productivity

### Time saved per interaction

| Task | Without Skills | With Skills |
|------|---------------|-------------|
| Write the prompt | 5-10 min | 0 min (invoke skill) |
| Verify LLM followed standards | Manual review | Built-in checklist |
| Fix LLM mistakes | Re-prompt 2-3x | Rare — rules prevent mistakes |
| Onboard new dev to standards | Days of reading docs | Instant — skill encodes knowledge |

### Knowledge democratization

- Junior devs get **senior-level guidance** on every task
- Standards are **executable**, not just documented
- Cross-platform consistency: Flutter and React follow the same contract

---

# Real Example: Accessibility Audit

### What the developer types:
```
/accessibility login screen
```

### What happens:
1. SKILL.md loads (131 lines, ~800 tokens)
2. LLM asks: "Does this target Android, iOS, or both?"
3. Dev answers: "both"
4. LLM loads REFERENCE.md (333 lines, on demand)
5. Audits against 7 hard rules + WCAG AA checklist
6. Fixes by severity (CRITICAL first)
7. Generates structured audit report
8. Verifies 16-item checklist before finishing

**Result:** Consistent, thorough audit in minutes — not hours.

---

# Distribution & Versioning

### Skills are distributed like packages

```json
{
  "name": "copilot-skills",
  "version": "0.1.0",
  "distribution": {
    "registry": "jfrog-artifactory",
    "repository": "copilot-skills"
  }
}
```

- Every SKILL.md has a **version** in frontmatter
- Jenkins CI auto-updates skills — **skips if version unchanged**
- Teams get the latest standards without lifting a finger
- Rollback is a version pin away

---

# Governance & Quality

### Automated CI checks on every PR

| Check | What it validates |
|-------|-------------------|
| `validate-frontmatter.sh` | name, version, description, allowed-tools present |
| `check-line-budget.sh` | SKILL.md < 300 lines, warns at 150 |
| `check-structure.sh` | CONTRACT.md exists for multi-platform skills |
| `check-codeblock-size.sh` | Code examples stay minimal |

### Federated ownership via CODEOWNERS

- **Platform Engineering** — distribution, scripts, CI
- **Frontend Team** — accessibility, code-review (Flutter, React)
- **Backend Team** — backend skills

---

# Before vs After

| Dimension | Before | After |
|-----------|--------|-------|
| Standards enforcement | Hope devs read the wiki | LLM enforces on every interaction |
| Prompt quality | Varies by person | Codified and versioned |
| Token efficiency | Verbose, repeated instructions | Compressed, loaded once |
| Onboarding | Weeks to learn standards | Day 1 — skills carry the knowledge |
| Cross-team consistency | Drift over time | CONTRACT.md locks shared rules |
| Audit trail | "I think I checked that" | Structured report with file:line refs |
| Updates | Email "please update your prompts" | CI auto-distributes new versions |

---

# Key Takeaways

1. **SKILL.md is a token-efficient contract** between your org and the LLM
2. **REFERENCE.md splits the cost** — heavy content loads only when needed
3. **Consistency at scale** — every dev, every interaction, same standards
4. **Knowledge as code** — version, review, distribute, roll back
5. **Measurable quality** — CI validates structure, LLM validates output

---

# Getting Started

### Use an existing skill
```bash
./install.sh --target /path/to/your/repo
```

### Create a new skill
```
/skill-development security
```

### Automate updates
Add the Jenkins stage from `docs/jenkinsfile-integration.md`

---

# Questions?

### Resources
- Repository: `github.com/alireza0511/skills`
- Skill authoring guide: `skills/skill-development/SKILL.md`
- Jenkins integration: `docs/jenkinsfile-integration.md`
- Contributing: `CONTRIBUTING.md`
