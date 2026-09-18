# RikiPath Auth Flow Completion

Reviewed on: 2026-09-18 (Asia/Bangkok)

## Contract evidence

- Live OpenAPI: `http://140.245.43.97/swagger/v1/swagger.json`
- Live snapshot SHA-256: `a2079ec3f6b5ace0d6bb1b82a3ec697cfc25b6d762c46c2afd42c4a088c53de4`
- Read-only backend revision: `959cad6567ba0101e7fed00c3384948f51c0f47d`
- Live Auth operations: exactly five (`register`, `verify-email`, `login`, `update-email/{userId}`, and `change-password/{userId}`)
- Live OpenAPI still publishes no typed success response bodies. Response envelopes and result DTOs remain source-backed.

## Auth endpoint audit matrix

| Endpoint | Repository | Controller | UI | Route | API wired | Tests | Status |
|---|---|---|---|---|---|---|---|
| `POST /api/Auth/register` | Existing | Existing | Existing Sakura Register | `/auth/register` | Yes | DTO, repository, validation, loading, payload, success, no session | COMPLETE_NOT_LIVE_MUTATION_TESTED |
| `POST /api/Auth/verify-email` | Added | Added | Added code, loading, invalid-code, success, and blocked-handoff states | `/auth/verify-email` | Yes when `userId` is known | DTO, repository, validation, loading, failure, success, missing handoff | BLOCKED_BY_BACKEND |
| `POST /api/Auth/login` | Existing | Existing | Existing Sakura Login | `/auth/login` | Yes | Request, failure, role gate, persistence, loading, routing | COMPLETE_NOT_LIVE_MUTATION_TESTED |
| `PUT /api/Auth/update-email/{userId}` | Added | Added | Added authenticated account form | `/profile/change-email` | Yes, current session ID only | DTO, path/body, session ID, loading, error, success | COMPLETE_NOT_LIVE_MUTATION_TESTED |
| `POST /api/Auth/change-password/{userId}` | Added | Added | Added authenticated account form | `/profile/change-password` | Yes, current session ID only | DTO, path/body, validation, loading, error, success, session preservation | COMPLETE_NOT_LIVE_MUTATION_TESTED |

## Final feature status

| Feature | UI | API | Route | Tests | Live verified | Status |
|---|---|---|---|---|---|---|
| Register | Complete | Real register endpoint | `/auth/register` | Complete | Contract and non-mutating validation only | COMPLETE_NOT_LIVE_MUTATION_TESTED |
| Verify Email | Complete as far as supplied ID permits | Real verify endpoint | `/auth/verify-email` | Complete | Contract only; no safe account/code | BLOCKED_BY_BACKEND |
| Login | Complete | Real login endpoint | `/auth/login` | Complete | Invalid login re-verified against the live API; successful login not verified | COMPLETE_NOT_LIVE_MUTATION_TESTED |
| Update Email | Complete | Real update endpoint | `/profile/change-email` | Complete | Not mutated without safe credentials | COMPLETE_NOT_LIVE_MUTATION_TESTED |
| Change Password | Complete | Real change endpoint | `/profile/change-password` | Complete | Not mutated without safe credentials | COMPLETE_NOT_LIVE_MUTATION_TESTED |
| Logout | Complete in Account settings | Local secure-session clear; no backend endpoint exists | `/profile/account` | Complete | Local behavior tested | COMPLETE |
| Session Restore | Complete, including stored authenticated user ID | Secure local storage | Startup/router | Complete | Repository/controller tests | COMPLETE |
| Forgot Password / Reset Password | Explicit unavailable/error state | No verified endpoint | `/auth/forgot-password` | Complete blocker behavior | Absence verified in live Swagger/source | BLOCKED_BY_BACKEND |

## Implemented flow

The established direction remains unchanged:

```text
Widget
→ Riverpod controller
→ AuthRepository
→ ApiClient
→ DTO / mapper
→ TokenStorage / AuthSessionController
→ go_router
```

