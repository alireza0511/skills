# PRD: Enterprise Copilot Skills & Agents Plugin

## National Bank — AI-Assisted Development Standards Platform

**Version:** 0.1.0-draft
**Date:** 2026-03-27
**Status:** Draft — Awaiting Stakeholder Review

---

## 1. Problem Statement

Development teams across the bank use different languages and frameworks (Flutter/Dart, React/TypeScript, Java/Spring, Python, Swift, Go, etc.) but must adhere to shared organizational standards for security, accessibility, architecture, and compliance. Today this knowledge lives in scattered Confluence pages, tribal knowledge, and inconsistently applied PR review checklists.

When developers use GitHub Copilot, the AI has no awareness of the bank's internal standards, leading to:

- Generated code that violates security policies (e.g., improper secret handling)
- Inconsistent architectural patterns across teams
- Repeated review cycles catching the same standard violations
- New developers ramping up slowly without embedded institutional knowledge

## 2. Vision

A **centralized, language-aware skills and agents library** distributed via JFrog Artifactory that any team in the bank can install into their repositories. When a developer uses GitHub Copilot (in VS Code, JetBrains, GitHub.com, or CLI), the AI automatically loads the bank's standards and best practices relevant to their current task and tech stack.

**One org-wide standard. Language-specific guidance. Zero manual lookup.**

## 3. Target Users

| Persona | Need |
|---|---|
| **Application Developer** | Get Copilot suggestions aligned with bank standards for their stack |
| **Tech Lead / Architect** | Author and publish skills for their team's stack |
| **Platform Engineering** | Maintain core (cross-cutting) skills, manage distribution pipeline |
| **Security / Compliance** | Ensure security and compliance skills are enforced across all teams |
| **Engineering Manager** | Visibility into which teams have adopted which skills |

## 4. GitHub Copilot Integration Model

### 4.1 Three Extension Mechanisms

This plugin leverages **three complementary** GitHub Copilot customization layers:

#### A. Custom Instructions (Organization-Level)

- Configured via **GitHub org settings** (Copilot → Custom Instructions)
- Applies to **all repos** in the org automatically
- Used for: universal bank-wide rules (e.g., "never hardcode secrets", "all APIs must use OAuth 2.0")
- **No code distribution needed** — configured in GitHub admin UI

#### B. Agent Skills (Repository-Level)

- Stored in `.github/skills/<skill-name>/SKILL.md`
- Each skill = a folder with a `SKILL.md` (YAML frontmatter + markdown instructions)
- Copilot **auto-loads relevant skills** based on the developer's prompt
- Used for: detailed, context-specific guidance (testing patterns, accessibility, architecture)
- **This is the primary distribution unit of this plugin**

#### C. Custom Agents (Organization-Level via `.github-private`)

- Stored in `.github-private/agents/<agent-name>.agent.md`
- Available across **all repos** in the org without per-repo setup
- Used for: specialized workflows (security review agent, architecture review agent)
- Can reference MCP servers and restrict tool access

### 4.2 Skill Loading Behavior

```
Developer prompt → Copilot evaluates skill descriptions →
  Matches relevant skills → Injects SKILL.md into context →
    AI responds with bank-standard-aware guidance
```

Skills are **not always-on**. Copilot selects them based on relevance to the current prompt, using the `description` field in YAML frontmatter.

## 5. Skill Architecture

### 5.1 Two-Tier Structure: Core + Language-Specific

Each topic area has a **core skill** (language-agnostic principles) and **language-specific sub-skills** (implementation guidance per stack).

