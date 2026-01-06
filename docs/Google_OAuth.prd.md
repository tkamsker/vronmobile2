# Product Requirements Document: Google OAuth Integration

**Version:** 1.0
**Status:** In Review
**Author:** Gemini AI Assistant

---

## 1. Objective

This document outlines the requirements for implementing a complete "Sign in with Google" feature. The goal is to provide users with a fast, secure, and familiar way to sign up and log in, reducing friction and improving the user experience. This integration will leverage the existing authentication infrastructure, including JWTs and the current user database.

## 2. Problem Statement & User Stories

Creating and remembering a new password for every service is a burden for users. By integrating Google OAuth, we can streamline the authentication process.

-   **As a new user,** I want to sign up and sign in with my Google account in one click so that I don't have to fill out a form or remember another password.
-   **As an existing user (with an email/password account),** I want to link my Google account so I can have the flexibility of logging in with either method.

## 3. Technical Requirements & Flow

The application currently uses a server-side OAuth flow. The frontend redirects the user to the main backend's Google OAuth endpoint, which then handles the interaction with Google.

> **Note:** This section has been aligned with the actual implementation in this repository  
> (see `containers/auth/sign-in/index.tsx` and `containers/auth/sign-up/index.tsx`).

### High-Level Flow:

1.  **Initiation:** The user clicks "Sign in with Google" on the frontend.
2.  **Redirect to Backend:** The frontend redirects the user to  
    `[VRON_API_URI]/auth/google?role=MERCHANT&preferredLanguage=<LANG>&redirectUrl=<FRONTEND_CALLBACK_URL>`.
3.  **Google Authentication:** The backend redirects the user to Google's consent screen.
4.  **Callback to Backend:** After user approval, Google redirects back to the backend with an `authorization code`.
5.  **Token Exchange:** The backend exchanges the `authorization code` for a Google `id_token` and `access_token`.
6.  **User Verification:** The backend verifies the `id_token`'s signature and payload.
7.  **GraphQL Mutation:** The backend internally calls a new GraphQL mutation to handle user provisioning and session creation.
8.  **Session Creation:** Upon successful authentication via the mutation, a JWT `accessToken` is generated, identical in format to the one from the email/password flow.
9.  **Redirect to Frontend:** The backend redirects the user back to the frontend's callback URL (e.g. `/oauth`), setting the `auth` cookie containing the `accessToken`.

### 3.1. Concrete Web Flow in This Repository

In the merchants web app (Next.js), the Google button builds the OAuth URL like this:

```ts
// containers/auth/sign-in/index.tsx (simplified)
const onGoogleClick = () => {
  const url = `${env.VRON_API_URI}/auth/google` +
    `?role=MERCHANT` +
    `&preferredLanguage=${preferredLanguage}` +
    `&redirectUrl=${encodeURIComponent(window.location.origin)}/oauth`;

  window.location.href = url;
};
```

Environment variables (see `env.ts` and `.env.local`):

```env
NEXT_PUBLIC_VRON_API_URI=https://api.vron.stage.motorenflug.at
NEXT_PUBLIC_VR_APP_URL=https://vr.vron.stage.motorenflug.at
NEXT_PUBLIC_VRON_MERCHANTS_URL=https://app.vron.stage.motorenflug.at
NEXT_PUBLIC_APP_COOKIE_DOMAIN=.motorenflug.at
```

So for staging, the actual URL the web client opens is:

```text
https://api.vron.stage.motorenflug.at/auth/google?role=MERCHANT&preferredLanguage=EN&redirectUrl=https%3A%2F%2Fapp.vron.stage.motorenflug.at%2Foauth
```

The backend then:
- talks to Google,
- creates/links the VRon user,
- sets the `auth` HTTP-only cookie for `.motorenflug.at`,
- and finally redirects the browser to `/oauth` on the merchants web app.

## 4. GraphQL API Contract

To handle the user provisioning logic cleanly, a new mutation will be introduced. The backend's OAuth callback handler will be responsible for calling this mutation after successfully verifying the token from Google.

### Mutation

```graphql
# mutation SignInWithGoogle($idToken: String!) {
#   signInWithGoogle(idToken: $idToken) {
#     accessToken
#     user {
#       id
#       email
#       # ... other user fields
#     }
#   }
# }

mutation SignInWithGoogle($idToken: String!) {
  signInWithGoogle(idToken: $idToken) {
    ...AuthPayloadFields
  }
}
```

-   **`idToken` (String!):** The JWT ID token received from Google after the code-for-token exchange. This token contains the user's profile information (email, name, etc.).

