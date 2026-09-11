# RikiPath Stitch Mobile Screen Reference

## Scope

This index began with the 12 Auth/Onboarding exports audited in C4A. The reference directory now contains 113 complete screen folders. C8 adds the newly approved Home and five-tab learner-shell references below while preserving the earlier Auth/Onboarding findings. `screen.png` remains the primary visual reference and `code.html` secondary structural/style evidence.

Route mappings use only paths already registered in `AppRoutes`. Deep references without a current route are not assigned invented paths.

## Route/state summary

| Export | Future Flutter ownership | Classification |
|---|---|---|
| Login | `features/auth/presentation/login/` | Unique route-level view |
| Login validation | Same `LoginScreen` | UI state, not a separate route |
| Login loading | Same `LoginScreen` | UI state, not a separate route |
| Registration | `features/auth/presentation/register/` | Unique route-level view |
| Registration validation | Same registration screen | UI state, not a separate route |
| Registration loading | Same registration screen | UI state, not a separate route |
| Registration success | Same registration flow | Success state, not a separate duplicated route |
| Forgot password | `features/auth/presentation/password_recovery/` | Unique route-level view |
| Forgot-password success | Same password-recovery flow | Success state, not a separate duplicated route |
| Choose JLPT goal | `features/auth/presentation/onboarding/` | Unique onboarding route entry; step 1 state |
| Choose study duration | Same onboarding flow | Step 2 state, not a separate route |
| Onboarding complete | Same onboarding flow | Completion state, not a separate route |
| Home — new learner | `features/home/presentation/` at `/home` | Home success variant used by C8 fixture |
| Home — offline | Same `HomeScreen` | Cached/offline state reference |
| Home — loading | Same `HomeScreen` | Loading state reference |
| Notifications | No registered route | Reference recorded; navigation deferred |
| Home shell | `/home` branch | Learner shell, selected tab 0 |
| Learn shell | `/learn` branch | Learner shell, selected tab 1 |
| Practice shell | `/practice` branch | Learner shell, selected tab 2 |
| Notebook shell | `/notebook` branch | Learner shell, selected tab 3 |
| Profile shell | `/profile` branch | Learner shell, selected tab 4 |

The original C4A classification remains **4 Auth/Onboarding route-level views and 8 additional states/steps**. C8 adds one existing Home route with loading/success/error-capable state and five existing stateful shell branches; it does not add routes.

## 1. Login — normal

- **Reference folder:** `docs/ui_reference/stitch_mobile/AUTH_01_Đăng nhập/`
- **Primary image:** `docs/ui_reference/stitch_mobile/AUTH_01_Đăng nhập/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/AUTH_01_Đăng nhập/code.html`
- **PNG size:** 706×1600
- **Flutter feature:** `features/auth/presentation/login/`
- **Type:** Unique route-level view

Primary composition:

- Standard app header with red `文` tile, red RikiPath wordmark, blue N4 badge, and `VI` language pill.
- Pale promotional AI pill.
- “Chào mừng trở lại! 👋” title and supporting copy.
- Email and password inputs, forgot-password action, and checked remember-session control.
- Full-width red login CTA.
- Amber login tip card.
- Registration action and security footer.

Reuse rule: this is the base composition for the validation and loading exports. Header, title, fields, and footer must not be copied into separate screens.

## 2. Registration — normal

- **Reference folder:** `docs/ui_reference/stitch_mobile/REGISTER_01_Đăng ký tài khoản/`
- **Primary image:** `docs/ui_reference/stitch_mobile/REGISTER_01_Đăng ký tài khoản/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/REGISTER_01_Đăng ký tài khoản/code.html`
- **PNG size:** 585×1275
- **Flutter feature:** `features/auth/presentation/register/`
- **Type:** Unique route-level view

Primary composition:

- Standard brand/JLPT/language header and AI promotional pill.
- Registration title and subtitle.
- Full-name, email, password, and confirmation inputs.
- Password requirements hint.
- Checked agreement row with underlined terms and privacy links.
- Full-width red register CTA.
- Login action and security footer.

Reuse rule: validation, loading, and success are states in this registration flow.

## 3. Choose JLPT goal

