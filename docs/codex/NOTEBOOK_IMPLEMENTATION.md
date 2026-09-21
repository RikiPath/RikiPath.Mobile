# Personal Vocabulary Notebook Implementation

Status: Phase C14 completed on 2026-09-20.

## Contract sources

The implementation was checked against the current Flutter code, live OpenAPI
at `http://140.245.43.97/swagger/v1/swagger.json`, the read-only backend at
revision `006c45cf7d863c1d5fa38b93a0b680cd37b5689d`, and the Sakura Notebook
references. Live Swagger exposes ten Learner-only `/api/Notebook` operations.
C14 uses the existing contracts for list read/create, per-list entry read,
manual add, vocabulary bookmark, and entry delete.

Swagger still publishes no typed success bodies. Source-backed responses are:

- `VocabularyListResponse`: `id`, `name`, nullable `description`,
  `entryCount`, `createdAt`.
- `NotebookEntryResponse`: `noteEntryId`, nullable `reviewItemId`, plain-string
  `contentType`, `term`, nullable `reading`, `meaning`, nullable `note`,
  `addedAt`.

The controller requires Bearer authentication with the `Learner` role.

## Existing code reused

C14 retained the existing Sakura Notebook screens, routes, domain objects,
request/response DTOs, mapper, exact API paths, authenticated `ApiClient`,
Riverpod controllers, search UI, collection selector, manual-entry form, and
remove-confirmation dialog. No parallel Notebook feature was created.

## Architecture and source of truth

```text
Notebook / Vocabulary presentation
  → Riverpod controllers
  → NotebookRepository
  → PersistentNotebookRepository
      ├─ ApiNotebookRepository (verified remote contract)
      └─ NotebookLocalStore → Drift AppDatabase
```

`savedVocabularyKeysProvider` observes the repository's Drift-backed saved keys.
Vocabulary Library, Vocabulary Detail, and Notebook mutations all use this same
source. The former independent `VocabularyEntry.isSaved` and detail-controller
bookmark state were removed.

After a successful save or remove, Drift emits the new saved-key set. Existing
Vocabulary screens therefore update without maintaining their own booleans.
Saving also invalidates the Notebook controller so an already-created shell tab
reloads its current repository state.

## Persistence and identity

The existing `VocabularyLists` and `PersonalVocabularyEntries` Drift tables are
reused. Schema version 2 adds only the fields needed to cache the verified
Notebook response, including remote IDs, content type, note, timestamps, source,
entry count, and an explicit entries-cache marker.

Local rows are scoped with the authenticated user ID. Public route identity
remains the C11 stable `entryKey`:

- remote vocabulary: `remote-{VocabularyEntryId}`;
- fixture/local vocabulary: its existing `fixture-*` key;
- backend numeric IDs remain nullable and separate;
- note IDs are never reused as vocabulary IDs.

Duplicate save checks use the stable vocabulary route key before calling the
backend. This prevents duplicate client calls after the item has been cached,
including after an app restart. It does not claim backend-wide idempotency.

## Vocabulary integration

For a remote vocabulary entry and remote list, the repository sends the exact
`vocabularyListId` and `vocabularyEntryId` request. The returned `noteEntryId`
is cached beside the stable vocabulary key. For a fixture/local entry with no
verified backend ID, the save stays local and sends no fabricated numeric ID.

Notebook removal calls the verified remote delete when a real `noteEntryId`
exists, then removes the cached row. Local-only rows are removed only from
Drift. Both paths update the shared saved-state stream.

## Search and filtering

Search is deterministic and local over the selected collection's term, reading,
meaning, and note. Collection chips are the supported filter because both API
and UI have real list identity. No JLPT or SRS-status filter is presented:
`NotebookEntryResponse` contains neither JLPT level nor review status.

## Offline behavior

Successfully loaded collections and entries remain readable and searchable
from Drift when the remote read fails. Entries with a known stable vocabulary
key can still open their established detail route. Local fixture saves persist
and can be removed without a server ID.

Remote create/save/delete still require the server. C14 does not queue remote
mutations or claim cloud conflict resolution because the backend has no sync
version, tombstone, idempotency, or reconciliation contract.

Status:

- Remote Notebook API: **AVAILABLE_AND_USED**
- Durable local read cache: **COMPLETE**
- Shared saved-state source: **COMPLETE**
- Offline remote mutation synchronization: **BACKEND_SYNC_NOT_AVAILABLE**

## Confirmed limitations

1. `NotebookEntryResponse` omits `vocabularyEntryId`. A bookmark first seen only
   through a server list response cannot be related to a Vocabulary detail key.
2. The backend does not reject duplicate bookmarks and exposes no idempotency
   key. Client duplicate protection only applies once the stable relation is in
   the local cache.
3. There is no all-list saved-state lookup or global Notebook search endpoint.
4. There is no entry update/move endpoint or offline sync protocol.
5. Existing server bookmarks created before the local relation was recorded
   remain listable/removable but cannot safely open Vocabulary Detail.

## Test coverage

Focused tests cover exact API paths/bodies, typed mappings, save, duplicate save,
repository recreation, cached offline reads, deterministic remove, empty/loading/
error states, search/search-empty, collection filtering, remove cancel/success,
Vocabulary ↔ Notebook state synchronization, VI/JA strings, 320px layout, and
the absence of fabricated backend IDs.
