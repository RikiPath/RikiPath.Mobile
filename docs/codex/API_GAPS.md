# RikiPath Frontend API Gaps

Reviewed on: 2026-09-12 (Asia/Bangkok)

This gap register compares the live OpenAPI document at `http://140.245.43.97/swagger/v1/swagger.json` with the supplied read-only backend source at revision `959cad6567ba0101e7fed00c3384948f51c0f47d` and the learner-mobile product scope.

Live Swagger was accessible during this phase. Routes and request schemas were verified against it. The deployed document contains 69 operations but publishes zero typed JSON response schemas, so source-backed response mappings remain unverified at the live schema level. The snapshot fetched at 2026-09-12T10:21:35+07:00 has SHA-256 `a2079ec3f6b5ace0d6bb1b82a3ec697cfc25b6d762c46c2afd42c4a088c53de4`.

## Highest-priority blockers

1. **No typed live response contracts.** Every operation declares only an untyped `200` response. Frontend response DTO generation cannot be based on Swagger.
2. **No JLPT level discovery.** The frontend must send integer `jlptLevelId` values but cannot retrieve the mapping for N5/N4/N3.
3. **Auth lifecycle is incomplete.** There is no refresh, logout/revocation, forgot-password, reset-password, or safe resend-verification endpoint.
4. **Two sensitive auth routes are not protected in source.** Update-email and change-password comments say Bearer is required, but neither action/controller has `[Authorize]`.
5. **Learning navigation is incomplete.** There is no course/roadmap/lesson-list API, only lesson detail by a known ID.
6. **Offline notebook/SRS sync cannot be connected.** No version, tombstone, idempotency, client event, batch review, or reconciliation contract exists.
7. **Exam autosave/resume cannot be connected.** Only start and final whole-attempt submission exist.
8. **Consultation discovery is missing.** Booking/payment requests require package and availability IDs that no learner endpoint exposes.

C10.5 frontend guardrails do not change these backend facts:

- `PUT /api/Auth/update-email/{userId}` and
  `POST /api/Auth/change-password/{userId}` remain intentionally unimplemented
  and unexposed in the mobile app until backend authorization is enforced.
- No response DTO was generated from the untyped live Swagger responses.
  Existing Auth response parsing remains explicitly source-backed.
- Local sign-out only clears secure client state. It does not claim token
  revocation because no logout/revocation endpoint exists.

## Missing endpoints by product area

### Authentication

- Refresh access token — **NOT YET AVAILABLE**.
- Logout/token revocation — **NOT YET AVAILABLE**.
- Forgot-password request — **NOT YET AVAILABLE**.
- Reset-password confirmation — **NOT YET AVAILABLE**.
- Purpose-built resend-verification — **NOT YET AVAILABLE**.
- Current-session/device management — **NOT YET AVAILABLE**.
- Registration cannot hand off to in-app email verification: `RegisterResponse`
  returns only `fullName` and `email`, while `VerifyEmailRequest` requires both
  `userId` and `verificationCode`. The newly created user's ID is not available
  to the mobile client through the registration response.

`POST /api/Email/send-validation` is not an acceptable mobile replacement: it accepts destination email plus arbitrary HTML and is described as backend/admin-oriented.

### User/Profile

- No endpoint exposes a safe self-service email change without a path `userId`.
- No API returns session expiry or token metadata.
- Profile and analytics endpoints otherwise exist.

### JLPT

- JLPT level list/name-to-ID mapping — **NOT YET AVAILABLE**.
- JLPT roadmap — **NOT YET AVAILABLE**.
- Supported learner-level values are not published. The frontend must remain N5/N4/N3 per project rules.
- C7 onboarding is **NOT YET SYNCED TO BACKEND**. Although `POST /api/UserProfile/me/jlpt-goal` accepts `targetJlptLevelId` and `dailyStudyMinutes`, the source service persists them together and validates the numeric level ID. Without a contract-derived N5/N4/N3-to-ID mapping, the frontend cannot construct this request safely.

