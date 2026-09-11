# RikiPath Frontend API Contract Reference

Verified on: 2026-09-11 (Asia/Bangkok)

## Contract status and provenance

- **Live Swagger status:** accessible. `GET http://140.245.43.97/swagger/v1/swagger.json` returned HTTP 200.
- **Swagger UI:** `http://140.245.43.97/swagger/index.html`
- **OpenAPI document:** `http://140.245.43.97/swagger/v1/swagger.json`
- **OpenAPI identity:** OpenAPI 3.0.1, title `RikiPath API`, version `v1`.
- **Live inventory:** 66 paths, 69 operations, 33 component schemas.
- **Backend source used for verification:** read-only `RikiPath.Backend/` revision `959cad6567ba0101e7fed00c3384948f51c0f47d`.
- **Swagger JSON endpoint derivation:** `RikiPath.WebApi/Program.cs` registers document `v1` and configures Swagger UI with `/swagger/v1/swagger.json`.

Live Swagger is the primary source for operation existence, HTTP method, exact route, parameters, request schema, and published enum values. The live document declares no typed JSON response schema for any of its 69 operations. Response DTO mappings below therefore come from the matching controller/service interfaces and response classes in the supplied backend source. They are labeled source-backed and must not be treated as live OpenAPI guarantees.

All 69 live operations are accounted for in this reference. Learner/mobile operations are organized by the requested product areas; non-learner content-management operations are retained in an appendix so an existing route is never mistaken for a missing one.

## Reading this reference

Authentication labels describe controller enforcement in the supplied source:

- **Public (source):** no `[Authorize]` attribute is applied.
- **Bearer — Learner:** `[Authorize(Roles = "Learner")]`.
- **Bearer — Consultant/ContentAuthor/Admin:** the named role is required.
- **Bearer — any role:** `[Authorize]` without a role.
- **Live-only; global Bearer:** the route exists in live Swagger but has no matching source controller, so its role cannot be verified.

The live OpenAPI document applies one global `Bearer` security requirement to every operation, including routes that source marks public or anonymous. This is a documentation/enforcement mismatch; see `API_GAPS.md`.

Request field notation:

- **R:** included in the live schema's `required` array and non-null.
- **O:** omittable in live Swagger and non-null if supplied. For C# value types, omission can bind the type default such as `0` or `false`.
- **O?:** omittable and explicitly nullable in live Swagger.
- Every live `requestBody` is itself marked optional, even when individual DTO fields are required.
- No validation may be assumed beyond the limits written below.

Response field notation:

- Response names and fields are **source-backed; live response schema unavailable** unless explicitly marked unknown.
- A `?` suffix means the C# source property is nullable. `Program.cs` omits null JSON values.
- A field without `?` is non-nullable in source intent, but live Swagger does not guarantee its presence.
- C# `DateTime` values serialize as JSON strings; no endpoint-specific timezone rule is published.

## Common JSON contracts

ASP.NET Core web JSON naming is camelCase, confirmed by the live request schemas. `Program.cs` serializes enums as strings and omits null properties.

Most source-backed responses use:

| DTO | JSON fields |
|---|---|
| `ApiResponse<T>` | `statusCode: integer`, `isSuccess: boolean`, `errorMessage?: string`, `errors?: string[]`, `result?: T` |
| `ApiResponse` | Same envelope; successful no-content operations normally omit `result` |
| `PagedResult<T>` | `items: T[]`, `page: integer`, `pageSize: integer`, `totalCount: integer`, `totalPages: integer` |

`totalPages` is calculated as `ceil(totalCount / pageSize)` and is `0` when `pageSize == 0`.

