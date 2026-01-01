
# HowTo_Github_Action_secrets

This document explains how to generate the required secret values via shell commands and map them into **GitHub → Settings → Secrets and variables → Actions**.[2][1]

## Overview of required secrets

These are the secrets you will configure:

- APP_STORE_CONNECT_KEY_ID  
- APP_STORE_CONNECT_ISSUER_ID  
- APP_STORE_CONNECT_API_KEY_BASE64 (or APP_STORE_CONNECT_P8)  
- MATCH_GIT_PRIVATE_KEY  
- MATCH_PASSWORD  
- ANDROID_KEYSTORE_BASE64  
- ANDROID_KEYSTORE_PASSWORD  
- ANDROID_KEY_ALIAS  
- ANDROID_KEY_ALIAS_PASSWORD[3][4][2]

***

## 1. Apple / App Store Connect secrets

### 1.1 Create an API key in App Store Connect

1. Go to **App Store Connect → Users and Access → API Keys**.  
2. Create a new key and note:  
   - **Key ID** → used as APP_STORE_CONNECT_KEY_ID  
   - **Issuer ID** → used as APP_STORE_CONNECT_ISSUER_ID  
3. Download the `.p8` file (private key) and store it securely.[3]

### 1.2 Base64‑encode the `.p8` file

Run in a terminal (macOS/Linux):

```bash
cd /path/to/your/apple-key
# Replace AuthKey_XXXXXX.p8 with your filename
base64 AuthKey_XXXXXX.p8 > AuthKey_XXXXXX.p8.base64
```

Show the encoded content:

```bash
cat AuthKey_XXXXXX.p8.base64
```

Copy the output; this will become **APP_STORE_CONNECT_API_KEY_BASE64**.[2][3]

> Alternative: Instead of base64, you can store the raw `.p8` content in a secret named APP_STORE_CONNECT_P8 and load it in your workflow.[2]

### 1.3 Add Apple secrets to GitHub

For a *user* or *org* repo:

1. Open your repo on GitHub.  
2. Go to **Settings → Secrets and variables → Actions → New repository secret**.  
3. Create:

- Name: `APP_STORE_CONNECT_KEY_ID`  
  - Value: the **Key ID** from App Store Connect.  
- Name: `APP_STORE_CONNECT_ISSUER_ID`  
  - Value: the **Issuer ID**.  
- Name: `APP_STORE_CONNECT_API_KEY_BASE64`  
  - Value: the base64 string from `cat AuthKey_XXXXXX.p8.base64`.[3][2]

***

## 2. fastlane match secrets

### 2.1 Generate an SSH key for your match repo (if needed)

If you host your signing repo over SSH (recommended):

```bash
ssh-keygen -t rsa -b 4096 -C "match-ios-signing" -f "$HOME/.ssh/id_rsa_match"
```

- Add the **public** key (`id_rsa_match.pub`) to your git hosting provider (e.g. GitHub Deploy Key with read/write).  
- Keep `id_rsa_match` private.[5]

Base64‑encode the private key for GitHub:

```bash
base64 "$HOME/.ssh/id_rsa_match" > id_rsa_match.base64
cat id_rsa_match.base64
```

Copy this output for **MATCH_GIT_PRIVATE_KEY**.[5][2]

### 2.2 Choose a match password

Decide a strong password, for example:

```bash
read -s MATCH_PASSWORD
```

Type your password (won’t echo), then press Enter. This is the value for **MATCH_PASSWORD**.  

### 2.3 Add match secrets to GitHub

Create these secrets:

- `MATCH_GIT_PRIVATE_KEY`  
  - Value: output from `cat id_rsa_match.base64`.  
- `MATCH_PASSWORD`  
  - Value: your chosen password (the same you use in your local `MATCH_PASSWORD`).[6][2]

Your workflow can then reconstruct the key:

```yaml
- name: Write match private key
  run: |
    echo "${{ secrets.MATCH_GIT_PRIVATE_KEY }}" | base64 --decode > ~/.ssh/id_rsa_match
    chmod 600 ~/.ssh/id_rsa_match
```

***

## 3. Android keystore secrets

### 3.1 Generate an Android keystore (if not existing)

From the Android module (or anywhere):

```bash
keytool -genkeypair \
  -v \
  -keystore my-upload-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Remember:

- Keystore file: `my-upload-key.jks`  
- Keystore password: e.g. `MY_KEYSTORE_PASSWORD`  
- Alias: `upload` (or your value)  
- Alias password: e.g. `MY_ALIAS_PASSWORD`.[7][8]

### 3.2 Base64‑encode the keystore

```bash
base64 my-upload-key.jks > my-upload-key.jks.base64
cat my-upload-key.jks.base64
```

Copy the output; this will be **ANDROID_KEYSTORE_BASE64**.[8][7]

### 3.3 Add Android secrets to GitHub

Create these secrets:

- `ANDROID_KEYSTORE_BASE64`  
  - Value: output from `cat my-upload-key.jks.base64`.  
- `ANDROID_KEYSTORE_PASSWORD`  
  - Value: your keystore password from `keytool`.  
- `ANDROID_KEY_ALIAS`  
  - Value: your alias, e.g. `upload`.  
- `ANDROID_KEY_ALIAS_PASSWORD`  
  - Value: the alias password.[7][8]

In the workflow you can reconstruct the keystore:

```yaml
- name: Decode Android keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android_keystore.jks
```

***

## 4. Using secrets in workflows

Once configured, you can use the secrets in your CI as environment variables:

```yaml
env:
  APP_STORE_CONNECT_KEY_ID:        ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
  APP_STORE_CONNECT_ISSUER_ID:    ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
  APP_STORE_CONNECT_API_KEY_BASE64: ${{ secrets.APP_STORE_CONNECT_API_KEY_BASE64 }}
  MATCH_PASSWORD:                  ${{ secrets.MATCH_PASSWORD }}

steps:
  - name: Setup Apple key file
    run: |
      echo "${APP_STORE_CONNECT_API_KEY_BASE64}" | base64 --decode > AuthKey.p8

  - name: Decode Android keystore
    run: |
      echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android_keystore.jks
```

Your fastlane lane can read these values via `ENV["APP_STORE_CONNECT_KEY_ID"]`, `ENV["MATCH_PASSWORD"]`, etc., and Android Gradle signing config can read them from environment variables or Gradle properties.[9][10][2]

