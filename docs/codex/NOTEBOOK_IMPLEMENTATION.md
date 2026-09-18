# Personal Vocabulary Notebook Implementation

Status: Phase C14 frontend implementation, verified 2026-09-13.

## Sources used

Contract priority was:

1. live OpenAPI JSON at http://140.245.43.97/swagger/v1/swagger.json;
2. the read-only RikiPath.Backend/ copy;
3. the existing Flutter architecture and Codex documents;
4. Stitch for visual structure only.

The approved visual references inspected were:

- NOTEBOOK_01_Sổ từ của tôi
- NOTEBOOK_02_Tất cả từ vựng
- NOTEBOOK_03_Danh sách của tôi
- NOTEBOOK_04_Chi tiết danh sách - N3 khó nhớ
- NOTEBOOK_05_Thêm từ mới
- NOTEBOOK_06_Thêm từ mới - Lỗi xác thực
- NOTEBOOK_07_Chỉnh sửa từ cá nhân
- NOTEBOOK_08_Chọn danh sách - Bottom Sheet

Every screen.png was treated as the primary visual source and every
corresponding code.html as secondary structural guidance.

## Verified API surface

Live Swagger exposes these Learner Notebook operations:

| Method | Route | Source request/result |
|---|---|---|
| POST | /api/Notebook/lists | CreateVocabularyListRequest → VocabularyListResponse |
| GET | /api/Notebook/lists | VocabularyListResponse[] |
| PUT | /api/Notebook/lists/{listId} | UpdateVocabularyListRequest → VocabularyListResponse |
| DELETE | /api/Notebook/lists/{listId} | non-generic ApiResponse |
| GET | /api/Notebook/lists/{listId}/entries | NotebookEntryResponse[] |
| POST | /api/Notebook/bookmark/vocabulary | BookmarkVocabularyRequest → NotebookEntryResponse |
| POST | /api/Notebook/bookmark/kanji | BookmarkKanjiRequest → NotebookEntryResponse |
| POST | /api/Notebook/bookmark/grammar/{grammarPointId} | route ID → GrammarBookmarkResponse |
| POST | /api/Notebook/entries | AddManualEntryRequest → NotebookEntryResponse |
| DELETE | /api/Notebook/entries/{noteEntryId} | non-generic ApiResponse |

C14 directly uses list read/create, per-list entry read, manual add, vocabulary
bookmark, and entry delete. List rename/delete and Kanji/Grammar bookmark UI are
outside this screen's implementation scope.

An unauthenticated runtime GET /api/Notebook/lists returned HTTP 401 with an
empty body. Source confirms Authorize(Roles = Learner) on the controller. No
credentials or mutating runtime requests were used.

## Source-backed response model

VocabularyListResponse contains:

- id
- name
- nullable description
- entryCount
- createdAt

NotebookEntryResponse contains:

- noteEntryId
- nullable reviewItemId
- plain-string contentType
- term
- nullable reading
- meaning
- nullable note
- addedAt

The source maps contentType to vocabulary, kanji, or manual. C14 models those
values and retains an unknown UI fallback because the field is not an enum.
The source repository orders lists by name and entries by newest CreatedDate.

## Swagger/source mismatches

- Live Swagger publishes no usable response schemas for Notebook operations.
- Live Swagger declares only 200; source also has Created, forbidden,
  not-found, validation-failure, and server-error paths.
- Live request bodies and properties are optional, while controllers accept
  non-null DTOs and services reject blank list names, manual words, and manual
  meanings. Source EF configuration limits list names to 200 characters, but
  Swagger does not publish that limit.
- Global Swagger Bearer metadata cannot express the controller's exact Learner
  role requirement.

DTOs are therefore manually source-backed and tested against the shared
ApiResponse envelope. No speculative response fields were generated.

## Routes

- Main screen: /notebook
- Proven fixture vocabulary detail: /notebook/vocabulary/:entryKey

The detail path is nested in the existing Notebook shell branch, so the
StatefulShellRoute.indexedStack keeps the Sổ từ tab selected. Remote Notebook
entries do not navigate to Vocabulary Detail because their response does not
contain vocabularyEntryId; a note ID is never reused as a bank ID.

## Architecture

The implementation follows:

Presentation → Riverpod controller → NotebookRepository → API/fixture source →
DTO → mapper → domain.

- NotebookController owns initial loading, list selection, local search,
  create/add/remove mutation state, and visible error state.
- ApiNotebookRepository is the only production provider.
- FixtureNotebookRepository is explicitly identifiable and used only through
  deliberate provider overrides/tests.
- DTOs and exact endpoint paths remain in the data layer.
- Widgets consume domain objects only and contain no Dio, raw JSON, or API
  paths.
- Remote list IDs, remote note-entry IDs, and local/fixture route keys are
  separate fields.

## Implemented states and behavior

- authenticated Notebook shell screen;
- initial loading and whole-screen API failure;
- empty Notebook with create-list action;
- selected-list entry loading/failure;
- populated saved-entry list;
- empty selected list;
- local search and no-result state;
- collection selection;
- create list with required-name validation;
- manual entry with only verified fields: word, optional reading, meaning, and
  optional note;
- delete confirmation, pending indicator, success update, and visible failure;
- Japanese text and narrow portrait layout;
- optional detail navigation only when a data source supplies a proven
  vocabulary route key.

JLPT filters, SRS-state filters, progress, due counts, audio, offline badges,
list sharing, entry edit, and entry move from Stitch were not implemented
because Notebook responses/contracts do not support them.

## Real, local, and fixture behavior

API-backed:

- list/create collections;
- load entries for one collection;
- create a manual entry;
- bookmark a real vocabulary bank ID into a real collection;
- delete a real note entry by noteEntryId.

Local-only:

- search over entries already returned for the selected list;
- transient mutation/loading/error state;
- immediate in-memory count/list updates after a successful server response.

No Drift cache was added. The current Drift draft contains offline/SRS concepts
whose synchronization contract is not established, so C14 does not treat it as
server-synchronized state.

Fixture-backed:

- the explicit fixture repository uses fixture-prefixed keys and null remote
  IDs;
- it is labeled Dữ liệu mẫu;
- it is never an automatic fallback for authenticated production Notebook
  failures.

## C11 Vocabulary integration

C11 now uses the shared NotebookRepository, NotebookCollection, and
NotebookBookmark types for real list loading and vocabulary bookmark calls.
The duplicate Vocabulary-specific Notebook DTO/repository implementation was
removed.

For a C11 fixture detail, the save interaction remains a clearly local,
fixture-only state transition with no fake network success. For a remote
vocabulary entry, saving calls the real Notebook API and retains the returned
noteEntryId in the session state.

The backend cannot restore isSaved reliably after reload, cannot find a
bookmark by source vocabulary ID, and does not prevent duplicates. C11
therefore does not invent durable saved-state reconciliation or a speculative
unsave flow.

## Deferred to C15 or backend work

- SRS scheduling and review UI;
- offline review queues;
- Drift/server reconciliation;
- retry and idempotency strategy;
- sync versions, tombstones, and conflicts;
- global/paginated Notebook search;
- reliable saved-state lookup;
- duplicate-bookmark enforcement;
- source-ID exposure for remote detail navigation;
- entry edit/move and richer custom fields.
