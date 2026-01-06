# GitOps Runtime Release Guide

This guide explains how to perform releases for the GitOps Runtime Helm chart.

> **Tip**: There's a CLI that automates most of these steps:
> ```bash
> npx @codefresh-io/gitops-release --help
> ```
> See the [CLI repository](https://github.com/codefresh-io/gitops-release) for details.

The instructions below explain how to do everything manually if you prefer that approach, don't have an Anthropic API key for AI release notes, or need to troubleshoot.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Release Types](#release-types)
4. [Creating a New Minor Release](#creating-a-new-minor-release)
5. [Publishing a Release](#publishing-a-release)
6. [Creating a Patch Release](#creating-a-patch-release)
7. [Cherry-Picking Fixes](#cherry-picking-fixes)
8. [Writing Release Notes](#writing-release-notes)
9. [Troubleshooting](#troubleshooting)
10. [Reference](#reference)

---

## Overview

The GitOps Runtime release process uses **Argo Events and Workflows** to automate most of the work. Your job as release manager is to:

1. **Trigger pipelines** by creating branches or merging PRs
2. **Review and approve** the automatically created prepare-release PRs
3. **Write/edit release notes** (the AI can help, but human review is essential)
4. **Publish releases** by merging the prepare-release PR

### How It Works

```
You create stable/X.Y branch
        ↓
[Argo Workflow: prepare-release] runs automatically
        ↓
Creates prep/vX.Y.0 branch + PR + draft GitHub release
        ↓
You review, edit release notes, then merge the PR
        ↓
[Argo Workflow: promote] runs automatically
        ↓
Chart published to quay.io + GitHub release published
```

---

## Prerequisites

### Required Access

- **GitHub**: Write access to `codefresh-io/gitops-runtime-helm`
- **GitHub Token**: Personal access token with `repo` scope (for API operations)

### Tools

- `gh` CLI (GitHub CLI) - recommended for easier operations
- Git

### Install GitHub CLI

```bash
# macOS
brew install gh

# Login
gh auth login
```

---

## Release Types

| Type | When | Branch Created | Example |
|------|------|----------------|---------|
| **Minor Release** | New features, starting a release line | `stable/0.27` | 0.27.0 |
| **Patch Release** | Bug fixes to existing release | Already exists | 0.26.6 |

---

## Creating a New Minor Release

Use this when starting a new release line (e.g., 0.27.x).

### Step 1: Create the Stable Branch

**Option A: GitHub UI (easiest)**
1. Go to https://github.com/codefresh-io/gitops-runtime-helm
2. Click the branch dropdown
3. Type `stable/0.27` (replace with your version)
4. Click "Create branch: stable/0.27 from main"

**Option B: Git command line**
```bash
git fetch origin
git checkout main
git pull
git checkout -b stable/0.27
git push -u origin stable/0.27
```

**From a specific commit:**
```bash
git checkout -b stable/0.27 abc1234
git push -u origin stable/0.27
```

### Step 2: Wait for the Pipeline

The **prepare-release** pipeline will automatically:
- Create `prep/v0.27.0` branch
- Bump version in `Chart.yaml`
- Open a PR with the `prepare-release` label
- Create a draft GitHub release

This usually takes 2-5 minutes.

### Step 3: Verify

Check that everything was created:
```bash
# Check for the PR
gh pr list --repo codefresh-io/gitops-runtime-helm --head prep/v0.27.0

# Check for draft release
gh release list --repo codefresh-io/gitops-runtime-helm | head -5
```

Or visit:
- PRs: https://github.com/codefresh-io/gitops-runtime-helm/pulls
- Releases: https://github.com/codefresh-io/gitops-runtime-helm/releases

---

## Publishing a Release

### Step 1: Check PR Status

Before publishing, verify:

1. **CI checks are passing**
   ```bash
   gh pr checks <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm
   ```

2. **PR has the `prepare-release` label** (CRITICAL - this triggers the promote pipeline)
   ```bash
   gh pr view <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm --json labels
   ```

3. **Release notes are complete** (see [Writing Release Notes](#writing-release-notes))

### Step 2: Review the PR

1. Open the PR in GitHub
2. Review the changes (version bump, changelog)
3. Ensure release notes in the draft GitHub release are accurate

### Step 3: Merge the PR

```bash
# Merge the prepare-release PR
gh pr merge <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm --squash
```

Or click "Merge" in the GitHub UI.

### Step 4: Verify Publication

The **promote** pipeline will automatically:
- Publish the chart to `quay.io/codefresh/gitops-runtime`
- Convert the draft release to published
- Sign container images

Check the release:
```bash
gh release view 0.27.0 --repo codefresh-io/gitops-runtime-helm
```

---

## Creating a Patch Release

Patch releases (e.g., 0.26.6) happen when fixes are merged to an existing stable branch.

### Step 1: Merge Fixes to Stable Branch

Either:
- Merge PRs directly to `stable/0.26`
- Cherry-pick commits (see [Cherry-Picking Fixes](#cherry-picking-fixes))

### Step 2: Pipeline Creates New Prep PR

When commits are merged to `stable/X.Y`, the prepare-release pipeline automatically:
- Creates `prep/v0.26.6` (incremented patch version)
- Opens a new prepare-release PR
- Creates a new draft release

### Step 3: Publish

Follow the same [Publishing a Release](#publishing-a-release) steps.

---

## Cherry-Picking Fixes

To backport a fix from `main` to a stable branch:

```bash
# Make sure you have the latest
git fetch origin

# Checkout stable branch
git checkout stable/0.26
git pull

# Create backport branch
git checkout -b backport/fix-memory-leak

# Cherry-pick the commit(s) from main
git cherry-pick abc1234

# If there are conflicts, resolve them, then:
git add .
git cherry-pick --continue

# Push and create PR
git push -u origin backport/fix-memory-leak
gh pr create --base stable/0.26 --title "Backport: Fix memory leak" --body "Cherry-picked from main"
```

**Multiple commits:**
```bash
git cherry-pick abc1234 def5678 ghi9012
```

---

## Writing Release Notes

> **Important**: AI-generated release notes are only as good as the commit messages. If commits are not descriptive or miss important context (like breaking changes), you MUST manually edit the notes.

### What to Include

1. **What's New** - New features and capabilities
2. **Improvements** - Enhancements to existing features
3. **Bug Fixes** - Issues that were resolved
4. **Breaking Changes** - CRITICAL: Always call these out prominently
5. **Component Versions** - Updated dependencies (ArgoCD, app-proxy, etc.)

### ArtifactHub Changelog Format

The `Chart.yaml` needs an `artifacthub.io/changes` annotation in YAML format:

```yaml
annotations:
  artifacthub.io/changes: |
    - kind: added
      description: Support for ArgoCD 2.10 application sets
    - kind: changed
      description: Updated app-proxy to v1.5.0 with improved caching
    - kind: fixed
      description: Memory leak in event-reporter under high load
    - kind: security
      description: Updated base images to patch CVE-2024-XXXXX
```

Valid `kind` values: `added`, `changed`, `deprecated`, `removed`, `fixed`, `security`

### GitHub Release Notes Format

```markdown
## What's New

### Features
- **ArgoCD 2.10 Support**: Full compatibility with ArgoCD 2.10 application sets

### Improvements
- Updated app-proxy to v1.5.0 with improved caching performance

### Bug Fixes
- Fixed memory leak in event-reporter that occurred under high load (#452)

## ⚠️ Breaking Changes

- The `legacy.enabled` value has been removed. Migrate to the new configuration format.

## Component Versions

| Component | Version |
|-----------|---------|
| ArgoCD | 2.10.0 |
| app-proxy | 1.5.0 |
```

### Updating Release Notes Manually

1. **Update the draft release body**:
   ```bash
   gh release edit 0.27.0 --repo codefresh-io/gitops-runtime-helm \
     --notes-file release-notes.md
   ```

2. **Update Chart.yaml** on the prep branch:
   - Edit `charts/gitops-runtime/Chart.yaml`
   - Update the `artifacthub.io/changes` annotation
   - Commit and push to `prep/v0.27.0`

### Tips for Good Release Notes

1. **Read the actual commits** - Don't rely solely on PR titles
2. **Check for breaking changes** - Look at API changes, removed values, behavior changes
3. **Verify component versions** - Check `values.yaml` for updated image tags
4. **Link to relevant issues/PRs** - Helps users understand context
5. **Keep it user-focused** - What does this mean for people using the chart?

---

## Troubleshooting

### Pipeline Didn't Run

**Symptom**: Created stable branch but no prep PR appeared

**Check**:
1. Verify the branch was created correctly:
   ```bash
   gh api repos/codefresh-io/gitops-runtime-helm/branches/stable/0.27
   ```
2. Check Argo Events sensor logs (requires cluster access)
3. Try creating a small commit to the branch to re-trigger

### PR Doesn't Have `prepare-release` Label

**Symptom**: PR exists but missing the label

**Fix**:
```bash
gh pr edit <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm --add-label prepare-release
```

### CI Checks Failing

**Symptom**: PR checks are red

**Fix**:
1. Review the failing checks in GitHub
2. Fix issues on the `prep/vX.Y.Z` branch
3. Push fixes - checks will re-run

### Merge Conflicts

**Symptom**: PR shows merge conflicts

**Fix**:
```bash
# Checkout the prep branch
git fetch origin
git checkout prep/v0.27.0

# Rebase or merge from stable
git rebase origin/stable/0.27
# OR
git merge origin/stable/0.27

# Resolve conflicts, then force push
git push --force-with-lease
```

### Release Not Publishing After Merge

**Symptom**: Merged the PR but release is still draft

**Check**:
1. Verify the PR had the `prepare-release` label when merged
2. Check promote pipeline logs (requires cluster access)
3. Manual fallback - publish the release:
   ```bash
   gh release edit 0.27.0 --repo codefresh-io/gitops-runtime-helm --draft=false
   ```

---

## Reference

### Key URLs

| Resource | URL |
|----------|-----|
| Helm Chart Repo | https://github.com/codefresh-io/gitops-runtime-helm |
| Releases | https://github.com/codefresh-io/gitops-runtime-helm/releases |
| Pull Requests | https://github.com/codefresh-io/gitops-runtime-helm/pulls |
| Published Charts | https://quay.io/codefresh/gitops-runtime |

### Branch Naming

| Pattern | Purpose | Example |
|---------|---------|---------|
| `main` | Development branch | - |
| `stable/X.Y` | Release branch | `stable/0.27` |
| `prep/vX.Y.Z` | Prepare-release branch | `prep/v0.27.0` |

### Important Labels

| Label | Purpose |
|-------|---------|
| `prepare-release` | **CRITICAL**: Triggers promote pipeline when PR is merged |

### Version Formats

| Context | Format | Example |
|---------|--------|---------|
| Creating a release line | `major.minor` | `0.27` |
| Specific release version | `major.minor.patch` | `0.27.0` |

### Key Files

| File | Purpose |
|------|---------|
| `charts/gitops-runtime/Chart.yaml` | Version, changelog annotations |
| `charts/gitops-runtime/values.yaml` | Component versions, defaults |

---

## Appendix: Writing Good Commits for Release Notes

The quality of release notes (whether AI-generated or manual) depends entirely on commit message quality. Here's how to write commits that translate into useful release notes.

### Conventional Commits Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types That Map to Release Notes

| Type | Maps To | Example |
|------|---------|---------|
| `feat` | Added | `feat(helm): add support for custom CA certificates` |
| `fix` | Fixed | `fix(app-proxy): resolve memory leak under high load` |
| `perf` | Changed | `perf(event-reporter): optimize batch processing` |
| `refactor` | Changed | `refactor(chart): restructure values for clarity` |
| `docs` | (usually omitted) | `docs: update installation guide` |
| `chore` | (usually omitted) | `chore: bump dependencies` |

### Breaking Changes

**Always** mark breaking changes explicitly:

```
feat(helm)!: remove deprecated legacy configuration

BREAKING CHANGE: The `legacy.enabled` value has been removed.
Migrate to the new `newConfig.enabled` value before upgrading.
```

Or in the footer:
```
feat(helm): restructure authentication values

BREAKING CHANGE: Auth values moved from `auth.*` to `security.auth.*`
```

### Good vs Bad Commits

❌ **Bad** (vague, no context):
```
fix: bug fix
update dependencies
fixes
wip
```

✅ **Good** (specific, actionable):
```
fix(app-proxy): resolve connection timeout on large payloads

The proxy was timing out when processing responses over 10MB.
Increased buffer size and added streaming support.

Fixes #1234
```

✅ **Good** (clear feature description):
```
feat(helm): add horizontal pod autoscaler support

Adds HPA configuration for event-reporter and app-proxy components.
Users can now configure min/max replicas and CPU/memory thresholds.

- Add `eventReporter.autoscaling.*` values
- Add `appProxy.autoscaling.*` values
- Default to disabled for backward compatibility
```

### Component Version Updates

When updating component versions, be explicit:

```
feat(deps): update ArgoCD to 2.10.0

Notable changes:
- ApplicationSet progressive syncs
- Improved diff performance
- New health checks for CRDs

See: https://github.com/argoproj/argo-cd/releases/tag/v2.10.0
```

### Security Fixes

Always mention CVEs:

```
fix(security): update base images for CVE-2024-12345

Updates alpine base image to 3.19.1 which patches CVE-2024-12345
(OpenSSL buffer overflow, CVSS 7.5).
```

---

## Quick Reference Commands

```bash
# List recent releases
gh release list --repo codefresh-io/gitops-runtime-helm

# View open prepare-release PRs
gh pr list --repo codefresh-io/gitops-runtime-helm --label prepare-release

# Check PR status
gh pr view <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm

# Check PR CI status
gh pr checks <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm

# Merge prepare-release PR
gh pr merge <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm --squash

# View a release
gh release view <VERSION> --repo codefresh-io/gitops-runtime-helm

# Create stable branch from main
git fetch origin && git checkout main && git pull
git checkout -b stable/0.27
git push -u origin stable/0.27
```
