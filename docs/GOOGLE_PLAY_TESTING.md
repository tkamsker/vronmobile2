# Google Play Internal & Closed Testing Implementation Guide

**Document Version**: 1.0
**Last Updated**: 2026-01-08
**Application**: VRonMobile2
**Platform**: Android

---

## Table of Contents

1. [Overview](#overview)
2. [Testing Track Types](#testing-track-types)
3. [Prerequisites](#prerequisites)
4. [Initial Play Console Setup](#initial-play-console-setup)
5. [Internal Testing Setup](#internal-testing-setup)
6. [Closed Testing Setup](#closed-testing-setup)
7. [CI/CD Integration](#cicd-integration)
8. [Manual Upload Process](#manual-upload-process)
9. [Tester Management](#tester-management)
10. [Testing Workflow](#testing-workflow)
11. [Troubleshooting](#troubleshooting)
12. [Best Practices](#best-practices)

---

## Overview

Google Play Console provides multiple testing tracks before releasing an app to production:

| Track | Purpose | Audience Size | Review Required | Distribution Speed |
|-------|---------|---------------|-----------------|-------------------|
| **Internal Testing** | Quick iterations, QA team | Up to 100 testers | No | Immediate (~minutes) |
| **Closed Testing** | Beta testing, controlled group | Unlimited | No | Fast (~hours) |
| **Open Testing** | Public beta | Unlimited | Yes | 1-2 days |
| **Production** | Public release | Unlimited | Yes | 1-7 days |

**VRonMobile2 Strategy:**
- **Internal Testing** → Development team, QA engineers (stage builds)
- **Closed Testing** → Selected partners, beta users (prod builds)
- **Production** → General public (stable releases)

---

## Testing Track Types

### Internal Testing

**Purpose**: Rapid development iterations and quality assurance

**Characteristics:**
- ✅ No Google review required
- ✅ Instant distribution (minutes)
- ✅ Up to 100 testers
- ✅ Email list management
- ✅ Multiple versions simultaneously
- ✅ Version rollback supported
- ⚠️ Limited audience size

**Use Cases:**
- Daily builds from `stage` branch
- Feature validation
- Bug fix verification
- Pre-release testing
- CI/CD automated uploads

**Ideal For:**
- Development team
- QA engineers
- Internal stakeholders
- Automated testing

---

### Closed Testing

**Purpose**: Controlled beta testing with external users

**Characteristics:**
- ✅ No Google review required
- ✅ Fast distribution (hours)
- ✅ Unlimited testers
- ✅ Email lists or Google Groups
- ✅ Multiple test tracks (alpha, beta, custom)
- ✅ Staged rollouts supported
- ✅ Feedback collection

**Use Cases:**
- Beta releases from `main` branch
- User acceptance testing
- Performance testing at scale
- Partner/client previews
- Pre-production validation

**Ideal For:**
- Beta testers
- Partner organizations
- Selected customers
- External stakeholders

---

## Prerequisites

### 1. Google Play Console Account

**Requirements:**
- Google Play Developer account ($25 one-time fee)
- App created in Play Console
- Package name: `com.example.vronmobile2`

**Setup:**
1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with Google account
3. Accept Developer Agreement
4. Pay one-time registration fee

---

### 2. App Signing Key

**Option A: Google Play App Signing (Recommended)**

**Benefits:**
- Google manages signing key
- Automatic APK optimization
- Key rotation support
- Lost key recovery

**Setup:**
```bash
# Generate upload key
keytool -genkey -v -keystore upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Store securely (don't commit to git)
# Add to .gitignore
echo "*.jks" >> android/.gitignore
echo "key.properties" >> android/.gitignore
```

**Option B: Manual Signing**

Not recommended. Use Google Play App Signing.

---

### 3. Android App Bundle (AAB)

**Why AAB?**
- Required for new apps since August 2021
- Smaller download sizes (dynamic delivery)
- Automatic APK generation for devices
- Better optimization

**Build Commands:**
```bash
# Stage flavor (Internal Testing)
flutter build appbundle --flavor stage --release \
  --dart-define=BUILD_NUMBER=123

# Prod flavor (Closed Testing / Production)
flutter build appbundle --flavor prod --release \
  --dart-define=BUILD_NUMBER=123
```

**Output:**
- **Stage**: `build/app/outputs/bundle/stageRelease/app-stage-release.aab`
- **Prod**: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

---

### 4. Signing Configuration

**Create `android/key.properties`:**
```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/path/to/upload-key.jks
```

**Update `android/app/build.gradle.kts`:**
```kotlin
// Load signing config
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Remove debug signing
            // signingConfig = signingConfigs.getByName("debug")
        }
    }
}
```

---

## Initial Play Console Setup

### Step 1: Create App in Play Console

1. **Navigate to Play Console**: https://play.google.com/console
2. **Click**: "Create app"
3. **Fill Details:**
   - **App name**: VRonMobile2
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
4. **Declarations:**
   - ✅ Developer Program Policies
   - ✅ US export laws
5. **Click**: "Create app"

---

### Step 2: Complete Store Listing

**Required Information:**
- App name: VRonMobile2
- Short description (80 chars)
- Full description (4000 chars)
- App icon (512x512 PNG)
- Feature graphic (1024x500 PNG)
- Screenshots (2-8 per device type)
- App category
- Contact email
- Privacy policy URL

**Store Listing Page:**
1. Go to: **Grow** → **Store presence** → **Main store listing**
2. Fill all required fields
3. Upload graphics
4. **Save** (don't publish yet)

---

### Step 3: Content Rating

1. Go to: **Policy** → **App content** → **Content rating**
2. Click: "Start questionnaire"
3. Answer questions honestly
4. Submit for rating
5. Wait for rating certificate (instant)

---

### Step 4: Target Audience & Content

1. Go to: **Policy** → **App content** → **Target audience and content**
2. Select age groups
3. Declare app content (no inappropriate content)
4. Submit

---

### Step 5: App Access

1. Go to: **Policy** → **App content** → **App access**
2. Choose:
   - ⚪ All functionality is available without restrictions
   - ⚪ Some functionality requires account/payment
3. Submit

---

### Step 6: Ads Declaration

1. Go to: **Policy** → **App content** → **Ads**
2. Declare if app contains ads
3. Submit

---

### Step 7: Set Up App Signing

1. Go to: **Release** → **Setup** → **App signing**
2. Choose: **Use Google Play App Signing** (recommended)
3. Upload upload key certificate:
   ```bash
   keytool -export -rfc \
     -keystore upload-key.jks \
     -alias upload \
     -file upload-cert.pem
   ```
4. Upload `upload-cert.pem`
5. Accept terms

---

## Internal Testing Setup

### Step 1: Create Internal Testing Track

1. Go to: **Release** → **Testing** → **Internal testing**
2. Click: "Create new release"
3. You'll see: "No testers yet. Add testers to share this release."

---

### Step 2: Add Testers (Email List)

**Method A: Email List**

1. Scroll to: **Testers** section
2. Click: "Create email list"
3. Enter:
   - **List name**: Internal QA Team
   - **Description**: Development team and QA engineers
4. Add email addresses (one per line):
   ```
   developer1@example.com
   developer2@example.com
   qa@example.com
   ```
5. **Save**
6. Go back to Internal testing page
7. Select: "Internal QA Team" email list
8. **Save**

**Method B: Copy Opt-In Link**

1. Copy the opt-in link shown
2. Share with testers via email/Slack
3. Testers click link → join test program

---

### Step 3: Upload First AAB (Manual)

1. Click: "Create new release"
2. In **App bundles** section:
   - Click: "Upload"
   - Select: `app-stage-release.aab`
   - Wait for upload and processing
3. **Release name**: Auto-filled (version code + version name)
4. **Release notes** (what's new):
   ```
   - Initial internal testing build
   - LiDAR scanning functionality
   - NavMesh generation
   - Room stitching
   ```
5. **Review release** → **Start rollout to Internal testing**
6. Confirm

---

### Step 4: Verify Distribution

**Processing Time**: 5-15 minutes

1. Go to: **Release** → **Testing** → **Internal testing**
2. Check status: "Available to testers"
3. Copy **opt-in URL** and share with testers

---

### Step 5: Tester Access Instructions

**Email to Testers:**
```
Subject: VRonMobile2 - Internal Testing Invitation

Hello!

You've been invited to test VRonMobile2 on Android.

1. Join the test program:
   https://play.google.com/apps/internaltest/XXXXXXXXXXXXXXX

2. Accept the invitation

3. Install the app from Play Store:
   https://play.google.com/store/apps/details?id=com.example.vronmobile2.stage

Note: You must join the test program BEFORE installing.

Questions? Reply to this email.

Thanks!
The VRon Team
```

---

## Closed Testing Setup

### Step 1: Create Closed Testing Track

1. Go to: **Release** → **Testing** → **Closed testing**
2. You'll see multiple tracks:
   - **Alpha** (built-in)
   - **Beta** (built-in)
   - **Custom tracks** (create your own)

**Recommendation**: Use **Beta** track for main closed testing

---

### Step 2: Create Beta Track Release

1. Click on: **Beta** track
2. Click: "Create new release"
3. Release will be similar to Internal Testing

---

### Step 3: Add Testers (Google Groups Recommended)

**Method A: Google Groups (Recommended for >20 testers)**

**Setup:**
1. Go to: https://groups.google.com
2. Create new group:
   - **Name**: VRonMobile2 Beta Testers
   - **Email**: vronmobile2-beta@googlegroups.com
   - **Privacy**: Private (invite only)
3. Add initial members
4. Copy group email address

**In Play Console:**
1. Go to: **Testers** section (Beta track)
2. Click: "Create email list"
3. Enter Google Group email: `vronmobile2-beta@googlegroups.com`
4. **Save**
5. Select the list
6. **Save changes**

**Benefits:**
- Manage testers outside Play Console
- Easy to add/remove members
- Testers don't need Play Console account
- Supports large groups

**Method B: Email List (For smaller groups)**

Same process as Internal Testing but with Beta tester emails.

---

### Step 4: Upload Prod AAB

1. In Beta track, click: "Create new release"
2. Upload: `app-prod-release.aab` (prod flavor)
3. **Release notes**:
   ```
   Beta Build 1.0.0-beta.1

   New Features:
   - Multi-room LiDAR scanning
   - NavMesh generation for Unity
   - Room stitching canvas
   - Project management

   Known Issues:
   - None

   Please report bugs to: beta-feedback@example.com
   ```
4. **Review release** → **Start rollout to Beta**
5. Confirm

---

### Step 5: Configure Rollout (Optional)

**Staged Rollout** (gradually release to percentage of users):

1. Before clicking "Start rollout"
2. Choose: "Staged rollout"
3. Select percentage:
   - 10% → 25% → 50% → 100%
4. Monitor crash reports and feedback
5. Increase percentage when stable

**Use Case:**
- Large beta tester base
- High-risk updates
- Performance validation

---

### Step 6: Countries & Regions

**Default**: All countries where app is available

**To Restrict:**
1. Go to: **Release** → **Testing** → **Closed testing** → **Beta**
2. Scroll to: **Countries/regions**
3. Click: "Manage countries/regions"
4. Select/deselect countries
5. **Save**

---

## CI/CD Integration

### Overview

Automate AAB uploads to Internal Testing (stage) and Closed Testing (prod) using GitHub Actions and Google Play Developer API.

---

### Step 1: Enable Google Play Developer API

1. Go to: https://console.cloud.google.com
2. Create new project: "VRonMobile2"
3. Enable API:
   - Search: "Google Play Developer API"
   - Click: "Enable"

---

### Step 2: Create Service Account

1. In Google Cloud Console:
   - **IAM & Admin** → **Service Accounts**
   - Click: "Create service account"
   - **Name**: github-actions-vronmobile2
   - **Description**: CI/CD uploads to Play Console
   - **Create and Continue**
2. Grant role: "Service Account User"
3. Click: "Done"

---

### Step 3: Create Service Account Key

1. Click on created service account
2. Go to: **Keys** tab
3. Click: "Add Key" → "Create new key"
4. Choose: **JSON**
5. Download JSON key file
6. **IMPORTANT**: Store securely, never commit to git

**JSON Key Format:**
```json
{
  "type": "service_account",
  "project_id": "vronmobile2",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "github-actions-vronmobile2@vronmobile2.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
}
```

---

### Step 4: Link Service Account to Play Console

1. Go to: https://play.google.com/console
2. Navigate to: **Setup** → **API access**
3. Scroll to: **Service accounts**
4. You should see your service account listed
5. Click: "Grant access"
6. Set permissions:
   - ✅ **Releases**: Create and edit releases
   - ✅ **Release to testing tracks**: Internal testing, Closed testing
   - ✅ **View app information**: Read-only
7. Click: "Invite user"
8. Confirm invitation in email

---

### Step 5: Add GitHub Secrets

1. Go to GitHub repository: https://github.com/tkamsker/vronmobile2
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Add secrets:

**Required Secrets:**

```bash
# Google Play Service Account (JSON key content)
PLAY_STORE_SERVICE_ACCOUNT_JSON
# Paste entire JSON file content

# Android Signing
ANDROID_KEYSTORE_FILE
# Base64 encoded keystore file:
# base64 -i upload-key.jks | pbcopy

ANDROID_KEYSTORE_PASSWORD
# Your keystore password

ANDROID_KEY_ALIAS
# upload

ANDROID_KEY_PASSWORD
# Your key password
```

**To Base64 Encode Keystore:**
```bash
# macOS/Linux
base64 -i upload-key.jks > keystore.base64

# Windows
certutil -encode upload-key.jks keystore.base64
```

Copy content of `keystore.base64` to `ANDROID_KEYSTORE_FILE` secret.

---

### Step 6: Update GitHub Actions Workflow

**File**: `.github/workflows/flutter-cicd.yml`

**Add Play Store Upload Step** (after Android build):

```yaml
      # Android stage build (AAB)
      - name: Build Android stage (AAB)
        run: |
          flutter build appbundle \
            --flavor stage \
            --release \
            --dart-define=BUILD_NUMBER=${BUILD_NUMBER}

      - name: Upload Android stage artifact
        uses: actions/upload-artifact@v4
        with:
          name: android-stage-aab
          path: ${{ env.ANDROID_AAB_BUILD_DIR }}/stageRelease/*.aab

      # NEW: Upload to Google Play Internal Testing
      - name: Upload to Play Store (Internal Testing)
        uses: r0adkll/upload-google-play@v1.1.3
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
          packageName: com.example.vronmobile2.stage
          releaseFiles: build/app/outputs/bundle/stageRelease/app-stage-release.aab
          track: internal
          status: completed
          whatsNewDirectory: distribution/whatsnew
```

**For Prod Builds (Closed Testing):**

```yaml
      - name: Build Android prod (AAB)
        run: |
          flutter build appbundle \
            --flavor prod \
            --release \
            --dart-define=BUILD_NUMBER=${BUILD_NUMBER}

      - name: Upload Android prod artifact
        uses: actions/upload-artifact@v4
        with:
          name: android-prod-aab
          path: ${{ env.ANDROID_AAB_BUILD_DIR }}/prodRelease/*.aab

      # NEW: Upload to Google Play Closed Testing (Beta)
      - name: Upload to Play Store (Beta Testing)
        uses: r0adkll/upload-google-play@v1.1.3
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
          packageName: com.example.vronmobile2
          releaseFiles: build/app/outputs/bundle/prodRelease/app-prod-release.aab
          track: beta
          status: completed
          inAppUpdatePriority: 2
          whatsNewDirectory: distribution/whatsnew
```

---

### Step 7: Create Release Notes Directory

**Structure:**
```
distribution/
└── whatsnew/
    ├── whatsnew-en-US
    ├── whatsnew-de-DE
    └── whatsnew-pt-PT
```

**File**: `distribution/whatsnew/whatsnew-en-US`
```
• LiDAR scanning with multi-room support
• NavMesh generation for Unity integration
• Room stitching canvas with drag & connect
• Bug fixes and performance improvements
```

**Commit:**
```bash
mkdir -p distribution/whatsnew
cat > distribution/whatsnew/whatsnew-en-US <<EOF
• LiDAR scanning with multi-room support
• NavMesh generation for Unity integration
• Room stitching canvas with drag & connect
• Bug fixes and performance improvements
EOF

git add distribution/
git commit -m "feat: add Play Store release notes"
```

---

### Step 8: Configure Signing in Workflow

**Add Keystore Setup Step** (before build):

```yaml
      - name: Setup Android signing
        run: |
          # Decode keystore from base64
          echo "${{ secrets.ANDROID_KEYSTORE_FILE }}" | base64 -d > android/upload-key.jks

          # Create key.properties
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=upload-key.jks
          EOF

      - name: Build Android stage (AAB)
        run: |
          flutter build appbundle \
            --flavor stage \
            --release \
            --dart-define=BUILD_NUMBER=${BUILD_NUMBER}
```

---

### Step 9: Test CI/CD Pipeline

1. Push commit to `stage` branch:
   ```bash
   git commit --allow-empty -m "test: trigger CI/CD pipeline"
   git push origin stage
   ```

2. Monitor GitHub Actions:
   - Go to: https://github.com/tkamsker/vronmobile2/actions
   - Watch build progress
   - Check for errors

3. Verify in Play Console:
   - Go to: **Release** → **Testing** → **Internal testing**
   - Check if new release appears (5-15 minutes)
   - Status should be: "Available to testers"

---

## Manual Upload Process

### Using Play Console Web Interface

**When to Use:**
- CI/CD not configured yet
- Emergency hotfix
- Testing before automation

**Steps:**

1. **Build AAB locally:**
   ```bash
   # Stage
   flutter build appbundle --flavor stage --release

   # Prod
   flutter build appbundle --flavor prod --release
   ```

2. **Go to Play Console:**
   - Navigate to app
   - Choose track: Internal testing / Closed testing (Beta)

3. **Create new release:**
   - Click: "Create new release"
   - Upload AAB file
   - Wait for processing (1-2 minutes)

4. **Fill release details:**
   - **Release name**: Auto-filled
   - **Release notes**: Enter what's new
   - Click: "Review release"

5. **Review and rollout:**
   - Check version code/name
   - Verify release notes
   - Click: "Start rollout to [track]"
   - Confirm

6. **Wait for distribution:**
   - Internal: 5-15 minutes
   - Closed: 1-2 hours

---

### Using fastlane (Automated CLI)

**Install fastlane:**
```bash
cd android
bundle install
```

**Create Fastfile:** `android/fastlane/Fastfile`
```ruby
default_platform(:android)

platform :android do
  desc "Upload AAB to Internal Testing"
  lane :deploy_internal do
    upload_to_play_store(
      package_name: "com.example.vronmobile2.stage",
      aab: "../build/app/outputs/bundle/stageRelease/app-stage-release.aab",
      track: "internal",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      json_key: ENV["PLAY_STORE_SERVICE_ACCOUNT_JSON"]
    )
  end

  desc "Upload AAB to Closed Testing (Beta)"
  lane :deploy_beta do
    upload_to_play_store(
      package_name: "com.example.vronmobile2",
      aab: "../build/app/outputs/bundle/prodRelease/app-prod-release.aab",
      track: "beta",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      json_key: ENV["PLAY_STORE_SERVICE_ACCOUNT_JSON"]
    )
  end
end
```

**Usage:**
```bash
# Set service account JSON path
export PLAY_STORE_SERVICE_ACCOUNT_JSON="/path/to/service-account.json"

# Build and upload to Internal Testing
flutter build appbundle --flavor stage --release
cd android
bundle exec fastlane deploy_internal

# Build and upload to Closed Testing (Beta)
flutter build appbundle --flavor prod --release
cd android
bundle exec fastlane deploy_beta
```

---

## Tester Management

### Adding Testers

**Internal Testing (Email Lists):**
1. Go to: **Release** → **Testing** → **Internal testing**
2. Scroll to: **Testers**
3. Click on email list name
4. Click: "Add testers"
5. Enter email addresses (one per line)
6. **Save**

**Closed Testing (Google Groups):**
1. Go to: https://groups.google.com
2. Open your beta group
3. Click: "Members" → "Add members"
4. Enter email addresses
5. **Send invite**

**Automatic Sync:**
- Play Console syncs with Google Groups hourly
- New members get access within 1-2 hours

---

### Removing Testers

**Email Lists:**
1. Go to email list
2. Click: "Remove" next to tester email
3. **Save**

**Google Groups:**
1. Go to Google Group
2. Select member
3. Click: "Remove member"

**Effect:**
- Tester loses access immediately
- Can no longer install updates
- Existing installation continues to work

---

### Tester Limits

| Track | Max Testers |
|-------|-------------|
| Internal Testing | 100 |
| Closed Testing | Unlimited |
| Open Testing | Unlimited |

**Workaround for Internal Testing > 100:**
- Create multiple email lists
- OR migrate to Closed Testing

---

### Tester Feedback Collection

**Method 1: Play Console Feedback**

Testers can submit feedback directly from Play Store:
1. Go to: **Quality** → **Android vitals** → **Feedback**
2. View crash reports
3. View user feedback

**Method 2: Custom Feedback Form**

Add feedback button in app:
```dart
// In app settings or help section
ElevatedButton(
  onPressed: () {
    launchUrl(Uri.parse('https://forms.gle/your-form-id'));
  },
  child: Text('Submit Feedback'),
)
```

**Method 3: Email**

Include feedback email in release notes:
```
Questions or issues? Email: beta-feedback@example.com
```

---

## Testing Workflow

### Recommended Flow

```
Development
    ↓
    ├─ Feature branch → Pull Request → Code Review
    ↓
Stage Branch (CI/CD)
    ↓
    ├─ Build AAB (stage flavor)
    ├─ Upload to Play Store (Internal Testing)
    ├─ QA Team Tests
    ↓
    ├─ [Bug Found] → Fix → Repeat
    ↓
Main Branch (Merge)
    ↓
    ├─ Build AAB (prod flavor)
    ├─ Upload to Play Store (Closed Testing - Beta)
    ├─ Beta Testers Test
    ↓
    ├─ [Issues Found] → Fix → Deploy new beta
    ↓
    ├─ [Stable] → Promote to Production
    ↓
Production Release
    ↓
    ├─ Staged Rollout (10% → 25% → 50% → 100%)
    ├─ Monitor crash reports
    ├─ Monitor user feedback
```

---

### Daily Development Cycle

**Morning:**
1. Developer merges feature to `stage` branch
2. CI/CD builds and uploads to Internal Testing (auto)
3. QA team receives notification (Play Store update)

**Afternoon:**
1. QA tests new build
2. Reports bugs in GitHub Issues
3. Developer fixes bugs

**Evening:**
1. Bug fixes merged to `stage`
2. New build uploaded to Internal Testing
3. QA verifies fixes next morning

**Weekly:**
1. Stable `stage` merged to `main`
2. Prod build uploaded to Closed Testing (Beta)
3. Beta testers test over week

**Bi-weekly:**
1. Stable beta promoted to Production
2. Staged rollout begins
3. Monitor for 48 hours

---

### Version Management

**Versioning Strategy:**

```yaml
# pubspec.yaml
version: 1.0.2+123

# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# 1.0.2 = Version Name (user-visible)
# 123   = Version Code (internal, must increment)
```

**Rules:**
- **Version Code**: Must always increment (never reuse)
- **Version Name**: Semantic versioning
  - **MAJOR**: Breaking changes
  - **MINOR**: New features (backward compatible)
  - **PATCH**: Bug fixes

**Example Progression:**
```
Internal Testing (stage):
  1.0.0-beta.1+101
  1.0.0-beta.2+102
  1.0.0-beta.3+103

Closed Testing (beta):
  1.0.0-rc.1+104
  1.0.0-rc.2+105

Production:
  1.0.0+106
  1.0.1+107 (hotfix)
  1.1.0+108 (new features)
```

---

## Troubleshooting

### Issue 1: "APK/AAB not signed"

**Error:**
```
Upload failed: APK is not signed
```

**Solution:**
1. Check `android/key.properties` exists
2. Verify `build.gradle.kts` has `signingConfigs` block
3. Ensure keystore file path is correct
4. Check keystore password is correct

**Test locally:**
```bash
# This should work without errors
flutter build appbundle --flavor stage --release
```

---

### Issue 2: "Package name mismatch"

**Error:**
```
Package name com.example.vronmobile2.stage does not match
the package name in Play Console: com.example.vronmobile2
```

**Solution:**
- Internal Testing: Must use separate package name (`.stage` suffix)
- Closed Testing: Must use production package name (no suffix)
- Production: Must use production package name

**Check `build.gradle.kts`:**
```kotlin
productFlavors {
    create("stage") {
        applicationId = "com.example.vronmobile2.stage" // Different
    }
    create("prod") {
        applicationId = "com.example.vronmobile2" // Same as Play Console
    }
}
```

---

### Issue 3: "Version code already used"

**Error:**
```
Version code 123 has already been used
```

**Solution:**
Version codes must always increment, never reuse.

**Fix:**
```bash
# Increment BUILD_NUMBER in CI/CD
BUILD_NUMBER=$((GITHUB_RUN_NUMBER + 100))

# Or manually increment in pubspec.yaml
version: 1.0.2+124  # Was 123, now 124
```

---

### Issue 4: Testers can't see app

**Symptoms:**
- Tester joined test program
- App not visible in Play Store

**Solutions:**

1. **Check if tester joined correctly:**
   - Verify opt-in link was clicked
   - Check "You're a tester" message appears

2. **Check device compatibility:**
   - Verify device meets minSdkVersion
   - Check `android/app/build.gradle.kts`:
     ```kotlin
     minSdk = 21  // Android 5.0+
     ```

3. **Check country availability:**
   - Ensure tester's country is enabled in track settings

4. **Wait for sync:**
   - Internal: 5-15 minutes
   - Closed: 1-2 hours

5. **Try direct link:**
   ```
   https://play.google.com/store/apps/details?id=com.example.vronmobile2.stage
   ```

---

### Issue 5: "Service account not authorized"

**Error:**
```
The current user has insufficient permissions to perform the requested operation
```

**Solution:**
1. Go to Play Console: **Setup** → **API access**
2. Find service account
3. Click: "Grant access"
4. Ensure these permissions are checked:
   - ✅ Release to testing tracks
   - ✅ Create and edit releases
5. Wait 1 hour for permissions to propagate

---

### Issue 6: CI/CD upload fails

**Check logs for:**
- Service account JSON format (must be valid JSON)
- Package name matches Play Console
- AAB file path is correct
- Version code increments

**Debug:**
```yaml
- name: Debug AAB upload
  run: |
    echo "Package: com.example.vronmobile2.stage"
    echo "AAB exists: $(ls build/app/outputs/bundle/stageRelease/*.aab)"
    echo "Version: $(grep 'version:' pubspec.yaml)"
```

---

### Issue 7: "This release is not compliant"

**Error in Play Console:**
```
This release is not compliant with Google Play Policies
```

**Common Causes:**
1. **Missing permissions declarations**: Add to `AndroidManifest.xml`
2. **Dangerous permissions without justification**: Explain in Play Console
3. **Outdated targetSdkVersion**: Update to latest
4. **Missing privacy policy**: Add URL in store listing

**Check:**
```bash
# View APK permissions
aapt dump permissions build/app/outputs/bundle/stageRelease/app-stage-release.aab
```

---

## Best Practices

### 1. Automate Everything

**✅ DO:**
- Use CI/CD for all uploads
- Automate version increment
- Auto-generate release notes from commits

**❌ DON'T:**
- Manually upload every build
- Manually edit version codes
- Forget to update release notes

---

### 2. Version Management

**✅ DO:**
- Use semantic versioning
- Increment version code in CI/CD: `BUILD_NUMBER=$GITHUB_RUN_NUMBER`
- Tag releases in git: `git tag v1.0.2`

**❌ DON'T:**
- Reuse version codes
- Use arbitrary version numbers
- Forget to sync pubspec.yaml with git tags

---

### 3. Release Notes

**✅ DO:**
- Write clear, user-friendly notes
- Highlight new features
- Mention known issues
- Update `distribution/whatsnew/` before release

**❌ DON'T:**
- Write technical jargon
- Leave notes empty
- Copy commit messages directly

**Good Example:**
```
• New: Multi-room scanning support
• Improved: NavMesh generation is 2x faster
• Fixed: Crash when rotating device during scan
• Note: Requires Android 7.0 or later
```

**Bad Example:**
```
• feat: add multiroom scanning (#123)
• perf: optimize navmesh generation
• fix: rotation crash
```

---

### 4. Testing Tracks Strategy

**✅ DO:**
- Use Internal for rapid iteration (daily/hourly)
- Use Closed Beta for wider testing (weekly)
- Promote stable betas to Production

**❌ DON'T:**
- Upload to Production directly
- Skip testing tracks
- Use Open Testing for internal QA

---

### 5. Tester Management

**✅ DO:**
- Use Google Groups for large beta programs
- Collect feedback actively
- Remove inactive testers periodically
- Send update notifications via email

**❌ DON'T:**
- Add testers to multiple tracks
- Ignore tester feedback
- Forget to remove testers after project ends

---

### 6. Monitoring & Feedback

**✅ DO:**
- Monitor Android Vitals daily
- Review crash reports immediately
- Read user feedback in Play Console
- Set up crash reporting (Firebase Crashlytics)

**❌ DON'T:**
- Ignore crash rates
- Dismiss user feedback
- Wait for users to report issues

---

### 7. Security

**✅ DO:**
- Store keystore securely (password manager)
- Use Google Play App Signing
- Add `*.jks` and `key.properties` to `.gitignore`
- Rotate service account keys annually
- Use GitHub Secrets for CI/CD

**❌ DON'T:**
- Commit keystore to git
- Share keystore passwords in Slack/email
- Use debug signing for release builds
- Hardcode credentials

---

### 8. Rollout Strategy

**✅ DO:**
- Use staged rollouts for Production (10% → 100%)
- Monitor crash rates at each stage
- Halt rollout if crash rate spikes
- Keep previous version ready to rollback

**❌ DON'T:**
- Release to 100% immediately
- Ignore crash rate increases
- Continue rollout with critical bugs

---

## Quick Reference

### Commands Cheat Sheet

```bash
# Build AABs
flutter build appbundle --flavor stage --release --dart-define=BUILD_NUMBER=123
flutter build appbundle --flavor prod --release --dart-define=BUILD_NUMBER=123

# Generate upload certificate
keytool -export -rfc -keystore upload-key.jks -alias upload -file upload-cert.pem

# Check AAB info
bundletool build-apks --bundle=app-stage-release.aab --output=output.apks
bundletool get-device-spec --output=device-spec.json

# fastlane upload
cd android
bundle exec fastlane deploy_internal
bundle exec fastlane deploy_beta
```

---

### Important URLs

- **Play Console**: https://play.google.com/console
- **Google Cloud Console**: https://console.cloud.google.com
- **Google Groups**: https://groups.google.com
- **Google Play Developer API**: https://developers.google.com/android-publisher

---

### Track Comparison Table

| Feature | Internal | Closed (Beta) | Production |
|---------|----------|---------------|------------|
| **Max Testers** | 100 | Unlimited | Unlimited |
| **Review Time** | None | None | 1-7 days |
| **Distribution** | Minutes | Hours | Days |
| **Google Groups** | No | Yes | N/A |
| **Staged Rollout** | No | Yes | Yes |
| **User Feedback** | Limited | Full | Full |
| **Crash Reports** | Yes | Yes | Yes |
| **App Visibility** | Testers only | Testers only | Everyone |

---

### Version Code Tracking

| Branch | Track | Version Format | Example |
|--------|-------|----------------|---------|
| `stage` | Internal | X.Y.Z-beta.N+BUILD | 1.0.0-beta.1+101 |
| `main` | Beta | X.Y.Z-rc.N+BUILD | 1.0.0-rc.1+104 |
| `main` | Production | X.Y.Z+BUILD | 1.0.0+106 |

---

## Appendix: Service Account JSON Setup

### Full GitHub Secrets Setup Script

```bash
#!/bin/bash
# Setup GitHub Secrets for Play Store deployment

REPO="tkamsker/vronmobile2"

# 1. Service Account JSON
echo "Setting PLAY_STORE_SERVICE_ACCOUNT_JSON..."
gh secret set PLAY_STORE_SERVICE_ACCOUNT_JSON \
  --repo="$REPO" \
  < service-account.json

# 2. Android Keystore (Base64)
echo "Setting ANDROID_KEYSTORE_FILE..."
base64 -i upload-key.jks | \
  gh secret set ANDROID_KEYSTORE_FILE --repo="$REPO"

# 3. Keystore Password
echo "Enter keystore password:"
read -s KEYSTORE_PASS
echo "$KEYSTORE_PASS" | gh secret set ANDROID_KEYSTORE_PASSWORD --repo="$REPO"

# 4. Key Password
echo "Enter key password:"
read -s KEY_PASS
echo "$KEY_PASS" | gh secret set ANDROID_KEY_PASSWORD --repo="$REPO"

# 5. Key Alias
echo "upload" | gh secret set ANDROID_KEY_ALIAS --repo="$REPO"

echo "✅ All secrets set successfully!"
```

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-08 | Initial document |

---

**Questions or Issues?**

Contact: dev@vron.one
Documentation: https://github.com/tkamsker/vronmobile2/docs
