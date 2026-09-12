# C10 Lesson Implementation

Implemented on: 2026-09-12 (Asia/Bangkok)

## Scope

C10 implements Lesson Detail, lesson video/content, resume presentation,
completion, locked, loading, and error states. It connects the existing
Learning Home and Roadmap lesson actions to the lesson route while keeping the
**Học tập** learner-shell destination selected.

Vocabulary, Kanji, and Grammar library screens are outside this phase. Notes
are shown only as an approved tab label; no note editing or persistence was
invented.

## Stitch references used

Each approved folder was inspected recursively. `screen.png` was the primary
visual source and `code.html` was secondary layout and copy evidence.

| Experience | Approved folder |
|---|---|
| Lesson detail | `LEARNING_07_Chi tiết bài học/` |
| Video lesson | `LEARNING_08_Trình phát video bài học/` |
| Resume video | `LEARNING_09_Video bài học - Tiếp tục học/` |
| Article content | `LEARNING_10_Nội dung bài học và ghi chú/` |
| Completion | `LEARNING_11_Hoàn thành bài học/` |
| Locked lesson | `LEARNING_12_Bài học chưa mở khóa/` |
| Loading | `LEARNING_13_Bài học - Trạng thái đang tải/` |
| Media/offline error | `LEARNING_14_Video bài học - Lỗi tải hoặc ngoại tuyến/` |

The references contain inconsistent visual sample totals: Lesson Detail shows
40% and 8 vocabulary items, while Resume shows 12:30 of 28:00 (45%) and the
video tab shows 12 items. These values remain separate typed fixture fields;
they were not normalized into an invented backend rule.

## Route and navigation

The route is nested under the existing Learn branch:

```text
/learn/lesson/:lessonId
```

`AppRoutes.lesson()` builds the encoded path. Learning Home and the current
Roadmap chapter pass the fixture route key through callbacks; Widgets do not
hardcode route strings.

The current route keys are local visual-development identifiers, not backend
IDs. `Lesson.remoteLessonId` is deliberately null until lesson discovery
provides a contract-derived numeric ID.

## Architecture

```text
LessonScreen and lesson views
  -> lessonControllerProvider / LessonController
  -> lessonRepositoryProvider / LessonRepository
  -> FixtureLessonRepository

LessonController
  -> lessonMediaDriverProvider / LessonMediaDriver
  -> FixtureLessonMediaDriver (current)
  -> VideoPlayerLessonMediaDriver (verified URL adapter)
```

Domain models cover lesson metadata, progress, parts, article content,
vocabulary previews, related grammar, prerequisites, next lesson, and mastery
items. Local fixture DTOs are explicitly separate from backend DTOs and are
mapped into the domain model by `LessonMapper`.

The media boundary exposes initialize, play, pause, and dispose. The current
fixture driver makes the visual flow deterministic without a fabricated media
URL. The `video_player` adapter accepts only a supplied network URI and never
creates or hardcodes one.

## UI and state model

The controller represents these video states explicitly:

- `initial`
- `loading`
- `ready`
- `playing`
- `paused`
- `completed`
- `error`

The screen also has detail, video, article, and completed stages. Repository
loading and failure are rendered through dedicated loading and retry views.
Locked lessons show their prerequisite and return/continue actions without
starting media.

The implementation reuses the existing RikiPath colors, typography, spacing,
cards, buttons, JLPT badge, Learning header, and learner bottom navigation. It
is portrait-first and is covered at a 320-pixel viewport width.

## API usage and progress behavior

No backend endpoint is called by C10 because the frontend cannot discover the
numeric lesson ID required by the available detail endpoint.

The related source-backed contract is:

- `GET /api/LessonProgress/lessons/{lessonId}` — Bearer, Learner.
- `PATCH /api/LessonProgress/lessons/{lessonId}/playback-position` — Bearer,
  Learner, with exact request fields `positionSeconds` and `durationSeconds`.

The source response fields are `lessonId`, `courseId`, `title`, `content`,
`videoUrl`, `attachmentUrl`, `orderIndex`, `progressPercent`,
`resumePositionSeconds`, `isCompleted`, and `completedAt`. Live Swagger exposes
the routes and request field names but no typed response schema.

For fixture interaction only, `FixtureLessonRepository` mirrors the confirmed
source behavior: duration must be positive, position must be nonnegative,
position is clamped to duration, progress does not move backward, and progress
at or above 95% is considered complete. This is not a remote sync claim.

## Tests

The C10 suite contains 16 tests covering:

- route construction and navigation from Learning Home and Roadmap;
- preservation of the selected Learn tab;
- N5/N4/N3 scope and separation of fixture keys from backend IDs;
- major Lesson Detail sections;
- repository loading and error states;
- resume at 12:30 and derived 45% video position;
- video loading, ready, playing, paused, and error states;
- media retry/article fallback;
- completion, 100% progress, XP, mastery, and next-lesson actions;
- repository-driven progress rendering;
- detail, video, completion, and locked states at 320-pixel width;
- absence of direct Dio use in the Learning presentation layer.

## Confirmed integration blockers

- No course, roadmap, lesson-list, or lesson-discovery endpoint maps the local
  lesson position to the required numeric `lessonId`.
- The detail response lacks the structured fields required by the Stitch
  composition, including duration, JLPT metadata, objective, lesson parts,
  examples, vocabulary preview, related grammar, prerequisite, and next lesson.
- `durationSeconds` is required by source service behavior but is not returned
  by the lesson detail response.
- The controller comment describes duration as optional, while the service
  rejects values at or below zero; Swagger publishes no matching validation.
- Completion is inferred by the source service at 95% playback; there is no
  separate lesson-completion endpoint or published contract for non-video
  completion.
- Media URL lifetime, signing, expiry, and refresh behavior are not documented.

These blockers are also recorded in `API_GAPS.md`. Remote integration must not
proceed by inventing IDs, fields, endpoints, or media behavior.

## Deferred to C11

- Vocabulary, Kanji, and Grammar library and detail experiences.
- Remote lesson discovery and DTO mapping until the missing contracts exist.
- Real media playback until a verified media URL and lifecycle contract are
  supplied by a repository.
- Note creation, editing, and persistence.
- Durable playback persistence and cross-session resume integration.
