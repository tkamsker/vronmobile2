# Backend Token Issue: Cookie vs Token Response

**Date**: 2025-12-23
**Issue**: Backend returns token as cookie instead of in GraphQL response
**Status**: ✅ RESOLVED - Using `exchangeGoogleIdToken` mutation

**Resolution**: This issue led to the creation of `exchangeGoogleIdToken` mutation which returns the accessToken as a String directly in the GraphQL response, suitable for mobile apps.

---

## Problem Summary (Historical)

The original `signInWithGoogle` GraphQL mutation was setting the `accessToken` as an **HTTP-only cookie** instead of returning it in the GraphQL response body. This was resolved by creating a dedicated `exchangeGoogleIdToken` mutation for mobile clients.

**Current Backend Behavior** (❌ Wrong for mobile):
```
Request: mutation { signInWithGoogle(input: { idToken }) }

Response:
HTTP/1.1 200 OK
Set-Cookie: auth=<TOKEN>; HttpOnly; Secure

{
  "data": {
    "signInWithGoogle": {
      // ❌ Missing: accessToken field
      "user": { ... }
    }
  }
}
```

**Expected Backend Behavior** (✅ Correct for mobile):
```
Request: mutation { signInWithGoogle(input: { idToken }) }

Response:
HTTP/1.1 200 OK

{
  "data": {
    "signInWithGoogle": {
      "accessToken": "eyJhbGc...",  // ✅ Token in response body
      "user": { ... }
    }
  }
}
```

---

## Why This Is a Problem

### For Web/Browser Clients (Option A):
✅ **Cookies work fine** because:
- Browser automatically stores cookies
- Browser automatically sends cookies with each request
- HTTP-only cookies protect against XSS

### For Native Mobile Apps (Option B):
❌ **Cookies DON'T work** because:
- HTTP-only cookies can't be read by the app
- Mobile apps need to store tokens in secure storage
- Mobile apps need explicit token for Authorization header
- GraphQL client doesn't automatically handle cookies

---

## The Two OAuth Flows (from PRD)

### Option A: Browser-based SSO (Web Apps)
**Flow**:
1. Frontend redirects to `/auth/google`
2. Backend handles OAuth with Google
3. Backend sets `auth` cookie
4. Backend redirects back to frontend
5. Browser uses cookie for authenticated requests

**Token Delivery**: HTTP-only cookie
**Used By**: Web applications (merchants web app)

### Option B: Token-based SSO (Native Mobile Apps)
**Flow**:
1. Mobile app uses Google Sign-In SDK
2. Mobile app gets `idToken` from Google
3. Mobile app calls GraphQL mutation `signInWithGoogle(idToken)`
4. **Backend returns `accessToken` in GraphQL response**
5. Mobile app stores token in secure storage
6. Mobile app uses token in Authorization header

**Token Delivery**: GraphQL response body
**Used By**: Native mobile apps (iOS, Android)

---

## Current Mobile Implementation

The Flutter mobile app is correctly implementing **Option B**:

```dart
// Mobile app flow
final GoogleSignInAccount googleAccount = await googleSignIn.authenticate();
final googleAuth = googleAccount.authentication;
final idToken = googleAuth.idToken;

// Call backend GraphQL mutation
final result = await graphqlService.mutate(
  signInWithGoogleMutation,
  variables: {'input': {'idToken': idToken}},
);

// Extract accessToken from response
final accessToken = result.data['signInWithGoogle']['accessToken']; // ❌ NULL!

// Store token
await tokenStorage.saveAccessToken(accessToken);

// Use token in future requests
// Authorization: Bearer <accessToken>
```

**Problem**: `result.data['signInWithGoogle']['accessToken']` is `null` because the backend isn't returning it.

---

## Backend Fix Required

### Current Backend Code (Wrong):

```typescript
// ❌ WRONG - Sets cookie but doesn't return token
async signInWithGoogle(idToken: string) {
  // Verify token with Google
  const payload = await verifyGoogleToken(idToken);

  // Create/link user
  const user = await createOrLinkUser(payload);

  // Generate JWT
  const accessToken = generateJWT(user);

  // Set cookie (for web clients)
  response.cookie('auth', accessToken, {
    httpOnly: true,
    secure: true,
    domain: '.motorenflug.at'
  });

  // Return user only (missing accessToken!)
  return {
    user: user
  };
}
```

### Fixed Backend Code (Correct):

```typescript
// ✅ CORRECT - Returns token in response AND sets cookie
async signInWithGoogle(idToken: string) {
  // Verify token with Google
  const payload = await verifyGoogleToken(idToken);

  // Create/link user
  const user = await createOrLinkUser(payload);

  // Generate JWT
  const accessToken = generateJWT(user);

  // Set cookie (for web clients) - OPTIONAL for mobile
  response.cookie('auth', accessToken, {
    httpOnly: true,
    secure: true,
    domain: '.motorenflug.at'
  });

  // Return BOTH user AND accessToken (for mobile clients)
  return {
    accessToken: accessToken,  // ✅ Add this!
    user: user
  };
}
```

---

## GraphQL Schema

The schema should include `accessToken` in the response type:

```graphql
type SignInWithGoogleResponse {
  """
  Application JWT access token for authenticating subsequent API requests
  REQUIRED for native mobile apps
  """
  accessToken: String!

  """
  User account information
  """
  user: User!
}

type Mutation {
  signInWithGoogle(input: SignInWithGoogleInput!): SignInWithGoogleResponse!
}
```

**Reference**: See `specs/003-google-oauth-login/contracts/graphql-api.md`

---

## Why Return Token AND Set Cookie?

You can do **both** to support **both** web and mobile clients:

```typescript
// Support both web (cookie) and mobile (token) clients
return {
  accessToken: accessToken,  // For mobile apps (Option B)
  user: user
};

// Cookie is set automatically by your web framework
// Web clients ignore the accessToken field and use cookie
// Mobile clients ignore the cookie and use accessToken field
```

This way:
- ✅ Web apps continue using cookies (no changes needed)
- ✅ Mobile apps can read the accessToken from response
- ✅ Single backend endpoint supports both client types

---

## Testing the Fix

### Test with cURL:

```bash
# Get a real idToken from mobile app first, then test:
curl -X POST https://api.vron.stage.motorenflug.at/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation SignInWithGoogle($input: SignInWithGoogleInput!) { signInWithGoogle(input: $input) { accessToken user { id email } } }",
    "variables": {
      "input": {
        "idToken": "REAL_GOOGLE_ID_TOKEN_HERE"
      }
    }
  }'
```

**Expected Response**:
```json
{
  "data": {
    "signInWithGoogle": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "user": {
        "id": "123",
        "email": "user@example.com"
      }
    }
  }
}
```

### Test from Mobile App:

After backend fix, the mobile app debug logs should show:

```
✅ [AUTH] Backend access token received
   Token preview: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Token length: 234 characters

✅ [AUTH] Tokens stored securely
✅ [AUTH] GraphQL client refreshed with new auth

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GOOGLE OAUTH SUCCESS!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Alternative: Mobile-Specific Endpoint (Not Recommended)

If you can't modify the existing mutation, you could create a mobile-specific one:

```graphql
type Mutation {
  signInWithGoogle(input: SignInWithGoogleInput!): SignInWithGoogleResponse!
  signInWithGoogleMobile(input: SignInWithGoogleInput!): SignInWithGoogleMobileResponse!
}

type SignInWithGoogleMobileResponse {
  accessToken: String!  # Always returns token
  user: User!
}
```

But this is **not recommended** because:
- ❌ Code duplication
- ❌ Two endpoints to maintain
- ❌ Inconsistent API surface

Better to fix the existing mutation to work for both web and mobile.

---

## Summary for Backend Team

### What to Change:

1. ✅ Keep existing cookie-setting logic (for web clients)
2. ✅ **ADD** `accessToken` to GraphQL response (for mobile clients)
3. ✅ Update GraphQL schema to include `accessToken: String!`
4. ✅ Test that both web and mobile flows work

### What NOT to Change:

- ❌ Don't remove cookie setting (web apps need it)
- ❌ Don't create a separate mobile endpoint
- ❌ Don't change the mutation signature
- ❌ Don't change user creation/linking logic

### One-Line Fix:

Add this to your resolver:
```typescript
return {
  accessToken: accessToken,  // Add this line
  user: user
};
```

That's it! 🎉

---

## Impact

### Before Fix:
- ✅ Web OAuth works
- ❌ Mobile OAuth fails (can't read cookie)
- ❌ Mobile users can't sign in with Google

### After Fix:
- ✅ Web OAuth works (uses cookie)
- ✅ Mobile OAuth works (uses accessToken from response)
- ✅ Both client types supported by single endpoint

---

## Questions?

Contact the mobile team:
- Implementation: `lib/features/auth/services/auth_service.dart`
- Contract: `specs/003-google-oauth-login/contracts/graphql-api.md`
- PRD: `Requirements/Google_OAuth.prd.md` (Section 8.3 - Option B)

**Mobile app is ready and waiting for backend fix!** 🚀

---

## ✅ Current Solution (Implemented)

The issue described above was resolved by implementing the `exchangeGoogleIdToken` mutation:

### Current Implementation:

```graphql
mutation ExchangeGoogleIdToken($input: ExchangeGoogleIdTokenInput!) {
  exchangeGoogleIdToken(input: $input)
}
```

**Response**: String (accessToken directly, not an object)

**Key Changes**:
1. ✅ New mutation `exchangeGoogleIdToken` specifically for mobile apps
2. ✅ Returns accessToken as String directly in GraphQL response
3. ✅ User profile data obtained from Google Sign-In SDK on client side
4. ✅ No cookie dependency for mobile clients
5. ✅ Backend validates idToken with Google's API

**Contract**: See `specs/003-google-oauth-login/contracts/graphql-api.md` for complete specification.

**Mobile Implementation**: `lib/features/auth/services/auth_service.dart:299` (signInWithGoogle method)
