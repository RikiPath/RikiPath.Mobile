# RikiPath Frontend API Gaps

Reviewed on: 2026-09-20 (Asia/Bangkok)

This gap register compares the live OpenAPI document at `http://140.245.43.97/swagger/v1/swagger.json` with the supplied read-only backend source, currently at revision `006c45cf7d863c1d5fa38b93a0b680cd37b5689d`, and the learner-mobile product scope.

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

C10.5/A3 frontend guardrails do not change these backend facts:

- A3 integrates `PUT /api/Auth/update-email/{userId}` and
  `POST /api/Auth/change-password/{userId}` only behind authenticated frontend
  routes, with the path ID taken from the current stored session and the normal
  bearer interceptor. This client restriction does not provide server-side
  authorization; both routes remain backend security blockers until ownership
  and role enforcement are added.
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
- The backend team reports that the deployed registration response now includes
  `userId`, and Flutter now consumes it for the Register → Verify Email handoff.
  However, the live OpenAPI operation still has an untyped `200` response and
  the supplied read-only source snapshot still shows the older two-field
  `RegisterResponse`. Flutter therefore keeps a safe fallback blocked state if
  an older server omits `userId`; Swagger/source artifacts still need refreshing.

Priority A1 reverified the unchanged live OpenAPI snapshot on 2026-09-18. An
invalid Login reached the deployed endpoint and returned the source-shaped HTTP
400 envelope with `statusCode`, `isSuccess`, and `errorMessage`. A malformed,
non-mutating Register probe returned the ASP.NET validation-problem shape rather
than `ApiResponse<T>`. No successful Login/Register response was observed
because no safe test credentials or test inbox were provided; the source-backed
success DTOs, including the reported registration `userId`, therefore remain
unverified at the live response-schema/runtime-success level.

`POST /api/Email/send-validation` is not an acceptable mobile replacement: it accepts destination email plus arbitrary HTML and is described as backend/admin-oriented.

### User/Profile

- No endpoint exposes a safe self-service email change without a path `userId`.
- No API returns session expiry or token metadata.
- P1 connected the five `/api/UserProfile/me` operations with source-backed
  response DTOs. Live Swagger still publishes only untyped `200` responses, so
  authenticated runtime response parity has not been verified.
- Swagger publishes avatar multipart key `avatarFile`, but its JPEG/PNG/WEBP
  allow-list and 5MB maximum are only present in the supplied backend source.
- UserProfile exposes no phone number, date of birth, gender, bio, or locale.
- Notification settings expose only `emailNotificationsEnabled` and
  `systemNotificationsEnabled`; more granular polished-UI settings cannot be
  represented as backend-synced values.

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

#### C11 vocabulary integration gaps

The following vocabulary findings were confirmed against live Swagger, live
runtime requests, `SharedBankController`, `SharedBankSearchService`, the bank
response and filter types, vocabulary/JLPT entities, and the Notebook source.

| Feature | Current backend capability | Frontend requirement | Confirmed missing or ambiguous contract | Priority | Blocks integration |
|---|---|---|---|---|---|
| Vocabulary data | `POST /api/SharedBank/vocabulary/search` returned a valid empty page during C11 verification | A usable N5/N4/N3 vocabulary library | The deployed vocabulary bank contained zero returned entries at verification time | P0 | Yes, for real content; C11 uses clearly labeled fixtures when page 1 is empty |
| JLPT filtering | Search accepts nullable integer `jlptLevelId` | N5/N4/N3 filter chips | No endpoint or published mapping relates N5/N4/N3 names to numeric IDs | P0 | Yes, for remote filtering |
| Detail composition | Detail returns `VocabularyCardResponse`, the same fields used by search cards | Stitch detail sections such as Hán-Việt, expanded definition, translations, collocations, nuance, Kanji analysis, frequency, and related lessons | None of those enrichment fields are in the response contract | P1 | Yes, for full detail fidelity |
| Part of speech | Response type declares `partOfSpeech` | Render a reliable part-of-speech label | The inspected `MapVocabulary` source does not assign `PartOfSpeech`, so source behavior produces an empty value; live behavior could not be observed because the list was empty | P1 | Yes, for this label |
| Example sentence | Response type declares non-null `exampleSentence` | Render an example and translation safely | The entity field is nullable, the mapper passes it through, null JSON is omitted globally, and no translation field exists | P1 | Yes, for guaranteed examples/translations |
| Search coverage | Source searches `word`, `reading`, and `meaning` | Stitch search hint also suggests Romaji and Hán-Việt | No Romaji or Hán-Việt search field/behavior exists | P1 | Yes, for those search modes |
| Saved status | Notebook can bookmark a known bank entry into a known list | Show per-entry saved status and reconcile it after reload | Bank responses have no saved flag; Notebook responses do not expose the originating `vocabularyEntryId`; removal requires `noteEntryId` | P0 | Yes, for reliable saved-state synchronization and removal after reload |
| Duplicate bookmark behavior | Bookmark creates a note entry and SRS item | Idempotent save UX | No idempotency key or duplicate-bookmark contract/check was found | P1 | Yes, for safe retry/idempotency |
| Audio | Bank response has nullable `audioUrl` | Word and sentence playback | No guaranteed audio, sentence-audio/TTS contract, or URL lifetime/refresh policy exists | P1 | Yes, when `audioUrl` is absent or expires |
| Published-content safety | Search/detail read shared-bank records | Learner screens should expose only published content | Search passes no content-status filter and detail has no confirmed published-status check in the inspected source; live behavior is unverified because the bank was empty | P0 | Yes, pending backend confirmation or enforcement |
| Pagination validation | Source normalizes page below 1 to 1, page size below 1 to 20, and caps page size at 100 | Stable client-side paging rules | Swagger publishes no defaults, ranges, or maximum | P1 | No for conservative paging; yes for generated validation |