## Authentication

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/Auth/register` | Public (source) | `RegisterRequest` | `ApiResponse<RegisterResponse>` |
| `POST /api/Auth/verify-email` | Public (source) | `VerifyEmailRequest` | `ApiResponse` |
| `POST /api/Auth/login` | Public (source) | `LoginRequest` | `ApiResponse<LoginResponse>` |
| `PUT /api/Auth/update-email/{userId}` | **Public in executable source**, despite controller comments saying Bearer | Path `userId: int32` (R); `UpdateEmailRequest` | `ApiResponse` |
| `POST /api/Auth/change-password/{userId}` | **Public in executable source**, despite controller comments saying Bearer | Path `userId: int32` (R); `ChangePasswordRequest` | `ApiResponse` |
| `POST /api/Email/send-validation` | Public (source); controller comment describes backend/admin usage | `SendValidationEmailRequest` | Direct `EmailSendResult`, not `ApiResponse<T>` |

Authentication behavior verified in source:

- Registration always creates role `Learner`, does not log the user in, creates an email verification code, and returns HTTP 201 through the envelope on success.
- Login rejects unverified email accounts.
- `LoginResponse` contains an access token only. No refresh token is returned.
- The JWT contains name-identifier/user ID, email, and role claims and expires one day after creation. The response does not include a separate `expiresAt` field.
- Role values in source are `Learner`, `ContentAuthor`, `Consultant`, and `Admin`.

**NOT YET AVAILABLE:** refresh token, logout/revocation, forgot-password request, reset-password confirmation, and a purpose-built resend-verification endpoint. `POST /api/Email/send-validation` accepts arbitrary HTML content and is not a safe substitute contract for mobile password recovery or verification resend.

## User/Profile

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `GET /api/UserProfile/me` | Bearer — Learner | None | `ApiResponse<UserProfileResponse>` |
| `PUT /api/UserProfile/me` | Bearer — Learner | `UpdateProfileRequest` | `ApiResponse<UserProfileResponse>` |
| `POST /api/UserProfile/me/avatar` | Bearer — Learner | `multipart/form-data`, field `avatarFile: binary` (O in live Swagger) | `ApiResponse<UserProfileResponse>` |
| `POST /api/UserProfile/me/jlpt-goal` | Bearer — Learner | `SetJlptGoalRequest` | `ApiResponse<UserProfileResponse>` |
| `PUT /api/UserProfile/me/notification-settings` | Bearer — Learner | `UpdateNotificationSettingsRequest` | `ApiResponse<UserProfileResponse>` |
| `GET /api/Analytics/study-streak` | Bearer — Learner | None | `ApiResponse<StudyStreakResponse>` |
| `GET /api/Analytics/completion-stats` | Bearer — Learner | None | `ApiResponse<CompletionStatsResponse>` |
| `GET /api/Analytics/skill-breakdown` | Bearer — Learner | None | `ApiResponse<SkillBreakdownItem[]>` |

## JLPT

There is no endpoint that lists JLPT levels or maps level names to integer IDs.

Existing endpoints that consume a JLPT ID are:

- `POST /api/UserProfile/me/jlpt-goal` through `targetJlptLevelId`;
- `GET /api/PracticeTest/level/{jlptLevelId}/tests`;
- the three shared-bank search bodies through nullable `jlptLevelId`; and
- `POST /api/PracticeSubmission/submit` through `jlptLevelId`.

The backend entity describes admin-configurable N5 through N1 data, but live Swagger exposes no allowed values or lookup endpoint. Per project rules, learner UI remains N5/N4/N3 only.

**NOT YET AVAILABLE:** JLPT level catalog and JLPT roadmap API.

## Lessons

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `GET /api/LessonProgress/lessons/{lessonId}` | Bearer — Learner | Path `lessonId: int32` (R) | `ApiResponse<LessonDetailResponse>` |

**NOT YET AVAILABLE:** course catalog, lesson list, lessons-by-level/skill, roadmap nodes, and a general lesson metadata endpoint. Only detail-by-known-ID exists.

## Lesson Progress

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `PATCH /api/LessonProgress/lessons/{lessonId}/playback-position` | Bearer — Learner | Path `lessonId: int32` (R); `UpdatePlaybackPositionRequest` | `ApiResponse<LessonDetailResponse>` |

The source service contract says playback updates recalculate progress and mark the lesson completed at 95% or more. No separate complete/uncomplete endpoint exists.

## Vocabulary

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/SharedBank/vocabulary/search` | Public (source) | `VocabularySearchFilter` | `ApiResponse<PagedResult<VocabularyCardResponse>>` |
| `GET /api/SharedBank/vocabulary/{id}` | Public (source) | Path `id: int32` (R) | `ApiResponse<VocabularyCardResponse>` |

Pagination uses `page` and `pageSize` in the request body, with source defaults `1` and `20`; response pagination uses the common `PagedResult<T>` structure.

