# Google OAuth Client IDs Explained

**Last Updated**: 2025-12-23
**Issue**: "Custom scheme URI are not allowed for WEB client type"

---

## Understanding Google OAuth Client Types

When setting up Google OAuth, you need to create **different OAuth clients** for different purposes:

### 1. Web Client (Server/Backend) 🖥️

**Purpose**: Used by your backend server to verify Google tokens

**Client ID**: `161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op.apps.googleusercontent.com`

**Where It's Used**:
- ✅ Backend server's `signInWithGoogle` mutation
- ✅ Backend token verification with Google's API
- ❌ **NOT** used in iOS/Android mobile apps

**Why Web Client Exists**:
When a user signs in with Google on your mobile app:
1. Mobile app gets an `idToken` from Google
2. Mobile app sends `idToken` to your backend
3. Backend verifies the `idToken` with Google using the **Web Client ID**
4. Backend returns your app's JWT token

**Supports**:
- ✅ Authorized redirect URIs (e.g., `https://api.vron.stage.motorenflug.at/auth/google/callback`)
- ❌ **NO custom URL schemes** (e.g., `com.googleusercontent.apps.*`)

---

### 2. iOS Client (Native iOS App) 📱

**Purpose**: Used by your iOS app for native Google Sign-In

**Client ID**: `161042226580-klsi82nn94vm94bfs6jo364h2do3hr36.apps.googleusercontent.com`

**Where It's Used**:
- ✅ iOS app's `Info.plist` → `GIDClientID`
- ✅ iOS app's `Info.plist` → `CFBundleURLSchemes` (reversed)
- ✅ iOS app's `GoogleService-Info.plist` → `CLIENT_ID`

**Configuration Requirements**:
- Bundle ID: `com.example.vronmobile2`
- No SHA-1 fingerprint needed (iOS uses Bundle ID)

**Supports**:
- ✅ Custom URL schemes (e.g., `com.googleusercontent.apps.161042226580-klsi82nn94vm94bfs6jo364h2do3hr36`)
- ✅ Native iOS OAuth flow
- ❌ **NOT for backend verification**

---

### 3. Android Client (Native Android App) 🤖

**Purpose**: Used by your Android app for native Google Sign-In

**Client ID**: Created with package name and SHA-1 fingerprint

**Where It's Used**:
- ✅ Android app's `google-services.json`
- ✅ Identifies your Android app to Google

**Configuration Requirements**:
- Package name: `com.example.vronmobile2`
- SHA-1 fingerprint: `FA:0C:47:8B:E4:A4:41:AE:63:0A:BC:DE:2B:F1:CA:8C:DF:78:24:4E`

**Supports**:
- ✅ Native Android OAuth flow
- ✅ SHA-1 based app verification
- ❌ **NOT for backend verification**

---

## The Error We Hit

### Error Message:
```
Custom scheme URI are not allowed for WEB client type
```

### What Caused It:

**❌ WRONG Configuration** (what we had):
```xml
<!-- Info.plist -->
<key>GIDClientID</key>
<string>161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op.apps.googleusercontent.com</string>
<!-- ↑ This is the WEB CLIENT ID -->

<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op</string>
    <!-- ↑ Custom URL scheme based on WEB CLIENT ID -->
</array>
```

**Problem**:
- Web Client IDs **cannot** use custom URL schemes
- Only iOS/Android Client IDs support custom URL schemes
- The error was telling us: "You're trying to use a Web Client ID with a custom scheme, which is not allowed"

### ✅ CORRECT Configuration (what we have now):

```xml
<!-- Info.plist -->
<key>GIDClientID</key>
<string>161042226580-klsi82nn94vm94bfs6jo364h2do3hr36.apps.googleusercontent.com</string>
<!-- ↑ This is the iOS CLIENT ID -->

<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.161042226580-klsi82nn94vm94bfs6jo364h2do3hr36</string>
    <!-- ↑ Custom URL scheme based on iOS CLIENT ID -->
</array>
```

**Why This Works**:
- iOS Client IDs **support** custom URL schemes
- The URL scheme matches the iOS Client ID
- Google can properly handle the OAuth callback

---

## Complete OAuth Flow Explained

### Step-by-Step with Correct Client IDs:

1. **User Taps "Sign in with Google"** (iOS App)
   - Uses **iOS Client ID**: `161042226580-klsi82nn94vm94bfs6jo364h2do3hr36`

2. **iOS App Opens Google's Consent Screen**
   - Google recognizes the iOS Client ID
   - User approves permissions

3. **Google Redirects Back to iOS App**
   - Uses custom URL scheme: `com.googleusercontent.apps.161042226580-klsi82nn94vm94bfs6jo364h2do3hr36://`
   - iOS app receives the OAuth callback

4. **iOS App Gets Google Tokens**
   - Receives `idToken` and `accessToken` from Google
   - These tokens are signed with the **iOS Client ID**

5. **iOS App Sends idToken to Backend**
   - GraphQL mutation: `signInWithGoogle(input: { idToken })`

