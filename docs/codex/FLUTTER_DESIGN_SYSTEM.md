# RikiPath Flutter Design System

## Status and scope

C4B implemented the reusable Flutter design foundation derived from `STITCH_DESIGN_SPEC.md`. C8 extends that foundation with the approved learner-shell surface palette, shell shadows, and five-destination bottom navigation. Feature-specific Home composition remains in the Home feature rather than expanding the global widget layer.

The implementation uses normal Material 3 Flutter Widgets with RikiPath-specific tokens and state styling. It does not copy the Stitch HTML, embed a WebView, or use screenshot-sized canvases.

## Implemented token files

| File | Responsibility |
|---|---|
| `lib/app/theme/app_colors.dart` | Semantic brand, Auth/Onboarding, learner-shell surface, text, border, validation, success, warning, and information colors. |
| `lib/app/theme/app_typography.dart` | Platform-sans roles for wordmark, titles, body, metadata, inputs, buttons, validation, and badges. |
| `lib/app/theme/app_spacing.dart` | The 4 px spacing scale plus a small set of screen/form/card semantic aliases. |
| `lib/app/theme/app_radius.dart` | Input, button, card, banner, tag, and pill radii. |
| `lib/app/theme/app_borders.dart` | Standard, emphasized, focused, and error border widths/sides. |
| `lib/app/theme/app_shadows.dart` | Soft card/action shadows plus the evidenced learner header and bottom-navigation separation shadows. |
| `lib/app/theme/app_theme.dart` | Material 3 `ThemeData` wiring for scaffold, text, inputs, buttons, cards, dividers, progress, checkboxes, and the preserved generic navigation shell. |

`app_theme.dart` re-exports the token files so existing imports continue to work. Existing `AppSpacing.xs` through `xxl` and `AppRadius.sm` through `lg` aliases remain available while new code can use the explicit semantic roles.

### Key decisions

- `AppColors.brandPrimary` is `#B7131A`.
- `AppColors.brandPrimaryPressed` is `#9B1016`, the most repeated dark-red reference value documented by C4A.
- No red disabled-button value was approved. Disabled primary buttons therefore use the documented neutral disabled palette (`#E2E8F0` with `#94A3B8` content) rather than an invented red.
- General success components use the more frequently evidenced emerald surface/border pair. The custom soft-mint pair remains available for the registration-success card treatment.
- `#2563EB` is retained as the semantic information/JLPT-badge color, not as the RikiPath brand primary.
- Typography does not force Inter or add a font package. It uses the platform font plus the existing Japanese-capable fallback family names.
- Learner pages use their approved blue-white tonal surface family without changing the Auth/Onboarding canvas.

## Shared components

All component exports are available through:

```dart
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
```

### Buttons

- `RikiPrimaryButton`
- `RikiSecondaryButton`
- `RikiTextButton`

`RikiPrimaryButton` owns normal, pressed, disabled, and loading presentation. A separate `RikiLoadingButton` was intentionally not created because loading is a state of the same action component.

```dart
RikiPrimaryButton(
  label: 'Đăng nhập',
  loadingLabel: 'Đang đăng nhập...',
  isLoading: state.isLoading,
  onPressed: state.isLoading ? null : submit,
)
```

While loading, the underlying action is disabled to prevent repeated submission, but the button retains the red Stitch processing treatment and displays an inline spinner.

### Inputs

- `RikiTextField`
- `RikiPasswordField`

The base field supports normal, focused, filled, error, read-only, and disabled presentation. Error state uses the approved red outline/tint, trailing error icon, and a wrapping validation row. `RikiPasswordField` composes the base field and adds an accessible obscure/reveal action.

```dart
RikiTextField(
  label: 'Email học viên',
  hintText: 'nhap.email@example.com',
  prefixIcon: Icons.mail_outline,
  errorText: state.emailError,
  controller: emailController,
)
```

Validation is supplied by feature UI state. The component does not own API calls or business rules.

### Header and badges

- `RikiAuthHeader`
- `JlptBadge`
- `LanguageBadge`

`RikiAuthHeader` supports the standard auth header, centered back-navigation header, and success-status header without reproducing a fake system status bar. The `文` mark is rendered from the visual reference until an approved logo asset is supplied.

`JlptBadge` accepts the typed `JlptLevel` enum. Its complete learner-facing domain is deliberately limited to `n5`, `n4`, and `n3`.

```dart
const RikiAuthHeader(level: JlptLevel.n4)

const JlptBadge(JlptLevel.n3)
```