## Kanji

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/SharedBank/kanji/search` | Public (source) | `KanjiSearchFilter` | `ApiResponse<PagedResult<KanjiCardResponse>>` |
| `GET /api/SharedBank/kanji/{id}` | Public (source) | Path `id: int32` (R) | `ApiResponse<KanjiCardResponse>` |

Pagination uses the common `PagedResult<T>` structure.

## Grammar

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/SharedBank/grammar/search` | Public (source) | `GrammarSearchFilter` | `ApiResponse<PagedResult<GrammarCardResponse>>` |
| `GET /api/SharedBank/grammar/{id}` | Public (source) | Path `id: int32` (R) | `ApiResponse<GrammarCardResponse>` |

Pagination uses the common `PagedResult<T>` structure.

## Personal Vocabulary

The controller name is `Notebook`; all routes require the Learner role.

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/Notebook/lists` | Bearer — Learner | `CreateVocabularyListRequest` | `ApiResponse<VocabularyListResponse>` |
| `GET /api/Notebook/lists` | Bearer — Learner | None | `ApiResponse<VocabularyListResponse[]>` |
| `PUT /api/Notebook/lists/{listId}` | Bearer — Learner | Path `listId: int32` (R); `UpdateVocabularyListRequest` | `ApiResponse<VocabularyListResponse>` |
| `DELETE /api/Notebook/lists/{listId}` | Bearer — Learner | Path `listId: int32` (R) | `ApiResponse` |
| `GET /api/Notebook/lists/{listId}/entries` | Bearer — Learner | Path `listId: int32` (R) | `ApiResponse<NotebookEntryResponse[]>` |
| `POST /api/Notebook/bookmark/vocabulary` | Bearer — Learner | `BookmarkVocabularyRequest` | `ApiResponse<NotebookEntryResponse>` |
| `POST /api/Notebook/bookmark/kanji` | Bearer — Learner | `BookmarkKanjiRequest` | `ApiResponse<NotebookEntryResponse>` |
| `POST /api/Notebook/bookmark/grammar/{grammarPointId}` | Bearer — Learner | Path `grammarPointId: int32` (R) | `ApiResponse<GrammarBookmarkResponse>` |
| `POST /api/Notebook/entries` | Bearer — Learner | `AddManualEntryRequest` | `ApiResponse<NotebookEntryResponse>` |
| `DELETE /api/Notebook/entries/{noteEntryId}` | Bearer — Learner | Path `noteEntryId: int32` (R) | `ApiResponse` |

Lists and entries are not paginated in the current contract.

**NOT YET AVAILABLE:** edit/move a saved entry, list all entries across lists, notebook search/pagination, and offline sync/version/idempotency endpoints.

## Review/SRS

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `GET /api/Review/daily-queue` | Bearer — Learner | None | `ApiResponse<DailyReviewQueueResponse>` |
| `POST /api/Review/submit-result` | Bearer — Learner | `SubmitReviewRequest` | `ApiResponse<SubmitReviewResultResponse>` |

`quality` is an integer with the only published constraint `1..5`. The endpoint does not accept the domain `ReviewRating` enum (`Again`, `Hard`, `Good`, `Easy`), and no numeric-to-label mapping is published.

**NOT YET AVAILABLE:** batch review submission, client event/idempotency key, offline reconciliation, or review-history endpoint.

## Mock Tests

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `GET /api/PracticeTest/level/{jlptLevelId}/tests` | Bearer — Learner | Path `jlptLevelId: int32` (R) | `ApiResponse<TestSummaryResponse[]>` |

**NOT YET AVAILABLE:** practice-test detail/instructions and an all-level test catalog.

## Exam Sessions

The backend calls an exam session a practice-test attempt.

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/PracticeTest/{practiceTestId}/start` | Bearer — Learner | Path `practiceTestId: int32` (R) | `ApiResponse<StartAttemptResponse>` |

**NOT YET AVAILABLE:** active-attempt lookup, resume endpoint, abandon endpoint, and server `expiresAt`. The start response provides `startedAt` and `timeLimitMinutes` only.

