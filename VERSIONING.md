# Versioning & Release Process

This project uses **semantic-release** for automated versioning and tagging based on conventional commits.

## How It Works

### Conventional Commits

All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types and Version Bumps

- `fix:` - Patch release (1.0.0 → 1.0.1)
- `feat:` - Minor release (1.0.0 → 1.1.0)
- `BREAKING CHANGE:` or `!` suffix - Major release (1.0.0 → 2.0.0)
- `chore:`, `docs:`, `style:`, `refactor:`, `test:`, `ci:` - No release

#### Examples

```bash
# Patch release
git commit -m "fix: resolve authentication timeout issue"

# Minor release
git commit -m "feat: add dark mode support"

# Major release
git commit -m "feat!: redesign API authentication flow

BREAKING CHANGE: Authentication now requires OAuth2 tokens"
```

## Branches and Versioning

### Main Branch (`main`)
- Production releases
- Creates stable versions: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Deploys to App Store / Google Play

### Stage Branch (`stage`)
- Pre-release versions
- Creates beta versions: `v1.1.0-beta.1`, `v1.1.0-beta.2`
- Deploys to TestFlight (internal testing)

## CI/CD Workflow

### Automated Process

1. **Push commits** to `stage` or `main`
2. **CI runs tests** and builds artifacts
3. **semantic-release analyzes commits** since last tag
4. **Version is determined** based on commit types
5. **pubspec.yaml is updated** with new version
6. **Git tag is created** (e.g., `v1.1.0`)
7. **GitHub release is created** with changelog
8. **Artifacts are deployed** to TestFlight/App Store

### Manual Version Check

To see what version would be released:

```bash
# Check commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Dry-run semantic-release
npx semantic-release --dry-run
```

## Version Format

### pubspec.yaml
```yaml
version: 1.0.2+da1166d
         ├──┬─┘ └──┬───┘
         │  │      └── Git commit hash (build metadata)
         │  └───────── Patch version
         └──────────── Major.Minor version
```

### Git Tags
- Production: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Stage: `v1.1.0-beta.1`, `v1.1.0-beta.2`

## Configuration Files

- `.releaserc.json` - semantic-release configuration
- `package.json` - Node.js dependencies for semantic-release
- `.github/workflows/flutter-cicd.yml` - CI/CD pipeline with release jobs

## Troubleshooting

### Version Not Updating

**Problem:** semantic-release says "no release published"

**Causes:**
1. No commits with `feat:` or `fix:` since last tag
2. Only `chore:`, `docs:`, `refactor:` commits (these don't trigger releases)
3. Last commit was a release commit (contains `[skip ci]`)

**Solution:**
```bash
# Check commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"%h %s"

# Ensure at least one feat: or fix: commit exists
```

### CI Failing on Warnings

**Problem:** `flutter analyze` fails on warnings

**Solution:** Workflow now uses `--no-fatal-infos --no-fatal-warnings` flags:
```yaml
- run: flutter analyze --no-fatal-infos --no-fatal-warnings
```

Only errors will cause CI failures.

### Manual Release

If automated release fails, you can manually tag:

```bash
# Create tag
git tag v1.1.0

# Push tag
git push origin v1.1.0

# Update pubspec.yaml manually
version: 1.1.0+$(git rev-parse --short HEAD)
```

## Best Practices

1. **Commit often** with clear, descriptive messages
2. **Use conventional commits** for all changes
3. **Group related changes** in single commits
4. **Test on stage** before merging to main
5. **Never force-push** to main or stage branches
6. **Review changelog** after each release

## Release Checklist

Before merging to main:

- [ ] All tests pass on stage
- [ ] TestFlight build tested by team
- [ ] Conventional commits used throughout feature
- [ ] No breaking changes (or documented properly)
- [ ] CHANGELOG.md reviewed
- [ ] Version bump is correct

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [semantic-release Documentation](https://semantic-release.gitbook.io/)
- [Flutter Versioning](https://dart.dev/tools/pub/pubspec#version)
