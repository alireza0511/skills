# Updating Skills in Your Repository

This guide explains how to pull the latest SKILL.md and REFERENCE.md files from the central skills repository into your project.

## Prerequisites

- `git` and `bash` available on your system
- Write access to your target repository

## Option 1: Run the Update Script

The fastest way to update. The script clones the latest skills and copies them into your repo.

```bash
# From your project root
curl -fsSL https://raw.githubusercontent.com/alireza0511/skills/main/scripts/update-skills.sh | bash -s -- --target .
```

Or if you have the skills repo cloned locally:

```bash
/path/to/skills/scripts/update-skills.sh --target /path/to/your/repo
```

### What the script does

1. Clones (or pulls) the latest `main` branch from `https://github.com/alireza0511/skills.git`
2. Copies `skills/` directory into your repo at `.github/skills/`
3. Records the installed version and commit SHA in `.github/skills/MANIFEST.md`
4. Cleans up the temporary clone

### Script options

| Flag | Description | Default |
|------|-------------|---------|
| `--target <path>` | Target repository path | `.` (current directory) |
| `--branch <name>` | Branch to pull from | `main` |
| `--dest <path>` | Destination within target repo | `.github/skills` |
| `-h`, `--help` | Show help | — |

## Option 2: Jenkins CI/CD Integration

See [jenkinsfile-integration.md](jenkinsfile-integration.md) for adding an automatic update stage to your Jenkins pipeline.

## Option 3: Manual Update

```bash
# Clone the skills repo
git clone https://github.com/alireza0511/skills.git /tmp/copilot-skills

# Copy skills into your repo
cp -R /tmp/copilot-skills/skills/* /path/to/your/repo/.github/skills/

# Clean up
rm -rf /tmp/copilot-skills
```

## Verifying the Installed Version

After updating, check `.github/skills/MANIFEST.md` in your repo:

```bash
cat .github/skills/MANIFEST.md
```

This shows the version, install date, and source commit SHA.

## Recommended Update Frequency

- **Manual projects**: Run the update script before each sprint or when notified of skill updates.
- **CI/CD projects**: Add the Jenkins stage so skills are updated automatically on each build or on a weekly schedule.
