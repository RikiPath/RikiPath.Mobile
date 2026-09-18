# RikiPath Stitch Mobile Design Specification

## Purpose and authority

This document records the reusable mobile design evidence currently available under `docs/ui_reference/stitch_mobile/`. It began as the C4A Auth/Onboarding audit and is updated as approved references are implemented. The C13.5 Neo-Japoniste Sakura set is the current visual authority; earlier red/blue phase notes are historical only.

Source priority is permanent for these references:

1. `screen.png` is the primary visual source of truth.
2. `code.html` is secondary evidence for structure, measurements, and color values.
3. Existing Flutter code is useful for reuse decisions, but cannot override approved visual evidence.

The generated HTML is not production code. It must not be embedded in a WebView or translated element-for-element into Flutter. Where HTML and PNG differ, the PNG wins.

## Reference inventory

The current recursive inventory contains:

- 67 screen folders
- 67 `screen.png` files
- 67 `code.html` files
- one design-system folder containing `neo_japoniste_sakura/DESIGN.md`

The original C4A subset formed four route-level experiences and eight additional visual states or steps:

- Login: normal, validation, loading
- Registration: normal, validation, loading, success
- Password recovery: request, request-success
- Onboarding: JLPT goal, study duration, completion

Exact screen ownership and route/state classification are in `docs/codex/UI_SCREEN_REFERENCE.md`.

C8 specifically adds deep analysis of four `HOME_*` references and five `SHELL_*` references. Other folders are inventory evidence only until their feature phase reviews them against API and routing contracts.

### Historical C8 post-auth reference map

Every folder below contains both a primary `screen.png` and secondary `code.html`.

| Reference folder | Existing route/state | Visual pattern and reuse decision |
|---|---|---|
| `HOME_01_Trang chủ - Người học mới/` | `/home` success variant | New-learner greeting, target/streak, first lesson, roadmap, setup checklist, and two tool shortcuts; source for Home fixture and feature-local Home cards. |
| `HOME_02_Trang chủ - Trạng thái ngoại tuyến/` | `/home` cached/offline variant | Offline banner plus cached learning/review/advisory content; presentation recorded, persistence behavior deferred. |
| `HOME_03_Trang chủ - Trạng thái đang tải/` | `/home` loading variant | Pale-blue skeleton hierarchy inside persistent shell chrome; source for `HomeLoadingView`. |
| `HOME_04_Thông báo/` | No registered route | Notification list/filter composition; route/tab ownership remains unresolved and no route is invented. |
| `SHELL_01_Trang chủ - Mobile Shell/` | `/home`, branch 0 | Established-learner Home and selected Home tab; shell evidence only beyond the C8 new-learner variant. |
| `SHELL_02_Học tập - Mobile Shell/` | `/learn`, branch 1 | Learning root hierarchy and selected Learn tab; deep content deferred. |
| `SHELL_03_Luyện tập - Mobile Shell/` | `/practice`, branch 2 | Practice root hierarchy and selected Practice tab; deep content deferred. |
| `SHELL_04_Sổ từ - Mobile Shell/` | `/notebook`, branch 3 | Notebook/SRS root hierarchy and selected Notebook tab; deep content deferred. |
| `SHELL_05_Cá nhân - Mobile Shell/` | `/profile`, branch 4 | Profile root hierarchy and selected Profile tab; deep content deferred. |

This table preserves phase provenance. Its old folder names and blue/red descriptions do not override the current `*_sakura` exports. The reusable cross-route result remains `RikiBottomNavigationBar`; C13.5 also establishes `RikiBrandLockup` as the shared brand unit.

## Visual language

RikiPath uses a clean, friendly portrait-mobile language:

- Warm Sakura-tinted near-white pages with ink-neutral text.
- Sakura `#E05A7A` for identity, selection, links, progress, and primary actions.
- Rounded controls and cards, normally with a thin border and very low elevation.
- Small pastel badges and banners for AI hints, JLPT context, success, warning, and progress.
- Strong title hierarchy, compact form labels, generous vertical separation, and full-width primary CTAs.
- Friendly emoji and simple line icons as accents, while core controls remain conventional and readable.
- Success views use centered mint/emerald illustrations and keep the main action near the bottom.
- Onboarding uses large selectable cards, explicit selected treatment, and visible step progress.
- Learner pages use a warm `#FFF9FA` canvas, compact white top and bottom surfaces, Sakura active navigation, and border-led white cards.
- Home uses a responsive single-column information hierarchy with greeting, next action, roadmap/setup summaries, and compact tool shortcuts.