### User & Account Logic

The `signInWithGoogle` resolver must handle two core scenarios:

1.  **Existing User (Account Linking):**
    -   The resolver decodes the `idToken` to get the user's email address.
    -   It searches for an existing user in the PostgreSQL database with that email.
    -   If a user exists and their account is **not** already linked to a Google provider, it links this new Google ID to the existing user record.
    -   A new `accessToken` for the user is generated and returned.

2.  **New User (Account Creation):**
    -   If no user exists with the email from the `idToken`, a new user account is created.
    -   The user record should be populated with the name, email, and profile picture URL from the Google token payload.
    -   A new `accessToken` for the new user is generated and returned.

### Error Handling

The mutation should return standard GraphQL errors for failure cases:

-   `INVALID_TOKEN`: If the Google `idToken` is expired, malformed, or has an invalid signature.
-   `ACCOUNT_ALREADY_LINKED`: If the user's Google account is already associated with a different local user.
-   `EMAIL_TAKEN_BY_OTHER_PROVIDER`: If a user with that email exists but is associated with a different OAuth provider (e.g., Facebook, if added in the future).

---

## 5. API Versioning

-   **Current Version:** N/A (this is a new endpoint).
-   **Future Considerations:** If breaking changes are needed in the future, we will create a versioned mutation (e.g., `signInWithGoogleV2`) and follow a standard deprecation lifecycle for the old version, documenting all changes in the API changelog.

---

## 6. Backend Reference Implementation Notes

This contract assumes the backend will:
1.  Use a standard library for Google token verification (e.g., `google-auth-library` for Node.js).
2.  Store user accounts in the existing PostgreSQL database.
3.  Generate JWT tokens using the existing authentication infrastructure, ensuring the token format is identical to the one from email/password login.
4.  Implement the account creation and linking logic as described above.

---

## 7. Open Questions for Backend Team

1.  **OAuth Client ID:** Which Google OAuth Client ID and Secret should be used for the token verification process on the backend?
2.  **Token Expiration:** What is the desired expiration time for the `accessToken` generated by our system after a successful Google sign-in?
3.  **User Creation:** Are there any additional mandatory fields that must be populated when creating a new user via OAuth?
4.  **Account Linking:** Should we send a notification email to the user when their existing account is linked to a new sign-in provider (Google)?
5.  **Rate Limiting:** What rate-limiting thresholds should be enforced on the initial OAuth redirect endpoint and the GraphQL mutation?
6.  **Monitoring:** Are there specific metrics, events, or logs we need to track for monitoring the health and usage of the Google OAuth sign-in feature?

---

## 8. Flutter Mobile Client Integration (Google SSO)

This section describes how a **native Flutter app** can implement Google SSO using the same backend contracts and environment that the web app uses.

There are two realistic integration options:

1. **Browser-based SSO (recommended short-term, minimal backend changes)**
2. **Token-based SSO using `signInWithGoogle` GraphQL mutation (requires backend work from this PRD)**

### 8.1. Shared Assumptions & Environment

The Flutter app talks to the same backend as the web app:

```env
VRON_API_URI=https://api.vron.stage.motorenflug.at         # from NEXT_PUBLIC_VRON_API_URI
VRON_MERCHANTS_URL=https://app.vron.stage.motorenflug.at   # from NEXT_PUBLIC_VRON_MERCHANTS_URL
APP_COOKIE_DOMAIN=.motorenflug.at                          # from NEXT_PUBLIC_APP_COOKIE_DOMAIN
```

For examples below we will use:

- `VRON_API_URI = https://api.vron.stage.motorenflug.at`
- `VRON_MERCHANTS_URL = https://app.vron.stage.motorenflug.at`

The relevant backend endpoint is:

```text
GET https://api.vron.stage.motorenflug.at/auth/google
```

with query parameters:

- `role=MERCHANT`
- `preferredLanguage=EN | DE | PT`
- `redirectUrl=<URL-encoded callback URL>`

### 8.2. Option A – Browser-based SSO from Flutter

This option reuses the **existing web OAuth flow** and is ideal if:

- you are embedding or launching the merchants web app from Flutter, and
- you are fine with authentication living in the system browser / webview (via HTTP-only cookies).

#### 8.2.1. High-level Flow (Flutter)

1. User taps **“Sign in with Google”** in the Flutter app.
2. Flutter opens the system browser or an in-app browser (Chrome Custom Tabs / SFSafariViewController) with:

   ```text
   https://api.vron.stage.motorenflug.at/auth/google
     ?role=MERCHANT
     &preferredLanguage=EN
     &redirectUrl=<URL-ENCODED-FRONTEND-CALLBACK-URL>
   ```

