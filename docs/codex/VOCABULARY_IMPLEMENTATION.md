# C11 Vocabulary Implementation

Implemented on: 2026-09-12 (Asia/Bangkok)

## Scope

C11 implements the learner Vocabulary Library and Vocabulary Detail flow. It
includes typed search, N5/N4/N3 filters, pagination state, loading, empty,
error, detail navigation, optional audio playback, and the smallest verified
Notebook bookmark interaction.

It does not implement the full Notebook feature, invent JLPT IDs, fabricate
audio URLs, or treat Stitch-only enrichment as backend data.

## Contract verification

Live Swagger was accessible at:

```text
http://140.245.43.97/swagger/v1/swagger.json
```

The deployed document confirms these C11 operations:

- `POST /api/SharedBank/vocabulary/search`
- `GET /api/SharedBank/vocabulary/{id}`
- `GET /api/Notebook/lists`
- `POST /api/Notebook/bookmark/vocabulary`

The vocabulary search body contains exactly `jlptLevelId`, `keyword`, `page`,
and `pageSize`. The bookmark body contains exactly `vocabularyListId` and
`vocabularyEntryId`.

Swagger applies a global Bearer description, but the supplied SharedBank source
has no authorization attribute and a runtime vocabulary search succeeded
without a token. Notebook source requires the Learner role. Live Swagger
publishes no typed response schema or useful per-operation status contract, so
response parsing is based on the supplied response types and observed envelope.

The runtime search returned a successful empty page during verification. C11
therefore displays typed, clearly labeled fixtures when the first unfiltered
remote page is empty. Remote failures remain visible errors and are not hidden
by fallback data.

## Stitch references used

Each approved `VOCABULARY_*` folder was inspected recursively. `screen.png` was
the primary visual source and `code.html` was secondary layout/copy evidence.

| Experience | Approved folder |
|---|---|
| Vocabulary library | `VOCABULARY_01_Danh sách từ vựng/` |
| Vocabulary detail | `VOCABULARY_02_Chi tiết từ vựng/` |
| Saved state | `VOCABULARY_03_Từ vựng - Đã lưu vào Sổ từ/` |

The implementation reuses RikiPath spacing, typography, cards, buttons, JLPT
badges, learner header, red accent, and portrait layout. It does not copy the
external image URL present in the HTML reference.

The Stitch `Đã học` and `Đã lưu` list filters are not implemented because no
bank response or query contract supports them.

## Routes and navigation

Both routes are nested under the indexed Learn branch:

```text
/learn/vocabulary
/learn/vocabulary/:entryKey
```

The Vocabulary card on Learning Home opens the library. List cards open detail
through `AppRoutes`; Widgets do not hardcode paths. The **Học tập** bottom tab
remains selected and its branch state is preserved.

Route keys distinguish data identity explicitly:

- `remote-<id>` wraps a verified numeric backend vocabulary ID.
- `fixture-<name>` is local visual-development identity and has `remoteId == null`.

Fixture keys are never sent to the backend.

## Architecture

```text
Vocabulary screens/views
  -> Riverpod AsyncNotifier controllers
  -> VocabularyRepository / VocabularyNotebookRepository
  -> ApiVocabularyRepository or FixtureVocabularyRepository
  -> source-backed DTO parsing and VocabularyMapper
  -> Vocabulary domain models
```

`FallbackVocabularyRepository` delegates unfiltered requests to the remote API.
It uses fixtures only when the first remote page is successfully empty. Because
the backend publishes no N5/N4/N3 name-to-ID mapping, a selected JLPT level is
filtered in the typed fixture repository instead of sending a guessed integer.

Presentation files receive domain objects and callbacks. They contain no Dio
imports, endpoint paths, response JSON parsing, or backend DTOs.

## Supported fields

Remote list/detail rendering uses only source-backed `VocabularyCardResponse`
fields:

- `id`
- `word`
- `reading`
- `meaning`
- `partOfSpeech`
- `exampleSentence`
- `audioUrl`
- `jlptLevelName`

`partOfSpeech`, `exampleSentence`, and `audioUrl` are treated as nullable at the
frontend boundary because inspected mapper/runtime serialization behavior does
not guarantee them.

Fixture enrichment is modeled separately as `VocabularyEnrichment`. It covers
the approved detail composition without claiming API support: Hán-Việt,
definition, translated examples, collocations, nuance, Kanji analysis,
frequency, and related lesson metadata. A visible notice identifies this
content as local fixture data.

## Notebook and saved state

For a remote entry with a numeric backend ID, the detail controller loads real
Notebook lists and posts the exact bookmark request. For a fixture entry, save
state is local and the list is labeled as sample data.

The frontend does not claim durable saved-state reconciliation. Bank responses
have no saved flag, Notebook responses omit the original `vocabularyEntryId`,
and deletion requires a `noteEntryId`. Those gaps remain in `API_GAPS.md`.

## Audio

`VocabularyAudioPlayer` isolates `just_audio` from presentation. Playback is
enabled only for a valid absolute HTTP(S) `audioUrl` supplied by the API. The
fixtures contain no fabricated audio URL, so their audio controls are disabled
with explicit copy.

No TTS, sentence audio, URL refresh, caching, or token behavior was invented.

## Tests

The C11 suite covers:

- exact remote search/detail paths and body field names;
- source envelope parsing and nullable fields;
- Notebook list and bookmark contracts;
- rejection of guessed JLPT numeric IDs;
- fixture keyword search, N5/N4/N3 filtering, and pagination;
- fixture fallback only for a successful empty first remote page;
- library list, search, filter, loading, empty, and error states;
- detail navigation and local fixture save state;
- Learn-tab preservation;
- list and detail rendering at 320-pixel portrait width;
- absence of direct Dio use in the Vocabulary presentation layer.

## Confirmed backend gaps

The complete prioritized table is maintained in `API_GAPS.md`. The primary C11
blockers are:

- empty deployed vocabulary data during verification;
- no discoverable JLPT name-to-ID mapping;
- card-only detail contract without Stitch enrichment;
- source mapper omission for part of speech;
- ambiguous example-sentence nullability and no translation;
- no reliable saved-state reconciliation or idempotent bookmark behavior;
- nullable audio without media lifecycle semantics;
- no confirmed published-only content filtering;
- no published pagination constraints.

Future remote work must resolve these contracts rather than embedding assumed
IDs, fields, URLs, or status behavior in Flutter.