The screenshots contain simulated iOS status bars and, in some HTML files, browser-only device frames. Flutter must use the platform status area through `SafeArea`; it must not recreate those status bars or device frames.

## Color tokens

The Neo-Japoniste Sakura `DESIGN.md`, current `*_sakura/screen.png` files, and their HTML overrides establish the following current roles. The earlier burgundy and blue learner palette is deprecated.

| Flutter role | Value | Rule |
|---|---:|---|
| `brandPrimary` | `#E05A7A` | Primary CTA, active navigation, brand mark/wordmark, focused input, and in-progress fill. |
| `brandPrimaryPressed` | `#C24362` | Pressed primary action and N4 foreground. |
| `brandSecondary` | `#F8BBD0` | Supporting Sakura surface, chip/level selection, and progress-track family. |
| `brandTint` / `brandSelectedTint` | `#FFF0F3` | Selected study card and quiet highlighted state. |
| `surfaceContainer` | `#FCE7EB` | Active navigation pill, interactive chip, secondary action, and progress track. |
| `surfaceContainerHigh` | `#F8DBE2` | Pressed/nested tonal container. |
| `background` | `#FFF9FA` | Warm portrait learner canvas. |
| `surface` / `input` | `#FFFFFF` | Elevated cards, headers, sheets, and normal fields. |
| `inputProcessing` | `#F6EBEE` | Disabled/read-only field surface. |
| `textPrimary` / `textBody` | `#2D282A` | Ink neutral for headings, body, meanings, and Japanese glyphs. |
| `textSecondary` | `#695F63` | Metadata, reading annotations, and inactive navigation. |
| `textMuted` / `textDisabled` | `#9E9397` | Placeholder and disabled content. |
| `border` | `#E8DDE0` | Default card, field, divider, and bottom-bar outline. |
| `borderStrong` | `#DDBFC3` | Stronger neutral/level boundary. |
| `success` | `#079D47` | Verified mastery, correct answer, and completed progress only. |
| `successBackground` | `#E8F5E9` | Verified success surface. |
| `successBorder` | `#C8E6C9` | Verified success outline. |
| `error` / `errorText` | `#D32F2F` | Validation, incorrect answer, destructive/reset action. Never substitute brand Sakura. |
| `errorBackground` | `#FDEDED` | Error/validation container. |
| `warning` | `#F59E0B` | Countdown, review, and caution accent. |
| `warningBackground` | `#FFFBEB` | Warning/tip container. |
| `information` | `#1976D2` | Linguistic note or informational state, not brand identity. |

Existing `learner*` Flutter names are compatibility aliases and resolve to the same Sakura surface/text roles; they no longer define a separate blue post-auth theme.

### JLPT and selection colors

- N5 uses `#E05A7A` on `#FCE7EB`.
- N4 uses `#C24362` on `#F8BBD0`.
- N3 uses `#942B46` on `#E8DDE0`.
- The learner product enum remains N5/N4/N3 only. N4 shown in a reference is sample state, not a global learner constant.
- Selected cards use `#FFF0F3` with an emphasized `#E05A7A` outline. Selected chips use a light Sakura container with Sakura foreground/border; they do not become solid destructive-looking red.

### Current Flutter theme alignment

`AppColors`, `AppTheme`, and `AppShadows` now own these roles. Feature Widgets consume the tokens rather than repeating raw Sakura hex values. Success, warning, information, and destructive/error treatments remain semantic and visually separate from primary brand actions.

## Typography

### Font evidence

- Eleven of the original twelve Auth/Onboarding HTML files use a platform system sans stack: `-apple-system`, `BlinkMacSystemFont`, `Segoe UI`, `Roboto`, `Helvetica`/`Arial`, `sans-serif`. Some include Apple `SF Pro Text` or `SF Pro Display` as an optional system face.
- `ONBOARDING_03_Hoàn tất - Sẵn sàng học/code.html` loads Inter weights 400, 500, 600, 700, and 800 from Google Fonts and sets Inter as its sans family.
- The C8 Home/shell HTML declares Inter with `Noto Sans JP` fallback. This remains style evidence only because neither font asset is bundled.
- The Flutter `pubspec.yaml` has no font declaration, and the repository contains no `.ttf`, `.otf`, `.woff`, or `.woff2` font assets.
- The current Flutter theme supplies fallback family names `Noto Sans`, `Noto Sans JP`, and `Roboto`, but no matching files are bundled. A family name alone does not guarantee that the font is installed on every device.