3. The backend completes the Google OAuth flow and sets the `auth` cookie for `.motorenflug.at`.
4. Backend redirects to the **merchants web app** (e.g. `https://app.vron.stage.motorenflug.at/oauth`).
5. From that point on, any web content loaded under `*.motorenflug.at` in that browser/webview will be authenticated.

This is a good fit if your Flutter app:
- primarily hosts the existing web UI in a WebView, **or**
- just wants to “hand off” the user into the web app after login.

#### 8.2.2. Example URL Construction (Flutter)

```dart
const vronApiUri = 'https://api.vron.stage.motorenflug.at';
const merchantsWebUrl = 'https://app.vron.stage.motorenflug.at';

String buildGoogleOAuthUrl({
  required String preferredLanguage, // 'EN', 'DE', 'PT'
}) {
  final redirectUrl = Uri.encodeComponent('$merchantsWebUrl/oauth');

  return '$vronApiUri/auth/google'
      '?role=MERCHANT'
      '&preferredLanguage=$preferredLanguage'
      '&redirectUrl=$redirectUrl';
}
```

To launch this URL from Flutter you can use `url_launcher`:

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> startGoogleLogin() async {
  final url = buildGoogleOAuthUrl(preferredLanguage: 'EN');
  final uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // TODO: handle error (e.g. show snackbar)
  }
}
```

**Important:** in this model the Flutter app itself **does not get direct access to the JWT / HTTP-only cookies**. The authenticated session “lives” in the browser context. If you need to call GraphQL directly from Flutter (without a webview), use **Option B** below.

### 8.3. Option B – Native Token-based SSO (recommended for pure Flutter clients)

This option is designed for a **pure native Flutter client** that:

- uses the Google Sign-In SDKs directly from Flutter,
- obtains a Google `idToken` on-device, and
- exchanges it with the VRon GraphQL backend via the `signInWithGoogle` mutation defined earlier.

#### 8.3.1. High-level Flow (Flutter)

1. User taps **“Sign in with Google”** in the Flutter app.
2. Flutter uses `google_sign_in` (Android/iOS) to obtain a Google `idToken`.
3. Flutter calls the GraphQL mutation:

   ```graphql
   mutation SignInWithGoogle($idToken: String!) {
     signInWithGoogle(idToken: $idToken) {
       ...AuthPayloadFields  # includes 'accessToken' and 'user'
     }
   }
   ```

4. Backend verifies the Google token, creates/links the user, and returns an **application `accessToken`** (JWT).
5. Flutter stores `accessToken` securely (e.g. `flutter_secure_storage`) and uses it as:

   ```http
   Authorization: Bearer <accessToken>
   X-VRon-Platform: merchants
   ```

   on all subsequent GraphQL calls to:

   ```text
   POST https://api.vron.stage.motorenflug.at/graphql
   ```

#### 8.3.2. Example Flutter Pseudocode

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

const graphqlEndpoint = 'https://api.vron.stage.motorenflug.at/graphql';

final HttpLink httpLink = HttpLink(graphqlEndpoint);

// Will be updated once we have an accessToken
AuthLink? authLink;

Link buildLink() {
  if (authLink == null) return httpLink;
  return authLink!.concat(httpLink);
}

late GraphQLClient client;

void initClient([String? accessToken]) {
  if (accessToken != null) {
    authLink = AuthLink(
      getToken: () async => 'Bearer $accessToken',
      headerKey: 'Authorization',
    );
  }

  client = GraphQLClient(
    link: buildLink(),
    cache: GraphQLCache(),
  );
}

const String signInWithGoogleMutation = r'''
  mutation SignInWithGoogle($idToken: String!) {
    signInWithGoogle(idToken: $idToken) {
      accessToken
      user {
        id
        email
      }
    }
  }
''';

Future<void> signInWithGoogleFromFlutter() async {
  // Step 1: Google sign-in on device
  final googleUser = await _googleSignIn.signIn();
  if (googleUser == null) {
    // user cancelled
    return;
  }

  final googleAuth = await googleUser.authentication;
  final idToken = googleAuth.idToken;
  if (idToken == null) {
    throw Exception('Missing idToken from Google');
  }

  // Step 2: Exchange idToken with VRon backend via GraphQL
  final result = await client.mutate(
    MutationOptions(
      document: gql(signInWithGoogleMutation),
      variables: {'idToken': idToken},
    ),
  );

  if (result.hasException) {
    // TODO: map GraphQL errors (e.g. INVALID_TOKEN, ACCOUNT_ALREADY_LINKED, etc.)
    throw result.exception!;
  }

  final data = result.data!['signInWithGoogle'] as Map<String, dynamic>;
  final accessToken = data['accessToken'] as String;

  // Step 3: Store accessToken securely and re-init client with auth
  // await secureStorage.write(key: 'accessToken', value: accessToken);

  initClient(accessToken);
}
```