### Lessons and lesson progress

- Course catalog — **NOT YET AVAILABLE**.
- Lessons by course, level, or skill — **NOT YET AVAILABLE**.
- Roadmap node/sequence data — **NOT YET AVAILABLE**.
- Non-video completion/progress mutation — **NOT YET AVAILABLE**.
- Learning history/continue-learning aggregation — **NOT YET AVAILABLE**.

#### C10 lesson integration gaps

The following items were confirmed against `LessonProgressController`,
`LessonProgressService`, `ILessonProgressService`, `LessonDetailResponse`,
`UpdatePlaybackPositionRequest`, `Lesson`, and `LessonProgress` in the supplied
read-only backend source.

| Feature | Current backend capability | Frontend requirement | Confirmed missing or ambiguous contract | Priority | Blocks integration |
|---|---|---|---|---|---|
| Lesson discovery | Detail is readable only by a known numeric `lessonId` | Resolve a roadmap/course lesson to its numeric ID | No catalog, course lessons, roadmap nodes, or lesson-list route | P0 | Yes |
| Lesson detail composition | Detail returns title, description-backed `content`, media URLs, order, and progress | JLPT/category/chapter metadata, objective, structured parts, examples, vocabulary preview, related grammar, notes, and mastery content | Required Stitch composition fields are absent; `attachmentUrl` is always null in the inspected service mapping | P0 | Yes |
| Resume and duration | Playback update accepts `positionSeconds` and `durationSeconds`; detail returns resume position and percent | A trusted duration and consistent validation before progress sync | Detail does not return duration; controller comment says duration is optional, source service rejects `durationSeconds <= 0`, and Swagger publishes no validation | P0 | Yes |
| Lesson completion | Source service marks playback complete when calculated progress is at least 95% | Explicit completion semantics for video and non-video lesson content | No separate completion endpoint and no non-video completion mutation | P1 | Yes |
| Locked prerequisite and next lesson | No matching fields in lesson detail | Prerequisite status, unlock reason, previous/next lesson identity | No prerequisite, lock, or lesson-link contract | P1 | Yes |
| Media delivery | Detail can return nullable `videoUrl` | Safe playback plus recovery for expired URLs | URL lifetime, signing, expiry, refresh, and offline policy are undocumented | P1 | Yes |

C10 therefore uses local route keys, typed fixtures, and a media-driver
abstraction. It makes no lesson API call and does not present fixture keys as
backend IDs.

### Vocabulary, Kanji, and Grammar

- Search and detail exist for all three banks.
- They cannot offer a contract-derived JLPT selector until the level catalog exists.
- Pagination limits and maximum `pageSize` are not published.

### Personal Vocabulary

- Update a manual/saved entry — **NOT YET AVAILABLE**.
- Move an entry between lists — **NOT YET AVAILABLE**.
- List/search all notebook entries independent of a list — **NOT YET AVAILABLE**.
- Entry/list pagination — **NOT YET AVAILABLE**.
- Offline sync push/pull, versioning, tombstones, idempotency, and conflict resolution — **NOT YET AVAILABLE**.

### Review/SRS

- Batch result upload — **NOT YET AVAILABLE**.
- Offline event ID/idempotency key — **NOT YET AVAILABLE**.
- Review history — **NOT YET AVAILABLE**.
- A live OpenAPI label contract for integer `quality` values 1 through 5 — **NOT YET AVAILABLE**. The supplied source maps `1..2` to `Again`, `3` to `Hard`, `4` to `Good`, and `5` to `Easy`; treat this as source-backed behavior until Swagger publishes it.

### Mock Tests, sessions, answers, and results

