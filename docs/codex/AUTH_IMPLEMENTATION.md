# RikiPath Authentication Implementation

Implemented in phase C6 on 2026-09-11 (Asia/Bangkok).

## Scope

C6 replaces the temporary login and registration screens and the forgot-password placeholder with responsive, state-driven Flutter UI. It adds the frontend authentication repository and Riverpod controllers needed by those screens. Onboarding UI remains unchanged and is deferred to C7.

`RikiPath.Backend/` was inspected only as a read-only contract source.

## Stitch references used

Primary visual references (`screen.png`) and their secondary `code.html` files:

- `docs/ui_reference/stitch_mobile/1._login_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/2._login_validation_state_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/3._login_loading_state_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/1._ng_k_t_i_kho_n_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/2.dang_ki_bao_loi_validation_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/3.dang_ki_loading_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/4.tao_tai_khoan_thanh_cong_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/4._forgot_password_mobile_portrait/`
- `docs/ui_reference/stitch_mobile/5._forgot_password_success_state_mobile_portrait/`

The implementation reuses the C4B header, badges, promotional pill, text fields, password fields, buttons, checkbox row, semantic banners, progress indicator, theme tokens, and responsive spacing. It does not embed the Stitch HTML or recreate a fixed screenshot canvas.

## Screen and state structure

| Screen | Riverpod state/controller | States represented |
|---|---|---|
| `LoginScreen` | `LoginState` / `LoginController` | idle, local field errors, loading, mapped server error, success navigation |
| `RegisterScreen` | `RegisterState` / `RegisterController` | idle, local field/agreement errors, loading, mapped server error, created-account success |
| `ForgotPasswordScreen` | `ForgotPasswordState` / `ForgotPasswordController` | form, local email error, submitting, mapped integration/error state, success |

The layout uses `SafeArea`, `LayoutBuilder`, `SingleChildScrollView`, a constrained maximum content width, and natural wrapping. Form fields remain reachable when the software keyboard reduces the viewport. Loading disables mutable inputs and the primary action to prevent duplicate submissions.

Feature-wide async state lives in Riverpod notifiers. Password visibility and remember/agreement checkboxes remain local presentation state.

## Data and repository direction

The implemented call direction is:

`Widget → Riverpod controller → AuthRepository → ApiClient → backend DTO`

Endpoint strings exist only in `auth_api_paths.dart`. Widgets do not import Dio, construct endpoint paths, parse envelopes, or handle tokens.

`ApiAuthRepository` uses the existing centralized `ApiClient` and the existing `TokenStorage`. Successful envelopes are decoded from `result`; malformed success shapes are converted to `UnknownError` instead of leaking parsing exceptions into the UI.

## Confirmed API mappings

### Login

- Endpoint: `POST /api/Auth/login`
- Authentication: public in backend source
- Request JSON:
  - `email: string` — required, email format
  - `password: string` — required
- Successful result JSON:
  - `accessToken: string`
  - `userId: int`
  - `email: string`
  - `fullName: string`
  - `role: string`

No username, phone, `identifier`, refresh token, or token-expiry field is sent or parsed.

### Registration

- Endpoint: `POST /api/Auth/register`
- Authentication: public in backend source
- Request JSON:
  - `email: string` — required, email format
  - `password: string` — required, minimum length 6
  - `confirmPassword: string` — required and must match `password`
  - `firstName: string?` — optional/nullable
  - `lastName: string?` — optional/nullable
- Successful result JSON:
  - `fullName: string`
  - `email: string`

The Flutter form collects `firstName` and `lastName` separately because the backend has no `fullName` request field and publishes no locale-aware rule for splitting the single full-name field shown by Stitch. Empty optional names are sent as `null`. `confirmPassword` is sent because it is part of the confirmed backend DTO.

The Stitch helper says eight characters and adds complexity wording. The backend publishes only a minimum of six characters and no uppercase/number/special-character rule, so C6 displays and validates the contract-backed six-character rule.

## Password recovery availability

There is no confirmed forgot-password, reset-password, or recovery-resend endpoint. C6 does not invent one and does not repurpose `POST /api/Email/send-validation`, which accepts arbitrary HTML and is backend/admin-oriented.

