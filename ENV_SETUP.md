# Environment Configuration Setup

This document explains how to manage environment configuration for VRon Mobile across local development and CI/CD pipelines.

## Overview

The project uses `.env` files to manage environment-specific configuration (API endpoints, API keys, feature flags, etc.). These files are **never committed** to the repository for security reasons.

## File Structure

```
.env.example               # Template with all required variables (committed)
.env.stage                 # Stage environment config (gitignored)
.env.main                  # Production environment config (gitignored)
.env                       # Active config loaded by flutter_dotenv (gitignored)
.env.backup                # Auto-created backup when switching (gitignored)
scripts/
  generate-env.sh          # CI/CD script to generate .env from GitHub Secrets
  switch-env.sh            # Local script to switch between environments
  setup-github-secrets.sh  # Set GitHub Secrets from .env files
  list-github-secrets.sh   # List configured GitHub Secrets
  delete-github-secrets.sh # Delete all VRon GitHub Secrets
```

## Local Development Setup

### Initial Setup

1. Create environment-specific files from the template:
   ```bash
   cp .env.example .env.stage
   cp .env.example .env.main
   ```

2. Edit `.env.stage` with staging values:
   ```bash
   VRON_API_URI=https://api.vron.stage.motorenflug.at
   VRON_MERCHANTS_URL=https://app.vron.stage.motorenflug.at
   BLENDER_API_BASE_URL=https://blenderapi.stage.motorenflug.at
   BLENDER_API_KEY=your-stage-api-key
   ENV=staging
   DEBUG=true
   ```

3. Edit `.env.main` with production values:
   ```bash
   VRON_API_URI=https://api.vron.motorenflug.at
   VRON_MERCHANTS_URL=https://app.vron.motorenflug.at
   BLENDER_API_BASE_URL=https://blenderapi.motorenflug.at
   BLENDER_API_KEY=your-production-api-key
   ENV=production
   DEBUG=false
   ```

### Switching Environments

Use the `switch-env.sh` script to switch between environments:

```bash
# Switch to stage environment
./scripts/switch-env.sh stage

# Switch to main/production environment
./scripts/switch-env.sh main
```

The script will:
- Back up your current `.env` to `.env.backup`
- Copy the selected environment file to `.env`
- Show current environment settings

### Manual Switching (Alternative)

If you prefer manual control:

```bash
# Use stage environment
cp .env.stage .env

# Use production environment
cp .env.main .env
```

## CI/CD Setup

### GitHub Secrets Configuration

The CI/CD pipeline requires the following GitHub Secrets to be configured:

#### Stage Branch Secrets
- `VRON_API_URI_STAGE` - Stage API endpoint
- `VRON_MERCHANTS_URL_STAGE` - Stage merchants web app URL
- `BLENDER_API_BASE_URL_STAGE` - Stage Blender API endpoint
- `BLENDER_API_KEY_STAGE` - Stage Blender API key

#### Main Branch Secrets
- `VRON_API_URI_MAIN` - Production API endpoint
- `VRON_MERCHANTS_URL_MAIN` - Production merchants web app URL
- `BLENDER_API_BASE_URL_MAIN` - Production Blender API endpoint
- `BLENDER_API_KEY_MAIN` - Production Blender API key

#### Shared Secrets
- `APP_COOKIE_DOMAIN` - Cookie domain (typically `.motorenflug.at`)

### How CI/CD Works

1. **Workflow triggers** on push to `stage` or `main` branch
2. **Checkout code** (no .env file present)
3. **Generate .env** from GitHub Secrets using `scripts/generate-env.sh`
4. **Flutter build** proceeds with generated .env file
5. **.env is never committed** back to repository

### Adding Secrets to GitHub

#### Option 1: Automated Script (Recommended)

Use the provided script to set all secrets from your `.env.stage` and `.env.main` files:

```bash
# 1. Install GitHub CLI (if not already installed)
brew install gh

# 2. Authenticate with GitHub
gh auth login

# 3. Ensure .env.stage and .env.main are configured
./scripts/switch-env.sh stage  # Verify stage config
./scripts/switch-env.sh main   # Verify main config

# 4. Run the secrets setup script
./scripts/setup-github-secrets.sh
```

The script will:
- Read values from `.env.stage` and `.env.main`
- Show you what will be set (with masked API keys)
- Ask for confirmation
- Set all required secrets in GitHub Actions

#### Option 2: Manual Setup

1. Go to your GitHub repository
2. Navigate to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Add each secret with its corresponding value