## Exam Answers

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/PracticeTest/attempts/{attemptId}/submit` | Bearer — Learner | Path `attemptId: int32` (R); `SubmitAttemptRequest` | `ApiResponse<AttemptResultResponse>` |

This is a whole-attempt submission body containing an `answers` array. Each item has `questionId` and nullable `selectedOptionId`.

**NOT YET AVAILABLE:** create/update/delete a single saved answer and answer autosave.

## Exam Results

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `GET /api/PracticeTest/attempts/{attemptId}` | Bearer — Learner | Path `attemptId: int32` (R) | `ApiResponse<AttemptResultResponse>` |
| `GET /api/PracticeTest/attempts/{attemptId}/detailed` | Bearer — Learner | Path `attemptId: int32` (R) | `ApiResponse<DetailedAttemptResultResponse>` |

**NOT YET AVAILABLE:** attempt history/list endpoint.

## AI Advisory

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/LearningPath/generate` | Bearer — Learner | None | `ApiResponse<LearningPathResponse>` |

**NOT YET AVAILABLE:** get latest recommendation, advisory history, accept/dismiss recommendation, or a client-supplied generation-options DTO.

## Writing/Kanji Submission

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/PracticeSubmission/submit` | Bearer — Learner | `SubmitPracticeRequest` | `ApiResponse<PracticeSubmissionResponse>` |
| `GET /api/PracticeSubmission/{submissionId}` | Bearer — any role | Path `submissionId: int32` (R) | `ApiResponse<PracticeSubmissionResponse>` |
| `GET /api/PracticeSubmission/my-history` | Bearer — Learner | None | `ApiResponse<PracticeSubmissionResponse[]>` |
| `POST /api/FileStorage/upload` | Bearer — any role | Query `folder?: string`; `multipart/form-data` field `file: binary` (O in live Swagger; source rejects null) | Direct `UploadedFileResult` |
| `DELETE /api/FileStorage` | Bearer — any role | Query `storedFileName?: string`, `folder?: string` in live Swagger | HTTP 204/no body in source |

`SubmitPracticeRequest.type` is the string enum `Writing` or `Kanji`; it accepts either nullable `textContent` or nullable `imageUrl`, plus `jlptLevelId`. The contract does not state a cross-field rule requiring the appropriate content field for each type.

The generic upload endpoint returns a URL, but no contract explicitly states that its URL should be copied into `SubmitPracticeRequest.imageUrl`.

## AI Grading

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/PracticeSubmission/{submissionId}/regrade` | Bearer — Learner | Path `submissionId: int32` (R) | `ApiResponse<PracticeSubmissionResponse>` |

There is no dedicated grading-result route. The source-backed `PracticeSubmissionResponse` contains nullable `grading`, which holds `GradingResultResponse` when available. `GET /api/PracticeSubmission/{submissionId}` is the only existing read route for one submission and its nested grading result.

**NOT YET AVAILABLE:** dedicated grading status/result endpoint, grading job ID, or a published grading-status enum.

## Consultation

Learner operations:

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/Consultation/tickets` | Bearer — Learner | `SubmitTicketRequest` | `ApiResponse<ConsultationRequestResponse>` |
| `GET /api/Consultation/my-requests` | Bearer — Learner | None | `ApiResponse<ConsultationRequestResponse[]>` |

Consultant-only operations also present in live Swagger:

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `GET /api/Consultation/consultant/queue` | Bearer — Consultant | None | `ApiResponse<ConsultantQueueResponse>` |
| `PATCH /api/Consultation/consultant/requests/{requestId}/claim` | Bearer — Consultant | Path `requestId: int32` (R) | `ApiResponse<ConsultationRequestResponse>` |
| `POST /api/Consultation/consultant/requests/{requestId}/answer` | Bearer — Consultant | Path `requestId: int32` (R); `SubmitAnswerRequest` | `ApiResponse<ConsultationRequestResponse>` |
| `POST /api/Consultation/consultant/requests/{requestId}/log-note` | Bearer — Consultant | Path `requestId: int32` (R); `LogMeetingNoteRequest` | `ApiResponse<ConsultationRequestResponse>` |

**NOT YET AVAILABLE:** consultation package list/detail, consultation request detail, cancellation, and meeting/written-request status actions for learners.

## Booking

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/Consultation/book-meeting` | Bearer — Learner | `BookMeetingRequest` | `ApiResponse<ConsultationRequestResponse>` |

**NOT YET AVAILABLE:** consultant list, consultant availability/slot list, slot detail, booking cancellation, and rescheduling. The existing request requires IDs that the current API does not expose through discovery endpoints.

