# Login and Registration API Integration

Verified on: 2026-09-18 (Asia/Bangkok)

## Evidence

- Live Swagger UI and `/swagger/v1/swagger.json` both returned HTTP 200.
- The live OpenAPI document still has SHA-256 `a2079ec3f6b5ace0d6bb1b82a3ec697cfc25b6d762c46c2afd42c4a088c53de4` and 69 operations.
- The live document publishes request schemas but no usable response schemas for either Auth operation.
- Response DTOs below are therefore backed by the read-only backend source at revision `959cad6567ba0101e7fed00c3384948f51c0f47d`, plus the explicitly observed error responses. They are not generated from speculative Swagger responses.

## Existing architecture

The existing flow is retained:

```text
Login/Register Widget
→ Riverpod controller
→ AuthRepository
→ centralized ApiClient/Dio
→ source-backed DTO parsing
→ TokenStorage/AuthSessionController
→ go_router redirect
```

There is one Auth repository and one pair of Login/Register controllers. Widgets do not call Dio directly. `ApiClient` obtains the base origin from `AppConfig`, attaches Bearer tokens from `TokenStorage`, and maps failures centrally.

## Login

### Contract

- Method/route: `POST /api/Auth/login`
- Authentication: public in backend source
- Required JSON fields: `email`, `password`
- Source-backed success envelope: `statusCode`, `isSuccess`, optional `errorMessage`, optional `errors`, and `result`
- Source-backed result fields: `accessToken`, `userId`, `email`, `fullName`, `role`
- Source roles: `Learner`, `ContentAuthor`, `Consultant`, `Admin`

The mobile repository accepts only the exact `Learner` role and stores the access token only after that gate. No refresh token field or refresh flow exists.

### Runtime result

The Android 17 emulator loaded `.env` through `--dart-define-from-file=.env`, started successfully, rendered Login, and reached the configured HTTP development origin.

An intentionally nonexistent `.invalid` account produced the observed live response:

```json
{
  "statusCode": 400,
  "isSuccess": false,
  "errorMessage": "Email hoặc mật khẩu không đúng."
}
```

The app mapped this to controlled Vietnamese UI feedback. Application-process logs contained only request method, path, and status metadata; no password, request body, Authorization header, or access token was logged.

A valid Login was not attempted because no safe test credentials were provided. Consequently, successful live response parsing, persisted-session restoration after a real Login, and authenticated live routing were not manually claimed. Their frontend behavior remains covered by repository, secure-storage, session-controller, screen, and router tests.

## Register

### Contract

- Method/route: `POST /api/Auth/register`
- Authentication: public in backend source
- Required JSON fields: `email`, `password`, `confirmPassword`
- Optional nullable JSON fields: `firstName`, `lastName`
- `password` minimum length: 6
- `confirmPassword` must equal `password`
- Source-backed result fields: `fullName`, `email`
- Source success status: HTTP 201 through the `ApiResponse<RegisterResponse>` envelope

Registration always creates a `Learner`, sends an email-verification code, and does not log the new account in. The Flutter success state therefore shows verification guidance and does not authenticate the session.

### Runtime result

No successful Register request was made because no safe test inbox/address was provided and the backend persists the account before attempting email delivery. A non-mutating malformed request reached the live endpoint and returned HTTP 400 ASP.NET validation-problem JSON with field errors for `Email`, `Password`, and `ConfirmPassword`. The centralized HTTP status mapping safely classifies that response as validation failure.

The deployed Swagger still provides no typed success response. Backend source still returns only `fullName` and `email`; it does not return the `userId` required by the later email-verification request. The frontend does not fabricate that identifier.

## Session, routing, and errors

- Persistent tokens use `flutter_secure_storage`; session-only Login remains memory-only and deletes an older persisted token.
- Startup begins in `unknown`, restores the stored access token, then becomes `authenticated` or `unauthenticated`.
- Successful Login marks the session authenticated; `go_router` then enters `/home`.
- Local logout clears memory and secure storage. It does not claim backend token revocation.
- Network/timeout, 400, 401, 403, 500, and unexpected-body paths use centralized error types and learner-safe UI messages.
- The development emulator reached the plain-HTTP host with the current Android configuration. No cleartext or production network-security relaxation was added.

## Confirmed gaps

- No refresh-token endpoint or response field.
- No logout/token-revocation endpoint.
- No forgot/reset-password endpoint.
- No safe resend-verification endpoint.
- Register does not return `userId`, so an in-app verification handoff cannot be constructed from the current contract.
- Live Swagger does not publish Login/Register response schemas or accurate operation status contracts.
- Valid Login, successful Register, duplicate-email runtime behavior, real session restart, and real logout remain unverified manually because no safe test account was supplied.

## Changes in Priority Phase A1

No application runtime fix was necessary: the tested invalid-Login path worked through the existing architecture. Regression coverage was strengthened for exact repository paths/payloads, registration without session creation or fabricated `userId`, duplicate-email UI handling, unexpected Login bodies, token persistence, role gating, and session routing.
