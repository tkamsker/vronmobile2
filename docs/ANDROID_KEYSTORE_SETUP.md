# Android Keystore Setup Guide

Complete guide for generating and configuring an Android keystore for release builds.

## Overview

An Android keystore is required to sign release builds of your app. This guide covers:
1. Generating the keystore file
2. Encoding it for CI/CD
3. Configuring the Android build
4. Securing the keystore

---

## Step 1: Generate the Keystore

### 1.1 Navigate to Project Root

```bash
cd /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2
```

### 1.2 Generate Keystore File

Run the following command:

```bash
keytool -genkeypair \
  -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

**Important:** Use `upload-keystore.jks` (not `my-upload-key.jks`) to follow Flutter conventions.

### 1.3 Enter Required Information

You'll be prompted for:

```
Enter keystore password: [CREATE_STRONG_PASSWORD]
Re-enter new password: [REPEAT_PASSWORD]

What is your first and last name?
  [CN]: VRon Mobile Team

What is the name of your organizational unit?
  [OU]: Mobile Development

What is the name of your organization?
  [O]: VRon

What is the name of your City or Locality?
  [L]: [Your City]

What is the name of your State or Province?
  [ST]: [Your State]

What is the two-letter country code for this unit?
  [C]: AT

Is CN=VRon Mobile Team, OU=Mobile Development, O=VRon, L=[City], ST=[State], C=AT correct?
  [no]: yes

Enter key password for <upload>
  (RETURN if same as keystore password): [PRESS_ENTER or CREATE_DIFFERENT_PASSWORD]
```

**Record These Values Securely:**
- ✅ Keystore file path: `android/app/upload-keystore.jks`
- ✅ Keystore password: `[YOUR_KEYSTORE_PASSWORD]`
- ✅ Key alias: `upload`
- ✅ Key password: `[YOUR_KEY_PASSWORD]` (or same as keystore)

⚠️ **CRITICAL:** Store these in a password manager immediately! Loss means you cannot update your app.

### 1.4 Verify Keystore Creation

```bash
ls -lh android/app/upload-keystore.jks
```

You should see a file (~2-3 KB).

---

## Step 2: Base64 Encode for CI/CD

### 2.1 Encode the Keystore

```bash
base64 android/app/upload-keystore.jks > android/app/upload-keystore.jks.base64
```

### 2.2 View the Encoded Content

```bash
cat android/app/upload-keystore.jks.base64
```

**Copy the entire output.** This is your `ANDROID_KEYSTORE_BASE64` secret for CI/CD.

Example output (truncated):
```
/u3+7QAAAAIAAAABAAAAAQAGdXBsb2FkAAABj...
...many lines...
...kN8qp2JK8mZ3Q==
```

⚠️ **CRITICAL:** This is sensitive! Store securely and never commit to git.

---

## Step 3: Configure Android Build

### 3.1 Create `key.properties` File

Create `android/key.properties`:

```bash
cat > android/key.properties <<'EOF'
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
EOF
```

**Replace:**
- `YOUR_KEYSTORE_PASSWORD` with your keystore password
- `YOUR_KEY_PASSWORD` with your key password (or same as keystore)

Example:
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=upload
storeFile=upload-keystore.jks
```

### 3.2 Update `.gitignore`

Ensure these files are NOT committed:

```bash
# Check if already ignored
grep -E "key.properties|keystore|\.jks" .gitignore

# If not present, add them
cat >> .gitignore <<'EOF'

# Android keystore files (NEVER commit these!)
android/app/upload-keystore.jks
android/app/upload-keystore.jks.base64
android/key.properties
android/**/*.jks
android/**/*.keystore
EOF
```

### 3.3 Configure `build.gradle`

Edit `android/app/build.gradle.kts` to load signing config:

**Find the line:**
```kotlin
android {
```

**Add BEFORE `android {`:**
```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

**Find the `buildTypes` section:**
```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

**Add signing configs BEFORE `buildTypes`:**
```kotlin
signingConfigs {
    create("release") {
        if (keystoreProperties.isNotEmpty()) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        // ... other release config
    }
}
```

---

## Step 4: Test Release Build

### 4.1 Build Release APK

```bash
flutter build apk --release
```

### 4.2 Verify Signing

