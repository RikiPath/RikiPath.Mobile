# Kanji Implementation (Phase C12)

## Scope

Phase C12 implements the portrait learner Kanji library and Kanji detail flow.
It adds:

- `/learn/kanji`
- `/learn/kanji/:entryKey`
- character/meaning search
- N5/N4/N3 filters
- paged loading when the selected data source has another page
- loading, empty, error, and load-more error states
- verified Kanji detail fields
- optional audio playback
- Kanji-to-Notebook bookmarking for remote IDs
- an internal stroke-order detail state when an image or typed fixture steps
  are available

Grammar, the full Notebook experience, SRS, mock tests, AI, and writing practice
are outside this phase.

## Contract evidence

Live Swagger at `http://140.245.43.97/swagger/v1/swagger.json` was accessible on
2026-09-12. It confirms these operations and request field names:

- `POST /api/SharedBank/kanji/search`
  - `jlptLevelId`, `keyword`, `page`, `pageSize`, `minStrokeCount`,
    `maxStrokeCount`
- `GET /api/SharedBank/kanji/{id}`
- `GET /api/Notebook/lists`
- `POST /api/Notebook/bookmark/kanji`
  - `vocabularyListId`, `kanjiEntryId`

Swagger publishes no usable response schemas and declares only a generic 200
response. Response parsing therefore follows the inspected read-only backend
source and verified API envelope structure. A live unfiltered Kanji search
returned a successful empty page; detail ID 1 returned 404 at verification
time.

The source-backed Kanji fields used by the frontend are:

- `id`
- `character`
- nullable `onYomi`
- nullable `kunYomi`
- nullable `sinoVietnamese`
- `meaning`
- `strokeCount`
- nullable `strokeOrderUrl`
- nullable `audioUrl`
- `jlptLevelName`

`onYomi` is intentionally parsed as nullable. The source entity is nullable,
even though the response class declares it as non-nullable, and null JSON
properties are omitted globally.

## Architecture

The module follows:

`Presentation -> Riverpod controller -> Repository -> Remote/Fixture -> DTO -> Mapper -> Domain`

- Widgets receive domain types and callbacks only.
- `ApiKanjiRepository` is the only Kanji search/detail layer using the shared
  `ApiClient`.
- `ApiKanjiNotebookRepository` owns the verified bookmark request.
- DTOs preserve exact backend JSON names.
- `KanjiMapper` enforces the mobile N5/N4/N3 scope and accepts only absolute
  HTTP(S) media URLs.
- `FallbackKanjiRepository` uses fixtures only for an empty first remote page
  or a JLPT filter that cannot be translated safely to a backend ID.

## Remote and fixture identity

Remote records use route keys such as `remote-27` and retain the numeric backend
ID. Visual-development records use `fixture-*` keys and have `remoteId == null`.
Fixture keys are never sent to the API.

The deployed API does not publish an endpoint mapping the names N5/N4/N3 to
numeric JLPT level IDs. Selecting a JLPT chip therefore filters the typed
fixture repository; the frontend never guesses an ID.

## Stitch-only enrichment

The approved `KANJI_01`, `KANJI_02`, and `KANJI_03` PNGs are the visual source.
Their HTML is used only to clarify hierarchy and states.

Radical labels, mnemonics, compounds, translated examples, stroke steps, and
writing rules do not exist in the Kanji API response. They live only inside the
typed `KanjiEnrichment` fixture model and are labeled as sample Stitch content.
Remote detail renders only fields that the backend can supply.

The backend exposes at most one nullable stroke-order image URL. It does not
publish vectors, per-stroke paths, directions, animation timing, playback
speed, or writing rules. The production UI does not manufacture those fields.

## Search and pagination behavior

Backend source search matches only `character` or `meaning`. The fixture follows
the same behavior; readings and Hán-Việt are not silently treated as supported
search fields.

Requests use conservative defaults of page 1 and page size 20. Source inspection
shows a server cap of 100, but live Swagger does not publish that constraint.
The list exposes “Xem thêm” only when `page < totalPages`.

## Notebook behavior

Remote bookmarking first loads the learner's Notebook lists and then posts a
real `kanjiEntryId`. Fixture bookmarking is local presentation state and uses a
negative fixture list ID. It never calls the backend.

Saved state cannot be restored reliably because SharedBank responses have no
saved flag and Notebook entry responses do not include the original
`kanjiEntryId`. Duplicate/idempotent behavior is also undocumented. These gaps
remain in `API_GAPS.md`.

## Tests

The C12 tests cover:

- exact search/detail/bookmark routes and JSON names
- nullable response fields and URL validation
- rejection of unsupported JLPT levels
- no invented numeric JLPT mapping
- fixture search scope, N5/N4/N3 filtering, stroke ranges, and pagination
- remote/fixture ID separation and fallback behavior
- library search, filters, navigation, and Learn-tab preservation
- detail sections, stroke-order internal state, and local fixture bookmark state
- loading, empty, error, and 320 px portrait layouts
- absence of Dio/raw envelope access in presentation code
- Japanese/Vietnamese Unicode integrity

## Confirmed limitations

See `API_GAPS.md` for the complete C12 table. The critical remaining blockers
are an empty deployed Kanji bank, no JLPT name-to-ID catalog, no published-only
content enforcement, and no saved-state reconciliation contract.
