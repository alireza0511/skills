# Copilot Skills

Enterprise GitHub Copilot skills repository. Provides standardized SKILL.md and REFERENCE.md files that teams install into their repos to guide AI-assisted development.

## Repository Structure

```
.
├── skills/                          # All skill definitions
│   ├── frontend/                    # Frontend skills (Flutter, React)
│   │   ├── accessibility/           # Accessibility audit & remediation
│   │   │   ├── CONTRACT.md
│   │   │   ├── flutter/  (SKILL.md + REFERENCE.md)
│   │   │   └── react/    (SKILL.md + REFERENCE.md)
│   │   └── code-review/             # Code review standards
│   │       ├── CONTRACT.md
│   │       ├── flutter/  (SKILL.md + REFERENCE.md)
│   │       └── react/    (SKILL.md + REFERENCE.md)
│   ├── backend/                     # Backend skills (placeholder)
│   │   ├── SKILL.md
│   │   └── REFERENCE.md
│   ├── skill-development/           # Meta-skill: how to author skills
│   │   ├── SKILL.md
│   │   └── REFERENCE.md
│   └── CONTRACT.template.md         # Template for new skill contracts
├── agents/                          # Agent definitions
│   └── AGENT.template.md            # Template for new agents
├── scripts/                         # CI validation scripts
├── docs/                            # Guides and documentation
│   ├── jenkinsfile-integration.md   # How to integrate with Jenkins CI/CD
│   └── update-skills.md             # How to update skills in your repo
├── install.sh                       # Install skills into a target repo
├── manifest.json                    # Package metadata
├── CONTRIBUTING.md                  # Contribution guidelines
├── CODEOWNERS                       # Federated ownership
└── CHANGELOG.md                     # Version history
```

## Quick Start

### Option 1: Shell script (recommended)

Run the update script to pull the latest skills into your repo:

```bash
curl -fsSL https://raw.githubusercontent.com/alireza0511/skills/main/scripts/update-skills.sh | bash -s -- --target .
```

Or clone and run locally:

```bash
git clone https://github.com/alireza0511/skills.git /tmp/copilot-skills
/tmp/copilot-skills/scripts/update-skills.sh --target /path/to/your/repo
```

### Option 2: Install script

```bash
./install.sh --target /path/to/your/repo
```

### Option 3: Jenkins CI/CD

Add a stage to your Jenkinsfile to automatically pull the latest skills on each build. See [docs/jenkinsfile-integration.md](docs/jenkinsfile-integration.md) for details.

## How Skills Work

Each skill consists of two files:

| File | Purpose | Loaded |
|------|---------|--------|
| `SKILL.md` | Rules, workflow, checklist — guides the AI | Always (into context) |
| `REFERENCE.md` | Code examples, patterns, templates | On demand (when needed) |

Multi-platform skills also have a `CONTRACT.md` that defines the shared rules across platforms.

## Available Skills

| Skill | Platforms | Description |
|-------|----------|-------------|
| `frontend/accessibility` | Flutter, React | Audit and fix accessibility issues against WCAG 2.1 AA |
| `frontend/code-review` | Flutter, React | PR conventions, conventional commits, branch strategy |
| `backend` | (placeholder) | Backend development skills — to be developed |
| `skill-development` | — | Meta-skill: standards for authoring new skills |

## Keeping Skills Up to Date

See [docs/update-skills.md](docs/update-skills.md) for full instructions on:
- Manual updates via the shell script
- Automated updates via Jenkins pipeline
- Verifying installed skill versions

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the ownership model, PR workflow, and authoring guidelines.

## License

See [LICENSE](LICENSE).
