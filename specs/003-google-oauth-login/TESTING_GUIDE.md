# Google OAuth Testing Guide

**Feature**: 003-google-oauth-login
**Status**: ✅ Ready for Device Testing
**Last Updated**: 2025-12-23

---

## ✅ Configuration Complete

All platform configuration is complete and verified:

### iOS Configuration:
- ✅ OAuth Client ID: `161042226580-klsi82nn94vm94bfs6jo364h2do3hr36.apps.googleusercontent.com`
- ✅ Web Client ID: `161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op.apps.googleusercontent.com`
- ✅ Bundle ID: `com.example.vronmobile2`
- ✅ `GoogleService-Info.plist` placed in `ios/Runner/`
- ✅ `Info.plist` configured with GIDClientID and CFBundleURLSchemes
- ✅ CocoaPods installed (15 pods)

### Android Configuration:
- ✅ OAuth Client ID: Created with package name and SHA-1
- ✅ Package Name: `com.example.vronmobile2`
- ✅ SHA-1 Fingerprint: `FA:0C:47:8B:E4:A4:41:AE:63:0A:BC:DE:2B:F1:CA:8C:DF:78:24:4E`
- ✅ `google-services.json` placed in `android/app/`

### Code Implementation:
- ✅ All 47 implementation tasks completed
- ✅ Tests passing: 8 passing, 4 skipped
- ✅ Environment variables configured (PRD-compliant)

---

## Testing Prerequisites

Before testing, verify:

### 1. Backend Deployment ⚠️ CRITICAL

The backend **must** have the `exchangeGoogleIdToken` GraphQL mutation deployed.

**Test Backend Availability**:
```bash
curl -X POST https://api.vron.stage.motorenflug.at/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { exchangeGoogleIdToken(input: { idToken: \"test\" }) }"}'
```

**Expected Response**: GraphQL error (invalid token) - NOT "field not found"

**If Backend Not Ready**:
- Contact backend team
- Reference: `specs/003-google-oauth-login/contracts/graphql-api.md`
- Backend must use Web Client ID: `161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op`

### 2. Device Requirements

**iOS Testing**:
- Real device or simulator with iOS 13.0+
- Signed in to iCloud/Apple ID
- Internet connectivity

**Android Testing**:
- Real device or emulator with Google Play Services
- Signed in to Google account
- Internet connectivity
- For real device: Must match SHA-1 fingerprint

---

## Testing Steps

### iOS Testing (T052)