`AuthRepository.requestPasswordReset` is the explicit integration seam. The production `ApiAuthRepository` throws `PasswordRecoveryUnavailableException` with a TODO to connect only after a real contract is published. The controller maps that condition to a learner-friendly Vietnamese message. A repository fake can return success in widget tests so the approved success presentation remains independently testable.

The success view's `Gửi lại (58s)` is presentation-only and has no tap/network action. C6 also omits the reference's 15-minute link-lifetime claim because no recovery contract publishes that lifetime.

## Token behavior

Only `accessToken` is persisted. `TokenStorage` keeps the active token in memory for the current session and writes it through `flutter_secure_storage` only when the learner leaves “Ghi nhớ phiên đăng nhập trên thiết bị này” selected. An unselected login clears any older persisted token while retaining the new token in memory for the running app session.

No token is stored after registration. No refresh token, refresh interceptor, logout/revocation call, or fabricated expiry metadata is implemented because the API exposes none.

## Validation and error presentation

Local validation prevents network submission for:

- missing or malformed email;
- missing login password;
- registration password shorter than 6 characters;
- missing or mismatched `confirmPassword`; and
- unaccepted registration terms.

The optional backend name fields are not falsely marked required.

Controllers map unauthorized/invalid credentials, network unavailability, backend validation failure, server failure, missing password-recovery integration, and unknown errors to concise Vietnamese copy. Raw `DioException`, response bodies, stack traces, and backend debug details are never rendered.

## Routing and post-auth behavior

Canonical authentication routes are:

- `/auth/login`
- `/auth/register`
- `/auth/forgot-password`

Forgot-password form, submitting, error, and success states stay on the single `/auth/forgot-password` route.

Successful login currently opens `/home`. This is a deliberately simple authenticated landing, not an inference that onboarding is complete: `LoginResponse` has no onboarding flag, and the profile contract does not publish a definitive onboarding-completion field. C7/Profile integration must define that decision before conditional routing is added.

Successful registration stays in the registration flow and displays contract-accurate email-verification guidance. Registration neither logs the learner in nor enters onboarding. A complete in-app verification handoff is blocked because `RegisterResponse` does not return the `userId` required by `POST /api/Auth/verify-email`; this confirmed gap is recorded in `API_GAPS.md`.

The requested `docs/codex/ROUTING_ARCHITECTURE.md` input was absent in this checkout. C6 therefore preserved the existing `GoRouter`/`StatefulShellRoute.indexedStack` structure and changed only the authentication path constants and forgot-password builder required by this phase.

## Tests

Added tests cover:

- exact login/register request JSON names and login response fields;
- remembered versus session-only secure token behavior;
- login content, local validation, repository suppression, password visibility, loading/duplicate prevention, and auth navigation;
- registration required-field validation, confirmation mismatch, loading, success, and return navigation;
- password-recovery form, invalid email, success presentation, and return navigation; and
- Vietnamese mapping for unauthorized, network, server, missing-integration, and unknown failures.

Existing router smoke tests now wrap the app in `ProviderScope`, use the canonical authentication paths, and expect `ForgotPasswordScreen` instead of the placeholder.

## Deferred work and known gaps

- C7 owns the final JLPT target, study-time, and onboarding-completion UI/integration.
- Password recovery and resend remain blocked on backend contracts.
- Email verification cannot be completed from the registration response without a returned `userId` or another lookup/handoff contract.
- Legal-document destinations and help-center navigation are not published; C6 renders the approved supporting copy without inventing routes.
- Login-to-onboarding branching awaits a definitive completion signal.
- Real-device Japanese glyph, keyboard, accessibility text-scale, Android, and iOS verification remain required once generated platform projects and the Flutter SDK are available.

## C6 verification status

- `flutter pub get` — **NOT EXECUTED — Flutter SDK unavailable** (`flutter` command not found).
- `dart format .` — **NOT EXECUTED — Dart SDK unavailable** (`dart` command not found).
- `flutter analyze` — **NOT EXECUTED — Flutter SDK unavailable** (`flutter` command not found).
- `flutter test` — **NOT EXECUTED — Flutter SDK unavailable** (`flutter` command not found).
- Manual static checks found no unmatched braces/parentheses in changed Dart files, no replacement Unicode characters, no Dio/API client/endpoint path in auth presentation, and no likely secret material.
- The root `.git/` directory is empty and is not a valid frontend Git worktree, so a root Git diff is unavailable. The nested backend Git repository is valid and was checked independently.