No Widget calls Dio, constructs an endpoint, handles a bearer token, or accepts an editable user ID. Login now stores the source-backed `userId` beside the access token through the secure-storage abstraction. Session-only login keeps both values in memory and removes older persisted values. Logout clears both.

`Cá nhân → Cài đặt → Tài khoản` now reaches Update Email, Change Password, and local Logout. Both mutation controllers require an authenticated session and use only `AuthSessionController.currentUserId`. The centralized interceptor attaches the existing bearer token. Neither form exposes a user ID.

Change Password sends only `currentPassword`, `newPassword`, and `confirmPassword`. Passwords remain in ephemeral text controllers/request objects, are never placed in controller state or storage, and API logging records only method/path/status metadata. The backend source leaves the current token valid, so the frontend preserves the session and does not invent logout or refresh behavior.

Update Email sends only `newEmail`. Source behavior changes the email, marks it unverified, creates a 30-minute code, and sends that code to the new address. The success state can open Verify Email with the current session ID.

## Register to Verify Email result

The Verify Email frontend stack is complete for the exact request:

```json
{
  "userId": 42,
  "verificationCode": "123456"
}
```

Automatic Register → Verify Email handoff remains **BLOCKED_BY_BACKEND**. `RegisterResponse` still contains only `fullName` and `email`; it does not contain the `userId` required by `VerifyEmailRequest`. Flutter does not derive an ID from email, decode or guess one, or expose an arbitrary ID field. The route therefore renders an explicit blocked state when no trusted ID is supplied.

Registration continues to collect one Vietnamese full-name value. Its deterministic adapter maps the first whitespace-separated token to `lastName` and the remaining tokens to `firstName`; a single token maps to `firstName`, and an empty value maps both optional backend fields to null. The backend publishes no locale-aware name splitting rule, so semantic fidelity for compound family names remains an acknowledged ambiguity.

## Confirmed backend gaps and security blockers

- Register omits the `userId` required by Verify Email.
- No forgot-password, reset-password, verification-resend, refresh-token, logout/revocation, or device-session endpoint exists.
- `PUT /api/Auth/update-email/{userId}` and `POST /api/Auth/change-password/{userId}` have no `[Authorize]` enforcement in the supplied controller even though comments describe bearer/ownership requirements. Flutter requiring a session, bearer token, and current session ID does not fix server authorization.
- Live Swagger applies a global bearer requirement even to source-public Auth operations and publishes only untyped `200` responses.
- Update Email does not invalidate the existing access token in source. Change Password also does not revoke it. The frontend therefore preserves the current session.

## Error handling

The centralized mapper supports both observed backend shapes:

- `ApiResponse`: `statusCode`, `isSuccess`, `errorMessage`, and optional string-list `errors`.
- ASP.NET validation problem: `type`, `title`, `status`, field-keyed `errors`, and `traceId`.

Field validation details can be classified without presenting `traceId`, raw JSON, exceptions, or stack traces to users. Auth controllers map network, authorization, validation, not-found, server, and unknown failures to controlled Vietnamese messages.

## Runtime and live-mutation scope

No valid learner credentials or safe disposable inbox were supplied. Successful Register, Login, Verify Email, Update Email, and Change Password mutations were therefore not performed against the live service. Contract/repository/controller/widget/router tests cover these paths without mutating arbitrary users.

- The debug app built, installed, and launched successfully on the Android 17 emulator with the local `.env` configuration.
- Login and Register were visually reviewed on the emulator. Their Sakura layout, Vietnamese text, full-name field, placeholders, password controls, checkbox rows, and route transition rendered correctly. Empty Register submission produced controlled local validation messages without making a successful mutation.
- An intentionally invalid Login submission reached the live API and rendered the controlled Vietnamese invalid-credentials message without exposing a raw response or trace ID.
- Verify Email, Account Settings, Update Email, and Change Password were rendered and interaction-tested through widget/router tests. A safe runtime path to the authenticated account screens was unavailable without learner credentials, while Register cannot hand off to Verify Email because its response omits `userId`.
- No live account was registered, verified, updated, or password-mutated during this review.