Therefore, a canonical branded typeface is not yet proven. Preserve the system-sans appearance for future implementation unless an approved, licensed font asset is provided. Do not add Inter or any random replacement solely because one export references it.

### Type scale

Sizes and line heights are logical Flutter pixels, derived from the HTML classes and checked against the PNG hierarchy. The “normalized use” column is guidance for later centralized theme work, not code added in this phase.

| Role | Observed size | Weight | Approx. line height | Color | Normalized use |
|---|---:|---:|---:|---|---|
| Brand wordmark | 18–24 | 700–900 | 22–29 | Sakura `brandPrimary` | Prefer 20/24 and bold through the shared `RikiBrandLockup`. |
| Hero title | 26 | 700 | 34–36 | `textPrimary` | Completion/success emphasis only. |
| Page title | 24 | 700–800; one export 900 | 30–32 | `textPrimary` | Default screen/form title. Loading must not change weight arbitrarily. |
| Compact onboarding title | 22 | 700 | 27–28 | `textPrimary` | Use when dense selection content must fit naturally. |
| Section/card heading | 14–16 | 600–700 | 20–22 | `textPrimary` or slate-800 | Card titles and option titles. |
| Body | 14 | 400–500 | 20–23 | `textBody` / `textSecondary` | Descriptions and instructions. |
| Supporting/metadata | 12–13 | 400–500 | 16–19 | `textSecondary` | Hints, footer copy, card metadata. |
| Form label | 12; one normal-register export uses 14 | 600 | 16–18 | slate-700/900 | Prefer a consistent 12 semibold role unless later visual approval chooses 14. |
| Input value/placeholder | 14 | 400–500 | about 20 | slate-900 / `textDisabled` | Password glyph tracking may be wider; do not use a visibly different monospace face unless approved. |
| Validation message | 12 | 400–500 | 16–18 | `errorText` | Place below its field with an error icon. |
| Button label | 14–16, commonly 14/15 | 500–600 | about 20 | White or slate-700 | Full-width CTA label; keep stable between normal/loading states. |
| Badge | 10–12 | 500–700 | 14–16 | Semantic foreground | Uppercase or wider tracking only where shown. |

Headings generally use slightly tight tracking. Body copy uses normal tracking and often relaxed line height. Vietnamese diacritics must render correctly and text must be allowed to wrap.

### Japanese text

The only Japanese glyph demonstrated in the current exports is the `文` logo mark. There is not enough visual evidence to define a separate Japanese content typeface or reading scale.

Future font verification must cover kana, common/rare kanji, punctuation, full-width forms, and mixed Japanese/Vietnamese lines. Test strings must render without tofu boxes on supported Android and iOS versions. The logo mark must eventually use an approved asset or a proven font; do not assume that an arbitrary system serif reproduces the brand mark.

## Spacing

The exports use a 4 px base rhythm with several Tailwind half-steps inside compact controls.

| Token | Value | Typical use |
|---|---:|---|
| `space1` | 4 | Icon/text micro gap, badge inset adjustment. |
| `space2` | 8 | Compact inline gap, title-to-subtitle gap. |
| `space3` | 12 | Field internals, compact stack gap, icon-to-copy gap. |
| `space4` | 16 | Card padding, field-to-message/next-item grouping. |
| `space5` | 20 | Compact screen horizontal padding and content separation. |
| `space6` | 24 | Standard screen horizontal padding, major form/section gap. |
| `space7` | 28 | Occasional roomy horizontal inset; use only where the reference needs it. |
| `space8` | 32 | Large title/section or hero separation. |
| `space10` | 40 | Hero and major top/bottom breathing room. |
| `space12` | 48 | Large completion-view separation. |

Component-local values of 6, 10, and 14 appear in the HTML and may be used for compact badges, field padding, and selection cards. They should not become unrelated one-off constants across Widgets.

Layout rules:

- Standard screen horizontal padding is 20–24. Use 20 for denser registration/onboarding content and 24 for regular auth layouts.
- Form labels sit about 6–8 above controls.
- Related fields are generally 16 apart; validation text increases the field group's natural height rather than overlapping the next field.
- Major title-to-form or section-to-section spacing is 20–24.
- Cards use 14–20 internal padding, most commonly 16.
- Bottom action regions use 20–24 horizontal padding and must include the device safe-area inset.
- Tall references use flexible whitespace. Do not encode that whitespace as a fixed spacer that overflows a shorter phone or an open keyboard.

## Radius scale