- Test detail/instructions/questions-before-start contract — **NOT YET AVAILABLE**.
- Active attempt lookup/resume — **NOT YET AVAILABLE**.
- Server expiry timestamp — **NOT YET AVAILABLE**.
- Abandon/cancel attempt — **NOT YET AVAILABLE**.
- Per-question answer create/update/delete/autosave — **NOT YET AVAILABLE**.
- Attempt history/list — **NOT YET AVAILABLE**.
- Summary and detailed result-by-attempt endpoints do exist.

### AI Advisory

- Latest generated advisory — **NOT YET AVAILABLE**.
- Advisory history — **NOT YET AVAILABLE**.
- Accept/dismiss recommendation — **NOT YET AVAILABLE**.
- Generate options/constraints request — **NOT YET AVAILABLE**.

### Writing/Kanji Submission and AI Grading

- A dedicated grading status/result endpoint — **NOT YET AVAILABLE**.
- Grading job ID and polling lifecycle — **NOT YET AVAILABLE**.
- Published grading status enum — **NOT YET AVAILABLE**.
- Cross-field validation that `Writing` uses `textContent` and `Kanji` uses `imageUrl` — not published.
- Direct image upload exists, but the API does not explicitly connect its returned `url` to `SubmitPracticeRequest.imageUrl`.

Source contains `SubmitEssayRequest`/`SubmitEssayResponse` types, but no live or local controller route uses them. They are not an available API contract.

### Consultation, Booking, and Payment

- Consultation package list/detail — **NOT YET AVAILABLE**.
- Consultant list — **NOT YET AVAILABLE**.
- Availability/slot list and detail — **NOT YET AVAILABLE**.
- Booking cancel/reschedule — **NOT YET AVAILABLE**.
- Learner consultation request detail — **NOT YET AVAILABLE**.
- Consultation purchase history — **NOT YET AVAILABLE**.
- The payment create and status endpoints exist, but required `consultationPackageId` values cannot be discovered.
- Meeting booking exists, but required `consultantAvailabilityId` values cannot be discovered.

### Notifications

- Push-device token registration/update/delete — **NOT YET AVAILABLE**.
- Notification delete/archive — **NOT YET AVAILABLE**.
- List, unread count, mark one read, and mark all read do exist.

## Live Swagger versus backend source mismatches

| Issue | Live Swagger | Supplied backend source | Frontend impact |
|---|---|---|---|
| Response schemas | All 69 operations have untyped responses | Service interfaces and response classes define most `ApiResponse<T>` shapes | Response DTOs cannot be claimed as live-verified; runtime fixtures are needed |
| Response status codes | Every operation declares only `200` | Controllers/services can return 201, 204, 400, 401, 403, 404, or 500 | Generated clients would model status handling incorrectly |
| Security description | Global Bearer applies to every operation | Auth, SharedBank, and Email have no `[Authorize]`; PayOS webhook has `[AllowAnonymous]` | Swagger cannot determine actual per-operation auth |
| Sensitive auth actions | Global Bearer shown | `update-email/{userId}` and `change-password/{userId}` have no enforcement attribute although comments say Bearer | Do not connect until backend confirms/fixes authorization |
| `CoursePurchase` | Four deployed operations exist | No matching controller, service, request-specific DTO, or response DTO exists in the supplied copy | Authentication, semantics, and responses are unknown |
| Bulk import transport | `application/json` with nullable `fileStream: string(binary)` | Controller uses `[FromBody] BulkImportRequest` containing `Stream` | Published upload contract is not practically implementable as written |
| Request-body requirement | Every request body is optional | Controller actions expect non-null DTO parameters; some DTO fields carry `[Required]` | A generated client may allow body omission that runtime rejects or mishandles |
| Email send request | `toEmail` and `htmlContent` are optional/nullable | Controller XML comment calls both required, but record has no validation annotations | Validation behavior is ambiguous |
| File delete query | `storedFileName` is optional in live Swagger | Controller XML comment calls it required; no annotation/check is present | Client cannot rely on published validation |
| Review rating | Request uses integer `quality` constrained to 1..5 but publishes no labels | Service maps 1..2=`Again`, 3=`Hard`, 4=`Good`, 5=`Easy` before storing the domain enum | Do not reuse the frontend Drift draft's 0..3 values; keep the source-only mapping isolated until live OpenAPI publishes it |