- **Reference folder:** `docs/ui_reference/stitch_mobile/ONBOARDING_01_Chọn mục tiêu JLPT/`
- **Primary image:** `docs/ui_reference/stitch_mobile/ONBOARDING_01_Chọn mục tiêu JLPT/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/ONBOARDING_01_Chọn mục tiêu JLPT/code.html`
- **PNG size:** 585×1266
- **Flutter feature:** `features/auth/presentation/onboarding/`
- **Type:** Unique onboarding route entry; step 1 UI state

Primary composition:

- Back control, centered “Bước 1 / 2” progress, and compact brand tile.
- Goal title and explanatory copy.
- N5, N4, and N3 selectable radio cards; N3 is the selected example and carries a “Phổ biến” tag.
- Bottom continue CTA and settings-change reassurance.

Reuse rule: one selection-card component renders all three learner levels. N5/N4/N3 are the only supported learner targets unless backend evidence proves otherwise.

## 4. Login — validation

- **Reference folder:** `docs/ui_reference/stitch_mobile/AUTH_02_Đăng nhập - Lỗi xác thực/`
- **Primary image:** `docs/ui_reference/stitch_mobile/AUTH_02_Đăng nhập - Lỗi xác thực/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/AUTH_02_Đăng nhập - Lỗi xác thực/code.html`
- **PNG size:** 585×1048
- **Flutter feature:** Same `LoginScreen`
- **Type:** UI state, **not** a separate route

Changes from normal login:

- Invalid inputs use pale-red fill, red border, and trailing red error icon.
- Each invalid field gets a red message row below it.
- Natural vertical spacing grows to contain the messages.
- CTA remains active red.
- The normal tip card is absent and the overall reference is shorter. The export does not prove whether this is conditional behavior or an omitted section.

State rule: field validation data controls decoration and messages on the base login form.

## 5. Choose daily study duration

- **Reference folder:** `docs/ui_reference/stitch_mobile/ONBOARDING_02_Chọn thời gian học hằng ngày/`
- **Primary image:** `docs/ui_reference/stitch_mobile/ONBOARDING_02_Chọn thời gian học hằng ngày/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/ONBOARDING_02_Chọn thời gian học hằng ngày/code.html`
- **PNG size:** 585×1266
- **Flutter feature:** Same onboarding flow
- **Type:** Step 2 UI state, **not** a separate route

Primary composition:

- Back control, selected target badge (“Mục tiêu: N3”), “Bước 2 / 2” badge, and full red progress bar.
- Title and explanatory copy.
- 15, 30, 45, and 60-minute selectable cards; 30 minutes is selected and tagged as most popular.
- Bottom completion CTA and reassurance copy.

State rule: use the same onboarding state model as step 1. The visible selected target and selected duration come from state, not hardcoded copy. The PNG has a tight/colliding popular tag near the selected-card metadata; later responsive layout must give the badge normal layout space rather than reproduce the overlap.

## 6. Registration — validation

- **Reference folder:** `docs/ui_reference/stitch_mobile/REGISTER_02_Đăng ký - Lỗi xác thực/`
- **Primary image:** `docs/ui_reference/stitch_mobile/REGISTER_02_Đăng ký - Lỗi xác thực/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/REGISTER_02_Đăng ký - Lỗi xác thực/code.html`
- **PNG size:** 706×1600
- **Flutter feature:** Same registration screen
- **Type:** UI state, **not** a separate route

Changes from normal registration:

- Name, email, password, and confirmation fields each show red validation styling.
- Each field has its own trailing error icon and message.
- CTA remains red.
- The agreement/legal row is absent in this export; the reference does not establish that errors should remove it.

State rule: render per-field errors through the shared input/form components. Do not create a validation page.

## 7. Login — loading

- **Reference folder:** `docs/ui_reference/stitch_mobile/AUTH_03_Đăng nhập - Đang xử lý/`
- **Primary image:** `docs/ui_reference/stitch_mobile/AUTH_03_Đăng nhập - Đang xử lý/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/AUTH_03_Đăng nhập - Đang xử lý/code.html`
- **PNG size:** 706×1600
- **Flutter feature:** Same `LoginScreen`
- **Type:** UI state, **not** a separate route

Changes from normal login:

- Populated email/password fields and surrounding form actions are softened and non-editable while processing.
- Email shows a green valid check.
- CTA shows a spinner and “Đang đăng nhập...” processing label.
- Amber synchronization message and a thin progress strip appear below the CTA.
- Footer actions are visually de-emphasized.

State rule: one submission/loading flag drives the shared form. The HTML defines the progress strip as indeterminate; do not invent a numeric login-progress API.

## 8. Registration — loading

- **Reference folder:** `docs/ui_reference/stitch_mobile/REGISTER_03_Đăng ký - Đang xử lý/`
- **Primary image:** `docs/ui_reference/stitch_mobile/REGISTER_03_Đăng ký - Đang xử lý/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/REGISTER_03_Đăng ký - Đang xử lý/code.html`
- **PNG size:** 706×1600
- **Flutter feature:** Same registration screen
- **Type:** UI state, **not** a separate route

Changes from normal registration:

- Populated fields are softened/locked and some valid fields show green checks.
- Agreement row remains visible.
- CTA uses spinner plus “Đang tạo tài khoản...” label.
- An amber setup message and thin indeterminate progress strip appear.
- Footer is de-emphasized while processing.

Inconsistency: this export changes the normal registration title, subtitle, promotional copy, wordmark size/color, and some validation copy. Those differences are not proven loading behavior. A future shared registration screen should keep stable copy unless product requirements explicitly choose a revision.

## 9. Onboarding — completion

- **Reference folder:** `docs/ui_reference/stitch_mobile/ONBOARDING_03_Hoàn tất - Sẵn sàng học/`
- **Primary image:** `docs/ui_reference/stitch_mobile/ONBOARDING_03_Hoàn tất - Sẵn sàng học/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/ONBOARDING_03_Hoàn tất - Sẵn sàng học/code.html`
- **PNG size:** 585×1266
- **Flutter feature:** Same onboarding flow
- **Type:** Completion UI state, **not** a separate route

Primary composition:

- Brand header with green “Đã kích hoạt lộ trình” status pill.
- Centered graduation/check success illustration.
- “Sẵn sàng bắt đầu! 🎉” title and confirmation copy.
- Green structured summary card showing selected JLPT target, daily duration, and a suggested lesson.
- Amber AI tip card.
- Red start-learning CTA and lower-emphasis home action.

State rule: summary values must come from confirmed onboarding/application data. The visible N3, 30-minute, learner lesson, and AI copy are reference examples, not an API contract.

## 10. Forgot password — request

- **Reference folder:** `docs/ui_reference/stitch_mobile/AUTH_04_Quên mật khẩu/`
- **Primary image:** `docs/ui_reference/stitch_mobile/AUTH_04_Quên mật khẩu/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/AUTH_04_Quên mật khẩu/code.html`
- **PNG size:** 585×982
- **Flutter feature:** `features/auth/presentation/password_recovery/`
- **Type:** Unique route-level view

Primary composition:

- Back navigation and centered compact RikiPath brand.
- Centered pale-red reset-password icon tile.
- Title/subtitle and registered-email input.
- Full-width red send action.
- Full-width outlined return-to-login action.
- The HTML contains a Sensei support/help footer, but it is not visible in the PNG. Because the PNG has priority, that footer remains secondary evidence rather than a confirmed visible element.

Reuse rule: the successful request replaces this flow's main state; shared branding/actions should remain reusable.

## 11. Registration — success

- **Reference folder:** `docs/ui_reference/stitch_mobile/REGISTER_04_Tạo tài khoản thành công/`
- **Primary image:** `docs/ui_reference/stitch_mobile/REGISTER_04_Tạo tài khoản thành công/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/REGISTER_04_Tạo tài khoản thành công/code.html`
- **PNG size:** 706×1600
- **Flutter feature:** Same registration flow, handing off to onboarding
- **Type:** Success UI state, **not** a separate duplicated route

Primary composition:

- Brand header with green “Đã kích hoạt” status pill.
- Centered mint user/check illustration.
- Success title and onboarding invitation.
- Green account-ready card with example learner identity.
- Amber one-minute setup hint.
- Red goal-setup CTA and lower-emphasis home action.

State rule: learner name/email and activation wording require real application/API state. The screenshot values are examples and must never be hardcoded as account data.

## 12. Forgot password — success

- **Reference folder:** `docs/ui_reference/stitch_mobile/AUTH_05_Quên mật khẩu - Gửi yêu cầu thành công/`
- **Primary image:** `docs/ui_reference/stitch_mobile/AUTH_05_Quên mật khẩu - Gửi yêu cầu thành công/screen.png`
- **Secondary HTML:** `docs/ui_reference/stitch_mobile/AUTH_05_Quên mật khẩu - Gửi yêu cầu thành công/code.html`
- **PNG size:** 706×1600
- **Flutter feature:** Same password-recovery flow
- **Type:** Success UI state, **not** a separate duplicated route

Primary composition:

- Brand header with green “Đã gửi email” status pill.
- Centered mint envelope/check illustration.
- Sent title and explanatory copy.
- Green instruction card.
- Amber warning card for inbox/spam checking and link lifetime.
- Resend countdown/action.
- Full-width red return-to-login CTA and help-center action.

State rule: countdown and link lifetime must come from approved product/API behavior. The reference demonstrates presentation only. If restoration/deep-link requirements later need an addressable success location, reuse this same flow state rather than duplicating the view.

## C8 Home references

### Home — new learner

- **Reference folder:** `docs/ui_reference/stitch_mobile/HOME_01_Trang chủ - Người học mới/`
- **Primary image:** `screen.png` (465×1600)
- **Secondary HTML:** `code.html`
- **Route:** `/home`
- **Type:** Home success variant and C8 fixture source

Visible hierarchy: shared learner header; learner greeting, target, and “Hành trình mới” pill; first-lesson journey card; personalized roadmap summary; three-item initial-setup checklist; two introductory tool cards; shared five-tab navigation.

C8 implements this hierarchy as the default fixture-backed success state. The visible learner identity, N4 target, one-day streak, lesson text, and counts are presentation fixtures—not backend results. The implementation replaces “Đã kích hoạt mục tiêu N4” with the contract-safe “Đã chọn mục tiêu N4” and omits the unsupported time-of-day claim.

Reusable patterns: `HomeHeader`, `RikiCard`, primary/text actions, typed `JlptBadge`, progress track, checklist item, tool shortcut, and `RikiBottomNavigationBar`.

### Home — offline

- **Reference folder:** `docs/ui_reference/stitch_mobile/HOME_02_Trang chủ - Trạng thái ngoại tuyến/`
- **Primary image:** `screen.png` (375×1600)
- **Secondary HTML:** `code.html`
- **Route:** `/home` state; no separate route

Visible hierarchy: offline banner with retry; cached greeting/streak; downloaded continue-learning card; cached SRS review counts; last-saved AI recommendation; offline practice tiles; weekly challenge and locked online event; shared navigation.

This is an evidence-backed cached-data state, not a generic request error. C8 records it but does not claim offline availability for Home because no Home cache/reconciliation repository exists yet.

### Home — loading

- **Reference folder:** `docs/ui_reference/stitch_mobile/HOME_03_Trang chủ - Trạng thái đang tải/`
- **Primary image:** `screen.png` (450×1600)
- **Secondary HTML:** `code.html`
- **Route:** `/home` state; no separate route

The shared header and navigation remain visible while content becomes pale-blue skeleton blocks that preserve the dashboard hierarchy. The export leaves a previously known N4/14-day/MA identity visible. C8 has no cached shell-identity source, so it keeps the shell chrome but uses restrained header placeholders instead of presenting those sample values as current learner data. The content follows the exported skeleton hierarchy without a blocking full-screen spinner or fabricated progress percentage.

### Notifications

- **Reference folder:** `docs/ui_reference/stitch_mobile/HOME_04_Thông báo/`
- **Primary image:** `screen.png` (459×1600)
- **Secondary HTML:** `code.html`
- **Route:** **NOT REGISTERED**

The reference shows filter chips and notification groups for review reminders, AI recommendations, schedules, mock results, consultation, and a study tip. Its bottom bar visually selects Học tập even though this is an app-level notification page, so tab ownership is ambiguous. C8 keeps the Home notification symbol non-navigating rather than inventing a route or ownership rule.