C11 therefore keeps fixture route keys separate from numeric backend IDs,
labels fixture content, never sends a guessed JLPT ID, accepts nullable audio
and example fields, and only calls Notebook bookmarking for remote entries with
a real backend ID.

#### C12 Kanji integration gaps

The following findings were confirmed on 2026-09-12 against live Swagger,
runtime requests, `SharedBankController`, `SharedBankSearchService`, the Kanji
entity/configuration/repository, bank response and filter types, and Notebook
controller/service/request types in the supplied read-only backend source.

| Feature | Current backend capability | Frontend requirement | Confirmed missing or mismatched contract | Priority | Blocks integration |
|---|---|---|---|---|---|
| Kanji data | `POST /api/SharedBank/kanji/search` returned a valid empty paged result | A usable N5/N4/N3 Kanji library | The deployed Kanji bank returned zero entries at verification time | P0 | Yes, for real content; C12 uses clearly labeled fixtures when page 1 is empty |
| JLPT filtering | Search accepts nullable integer `jlptLevelId` | N5/N4/N3 filter chips | No endpoint or published mapping relates N5/N4/N3 names to numeric IDs | P0 | Yes, for remote filtering |
| Detail composition | Detail returns the same `KanjiCardResponse` shape used by search | Radical, mnemonic, compound words, translated examples, and related lesson content shown by Stitch | These enrichment fields are absent; the controller comment mentions examples but the executable response type does not contain them | P1 | Yes, for full Stitch detail fidelity |
| On reading nullability | `KanjiCardResponse.onYomi` is declared non-nullable | Safe rendering of optional readings | `KanjiEntry.OnYomi` is nullable, the mapper passes it through, and global JSON options omit null values | P1 | No when parsed as nullable; yes for generated non-null clients |
| Keyword search | Source repository searches `character` and `meaning` | Predictable search hint and behavior | On-yomi, kun-yomi, and Hán-Việt fields are not included in source search despite the broader Stitch search hint | P1 | Yes, for reading/Hán-Việt search |
| Stroke order | Response can contain one nullable `strokeOrderUrl` image | The approved stroke screen shows an 18-step sequence, active stroke, animation controls, directions, and writing rules | No stroke-sequence, vector, direction, animation, speed, or rules contract exists | P1 | Yes, for production stroke animation; a typed, labeled Stitch fixture is isolated in C12 |
| Saved status | Notebook can bookmark a known Kanji entry into a known list | Show and reconcile saved state after reload | Bank responses have no saved flag; Notebook responses do not return the originating `kanjiEntryId`; removal requires `noteEntryId` | P0 | Yes, for reliable saved-state synchronization and removal after reload |
| Duplicate bookmark behavior | Bookmark creates a note entry and SRS item | Idempotent save and retry UX | No idempotency key or duplicate-bookmark check/contract was found | P1 | Yes, for safe retries |
| Bookmark documentation | Executable request and live Swagger use `vocabularyListId` plus `kanjiEntryId` | Stable generated/manual client documentation | Controller XML text says `KanjiId or Character` although neither name matches the request DTO | P2 | No; C12 follows the executable DTO and live request schema |
| Audio | Bank response has nullable `audioUrl` | Reading playback | No guaranteed audio or URL lifetime/signing/refresh policy exists | P1 | Yes when audio is absent or expires |
| Published-content safety | Search/detail read shared-bank Kanji records | Learner screens should expose only published content | Search passes no content-status filter and detail has no confirmed published-status check | P0 | Yes, pending backend enforcement or confirmation |
| Pagination validation | Source normalizes page below 1 to 1, page size below 1 to 20, and caps page size at 100 | Stable client paging rules | Swagger publishes no defaults, ranges, or maximum; stroke min/max also have no range/cross-field rule | P1 | No for conservative paging; yes for generated validation |

