# RIKIPATH MOBILE — MENTOR & LEARNER PARITY AND FULL UX AUDIT REPORT

- **Workspace:** `D:\FPT University\SEP491-new\rikipath`
- **Primary Repository:** `RikiPath.Mobile`
- **Backend Reference:** `RikiPath.Backend`
- **Design System:** Sakura Premium (`#E5577F` Sakura Pink · Warm Ivory `#FFF8FA` · Sakura Glass Notifications · Sakura Bloom Loading)
- **Date:** 2026-11-14

---

## 1. Executive Summary

Toàn bộ trải nghiệm **Mentor trên RikiPath Mobile** đã được rà soát, chuẩn hóa và đồng bộ hoàn toàn với trải nghiệm **Learner** theo nguyên tắc cốt lõi:

> **Cái gì Learner đã có và có thể dùng chung, Mentor tái sử dụng 100% thông qua kiến trúc shared component + cấu hình role-specific.**

Không tạo bộ UI Mentor rời rạc hay copy-paste nguyên khối code Learner sang Mentor. Các thành phần dùng chung (`SakuraAppHeader`, `AnimatedNotificationBell`, `RikiBottomNavigationBar`, `SakuraLoadingIndicator`/`SakuraLoadingOverlay`, `RikiToastHost`/`RikiToastService`, `ProfileSection`, `ProfileActionTile`, `showSakuraLanguageBottomSheet`, `showProfileConfirmationSheet`, `ChangePasswordScreen`, `UpdateEmailScreen`) được cấu hình theo role (`Learner` vs `Mentor`) và bảo vệ chặt chẽ bởi role-based router guards.

---

## 2. Full System Inventory & Learner–Mentor Parity Matrix

### A. Learner Feature Inventory (Verified Live Components)
- **App Header:** `SakuraAppHeader` (`lib/core/widgets/sakura_app_header.dart`) — `[RikiPath Logo]` bên trái, `[🔥 Streak Pill]` (Learner-only), `[AnimatedNotificationBell]` (kèm Sakura Pink unread badge & physics swing animation), `[Calendar Icon]` bên phải.
- **Bottom Navigation:** `RikiBottomNavigationBar` (`lib/core/widgets/riki_bottom_navigation_bar.dart`) — thanh điều hướng 5 tab với hiệu ứng nổi Sakura Pink cho tab trung tâm và chỉ báo gạch chân hồng cho các tab còn lại.
- **Loading System:** `SakuraLoadingIndicator`, `SakuraLoadingOverlay`, `SakuraLoadingButton`, `SakuraSkeleton` (`lib/core/widgets/sakura_loading.dart`).
- **Global Feedback:** `RikiToastHost` & `RikiToastService` (`lib/core/widgets/riki_toast_host.dart`, `lib/core/notifications/riki_toast_service.dart`) — Sakura Glass toast notifications.
- **Profile & Account Settings:** `ProfileSection`, `ProfileActionTile`, `showProfileConfirmationSheet` (`lib/features/profile/presentation/widgets/profile_detail_components.dart`), `showSakuraLanguageBottomSheet` (`lib/features/settings/presentation/language_bottom_sheet.dart`), `ChangePasswordScreen`, `UpdateEmailScreen`.

### B. Complete Learner–Mentor Parity Matrix