`LanguageBadge` implements only the compact visible language control. It does not introduce localization infrastructure.

### Cards and banners

- `RikiCard`
- `AppSectionCard` (now composed from `RikiCard`)
- `RikiInfoBanner`
- `RikiWarningBanner`
- `RikiSuccessBanner`

Cards are border-led with a 16 px radius and extremely soft elevation. Semantic banners share icon/content alignment, 16 px padding, border, and radius while selecting the documented semantic palette.

```dart
const RikiWarningBanner(
  title: 'Mẹo đăng nhập',
  message: 'Sử dụng tài khoản khóa học để đồng bộ lộ trình.',
)
```

### Supporting patterns

- `RikiProgressIndicator` supports indeterminate loading or a real `0...1` value.
- `RikiCheckboxRow` provides a reusable remember/agreement layout and full-row interaction.
- `RikiPromotionalPill` provides the reusable auth learning/AI pill and allows its text to wrap.
- `RikiSelectionCard` provides the shared responsive radio-card treatment for JLPT goal and study-duration choices. Its title badge participates in normal wrapping layout rather than being absolutely positioned.

Do not pass a mock percentage to `RikiProgressIndicator` merely to resemble a screenshot. Use `value: null` when progress is not measurable.

### Learner bottom navigation

- `RikiBottomNavigationBar`

The component implements the five approved labels, outlined/filled icon states, pale-red selected pill, 64-pixel content height, platform safe-area inset, and full-width touch targets. It accepts a selected index and reports taps; `MainShell` retains all routing responsibility through `StatefulNavigationShell.goBranch()`.

Home-only pieces such as `HomeHeader`, first-lesson/setup cards, tool shortcuts, and Home loading/error compositions stay under `features/home/presentation/widgets/`. They reuse global tokens and primitives but are not presented as universal components before another feature proves reuse.

## Responsive usage

- Place page content inside `SafeArea`.
- Use 20 px horizontal padding for dense auth/onboarding layouts and 24 px for standard auth layouts.
- Use `SingleChildScrollView` for keyboard/form screens.
- When a CTA should sit low on tall phones, combine constrained minimum height and flexible layout while preserving scrolling on short phones.
- Allow Vietnamese, Japanese, badges, validation messages, and banner copy to wrap.
- Keep interactive controls around 44–48 logical pixels even when their visible icon or badge is smaller.
- Do not use 390×844 screen-sized boxes, full-screen absolute positioning, or simulated status bars.

## Accessibility

- Password reveal and back controls have tooltips/semantic labels.
- JLPT and language badges expose descriptive semantics.
- Validation messages are live semantic regions and do not rely only on color.
- Buttons disable their callback while loading.
- The test suite includes mixed Japanese/Vietnamese Unicode content. Real device font-glyph verification remains necessary because widget presence alone cannot prove installed glyph coverage.

## Tests

`test/core/widgets/riki_design_system_test.dart` covers:

- Primary button label and action.
- Loading button callback suppression and progress presentation.
- Validation field message and error icons.
- Password visibility state.
- Typed N5/N4/N3 badge rendering.
- Information, warning, and success banner content.
- Selection-card selected state and action.
- Mixed Japanese/Vietnamese text preservation.
- Compact `VI` language badge.

`test/core/widgets/riki_bottom_navigation_bar_test.dart` separately covers all five labels, selected semantics/icon state, and tap-index reporting.

A development-only showcase route was not added. The repository has no existing showcase infrastructure, and adding one would complicate production routing; focused widget tests provide the requested isolated component coverage instead.

## Deferred components and decisions

- Dialog and bottom-sheet-specific tokens/themes remain outside the C4B/C8 scopes and require review of their feature references before implementation.
- Layered success illustrations remain deferred until the corresponding feature-screen implementation phase establishes their final icon/assets and composition needs.
- A bundled canonical font and logo/icon/illustration assets are deferred pending approved, licensed assets.
- Dark theme, landscape, tablet, and large-text reference tuning are not defined by the C4B/C8 reference subsets.
- Localization infrastructure is outside C4B; `LanguageBadge` is presentation only.

## Usage guardrails

- Import shared tokens/components instead of repeating colors and `TextStyle` values in feature Widgets.
- Keep networking, endpoint paths, token storage, DTO parsing, and validation business rules outside these components.
- Use one screen with state-driven normal/validation/loading/success variants.
- Do not expand the JLPT learner enum beyond N5/N4/N3 without backend and product proof.
- Run `flutter analyze` and `flutter test` after every implementation phase.
- Verify `RikiPath.Backend/` remains clean before handoff.