C12 therefore keeps `fixture-*` route keys separate from numeric `remote-*`
IDs, labels visual-only enrichment, never sends a guessed JLPT ID, treats
`onYomi` and media URLs as nullable, and calls Kanji bookmarking only for a
remote entry with a real backend ID.

#### C13 Grammar integration gaps

The following findings were re-confirmed on 2026-09-20 against live Swagger,
read-only runtime requests, `SharedBankController`,
`SharedBankSearchService`, the Grammar entity/configuration/repository, bank
response/filter types, and the Notebook controller/service in the supplied
read-only backend source.

| Feature | Current backend capability | Frontend requirement | Confirmed missing or mismatched contract | Priority | Blocks integration |
|---|---|---|---|---|---|
| Grammar data | `POST /api/SharedBank/grammar/search` returned HTTP 200 with a valid empty paged result; `GET /api/SharedBank/grammar/1` returned the source-shaped HTTP 404 envelope | A usable N5/N4/N3 Grammar library | The deployed Grammar bank returned zero entries at verification time | P0 | Yes, for real content; C13 uses clearly labeled fixtures only when page 1 is empty |
| JLPT filtering | Search accepts nullable integer `jlptLevelId` | N5/N4/N3 filter chips | No endpoint or published mapping relates N5/N4/N3 labels to numeric IDs | P0 | Yes, for remote filtering |
| Published-content safety | Search/detail read shared-bank Grammar records | Learners must receive only published Grammar | Search passes `status: null`, and detail has no published-status check in the inspected source | P0 | Yes, pending backend enforcement |
| Detail composition | Detail returns the same `GrammarCardResponse` shape as search | Stitch sections for distinct meaning, usage rules, cautions, multiple translated examples, related Grammar, lesson links, audio, and practice | None of those richer fields/relationships are exposed by the executable response type | P1 | Yes, for full Stitch detail fidelity |
| Explanation/example nullability | Response properties are declared non-nullable strings | Safe optional rendering | Mapper assigns nullable `UsageNotes` and `ExampleSentence` directly; global JSON options omit null values, so either field can be absent at runtime | P1 | No when parsed as optional; yes for generated non-null clients |
| Example translation | Entity contains nullable `ExampleSentenceMeaning` | Vietnamese example translation | `GrammarCardResponse` and `MapGrammar` do not expose the entity field | P1 | Yes |
| Keyword behavior | Source searches `title`, `structure`, and nullable `usageNotes` | Predictable multilingual search | Example sentence and translation are not searched; collation/case behavior is database-dependent and not published | P1 | Yes, for broader Stitch search expectations |
| Related Grammar | No related-Grammar field or endpoint was found | “Ngữ pháp liên quan & phân biệt” section | Relationship IDs, summaries, ordering, and comparison guidance are absent | P1 | Yes; C13 keeps this as labeled fixture enrichment only |
| Saved status/removal | `POST /api/Notebook/bookmark/grammar/{grammarPointId}` creates a review item for a Learner | Reliable save/un-save and saved-state restoration | Bank responses have no saved flag, the bookmark service has no duplicate check/idempotency contract, and no Grammar-specific unbookmark/read-state contract was found | P0 | Yes; C13 does not expose Notebook actions |
| Authentication publication | SharedBank source is public; Notebook source requires Learner | Accurate per-operation auth | Live Swagger applies Bearer globally and cannot express the public SharedBank exception; responses remain untyped | P1 | No for search/detail after source/runtime verification; yes for generated auth metadata |
| Pagination validation | Source normalizes page below 1 to 1, page size below 1 to 20, and caps page size at 100 | Stable client paging rules | Swagger publishes no defaults, ranges, or maximum | P1 | No for conservative paging; yes for generated validation |

C13 therefore keeps `fixture-*` keys separate from numeric `remote-*` IDs,
labels fixture-only enrichment, treats nullable entity-backed strings as
optional, never sends a guessed JLPT ID, and leaves Notebook, audio, lessons,
practice, and related-Grammar production integration deferred.

### Personal Vocabulary

- Update a manual/saved entry — **NOT YET AVAILABLE**.
- Move an entry between lists — **NOT YET AVAILABLE**.
- List/search all notebook entries independent of a list — **NOT YET AVAILABLE**.
- Entry/list pagination — **NOT YET AVAILABLE**.
- Offline sync push/pull, versioning, tombstones, idempotency, and conflict resolution — **NOT YET AVAILABLE**.

#### C14 Notebook integration gaps

The following findings were confirmed on 2026-09-13 against live Swagger,
an unauthenticated runtime request, and the read-only Notebook controller,
service, requests, responses, repositories, entities, and EF configurations.

| Feature | Current backend capability | Frontend requirement | Missing/ambiguous contract | Swagger/backend mismatch | Priority | Blocks real integration |
|---|---|---|---|---|---|---|
| Saved-state lookup | A learner can bookmark a known bank vocabulary ID into a known list | Restore whether a bank entry is saved and offer reliable save/unsave | No saved-state endpoint or flag exists; NotebookEntryResponse omits the originating vocabularyEntryId | Live responses have no schemas, so the omission is only verifiable from source/runtime-shaped fixtures | P0 | Yes |
| Duplicate save | Each bookmark call creates a new note entry and linked ReviewItem | Safe retries and one logical bookmark per list/word | No uniqueness rule, duplicate check, idempotency key, or conflict response exists | Swagger declares only an untyped 200, while source creates a new result with Created semantics | P0 | Yes |
| Cross-list reconciliation | Lists and their entries can be read one list at a time | Show all locations containing one vocabulary item and remove the correct bookmark | There is no all-entry lookup and an entry cannot be related back to its source bank ID | Swagger publishes the per-list path but no response schema or relationship fields | P0 | Yes |
| Remote detail navigation | Per-list reads return term, reading, meaning, note, and note/review IDs | Open the source Vocabulary Detail from Notebook | vocabularyEntryId is not returned, so the frontend cannot derive a real detail route | Live response schema is absent; source response confirms the missing ID | P1 | Yes |
| Notebook search/filter | GET /api/Notebook/lists/{listId}/entries returns a complete list ordered newest-first in source | Server-backed search, JLPT filters, and SRS-status filters shown by Stitch | No query parameters or all-list search endpoint exists; entries expose neither JLPT nor review status | Swagger shows no parameters or response schema; source confirms no filters/pagination | P1 | Yes, for server-backed/global filtering; no for local search of a loaded list |
| Pagination | Lists and per-list entries return arrays | Scale large personal notebooks | No page fields, limits, continuation token, or stable paging contract exists | Swagger has no pagination parameters and untyped responses | P1 | Yes, for large-data incremental loading |
| Manual-entry fidelity | POST /api/Notebook/entries accepts list ID, word, optional reading, meaning, and optional note | Stitch also shows JLPT, part of speech, and example fields | JLPT, part of speech, examples, and example translations cannot be stored | Live request schema matches source but marks every property optional; source validates word and meaning at service level | P1 | Yes, for full Stitch form fidelity |
| Entry edit/move | An entry can be added and deleted | Edit notes/content or move/copy between lists | No update-entry or move-entry endpoint exists | No such operation appears in live Swagger or source | P1 | Yes |
| Delete contract | Source ownership-checks the list and removes the note plus its linked ReviewItem | Confirm deletion and update UI safely | No typed success body/status contract or concurrency/not-found recovery contract is published | Swagger declares only untyped 200; source can return success/403/404/500-style envelopes | P1 | No for basic online delete; yes for generated/optimistic conflict handling |
| Create-list validation | POST /api/Notebook/lists creates a list; source rejects blank names and EF limits names to 200 characters | Accurate client validation and generated DTO requiredness | No description limit or duplicate-name rule is defined | Live body/fields are optional and publish neither the source-required name nor its 200-character limit | P1 | No for source-backed required-name/length validation |
| Content type | Source currently maps vocabulary, kanji, or manual | Stable typed display and future compatibility | contentType is a plain string, not an enum or exhaustive contract | Live response schema is absent | P2 | No; C14 preserves unknown values as an explicit fallback |
| Offline synchronization | No Notebook sync/version endpoint exists | Durable offline Notebook edits, retries, and conflict resolution | Versions, tombstones, retry tokens, idempotency, and reconciliation are absent | No live or source operations exist | P0 | Yes; deferred to C15/backend work |

C14 therefore uses real per-list reads and mutations, caches verified response
fields in user-scoped Drift storage, performs search only over the selected
cached list, never derives a vocabulary route from a note ID, and
does not expose JLPT/SRS filters that the response cannot support.

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
  and publishes no locale-aware name-order or splitting rule. A3 preserves the
  approved single field and uses a deterministic adapter (first token to
  `lastName`, remainder to `firstName`), but compound-family-name fidelity
  remains ambiguous until backend/product naming behavior is defined.
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

- Register and login with an access token only. Verify Email is wired for a
  trusted known `userId`, but Register cannot hand it off because its response
  omits that ID.
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