```
.github/skills/
├── accessibility/
│   ├── SKILL.md                    # Core: WCAG 2.1 AA principles, bank a11y policy (lean)
│   └── reference.md                # Detailed guidelines, examples, checklists
├── accessibility-flutter/
│   ├── SKILL.md                    # Flutter: brief rules + pointers to reference
│   └── reference.md                # Full examples: Semantics, screen reader, testing
├── accessibility-react/
│   ├── SKILL.md                    # React: brief rules + pointers to reference
│   └── reference.md                # Full examples: aria-*, react-axe, keyboard nav
├── accessibility-ios/
│   ├── SKILL.md                    # iOS/Swift: brief rules + pointers to reference
│   └── reference.md                # Full examples: VoiceOver, Dynamic Type
│
├── security/
│   ├── SKILL.md                    # Core: OWASP Top 10, bank security policy (lean)
│   └── reference.md                # Detailed threat models, code patterns, checklists
├── security-java/
│   ├── SKILL.md                    # Java/Spring: brief rules
│   └── reference.md                # Full examples: Spring Security, CSRF, SQL injection
├── security-react/
│   ├── SKILL.md                    # React: brief rules
│   └── reference.md                # Full examples: XSS prevention, CSP, auth patterns
├── security-flutter/
│   ├── SKILL.md                    # Flutter: brief rules
│   └── reference.md                # Full examples: flutter_secure_storage, cert pinning
│
├── testing/
│   ├── SKILL.md                    # Core: coverage policy, test pyramid (lean)
│   └── reference.md                # Detailed patterns, naming, directory structure
├── testing-java/
│   ├── SKILL.md                    # Java: brief rules
│   └── reference.md                # Full examples: JUnit 5, Mockito, Testcontainers
├── testing-flutter/
│   ├── SKILL.md                    # Flutter: brief rules
│   └── reference.md                # Full examples: widget tests, golden tests, mocktail
├── testing-react/
│   ├── SKILL.md                    # React: brief rules
│   └── reference.md                # Full examples: RTL, MSW, Vitest
│
├── ... (same pattern for all topics)
```

### 5.2 Two-File Pattern: SKILL.md + reference.md

Each skill folder contains **two files** with distinct roles:

| File | Loaded by Copilot | Purpose | Target Size |
|---|---|---|---|
| `SKILL.md` | **Automatically** (injected into context when relevant) | Concise rules, principles, do/don't — just enough for Copilot to generate correct code | **< 300 lines** (ideal < 150) |
| `reference.md` | **On-demand** (Copilot reads it via `read` tool only when deeper detail is needed) | Full code examples, detailed explanations, checklists, migration guides | **Unlimited** (not injected by default) |

#### Why This Matters

When Copilot loads a skill, the entire `SKILL.md` is injected into the LLM's context window. Every token counts:
- A bloated `SKILL.md` with full code examples wastes context tokens on every prompt — even when the developer only needs a quick answer
- Multiple skills may load simultaneously (e.g., `security` + `security-java` + `testing-java`), compounding the token cost
- Keeping `SKILL.md` lean means **more room for the developer's actual code** in the context window

The `reference.md` file sits alongside `SKILL.md` in the same folder. Copilot's agent can **read it on demand** when the developer asks for detailed examples, migration steps, or full implementation patterns — but it doesn't consume tokens by default.

#### SKILL.md Frontmatter Schema

```yaml
---
name: kebab-case-name                    # Required. Must match directory name.
description: >                           # Required. One sentence — used for skill
  Bank security standards for            # discovery. Write for search: include key
  Java/Spring applications.              # terms a user would type to find this skill.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash  # Required. Only tools the skill needs.
argument-hint: "[what user passes] — e.g. 'service name', 'file path'"  # Optional.
---
```

| Field | Required | Purpose |
|---|---|---|
| `name` | Yes | Kebab-case identifier, must match directory name |
| `description` | Yes | Search-optimized one-liner — Copilot uses this to decide when to load the skill |
| `allowed-tools` | Yes | Restrict tool access to only what the skill needs (principle of least privilege) |
| `argument-hint` | No | Shows the developer what to pass when invoking the skill |

#### SKILL.md Required Structure

Every SKILL.md must follow this section order:

1. **Frontmatter** — name, description, allowed-tools, argument-hint
2. **Role Statement** (1–2 lines) — "You are a [role] for [context]. When invoked, [action]."
3. **Hard Rules** — Non-negotiable constraints with WRONG/CORRECT code pairs (2–4 lines each)
4. **Core Content** — Domain-specific guidance using tables over prose
5. **Workflow** (3–7 steps) — Numbered steps the agent follows when invoked
6. **Checklist** — Markdown checkbox list of deliverables

#### SKILL.md Example (Lean — Always Loaded)

