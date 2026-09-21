# Profile V3 implementation audit

This document records the Profile route audit and presentation decisions for
Phase UI-PROFILE-V3. It does not redefine backend contracts.

## Route matrix

| Route / entry | Screen | Data source | Phase result | States and motion |
| --- | --- | --- | --- | --- |
| `/profile` | Profile | UserProfile API | Existing premium home retained; Consultation entry refined as a service card | Layout-aware skeleton, controlled page error, entrance animation |
| `/profile/edit` | Edit Profile | UserProfile update and avatar upload APIs | Avatar identity surface, grouped supported name fields, preview confirmation sheet | Profile skeleton, inline validation, upload/save loading, global toast, avatar cross-fade |
| `/profile/account` | Account & Security | UserProfile API plus authenticated session | Real email verification summary and grouped Security, Options, and Session surfaces | Settings skeleton, localized page error, press feedback, logout sheet |
| `/profile/notifications` | Notification Settings | UserProfile notification settings API | Only email and system preferences are displayed | Stable skeleton, immediate mutation indicator, global toast |
| `/profile/change-email` | Change Email | Auth update-email operation plus UserProfile email | Focused security flow with current-email summary and grouped form | Inline validation, loading CTA, controlled error/success, verify-email navigation retained |
| `/auth/verify-email` | Verify Email | Auth verify-email operation | Existing Sakura authentication flow retained because it is also used after registration | Existing validation/loading/error/success behavior retained |
| `/profile/change-password` | Change Password | Auth change-password operation | Focused security form and requirement panel matching the verified six-character rule | Inline validation, loading CTA, controlled error/success |
| `/profile/jlpt-goal` | JLPT Goal | UserProfile API | Current goal, N5/N4/N3 preview, and daily-time preview | Goal skeleton, controlled page error, save remains disabled while ID mapping is unavailable |
| `/learn/progress` from Profile | Progress & History | Existing learning providers | Reviewed and retained: it already has purpose-built summaries and learning-specific loading/error states | Existing learning motion and state handling retained |
| Consultation entry | No route available | No confirmed API/route | Premium disabled service card only; no feature screen invented | Static unavailable state |

There is no separate general Settings screen. The existing Profile settings
entry routes to Account & Security, so no additional route was created.

## Shared presentation foundation

The Profile family now reuses:

- `ProfileDetailHeader`
- `ProfileDetailIntro`
- `ProfileSurface`
- `ProfileSettingsGroup`
- `ProfileSettingsTile`
- `ProfileFormSection`
- `ProfileSecurityCard`
- `ProfileDetailSkeleton`
- `ProfileAnimatedEntrance`
- `showProfileConfirmationSheet`

These components use the existing Material outlined icon family and Sakura
tokens. No icon or animation package was added. Profile child routes retain the
existing approximately 260 ms fade and small horizontal slide transition.

## Contract and security constraints preserved

- Edit Profile exposes only `firstName`, `lastName`, and the supported avatar
  upload operation.
- Notification Settings exposes only `emailNotificationsEnabled` and
  `systemNotificationsEnabled`.
- JLPT options are limited to N5, N4, and N3. Selection is preview-only because
  the backend does not expose a verified name-to-ID mapping; the frontend does
  not submit guessed IDs.
- Update Email and Change Password retain their existing API integration. The
  missing backend authorization enforcement documented in `API_GAPS.md`
  remains a backend security blocker and is not presented as resolved here.
- Consultation remains unavailable because no confirmed frontend route/API
  exists.

## Feedback and accessibility

Mutation success and failure continue through the global RikiPath toast host.
Field validation remains inline, while initial-load failures use localized page
states. Entrance and press motion respect `disableAnimations` and
`accessibleNavigation` where the shared component owns the animation.
