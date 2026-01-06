# Google OAuth Troubleshooting Guide

**Feature**: 003-google-oauth-login
**Last Updated**: 2025-12-23

This guide helps diagnose and resolve Google OAuth authentication issues in the mobile app.

---

## Quick Diagnostic Checklist

Run through this checklist to identify the root cause:

- [ ] **Phase 1 Setup Complete**: Platform configuration (T003-T009) finished
- [ ] **Backend Deployed**: `exchangeGoogleIdToken` GraphQL mutation is deployed and accessible
- [ ] **Environment Variables**: `.env` file exists and contains correct URLs
- [ ] **Google Cloud Console**: OAuth clients configured for both Android and iOS
- [ ] **Network Connectivity**: Device can reach backend API
- [ ] **Debug Logs**: Check console output for specific error messages

---

## Common Issues and Solutions

### Issue 1: "PlatformException: sign_in_failed" (Android)

**Symptoms**:
- OAuth flow fails immediately after tapping "Sign in with Google"
- Error code: `sign_in_failed`, `ERROR_SIGN_IN_REQUIRED`, or `10`

**Root Cause**:
Google Play Services configuration issue - SHA-1 fingerprint not configured in Google Cloud Console.

**Solution**:
1. Get your app's SHA-1 certificate fingerprint:
   ```bash
   # Debug keystore (for development)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

   # Release keystore (for production)
   keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
   ```

2. Add SHA-1 to Google Cloud Console:
   - Go to: https://console.cloud.google.com/apis/credentials
   - Select your OAuth 2.0 Client ID (Android type)
   - Add the SHA-1 fingerprint under "Signing certificate fingerprint"
   - Save changes

3. Download new `google-services.json` and place in `android/app/`

4. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   cd .. && flutter run
   ```

**Reference**: Tasks T003, T005

---

### Issue 2: "PlatformException: sign_in_canceled" (iOS)

**Symptoms**:
- OAuth flow doesn't open Google's consent screen
- Fails immediately or shows "The operation couldn't be completed"

**Root Cause**:
URL scheme callback not configured properly in iOS.

**Solution**:
1. Check `ios/Runner/Info.plist` contains:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_CLIENT_ID_REVERSED</string>
       </array>
     </dict>
   </array>

   <key>GIDClientID</key>
   <string>YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
   ```

2. Verify the reversed client ID matches your OAuth client ID from Google Cloud Console

3. Run `cd ios && pod install` to update CocoaPods

4. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   cd ios && rm -rf Pods Podfile.lock
   pod install
   cd .. && flutter run
   ```

**Reference**: Tasks T004, T006, T007, T008

---

### Issue 3: GraphQL Error - "Invalid or expired Google token"

**Symptoms**:
- Google sign-in completes successfully
- Error occurs during backend token exchange
- Console log shows: "GraphQL error: Invalid or expired Google token"

**Root Cause**:
Backend's OAuth client ID doesn't match the mobile app's OAuth client ID.

**Solution**:
1. Verify Google Cloud Console has 3 OAuth clients:
   - **Web Client**: For backend token verification
   - **Android Client**: For Android app (with SHA-1)
   - **iOS Client**: For iOS app (with bundle ID)

2. Backend must use the **Web Client ID** for token verification

3. Check with backend team that `exchangeGoogleIdToken` mutation is using correct client ID

**GraphQL Contract**: See `specs/003-google-oauth-login/contracts/graphql-api.md`

---

### Issue 4: Network Error / Backend Unreachable

**Symptoms**:
- Error: "Network error. Please check your connection"
- Console log shows: "Network/link error detected"

**Root Cause**:
Mobile app cannot reach the GraphQL endpoint.

**Solution**:
1. Verify `.env` file exists and contains correct `VRON_API_URI`:
   ```env
   VRON_API_URI=https://api.vron.stage.motorenflug.at
   ```

2. Test backend connectivity:
   ```bash
   # Test GraphQL endpoint is reachable
   curl -X POST https://api.vron.stage.motorenflug.at/graphql \
     -H "Content-Type: application/json" \
     -d '{"query":"{ __typename }"}'
   ```

3. Check device network:
   - Emulator: Ensure emulator has internet access
   - Real device: Ensure WiFi/mobile data is enabled
   - Firewall: Check corporate firewall isn't blocking API

4. Verify backend is deployed and healthy

**Reference**: `lib/core/config/env_config.dart`

---

### Issue 5: "Sign-in failed. Please try again later" (Generic Backend Error)

**Symptoms**:
- Generic error message after Google sign-in
- Console log shows: "Backend authentication failed" or "GraphQL exception"

**Root Cause**:
Backend `exchangeGoogleIdToken` mutation not implemented or throwing errors.

**Solution**:
1. Verify backend mutation is deployed:
   ```bash
   # Test mutation directly (requires valid Google idToken)
   curl -X POST https://api.vron.stage.motorenflug.at/graphql \
     -H "Content-Type: application/json" \
     -d '{
       "query": "mutation { exchangeGoogleIdToken(input: { idToken: \"test\" }) }"
     }'
   ```

2. Check backend logs for errors during OAuth flow

3. Verify database permissions for user creation/linking

4. Confirm backend can reach Google's token verification API:
   ```
   POST https://oauth2.googleapis.com/tokeninfo?id_token={idToken}
   ```

**Backend Contract**: See `specs/003-google-oauth-login/contracts/graphql-api.md`

---

## Debug Logging Guide

The app includes comprehensive debug logging when `DEBUG=true` in `.env`. Look for these log messages:

### Successful Flow:
```
🔐 [AUTH] Starting Google sign-in
✅ [AUTH] Google account obtained: user@example.com
✅ [AUTH] Google idToken obtained
🔐 [AUTH] GraphQL mutation completed
✅ [AUTH] Received backend access token
✅ [AUTH] Tokens stored securely
✅ [AUTH] GraphQL client refreshed with new auth
✅ [AUTH] Google sign-in successful for: user@example.com
✅ [AUTH] Linked providers: google
```

### Error Indicators:
```
❌ [AUTH] Platform exception: sign_in_failed
❌ [AUTH] Failed to obtain Google idToken
❌ [AUTH] GraphQL exception: ...
❌ [AUTH] Network/link error detected
❌ [AUTH] GraphQL error: ...
❌ [AUTH] User cancelled sign-in
```

---

## Testing on Real Devices

### Android Testing Requirements:
1. **Device with Google Play Services**:
   - Physical device preferred (emulators sometimes have issues)
   - Google Play Services must be up-to-date
   - Signed in to Google account

2. **SHA-1 Fingerprint**:
   - Debug builds use `~/.android/debug.keystore` SHA-1
   - Release builds use your release keystore SHA-1
   - Both must be added to Google Cloud Console

3. **Test Command**:
   ```bash
   flutter run --debug
   # or for release build:
   flutter build apk --release
   ```

### iOS Testing Requirements:
1. **Real Device Preferred**:
   - Simulator sometimes has OAuth issues
   - Must be signed in to iCloud/Apple ID

2. **Bundle ID**:
   - Must match the one in Google Cloud Console
   - Check `ios/Runner/Info.plist`: `CFBundleIdentifier`

3. **CocoaPods Setup**:
   ```bash
   cd ios
   pod install
   cd ..
   flutter run
   ```

**Reference**: Tasks T051, T052

---

## Environment Configuration

### Staging Environment (Current Default):
```env
VRON_API_URI=https://api.vron.stage.motorenflug.at
VRON_MERCHANTS_URL=https://app.vron.stage.motorenflug.at
APP_COOKIE_DOMAIN=.motorenflug.at
ENV=development
DEBUG=true
```

### Production Environment:
```env
VRON_API_URI=https://api.vron.motorenflug.at
VRON_MERCHANTS_URL=https://app.vron.motorenflug.at
APP_COOKIE_DOMAIN=.motorenflug.at
ENV=production
DEBUG=false
```

### Local Development (if backend runs locally):
```env
VRON_API_URI=http://localhost:4000
VRON_MERCHANTS_URL=http://localhost:3000
APP_COOKIE_DOMAIN=localhost
ENV=development
DEBUG=true
```

**Note**: Android emulator uses `10.0.2.2` to access host machine's localhost:
```env
VRON_API_URI=http://10.0.2.2:4000
```

---

## Verifying Implementation

### Check Implementation Status:
```bash
# View task completion status
cat specs/003-google-oauth-login/tasks.md | grep "^\- \[X\]" | wc -l