| Role | Radius | Evidence |
|---|---:|---|
| Small tag/counter | 4–6 | Small “Phổ biến” and option metadata tags. |
| Compact icon/back control | 8–12 | Small logo and navigation tiles vary by screen. |
| Input/control | 12 | `rounded-xl` is consistent across form states. |
| Card/banner/selection card | 16 | `rounded-2xl` is the dominant larger container radius. |
| Primary action | 12 or 16 | Most screens use 12; login normal and loading registration use 16. Preserve the family until a later visual normalization decision. |
| Badge/pill/status | Full pill | `BorderRadius.circular(999)` equivalent. |

## Borders, focus, and elevation

- Default input/card border: 1 px `border` (`#E2E8F0`).
- Strong neutral choice indicator: 2 px `borderStrong` (`#CBD5E1`).
- Selected choice card: emphasized `brandPrimary` outline with a light Sakura surface and subtle Sakura shadow.
- Validation input: 1 px `error`, pale error surface, trailing error icon, and message below.
- HTML focus classes generally use a 2 px translucent red focus ring. No PNG captures a focused keyboard state, so this is secondary evidence only.
- Standard cards are border-led with zero or very low elevation. Common HTML `shadow-sm` should render as a restrained native shadow, not a raised Material card.
- Selected-card reference shadow: `0 4px 12px rgba(183, 19, 26, 0.08)`.
- Completion-card soft shadow: `0 2px 10px rgba(0, 0, 0, 0.02)`.
- Loading registration button HTML declares `0 8px 24px -4px rgba(185, 28, 28, 0.45)`; visually keep it subtle enough to match the PNG.
- Ignore the large browser/device-frame shadows in HTML; they are presentation scaffolding, not app UI.

## Reusable component rules

### RikiPath app header

Three related variants are evidenced:

- Standard auth: red `文` tile, wordmark, compact JLPT badge on the left; outlined `VI` language pill on the right.
- Back-navigation auth: back control on the left and centered compact brand lockup.
- Success/onboarding completion: brand lockup on the left and an emerald status pill on the right.

Typical brand tiles are 32–40 square with an 8–16 radius. The standard wordmark is about 20 bold. Header badges are 10–12 semibold and pill-shaped. Use `SafeArea`; do not reproduce the screenshot status bar.

The standard header should accept the JLPT level as data and support N5/N4/N3. The language pill is a control, not decorative text, but the current references do not define its menu or alternate-language state.

### Primary button

- Full available width, normally 48 high.
- `brandPrimary` fill, white label, 14–15 semibold, 12–16 radius.
- Optional trailing arrow is part of the label hierarchy, not a separate floating element.
- Preserve at least a 48 high touch target and visible pressed/focus semantics.
- Do not place networking in the button Widget; actions belong to feature state/controllers in implementation phases.

### Loading button

- Same footprint as the primary button.
- Inline small spinner plus processing label, centered as one unit.
- Disable duplicate submission and related mutable form controls while processing.
- Loading does not imply a refresh-token or API progress protocol.

### Secondary button

- White surface, 1 px slate border, slate-700 label, same 48 height and 12 radius as its primary peer.
- Used for return/back actions. It is visually stronger than a plain text link but weaker than the primary CTA.

### Text button/link

- Sakura and semibold for important navigation such as register/login, or ink-neutral metadata for lower-emphasis “later” actions.
- Must retain an accessible touch target even when its visible text is compact.
- Legal links are underlined in the registration reference.

### Text input

- Label above; leading icon; optional trailing status/action; 44–48 visual height.
- White fill, 1 px slate border, 12 radius, 14 input text, slate-400 placeholder.
- Keep field internals aligned when trailing icons appear so normal and validation states do not jump horizontally.
- Use platform text input, autofill, keyboard type, and semantics rather than a decorative container pretending to be an input.

### Password input

- Same base input plus lock icon and show/hide action.
- The forgot-password action aligns with the password label row on login.
- Password visibility is local UI state. Do not change the underlying field value or validation message when toggled.

### Validation input

- Error outline `#EF4444`, lightly tinted surface, red trailing error icon.
- Error message directly below in about 12 px red text with a small information/error icon.
- Layout must grow to fit long/localized messages; do not absolutely position the message.
- Validation exports are states of the same form Widgets, not alternate pages.

### Checkbox/agreement row

- Small 16 px visual checkbox using brand Sakura when checked, with a larger semantic/touch target.
- Supporting copy is 12 px and may wrap across lines.
- Login uses remember-session copy; registration uses agreement plus underlined legal links.