### Managing Secrets

**List all secrets:**
```bash
./scripts/list-github-secrets.sh
```

**Delete all secrets:**
```bash
./scripts/delete-github-secrets.sh
```

**Update secrets:**
```bash
# Edit .env.stage or .env.main with new values
# Then re-run the setup script
./scripts/setup-github-secrets.sh
```

### Testing CI/CD Locally

To test the generate-env.sh script locally:

```bash
# Set environment variables
export VRON_API_URI="https://api.vron.stage.motorenflug.at"
export VRON_MERCHANTS_URL="https://app.vron.stage.motorenflug.at"
export APP_COOKIE_DOMAIN=".motorenflug.at"
export BLENDER_API_BASE_URL="https://blenderapi.stage.motorenflug.at"
export BLENDER_API_KEY="test-key"

# Run the generation script
./scripts/generate-env.sh

# Verify the generated .env
cat .env
```

## Environment Variables Reference

### Required Variables

| Variable | Description | Stage Example | Production Example |
|----------|-------------|---------------|-------------------|
| `VRON_API_URI` | Backend API base URL | `https://api.vron.stage.motorenflug.at` | `https://api.vron.motorenflug.at` |
| `VRON_MERCHANTS_URL` | Merchants web app URL | `https://app.vron.stage.motorenflug.at` | `https://app.vron.motorenflug.at` |
| `APP_COOKIE_DOMAIN` | Cookie domain | `.motorenflug.at` | `.motorenflug.at` |
| `BLENDER_API_BASE_URL` | Blender API endpoint | `https://blenderapi.stage.motorenflug.at` | `https://blenderapi.motorenflug.at` |
| `BLENDER_API_KEY` | Blender API key | `stage-key-...` | `prod-key-...` |
| `ENV` | Environment name | `staging` | `production` |
| `DEBUG` | Debug mode flag | `true` | `false` |

### Optional Variables (with defaults)

| Variable | Description | Default |
|----------|-------------|---------|
| `BLENDER_API_TIMEOUT_SECONDS` | API timeout in seconds | `900` |
| `BLENDER_API_POLL_INTERVAL_SECONDS` | Polling interval | `2` |
| `ROOM_ROTATION_DEGREES` | Room canvas rotation | `45` |
| `DOOR_CONNECTION_THRESHOLD` | Door threshold pixels | `50` |
| `CANVAS_GRID_SIZE` | Canvas grid size | `20` |

## Troubleshooting

### Error: "No file or variants found for asset: .env"

**Cause**: The `.env` file doesn't exist at build time.

**Solution**:
- **Local**: Run `./scripts/switch-env.sh stage` or `cp .env.stage .env`
- **CI/CD**: Ensure GitHub Secrets are configured and workflow has the "Generate .env file" step

### Error: "Missing environment variable"

**Cause**: A required variable is not set in your .env file.

**Solution**: Check `.env.example` for all required variables and ensure they're in your `.env.stage` or `.env.main` file.

### CI/CD build fails with missing secrets

**Cause**: GitHub Secrets not configured.

**Solution**:
1. Verify all required secrets are added in GitHub Settings
2. Check secret names match exactly (case-sensitive)
3. Check workflow file references correct secret names

### Script permission denied

**Cause**: Shell scripts don't have execute permissions.

**Solution**:
```bash
chmod +x scripts/generate-env.sh
chmod +x scripts/switch-env.sh
```

## Security Best Practices

1. **Never commit .env files** - They contain sensitive API keys
2. **Use different API keys** for stage and production
3. **Rotate API keys regularly** - Update GitHub Secrets when rotating
4. **Limit secret access** - Only grant GitHub Actions access to necessary secrets
5. **Review .gitignore** - Ensure all .env variants are listed
6. **Use strong API keys** - Minimum 16 characters, random generation

## Migration from Old Setup

If you previously had a committed `.env` file:

1. **Remove from git history** (if sensitive data was committed):
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all
   ```

2. **Create environment files**:
   ```bash
   cp .env .env.stage
   cp .env .env.main
   # Edit .env.main with production values
   ```

3. **Verify gitignore**:
   ```bash
   git check-ignore .env .env.stage .env.main
   # Should show all three files are ignored
   ```

4. **Configure GitHub Secrets** as described above

## References

- [Flutter dotenv package](https://pub.dev/packages/flutter_dotenv)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [VERSIONING.md](./VERSIONING.md) - Semantic versioning and CI/CD pipeline
- [.env.example](./.env.example) - Template with all required variables
