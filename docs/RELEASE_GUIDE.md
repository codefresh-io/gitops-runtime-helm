# GitOps Runtime Release Guide

This guide explains how to perform releases for the GitOps Runtime Helm chart.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Release Types](#release-types)
4. [Creating a New Minor Release](#creating-a-new-minor-release)
5. [Release Validation](#release-validation)
6. [Publishing a Release](#publishing-a-release)
7. [Creating a Patch Release](#creating-a-patch-release)
8. [Cherry-Picking Fixes](#cherry-picking-fixes)
9. [Writing Release Notes](#writing-release-notes)
10. [Troubleshooting](#troubleshooting)
11. [Reference](#reference)

---

## Overview

The GitOps Runtime release process uses **Codefresh CI** to automate most of the work.
The developers:

1. **Trigger pipelines** by creating branches
2. **Review and approve** the PRs
3. **Write/edit release notes** (the AI can help, but human review is essential)
4. **Publish releases** by merging the PR

### How It Works

```
You complete work on a PR for main, edit release notes, then merge the PR
        ↓
[CF CI: promote] runs automatically
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

| Type | When | Example |
|------|------|---------|
| **Minor Release** | New features, starting a release line | 0.27.0 |
| **Patch Release** | Bug fixes to existing release | 0.26.6 |

---

## Basic release sanity checks

```bash
# Check for the PR
gh pr list --repo codefresh-io/gitops-runtime-helm --head your-branch-name

# Check for draft release
gh release list --repo codefresh-io/gitops-runtime-helm | head -5
```

Or visit:
- PRs: https://github.com/codefresh-io/gitops-runtime-helm/pulls
- Releases: https://github.com/codefresh-io/gitops-runtime-helm/releases

---

## Release Validation

After the PR is reviewed and approved, the release should be validated to ensure stability.

### Current Approach

The CI pipeline runs e2e tests on every PR. If these tests pass, the release is considered validated and ready to publish.

> **Note**: Previously, releases were validated by deploying to staging environments and letting them run for a period before publishing. This approach is no longer in use. If additional validation is needed in the future, consider introducing a manual testing stage or dedicated validation environments.

### Validation Checklist

Before publishing, ensure:

- [ ] All CI checks pass (unit tests, linting, e2e tests)
- [ ] The PR has been reviewed by the right reviewers
- [ ] Release notes accurately reflect the changes
- [ ] No known critical issues exist in the changes being released

---

## Publishing a Release

### Step 1: Check PR Status

Before publishing, verify:

1. **CI checks are passing**
   ```bash
   gh pr checks <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm
   ```

3. **Release notes are complete** (see [Writing Release Notes](#writing-release-notes))

### Step 2: Review the PR

1. Open the PR in GitHub
2. Review the changes (version bump, changelog)
3. Ensure release notes in the draft GitHub release are accurate

### Step 3: Merge the PR

```bash
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

### Step 5: Announcement (Automated)

When a release is published, a GitHub Actions workflow automatically posts announcements to:
- `#topic-cf-gitops-runtime` - Primary announcement with release version and link
- `#team-support-announcements` - Cross-post for the support team

No manual action required. If notifications don't appear, see [Troubleshooting: Slack Notifications Not Sent](#slack-notifications-not-sent).

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

### CI Checks Failing

**Symptom**: PR checks are red

**Fix**:
1. Review the failing checks in GitHub
2. Fix issues on the `prep/vX.Y.Z` branch
3. Push fixes - checks will re-run

### Slack Notifications Not Sent

**Symptom**: Release published but no Slack notifications appeared

**Check**:
1. Verify the `release-notification` workflow ran:
   - Go to Actions tab → "Release Notification" workflow
   - Check for failed runs
2. If workflow failed, check for:
   - Missing `SLACK_BOT_TOKEN` secret
   - Missing `SLACK_CHANNEL_GITOPS_RUNTIME` or `SLACK_CHANNEL_SUPPORT_ANNOUNCEMENTS` variables
   - Bot not invited to the channels
3. Manual fallback - post manually to Slack:
   ```
   🚀 GitOps Runtime vX.Y.Z has been released!

   Release notes: https://github.com/codefresh-io/gitops-runtime-helm/releases/tag/X.Y.Z
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
| `main` | Release branch | - |
| `(feat|fix|...)/XX-YYYY-desc` | Development branches | `feat/CF-1234-fancy-stuff` |

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
| `.github/workflows/release-notification.yaml` | Slack release announcements |

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

# View open PRs
gh pr list --repo codefresh-io/gitops-runtime-helm

# Check PR status
gh pr view <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm

# Check PR CI status
gh pr checks <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm

# Merge a PR
gh pr merge <PR-NUMBER> --repo codefresh-io/gitops-runtime-helm --squash

# View a release
gh release view <VERSION> --repo codefresh-io/gitops-runtime-helm
```