```yaml
---
name: security-java
description: Bank security standards for Java/Spring — authentication, authorization, input validation, cryptography, sensitive data handling
allowed-tools: Read, Edit, Grep, Bash
argument-hint: "[service name] — e.g. 'payment-service', 'auth-gateway'"
---

# Security — Java / Spring Boot

You are a security expert for the bank's Java/Spring services. When invoked, audit and fix security issues against bank policy.

## Hard Rules

### Never hardcode secrets

` ``java
// WRONG
private static final String API_KEY = "sk-live-abc123";
// CORRECT — read from Vault at runtime
@Value("${vault.api-key}") private String apiKey;
` ``

### Always use parameterized queries

` ``java
// WRONG — SQL injection
String sql = "SELECT * FROM accounts WHERE id = " + userId;
// CORRECT
@Query("SELECT a FROM Account a WHERE a.id = :id")
Account findById(@Param("id") Long id);
` ``

## Core Standards

| Area | Rule |
|---|---|
| AuthN | All services use bank's OAuth 2.0 / OIDC provider |
| AuthZ | `@PreAuthorize` for method-level (not `@Secured`) |
| Passwords | `BCryptPasswordEncoder` strength ≥ 12 |
| CSRF | Enabled for all stateful endpoints |
| TLS | 1.2+ required for all service-to-service |
| Logging | Security events → audit trail (see observability skill) |

## Workflow

1. Identify service and its security surface (APIs, data stores, external calls)
2. Audit against Core Standards table
3. Fix violations, applying Hard Rules
4. Verify with checklist

## Checklist

- [ ] OAuth 2.0 resource server configured
- [ ] No hardcoded secrets (grep for patterns)
- [ ] Parameterized queries on all DB access
- [ ] CSRF enabled
- [ ] Input validation on all endpoints
- [ ] TLS 1.2+ verified

For full code examples, implementation patterns, and migration guides,
read `skills/security-java/reference.md` § Authentication Setup.
```

#### reference.md Format (Verbose — Loaded On-Demand)

**No frontmatter required.** Use clear `##` section headings so `SKILL.md` can point to specific sections using the `§` notation.

**Convention:** In SKILL.md, reference specific sections like this:
```markdown
For full code examples, read `skills/<name>/reference.md` § Section Name.
```

The agent reads **only the referenced section** from reference.md — not the entire file.

```markdown
# Security — Java / Spring Boot: Reference

## Authentication Setup

### OAuth 2.0 Resource Server Configuration

` ``java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(bankJwtConverter()))
            );
        return http.build();
    }
}
` ``

### Why This Pattern
[Detailed explanation of the bank's OAuth provider integration...]

## Input Validation

### Controller-Level Validation Example
[Full code with Jakarta Validation, custom validators for IBAN, amount ranges...]

## Migration Guide: Legacy Auth → OAuth 2.0
[Step-by-step with before/after examples...]

## Security Checklist
[Extended checklist with pen-test scheduling, SAST/DAST integration...]
```

#### How Copilot Uses the Two Files

```
Developer: "Add authentication to this Spring controller"

  1. Copilot matches prompt → loads security-java/SKILL.md (~150 lines)
  2. SKILL.md gives Copilot the hard rules + core standards table
  3. Copilot generates code following the rules ✓
  4. reference.md NOT loaded — rules were sufficient

Developer: "Show me the full security config setup with examples"

  1. SKILL.md is already loaded (rules in context)
  2. SKILL.md says: "read reference.md § Authentication Setup"
  3. Copilot reads ONLY that section from reference.md
  4. Copilot provides detailed implementation with bank-specific patterns ✓
```

### 5.3 Compression Rules for SKILL.md

Every line in SKILL.md costs tokens on every invocation. Authors must follow these rules to minimize token usage:

| Rule | Instead of | Do |
|---|---|---|
| **Tables over prose** | 6 lines of paragraph explaining mappings | 4-line table with columns |
| **One example per pattern** | Repeating WRONG/CORRECT for every variant | One pair, then a table for variants |
| **Reference, don't duplicate** | Copying content from another skill | `See skills/<name>/SKILL.md § Section` |
| **Minimal code examples** | Full widget/class file (30+ lines) | Only the 3–5 lines that illustrate the point |
| **No Flutter/Java/React basics** | Explaining what a widget or annotation does | State project-specific constraint only |
| **Imperative voice** | "The user should consider using..." | "Use X" or "Always X" |
| **Delete filler** | "It is important to note that..." | Just state the fact |