### JLPT badge and language badge

- JLPT badge: blue information palette, 10–12 semibold, full pill.
- Language badge: white/slate surface, slate border, globe plus language code, full pill.
- Neither badge may be hardcoded as a visual-only Widget with no semantics.

### Promotional badge

- Compact, left-aligned pill near the title, with sparkle icon and 12 px text.
- References alternate between pale red and pale amber gradients/surfaces. Preserve the current screen family rather than creating several global semantic variants prematurely.
- It must wrap or adapt on narrow devices; the validation PNG demonstrates that fixed-width copy can become cramped.

### Information, warning, and success banners

- Rounded 16 container, thin semantic border, 14–16 padding, leading icon, 12–14 copy with relaxed line height.
- AI/login tip banners use amber/cream treatment.
- Warnings use amber and should not rely on color alone.
- Success summaries use mint/emerald and may contain structured rows and dividers.
- The references do not show a general blue information banner; blue is currently established mainly for compact information/JLPT badges.

### Selection card

- White, 1 px slate border, 16 radius, about 14–16 padding.
- Leading 44 square level/icon tile, flexible title/description column, trailing radio/check state.
- Selected state uses an emphasized Sakura border, light Sakura surface, Sakura/white leading tile, check, and subtle Sakura shadow.
- Use radio-group semantics and make the entire card tappable.
- Badges such as “Phổ biến nhất” must participate in layout. The duration PNG shows a collision around the selected card; do not reproduce it with absolute positioning.

### Card

- Default card is white with 1 px slate border and 16 radius.
- Prefer no elevation or a very soft shadow.
- Structured summary cards may use internal dividers; semantic banners should retain their semantic tint.

### Progress indicator

- Onboarding: short/full red step bars with gray track and textual step labels.
- Loading: thin red-on-gray progress strip paired with a processing banner.
- The loading HTML defines an indeterminate animation even where a PNG looks partially filled. Do not claim a numeric percentage unless the application actually has measured progress.

### Success illustration

- Centered layered mint circles with a white inner icon tile and emerald symbol.
- This is reusable across password, registration, and onboarding completion, with feature-specific glyphs.
- The current export supplies no standalone vector/image asset. Later implementation should use approved icons or a purpose-built reusable Flutter composition, not crop the screenshot.

### Bottom navigation

The five `SHELL_*` exports establish one shared learner navigation component:

- White surface with subtle upward separation shadow and platform bottom safe-area handling.
- 64 logical pixels of navigation content above the safe-area inset.
- Five equal-width destinations: Trang chủ, Học tập, Luyện tập, Sổ từ, Cá nhân.
- Each destination retains a full-height touch target; the icon is 22 pixels inside a 40×24 icon region.
- Selected destination uses a filled icon, `brandPrimary` label/icon, bold 11-pixel label, and `learnerPrimaryFixed` pill.
- Unselected destinations use outlined icons and `learnerTextSecondary` labels.
- Route/state ownership remains in `StatefulShellRoute.indexedStack`; the visual component only reports the selected index.

## Auth state differences

### Login

| State | Differences from normal |
|---|---|
| Normal | Editable empty/default fields, forgot-password link, checked remember control, active CTA, amber tip card, register action, security footer. |
| Validation | Invalid fields gain red outline/tint, trailing error icons, and messages below. CTA remains red. The reference omits the normal tip card and uses a shorter composition; whether the tip is intentionally hidden or merely omitted by this export is unknown. |
| Loading | Populated fields and surrounding actions are softened/locked, email shows a green check, CTA shows spinner and processing copy, and a sync/status banner plus thin indeterminate progress strip appears. |

These are one future `LoginScreen` driven by form/submission state, not three screen classes.

### Registration

| State | Differences from normal |
|---|---|
| Normal | Four editable fields, password rule hint, agreement/legal row, active registration CTA, login and security footer. |
| Validation | Four fields show per-field error outline/icon/message. The agreement row is absent from this export; there is no evidence that validation should remove it. |
| Loading | Values are populated and softened/locked, valid fields may show checks, CTA has spinner/processing label, and a setup banner plus indeterminate progress appears. |
| Success | Form is replaced by success illustration, active status pill, account-ready summary, one-minute hint, onboarding CTA, and lower-emphasis home action. |

Normal and loading references contain copy and wordmark differences. A processing state should not silently change page title, promo copy, or brand style; final copy needs product confirmation.

### Password recovery

