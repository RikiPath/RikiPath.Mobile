# Codex Rules for RikiPath Mobile

These rules apply to every future Codex phase in this repository. They are mandatory unless the repository owner explicitly changes them.

## 1. Repository scope

- The backend reference copy is `RikiPath.Backend/`. The task description may also refer to it as `RikiPath Backend/`; both names mean the backend reference copy, and the directory that exists in this checkout is `RikiPath.Backend/`.
- Treat the entire backend directory, including its nested `.git/`, as strictly read-only.
- Backend inspection may cover controllers, routes, DTO/request/response types, entities, enums, validation, authentication contracts, and Swagger/OpenAPI setup.
- Never edit, format, rename, move, delete, or generate a file under `RikiPath.Backend/`.
- Never run migrations or attempt to fix backend code.
- Do not run backend commands that can create or update files in the reference copy, including restore, build, test, format, scaffolding, code generation, or Entity Framework commands. Read-only searches and Git status/diff checks are allowed.
- Modify only Flutter/mobile frontend files and frontend documentation or configuration that is in scope for the current task.
- Do not refactor unrelated Flutter code. Keep every change within the requested phase.

## 2. API contracts are evidence-based

- API routes, HTTP methods, path/query parameters, request fields, response fields, nullability, enum values, validation limits, authentication requirements, and response envelopes must come from the deployed Swagger/OpenAPI contract or the backend reference source.
- The deployed reference is [RikiPath API Swagger](http://140.245.43.97/swagger/index.html).
- Use the local backend in this order: controller route/action, request or response type, validation attributes, enum/entity definition, then service behavior when needed to resolve a contract detail.
- `docs/API_CONTRACT_DRAFT.md` is a planning draft, not an authoritative API contract.
- Never invent an endpoint.
- Never invent, rename, or silently omit an API DTO field.
- Never assume a conventional endpoint exists, including refresh, logout, list, detail, batch, autosave, or sync endpoints.
- Never infer a response model solely from UI mock data.
- When Swagger and the backend copy disagree, record the mismatch and stop that integration until the intended contract is confirmed. Do not choose a shape by guesswork.
- When Swagger omits a typed response schema, inspect the matching local response type and service/controller behavior. If the deployed response still cannot be verified, treat that as a blocker.
- Respect the backend `ApiResponse<T>` envelope where the inspected endpoint returns it: `statusCode`, `isSuccess`, optional `errorMessage`, optional `errors`, and optional `result`.
- Respect the backend's string enum serialization. Do not replace server enum strings with guessed numeric values.

## 3. Authentication and secrets

- Never place API keys, JWT signing secrets, database credentials, payment credentials, AI provider credentials, private tokens, or other secrets in Flutter source, assets, build scripts, logs, examples, or committed environment files.
- A mobile binary cannot safely keep a shared secret. Secret-bearing integrations must remain server-side.
- Store user access credentials only through the approved secure-storage abstraction. Do not log tokens or include them in error messages.
- Do not implement refresh-token behavior until an actual refresh endpoint and response contract are present. The inspected login contract currently returns an access token only.
- Keep the API base URL in centralized environment/flavor configuration and the network layer.
- Never hardcode an API base URL or endpoint URL inside a Widget or presentation file.
- Build endpoint paths in a dedicated API/data layer, not in button handlers or screens.

## 4. Product scope and UI

- Learner-facing JLPT support is N5, N4, and N3 only unless the current deployed Swagger and backend learner contract explicitly prove that another level is supported and the task authorizes exposing it.
- Do not add N2 or N1 merely because they exist in the general JLPT standard or in a backend comment. Confirm a usable learner-facing contract and data source first.
- Design and verify the app as a portrait mobile UI. Account for safe areas, the software keyboard, narrow phone widths, vertical scrolling, and touch targets.
- Do not make landscape, tablet, desktop, or web layout the primary experience unless a later task explicitly expands the supported form factors.
- Preserve the existing RikiPath visual language: Material 3 foundation, centralized colors/spacing/radii, rounded outlined cards, and the five-destination mobile navigation shell.
- Reuse `AppTheme`, `AppColors`, `AppSpacing`, `AppRadius`, `AppSectionCard`, and `JlptBadge` where appropriate. Add or adjust shared tokens/components centrally rather than creating a second visual system in feature screens.
- The current theme tokens are explicitly marked temporary. Do not present them as final brand tokens; replace them only from an approved RikiPath visual reference.
- Treat `docs/ui_reference/` PNG and HTML exports as visual evidence, not production source code. Do not edit the reference exports unless a task explicitly requests it.
- Translate approved reference values into Flutter theme tokens and reusable components. Do not copy Tailwind markup, simulated status bars, browser-only scripts, or fixed screenshot dimensions into Flutter Widgets.
- If reference exports disagree on a token or behavior, record the discrepancy and obtain a decision instead of inventing a new value.

## 5. Japanese text and localization

- Preserve Japanese strings as Unicode and verify that kanji, hiragana, katakana, punctuation, and mixed Japanese/Vietnamese text render without mojibake or missing glyphs.
- Use a Japanese-capable font and fallback chain. A font family name in `ThemeData` is not proof that the font ships on every device; bundle and declare an approved font if platform coverage is not guaranteed.
- Test representative Japanese content on target Android/iOS builds, including wrapping, line height, text scaling, and narrow portrait layouts.
- Do not replace Japanese text with romanization merely to avoid a rendering problem.
- Keep user-facing strings ready for localization; do not spread new repeated strings through business or data code.

## 6. Architecture boundaries

- Widgets render state and dispatch user intent. They must not own HTTP calls, endpoint strings, token handling, database synchronization, or DTO parsing.
- Put API DTOs and serializers in the frontend data layer, domain behavior in domain/application abstractions, and UI state in Riverpod providers/notifiers or the established equivalent.
- Keep the Dio client, authentication header handling, timeout policy, and API base configuration centralized.
- Keep offline persistence behind repositories/services. Do not make Drift rows the public UI model by default.
- Do not implement offline conflict, version, idempotency, batching, or SRS payload fields until the backend exposes the required contract.

## 7. Verification for implementation phases

- This audit-only phase does not authorize feature implementation.
- After every later implementation phase, format only changed frontend files, then run `flutter analyze` and `flutter test`.
- Run focused tests in addition to the full test command when the changed area has dedicated tests.
- If code generation is required, generate only frontend artifacts and review them before completion.
- Report unavailable tooling or pre-existing failures explicitly; never claim a check passed when it was not run.
- Before and after work, inspect backend Git state. At completion, verify both tracked and untracked state under `RikiPath.Backend/` are unchanged. At minimum, run the equivalent of:

  ```powershell
  git -C RikiPath.Backend status --short
  git -C RikiPath.Backend diff --exit-code
  ```

- If Git safe-directory protection applies, use a per-command read-only `safe.directory` override rather than changing backend files.
- If an outer frontend Git repository is available, also confirm its diff contains no path under `RikiPath.Backend/`.
- Do not mark a phase complete if any backend path was created, modified, renamed, or deleted.

## 8. Completion report

Every implementation handoff must state:

- frontend files changed;
- contract sources used;
- analysis/tests run and their results;
- known blockers or unresolved contract gaps; and
- explicit confirmation that no file under `RikiPath.Backend/` was modified.