6. **Backend Verifies idToken with Google**
   - Backend uses **Web Client ID**: `161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op`
   - Google verifies the token is valid
   - Backend extracts user info (email, name, picture)

7. **Backend Creates JWT and Returns to App**
   - Backend creates its own JWT (application token)
   - iOS app stores the JWT securely
   - User is now logged in!

---

## Why We Need 3 Different Client IDs

### Web Client:
- **Purpose**: Backend token verification
- **Security**: Backend secret stays on server
- **Use Case**: Verify that the `idToken` from mobile app is legitimate

### iOS Client:
- **Purpose**: Native iOS OAuth flow
- **Security**: Restricted by Bundle ID
- **Use Case**: Let iOS users sign in with Google natively

### Android Client:
- **Purpose**: Native Android OAuth flow
- **Security**: Restricted by Package Name + SHA-1 fingerprint
- **Use Case**: Let Android users sign in with Google natively

---

## Common Mistakes and How to Avoid Them

### Mistake 1: Using Web Client ID in Mobile App ❌

```xml
<!-- WRONG -->
<key>GIDClientID</key>
<string>WEB_CLIENT_ID.apps.googleusercontent.com</string>
```

**Error**: "Custom scheme URI are not allowed for WEB client type"

**Fix**: Use iOS Client ID instead

### Mistake 2: Mismatched URL Scheme ❌

```xml
<!-- WRONG -->
<key>GIDClientID</key>
<string>161042226580-klsi82nn94vm94bfs6jo364h2do3hr36.apps.googleusercontent.com</string>

<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.161042226580-DIFFERENT-ID</string>
    <!-- ↑ This doesn't match GIDClientID! -->
</array>
```

**Error**: "Your app is missing support for the following URL schemes"

**Fix**: URL scheme must be the reversed iOS Client ID (must match `GIDClientID`)

### Mistake 3: Using iOS Client ID on Backend ❌

```typescript
// Backend code - WRONG
const googleAuth = new OAuth2Client(
  'IOS_CLIENT_ID.apps.googleusercontent.com' // ❌ Wrong!
);
```

**Error**: Backend can't verify tokens properly

**Fix**: Backend must use Web Client ID for verification

---

## Testing Each Client ID

### Test iOS Client ID:
```bash
# Run iOS app
flutter run -d <ios-device>

# Try Google Sign-In
# Expected: Google consent screen appears
# Expected: OAuth flow completes successfully
```

### Test Web Client ID (Backend):
```bash
# Test backend token verification
curl -X POST https://api.vron.stage.motorenflug.at/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { signInWithGoogle(input: { idToken: \"REAL_IDTOKEN_HERE\" }) { accessToken } }"}'

# Expected: Returns accessToken (if valid idToken)
# Expected: Error about invalid token (if test token)
```

### Test Android Client ID:
```bash
# Run Android app
flutter run -d <android-device>

# Try Google Sign-In
# Expected: Google consent screen appears
# Expected: OAuth flow completes successfully
```

---

## Summary: Which Client ID Goes Where

| Location | Client Type | Client ID | Purpose |
|----------|-------------|-----------|---------|
| **iOS Info.plist** (`GIDClientID`) | iOS Client | `...klsi82nn94vm94bfs6jo364h2do3hr36` | Native iOS OAuth |
| **iOS Info.plist** (`CFBundleURLSchemes`) | iOS Client (reversed) | `com.googleusercontent.apps....klsi82nn94vm94bfs6jo364h2do3hr36` | OAuth callback |
| **iOS GoogleService-Info.plist** | iOS Client | `...klsi82nn94vm94bfs6jo364h2do3hr36` | iOS app config |
| **Android google-services.json** | Android Client | (in JSON file) | Android app config |
| **Backend Token Verification** | Web Client | `...8k8rpnr3tc0qj22og5nciep5vr4sn5op` | Verify tokens |

---

## Quick Reference

### iOS Client ID (for mobile app):
```
161042226580-klsi82nn94vm94bfs6jo364h2do3hr36.apps.googleusercontent.com
```

### Web Client ID (for backend):
```
161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op.apps.googleusercontent.com
```

### Reversed iOS Client ID (for URL scheme):
```
com.googleusercontent.apps.161042226580-klsi82nn94vm94bfs6jo364h2do3hr36
```

---

## Verification Commands

### Check iOS Configuration:
```bash
# Should show iOS Client ID (ending in klsi82nn94vm94bfs6jo364h2do3hr36)
grep -A1 "GIDClientID" ios/Runner/Info.plist | grep string

# Should show reversed iOS Client ID
grep "com.googleusercontent" ios/Runner/Info.plist
```

### Check Backend Configuration:
Contact backend team to verify they're using:
```
Web Client ID: 161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op
```

---

## Next Steps

1. ✅ Info.plist now correctly uses iOS Client ID
2. ✅ URL scheme now matches iOS Client ID
3. ⏳ Hot restart the app and test OAuth
4. ⏳ Verify backend uses Web Client ID for verification

**The configuration is now correct!** 🎉