| State | Composition |
|---|---|
| Request | Back navigation, centered brand, reset icon, title/subtitle, email field, primary send action, and secondary return action. The HTML also contains a Sensei help footer, but it is outside/absent from the PNG and is secondary evidence only. |
| Success | Brand plus sent-status badge, success illustration, title/subtitle, green instruction card, amber inbox/spam warning, resend countdown, return-to-login CTA, and help-center action. |

These belong to one password-recovery flow. The current references do not justify a separately duplicated feature screen; a router requirement may later choose whether the success state is addressable.

### Onboarding

| State/step | Composition |
|---|---|
| JLPT goal | Step 1 of 2, back action, N5/N4/N3 radio cards, N3 selected example, continue CTA. |
| Study duration | Step 2 of 2, selected target badge, 15/30/45/60-minute radio cards, 30-minute selected example, complete CTA. |
| Completion | Active-status header, success illustration, personalized plan summary, AI tip, start-learning CTA, and home action. |

All three should share one onboarding flow and state model. Values shown in completion are example UI content, not permission to invent an API response.

## Responsive Flutter interpretation

Later Flutter implementation should:

- Use `SafeArea` for system insets. Auth/Onboarding uses its documented 20–24 horizontal rhythm; C8 learner pages use the evidenced 16-pixel screen edge.
- Use `Column`/`Row`, `Flexible`, and `Expanded` only where content behavior requires them.
- Put keyboard/form layouts in a `SingleChildScrollView`, with a constrained minimum content height where useful.
- Let bottom actions sit low on tall phones through flexible layout, while remaining reachable by scrolling on short phones or with large text.
- Use `LayoutBuilder` or constraints for adaptable content, never `width: 390` or a screenshot-sized canvas.
- Allow Vietnamese, Japanese, badge, and validation copy to wrap. Test large text scale without clipping.
- Keep touch targets at least about 44–48 logical pixels even where the visible badge/link is smaller.
- Avoid full-screen `Stack`/`Positioned` reconstruction. A local stack is acceptable only for a contained decorative illustration or badge when it still responds to text and screen constraints.
- Treat the 585×982, 585×1048, 585×1266/1275, and 706×1600 PNGs as raster exports of phone compositions, not logical Flutter dimensions.
- Avoid globally weakening platform security or embedding remote HTML/assets to reproduce the mockup.

## Known unknowns and inconsistencies

- Canonical font family is unresolved: system sans dominates, while one completion export uses Inter. No fonts are bundled.
- Historical exports used inconsistent burgundy pressed colors. The current normalized pressed token is Sakura `#C24362`.
- Success surface/border uses both custom mint values and Tailwind emerald values.
- Wordmark color, size, and weight vary between normal, validation, loading, and success exports.
- Registration loading changes the normal screen title and promotional copy. This looks like export drift, not proven state behavior.
- Login validation omits the normal tip card; registration validation omits the agreement row. Intentional conditional visibility is not proven.
- The screenshots do not define focus-with-keyboard, API failure, offline, disabled-nonloading, or retry states.
- No approved logo, icon, or success-illustration asset files accompany the PNG/HTML references.
- No dark theme, landscape, tablet, foldable, or desktop composition is provided.
- The C8 Home/shell subset does not establish long-form Japanese lesson typography; later lesson references must be reviewed in their own phase.
- Notification route ownership is unresolved: `HOME_04` visually selects Học tập even though notifications are launched from an app-level header affordance.
- The Home offline reference proves a cached presentation, not the persistence, freshness, or reconciliation contract needed to enable it.
- Route paths, transition animations, and whether success states are deep-linkable are not established by the visual exports.
- Selected examples show N3 and 30 minutes only. N5/N4 and other duration selections should be data-driven states of the same components, not new pages.
- Countdown duration, example learner details, lesson text, percentages, and study-duration choices shown in the mockups are visual content evidence only. They must not be promoted to API facts without `API_CONTRACT.md`/backend confirmation.

## Guardrails for the implementation phase

- Centralize the final colors, type styles, spacing, radii, and component themes before using them across feature Widgets.
- Reuse one screen per route-level flow and render validation/loading/success/step variants from explicit UI state.
- Keep API calls, persistence, and endpoint strings out of Widgets.
- Preserve portrait-mobile proportions without fixed-canvas implementation.
- Test Japanese rendering and text scaling on supported Android and iOS devices.
- Run `flutter analyze` and `flutter test` after an authorized implementation phase.
- Verify every final Git diff contains no file under `RikiPath.Backend/`.
