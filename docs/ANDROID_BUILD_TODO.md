# Android Build - Re-enablement Guide

**Status**: ⏸️ **TEMPORARILY DISABLED**
**Date Disabled**: 2026-01-08
**Reason**: Android signing configuration issues in CI/CD
**Location**: `.github/workflows/flutter-cicd.yml`

---

## Current Status

Android builds have been **temporarily disabled** in the CI/CD pipeline to allow iOS builds to complete successfully while Android configuration issues are resolved.

### What's Disabled:

**build-stage job (lines 96-118):**
- ❌ Build Android stage (AAB)
- ❌ Upload Android stage artifact

**build-main job (lines 184-205):**
- ❌ Build Android prod (AAB)
- ❌ Upload Android prod artifact

### What's Still Active:

- ✅ iOS stage builds → TestFlight (Internal Testing)
- ✅ iOS prod builds → TestFlight (Closed Testing)
- ✅ Flutter analyze
- ✅ Semantic release (versioning & tagging)

---

## Issues to Resolve

Before re-enabling Android builds, the following issues must be fixed:

### 1. Android Signing Configuration

**Problem**: Keystore and signing configuration not properly set up for CI/CD

**Files to Check:**
- `android/key.properties` (created dynamically in CI/CD)
- `android/app/build.gradle.kts` (signing config section)

**Required Configuration in build.gradle.kts:**
```kotlin
// Load signing config
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
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
        }
    }
}
```

**Action Items:**
- [ ] Generate keystore file locally: `keytool -genkey -v -keystore upload-key.jks ...`
- [ ] Create `android/key.properties` locally (add to .gitignore)
- [ ] Test local build: `flutter build appbundle --flavor stage --release`
- [ ] Verify AAB is signed correctly

---

### 2. GitHub Secrets Configuration

**Problem**: Missing or incorrect GitHub Secrets for Android signing

**Required Secrets:**

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `ANDROID_KEYSTORE_FILE` | Base64-encoded keystore | `base64 -i upload-key.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | From keystore creation |
| `ANDROID_KEY_ALIAS` | Key alias (usually "upload") | From keystore creation |
| `ANDROID_KEY_PASSWORD` | Key password | From keystore creation |

**How to Set Secrets:**

1. Go to GitHub repository: https://github.com/tkamsker/vronmobile2
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click: **New repository secret**
4. Add each secret from the table above

**Base64 Encode Keystore:**
```bash
# macOS/Linux
base64 -i android/upload-key.jks > keystore.base64
cat keystore.base64 | pbcopy  # Copy to clipboard

# Windows
certutil -encode android/upload-key.jks keystore.base64
```

**Action Items:**
- [ ] Generate keystore if not exists
- [ ] Base64 encode keystore file
- [ ] Add all 4 secrets to GitHub
- [ ] Verify secrets are set correctly

---

### 3. CI/CD Workflow Configuration

**Problem**: Workflow needs to create key.properties before building

**Current Setup** (needs to be added):

The workflow should create `android/key.properties` dynamically before building:

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
```

**Action Items:**
- [ ] Add "Setup Android signing" step to workflow
- [ ] Place before Android build steps
- [ ] Test in CI/CD after re-enabling

---

### 4. Product Flavors Verification

**Status**: ✅ Already configured correctly

**Current Configuration** (android/app/build.gradle.kts):
```kotlin
flavorDimensions += "environment"
productFlavors {
    create("stage") {
        dimension = "environment"
        applicationIdSuffix = ".stage"
        versionNameSuffix = "-stage"
    }
    create("prod") {
        dimension = "environment"
        // Production uses the base applicationId from defaultConfig
    }
}
```

**Verification:**
- [ ] Test build locally: `flutter build appbundle --flavor stage --release`
- [ ] Verify AAB output path: `build/app/outputs/bundle/stageRelease/app-stage-release.aab`
- [ ] Test build locally: `flutter build appbundle --flavor prod --release`
- [ ] Verify AAB output path: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

---

## How to Re-enable Android Builds

Once all issues are resolved, follow these steps to re-enable Android builds:

### Step 1: Locate Disabled Sections

Open `.github/workflows/flutter-cicd.yml` and search for:

```yaml
# ANDROID BUILD - TEMPORARILY DISABLED
```

You'll find **2 sections** (one in build-stage, one in build-main).

---

### Step 2: Uncomment Build Steps

**For build-stage job (around line 102):**

