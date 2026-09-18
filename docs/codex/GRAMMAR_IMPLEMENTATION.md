# Grammar Implementation (C13)

## Scope

C13 implements only the learner Grammar library and Grammar detail flow. It
does not implement Notebook/SRS, mock tests, AI, audio, lesson launch, or
practice actions.

Routes:

- `/learn/grammar`
- `/learn/grammar/:entryKey`

Both routes are children of the existing Learn branch, so the Học tập bottom
tab remains active and its indexed-stack state is preserved.

## Verified API contract

Live Swagger was reachable at
`http://140.245.43.97/swagger/v1/swagger.json` on 2026-09-13 and was used as the
primary deployed-operation reference.

| Method | Route | Source auth | Request | Runtime/source response |
|---|---|---|---|---|
| POST | `/api/SharedBank/grammar/search` | Public in source | `jlptLevelId`, `keyword`, `page`, `pageSize` | `ApiResponse<PagedResult<GrammarCardResponse>>` |
| GET | `/api/SharedBank/grammar/{id}` | Public in source | Required positive integer path ID | `ApiResponse<GrammarCardResponse>` |

`GrammarCardResponse` contains only `id`, `title`, `structure`, `explanation`,
`exampleSentence`, and `jlptLevelName`. Live Swagger publishes only an untyped
200 response, so the response shape is verified from the supplied read-only
backend source and observed envelopes, not from a generated OpenAPI schema.

Runtime checks returned an empty successful page for search and the expected
HTTP 404 envelope for detail ID 1. No successful live Grammar item was
available for response-value verification.

## Backend source cross-check

- Search normalizes `page` to at least 1, `pageSize` to 20 when below 1, and
  caps `pageSize` at 100.
- Search matches `Title`, `Structure`, and nullable `UsageNotes`, orders by ID
  descending, and includes the JLPT relation.
- Search passes no content status, and detail performs no published-status
  check.
- `UsageNotes` maps to `explanation`; nullable `ExampleSentence` maps directly
  to `exampleSentence`.
- Global JSON configuration omits null fields. The frontend therefore parses
  `explanation` and `exampleSentence` as optional even though the C# response
  properties are declared non-nullable.
- `ExampleSentenceMeaning` exists on the entity but is not mapped to the bank
  response.
- No endpoint publishes the numeric ID corresponding to N5/N4/N3.

The confirmed limitations are recorded in `API_GAPS.md`.

## Architecture

```text
Grammar screens/widgets
  → Riverpod async controllers
  → GrammarRepository
  → FallbackGrammarRepository
       → ApiGrammarRepository → ApiClient → Dio
       → FixtureGrammarRepository
  → DTO → mapper → domain models
```

Widgets receive typed domain state and callbacks. They contain no Dio calls,
endpoint strings, raw JSON access, or fixture declarations.

Remote entries use `remote-<id>` route keys and retain the numeric backend ID
separately. Fixtures use `fixture-*` keys and always have `remoteId == null`.
Fixture keys are never sent to the API.

## API-backed UI

The production DTO/domain mapping can render only:

- Grammar title
- Structure
- Explanation when present
- One example sentence when present
- JLPT label limited to N5/N4/N3
- Paged search metadata

Search and detail use the exact verified routes. A selected JLPT chip is not
sent remotely because the required numeric mapping is unavailable.

## Fixture fallback

The deployed bank was empty during C13 verification. A typed fixture
repository provides a clearly labeled portrait UI reference when the first
remote page has zero results. It also provides local N5/N4/N3 filtering and
pagination for deterministic development and tests.

Stitch-only enrichment—usage guidance, translated examples, cautions, and
related Grammar—is isolated in `GrammarEnrichment`. Remote mapping never
populates that field. Network/contract failures are not swallowed by the
fallback; they render the error state.

## Stitch normalization

All three `GRAMMAR_*` PNGs and their HTML references were inspected. The
implementation preserves the approved RikiPath mobile language: pale learner
background, white rounded cards, brand-red accents, compact JLPT chips,
portrait spacing, Japanese text, and the Learn tab context.

The third reference is normalized as a related-Grammar section inside the
existing detail route, not as an invented third route. Unsupported Stitch
controls (audio, save/un-save, share, practice, lesson links, learning-status
filters, category counts) are intentionally omitted.

## States and tests

The library supports loading, success, empty, error, search, JLPT fixture
filtering, load-more pagination, and load-more failure. Detail supports
loading, supported API sections, fixture enrichment, related-item navigation,
and error/retry.

Tests cover exact DTO keys/routes, nullable mapping, N5/N4/N3 enforcement,
search scope, pagination, fallback, remote/fixture ID separation, list/detail
navigation, detail sections, loading/empty/error states, 320 px portrait
layout, Learn-tab selection, Unicode integrity, and the no-Dio/raw-JSON widget
boundary.

## Deferred to C14 or later

- Notebook save/remove and restored saved state
- Duplicate-safe bookmark behavior
- Real JLPT ID discovery and remote level filters
- Published-content enforcement
- Multiple examples and Vietnamese translations from the API
- Related-Grammar and comparison contracts
- Audio, lesson linkage, and practice navigation
