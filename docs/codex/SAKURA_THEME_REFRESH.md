# Neo-Japoniste Sakura Theme Refresh

## Scope

Phase C13.5 migrates the presentation of the already implemented Flutter app to the approved Neo-Japoniste Sakura Stitch language. It does not add product features or change routing, session behavior, repositories, DTOs, API paths, mappers, persistence, fixtures, or backend contracts.

Primary evidence:

1. `docs/ui_reference/stitch_mobile/*_sakura/screen.png`
2. matching `code.html` files for measurements and color evidence
3. `docs/ui_reference/stitch_mobile/neo_japoniste_sakura/DESIGN.md`

The local Stitch folder contains 67 screen/HTML pairs and one design-system document. It is ignored by Git and is not a runtime application dependency.

## Canonical palette

| Role | Token | Value |
|---|---|---:|
| Primary Sakura | `AppColors.brandPrimary` | `#E05A7A` |
| Pressed Sakura | `AppColors.brandPrimaryPressed` | `#C24362` |
| Secondary Sakura | `AppColors.brandSecondary` | `#F8BBD0` |
| Light selected surface | `AppColors.brandTint` | `#FFF0F3` |
| Interactive tonal surface | `AppColors.surfaceContainer` | `#FCE7EB` |
| Ink neutral | `AppColors.textPrimary` | `#2D282A` |
| Supporting neutral | `AppColors.textSecondary` | `#695F63` |
| Mastery/success | `AppColors.success` | `#079D47` |
| Destructive/error | `AppColors.error` | `#D32F2F` |

Success, warning, information, and destructive colors remain semantic. In particular, deletion and validation use destructive red; they do not reuse brand Sakura.

## Previous-to-current token mapping

| Existing role | Previous value | Sakura value |
|---|---:|---:|
| `brandPrimary` | `#B7131A` | `#E05A7A` |
| `brandPrimaryPressed` | `#9B1016` | `#C24362` |
| `brandTint` | `#FEF2F2` | `#FFF0F3` |
| `brandSelectedTint` | `#FFF1F2` | `#FFF0F3` |
| `brandSelectedBorder` | `#FDA4AF` | `#E05A7A` |
| `background` | `#FFFFFF` | `#FFF9FA` |
| `textPrimary` | `#0F172A` | `#2D282A` |
| `textSecondary` | `#64748B` | `#695F63` |

The separate legacy learner-shell blues now resolve through the same Sakura surface and neutral token family. Existing semantic roles were reviewed individually instead of being replaced as brand colors.

## Shared presentation decisions

- `RikiBrandLockup` is the single mark/wordmark implementation for Splash, Auth, Home, and Learning surfaces. It renders the Sakura gradient `文` mark, Sakura wordmark, and optional typed JLPT badge.
- `RikiBottomNavigationBar` remains connected to `StatefulShellRoute.indexedStack`. It has exactly five equal-width, single-line destinations: `Trang chủ`, `Học tập`, `Luyện tập`, `Sổ từ`, and `Cá nhân`.
- Active navigation uses Sakura text/icon on `#FCE7EB`; inactive navigation uses `#695F63`.
- Standard cards remain white. Selected cards use `#FFF0F3` with a Sakura outline.
- Selected filter/collection chips use a light Sakura container with Sakura foreground and border.
- Input focus is Sakura. Validation remains destructive red.
- In-progress bars use Sakura; verified completed progress uses mastery green.
- JLPT remains a typed N5/N4/N3-only frontend scope.

## Existing screen audit

| Area | Presentation result |
|---|---|
| Startup and session restoration | Splash adopts the shared brand lockup; session behavior is unchanged. |
| Login, register, forgot password | Existing state-driven layouts inherit Sakura fields, CTAs, links, banners, and shared header. Validation and success remain semantic. |
| Onboarding | Existing JLPT/time/complete states inherit Sakura selected cards, progress, CTA, and N5/N4/N3 badges. |
| Home and learner shell | Learner canvas, cards, header, progress, active navigation, and skeleton tones use the Sakura system. |
| Learning, roadmap, progress, lessons, video, locked/completion states | Existing structure and fixtures are unchanged. In-progress fills are Sakura; completion remains mastery green. |
| Vocabulary | Library/detail/loading/empty/error presentation uses Sakura surfaces, header, chips, cards, search, save, and audio controls. Search, paging, DTOs, repositories, and fixture boundaries are unchanged. |
| Kanji | Library/detail/stroke/loading/empty/error presentation uses Sakura surfaces, chips, cards, progress, and controls. Domain/repository/audio behavior is unchanged. |
| Grammar | Library/detail/loading/empty/error presentation uses Sakura surfaces, chips, cards, and headers. Search/paging/detail logic is unchanged. |
| Notebook | The already implemented C14 presentation inherits Sakura tokens; collection chips and destructive removal are normalized. Notebook API/domain/application behavior is unchanged. |
| Practice and Profile placeholders | Existing content inherits the Sakura canvas/theme. Page terms use `Thi thử JLPT`, `Chấm bài AI`, and `Cá nhân`; no future flow was implemented. |

## Terminology

Current implemented pages use the normalized terms `Từ vựng`, `Chi tiết từ vựng`, `Kanji`, `Chi tiết Kanji`, `Ngữ pháp`, `Chi tiết ngữ pháp`, `Sổ từ`, `Thi thử JLPT`, `Chấm bài AI`, and `Cá nhân`. Future-only terms are documented but were not introduced as screens in this phase.

## Legacy color audit

- The former burgundy brand token is removed from Flutter source and current design-system documentation.
- `docs/codex/PROJECT_AUDIT.md` retains one explicitly historical mention to explain the superseded initial audit.
- Semantic destructive red remains intentionally present through `AppColors.error`/`errorText`.
- Dark navy colors in the lesson video placeholder remain media-overlay neutrals, not brand colors.
- Raw colors inside ignored local Stitch HTML are source evidence and are not Flutter runtime values.

## Validation

Final validation for this phase must run:

```text
dart format .
flutter analyze
flutter test
git diff --check
```

Validation results are recorded in the phase handoff after execution. No C13.5 file is staged, committed, pushed, or tagged.