| Feature | Learner Implementation | Mentor Implementation (Refactored) | Shared Component Reused | Missing Case Resolved | Status |
|---|---|---|---|---|---|
| **Login & Auth Feedback** | `LoginScreen` + `SakuraLoadingOverlay` + `RikiToastHost` | Shared `LoginScreen` -> routes to `AppRoutes.mentor` (`MentorHomeScreen`) for `BackendUserRole.mentor` | `LoginScreen`, `SakuraLoadingOverlay`, `RikiToastService` | Unified login overlay & Sakura Glass toast feedback | **100% Shared** |
| **Unified Loading System** | `SakuraLoadingIndicator`, `SakuraLoadingOverlay`, `SakuraSkeleton` | All Mentor screens & actions use `SakuraLoadingIndicator` / `RikiSkeleton` (`SakuraSkeleton`) | `sakura_loading.dart`, `riki_loading.dart` | Removed legacy spinners/Copy | **100% Shared** |
| **Shared App Header** | `SakuraAppHeader(showStreak: true)` | `SakuraAppHeader(showStreak: false, calendarTooltip: 'Lịch giảng dạy')` across `MentorHomeScreen`, `MentorAvailabilityScreen`, `MentorMeetingsScreen`, `MentorProfileScreen` | `SakuraAppHeader`, `RikiBrandLockup` | Removed duplicate `RikiBrandLockup` in body & legacy `AppBar`; skipped Learner `/api/analytics` call when `showStreak: false` | **100% Shared** |
| **Notification Bell & Center** | `AnimatedNotificationBell` -> `AppRoutes.notifications` | `AnimatedNotificationBell` in `SakuraAppHeader` -> `AppRoutes.notifications` (`/notifications`) | `AnimatedNotificationBell`, `NotificationScreen`, `notificationControllerProvider` | Opened `/notifications` route guard in `app_router.dart` for `BackendUserRole.mentor` | **100% Shared** |
| **Bottom Navigation Bar** | `RikiBottomNavigationBar` (5 Learner tabs) | `MentorBottomNavigationBar` wrapping `RikiBottomNavigationBar` with 5 Mentor destinations (`Trang chủ`, `Lịch dạy`, `Buổi tư vấn`, `Lịch trống`, `Cá nhân`) | `RikiBottomNavigationBar` (`destinations` parameter) | Added 5-tab Mentor bottom navigation across all primary Mentor screens | **100% Shared** |
| **Role-Based Home Dashboard** | `HomeDashboardView` (Greeting + `SakuraHeroBanner` + Quick Actions) | `MentorHomeScreen` (`MentorGreetingHeader` + `SakuraMentorHeroBanner` + Approval Banner + `_MentorKpiSummaryStrip` + Calendar/Availability/Meetings summary cards) | `RikiCard`, `RikiPrimaryButton`, `RikiSkeleton`, Sakura design tokens | Added personalized Mentor greeting, Sakura Mentor Hero Banner, KPI strip (never faking `0` on error), and partial/full failure recovery | **Completed** |
| **Calendar Experience** | `LearnerCalendarScreen` (`SakuraCalendarShell`) | `MentorCalendarScreen` (`SakuraCalendarShell` + `MentorBottomNavigationBar(selectedIndex: 1)`) | `SakuraCalendarShell`, `SakuraMonthView`, `SakuraYearView`, `SakuraEventDetailSheet` | Added `MentorBottomNavigationBar` & header calendar shortcut (`AppRoutes.mentorCalendar`) | **100% Shared** |
| **Profile & Verification** | `ProfileScreen` / `EditProfileScreen` | `MentorProfileScreen` (Professional Bio, Expertise, JLPT Level, Years of Experience, Workplace, Verification Document Upload, Submit Verification) | `SakuraAppHeader`, `RikiCard`, `RikiPrimaryButton`, `RikiToastService` | Preserved full Mentor verification workflow while integrating shared header & bottom nav | **Completed** |
| **Account Settings & Security** | `ProfileSection` + `ProfileActionTile` (`ChangePasswordScreen`, `UpdateEmailScreen`, `showSakuraLanguageBottomSheet`) | `_MentorAccountSettingsSection` in `MentorProfileScreen` -> `/mentor/change-password`, `/mentor/change-email`, `showSakuraLanguageBottomSheet`, Compensation & Bank Account | `ProfileSection`, `ProfileActionTile`, `ChangePasswordScreen`, `UpdateEmailScreen`, `showSakuraLanguageBottomSheet` | Added `AppRoutes.mentorChangePassword` & `AppRoutes.mentorChangeEmail`; updated `UpdateEmailScreen` to read `mentorProfileControllerProvider` for Mentor role | **100% Shared** |
| **Logout Confirmation & Toast** | `showProfileConfirmationSheet` + `signOut()` + `"Đã đăng xuất"` Sakura Glass toast | `confirmAndPerformMentorLogout` reusing `showProfileConfirmationSheet` (`"Bạn muốn đăng xuất?"`, `"Đăng xuất"` / `"Ở lại"`) + Mentor provider invalidation + `"Đã đăng xuất"` toast | `showProfileConfirmationSheet`, `RikiToastService` | Replaced immediate unconfirmed logout with 100% shared confirmation sheet + toast + session cleanup | **100% Shared** |
| **Session Isolation** | Invalidates Learner providers on `authenticatedUserIdProvider` change | Invalidates all Mentor & Notification providers in `RikiPathApp` (`app.dart`) and `confirmAndPerformMentorLogout` | `authenticatedUserIdProvider` listener in `RikiPathApp` | Prevents cross-account Learner/Mentor data leakage | **100% Shared** |

---

## 3. Detailed Architectural & UI/UX Changes

### 3.1 Shared Sakura Header (`lib/core/widgets/sakura_app_header.dart`)
- Bổ sung tham số `showStreak` (mặc định `true` cho Learner, `false` cho Mentor) và `calendarTooltip`.
- Khi `showStreak: false`:
  - Không gọi `learnerAnalyticsControllerProvider` (tránh gọi endpoint `/api/analytics` vốn chỉ dành cho Learner).
  - Hiển thị `[RikiPath Logo]` bên trái, `[AnimatedNotificationBell]` (với unread badge Sakura Pink và hiệu ứng lắc chuông vật lý) và `[Calendar Icon]` điều hướng tới `AppRoutes.mentorCalendar` (`/mentor/calendar`) bên phải.