## C8 learner-shell references

| Reference folder | Existing route | Visible shell/content pattern | C8 boundary |
|---|---|---|---|
| `SHELL_01_Trang chủ - Mobile Shell/` (501×1600) | `/home` | Established-learner greeting, daily goal, AI recommendation, shortcuts, challenge/news; Home tab selected | Used for shared header/navigation evidence; established-learner dashboard remains a future data variant |
| `SHELL_02_Học tập - Mobile Shell/` (535×1600) | `/learn` | Level chips, JLPT roadmap progress, learning categories, next lessons; Learn tab selected | Deep learning content deferred |
| `SHELL_03_Luyện tập - Mobile Shell/` (345×1600) | `/practice` | Mock-test entry, AI practice cards, recent assessment; Practice tab selected | Mock engine and AI practice deferred |
| `SHELL_04_Sổ từ - Mobile Shell/` (411×1600) | `/notebook` | Saved/review stats, SRS CTA, collections, search, vocabulary previews; Notebook tab selected | Notebook/SRS feature implementation deferred |
| `SHELL_05_Cá nhân - Mobile Shell/` (405×1600) | `/profile` | Learner identity, statistics, progress, consultation, downloads, settings, support; Profile tab selected | Profile and consultation flows deferred |

All five use the same 64-logical-pixel content header and five-item navigation grammar in their HTML. Their PNGs consistently show a white navigation surface, subtle top separation, 22-pixel icons, compact 11-pixel labels, a pale-red 40×24 selected-icon pill, a filled selected icon, and red selected label. Unselected icon/label content is dark brown/slate. The navigation sits above the platform safe-area inset.

Route switching remains owned by `StatefulShellRoute.indexedStack`; `RikiBottomNavigationBar` is presentation only.

## Cross-screen reuse map

| Shared component/state | References |
|---|---|
| Standard RikiPath auth header | Login normal/validation/loading; registration normal/validation/loading |
| Success-status header | Registration success; forgot-password success; onboarding completion |
| Primary red CTA | Original 12 Auth/Onboarding references and Home action cards |
| Outlined secondary CTA | Forgot-password request; conceptually related return actions |
| Standard text/password input | Login and registration normal/loading; forgot-password request |
| Validation input | Login validation; registration validation |
| Loading button and progress status | Login loading; registration loading |
| AI/promotional pill | Login and registration form states |
| Semantic banner/card | Login tip/loading; registration success/loading; forgot success; onboarding completion |
| Selection card/radio group | JLPT goal; study duration |
| Layered success illustration | Registration success; forgot-password success; onboarding completion |
| Bottom primary + low-emphasis action | Registration success; onboarding completion |

## C8 boundaries and unproven states

The repository now contains references for many later learner features, so the earlier claim that all post-auth screens were absent is no longer valid. C8 reviewed only the four `HOME_*` and five `SHELL_*` folders in depth. The following remain unproven for this phase and must not be invented:

- A generic Home network/server-error composition. C8 uses a restrained reusable error card rather than presenting the cached offline reference as a server error.
- Home offline persistence, cache freshness, and reconciliation behavior. The offline PNG proves presentation only; it does not prove a storage contract.
- Notification route, shell ownership, and navigation behavior. `HOME_04` visually selects Học tập, which is insufficient route evidence.
- A backend response that aggregates the full Home dashboard, or identifiers that connect its fixture lesson/roadmap to server records.
- Dark theme, landscape, tablet, foldable, desktop, and large-text reference captures.
- A canonical bundled font and approved standalone logo/icon/illustration assets.

The remaining feature reference folders may guide their own authorized implementation phases, but they do not establish API availability or authorize implementing those features in C8.

## Implementation boundary

This document records visual evidence and the C8 Home/shell decisions. It does not authorize HTML embedding, fixed screenshot canvases, route invention, speculative API integration, or backend changes. Later Flutter work must follow `docs/codex/CODEX_RULES.md`, use `docs/codex/STITCH_DESIGN_SPEC.md`, verify API-driven content against `docs/codex/API_CONTRACT.md`, and keep `RikiPath.Backend/` strictly read-only.