**Before:**
```yaml
# # Android stage build (APK / AAB)
# - name: Build Android stage (AAB)
#   run: |
#     flutter build appbundle \
#       --flavor stage \
#       --release \
#       --dart-define=BUILD_NUMBER=${BUILD_NUMBER}
```

**After:**
```yaml
# Android stage build (APK / AAB)
- name: Build Android stage (AAB)
  run: |
    flutter build appbundle \
      --flavor stage \
      --release \
      --dart-define=BUILD_NUMBER=${BUILD_NUMBER}
```

**For build-main job (around line 190):**

Do the same for prod build.

---

### Step 3: Add Android Signing Setup Step

**Add this BEFORE the Android build steps:**

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
```

---

### Step 4: Test Locally First

**Before pushing changes, test locally:**

```bash
# 1. Ensure you have key.properties locally
cat android/key.properties

# 2. Build stage flavor
flutter build appbundle --flavor stage --release

# 3. Verify output exists
ls -lh build/app/outputs/bundle/stageRelease/app-stage-release.aab

# 4. Build prod flavor
flutter build appbundle --flavor prod --release

# 5. Verify output exists
ls -lh build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

**If local builds succeed**, proceed to next step.

---

### Step 5: Commit and Push

```bash
git add .github/workflows/flutter-cicd.yml
git commit -m "ci: re-enable Android builds after fixing signing configuration

- Uncommented Android build steps for stage and prod
- Added Android signing setup step
- Verified keystore and secrets are configured
- Tested local builds successfully

Android builds now active in CI/CD pipeline."

git push origin stage
```

---

### Step 6: Monitor CI/CD

1. Go to: https://github.com/tkamsker/vronmobile2/actions
2. Watch the build progress
3. Check for errors in:
   - Setup Android signing
   - Build Android stage (AAB)
   - Upload Android stage artifact

**If build succeeds:**
- ✅ Android builds are now restored
- ✅ AAB artifacts will be uploaded
- ✅ Can proceed with Play Store deployment setup

**If build fails:**
- Check error message in Actions log
- Verify secrets are set correctly
- Verify signing config in build.gradle.kts
- Re-disable builds and investigate

---

## Testing Checklist

Before considering Android builds fully restored, verify:

### Local Testing:
- [ ] `flutter build appbundle --flavor stage --release` succeeds
- [ ] `flutter build appbundle --flavor prod --release` succeeds
- [ ] AAB files are created in correct directories
- [ ] AAB files are signed (check with: `jarsigner -verify -verbose app-stage-release.aab`)

### CI/CD Testing:
- [ ] GitHub Secrets are set (all 4 required secrets)
- [ ] Workflow runs without errors
- [ ] AAB artifacts are uploaded successfully
- [ ] Artifacts can be downloaded from Actions tab

### Play Console Testing:
- [ ] AAB can be uploaded to Play Console (manual test)
- [ ] Version code increments correctly
- [ ] Signing is recognized by Play Console

---

## Alternative: Use fastlane for Android

If manual signing setup proves difficult, consider using fastlane for Android builds:

**Benefits:**
- Automated signing management
- Play Store upload integration
- Consistent with iOS approach

**Setup:**
1. Create `android/fastlane/Fastfile`
2. Configure signing in fastlane
3. Add fastlane step to workflow

**Example Fastfile:**
```ruby
platform :android do
  desc "Deploy to Play Store Internal Testing"
  lane :deploy_internal do
    gradle(
      task: "bundle",
      flavor: "stage",
      build_type: "Release"
    )

    upload_to_play_store(
      track: "internal",
      aab: "../build/app/outputs/bundle/stageRelease/app-stage-release.aab",
      skip_upload_metadata: true
    )
  end
end
```

---

## Reference Documentation

- [Google Play Testing Guide](./GOOGLE_PLAY_TESTING.md) - Complete Play Console setup
- [Android Setup Script](../scripts/setup-android.sh) - Local environment setup
- [GitHub Actions Workflow](../.github/workflows/flutter-cicd.yml) - CI/CD configuration

---

## Contact & Support

**Issues?**
- Create GitHub Issue: https://github.com/tkamsker/vronmobile2/issues
- Tag with: `ci-cd`, `android`, `build`

**Questions?**
- Check documentation in `docs/` directory
- Review setup scripts in `scripts/` directory

---

**Last Updated**: 2026-01-08
**Status**: Android builds disabled, iOS builds active
**Next Action**: Fix signing configuration and re-enable builds