- Loại bỏ các `RikiBrandLockup` bị lặp lại trong phần `body` của `MentorHomeScreen`, `MentorAvailabilityScreen`, `MentorMeetingsScreen`, `MentorProfileScreen`.

### 3.2 Shared Bottom Navigation (`lib/core/widgets/riki_bottom_navigation_bar.dart` & `mentor_shared_widgets.dart`)
- Mở rộng `RikiBottomNavigationBar` nhận danh sách `destinations` tùy chọn (mặc định giữ nguyên 5 tab Learner).
- Triển khai `MentorBottomNavigationBar` tái sử dụng trực tiếp `RikiBottomNavigationBar` với 5 điểm đến của Mentor:
  1. `Trang chủ` (`AppRoutes.mentor`)
  2. `Lịch dạy` (`AppRoutes.mentorCalendar`)
  3. `Buổi tư vấn` (`AppRoutes.mentorMeetings`) — nút tròn nổi Sakura Pink ở trung tâm
  4. `Lịch trống` (`AppRoutes.mentorAvailability`)
  5. `Cá nhân` (`AppRoutes.mentorProfile`)

### 3.3 Mentor Home Dashboard (`lib/features/mentor/presentation/mentor_home_screen.dart`)
- **`MentorGreetingHeader`**: Chào mừng cá nhân hóa theo tên thật của Mentor từ `mentorProfileControllerProvider` (hoặc fallback trang nhã `"Chào mừng Cố vấn!"`), kèm badge trạng thái phê duyệt hồ sơ.
- **`SakuraMentorHeroBanner`**: Banner Sakura tràn viền đồng bộ phong cách Learner (`"Đồng hành cùng học viên"` / `"Quản lý buổi tư vấn và chia sẻ kinh nghiệm JLPT."`).
- **`_MentorApprovalBanner`**: Banner ngữ cảnh rõ ràng khi hồ sơ ở trạng thái `Pending`, `Rejected` (hiển thị lý do từ chối), `ChangesRequested` (hiển thị ghi chú), hoặc `Unverified`.
- **`_MentorKpiSummaryStrip`**: Hiển thị 3 chỉ số thực (`Sắp tới`, `Giờ trống`, `Đã dạy`). Khi đang tải hiển thị `…`, khi lỗi API hiển thị `—` (**tuyệt đối không giả mạo số `0` khi API lỗi**).
- **Partial & Full Error Resilience**:
  - Nếu `availability` lỗi nhưng `meetings` thành công (hoặc ngược lại), phần thành công vẫn hiển thị đầy đủ dữ liệu thật.
  - Nếu cả hai nguồn dữ liệu cùng lỗi, hiển thị thêm banner khôi phục hợp nhất (`mentor_home_both_error_banner`) với nút thử lại đồng thời.

### 3.4 Mentor Profile, Account Settings & 100% Shared Logout (`lib/features/mentor/presentation/mentor_profile_screen.dart`)
- Bổ sung khu vực **Tài khoản & Bảo mật (`_MentorAccountSettingsSection`)** tái sử dụng `ProfileSection` và `ProfileActionTile` của Learner:
  - **Thu nhập & Đối soát** (`AppRoutes.mentorCompensation`)
  - **Tài khoản ngân hàng** (`AppRoutes.mentorBankAccount`)
  - **Đổi mật khẩu** (`AppRoutes.mentorChangePassword` -> tái sử dụng `ChangePasswordScreen`)
  - **Cập nhật email** (`AppRoutes.mentorChangeEmail` -> tái sử dụng `UpdateEmailScreen`, tự động lấy email hiện tại từ `mentorProfileControllerProvider` khi role là `Mentor`)
  - **Ngôn ngữ hiển thị** (`showSakuraLanguageBottomSheet` — Tiếng Việt / 日本語)
  - **Đăng xuất** (`confirmAndPerformMentorLogout` -> mở `showProfileConfirmationSheet` với tiêu đề `"Bạn muốn đăng xuất?"`, nút `"Đăng xuất"` / `"Ở lại"`, xóa sạch session + invalidate toàn bộ Mentor/Notification providers và hiển thị Sakura Glass toast `"Đã đăng xuất"`).

---

## 4. Verification & Quality Gates

- **`flutter analyze --no-pub`**: `No issues found!` (0 errors, 0 warnings, 0 lints).
- **Focused Mentor & Router Test Suite**:
  - `flutter test test/features/mentor/mentor_contract_test.dart test/app/router/app_router_test.dart --no-pub` -> **71/71 passed**.
- **Full Repository Regression Suite**:
  - `flutter test --no-pub` -> **1,302 passed, 0 failed**.
- **Debug APK Build**:
  - `flutter build apk --debug --target-platform android-x64` -> `Built build\app\outputs\flutter-apk\app-debug.apk`.
- **`git diff --check`**: Clean (no whitespace/conflict markers).
- **Uncommitted Constraint**: All changes remain uncommitted in the working tree as requested.