# Expected: 47+ tasks completed
```

### Run Tests:
```bash
# Unit tests
flutter test test/features/auth/services/auth_service_test.dart

# Integration tests (requires backend + real device)
flutter test test/integration/auth_flow_test.dart

# Expected: 8 tests passing, 4 skipped (Google OAuth unit tests)
```

### Verify Files Exist:
```bash
# Core implementation files
ls -la lib/features/auth/services/auth_service.dart
ls -la lib/features/auth/utils/oauth_error_mapper.dart
ls -la lib/features/auth/widgets/oauth_button.dart
ls -la lib/core/config/env_config.dart

# Platform configuration files (must be added manually)
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist
```

---

## Backend Integration Checklist

Confirm with backend team:

- [ ] `exchangeGoogleIdToken` GraphQL mutation is deployed
- [ ] Mutation follows contract in `specs/003-google-oauth-login/contracts/graphql-api.md`
- [ ] Backend validates Google idToken with Google's API
- [ ] Backend handles account creation/linking logic
- [ ] Backend returns JWT accessToken in correct format
- [ ] Backend uses Web OAuth Client ID for token verification
- [ ] Backend is accessible from mobile devices (CORS, network, etc.)

---

## Getting Help

If OAuth still isn't working after checking above:

1. **Capture Debug Logs**:
   - Enable `DEBUG=true` in `.env`
   - Reproduce the issue
   - Copy console output from when you tap "Sign in with Google" until error appears

2. **Check These Files**:
   - `.env` - Environment configuration
   - `android/app/google-services.json` - Android OAuth config
   - `ios/Runner/Info.plist` - iOS OAuth config (GIDClientID, CFBundleURLTypes)
   - Backend logs - Check for errors during token exchange

3. **Test Components Individually**:
   - Test Google Sign-In alone (does consent screen appear?)
   - Test backend GraphQL endpoint (is it reachable?)
   - Test with mock data (can you manually call the mutation?)

4. **Review PRD**:
   - See `Requirements/Google_OAuth.prd.md` Section 8 for Flutter integration
   - Confirm you're using Option B (Token-based SSO)

5. **Check Task List**:
   - See `specs/003-google-oauth-login/tasks.md`
   - Verify Phase 1 (T001-T009) is 100% complete
   - Platform configuration tasks CANNOT be skipped

---

## Next Steps After Resolution

Once OAuth is working:

1. **Test on Both Platforms**: Android and iOS real devices
2. **Test Edge Cases**: Network errors, cancellation, invalid tokens
3. **Verify Account Linking**: Sign in with email/password, then Google with same email
4. **Production Setup**: Configure production OAuth clients and environment
5. **Analytics**: Add tracking for OAuth success/failure rates (T055)

---

## Reference Documentation

- **PRD**: `Requirements/Google_OAuth.prd.md`
- **Tasks**: `specs/003-google-oauth-login/tasks.md`
- **GraphQL Contract**: `specs/003-google-oauth-login/contracts/graphql-api.md`
- **Google Sign-In Docs**: https://pub.dev/packages/google_sign_in
- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials
