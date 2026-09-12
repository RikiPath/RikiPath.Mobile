# C9 Learning Implementation

Implemented on: 2026-09-12 (Asia/Bangkok)

## Scope

C9 implements the learner Learning Home, JLPT Roadmap, and JLPT Level Progress experiences. Lesson Detail, lesson lists, lesson video, playback updates, and lesson completion remain deferred to C10.

The existing five-tab `StatefulShellRoute.indexedStack` remains unchanged. All C9 routes live inside the Learn branch, so the **Học tập** bottom-navigation destination stays selected throughout the flow.

## Stitch references used

Each folder was inspected recursively. `screen.png` was the primary visual source and `code.html` was secondary layout/style evidence.

| Experience | Approved folder |
|---|---|
| Learning Home | `LEARNING_01_Học tập - Trang chính/` |
| JLPT Roadmap | `LEARNING_02_Lộ trình JLPT/` |
| JLPT Level Progress | `LEARNING_03_Tiến độ JLPT/` |

`LEARNING_04` through `LEARNING_14` belong to chapter, lesson, video, loading, and offline/error experiences outside C9. They were not implemented.

## Screens and routes

| Route | Screen | Purpose |
|---|---|---|
| `/learn` | `LearnScreen` | Target summary, overall progress, current lesson summary, and the three visible learning categories. |
| `/learn/roadmap` | `LearningRoadmapScreen` | Completed, current, available-ready, and locked chapter state presentation. |
| `/learn/progress` | `JlptProgressScreen` | Five-skill breakdown for vocabulary, Kanji, grammar, reading, and listening. |

The active Learning Home roadmap CTA opens `/learn/roadmap`. The completed roadmap result action opens `/learn/progress`. The progress screen can return to the detailed roadmap. Lesson CTAs remain visibly deferred and do not create a C10 route early.

## Repository and controller structure

```text
Learning screen
  -> learningControllerProvider / LearningController
  -> learningRepositoryProvider / LearningRepository
  -> FixtureLearningRepository
```

`LearningController` is a Riverpod `AsyncNotifier` and exposes loading, data, retry, and error states. All three screens reuse the same provider and shared loading/error compositions. Widgets receive typed domain objects and callbacks; they do not parse JSON, own endpoint strings, or call Dio.

`LearningRepository` is the remote-data seam. C9 supplies only `FixtureLearningRepository`; no placeholder remote endpoint or guessed DTO implementation was added.

## API usage

No backend endpoint is called by C9.

Confirmed related endpoints are insufficient for the complete Stitch hierarchy:

- `GET /api/UserProfile/me` can source a learner's target level only after authentication, but numeric JLPT IDs have no published N5/N4/N3 mapping.
- `GET /api/Analytics/study-streak` exposes streak aggregates.
- `GET /api/Analytics/completion-stats` exposes total/completed lesson counts and completion percentage.
- `GET /api/Analytics/skill-breakdown` exposes `skillName`, `averageScore`, and `attemptCount`, which do not provide the category unit totals shown by Stitch.
- `GET /api/LessonProgress/lessons/{lessonId}` returns one lesson only when its numeric ID is already known.
- `PATCH /api/LessonProgress/lessons/{lessonId}/playback-position` is a C10 mutation and is not used here.

Live Swagger still publishes no typed response schemas. Source-backed response fields remain unverified at the deployed OpenAPI schema level.

## Fixture data

Fixture data is isolated in `FixtureLearningRepository`. It reproduces the visible N4 example from the three approved Stitch screens:

- 58% overall progress, 18 of 30 lessons, and one of three completed chapters;
- the 12-day streak and `12/2024` example exam label;
- the current Chapter 2 / Lesson 19 summary and its Japanese grammar pattern;
- three chapter states: completed, current, and locked;
- vocabulary, Kanji, grammar, reading, and listening progress values.

These values are visual-development fixtures, not backend DTO defaults or business rules. The typed learner level remains `JlptLevel.n4`; no numeric backend JLPT ID is assigned.

## Confirmed backend gaps

The existing `API_GAPS.md` already records every C9 blocker, so no duplicate gap entry was added:

- no JLPT level catalog or name-to-ID mapping;
- no JLPT roadmap or roadmap-node contract;
- no course catalog or lesson discovery/list endpoint;
- no learning-history or continue-learning aggregate;
- no non-video completion/progress mutation;
- live Swagger has no typed response contracts.

## Tests

C9 tests cover:

- `/learn` and its major Learning Home hierarchy;
- the exact N5/N4/N3 typed mobile scope;
- Learning Home to roadmap navigation;
- completed, current, and locked roadmap presentation;
- roadmap to level-progress navigation;
- the five approved progress categories;
- loading and error states;
- the selected Learn bottom-navigation destination on nested routes;
- overflow safety across all three routes at a 320-pixel portrait width;
- a presentation-layer guard against direct Dio usage.

## Deferred to C10

- Chapter detail and lesson list screens.
- Lesson Detail and locked/loading/error lesson states.
- Video playback, resume position, and playback-position API integration.
- Lesson content/notes and lesson-completion presentation.
- Every CTA whose destination would require a lesson ID or C10 route.