## Payment

Consultation-payment operations verified in both live Swagger and supplied source:

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/Payment/consultation` | Bearer — Learner | `CreateConsultationPaymentRequest` | `ApiResponse<ConsultationPaymentResponse>` |
| `POST /api/Payment/payos/webhook` | Public/`[AllowAnonymous]` (source); server-to-server, not a mobile action | `PayOsWebhookRequest` | `ApiResponse<boolean>` |
| `GET /api/Payment/purchases/{purchaseId}/status` | Bearer — Learner | Path `purchaseId: int32` (R) | `ApiResponse<ConsultationPurchaseStatusResponse>` |

Additional `CoursePurchase` operations exist in live Swagger but have no matching controller/service/response DTO in the supplied backend copy:

| Method and exact route | Authentication | Request | Response |
|---|---|---|---|
| `POST /api/CoursePurchase/checkout/{courseId}` | Live-only; global Bearer, role unknown | Path `courseId: int32` (R) | **UNKNOWN:** live response is untyped; source absent |
| `POST /api/CoursePurchase/payos/webhook` | Live-only; global Bearer, actual anonymous policy unknown | `PayOsWebhookRequest` | **UNKNOWN:** live response is untyped; source absent |
| `GET /api/CoursePurchase/purchases/{purchaseId}/status` | Live-only; global Bearer, role unknown | Path `purchaseId: int32` (R) | **UNKNOWN:** live response is untyped; source absent |
| `GET /api/CoursePurchase/my-purchases` | Live-only; global Bearer, role unknown | None | **UNKNOWN:** live response is untyped; source absent |

**NOT YET AVAILABLE:** consultation purchase history/list and consultation package discovery. `CoursePurchase/my-purchases` cannot be treated as consultation history because its response and source semantics are unavailable.

## Notifications

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `GET /api/Notification` | Bearer — Learner | Query `onlyUnread?: boolean = false`, `page?: int32 = 1`, `pageSize?: int32 = 20` | `ApiResponse<PagedResult<NotificationResponse>>` |
| `GET /api/Notification/unread-count` | Bearer — Learner | None | `ApiResponse<integer>` |
| `PATCH /api/Notification/{notificationId}/read` | Bearer — Learner | Path `notificationId: int32` (R) | `ApiResponse` |
| `PATCH /api/Notification/mark-all-read` | Bearer — Learner | None | `ApiResponse` |

**NOT YET AVAILABLE:** push-device token registration, notification preferences beyond email/system booleans on the profile endpoint, and notification delete/archive.

## Live request DTO field catalog

Every request DTO referenced above is defined here using live Swagger field names and presence/nullability. DTOs used only by non-learner operations are included because those routes exist in the live document.

| Request DTO | JSON fields and published constraints |
|---|---|
| `LoginRequest` | `email: string(email)` R; `password: string` R |
| `RegisterRequest` | `email: string(email)` R; `password: string` R, minimum length 6; `confirmPassword: string` R and source `[Compare(password)]`; `firstName: string` O?; `lastName: string` O? |
| `VerifyEmailRequest` | `userId: int32` R; `verificationCode: string` R; no published length/pattern |
| `UpdateEmailRequest` | `newEmail: string(email)` R |
| `ChangePasswordRequest` | `currentPassword: string` R; `newPassword: string` R, minimum length 6; `confirmPassword: string` R and source `[Compare(newPassword)]` |
| `SendValidationEmailRequest` | `toEmail: string` O?; `htmlContent: string` O? |
| `UpdateProfileRequest` | `firstName: string` O?; `lastName: string` O? |
| `SetJlptGoalRequest` | `targetJlptLevelId: int32` O; `dailyStudyMinutes: int32` O; no ranges published |
| `UpdateNotificationSettingsRequest` | `emailNotificationsEnabled: boolean` O; `systemNotificationsEnabled: boolean` O |
| `UpdatePlaybackPositionRequest` | `positionSeconds: int32` O; `durationSeconds: int32` O; no ranges published |
| `VocabularySearchFilter` | `jlptLevelId: int32` O?; `keyword: string` O?; `page: int32` O, source default 1; `pageSize: int32` O, source default 20; no ranges published |
| `KanjiSearchFilter` | `jlptLevelId: int32` O?; `keyword: string` O?; `page: int32` O, source default 1; `pageSize: int32` O, source default 20; `minStrokeCount: int32` O?; `maxStrokeCount: int32` O? |
| `GrammarSearchFilter` | `jlptLevelId: int32` O?; `keyword: string` O?; `page: int32` O, source default 1; `pageSize: int32` O, source default 20; no ranges published |
| `CreateVocabularyListRequest` | `name: string` O?; `description: string` O? |
| `UpdateVocabularyListRequest` | `name: string` O?; `description: string` O? |
| `BookmarkVocabularyRequest` | `vocabularyListId: int32` O; `vocabularyEntryId: int32` O |
| `BookmarkKanjiRequest` | `vocabularyListId: int32` O; `kanjiEntryId: int32` O |
| `AddManualEntryRequest` | `vocabularyListId: int32` O; `word: string` O?; `reading: string` O?; `meaning: string` O?; `note: string` O? |
| `SubmitReviewRequest` | `reviewItemId: int32` R; `quality: int32` O, minimum 1, maximum 5 |
| `AnswerSubmissionItem` | `questionId: int32` O; `selectedOptionId: int32` O? |
| `SubmitAttemptRequest` | `answers: AnswerSubmissionItem[]` O? |
| `SubmitPracticeRequest` | `type: SubmissionType` O; `textContent: string` O?; `imageUrl: string` O?; `jlptLevelId: int32` O |
| `BookMeetingRequest` | `consultationPurchaseId: int32` O; `consultantAvailabilityId: int32` O; `note: string` O? |
| `SubmitTicketRequest` | `consultationPurchaseId: int32` O; `question: string` O? |
| `SubmitAnswerRequest` | `answerText: string` O? |
| `LogMeetingNoteRequest` | `meetingNotes: string` O? |
| `CreateConsultationPaymentRequest` | `consultationPackageId: int32` O; `returnUrl: string` O?; `cancelUrl: string` O? |
| `PayOsWebhookRequest` | `code: string` O?; `desc: string` O?; `success: boolean` O; `data: PayOsWebhookData` O; `signature: string` O? |
| `PayOsWebhookData` | `orderCode: int64` O; `amount: int32` O; `description: string` O?; `accountNumber?: string`; `reference?: string`; `transactionDateTime?: string`; `currency?: string`; `paymentLinkId?: string`; `code?: string`; `desc?: string`; `counterAccountBankId?: string`; `counterAccountBankName?: string`; `counterAccountName?: string`; `counterAccountNumber?: string`; `virtualAccountName?: string`; `virtualAccountNumber?: string` |
| `BulkImportRequest` | `entityType: ContentEntityType` O; `fileStream: string(binary)` O?; `jlptLevelId: int32` O; `targetPracticeTestSectionId: int32` O? |
| `ReviewContentRequest` | `approve: boolean` O; `reviewNote: string` O? |

Live request enum values:

| Enum | String values |
|---|---|
| `SubmissionType` | `Writing`, `Kanji` |
| `ContentEntityType` | `Course`, `KanjiEntry`, `VocabularyEntry`, `GrammarPoint`, `PracticeTest`, `PracticeQuestion` |

## Source-backed response DTO field catalog

These response DTOs are absent from live OpenAPI schemas. Field names come from the supplied backend source and camelCase serialization settings.

| Response DTO | JSON fields |
|---|---|
| `RegisterResponse` | `fullName: string`, `email: string` |
| `LoginResponse` | `accessToken: string`, `userId: int32`, `email: string`, `fullName: string`, `role: string` |
| `UserProfileResponse` | `userId: int32`, `email: string`, `firstName: string`, `lastName: string`, `avatarUrl?: string`, `role: string`, `isEmailVerified: boolean`, `targetJlptLevelId?: int32`, `targetJlptLevelName?: string`, `dailyStudyMinutes: int32`, `emailNotificationsEnabled: boolean`, `systemNotificationsEnabled: boolean` |
| `StudyStreakResponse` | `currentStreakDays: int32`, `longestStreakDays: int32`, `lastActivityDate?: datetime`, `isActiveToday: boolean` |
| `CompletionStatsResponse` | `totalLessons: int32`, `completedLessons: int32`, `completionPercent: number(double)` |
| `SkillBreakdownItem` | `skillName: string`, `averageScore: number(double)`, `attemptCount: int32` |
| `LessonDetailResponse` | `lessonId: int32`, `courseId: int32`, `title: string`, `content: string`, `videoUrl?: string`, `attachmentUrl?: string`, `orderIndex: int32`, `progressPercent: int32`, `resumePositionSeconds: int32`, `isCompleted: boolean`, `completedAt?: datetime` |
| `VocabularyCardResponse` | `id: int32`, `word: string`, `reading: string`, `meaning: string`, `partOfSpeech: string`, `exampleSentence: string`, `audioUrl?: string`, `jlptLevelName: string` |
| `KanjiCardResponse` | `id: int32`, `character: string`, `onYomi: string`, `kunYomi?: string`, `sinoVietnamese?: string`, `meaning: string`, `strokeCount: int32`, `strokeOrderUrl?: string`, `audioUrl?: string`, `jlptLevelName: string` |
| `GrammarCardResponse` | `id: int32`, `title: string`, `structure: string`, `explanation: string`, `exampleSentence: string`, `jlptLevelName: string` |
| `VocabularyListResponse` | `id: int32`, `name: string`, `description?: string`, `entryCount: int32`, `createdAt: datetime` |
| `NotebookEntryResponse` | `noteEntryId: int32`, `reviewItemId?: int32`, `contentType: string`, `term: string`, `reading?: string`, `meaning: string`, `note?: string`, `addedAt: datetime` |
| `GrammarBookmarkResponse` | `reviewItemId: int32`, `grammarPointId: int32`, `grammarTitle: string` |
| `DailyReviewQueueResponse` | `totalDue: int32`, `items: ReviewQueueItemResponse[]` |
| `ReviewQueueItemResponse` | `reviewItemId: int32`, `contentType: ReviewContentType`, `term: string`, `reading?: string`, `meaning: string`, `note?: string`, `repetitions: int32`, `nextReviewDate: datetime` |
| `SubmitReviewResultResponse` | `reviewItemId: int32`, `qualitySubmitted: int32`, `newEaseFactor: number(double)`, `newIntervalDays: int32`, `repetitions: int32`, `nextReviewDate: datetime` |
| `TestSummaryResponse` | `practiceTestId: int32`, `title: string`, `description: string`, `jlptLevelName: string`, `timeLimitMinutes: int32` |
| `StartAttemptResponse` | `attemptId: int32`, `practiceTestId: int32`, `startedAt: datetime`, `timeLimitMinutes: int32` |
| `AttemptResultResponse` | `attemptId: int32`, `practiceTestId: int32`, `status: string`, `startedAt: datetime`, `submittedAt?: datetime`, `totalScore: number(double)`, `sections: SectionResultItem[]` |
| `SectionResultItem` | `practiceTestSectionId: int32`, `sectionTitle: string`, `skillName: string`, `correctCount: int32`, `totalCount: int32`, `score: number(double)` |
| `DetailedAttemptResultResponse` | `attemptId: int32`, `practiceTestId: int32`, `totalScore: number(double)`, `questions: QuestionReviewItem[]` |
| `QuestionReviewItem` | `questionId: int32`, `questionText: string`, `options: QuestionOptionReview[]`, `selectedOptionId?: int32`, `isCorrect: boolean`, `explanation?: string` |
| `QuestionOptionReview` | `optionId: int32`, `optionText: string`, `isCorrect: boolean` |
| `LearningPathResponse` | `userId: int32`, `generatedAt: datetime`, `summary: string`, `focusTopics: string[]`, `suggestedLessons: SuggestedLessonResponse[]` |
| `SuggestedLessonResponse` | `lessonId?: int32`, `title: string`, `reason: string` |
| `PracticeSubmissionResponse` | `id: int32`, `type: SubmissionType`, `textContent?: string`, `imageUrl?: string`, `jlptLevelId: int32`, `jlptLevelName: string`, `submittedAt: datetime`, `grading?: GradingResultResponse` |
| `GradingResultResponse` | `submissionId: int32`, `score: number(double)`, `overallFeedback: string`, `issues: GradingIssueItem[]`, `gradedAt: datetime` |
| `GradingIssueItem` | `category: string`, `originalText: string`, `issue: string`, `suggestion: string` |
| `ConsultationRequestResponse` | `id: int32`, `type: ConsultationType`, `status: ConsultationStatus`, `consultantId?: int32`, `scheduledAt?: datetime`, `meetingLink?: string`, `question?: string`, `answerText?: string`, `meetingNotes?: string`, `completedAt?: datetime` |
| `ConsultantQueueResponse` | `items: ConsultantQueueItem[]` |
| `ConsultantQueueItem` | `requestId: int32`, `learnerId: int32`, `learnerName: string`, `type: ConsultationType`, `status: ConsultationStatus`, `scheduledAt?: datetime`, `question?: string`, `recentMockTestResults: MockTestSummary[]` |
| `MockTestSummary` | `testTitle: string`, `score?: number(double)`, `submittedAt?: datetime` |
| `ConsultationPaymentResponse` | `purchaseId: int32`, `orderCode: int64`, `checkoutUrl: string`, `paymentLinkId: string`, `qrCode: string`, `amount: number(decimal)` |
| `ConsultationPurchaseStatusResponse` | `id: int32`, `consultationPackageId: int32`, `packageName: string`, `amountPaid: number(decimal)`, `status: PaymentStatus`, `purchasedAt: datetime` |
| `NotificationResponse` | `id: int32`, `title: string`, `message: string`, `type: string`, `isRead: boolean`, `createdAt: datetime` |
| `EmailSendResult` | `isSuccess: boolean`, `errorMessage?: string` |
| `UploadedFileResult` | `url: string`, `storedFileName: string`, `sizeBytes: int64` |
| `BulkImportResultResponse` | `totalRows: int32`, `successCount: int32`, `failedCount: int32`, `errors: string[]` |
| `ContentReviewStatusResponse` | `id: int32`, `entityType: ContentEntityType`, `title: string`, `status: ContentStatus`, `contentAuthorId: int32`, `reviewNote?: string`, `reviewedDate?: datetime`, `reviewedById?: int32` |

Source response enum values, serialized as strings:

| Enum | String values |
|---|---|
| `Role` | `Learner`, `ContentAuthor`, `Consultant`, `Admin` |
| `SubmissionType` | `Writing`, `Kanji` |
| `ReviewContentType` | `Vocabulary`, `Kanji`, `Grammar` |
| `ConsultationType` | `Meeting`, `WrittenAnswer` |
| `ConsultationStatus` | `PendingAssignment`, `Assigned`, `Accepted`, `Completed`, `Cancelled` |
| `PaymentStatus` | `Pending`, `Paid`, `Failed`, `Refunded` |
| `ContentStatus` | `Draft`, `PendingReview`, `Published`, `Rejected` |

Plain string fields such as attempt `status`, notification `type`, notebook `contentType`, grading issue `category`, and skill names are not enums. Do not invent closed value sets for them.

## Additional existing operations outside the learner mobile scope

These five content-management operations are present in live Swagger and verified against source. They must not be called by the learner mobile app.

| Method and exact route | Authentication | Request | Source-backed response |
|---|---|---|---|
| `POST /api/ContentManagement/bulk-import` | Bearer — ContentAuthor | `BulkImportRequest` | `ApiResponse<BulkImportResultResponse>` |
| `POST /api/ContentManagement/submit/{entityType}/{entityId}` | Bearer — ContentAuthor | Path `entityType: ContentEntityType` (R), `entityId: int32` (R) | `ApiResponse<ContentReviewStatusResponse>` |
| `GET /api/ContentManagement/my-content/{entityType}` | Bearer — ContentAuthor | Path `entityType: ContentEntityType` (R) | `ApiResponse<ContentReviewStatusResponse[]>` |
| `GET /api/ContentManagement/reviews/pending/{entityType}` | Bearer — Admin | Path `entityType: ContentEntityType` (R) | `ApiResponse<ContentReviewStatusResponse[]>` |
| `POST /api/ContentManagement/reviews/{entityType}/{entityId}/review` | Bearer — Admin | Path `entityType: ContentEntityType` (R), `entityId: int32` (R); `ReviewContentRequest` | `ApiResponse<ContentReviewStatusResponse>` |

Live Swagger models `BulkImportRequest.fileStream` as an optional nullable `string(binary)` inside an `application/json` body, while the controller uses `[FromBody]`. This is not a usable mobile upload contract without backend clarification.
