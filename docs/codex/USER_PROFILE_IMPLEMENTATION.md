# UserProfile Frontend Implementation

Reviewed on: 2026-09-20 (Asia/Bangkok)

This document records Priority Phase P1. The deployed OpenAPI document was
available at `http://140.245.43.97/swagger/v1/swagger.json`. It publishes the
five routes and their request shapes, but every success response remains an
untyped `200`. Response fields and avatar validation therefore come from the
read-only backend source at revision
`006c45cf7d863c1d5fa38b93a0b680cd37b5689d`.

## Endpoint matrix

| Endpoint | DTO | Repository | Controller | UI | API wired | Tests | Status |
|---|---|---|---|---|---|---|---|
| `GET /api/UserProfile/me` | `UserProfileDto` | `loadProfile` | Initial load and retry | Profile loading, success, error, retry | Yes | Exact path, mapping, nulls, states | COMPLETE_NOT_LIVE_TESTED |
| `PUT /api/UserProfile/me` | `UpdateProfileRequestDto` | `updateProfile` | Duplicate-safe mutation | Existing Profile → edit flow | Yes | Exact body, validation, loading, state refresh | COMPLETE_NOT_LIVE_TESTED |
| `POST /api/UserProfile/me/avatar` | Multipart `avatarFile` | `uploadAvatar` | Duplicate-safe mutation | Pick, preview, confirm, upload | Yes | Multipart contract, success, failure, refresh | COMPLETE_NOT_LIVE_TESTED |
| `POST /api/UserProfile/me/jlpt-goal` | `SetJlptGoalRequestDto` | `setJlptGoal` | Mutation capability ready | Current value shown; save intentionally blocked | Repository only | Exact path/body and no guessed mapping | BLOCKED_BY_BACKEND |
| `PUT /api/UserProfile/me/notification-settings` | `UpdateNotificationSettingsRequestDto` | `updateNotificationSettings` | Duplicate-safe immediate save | Two supported toggles | Yes | Exact body, success, failure/no false state | COMPLETE_NOT_LIVE_TESTED |

`COMPLETE_NOT_LIVE_TESTED` means the implementation is covered by repository,
controller, and widget tests but was not called with a live Learner account.

## Architecture reused

```text
Profile presentation
  → Riverpod UserProfileController
  → UserProfileRepository
  → authenticated ApiClient
  → DTO / mapper
  → UserProfile domain model
```

The existing `ApiClient` supplies the access token through its Bearer
interceptor and retains the centralized error mapping. Widgets contain no Dio
calls, endpoint strings, token logic, or response parsing. The Profile provider
is auto-disposed after the authenticated Profile route tree is left, preventing
one learner's cached profile from leaking into a later session.

## Observed contracts

All five operations inherit the live document's global Bearer requirement. The
read-only controller additionally has `[Authorize(Roles = "Learner")]`.

### UserProfile response

Source-backed `ApiResponse<UserProfileResponse>.result` fields:

- `userId: int`
- `email: string`
- `firstName: string`
- `lastName: string`
- `avatarUrl: string?`
- `role: string`
- `isEmailVerified: bool`
- `targetJlptLevelId: int?`
- `targetJlptLevelName: string?`
- `dailyStudyMinutes: int`
- `emailNotificationsEnabled: bool`
- `systemNotificationsEnabled: bool`

The Profile screen now renders these fields instead of the previous learner
name, N3 goal, and metric demonstration values. Phone number, date of birth,
gender, bio, locale, streak, score, and level percentage are not UserProfile
fields and were not invented.

### Update profile

Exact JSON body:

```json
{
  "firstName": "Aiko",
  "lastName": "Sato"
}
```

The source service rejects either value when blank. The frontend validates both,
sends no UI-only fields, prevents duplicate submissions, and replaces the local
profile with the returned profile.

### Avatar upload

- Content type: `multipart/form-data`
- Exact field name: `avatarFile`
- Source-supported content types: `image/jpeg`, `image/png`, `image/webp`
- Source maximum size: 5MB

`image_picker` is used behind `ProfileAvatarPicker`. The implementation reads
cross-platform bytes and does not import `dart:io`, so Android, iOS, and the
picker's supported web implementation share the same upload model. Selection is
previewed and explicitly confirmed before upload. Android needs no additional
photo-library permission entry; iOS has the required usage description.

Swagger publishes the multipart field but does not publish the type/size
constraints; those constraints are source-backed.

### JLPT goal

Exact JSON body:

```json
{
  "targetJlptLevelId": 73,
  "dailyStudyMinutes": 45
}
```

The numeric value above is an example repository-test input, not an N3 mapping.
Neither live Swagger nor the supplied source exposes a certification-level list,
seed, or stable N5/N4/N3-to-ID mapping. The frontend therefore provides the
typed repository/controller capability but does not expose a save action that
would require a guessed ID. Current values returned by `GET /me` remain visible.

Onboarding continues to collect N5/N4/N3 and 15/30/45/60 minutes locally. It
cannot safely submit them until the backend publishes the mapping. No second
network implementation was added to onboarding.

### Notification settings

Exact supported JSON body:

```json
{
  "emailNotificationsEnabled": true,
  "systemNotificationsEnabled": true
}
```

The UI uses immediate save. It updates the visible switch only after the API
returns the updated profile. A failed request leaves the previous value visible
and shows localized feedback. Daily reminder time, consultation-only alerts,
learning-path alerts, marketing, push-device registration, and per-category
preferences are not backend fields and are not presented as synchronized.

## Localization and errors

All new Profile, edit, avatar, JLPT-blocker, notification, validation, and error
messages exist in both `app_vi.arb` and `app_ja.arb`. UI error text maps typed
network, authorization, validation, server, and unknown failures to localized
messages. Raw response JSON, trace IDs, exception strings, and backend debug
details are not displayed.

## Live verification status

`LIVE AUTHENTICATED PROFILE TEST = NOT PERFORMED`

No safe Learner credentials were provided. No live profile read or mutation was
attempted. Contract behavior was verified with the current live OpenAPI request
shapes, read-only backend source, and frontend mocks/tests.

## Confirmed backend gaps

1. Live OpenAPI provides no typed response/status schemas for these operations.
2. There is no discoverable N5/N4/N3-to-`targetJlptLevelId` mapping.
3. Avatar content-type and 5MB limits are absent from OpenAPI.
4. UserProfile has no phone, birth date, gender, bio, or locale fields.
5. Notification settings expose only email and system/in-app booleans.
6. No refresh-token endpoint exists; P1 adds no refresh behavior.