```bash
# Check APK signature
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# Should show:
# Owner: CN=VRon Mobile Team, OU=Mobile Development, O=VRon, ...
# Issuer: CN=VRon Mobile Team, OU=Mobile Development, O=VRon, ...
```

### 4.3 Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 5: Store Secrets Securely

### 5.1 Local Development (You)

Store in password manager:
```
App: VRon Mobile (Android)
Keystore File: android/app/upload-keystore.jks (backed up securely)
Keystore Password: [YOUR_PASSWORD]
Key Alias: upload
Key Password: [YOUR_PASSWORD]
Base64 Encoded: [CONTENTS_OF_.base64_FILE]
```

### 5.2 Team Members

Share via secure method:
1. **1Password/LastPass**: Share keystore entry
2. **Encrypted file**: Send keystore via encrypted channel
3. **Each developer needs:**
   - `upload-keystore.jks` file in `android/app/`
   - `key.properties` file in `android/`

### 5.3 CI/CD (GitHub Actions / GitLab CI)

Add as repository secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `ANDROID_KEYSTORE_BASE64` | [base64 content] | From step 2.2 |
| `ANDROID_KEYSTORE_PASSWORD` | [password] | Keystore password |
| `ANDROID_KEY_ALIAS` | `upload` | Key alias |
| `ANDROID_KEY_PASSWORD` | [password] | Key password |

**Example CI step:**
```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

- name: Create key.properties
  run: |
    cat > android/key.properties <<EOF
    storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
    keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
    keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
    storeFile=upload-keystore.jks
    EOF
```

---

## Step 6: Backup Strategy

### 6.1 Create Secure Backup

```bash
# Backup keystore to secure location
cp android/app/upload-keystore.jks ~/Backups/vron-mobile-keystore-$(date +%Y%m%d).jks

# Backup to encrypted cloud storage
# Upload to 1Password, encrypted USB drive, or secure cloud
```

### 6.2 Document Recovery Process

Create `android/KEYSTORE_RECOVERY.md`:
```markdown
# Keystore Recovery

If keystore is lost:
1. Check password manager: [Link]
2. Check backup location: [Path]
3. Contact team lead: [Email]

⚠️ If completely lost, you CANNOT update existing app on Play Store.
You must publish under a new package name.
```

---

## Troubleshooting

### Error: "Keystore was tampered with, or password was incorrect"

**Solution:**
- Double-check password in `key.properties`
- Ensure no extra spaces or quotes in password
- Verify keystore file is not corrupted

### Error: "Could not read key upload from store"

**Solution:**
- Verify `keyAlias=upload` matches the alias used during generation
- Check `storeFile` path is correct (relative to `android/app/`)

### Error: "JAVA_HOME not set"

**Solution:**
```bash
# macOS
export JAVA_HOME=$(/usr/libexec/java_home)

# Linux
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

### Build works locally but fails in CI

**Solution:**
- Verify base64 encoding/decoding works correctly
- Check file permissions: `chmod 600 android/app/upload-keystore.jks`
- Ensure `key.properties` is created in CI before build

---

## Security Checklist

- [ ] ✅ Keystore file is in `.gitignore`
- [ ] ✅ `key.properties` is in `.gitignore`
- [ ] ✅ Passwords stored in password manager
- [ ] ✅ Keystore backed up to secure location
- [ ] ✅ Base64 version stored in CI/CD secrets
- [ ] ✅ Team members have access to keystore (securely)
- [ ] ✅ Recovery process documented
- [ ] ✅ No passwords in git history (`git log --all -p | grep -i password`)

---

## Quick Reference

```bash
# Generate keystore
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Base64 encode
base64 android/app/upload-keystore.jks > android/app/upload-keystore.jks.base64

# Verify keystore
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload

# Build release
flutter build apk --release
flutter build appbundle --release

# Verify signature
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

---

## Next Steps

After completing this setup:

1. ✅ Test release build locally
2. ✅ Configure CI/CD with secrets
3. ✅ Upload to Google Play Console (initial upload)
4. ✅ Document keystore location for team
5. ✅ Schedule annual backup verification

**Remember:** The keystore is the key to your app's identity. Lose it, and you cannot update your app on Google Play Store!