#### Line Budget

| Rating | Lines | When appropriate |
|---|---|---|
| Ideal | < 150 | Focused, single-concern skills |
| Acceptable | 150–300 | Multi-concern skills with examples |
| Needs justification | 300–500 | Complex domains (e.g., accessibility with platform matrix) |
| Too large | > 500 | Must split into multiple skills or move content to reference.md |

**Measure before committing:** `wc -l skills/<name>/SKILL.md`

### 5.4 Skill Topic Areas

| # | Topic | Core Skill | Language Sub-Skills |
|---|---|---|---|
| 1 | **Security** | OWASP, bank security policy, secret management | Java, Flutter, React, iOS, Python, Go |
| 2 | **Accessibility** | WCAG 2.1 AA, bank a11y policy | Flutter, React, iOS, Android |
| 3 | **Testing** | Test pyramid, coverage thresholds, naming | Java, Flutter, React, iOS, Python, Go |
| 4 | **Architecture** | Layered architecture, DDD principles | Java/Spring, Flutter/Bloc, React/Next.js |
| 5 | **API Design** | REST conventions, error format, versioning | Java/Spring, Python/FastAPI, Go |
| 6 | **Observability** | Logging, metrics, tracing standards | Java, Python, Go, React (frontend telemetry) |
| 7 | **CI/CD** | Pipeline standards, deployment gates | GitHub Actions, Gradle, Fastlane |
| 8 | **Code Review** | PR conventions, commit messages, branch strategy | Language-agnostic (one skill) |
| 9 | **Internationalization** | i18n/l10n policy, RTL support | Flutter, React, iOS |
| 10 | **License Compliance** | Approved/banned license list, audit process | Gradle, npm, pub, pip |
| 11 | **Documentation** | ADR templates, API docs, runbook standards | OpenAPI/Swagger, Dart doc, JSDoc |
| 12 | **Project Scaffolding** | Repository structure, bootstrap checklist | Java/Spring Initializr, Flutter, React/Next.js |
| 13 | **Error Handling** | Error taxonomy, user-facing messages, retry policy | Java, Flutter, React, Go |
| 14 | **Data Privacy** | PII handling, data classification, GDPR/local regs | Cross-cutting + DB-specific (SQL, NoSQL) |
| 15 | **Skill Development** | Meta-skill: how to author SKILL.md + reference.md files | Language-agnostic (one skill) |

### 5.5 Custom Agents (Organization-Wide)

Stored in `.github-private/agents/`:

| Agent | Purpose | Tools |
|---|---|---|
| `security-reviewer.agent.md` | Reviews code for security violations against bank policy | `read`, `search` |
| `architecture-reviewer.agent.md` | Validates architectural patterns and layer boundaries | `read`, `search` |
| `compliance-checker.agent.md` | Checks license compliance and data privacy patterns | `read`, `search` |
| `onboarding-guide.agent.md` | Helps new developers understand repo structure and conventions | `read`, `search` |

## 6. Distribution & Installation

### 6.1 Package Structure

The skills are packaged as a **versioned artifact** in JFrog Artifactory:

```
bank-copilot-skills-<version>.tar.gz
│
├── core/                           # Cross-cutting skills (every team installs)
│   ├── security/
│   │   ├── SKILL.md                # Lean rules (~2K tokens)
│   │   └── reference.md            # Full examples, checklists
│   ├── accessibility/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── testing/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── code-review/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── license-compliance/
│   │   ├── SKILL.md
│   │   └── reference.md
│   └── data-privacy/
│       ├── SKILL.md
│       └── reference.md
│
├── stacks/                         # Language-specific skill packs
│   ├── java/
│   │   ├── security-java/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   ├── testing-java/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   ├── architecture-java/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   └── ...
│   ├── flutter/
│   │   ├── security-flutter/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   ├── testing-flutter/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   ├── accessibility-flutter/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   └── ...
│   ├── react/
│   │   ├── security-react/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   ├── testing-react/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   ├── accessibility-react/
│   │   │   ├── SKILL.md
│   │   │   └── reference.md
│   │   └── ...
│   └── ... (ios, python, go)
│
├── agents/                         # Custom agents for .github-private
│   ├── security-reviewer.agent.md
│   ├── architecture-reviewer.agent.md
│   └── ...
│
├── install.sh                      # Installer script
└── manifest.json                   # Package metadata, version, checksums
```