1. **Build and Run**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run -d <ios-device-id>
   ```

2. **Test OAuth Flow**:
   - Launch app
   - Tap "Sign in with Google" button
   - **Expected**: Google consent screen appears
   - Select Google account
   - **Expected**: App exchanges token with backend
   - **Expected**: Navigate to home screen
   - **Expected**: User stays logged in on app restart

3. **Check Console Logs** (with DEBUG=true):
   ```
   🔐 [AUTH] Starting Google sign-in
   ✅ [AUTH] Google account obtained: user@example.com
   ✅ [AUTH] Google idToken obtained
   🔐 [AUTH] GraphQL mutation completed
   ✅ [AUTH] Received backend access token
   ✅ [AUTH] Tokens stored securely
   ✅ [AUTH] Google sign-in successful for: user@example.com
   ```

4. **Test Error Scenarios**:
   - Cancel OAuth flow → "Sign-in was cancelled"
   - Turn off WiFi → "Network error. Please check your connection"
   - Try with unverified email → Backend should reject

### Android Testing (T051)

1. **Build and Run**:
   ```bash
   flutter clean
   flutter pub get
   flutter run -d <android-device-id>
   ```

2. **Test OAuth Flow**:
   - Same steps as iOS above
   - Ensure Google Play Services is up-to-date
   - Check device has Google account signed in

3. **Common Android Issues**:

   **"PlatformException: sign_in_failed"**:
   - SHA-1 fingerprint mismatch
   - Verify: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Ensure SHA-1 matches Google Cloud Console: `FA:0C:47:8B:E4:A4:41:AE:63:0A:BC:DE:2B:F1:CA:8C:DF:78:24:4E`

   **"Google Play Services not available"**:
   - Update Google Play Services on device
   - Or test on different device/emulator

---

## Test Cases

### Happy Path (US1 - MVP):
- [T052/T051] User taps "Sign in with Google"
- [T052/T051] Google consent screen appears
- [T052/T051] User approves permissions
- [T052/T051] Backend exchanges idToken for JWT
- [T052/T051] User navigates to home screen
- [T052/T051] User remains logged in across restarts

**Success Criteria (SC-001)**: OAuth flow completes in under 30 seconds
**Success Criteria (SC-004)**: User remains logged in across app restarts

### Error Handling (US2):
- [T052/T051] User cancels → "Sign-in was cancelled"
- [T052/T051] Network error → "Network error. Please check your connection"
- [T052/T051] Backend error → "Sign-in failed. Please try again later"
- [T052/T051] Invalid token → "Authentication failed. Please try again"

**Success Criteria (SC-003)**: 95% of attempts show clear error or succeed
**Success Criteria (SC-006)**: Error messages are understandable

### Account Linking (US3):
- [ ] Create email/password account
- [ ] Sign in with Google using same email
- [ ] Verify account is linked (not duplicated)
- [ ] Both sign-in methods work

**Success Criteria (SC-005)**: Zero duplicate accounts for same email

---

## Troubleshooting During Testing

### Issue: OAuth Doesn't Start

**Symptoms**: Button does nothing, no Google screen appears

**Check**:
1. GoogleService-Info.plist exists (iOS)
2. google-services.json exists (Android)
3. Console shows any errors
4. Device has internet connectivity

**iOS Specific**:
- Check Info.plist has GIDClientID
- Check CFBundleURLSchemes is correct
- Run `cd ios && pod install`

**Android Specific**:
- Check google-services.json is in `android/app/`
- Check SHA-1 matches debug keystore
- Update Google Play Services on device

### Issue: "Invalid or expired Google token"

**Symptoms**: Google sign-in succeeds, but backend rejects token

**Causes**:
1. Backend not using correct Web Client ID for verification
2. Backend's `exchangeGoogleIdToken` mutation not deployed
3. Token validation failing on backend

**Solution**:
- Contact backend team
- Verify Web Client ID: `161042226580-8k8rpnr3tc0qj22og5nciep5vr4sn5op`
- Check backend logs for detailed error

### Issue: Network Error

**Symptoms**: "Network error. Please check your connection"

**Causes**:
1. Backend API not reachable from device
2. Device network issues
3. VPN/firewall blocking API

**Solution**:
```bash
# Test from same network as device:
curl -X POST https://api.vron.stage.motorenflug.at/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}'
```

### Issue: App Crashes After OAuth

**Symptoms**: App crashes after Google sign-in completes

**Check**:
1. Console logs for exception
2. GraphQL response format matches contract
3. Token storage permissions
4. Navigation route exists

---

## Performance Testing

### OAuth Flow Timing (SC-001):
- Start timer when user taps "Sign in with Google"
- Stop timer when home screen appears
- **Target**: < 30 seconds
- **Acceptable**: < 45 seconds with slow network

### Session Persistence (SC-004):
1. Sign in with Google
2. Navigate to home screen
3. Kill app completely (swipe away)
4. Relaunch app
5. **Expected**: User still logged in, no re-authentication needed

---

## Security Testing

### Token Handling:
- [ ] idToken not logged in production
- [ ] Tokens stored in flutter_secure_storage only
- [ ] Tokens cleared on sign out
- [ ] HTTPS enforced for all API calls

### Error Messages:
- [ ] Error messages don't expose sensitive data
- [ ] Invalid credentials don't reveal if email exists
- [ ] Backend errors sanitized for user display

---

## Accessibility Testing (SC-002, FR-011)

### Screen Reader (TalkBack/VoiceOver):
- [ ] "Sign in with Google" button announced correctly
- [ ] Button state (enabled/disabled) announced
- [ ] Loading state announced
- [ ] Error messages announced
- [ ] Navigation after sign-in accessible

### Touch Targets:
- [ ] OAuth button meets 44x44dp minimum size
- [ ] Button easily tappable without zoom

---

## Test Results Checklist

After completing device testing, verify:

### iOS (T052):
- [ ] OAuth flow works on iOS device
- [ ] Debug build: OAuth succeeds
- [ ] Release build: OAuth succeeds (requires different provisioning)
- [ ] Session persists across app restarts
- [ ] Error handling works (cancel, network error)
- [ ] Accessibility verified with VoiceOver

### Android (T051):
- [ ] OAuth flow works on Android device
- [ ] Debug build: OAuth succeeds (SHA-1 matches)
- [ ] Release build: Pending release keystore
- [ ] Session persists across app restarts
- [ ] Error handling works (cancel, network error)
- [ ] Accessibility verified with TalkBack

### Backend Integration:
- [ ] Backend mutation deployed and accessible
- [ ] Backend validates tokens correctly
- [ ] Account creation works (new user)
- [ ] Account linking works (existing user)
- [ ] Backend errors handled gracefully

---

## Known Limitations

### Unit Tests Skipped:
- Google OAuth unit tests skipped due to v7.0 singleton pattern
- Coverage provided by integration tests instead
- Email/password auth unit tests validate core logic

### Platform Configuration:
- Debug keystore SHA-1 only (release keystore pending)
- Package names use `com.example.*` (change before production)
- Bundle ID uses `com.example.*` (change before production)

---

## Next Steps After Testing

### If OAuth Works:
1. ✅ Mark T051 and T052 as complete
2. Update STATUS.md with test results
3. Coordinate with backend for production deployment
4. Plan production OAuth client setup (new package names)
5. Consider analytics implementation (T055)

### If OAuth Fails:
1. Check TROUBLESHOOTING.md for common issues
2. Review console logs with DEBUG=true
3. Test backend GraphQL endpoint directly
4. Verify Google Cloud Console configuration
5. Contact backend team if token validation fails

---

## Production Readiness Checklist

Before deploying to production:

### Code:
- [ ] Change package names from `com.example.*`
- [ ] Update bundle IDs with company domain
- [ ] Set DEBUG=false in .env for production
- [ ] Remove debug logging from production builds

### OAuth Clients:
- [ ] Create production OAuth clients with new package names
- [ ] Add release keystore SHA-1 to Android OAuth client
- [ ] Update environment to production URLs
- [ ] Download new GoogleService-Info.plist and google-services.json

### Backend:
- [ ] exchangeGoogleIdToken mutation deployed to production
- [ ] Rate limiting configured
- [ ] Logging and monitoring set up
- [ ] Production Web Client ID configured

### Testing:
- [ ] Test on production environment
- [ ] Verify session persistence
- [ ] Test error scenarios
- [ ] Load testing (if expected high volume)

---

## Support

**Documentation**:
- Implementation: `specs/003-google-oauth-login/STATUS.md`
- Troubleshooting: `specs/003-google-oauth-login/TROUBLESHOOTING.md`
- Backend Contract: `specs/003-google-oauth-login/contracts/graphql-api.md`
- PRD: `Requirements/Google_OAuth.prd.md`

**Debug Logs**:
Enable `DEBUG=true` in `.env` for verbose logging during testing.

**Google Cloud Console**:
https://console.cloud.google.com/apis/credentials

**Test Backend**:
```bash
curl -X POST https://api.vron.stage.motorenflug.at/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { exchangeGoogleIdToken(input: { idToken: \"test\" }) }"}'
```