#### 8.3.3. Error Handling (Flutter)

The backend mutation is expected to surface the following error codes (as GraphQL errors):

- `INVALID_TOKEN` – invalid / expired Google token
- `ACCOUNT_ALREADY_LINKED` – this Google account is already linked to another user
- `EMAIL_TAKEN_BY_OTHER_PROVIDER` – email exists but with a different provider

Flutter should:

- inspect `result.exception?.graphqlErrors`,
- map `error.extensions['code']` (or similar) to user-friendly messages,
- follow the same UX tone/messages as defined in `messages/en.json` where possible.

### 8.4. Choosing Between Option A and Option B

- Use **Option A (Browser-based SSO)** if:
  - you mainly want to drop users into the existing web merchants app from Flutter, and
  - you do not need the JWT inside the Flutter process.

- Use **Option B (Token-based SSO)** if:
  - Flutter is a first-class client,
  - you want to call the VRon GraphQL API directly from Flutter, and
  - you can coordinate with the backend team to implement the `signInWithGoogle` mutation as specified above.

---

## 9. Next Steps

1.  [✅] GraphQL contract defined.
2.  [✅] Web OAuth integration implemented (`/auth/google` with `redirectUrl`).
3.  [⚠️] **UPDATED 2026-01-06**: Backend team has implemented redirect-based mobile OAuth flow
    - Mobile apps now use `/auth/google` endpoint with `fromMobile=true` parameter
    - Backend returns authorization code via deep link callback
    - New mutation `exchangeMobileAuthCode` replaces `signInWithGoogle` for mobile clients
    - See updated specification in `specs/003-google-oauth-login/` for details
4.  [➡️] Flutter team implements redirect-based mobile OAuth flow (Option A variant for mobile)
5.  [➡️] Frontend (web) and mobile clients + Backend conduct integration testing on a staging environment.
6.  [ ] Documentation updated with final backend error formats and monitoring/metrics guidelines.

---

## 10. Mobile Implementation Update (2026-01-06)

**Breaking Change**: The mobile implementation has been updated to use a redirect-based OAuth flow instead of the native SDK token-based approach (Option B).

### New Mobile Flow

1. User taps "Sign in with Google" in Flutter app
2. App redirects to: `https://api.vron.stage.motorenflug.at/auth/google?role=MERCHANT&preferredLanguage=EN&redirectUrl={DEEP_LINK}&fromMobile=true`
3. Backend handles OAuth with Google (user sees consent screen)
4. Backend redirects back to app via deep link:
   - Success: `{DEEP_LINK}?code={AUTHORIZATION_CODE}`
   - Error: `{DEEP_LINK}?error={ERROR_CODE}`
5. App receives deep link callback and extracts code or error
6. If code received, app calls new GraphQL mutation:
   ```graphql
   mutation ExchangeMobileAuthCode($input: ExchangeMobileAuthCodeInput!) {
     exchangeMobileAuthCode(input: $input) {
       accessToken
     }
   }
   ```
7. Backend validates code and returns accessToken
8. App stores token and completes authentication

### Key Differences from Option B

- **No Google Sign-In SDK required** (can remove `google_sign_in` dependency)
- **Backend handles OAuth flow** entirely (no client-side token validation)
- **Uses deep links** for callback instead of in-app token exchange
- **Authorization code** is single-use and short-lived (5-10 minutes)
- **Simplified mobile implementation** - no platform-specific OAuth configuration needed

### Migration Path

For existing implementations using Option B:
1. Remove dependency on `google_sign_in` package (or keep for other features)
2. Implement deep link handling for OAuth callbacks
3. Replace `signInWithGoogle` mutation with `exchangeMobileAuthCode`
4. Update UI to launch browser/web view for OAuth redirect
5. Update error handling for redirect-based flow
6. Re-test entire OAuth flow end-to-end

See `specs/003-google-oauth-login/spec.md` and `specs/003-google-oauth-login/contracts/graphql-api.md` for complete updated specifications.