## Ambiguous DTO fields and behavior

- DTO fields without `[Required]` are omittable in live Swagger, including many IDs and booleans. Missing non-nullable C# value types can bind to `0`/`false`, but valid business ranges are undocumented.
- `SetJlptGoalRequest.dailyStudyMinutes` has no minimum or maximum.
- Search `page`, `pageSize`, and Kanji stroke-count filters have no published ranges or cross-field rule.
- `UpdatePlaybackPositionRequest` has no nonnegative/range rule and no rule relating `positionSeconds` to `durationSeconds`.
- `SubmitAttemptRequest.answers` is nullable/optional in Swagger, and `AnswerSubmissionItem.questionId` is not required.
- `SubmitPracticeRequest` does not publish which content field is required for each `SubmissionType`.
- `CreateConsultationPaymentRequest.returnUrl` and `cancelUrl` have no URI scheme/allow-list contract.
- Consultation package, purchase, and availability identifiers have no discovery source.
- `AttemptResultResponse.status` is a plain string with no published values.
- `NotificationResponse.type` is a plain string; source comments provide examples but no exhaustive values.
- `NotebookEntryResponse.contentType` is a plain string. Source comments mention `vocabulary`, `kanji`, and `manual`, but it is not an enum.
- `GradingIssueItem.category` is a plain string. Source comments mention examples, not an exhaustive enum.
- `LoginResponse.role` and `UserProfileResponse.role` are strings; known source role values are documented, but live responses remain untyped.
- The approved registration UI presents one Vietnamese full-name field, while
  `RegisterRequest` exposes separate nullable `firstName` and `lastName` fields
  and publishes no locale-aware name-order or splitting rule. The frontend must
  collect these values separately until product/backend naming behavior is
  clarified.
- The JWT expires after one day in the supplied source, but login does not return `expiresAt`; deployed parity is not expressible through Swagger.
- Date/time fields do not publish an offset/timezone policy.
- Media URL lifetime, signing, and refresh behavior are not documented for avatar, video, attachment, audio, image, or stroke-order URLs.
- Payment controller comments refer to a possible `Success` status, while the source enum value is `Paid`.

## Features the frontend cannot connect end-to-end yet

- Forgot-password screens in the visual references.
- Token refresh and server-side logout.
- Contract-derived N5/N4/N3 onboarding without externally supplied JLPT IDs.
- Learning roadmap, course selection, and lesson discovery.
- Offline notebook synchronization and offline review event upload.
- Resumable mock exams with per-answer autosave and server expiry.
- Mock-test history.
- Retrieving an existing/latest AI learning path without regenerating it.
- A fully specified asynchronous grading/polling flow.
- Consultation package browsing and availability-slot selection.
- Consultation purchase history.
- Push-notification device registration.
- Deployed `CoursePurchase` integration, because the local source and response contracts are absent.

## APIs currently connectable with stated limitations

- Register, verify email, and login with an access token only.
- Learner profile, avatar, JLPT-goal update, notification preferences, and analytics.
- Vocabulary, Kanji, and Grammar search/detail when integer JLPT IDs are already known.
- Notebook list management, bookmarking, manual add, entry/list delete, and per-list entry reads.
- Daily SRS queue and single review submission using the source-backed 1..5 mapping, with the caveat that live Swagger does not publish the labels or response schema.
- Mock-test list by known JLPT ID, start, final answer submission, and result reads.
- AI advisory generation.
- Writing/Kanji practice submission, history, nested grading read, and regrade.
- Consultation ticket/booking and consultation payment only when package/purchase/availability IDs are obtained out of band.
- Notification list/count/read operations.

No frontend integration should proceed through a gap by inventing an endpoint, field, enum value, ID mapping, or response shape.