### 6.2 Installation Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                      JFrog Artifactory                           │
│  bank-copilot-skills (generic repo)                              │
│  ├── bank-copilot-skills-1.0.0.tar.gz                           │
│  ├── bank-copilot-skills-1.1.0.tar.gz                           │
│  └── ...                                                         │
└──────────────┬───────────────────────────────────────────────────┘
               │
               │  Team downloads / CI pulls
               ▼
┌──────────────────────────────────────────────────────────────────┐
│  ./install.sh --stacks java,react --target ./my-repo             │
│                                                                   │
│  1. Copies core/* → .github/skills/                              │
│  2. Copies stacks/java/* → .github/skills/                       │
│  3. Copies stacks/react/* → .github/skills/                      │
│  4. Validates SKILL.md frontmatter (name, description, allowed-tools) │
│  5. Validates reference.md exists for each skill                  │
│  6. Warns if any SKILL.md exceeds 300 lines                      │
│  7. Generates .github/skills/MANIFEST.md (installed version)     │
└──────────────────────────────────────────────────────────────────┘
```

### 6.3 Update Mechanism

| Method | Description |
|---|---|
| **Manual** | Team runs `install.sh --update` to pull latest from Artifactory |
| **CI-Automated** | A scheduled GitHub Action checks Artifactory for new versions, opens a PR to update skills |
| **Renovate/Dependabot-style** | Custom Renovate datasource pointing at Artifactory generic repo |

### 6.4 Organization Agents Distribution

Custom agents in the `agents/` folder are installed **once** into the bank's `.github-private` repository by the Platform Engineering team. They are then available across all repos in the GitHub org automatically — no per-repo action needed.

## 7. Governance & Ownership

### 7.1 Federated Ownership Model

```
┌─────────────────────────────────────────────────────┐
│              Platform Engineering                     │
│  Owns: core skills, agents, distribution pipeline    │
│  Reviews: all PRs to the skills repo                 │
└──────────┬──────────────────────────┬────────────────┘
           │                          │
    ┌──────▼──────┐           ┌──────▼──────┐
    │  Mobile Team │           │ Backend Team │    ...
    │  Owns:       │           │  Owns:       │
    │  - flutter/* │           │  - java/*    │
    │  - ios/*     │           │  - python/*  │
    │  - android/* │           │  - go/*      │
    └─────────────┘           └─────────────┘
```

### 7.2 Contribution Workflow

1. Team authors/updates a skill in a **feature branch** of the central skills repo
2. Opens a **PR** with:
   - `SKILL.md` changes
   - Justification (link to ADR, policy doc, or incident)
3. **Required reviewers:**
   - Platform Engineering (structural/format review)
   - Domain owner (content review — e.g., Security team for security skills)
4. Automated CI checks:
   - YAML frontmatter schema validation (`name`, `description`, `allowed-tools` required)
   - `name` matches directory name (kebab-case)
   - Markdown lint
   - **Line budget check:** `wc -l SKILL.md` must be < 300 (warn at 150+)
   - **Required structure check:** frontmatter → role statement → hard rules → core content → workflow → checklist
   - **reference.md existence check** (every skill must have one)
   - **Code block size check:** SKILL.md code blocks must be ≤ 10 lines (longer examples belong in reference.md)
   - **No duplication check:** SKILL.md must not contain content that exists verbatim in another skill (use `§` references)
   - No secrets or PII in skill content
5. Merge → automated publish to Artifactory

### 7.3 Versioning

- **Semantic versioning** (major.minor.patch)
- **Major**: breaking changes (skill renamed/removed, structure change)
- **Minor**: new skills added, existing skills enhanced
- **Patch**: typo fixes, minor wording improvements
- Each release includes a `CHANGELOG.md`

## 8. Success Metrics

| Metric | Target | How to Measure |
|---|---|---|
| **Adoption** | 80% of active repos have skills installed within 6 months | Scan org repos for `.github/skills/MANIFEST.md` |
| **Freshness** | 90% of repos on latest minor version within 2 weeks of release | Compare MANIFEST.md version vs Artifactory latest |
| **PR Review Efficiency** | 30% reduction in standard-violation review comments | Sample PR review data before/after |
| **Security Findings** | 25% reduction in security-related findings in code review | SAST/DAST tool trend data |
| **Developer Satisfaction** | NPS > 40 for Copilot + skills experience | Quarterly survey |
| **Contribution Health** | Skills updated at least quarterly per stack | Git log on skills repo |

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Skills become stale / outdated | Developers ignore or disable them | Quarterly review cycle, ownership SLA, freshness dashboard |
| Too many skills slow down Copilot | Degraded developer experience | Copilot only loads relevant skills (description-based matching); keep descriptions precise |
| Conflicting guidance between core and language skills | Confusion | Core skills set principles, language skills set implementation — never contradict |
| Copilot ignores or misinterprets skills | Standards not enforced | Pair skills with CI linters/hooks as a safety net; skills guide, CI enforces |
| JFrog Artifactory downtime | Teams can't install/update | Cache last-known-good in `.github-private` as fallback |
| Sensitive internal info in skill content | Leakage via Copilot telemetry | Review policy with GitHub enterprise support; skills contain patterns, not secrets |

## 10. Phased Rollout

### Phase 1 — Foundation (Weeks 1–4)

- [ ] Set up central skills repository (`bank-copilot-skills`)
- [ ] Define SKILL.md schema and validation CI
- [ ] Author **core skills**: Security, Testing, Code Review
- [ ] Author **one stack** end-to-end as pilot (e.g., Java or Flutter)
- [ ] Set up JFrog Artifactory generic repo + publish pipeline
- [ ] Install on 2–3 pilot team repos
- [ ] Configure org-level custom instructions in GitHub admin

### Phase 2 — Expand (Weeks 5–8)

- [ ] Author remaining core skills (Accessibility, Architecture, Observability, etc.)
- [ ] Add 2–3 more language stacks based on team demand
- [ ] Create custom agents in `.github-private`
- [ ] Build `install.sh` with stack selection
- [ ] Build automated update GitHub Action
- [ ] Onboard 5–10 more teams

### Phase 3 — Scale (Weeks 9–12)

- [ ] All language stacks covered
- [ ] Renovate-style auto-update PRs
- [ ] Adoption dashboard (repo scan + version tracking)
- [ ] Quarterly review process formalized
- [ ] Contribution guide published, teams self-serve skill authoring
- [ ] Org-wide rollout announcement

### Phase 4 — Optimize (Ongoing)

- [ ] Feedback loop: developer survey → skill refinements
- [ ] Measure PR review efficiency improvements
- [ ] Explore MCP server integration for internal tools (Vault, SonarQube, internal scaffolders)
- [ ] Evaluate GitHub Copilot org-level skills when GA (eliminate per-repo install)

## 11. Open Questions

1. **Copilot telemetry & data residency**: Does GitHub Copilot Enterprise send skill content to external servers? Need confirmation from GitHub account team for compliance.
2. **Org-level skills GA timeline**: GitHub has announced org/enterprise-level skills are "coming soon." If available, this simplifies distribution significantly (no per-repo install). Should we wait or proceed with per-repo approach?
3. **Skill content language**: Should skills be authored in English only, or also in Farsi for teams that prefer it?
4. **Mandatory vs. optional skills**: Should core skills (Security, Data Privacy) be enforced via CI checks that verify they're installed, or remain advisory?
5. **MCP server integration**: Should Phase 1 include an MCP server for internal tooling (e.g., Vault secret lookup, SonarQube scan trigger)?

## 12. References

- [GitHub Copilot Agent Skills Docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Creating Agent Skills](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills)
- [Custom Agents](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-custom-agents)
- [Creating Custom Agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)
- [Org Custom Instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-organization-instructions)
- [Copilot Extensions — Skillsets (Enterprise Cloud)](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/use-copilot-extensions/build-copilot-skillsets)
- [awesome-copilot](https://github.com/github/awesome-copilot)
- [VGV Flutter Plugin (inspiration)](https://github.com/VeryGoodOpenSource/very_good_ai_flutter_plugin)
