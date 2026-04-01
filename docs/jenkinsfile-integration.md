# Jenkins CI/CD Integration

This guide explains how to add a stage to your Jenkinsfile that automatically pulls the latest Copilot skills into your repository.

## Quick Setup

Add the following stage to your `Jenkinsfile` (Declarative Pipeline):

```groovy
pipeline {
    agent any

    stages {
        stage('Update Copilot Skills') {
            steps {
                sh '''
                    # Clone the skills repo
                    SKILLS_REPO="https://github.com/alireza0511/skills.git"
                    SKILLS_DIR="${WORKSPACE}/.github/skills"
                    TEMP_DIR=$(mktemp -d)

                    git clone --depth 1 --branch main "${SKILLS_REPO}" "${TEMP_DIR}"

                    # Copy skills into the workspace
                    mkdir -p "${SKILLS_DIR}"
                    cp -R "${TEMP_DIR}/skills/"* "${SKILLS_DIR}/"

                    # Record version info
                    VERSION=$(jq -r '.version' "${TEMP_DIR}/manifest.json")
                    COMMIT=$(git -C "${TEMP_DIR}" rev-parse --short HEAD)
                    DATE=$(date +%Y-%m-%d)

                    cat > "${SKILLS_DIR}/MANIFEST.md" <<EOF
# Installed Copilot Skills

- **Version:** ${VERSION}
- **Commit:** ${COMMIT}
- **Installed on:** ${DATE}
- **Source:** https://github.com/alireza0511/skills

---
*Updated by Jenkins pipeline*
EOF

                    # Clean up
                    rm -rf "${TEMP_DIR}"

                    echo "Skills updated to version ${VERSION} (${COMMIT})"
                '''
            }
        }

        // ... your existing stages (build, test, deploy) ...
    }
}
```

## Scripted Pipeline

```groovy
node {
    stage('Update Copilot Skills') {
        sh '''
            curl -fsSL https://raw.githubusercontent.com/alireza0511/skills/main/scripts/update-skills.sh \
                | bash -s -- --target "${WORKSPACE}"
        '''
    }

    // ... your existing stages ...
}
```

## Using the Update Script Directly

If your Jenkins agents have internet access, the simplest approach is to call the update script:

```groovy
stage('Update Copilot Skills') {
    steps {
        sh 'curl -fsSL https://raw.githubusercontent.com/alireza0511/skills/main/scripts/update-skills.sh | bash -s -- --target .'
    }
}
```

## Scheduled Updates Only

If you don't want to update on every build, use a separate scheduled pipeline:

```groovy
pipeline {
    agent any

    triggers {
        // Update skills every Monday at 8:00 AM
        cron('0 8 * * 1')
    }

    stages {
        stage('Update Copilot Skills') {
            steps {
                sh 'curl -fsSL https://raw.githubusercontent.com/alireza0511/skills/main/scripts/update-skills.sh | bash -s -- --target .'
            }
        }

        stage('Commit Updated Skills') {
            steps {
                sh '''
                    git config user.name "Jenkins CI"
                    git config user.email "jenkins@example.com"
                    git add .github/skills/
                    git diff --cached --quiet || git commit -m "chore(skills): update copilot skills to latest"
                    git push origin HEAD
                '''
            }
        }
    }
}
```

## Private Repository / Authentication

If the skills repo requires authentication:

```groovy
stage('Update Copilot Skills') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'github-credentials',
            usernameVariable: 'GIT_USER',
            passwordVariable: 'GIT_TOKEN'
        )]) {
            sh '''
                SKILLS_REPO="https://${GIT_USER}:${GIT_TOKEN}@github.com/alireza0511/skills.git"
                TEMP_DIR=$(mktemp -d)
                git clone --depth 1 --branch main "${SKILLS_REPO}" "${TEMP_DIR}"
                mkdir -p .github/skills
                cp -R "${TEMP_DIR}/skills/"* .github/skills/
                rm -rf "${TEMP_DIR}"
            '''
        }
    }
}
```

## Verifying the Update

Add a verification step after the update:

```groovy
stage('Verify Skills') {
    steps {
        sh '''
            if [ -f .github/skills/MANIFEST.md ]; then
                echo "Skills manifest found:"
                cat .github/skills/MANIFEST.md
            else
                echo "WARNING: Skills manifest not found"
                exit 1
            fi
        '''
    }
}
```

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `git clone` fails | No network access from Jenkins agent | Pre-clone the repo on the agent or use Artifactory mirror |
| `jq` not found | Missing on Jenkins agent | Install `jq` or use `python3 -c "import json; ..."` instead |
| Permission denied on `.github/skills/` | Directory owned by different user | Run `chmod -R u+w .github/skills/` before copying |
| Skills not picked up by Copilot | Wrong destination path | Ensure skills are at `.github/skills/` in the repo root |
