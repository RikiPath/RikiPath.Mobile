import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ja'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath'**
  String get appTitle;

  /// No description provided for @toastRegisterSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản thành công'**
  String get toastRegisterSuccessTitle;

  /// No description provided for @toastRegisterSuccessDescription.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng xác thực email để tiếp tục.'**
  String get toastRegisterSuccessDescription;

  /// No description provided for @toastVerifyEmailSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực email thành công'**
  String get toastVerifyEmailSuccessTitle;

  /// No description provided for @toastVerifyEmailSuccessDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể đăng nhập ngay bây giờ.'**
  String get toastVerifyEmailSuccessDescription;

  /// No description provided for @toastLoginSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thành công'**
  String get toastLoginSuccessTitle;

  /// No description provided for @toastLoginSuccessDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng bạn trở lại với RikiPath.'**
  String get toastLoginSuccessDescription;

  /// No description provided for @toastProfileUpdateSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật hồ sơ thành công'**
  String get toastProfileUpdateSuccessTitle;

  /// No description provided for @toastEmailUpdateSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật email thành công'**
  String get toastEmailUpdateSuccessTitle;

  /// No description provided for @toastPasswordChangeSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thành công'**
  String get toastPasswordChangeSuccessTitle;

  /// No description provided for @toastAvatarUploadSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ảnh đại diện thành công'**
  String get toastAvatarUploadSuccessTitle;

  /// No description provided for @toastNotificationUpdateSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông báo thành công'**
  String get toastNotificationUpdateSuccessTitle;

  /// No description provided for @toastJlptGoalUpdateSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật mục tiêu JLPT thành công'**
  String get toastJlptGoalUpdateSuccessTitle;

  /// No description provided for @toastActionFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hoàn tất thao tác'**
  String get toastActionFailedTitle;

  /// No description provided for @toastAudioFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể phát âm thanh'**
  String get toastAudioFailedTitle;

  /// No description provided for @languagePickerSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get languagePickerSemantics;

  /// No description provided for @languageMenuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ / 言語'**
  String get languageMenuTitle;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageJapanese.
  ///
  /// In vi, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageCodeVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'VI'**
  String get languageCodeVietnamese;

  /// No description provided for @languageCodeJapanese.
  ///
  /// In vi, this message translates to:
  /// **'JA'**
  String get languageCodeJapanese;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @clearFilters.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get clearFilters;

  /// No description provided for @all.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get all;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @continueLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get continueLabel;

  /// No description provided for @finish.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get finish;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @preparingLearningContent.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang chuẩn bị bài học cho bạn...'**
  String get preparingLearningContent;

  /// No description provided for @preparingLearningSubtext.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung và lộ trình học tập sẽ sẵn sàng trong giây lát.'**
  String get preparingLearningSubtext;

  /// No description provided for @notAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa khả dụng'**
  String get notAvailable;

  /// No description provided for @pageNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy trang: {uri}'**
  String pageNotFound(String uri);

  /// No description provided for @navigationHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navigationHome;

  /// No description provided for @navigationLearn.
  ///
  /// In vi, this message translates to:
  /// **'Học tập'**
  String get navigationLearn;

  /// No description provided for @navigationPractice.
  ///
  /// In vi, this message translates to:
  /// **'Luyện tập'**
  String get navigationPractice;

  /// No description provided for @navigationNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Sổ từ'**
  String get navigationNotebook;

  /// No description provided for @navigationProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get navigationProfile;

  /// No description provided for @splashTagline.
  ///
  /// In vi, this message translates to:
  /// **'Học tiếng Nhật • Luyện thi JLPT'**
  String get splashTagline;

  /// No description provided for @authPromotion.
  ///
  /// In vi, this message translates to:
  /// **'Học tiếng Nhật cá nhân hoá cùng AI'**
  String get authPromotion;

  /// No description provided for @loginWelcome.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại! 👋'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục hành trình chinh phục JLPT cùng RikiPath.'**
  String get loginSubtitle;

  /// No description provided for @studentEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email học viên'**
  String get studentEmail;

  /// No description provided for @emailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In vi, this message translates to:
  /// **'hocvien@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @rememberSession.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhớ phiên đăng nhập trên thiết bị này'**
  String get rememberSession;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @loggingIn.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập...'**
  String get loggingIn;

  /// No description provided for @loggingInSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập'**
  String get loggingInSemantics;

  /// No description provided for @loginSecureConnection.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối an toàn với tài khoản của bạn...'**
  String get loginSecureConnection;

  /// No description provided for @loginTipTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mẹo đăng nhập'**
  String get loginTipTitle;

  /// No description provided for @loginTipMessage.
  ///
  /// In vi, this message translates to:
  /// **'Sử dụng tài khoản đã đăng ký khóa học để đồng bộ chuỗi streak và lộ trình AI.'**
  String get loginTipMessage;

  /// No description provided for @loginFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đăng nhập'**
  String get loginFailedTitle;

  /// No description provided for @noAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản?'**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @securityFooter.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật chuẩn mã hóa Riki Learning'**
  String get securityFooter;

  /// No description provided for @registerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản RikiPath'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu xây dựng lộ trình học JLPT của riêng bạn.'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nguyễn Minh Anh'**
  String get fullNameHint;

  /// No description provided for @minimumSixCharacters.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu 6 ký tự'**
  String get minimumSixCharacters;

  /// No description provided for @confirmPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu'**
  String get confirmPasswordHint;

  /// No description provided for @termsPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Bằng việc đăng ký, bạn đồng ý với '**
  String get termsPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản dịch vụ'**
  String get termsOfService;

  /// No description provided for @termsJoiner.
  ///
  /// In vi, this message translates to:
  /// **' & '**
  String get termsJoiner;

  /// No description provided for @privacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách bảo mật'**
  String get privacyPolicy;

  /// No description provided for @termsSuffix.
  ///
  /// In vi, this message translates to:
  /// **' của RikiPath.'**
  String get termsSuffix;

  /// No description provided for @registerFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo tài khoản'**
  String get registerFailedTitle;

  /// No description provided for @creatingAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo tài khoản...'**
  String get creatingAccount;

  /// No description provided for @creatingAccountSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo tài khoản'**
  String get creatingAccountSemantics;

  /// No description provided for @creatingAccountMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo tài khoản học viên và gửi email xác thực...'**
  String get creatingAccountMessage;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản?'**
  String get alreadyHaveAccount;

  /// No description provided for @accountCreatedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo tài khoản'**
  String get accountCreatedStatus;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản thành công'**
  String get accountCreatedTitle;

  /// No description provided for @accountCreatedMessage.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đã gửi mã xác thực tới\n{email}.'**
  String accountCreatedMessage(String email);

  /// No description provided for @checkEmailVerification.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra email để xác thực tài khoản.'**
  String get checkEmailVerification;

  /// No description provided for @verificationBackendBlocker.
  ///
  /// In vi, this message translates to:
  /// **'Email chứa mã xác thực 6 chữ số, có hiệu lực trong 30 phút. RikiPath chưa nhận đủ thông tin tài khoản để mở bước nhập mã một cách an toàn.'**
  String get verificationBackendBlocker;

  /// No description provided for @returnToLogin.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại đăng nhập'**
  String get returnToLogin;

  /// No description provided for @verifyEmailStatus.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực email'**
  String get verifyEmailStatus;

  /// No description provided for @emailVerifiedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Email đã xác thực'**
  String get emailVerifiedStatus;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã xác thực'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã 6 chữ số đã được gửi tới email của bạn.'**
  String get verifyEmailSubtitle;

  /// No description provided for @verificationCodeSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực đã được gửi đến'**
  String get verificationCodeSentTo;

  /// No description provided for @verificationCodeSentToYourEmail.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực đã được gửi đến email của bạn.'**
  String get verificationCodeSentToYourEmail;

  /// No description provided for @verificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực'**
  String get verificationCode;

  /// No description provided for @verificationCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'000000'**
  String get verificationCodeHint;

  /// No description provided for @didNotReceiveVerificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được mã?'**
  String get didNotReceiveVerificationCode;

  /// No description provided for @resendVerificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get resendVerificationCode;

  /// No description provided for @resendVerificationCodeIn.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã sau {time}'**
  String resendVerificationCodeIn(String time);

  /// No description provided for @resendingVerificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi lại...'**
  String get resendingVerificationCode;

  /// No description provided for @verificationCodeResentMessage.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đã gửi một mã xác thực mới tới email của bạn.'**
  String get verificationCodeResentMessage;

  /// No description provided for @resendVerificationFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi lại mã'**
  String get resendVerificationFailedTitle;

  /// No description provided for @verify.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực'**
  String get verify;

  /// No description provided for @verifying.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác thực...'**
  String get verifying;

  /// No description provided for @verifyEmailSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực email thành công'**
  String get verifyEmailSuccessTitle;

  /// No description provided for @verifyEmailSuccessMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn đã sẵn sàng để đăng nhập.'**
  String get verifyEmailSuccessMessage;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @registeredEmail.
  ///
  /// In vi, this message translates to:
  /// **'EMAIL ĐÃ ĐĂNG KÝ'**
  String get registeredEmail;

  /// No description provided for @sendRequest.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu'**
  String get sendRequest;

  /// No description provided for @sendingRequest.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi yêu cầu...'**
  String get sendingRequest;

  /// No description provided for @requestSentStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi email'**
  String get requestSentStatus;

  /// No description provided for @requestSentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đã được gửi'**
  String get requestSentTitle;

  /// No description provided for @requestSentMessage.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra hộp thư {email} để tiếp tục đặt lại mật khẩu.'**
  String requestSentMessage(String email);

  /// No description provided for @resendCountdown.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại ({seconds}s)'**
  String resendCountdown(int seconds);

  /// No description provided for @passwordRecoveryUnavailableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể gửi yêu cầu'**
  String get passwordRecoveryUnavailableTitle;

  /// No description provided for @account.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get account;

  /// No description provided for @accountSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật tài khoản'**
  String get accountSecurity;

  /// No description provided for @accountSecuritySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý email đăng nhập, mật khẩu và phiên hiện tại.'**
  String get accountSecuritySubtitle;

  /// No description provided for @changeEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get changeEmail;

  /// No description provided for @changeEmailSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã xác thực tới email mới'**
  String get changeEmailSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu mật khẩu hiện tại'**
  String get changePasswordSubtitle;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @newEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email mới'**
  String get newEmail;

  /// No description provided for @newEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'emailmoi@example.com'**
  String get newEmailHint;

  /// No description provided for @updateEmail.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật email'**
  String get updateEmail;

  /// No description provided for @updatingEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật...'**
  String get updatingEmail;

  /// No description provided for @emailUpdatedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật email'**
  String get emailUpdatedTitle;

  /// No description provided for @emailUpdatedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra email mới để hoàn tất xác thực.'**
  String get emailUpdatedMessage;

  /// No description provided for @currentPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get confirmNewPassword;

  /// No description provided for @changePasswordAction.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật mật khẩu'**
  String get changePasswordAction;

  /// No description provided for @changingPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật...'**
  String get changingPassword;

  /// No description provided for @passwordChangedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi mật khẩu'**
  String get passwordChangedTitle;

  /// No description provided for @passwordChangedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu của bạn đã được cập nhật.'**
  String get passwordChangedMessage;

  /// No description provided for @showPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get hidePassword;

  /// No description provided for @validationEmailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ. Vui lòng kiểm tra lại định dạng.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 6 ký tự.'**
  String get validationPasswordLength;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng xác nhận mật khẩu.'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp.'**
  String get validationPasswordMismatch;

  /// No description provided for @validationVerificationCodeRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã xác thực.'**
  String get validationVerificationCodeRequired;

  /// No description provided for @validationVerificationCodeLength.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực phải gồm đúng 6 chữ số.'**
  String get validationVerificationCodeLength;

  /// No description provided for @validationTermsRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đồng ý với điều khoản trước khi đăng ký.'**
  String get validationTermsRequired;

  /// No description provided for @authErrorPasswordRecoveryUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng lấy lại mật khẩu hiện chưa khả dụng trong ứng dụng. Vui lòng liên hệ trung tâm trợ giúp.'**
  String get authErrorPasswordRecoveryUnavailable;

  /// No description provided for @authErrorUnsupportedRole.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng di động hiện chỉ hỗ trợ tài khoản Học viên và Mentor.'**
  String get authErrorUnsupportedRole;

  /// No description provided for @mentorLandingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không gian Mentor'**
  String get mentorLandingTitle;

  /// No description provided for @mentorLandingDescription.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi lịch trống và các lịch tư vấn sắp tới của bạn.'**
  String get mentorLandingDescription;

  /// No description provided for @mentorHomeGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại'**
  String get mentorHomeGreeting;

  /// No description provided for @mentorAvailabilityTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch trống của tôi'**
  String get mentorAvailabilityTitle;

  /// No description provided for @mentorAvailabilityDescription.
  ///
  /// In vi, this message translates to:
  /// **'Các khung giờ đang được hiển thị cho học viên.'**
  String get mentorAvailabilityDescription;

  /// No description provided for @mentorAvailabilityCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} khung giờ'**
  String mentorAvailabilityCount(int count);

  /// No description provided for @mentorAvailabilityEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có khung giờ trống nào.'**
  String get mentorAvailabilityEmpty;

  /// No description provided for @mentorAvailabilityError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải lịch trống. Vui lòng thử lại.'**
  String get mentorAvailabilityError;

  /// No description provided for @mentorAvailabilityReadOnlyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ chỉ đọc'**
  String get mentorAvailabilityReadOnlyTitle;

  /// No description provided for @mentorAvailabilityReadOnlyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể xem lịch trống trên ứng dụng. Tính năng thay đổi lịch sẽ được mở khi cách xử lý múi giờ được thống nhất.'**
  String get mentorAvailabilityReadOnlyMessage;

  /// No description provided for @mentorViewAvailability.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch trống'**
  String get mentorViewAvailability;

  /// No description provided for @mentorMeetingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tư vấn của tôi'**
  String get mentorMeetingsTitle;

  /// No description provided for @mentorMeetingsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Các buổi tư vấn đã được xác nhận với học viên.'**
  String get mentorMeetingsDescription;

  /// No description provided for @mentorMeetingsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} buổi tư vấn'**
  String mentorMeetingsCount(int count);

  /// No description provided for @mentorMeetingsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có lịch tư vấn nào.'**
  String get mentorMeetingsEmpty;

  /// No description provided for @mentorMeetingsError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải lịch tư vấn. Vui lòng thử lại.'**
  String get mentorMeetingsError;

  /// No description provided for @mentorViewMeetings.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch tư vấn'**
  String get mentorViewMeetings;

  /// No description provided for @mentorMeetingDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết buổi tư vấn'**
  String get mentorMeetingDetailTitle;

  /// No description provided for @mentorLearnerLabel.
  ///
  /// In vi, this message translates to:
  /// **'Học viên'**
  String get mentorLearnerLabel;

  /// No description provided for @mentorLearnerUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông tin học viên'**
  String get mentorLearnerUnknown;

  /// No description provided for @mentorScheduleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get mentorScheduleLabel;

  /// No description provided for @mentorSchedulePending.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định thời gian'**
  String get mentorSchedulePending;

  /// No description provided for @mentorStartTimeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get mentorStartTimeLabel;

  /// No description provided for @mentorEndTimeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get mentorEndTimeLabel;

  /// No description provided for @mentorStatusLabel.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get mentorStatusLabel;

  /// No description provided for @mentorSlotOpen.
  ///
  /// In vi, this message translates to:
  /// **'Còn trống'**
  String get mentorSlotOpen;

  /// No description provided for @mentorSlotBooked.
  ///
  /// In vi, this message translates to:
  /// **'Đã được đặt'**
  String get mentorSlotBooked;

  /// No description provided for @mentorJoinMeeting.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia buổi tư vấn'**
  String get mentorJoinMeeting;

  /// No description provided for @mentorMeetingLinkUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Phòng họp chưa sẵn sàng cho lịch tư vấn này.'**
  String get mentorMeetingLinkUnavailable;

  /// No description provided for @mentorMeetingNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy buổi tư vấn trong lịch của bạn.'**
  String get mentorMeetingNotFound;

  /// No description provided for @mentorJoinFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở phòng họp'**
  String get mentorJoinFailedTitle;

  /// No description provided for @mentorJoinFailedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết phòng họp không thể mở trên thiết bị này.'**
  String get mentorJoinFailedDescription;

  /// No description provided for @mentorStatusAwaitingPayment.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get mentorStatusAwaitingPayment;

  /// No description provided for @mentorStatusPendingAssignment.
  ///
  /// In vi, this message translates to:
  /// **'Chờ phân công'**
  String get mentorStatusPendingAssignment;

  /// No description provided for @mentorStatusAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Đã phân công'**
  String get mentorStatusAssigned;

  /// No description provided for @mentorStatusAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã chấp nhận'**
  String get mentorStatusAccepted;

  /// No description provided for @mentorStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get mentorStatusCompleted;

  /// No description provided for @mentorStatusCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get mentorStatusCancelled;

  /// No description provided for @mentorStatusUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get mentorStatusUnknown;

  /// No description provided for @unsupportedRoleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò chưa được hỗ trợ'**
  String get unsupportedRoleTitle;

  /// No description provided for @unsupportedRoleDescription.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò {role} không thuộc phạm vi ứng dụng di động. Vui lòng đăng xuất và dùng tài khoản Học viên hoặc Mentor.'**
  String unsupportedRoleDescription(String role);

  /// No description provided for @authErrorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối tới RikiPath. Vui lòng kiểm tra mạng và thử lại.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.'**
  String get authErrorSessionExpired;

  /// No description provided for @authErrorForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thay đổi này.'**
  String get authErrorForbidden;

  /// No description provided for @authErrorNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tài khoản cần cập nhật.'**
  String get authErrorNotFound;

  /// No description provided for @authErrorLoginValidation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đăng nhập chưa hợp lệ. Vui lòng kiểm tra lại.'**
  String get authErrorLoginValidation;

  /// No description provided for @authErrorRegisterValidation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đăng ký chưa hợp lệ hoặc email đã được sử dụng.'**
  String get authErrorRegisterValidation;

  /// No description provided for @authErrorVerifyValidation.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực không hợp lệ, đã hết hạn hoặc đã được sử dụng.'**
  String get authErrorVerifyValidation;

  /// No description provided for @authErrorResendValidation.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi lại mã cho email này. Vui lòng kiểm tra và thử lại.'**
  String get authErrorResendValidation;

  /// No description provided for @authErrorResendRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã yêu cầu gửi lại mã quá nhiều lần. Vui lòng thử lại sau.'**
  String get authErrorResendRateLimited;

  /// No description provided for @authErrorUpdateEmailValidation.
  ///
  /// In vi, this message translates to:
  /// **'Email mới chưa hợp lệ hoặc đã được sử dụng.'**
  String get authErrorUpdateEmailValidation;

  /// No description provided for @authErrorChangePasswordValidation.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại không đúng hoặc mật khẩu mới chưa hợp lệ.'**
  String get authErrorChangePasswordValidation;

  /// No description provided for @authErrorRecoveryValidation.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa hợp lệ. Vui lòng kiểm tra lại.'**
  String get authErrorRecoveryValidation;

  /// No description provided for @authErrorServer.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang gặp sự cố. Vui lòng thử lại sau ít phút.'**
  String get authErrorServer;

  /// No description provided for @authErrorUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi ngoài dự kiến. Vui lòng thử lại.'**
  String get authErrorUnknown;

  /// No description provided for @authErrorVerifyMissingUserId.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath chưa nhận đủ thông tin tài khoản cần thiết để xác thực email.'**
  String get authErrorVerifyMissingUserId;

  /// No description provided for @authErrorResendMissingEmail.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath chưa nhận được email cần gửi lại mã xác thực.'**
  String get authErrorResendMissingEmail;

  /// No description provided for @authErrorSessionMissingUserId.
  ///
  /// In vi, this message translates to:
  /// **'Phiên hiện tại thiếu thông tin tài khoản cần thiết. Vui lòng đăng nhập lại.'**
  String get authErrorSessionMissingUserId;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get profileTitle;

  /// No description provided for @learner.
  ///
  /// In vi, this message translates to:
  /// **'Học viên'**
  String get learner;

  /// No description provided for @currentGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu hiện tại'**
  String get currentGoal;

  /// No description provided for @learningStatistics.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê học tập'**
  String get learningStatistics;

  /// No description provided for @latestScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gần nhất'**
  String get latestScore;

  /// No description provided for @progressAndHistory.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ & lịch sử học'**
  String get progressAndHistory;

  /// No description provided for @consultation.
  ///
  /// In vi, this message translates to:
  /// **'Tư vấn'**
  String get consultation;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @languageSettings.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get languageSettings;

  /// No description provided for @emailVerifiedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Email của bạn đã được xác thực trên RikiPath.'**
  String get emailVerifiedMessage;

  /// No description provided for @verifyEmailInputSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã được gửi tới email của bạn để hoàn tất xác thực.'**
  String get verifyEmailInputSubtitle;

  /// No description provided for @verifyEmailBlockedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tiếp tục từ đăng ký'**
  String get verifyEmailBlockedTitle;

  /// No description provided for @verifyEmailBlockedMessage.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath chưa nhận đủ thông tin tài khoản để gửi mã xác thực một cách an toàn.'**
  String get verifyEmailBlockedMessage;

  /// No description provided for @verificationCodeValidity.
  ///
  /// In vi, this message translates to:
  /// **'Mã gồm 6 chữ số và có hiệu lực trong 30 phút.'**
  String get verificationCodeValidity;

  /// No description provided for @verifyEmailFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xác thực email'**
  String get verifyEmailFailedTitle;

  /// No description provided for @verifiedPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác thực?'**
  String get verifiedPrompt;

  /// No description provided for @forgotPasswordSentBody.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi đã gửi hướng dẫn lấy lại mật khẩu tới {email}.'**
  String forgotPasswordSentBody(String email);

  /// No description provided for @forgotPasswordCheckEmail.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra email để tiếp tục đặt lại mật khẩu.'**
  String get forgotPasswordCheckEmail;

  /// No description provided for @forgotPasswordSpamHint.
  ///
  /// In vi, this message translates to:
  /// **'Nếu không thấy email trong Hộp thư đến, vui lòng kiểm tra Thư rác hoặc Spam.'**
  String get forgotPasswordSpamHint;

  /// No description provided for @forgotPasswordResend.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được thư? Gửi lại (58s)'**
  String get forgotPasswordResend;

  /// No description provided for @helpDirectPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Cần trợ giúp trực tiếp?'**
  String get helpDirectPrefix;

  /// No description provided for @helpSensei.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ Sensei hỗ trợ'**
  String get helpSensei;

  /// No description provided for @helpAccountPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Cần hỗ trợ về tài khoản?'**
  String get helpAccountPrefix;

  /// No description provided for @helpCenter.
  ///
  /// In vi, this message translates to:
  /// **'Trung tâm trợ giúp'**
  String get helpCenter;

  /// No description provided for @newLoginEmailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Email đăng nhập mới'**
  String get newLoginEmailTitle;

  /// No description provided for @newLoginEmailSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi cập nhật, máy chủ sẽ gửi mã xác thực tới email mới.'**
  String get newLoginEmailSubtitle;

  /// No description provided for @missingSessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu thông tin phiên'**
  String get missingSessionTitle;

  /// No description provided for @missingSessionMessage.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập hiện tại thiếu thông tin cần thiết. Vui lòng đăng xuất rồi đăng nhập lại.'**
  String get missingSessionMessage;

  /// No description provided for @changeEmailFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đổi email'**
  String get changeEmailFailedTitle;

  /// No description provided for @emailUpdatedVerificationMessage.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được cập nhật. Hãy nhập mã được gửi tới email mới.'**
  String get emailUpdatedVerificationMessage;

  /// No description provided for @enterVerificationCode.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã xác thực'**
  String get enterVerificationCode;

  /// No description provided for @protectAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảo vệ tài khoản'**
  String get protectAccountTitle;

  /// No description provided for @passwordContractHint.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới phải có ít nhất 6 ký tự theo hợp đồng hiện tại.'**
  String get passwordContractHint;

  /// No description provided for @currentPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu hiện tại'**
  String get currentPasswordHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu mới'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu mới'**
  String get confirmNewPasswordHint;

  /// No description provided for @changePasswordFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đổi mật khẩu'**
  String get changePasswordFailedTitle;

  /// No description provided for @passwordUpdatedSessionMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu đã được cập nhật. Phiên đăng nhập hiện tại vẫn được giữ.'**
  String get passwordUpdatedSessionMessage;

  /// No description provided for @dayCount.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {count}'**
  String dayCount(int count);

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No description provided for @openProfile.
  ///
  /// In vi, this message translates to:
  /// **'Mở trang cá nhân'**
  String get openProfile;

  /// No description provided for @homeToolsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Làm quen với công cụ học tập'**
  String get homeToolsTitle;

  /// No description provided for @homeLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải Trang chủ'**
  String get homeLoadFailed;

  /// No description provided for @checkConnectionRetry.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra kết nối và thử lại.'**
  String get checkConnectionRetry;

  /// No description provided for @greetingName.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào, {name}! 👋'**
  String greetingName(String name);

  /// No description provided for @jlptGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu JLPT {level}'**
  String jlptGoal(String level);

  /// No description provided for @notStarted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa bắt đầu'**
  String get notStarted;

  /// No description provided for @lessonPartsCompleted.
  ///
  /// In vi, this message translates to:
  /// **' • {completed}/{total} phần hoàn thành'**
  String lessonPartsCompleted(int completed, int total);

  /// No description provided for @lessonProgressSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ bài học {percentage} phần trăm'**
  String lessonProgressSemantics(int percentage);

  /// No description provided for @startLearning.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu học'**
  String get startLearning;

  /// No description provided for @stageCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} chặng'**
  String stageCount(int count);

  /// No description provided for @personalizedByAbility.
  ///
  /// In vi, this message translates to:
  /// **'Được cá nhân hóa theo năng lực'**
  String get personalizedByAbility;

  /// No description provided for @viewRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Xem lộ trình'**
  String get viewRoadmap;

  /// No description provided for @initialSetup.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập ban đầu'**
  String get initialSetup;

  /// No description provided for @initialSetupSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các bước khởi đầu cho người mới'**
  String get initialSetupSubtitle;

  /// No description provided for @completedCount.
  ///
  /// In vi, this message translates to:
  /// **'{completed}/{total} hoàn tất'**
  String completedCount(int completed, int total);

  /// No description provided for @leaveSetup.
  ///
  /// In vi, this message translates to:
  /// **'Rời thiết lập'**
  String get leaveSetup;

  /// No description provided for @onboardingJlptTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu JLPT của bạn là gì?'**
  String get onboardingJlptTitle;

  /// No description provided for @onboardingJlptDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chọn trình độ bạn muốn hướng tới để RikiPath cá nhân hóa lộ trình học.'**
  String get onboardingJlptDescription;

  /// No description provided for @popular.
  ///
  /// In vi, this message translates to:
  /// **'Phổ biến'**
  String get popular;

  /// No description provided for @mostPopular.
  ///
  /// In vi, this message translates to:
  /// **'Phổ biến nhất'**
  String get mostPopular;

  /// No description provided for @onboardingJlptHelper.
  ///
  /// In vi, this message translates to:
  /// **'Chọn N5, N4 hoặc N3 để tiếp tục.'**
  String get onboardingJlptHelper;

  /// No description provided for @jlptN5Description.
  ///
  /// In vi, this message translates to:
  /// **'Nền tảng tiếng Nhật cơ bản'**
  String get jlptN5Description;

  /// No description provided for @jlptN4Description.
  ///
  /// In vi, this message translates to:
  /// **'Củng cố kiến thức sơ – trung cấp'**
  String get jlptN4Description;

  /// No description provided for @jlptN3Description.
  ///
  /// In vi, this message translates to:
  /// **'Hướng tới trình độ trung cấp'**
  String get jlptN3Description;

  /// No description provided for @backToGoalSelection.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại bước chọn mục tiêu'**
  String get backToGoalSelection;

  /// No description provided for @onboardingStudyTimeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn học bao lâu mỗi ngày?'**
  String get onboardingStudyTimeTitle;

  /// No description provided for @onboardingStudyTimeDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhịp học phù hợp với lịch sinh hoạt của bạn. Sự đều đặn quan trọng hơn tốc độ.'**
  String get onboardingStudyTimeDescription;

  /// No description provided for @studyMinutesPerDay.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút/ngày'**
  String studyMinutesPerDay(int minutes);

  /// No description provided for @studyPaceGentle.
  ///
  /// In vi, this message translates to:
  /// **'Nhẹ nhàng'**
  String get studyPaceGentle;

  /// No description provided for @studyPaceBalanced.
  ///
  /// In vi, this message translates to:
  /// **'Cân bằng'**
  String get studyPaceBalanced;

  /// No description provided for @studyPaceActive.
  ///
  /// In vi, this message translates to:
  /// **'Tích cực'**
  String get studyPaceActive;

  /// No description provided for @studyPaceIntensive.
  ///
  /// In vi, this message translates to:
  /// **'Chuyên sâu'**
  String get studyPaceIntensive;

  /// No description provided for @finishSetup.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất thiết lập'**
  String get finishSetup;

  /// No description provided for @onboardingAdjustHelper.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể quay lại để điều chỉnh các lựa chọn.'**
  String get onboardingAdjustHelper;

  /// No description provided for @setupCompleteStatus.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập hoàn tất'**
  String get setupCompleteStatus;

  /// No description provided for @readyToStart.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng bắt đầu! 🎉'**
  String get readyToStart;

  /// No description provided for @learningPlanReady.
  ///
  /// In vi, this message translates to:
  /// **'Lộ trình học của bạn đã được thiết lập.'**
  String get learningPlanReady;

  /// No description provided for @studySummary.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút/ngày · {description}'**
  String studySummary(int minutes, String description);

  /// No description provided for @goalPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu:'**
  String get goalPrefix;

  /// No description provided for @stepOfTwo.
  ///
  /// In vi, this message translates to:
  /// **'Bước {step} / 2'**
  String stepOfTwo(int step);

  /// No description provided for @setupProgressSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ thiết lập: bước {step} trên 2'**
  String setupProgressSemantics(int step);

  /// No description provided for @setupCompleteSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập lộ trình hoàn tất'**
  String get setupCompleteSemantics;

  /// No description provided for @mockTestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thi thử JLPT'**
  String get mockTestTitle;

  /// No description provided for @mockTestSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mô phỏng cấu trúc từ vựng/ngữ pháp, đọc và nghe'**
  String get mockTestSubtitle;

  /// No description provided for @notAttempted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa làm'**
  String get notAttempted;

  /// No description provided for @latestResult.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả gần nhất'**
  String get latestResult;

  /// No description provided for @view.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get view;

  /// No description provided for @aiGrading.
  ///
  /// In vi, this message translates to:
  /// **'Chấm bài AI'**
  String get aiGrading;

  /// No description provided for @writingAndKanjiPractice.
  ///
  /// In vi, this message translates to:
  /// **'Luyện viết & Kanji'**
  String get writingAndKanjiPractice;

  /// No description provided for @library.
  ///
  /// In vi, this message translates to:
  /// **'THƯ VIỆN'**
  String get library;

  /// No description provided for @vocabulary.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng'**
  String get vocabulary;

  /// No description provided for @vocabularyDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết từ vựng'**
  String get vocabularyDetail;

  /// No description provided for @vocabularyAudioFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể phát âm thanh từ vựng.'**
  String get vocabularyAudioFailed;

  /// No description provided for @chooseNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Sổ từ'**
  String get chooseNotebook;

  /// No description provided for @wordCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} từ'**
  String wordCount(int count);

  /// No description provided for @savedToCollection.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào {name}.'**
  String savedToCollection(String name);

  /// No description provided for @vocabularySearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm từ tiếng Nhật, cách đọc hoặc nghĩa...'**
  String get vocabularySearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get clearSearch;

  /// No description provided for @illustrationData.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung bổ sung'**
  String get illustrationData;

  /// No description provided for @saved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get saved;

  /// No description provided for @audioUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có âm thanh'**
  String get audioUnavailable;

  /// No description provided for @listenPronunciation.
  ///
  /// In vi, this message translates to:
  /// **'Nghe phát âm'**
  String get listenPronunciation;

  /// No description provided for @loadMore.
  ///
  /// In vi, this message translates to:
  /// **'Tải thêm'**
  String get loadMore;

  /// No description provided for @vocabularyEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy từ vựng'**
  String get vocabularyEmptyTitle;

  /// No description provided for @vocabularyEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thử từ khóa khác hoặc bỏ bộ lọc JLPT.'**
  String get vocabularyEmptyMessage;

  /// No description provided for @vocabularyLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải thư viện từ vựng'**
  String get vocabularyLoadFailed;

  /// No description provided for @localFixtureNotice.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung bổ sung bên dưới được lưu sẵn trên thiết bị.'**
  String get localFixtureNotice;

  /// No description provided for @meaning.
  ///
  /// In vi, this message translates to:
  /// **'Ý nghĩa'**
  String get meaning;

  /// No description provided for @examples.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ'**
  String get examples;

  /// No description provided for @usageNuance.
  ///
  /// In vi, this message translates to:
  /// **'Sắc thái sử dụng'**
  String get usageNuance;

  /// No description provided for @commonCollocations.
  ///
  /// In vi, this message translates to:
  /// **'Cụm từ thường gặp'**
  String get commonCollocations;

  /// No description provided for @kanjiAnalysis.
  ///
  /// In vi, this message translates to:
  /// **'Phân tích Kanji'**
  String get kanjiAnalysis;

  /// No description provided for @relatedLessons.
  ///
  /// In vi, this message translates to:
  /// **'Bài học liên quan'**
  String get relatedLessons;

  /// No description provided for @wordAlreadySaved.
  ///
  /// In vi, this message translates to:
  /// **'Từ này đã được lưu.'**
  String get wordAlreadySaved;

  /// No description provided for @personalNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Sổ từ cá nhân'**
  String get personalNotebook;

  /// No description provided for @saveWordDescription.
  ///
  /// In vi, this message translates to:
  /// **'Lưu từ này để ôn tập trong danh sách của bạn.'**
  String get saveWordDescription;

  /// No description provided for @saveToNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào Sổ từ'**
  String get saveToNotebook;

  /// No description provided for @processing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get processing;

  /// No description provided for @kanjiDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết Kanji'**
  String get kanjiDetail;

  /// No description provided for @strokeOrder.
  ///
  /// In vi, this message translates to:
  /// **'Thứ tự nét viết'**
  String get strokeOrder;

  /// No description provided for @kanjiAudioFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể phát âm thanh Kanji.'**
  String get kanjiAudioFailed;

  /// No description provided for @itemCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục'**
  String itemCount(int count);

  /// No description provided for @kanjiSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo Kanji hoặc ý nghĩa'**
  String get kanjiSearchHint;

  /// No description provided for @search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get search;

  /// No description provided for @kanjiCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} Kanji'**
  String kanjiCount(int count);

  /// No description provided for @sampleData.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung bổ sung'**
  String get sampleData;

  /// No description provided for @showMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get showMore;

  /// No description provided for @strokeCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} nét'**
  String strokeCount(int count);

  /// No description provided for @onReading.
  ///
  /// In vi, this message translates to:
  /// **'Âm On'**
  String get onReading;

  /// No description provided for @kunReading.
  ///
  /// In vi, this message translates to:
  /// **'Âm Kun'**
  String get kunReading;

  /// No description provided for @listenReading.
  ///
  /// In vi, this message translates to:
  /// **'Nghe cách đọc'**
  String get listenReading;

  /// No description provided for @kanjiEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy Kanji'**
  String get kanjiEmptyTitle;

  /// No description provided for @kanjiLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải thư viện Kanji'**
  String get kanjiLoadFailed;

  /// No description provided for @memoryTip.
  ///
  /// In vi, this message translates to:
  /// **'Mẹo ghi nhớ'**
  String get memoryTip;

  /// No description provided for @commonCompounds.
  ///
  /// In vi, this message translates to:
  /// **'Từ ghép thường gặp'**
  String get commonCompounds;

  /// No description provided for @savedToNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào Sổ từ'**
  String get savedToNotebook;

  /// No description provided for @radicalLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bộ {radical}'**
  String radicalLabel(String radical);

  /// No description provided for @stitchFixtureNotice.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung bổ sung được lưu sẵn trên thiết bị.'**
  String get stitchFixtureNotice;

  /// No description provided for @reading.
  ///
  /// In vi, this message translates to:
  /// **'Cách đọc'**
  String get reading;

  /// No description provided for @noData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu'**
  String get noData;

  /// No description provided for @viewStrokeOrder.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết thứ tự nét'**
  String get viewStrokeOrder;

  /// No description provided for @sampleBadge.
  ///
  /// In vi, this message translates to:
  /// **'BỔ SUNG'**
  String get sampleBadge;

  /// No description provided for @strokeProgress.
  ///
  /// In vi, this message translates to:
  /// **'Nét {current}/{total}'**
  String strokeProgress(int current, int total);

  /// No description provided for @restartStroke.
  ///
  /// In vi, this message translates to:
  /// **'Phát lại từ đầu'**
  String get restartStroke;

  /// No description provided for @previousStroke.
  ///
  /// In vi, this message translates to:
  /// **'Nét trước'**
  String get previousStroke;

  /// No description provided for @nextStroke.
  ///
  /// In vi, this message translates to:
  /// **'Nét tiếp theo'**
  String get nextStroke;

  /// No description provided for @strokeProgressTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiến trình từng nét'**
  String get strokeProgressTitle;

  /// No description provided for @strokeNumber.
  ///
  /// In vi, this message translates to:
  /// **'Nét {number}'**
  String strokeNumber(int number);

  /// No description provided for @strokeRules.
  ///
  /// In vi, this message translates to:
  /// **'Quy tắc bút thuận'**
  String get strokeRules;

  /// No description provided for @strokeFixtureWarning.
  ///
  /// In vi, this message translates to:
  /// **'Phần minh họa nét viết này được cung cấp để bạn tham khảo.'**
  String get strokeFixtureWarning;

  /// No description provided for @strokeImageOnlyWarning.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chỉ có ảnh thứ tự nét; chưa hỗ trợ phát từng nét.'**
  String get strokeImageOnlyWarning;

  /// No description provided for @backToKanjiDetail.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại chi tiết chữ {character}'**
  String backToKanjiDetail(String character);

  /// No description provided for @grammar.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ pháp'**
  String get grammar;

  /// No description provided for @grammarDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết ngữ pháp'**
  String get grammarDetail;

  /// No description provided for @grammarSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm cấu trúc ngữ pháp hoặc ý nghĩa…'**
  String get grammarSearchHint;

  /// No description provided for @grammarPatternCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} cấu trúc'**
  String grammarPatternCount(int count);

  /// No description provided for @grammarStructureInline.
  ///
  /// In vi, this message translates to:
  /// **'Cấu trúc: {structure}'**
  String grammarStructureInline(String structure);

  /// No description provided for @grammarEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy ngữ pháp'**
  String get grammarEmptyTitle;

  /// No description provided for @grammarLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải thư viện ngữ pháp'**
  String get grammarLoadFailed;

  /// No description provided for @grammarMeaningNature.
  ///
  /// In vi, this message translates to:
  /// **'Ý nghĩa & bản chất'**
  String get grammarMeaningNature;

  /// No description provided for @grammarStructure.
  ///
  /// In vi, this message translates to:
  /// **'Cấu trúc ngữ pháp'**
  String get grammarStructure;

  /// No description provided for @usage.
  ///
  /// In vi, this message translates to:
  /// **'Cách sử dụng'**
  String get usage;

  /// No description provided for @grammarFixtureNotice.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung giải thích bổ sung được lưu sẵn trên thiết bị.'**
  String get grammarFixtureNotice;

  /// No description provided for @practicalExamples.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ thực tế'**
  String get practicalExamples;

  /// No description provided for @usageCautions.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý khi dùng'**
  String get usageCautions;

  /// No description provided for @relatedGrammar.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ pháp liên quan & phân biệt'**
  String get relatedGrammar;

  /// No description provided for @collectionCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo danh sách mới.'**
  String get collectionCreated;

  /// No description provided for @wordAddedToNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm từ vào Sổ từ.'**
  String get wordAddedToNotebook;

  /// No description provided for @removeFromNotebookQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khỏi Sổ từ?'**
  String get removeFromNotebookQuestion;

  /// No description provided for @removeEntryMessage.
  ///
  /// In vi, this message translates to:
  /// **'“{term}” sẽ bị xóa khỏi danh sách và hàng đợi ôn tập liên kết.'**
  String removeEntryMessage(String term);

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @removedFromNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa khỏi Sổ từ.'**
  String get removedFromNotebook;

  /// No description provided for @createCollection.
  ///
  /// In vi, this message translates to:
  /// **'Tạo danh sách mới'**
  String get createCollection;

  /// No description provided for @collectionNameRequiredLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh sách *'**
  String get collectionNameRequiredLabel;

  /// No description provided for @collectionNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên danh sách.'**
  String get collectionNameRequired;

  /// No description provided for @optionalDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả (tùy chọn)'**
  String get optionalDescription;

  /// No description provided for @createCollectionAction.
  ///
  /// In vi, this message translates to:
  /// **'Tạo danh sách'**
  String get createCollectionAction;

  /// No description provided for @addNewWord.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ mới'**
  String get addNewWord;

  /// No description provided for @notebookApiFieldsHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ, cách đọc, ý nghĩa và ghi chú bạn muốn lưu.'**
  String get notebookApiFieldsHint;

  /// No description provided for @japaneseWordRequiredLabel.
  ///
  /// In vi, this message translates to:
  /// **'Từ tiếng Nhật *'**
  String get japaneseWordRequiredLabel;

  /// No description provided for @wordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập từ cần lưu.'**
  String get wordRequired;

  /// No description provided for @optionalReading.
  ///
  /// In vi, this message translates to:
  /// **'Cách đọc (tùy chọn)'**
  String get optionalReading;

  /// No description provided for @meaningRequiredLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa tiếng Việt *'**
  String get meaningRequiredLabel;

  /// No description provided for @meaningRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập nghĩa của từ.'**
  String get meaningRequired;

  /// No description provided for @optionalPersonalNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú cá nhân (tùy chọn)'**
  String get optionalPersonalNote;

  /// No description provided for @yourCollections.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập của bạn'**
  String get yourCollections;

  /// No description provided for @collectionSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm bộ sưu tập…'**
  String get collectionSearchHint;

  /// No description provided for @noMatchingCollection.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bộ sưu tập phù hợp'**
  String get noMatchingCollection;

  /// No description provided for @collectionSearchEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thử từ khóa khác hoặc xóa tìm kiếm hiện tại.'**
  String get collectionSearchEmptyMessage;

  /// No description provided for @openCollection.
  ///
  /// In vi, this message translates to:
  /// **'Mở bộ sưu tập {name}'**
  String openCollection(String name);

  /// No description provided for @notebookCollectionUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập này không còn khả dụng.'**
  String get notebookCollectionUnavailable;

  /// No description provided for @notebookSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm Kanji, Kana hoặc nghĩa…'**
  String get notebookSearchHint;

  /// No description provided for @savedWords.
  ///
  /// In vi, this message translates to:
  /// **'Từ đã lưu'**
  String get savedWords;

  /// No description provided for @savedItemCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} mục đã lưu'**
  String savedItemCount(int count);

  /// No description provided for @personalCollectionCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} danh sách cá nhân'**
  String personalCollectionCount(int count);

  /// No description provided for @openWordDetail.
  ///
  /// In vi, this message translates to:
  /// **'Mở chi tiết từ {term}'**
  String openWordDetail(String term);

  /// No description provided for @removeFromNotebook.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khỏi Sổ từ'**
  String get removeFromNotebook;

  /// No description provided for @detail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get detail;

  /// No description provided for @personalWord.
  ///
  /// In vi, this message translates to:
  /// **'Từ cá nhân'**
  String get personalWord;

  /// No description provided for @savedItem.
  ///
  /// In vi, this message translates to:
  /// **'Mục đã lưu'**
  String get savedItem;

  /// No description provided for @personalNoteLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú cá nhân'**
  String get personalNoteLabel;

  /// No description provided for @addedToNotebookLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm vào Sổ từ'**
  String get addedToNotebookLabel;

  /// No description provided for @notebookEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sổ từ của bạn đang trống'**
  String get notebookEmptyTitle;

  /// No description provided for @notebookEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tạo danh sách đầu tiên để lưu từ vựng.'**
  String get notebookEmptyMessage;

  /// No description provided for @noMatchingWord.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy từ phù hợp'**
  String get noMatchingWord;

  /// No description provided for @collectionHasNoWords.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách chưa có từ'**
  String get collectionHasNoWords;

  /// No description provided for @notebookSearchEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thử từ khóa khác hoặc xóa tìm kiếm hiện tại.'**
  String get notebookSearchEmptyMessage;

  /// No description provided for @notebookCollectionEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ đầu tiên để bắt đầu ôn tập trong danh sách này.'**
  String get notebookCollectionEmptyMessage;

  /// No description provided for @notebookLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải Sổ từ'**
  String get notebookLoadFailed;

  /// No description provided for @checkConnectionShort.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối rồi thử lại.'**
  String get checkConnectionShort;

  /// No description provided for @loadingRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải lộ trình'**
  String get loadingRoadmap;

  /// No description provided for @roadmapSummary.
  ///
  /// In vi, this message translates to:
  /// **'{chapters} chương • {lessons} bài học'**
  String roadmapSummary(int chapters, int lessons);

  /// No description provided for @jlptRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Lộ trình JLPT{level}'**
  String jlptRoadmap(String level);

  /// No description provided for @jlptProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ JLPT{level}'**
  String jlptProgress(String level);

  /// No description provided for @fiveSkillBreakdown.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết phân bổ 5 kỹ năng'**
  String get fiveSkillBreakdown;

  /// No description provided for @lesson.
  ///
  /// In vi, this message translates to:
  /// **'Bài học'**
  String get lesson;

  /// No description provided for @completeLesson.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành bài học'**
  String get completeLesson;

  /// No description provided for @lessonNumber.
  ///
  /// In vi, this message translates to:
  /// **'Bài {number}'**
  String lessonNumber(int number);

  /// No description provided for @loadingContent.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải nội dung'**
  String get loadingContent;

  /// No description provided for @chapterLessonSummary.
  ///
  /// In vi, this message translates to:
  /// **'Chương {chapter} • {category} {level}'**
  String chapterLessonSummary(int chapter, String category, String level);

  /// No description provided for @dayShort.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày'**
  String dayShort(int count);

  /// No description provided for @mainLearningSections.
  ///
  /// In vi, this message translates to:
  /// **'Các phần học chính'**
  String get mainLearningSections;

  /// No description provided for @viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get viewAll;

  /// No description provided for @roadmap.
  ///
  /// In vi, this message translates to:
  /// **'Lộ trình'**
  String get roadmap;

  /// No description provided for @lessonPlural.
  ///
  /// In vi, this message translates to:
  /// **'Bài học'**
  String get lessonPlural;

  /// No description provided for @overallProgressUpper.
  ///
  /// In vi, this message translates to:
  /// **'TIẾN ĐỘ TỔNG'**
  String get overallProgressUpper;

  /// No description provided for @overallProgressSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ tổng {percentage} phần trăm'**
  String overallProgressSemantics(int percentage);

  /// No description provided for @completedLessons.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành {completed}/{total} bài học'**
  String completedLessons(int completed, int total);

  /// No description provided for @studyStreak.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi học: {days} ngày 🔥'**
  String studyStreak(int days);

  /// No description provided for @continueRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục lộ trình'**
  String get continueRoadmap;

  /// No description provided for @inProgressUpper.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG HỌC DỞ'**
  String get inProgressUpper;

  /// No description provided for @chapterAndLesson.
  ///
  /// In vi, this message translates to:
  /// **'Chương {chapter} • Bài {lesson}'**
  String chapterAndLesson(int chapter, int lesson);

  /// No description provided for @durationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String durationMinutes(int minutes);

  /// No description provided for @continueLearning.
  ///
  /// In vi, this message translates to:
  /// **'Học tiếp'**
  String get continueLearning;

  /// No description provided for @learningLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải nội dung học tập'**
  String get learningLoadFailed;

  /// No description provided for @continueStudy.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục học'**
  String get continueStudy;

  /// No description provided for @viewDetailedRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Xem lộ trình chi tiết'**
  String get viewDetailedRoadmap;

  /// No description provided for @targetLevel.
  ///
  /// In vi, this message translates to:
  /// **'Cấp độ mục tiêu: {level}'**
  String targetLevel(String level);

  /// No description provided for @courseOverallProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiến độ toàn khóa'**
  String get courseOverallProgress;

  /// No description provided for @courseProgressSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiến độ toàn khóa {percentage} phần trăm'**
  String courseProgressSemantics(int percentage);

  /// No description provided for @completedOverallLessons.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành {completed}/{total} bài học tổng thể'**
  String completedOverallLessons(int completed, int total);

  /// No description provided for @expectedExam.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ thi dự kiến: {date}'**
  String expectedExam(String date);

  /// No description provided for @skillProgressDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết tiến độ kỹ năng'**
  String get skillProgressDetail;

  /// No description provided for @skillCount.
  ///
  /// In vi, this message translates to:
  /// **'{count}/5 kỹ năng'**
  String skillCount(int count);

  /// No description provided for @progressSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ {category} {percentage} phần trăm'**
  String progressSemantics(String category, int percentage);

  /// No description provided for @overallProgressTitle.
  ///
  /// In vi, this message translates to:
  /// **'TIẾN ĐỘ TỔNG THỂ'**
  String get overallProgressTitle;

  /// No description provided for @onTrack.
  ///
  /// In vi, this message translates to:
  /// **'Đang đúng tiến độ'**
  String get onTrack;

  /// No description provided for @completedChapters.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành {completed}/{total} chương học'**
  String completedChapters(int completed, int total);

  /// No description provided for @achievedLessons.
  ///
  /// In vi, this message translates to:
  /// **'{completed} / {total} bài đã đạt'**
  String achievedLessons(int completed, int total);

  /// No description provided for @reviewResults.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại kết quả'**
  String get reviewResults;

  /// No description provided for @continueLessonNineteen.
  ///
  /// In vi, this message translates to:
  /// **'Học tiếp: Bài 19 – 〜たり〜たりする'**
  String get continueLessonNineteen;

  /// No description provided for @chapterNumberUpper.
  ///
  /// In vi, this message translates to:
  /// **'CHƯƠNG {number}'**
  String chapterNumberUpper(int number);

  /// No description provided for @lessonRange.
  ///
  /// In vi, this message translates to:
  /// **'• Bài {first} – Bài {last}'**
  String lessonRange(int first, int last);

  /// No description provided for @skillsAchievedUpper.
  ///
  /// In vi, this message translates to:
  /// **'KỸ NĂNG ĐẠT CHUẨN:'**
  String get skillsAchievedUpper;

  /// No description provided for @fiveSkillProgressUpper.
  ///
  /// In vi, this message translates to:
  /// **'TIẾN ĐỘ 5 KỸ NĂNG:'**
  String get fiveSkillProgressUpper;

  /// No description provided for @lessonCountUpper.
  ///
  /// In vi, this message translates to:
  /// **'{completed}/{total} BÀI HỌC'**
  String lessonCountUpper(int completed, int total);

  /// No description provided for @statusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get statusCompleted;

  /// No description provided for @statusLearning.
  ///
  /// In vi, this message translates to:
  /// **'Đang học'**
  String get statusLearning;

  /// No description provided for @statusReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get statusReady;

  /// No description provided for @statusNotStarted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa bắt đầu'**
  String get statusNotStarted;

  /// No description provided for @lessonContentCount.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung bài học ({count} phần)'**
  String lessonContentCount(int count);

  /// No description provided for @totalDuration.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thời lượng ~{minutes}m'**
  String totalDuration(int minutes);

  /// No description provided for @focusVocabulary.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng trọng tâm trong bài'**
  String get focusVocabulary;

  /// No description provided for @vocabularyCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} từ vựng'**
  String vocabularyCount(int count);

  /// No description provided for @relatedGrammarShort.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ pháp liên quan'**
  String get relatedGrammarShort;

  /// No description provided for @continueLessonProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục bài học ({percentage}%)'**
  String continueLessonProgress(int percentage);

  /// No description provided for @startLesson.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu bài học'**
  String get startLesson;

  /// No description provided for @focusLabel.
  ///
  /// In vi, this message translates to:
  /// **'Trọng tâm:'**
  String get focusLabel;

  /// No description provided for @partProgress.
  ///
  /// In vi, this message translates to:
  /// **'Phần {current} / {total}'**
  String partProgress(int current, int total);

  /// No description provided for @lessonObjective.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu bài học'**
  String get lessonObjective;

  /// No description provided for @streakMotivation.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {days} ngày bền bỉ'**
  String streakMotivation(int days);

  /// No description provided for @keepStreakMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành bài này để giữ lửa streak!'**
  String get keepStreakMessage;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get done;

  /// No description provided for @videoLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải video bài giảng'**
  String get videoLoadFailed;

  /// No description provided for @watchingInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem dở'**
  String get watchingInProgress;

  /// No description provided for @hdLecture.
  ///
  /// In vi, this message translates to:
  /// **'Bài giảng HD'**
  String get hdLecture;

  /// No description provided for @pauseVideo.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng video'**
  String get pauseVideo;

  /// No description provided for @resumeVideoFrom.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục video từ {time}'**
  String resumeVideoFrom(String time);

  /// No description provided for @articleFallbackMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn vẫn có thể học tiếp bằng phần tóm tắt bên dưới.'**
  String get articleFallbackMessage;

  /// No description provided for @viewArticle.
  ///
  /// In vi, this message translates to:
  /// **'Xem bản chữ'**
  String get viewArticle;

  /// No description provided for @contentTab.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get contentTab;

  /// No description provided for @notesTab.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú ({count})'**
  String notesTab(int count);

  /// No description provided for @vocabularyTab.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng ({count})'**
  String vocabularyTab(int count);

  /// No description provided for @coreStructure.
  ///
  /// In vi, this message translates to:
  /// **'Cấu trúc cốt lõi'**
  String get coreStructure;

  /// No description provided for @usageAndContext.
  ///
  /// In vi, this message translates to:
  /// **'Cách sử dụng & Ngữ cảnh'**
  String get usageAndContext;

  /// No description provided for @practicalExamplesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Các ví dụ thực tế tiêu biểu'**
  String get practicalExamplesTitle;

  /// No description provided for @importantGrammarNotes.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý ngữ pháp quan trọng'**
  String get importantGrammarNotes;

  /// No description provided for @importantVocabulary.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng quan trọng trong bài'**
  String get importantVocabulary;

  /// No description provided for @wordsAppearing.
  ///
  /// In vi, this message translates to:
  /// **'{count} từ xuất hiện'**
  String wordsAppearing(int count);

  /// No description provided for @topicUpper.
  ///
  /// In vi, this message translates to:
  /// **'CHUYÊN ĐỀ {category}'**
  String topicUpper(String category);

  /// No description provided for @topicSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Liệt kê hành động và trạng thái tiêu biểu'**
  String get topicSubtitle;

  /// No description provided for @openLessonVideo.
  ///
  /// In vi, this message translates to:
  /// **'Mở video bài học'**
  String get openLessonVideo;

  /// No description provided for @excellentCompletion.
  ///
  /// In vi, this message translates to:
  /// **'Xuất sắc hoàn thành'**
  String get excellentCompletion;

  /// No description provided for @completionCongratulations.
  ///
  /// In vi, this message translates to:
  /// **'Chúc mừng bạn đã hoàn thành!'**
  String get completionCongratulations;

  /// No description provided for @lessonUpper.
  ///
  /// In vi, this message translates to:
  /// **'BÀI {number}'**
  String lessonUpper(int number);

  /// No description provided for @streakConsecutive.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi học tập: {days} ngày liên tiếp'**
  String streakConsecutive(int days);

  /// No description provided for @masteredContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung bạn đã nắm vững'**
  String get masteredContent;

  /// No description provided for @masteredItemCount.
  ///
  /// In vi, this message translates to:
  /// **'{count}/{count} mục'**
  String masteredItemCount(int count);

  /// No description provided for @nextLessonAction.
  ///
  /// In vi, this message translates to:
  /// **'Học bài tiếp theo (Bài {number})'**
  String nextLessonAction(int number);

  /// No description provided for @backToLevelRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại Lộ trình học {level}'**
  String backToLevelRoadmap(String level);

  /// No description provided for @nextLessonInRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Bài học tiếp theo trong lộ trình'**
  String get nextLessonInRoadmap;

  /// No description provided for @lockedContentUpper.
  ///
  /// In vi, this message translates to:
  /// **'NỘI DUNG CÓ KHÓA TIẾN TRÌNH'**
  String get lockedContentUpper;

  /// No description provided for @lessonLockedDefault.
  ///
  /// In vi, this message translates to:
  /// **'Bài học này chưa được mở.'**
  String get lessonLockedDefault;

  /// No description provided for @unlockConditionUpper.
  ///
  /// In vi, this message translates to:
  /// **'ĐIỀU KIỆN MỞ KHÓA'**
  String get unlockConditionUpper;

  /// No description provided for @prerequisiteProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ: {completed}/{total} phần'**
  String prerequisiteProgress(int completed, int total);

  /// No description provided for @remainingMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Còn ~{minutes} phút'**
  String remainingMinutes(int minutes);

  /// No description provided for @previewLesson.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước nội dung Bài {number}'**
  String previewLesson(int number);

  /// No description provided for @lessonPartsDuration.
  ///
  /// In vi, this message translates to:
  /// **'{parts} phần học • ~{minutes} phút'**
  String lessonPartsDuration(int parts, int minutes);

  /// No description provided for @continuePrerequisite.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục Bài {number} (còn {remaining}%)'**
  String continuePrerequisite(int number, int remaining);

  /// No description provided for @backToLearningRoadmap.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại lộ trình học tập'**
  String get backToLearningRoadmap;

  /// No description provided for @lessonLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải bài học'**
  String get lessonLoadFailed;

  /// No description provided for @lessonProgressTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ bài học'**
  String get lessonProgressTitle;

  /// No description provided for @completedUpper.
  ///
  /// In vi, this message translates to:
  /// **'100% HOÀN THÀNH'**
  String get completedUpper;

  /// No description provided for @learningProgressValue.
  ///
  /// In vi, this message translates to:
  /// **'{percentage}% • Đang học'**
  String learningProgressValue(int percentage);

  /// No description provided for @notebookShort.
  ///
  /// In vi, this message translates to:
  /// **'Sổ từ'**
  String get notebookShort;

  /// No description provided for @processingSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get processingSemantics;

  /// No description provided for @jlptLevelSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Trình độ JLPT {level}'**
  String jlptLevelSemantics(String level);

  /// No description provided for @vocabularyLoadMoreFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thêm từ vựng. Vui lòng thử lại.'**
  String get vocabularyLoadMoreFailed;

  /// No description provided for @fixtureDefaultNotebookName.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu từ bài học'**
  String get fixtureDefaultNotebookName;

  /// No description provided for @notebookListsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách Sổ từ.'**
  String get notebookListsLoadFailed;

  /// No description provided for @vocabularySaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu từ vựng vào Sổ từ.'**
  String get vocabularySaveFailed;

  /// No description provided for @kanjiLoadMoreFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thêm Kanji. Vui lòng thử lại.'**
  String get kanjiLoadMoreFailed;

  /// No description provided for @kanjiFixtureNotebookName.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu từ bài học'**
  String get kanjiFixtureNotebookName;

  /// No description provided for @kanjiSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu Kanji vào Sổ từ.'**
  String get kanjiSaveFailed;

  /// No description provided for @grammarLoadMoreFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thêm ngữ pháp. Vui lòng thử lại.'**
  String get grammarLoadMoreFailed;

  /// No description provided for @notebookEntriesLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải nội dung danh sách. Vui lòng thử lại.'**
  String get notebookEntriesLoadFailed;

  /// No description provided for @notebookCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo danh sách. Vui lòng thử lại.'**
  String get notebookCreateFailed;

  /// No description provided for @notebookAddFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thêm từ vào Sổ từ. Vui lòng thử lại.'**
  String get notebookAddFailed;

  /// No description provided for @notebookRemoveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xóa mục khỏi Sổ từ. Vui lòng thử lại.'**
  String get notebookRemoveFailed;

  /// No description provided for @notebookLocalRemoveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật mục đã lưu trên thiết bị.'**
  String get notebookLocalRemoveFailed;

  /// No description provided for @notebookLocalRestoreUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu đã lưu trên thiết bị tạm thời không khả dụng. Dữ liệu trực tuyến vẫn được giữ nguyên.'**
  String get notebookLocalRestoreUnavailable;

  /// No description provided for @selectLiveCollectionForManualEntry.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chọn một danh sách có thể đồng bộ để thêm mục thủ công.'**
  String get selectLiveCollectionForManualEntry;

  /// No description provided for @notebookKanjiLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kanji'**
  String get notebookKanjiLabel;

  /// No description provided for @wordAndMeaningRequired.
  ///
  /// In vi, this message translates to:
  /// **'Từ tiếng Nhật và nghĩa tiếng Việt là bắt buộc.'**
  String get wordAndMeaningRequired;

  /// No description provided for @grammarDetailSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mở chi tiết ngữ pháp {title}'**
  String grammarDetailSemantics(String title);

  /// No description provided for @kanjiDetailSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mở chi tiết Kanji {character}'**
  String kanjiDetailSemantics(String character);

  /// No description provided for @lessonDetailsComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết bài học đang được hoàn thiện'**
  String get lessonDetailsComingSoon;

  /// No description provided for @examDateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ thi {date}'**
  String examDateLabel(String date);

  /// No description provided for @mockDurationStatus.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút • {status}'**
  String mockDurationStatus(int minutes, String status);

  /// No description provided for @mockScoreReading.
  ///
  /// In vi, this message translates to:
  /// **'{score} / {total} • Đọc hiểu: {percentage}%'**
  String mockScoreReading(int score, int total, int percentage);

  /// No description provided for @successSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get successSemantics;

  /// No description provided for @skillVocabulary.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng'**
  String get skillVocabulary;

  /// No description provided for @skillKanji.
  ///
  /// In vi, this message translates to:
  /// **'Kanji'**
  String get skillKanji;

  /// No description provided for @skillGrammar.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ pháp'**
  String get skillGrammar;

  /// No description provided for @skillReading.
  ///
  /// In vi, this message translates to:
  /// **'Đọc hiểu'**
  String get skillReading;

  /// No description provided for @skillListening.
  ///
  /// In vi, this message translates to:
  /// **'Nghe hiểu'**
  String get skillListening;

  /// No description provided for @unitWords.
  ///
  /// In vi, this message translates to:
  /// **'từ'**
  String get unitWords;

  /// No description provided for @unitCharacters.
  ///
  /// In vi, this message translates to:
  /// **'chữ'**
  String get unitCharacters;

  /// No description provided for @unitLessons.
  ///
  /// In vi, this message translates to:
  /// **'bài'**
  String get unitLessons;

  /// No description provided for @writing.
  ///
  /// In vi, this message translates to:
  /// **'Viết'**
  String get writing;

  /// No description provided for @mockTestName.
  ///
  /// In vi, this message translates to:
  /// **'Đề thi thử {level} #{number}'**
  String mockTestName(String level, String number);

  /// No description provided for @levelProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ {level}'**
  String levelProgress(String level);

  /// No description provided for @streakMetric.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi học'**
  String get streakMetric;

  /// No description provided for @authErrorEmailNotVerified.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng xác thực email trước khi đăng nhập.'**
  String get authErrorEmailNotVerified;

  /// No description provided for @profileLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải hồ sơ...'**
  String get profileLoading;

  /// No description provided for @profileLoadFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải hồ sơ'**
  String get profileLoadFailedTitle;

  /// No description provided for @profileLoadFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dữ liệu hồ sơ lúc này. Vui lòng thử lại.'**
  String get profileLoadFailedMessage;

  /// No description provided for @profileEdit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa hồ sơ'**
  String get profileEdit;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật họ và tên hiển thị của bạn.'**
  String get profileEditSubtitle;

  /// No description provided for @profileProgressSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem lộ trình và tiến độ JLPT của bạn.'**
  String get profileProgressSubtitle;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý tài khoản, bảo mật và thông báo.'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileServicesSection.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get profileServicesSection;

  /// No description provided for @configure.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập'**
  String get configure;

  /// No description provided for @firstName.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In vi, this message translates to:
  /// **'Họ'**
  String get lastName;

  /// No description provided for @firstNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Minh Anh'**
  String get firstNameHint;

  /// No description provided for @lastNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nguyễn'**
  String get lastNameHint;

  /// No description provided for @validationFirstNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên.'**
  String get validationFirstNameRequired;

  /// No description provided for @validationLastNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ.'**
  String get validationLastNameRequired;

  /// No description provided for @saveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get saveChanges;

  /// No description provided for @savingChanges.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get savingChanges;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ đã được cập nhật.'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật hồ sơ. Vui lòng thử lại.'**
  String get profileUpdateFailed;

  /// No description provided for @learningProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ học tập'**
  String get learningProfile;

  /// No description provided for @dailyStudyGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu mỗi ngày'**
  String get dailyStudyGoal;

  /// No description provided for @notConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thiết lập'**
  String get notConfigured;

  /// No description provided for @emailVerification.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực email'**
  String get emailVerification;

  /// No description provided for @verified.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác thực'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác thực'**
  String get unverified;

  /// No description provided for @editAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get editAvatar;

  /// No description provided for @chooseAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thiết bị'**
  String get chooseAvatar;

  /// No description provided for @confirmAvatarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ảnh đại diện?'**
  String get confirmAvatarTitle;

  /// No description provided for @confirmAvatarMessage.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh JPEG, PNG hoặc WEBP sẽ được tải lên hồ sơ của bạn.'**
  String get confirmAvatarMessage;

  /// No description provided for @confirmUpload.
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh lên'**
  String get confirmUpload;

  /// No description provided for @uploadingAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ảnh...'**
  String get uploadingAvatar;

  /// No description provided for @avatarUploadSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đại diện đã được cập nhật.'**
  String get avatarUploadSuccess;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật ảnh đại diện. Vui lòng thử lại.'**
  String get avatarUploadFailed;

  /// No description provided for @avatarUnsupportedType.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WEBP.'**
  String get avatarUnsupportedType;

  /// No description provided for @avatarTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đại diện phải nhỏ hơn hoặc bằng 5MB.'**
  String get avatarTooLarge;

  /// No description provided for @avatarPickerFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở thư viện ảnh trên thiết bị này.'**
  String get avatarPickerFailed;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt thông báo'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các tùy chọn khả dụng sẽ được đồng bộ với tài khoản của bạn.'**
  String get notificationSettingsSubtitle;

  /// No description provided for @emailNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo qua email'**
  String get emailNotifications;

  /// No description provided for @emailNotificationsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhận cập nhật học tập qua email.'**
  String get emailNotificationsDescription;

  /// No description provided for @systemNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo trong ứng dụng'**
  String get systemNotifications;

  /// No description provided for @systemNotificationsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo hệ thống của RikiPath.'**
  String get systemNotificationsDescription;

  /// No description provided for @notificationUpdateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt thông báo đã được cập nhật.'**
  String get notificationUpdateSuccess;

  /// No description provided for @notificationUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật cài đặt thông báo. Thay đổi chưa được lưu.'**
  String get notificationUpdateFailed;

  /// No description provided for @jlptGoalSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu JLPT'**
  String get jlptGoalSettings;

  /// No description provided for @jlptGoalSettingsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem mục tiêu JLPT và thời gian học mỗi ngày.'**
  String get jlptGoalSettingsSubtitle;

  /// No description provided for @jlptGoalMappingUnavailableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể đổi mục tiêu JLPT'**
  String get jlptGoalMappingUnavailableTitle;

  /// No description provided for @jlptGoalMappingUnavailableMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể đồng bộ mục tiêu JLPT lúc này. Lựa chọn hiện tại của bạn vẫn được giữ nguyên.'**
  String get jlptGoalMappingUnavailableMessage;

  /// No description provided for @currentJlptGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu hiện tại'**
  String get currentJlptGoal;

  /// No description provided for @currentDailyStudyTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian học hiện tại'**
  String get currentDailyStudyTime;

  /// No description provided for @profileErrorUnauthorized.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.'**
  String get profileErrorUnauthorized;

  /// No description provided for @profileErrorForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này không có quyền truy cập hồ sơ học viên.'**
  String get profileErrorForbidden;

  /// No description provided for @profileErrorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.'**
  String get profileErrorNetwork;

  /// No description provided for @profileErrorValidation.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu hồ sơ chưa hợp lệ. Vui lòng kiểm tra lại.'**
  String get profileErrorValidation;

  /// No description provided for @profileErrorServer.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa thể xử lý yêu cầu hồ sơ. Vui lòng thử lại sau.'**
  String get profileErrorServer;

  /// No description provided for @profileErrorUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi khi xử lý hồ sơ. Vui lòng thử lại.'**
  String get profileErrorUnknown;

  /// No description provided for @accountSecuritySection.
  ///
  /// In vi, this message translates to:
  /// **'BẢO MẬT'**
  String get accountSecuritySection;

  /// No description provided for @accountOptionsSection.
  ///
  /// In vi, this message translates to:
  /// **'TÙY CHỌN'**
  String get accountOptionsSection;

  /// No description provided for @accountSessionSection.
  ///
  /// In vi, this message translates to:
  /// **'PHIÊN'**
  String get accountSessionSection;

  /// No description provided for @accountVerifiedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã được xác thực'**
  String get accountVerifiedTitle;

  /// No description provided for @accountUnverifiedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản chưa được xác thực'**
  String get accountUnverifiedTitle;

  /// No description provided for @logoutConfirmationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi RikiPath?'**
  String get logoutConfirmationTitle;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ cần đăng nhập lại để tiếp tục hành trình học trên thiết bị này.'**
  String get logoutConfirmationMessage;

  /// No description provided for @profileNameSection.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN HIỂN THỊ'**
  String get profileNameSection;

  /// No description provided for @notificationPreferencesSection.
  ///
  /// In vi, this message translates to:
  /// **'TÙY CHỌN THÔNG BÁO'**
  String get notificationPreferencesSection;

  /// No description provided for @currentEmailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email hiện tại'**
  String get currentEmailLabel;

  /// No description provided for @passwordRequirementsTitle.
  ///
  /// In vi, this message translates to:
  /// **'YÊU CẦU MẬT KHẨU'**
  String get passwordRequirementsTitle;

  /// No description provided for @passwordMinimumRequirement.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới có ít nhất 6 ký tự'**
  String get passwordMinimumRequirement;

  /// No description provided for @jlptSelectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'CHỌN MỤC TIÊU JLPT'**
  String get jlptSelectionTitle;

  /// No description provided for @dailyStudySelectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'THỜI GIAN HỌC MỖI NGÀY'**
  String get dailyStudySelectionTitle;

  /// No description provided for @jlptSelectionSafeHint.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn được lưu trên thiết bị này và bạn có thể thay đổi sau.'**
  String get jlptSelectionSafeHint;

  /// No description provided for @profileConsultationSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá gói tư vấn và lịch hẹn của bạn.'**
  String get profileConsultationSubtitle;

  /// No description provided for @savedFromLessons.
  ///
  /// In vi, this message translates to:
  /// **'Từ đã lưu trong bài học'**
  String get savedFromLessons;

  /// No description provided for @localJlptPreferenceSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu mục tiêu học trên thiết bị'**
  String get localJlptPreferenceSaved;

  /// No description provided for @dailyReviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập hôm nay'**
  String get dailyReviewTitle;

  /// No description provided for @reviewLoadingTitle.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang chuẩn bị thẻ ôn tập...'**
  String get reviewLoadingTitle;

  /// No description provided for @reviewProgress.
  ///
  /// In vi, this message translates to:
  /// **'{current} / {total} thẻ'**
  String reviewProgress(int current, int total);

  /// No description provided for @reviewRecallPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Bạn còn nhớ nội dung này không?'**
  String get reviewRecallPrompt;

  /// No description provided for @revealAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Hiện đáp án'**
  String get revealAnswer;

  /// No description provided for @reviewAgain.
  ///
  /// In vi, this message translates to:
  /// **'Học lại'**
  String get reviewAgain;

  /// No description provided for @reviewHard.
  ///
  /// In vi, this message translates to:
  /// **'Khó'**
  String get reviewHard;

  /// No description provided for @reviewGood.
  ///
  /// In vi, this message translates to:
  /// **'Tốt'**
  String get reviewGood;

  /// No description provided for @reviewEasy.
  ///
  /// In vi, this message translates to:
  /// **'Dễ'**
  String get reviewEasy;

  /// No description provided for @reviewCompleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành phiên ôn tập'**
  String get reviewCompleteTitle;

  /// No description provided for @reviewCompleteCount.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ôn {count} thẻ trong phiên này.'**
  String reviewCompleteCount(int count);

  /// No description provided for @reviewResponseCount.
  ///
  /// In vi, this message translates to:
  /// **'{label}: {count}'**
  String reviewResponseCount(String label, int count);

  /// No description provided for @reviewAgainAction.
  ///
  /// In vi, this message translates to:
  /// **'Ôn lại phiên này'**
  String get reviewAgainAction;

  /// No description provided for @backToPractice.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại Luyện tập'**
  String get backToPractice;

  /// No description provided for @reviewQueueEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay chưa có thẻ cần ôn.'**
  String get reviewQueueEmpty;

  /// No description provided for @reviewLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải phiên ôn tập'**
  String get reviewLoadFailed;

  /// No description provided for @reviewDueCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thẻ đang chờ bạn ôn lại'**
  String reviewDueCount(int count);

  /// No description provided for @mockLoadingTitle.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang chuẩn bị đề thi...'**
  String get mockLoadingTitle;

  /// No description provided for @mockLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải đề thi thử.'**
  String get mockLoadFailed;

  /// No description provided for @mockTestUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Đề thi thử này hiện không khả dụng.'**
  String get mockTestUnavailable;

  /// No description provided for @leaveMockTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi bài thi?'**
  String get leaveMockTitle;

  /// No description provided for @leaveMockMessage.
  ///
  /// In vi, this message translates to:
  /// **'Các đáp án trong phiên hiện tại vẫn được giữ khi bạn quay lại.'**
  String get leaveMockMessage;

  /// No description provided for @continueAction.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục làm bài'**
  String get continueAction;

  /// No description provided for @leaveAction.
  ///
  /// In vi, this message translates to:
  /// **'Rời bài thi'**
  String get leaveAction;

  /// No description provided for @submitMockTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài thi thử?'**
  String get submitMockTitle;

  /// No description provided for @submitMockMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể nộp dù vẫn còn câu chưa trả lời. Điểm được tính cục bộ trên thiết bị.'**
  String get submitMockMessage;

  /// No description provided for @submitAction.
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài'**
  String get submitAction;

  /// No description provided for @mockMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian: {minutes} phút'**
  String mockMinutes(int minutes);

  /// No description provided for @mockQuestionCount.
  ///
  /// In vi, this message translates to:
  /// **'Số câu: {count}'**
  String mockQuestionCount(int count);

  /// No description provided for @mockLocalScoringNotice.
  ///
  /// In vi, this message translates to:
  /// **'Đề luyện tập được chấm trên thiết bị và không phải kết quả JLPT chính thức.'**
  String get mockLocalScoringNotice;

  /// No description provided for @startMockTest.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu làm bài'**
  String get startMockTest;

  /// No description provided for @questionProgress.
  ///
  /// In vi, this message translates to:
  /// **'Câu {current} / {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @previousQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Câu trước'**
  String get previousQuestion;

  /// No description provided for @nextQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Câu tiếp'**
  String get nextQuestion;

  /// No description provided for @mockResultTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả thi thử'**
  String get mockResultTitle;

  /// No description provided for @mockResultUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kết quả cho đề thi này.'**
  String get mockResultUnavailable;

  /// No description provided for @mockCorrectCount.
  ///
  /// In vi, this message translates to:
  /// **'Đúng {correct} / {total} câu'**
  String mockCorrectCount(int correct, int total);

  /// No description provided for @mockLocalResultNotice.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả này dùng để luyện tập và không phải điểm JLPT chính thức.'**
  String get mockLocalResultNotice;

  /// No description provided for @sectionBreakdown.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả theo phần'**
  String get sectionBreakdown;

  /// No description provided for @mockSectionResult.
  ///
  /// In vi, this message translates to:
  /// **'{correct}/{total} đúng • {percentage}%'**
  String mockSectionResult(int correct, int total, int percentage);

  /// No description provided for @detailedReview.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết đáp án'**
  String get detailedReview;

  /// No description provided for @retakeMockTest.
  ///
  /// In vi, this message translates to:
  /// **'Làm lại đề'**
  String get retakeMockTest;

  /// No description provided for @questionNumber.
  ///
  /// In vi, this message translates to:
  /// **'Câu {number}'**
  String questionNumber(int number);

  /// No description provided for @selectedAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chọn: {answer}'**
  String selectedAnswer(String answer);

  /// No description provided for @correctAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Đáp án đúng: {answer}'**
  String correctAnswer(String answer);

  /// No description provided for @notAnswered.
  ///
  /// In vi, this message translates to:
  /// **'Chưa trả lời'**
  String get notAnswered;

  /// No description provided for @practiceLoadingTitle.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang chuẩn bị nội dung luyện tập...'**
  String get practiceLoadingTitle;

  /// No description provided for @practiceJourneyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện tập theo nhịp của bạn'**
  String get practiceJourneyTitle;

  /// No description provided for @practiceJourneySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ôn lại kiến thức, thử sức với đề JLPT và theo dõi từng bước tiến bộ.'**
  String get practiceJourneySubtitle;

  /// No description provided for @mockSummary.
  ///
  /// In vi, this message translates to:
  /// **'{level} • {minutes} phút • {count} câu'**
  String mockSummary(String level, int minutes, int count);

  /// No description provided for @mockInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang làm {answered}/{total} câu'**
  String mockInProgress(int answered, int total);

  /// No description provided for @mockCompletedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành • {percentage}%'**
  String mockCompletedStatus(int percentage);

  /// No description provided for @additionalPractice.
  ///
  /// In vi, this message translates to:
  /// **'Luyện tập bổ sung'**
  String get additionalPractice;

  /// No description provided for @aiWritingPractice.
  ///
  /// In vi, this message translates to:
  /// **'Luyện viết cùng AI'**
  String get aiWritingPractice;

  /// No description provided for @practiceAnswerLabel.
  ///
  /// In vi, this message translates to:
  /// **'Câu trả lời luyện tập'**
  String get practiceAnswerLabel;

  /// No description provided for @gradePractice.
  ///
  /// In vi, this message translates to:
  /// **'Chấm bài luyện tập'**
  String get gradePractice;

  /// No description provided for @gradingPractice.
  ///
  /// In vi, this message translates to:
  /// **'Đang chấm...'**
  String get gradingPractice;

  /// No description provided for @aiGradingResult.
  ///
  /// In vi, this message translates to:
  /// **'Điểm {score}/100 • {feedback}'**
  String aiGradingResult(int score, String feedback);

  /// No description provided for @mentorConsultation.
  ///
  /// In vi, this message translates to:
  /// **'Tư vấn cùng Mentor'**
  String get mentorConsultation;

  /// No description provided for @openDemoBooking.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước lịch tư vấn'**
  String get openDemoBooking;

  /// No description provided for @confirmDemoBooking.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xem trước'**
  String get confirmDemoBooking;

  /// No description provided for @demoBookingConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã hoàn tất phần xem trước lịch tư vấn.'**
  String get demoBookingConfirmed;

  /// No description provided for @practiceLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải nội dung luyện tập'**
  String get practiceLoadFailed;

  /// No description provided for @learningAnalyticsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ học tập'**
  String get learningAnalyticsTitle;

  /// No description provided for @analyticsLoadingTitle.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang tổng hợp tiến độ của bạn...'**
  String get analyticsLoadingTitle;

  /// No description provided for @analyticsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu học tập để hiển thị.'**
  String get analyticsEmpty;

  /// No description provided for @studyStreakLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi ngày học'**
  String get studyStreakLabel;

  /// No description provided for @streakDaysValue.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày'**
  String streakDaysValue(int days);

  /// No description provided for @completedLessonsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bài học đã hoàn thành'**
  String get completedLessonsLabel;

  /// No description provided for @analyticsCompletedLessons.
  ///
  /// In vi, this message translates to:
  /// **'{completed} / {total} bài'**
  String analyticsCompletedLessons(int completed, int total);

  /// No description provided for @skillBreakdown.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ theo kỹ năng'**
  String get skillBreakdown;

  /// No description provided for @analyticsSkillsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu kỹ năng.'**
  String get analyticsSkillsEmpty;

  /// No description provided for @analyticsSectionUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Phần dữ liệu này tạm thời chưa tải được.'**
  String get analyticsSectionUnavailable;

  /// No description provided for @analyticsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải tiến độ học tập'**
  String get analyticsLoadFailed;

  /// No description provided for @markAllNotificationsRead.
  ///
  /// In vi, this message translates to:
  /// **'Đọc tất cả'**
  String get markAllNotificationsRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo trong ứng dụng.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải thông báo'**
  String get notificationsLoadFailed;

  /// No description provided for @notebookEntryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ đã lưu'**
  String get notebookEntryTitle;

  /// No description provided for @notebookEntryUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Mục đã lưu này không còn khả dụng.'**
  String get notebookEntryUnavailable;

  /// No description provided for @homeChooseJlptTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn mục tiêu JLPT để bắt đầu'**
  String get homeChooseJlptTitle;

  /// No description provided for @homeChooseJlptDescription.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath sẽ chuẩn bị lộ trình phù hợp sau khi bạn chọn N5, N4 hoặc N3.'**
  String get homeChooseJlptDescription;

  /// No description provided for @homeChooseJlptAction.
  ///
  /// In vi, this message translates to:
  /// **'Chọn mục tiêu'**
  String get homeChooseJlptAction;

  /// No description provided for @homeContinueLearningTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục học'**
  String get homeContinueLearningTitle;

  /// No description provided for @homeCurrentLessonMeta.
  ///
  /// In vi, this message translates to:
  /// **'Bài {lesson} • {minutes} phút'**
  String homeCurrentLessonMeta(int lesson, int minutes);

  /// No description provided for @homeRoadmapProgressTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ lộ trình'**
  String get homeRoadmapProgressTitle;

  /// No description provided for @homeRoadmapProgressDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ bài học được lưu trên thiết bị này.'**
  String get homeRoadmapProgressDescription;

  /// No description provided for @homeRoadmapProgressValue.
  ///
  /// In vi, this message translates to:
  /// **'{completed}/{total} bài • {percentage}%'**
  String homeRoadmapProgressValue(int completed, int total, int percentage);

  /// No description provided for @homeLiveProgressTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê học tập'**
  String get homeLiveProgressTitle;

  /// No description provided for @homeLiveProgressDescription.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu tổng hợp từ tài khoản RikiPath của bạn.'**
  String get homeLiveProgressDescription;

  /// No description provided for @homeViewProgress.
  ///
  /// In vi, this message translates to:
  /// **'Xem tiến độ'**
  String get homeViewProgress;

  /// No description provided for @homeAnalyticsUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê trực tuyến tạm thời chưa tải được.'**
  String get homeAnalyticsUnavailable;

  /// No description provided for @homeReviewDescription.
  ///
  /// In vi, this message translates to:
  /// **'Ôn lại kiến thức theo nhịp học hiện tại của bạn.'**
  String get homeReviewDescription;

  /// No description provided for @homeResumeReview.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục ôn tập'**
  String get homeResumeReview;

  /// No description provided for @homeReviewNow.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập ngay'**
  String get homeReviewNow;

  /// No description provided for @homePracticeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện đề'**
  String get homePracticeTitle;

  /// No description provided for @homeStartPractice.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu luyện tập'**
  String get homeStartPractice;

  /// No description provided for @homeResumeMock.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục đề thi thử'**
  String get homeResumeMock;

  /// No description provided for @homeResumeMockDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bài làm trên thiết bị vẫn đang được lưu.'**
  String get homeResumeMockDescription;

  /// No description provided for @homeRecentMockResult.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả gần đây'**
  String get homeRecentMockResult;

  /// No description provided for @homeRecentMockScore.
  ///
  /// In vi, this message translates to:
  /// **'Đúng {score}/{total} câu • {percentage}%'**
  String homeRecentMockScore(int score, int total, int percentage);

  /// No description provided for @homeViewResult.
  ///
  /// In vi, this message translates to:
  /// **'Xem kết quả'**
  String get homeViewResult;

  /// No description provided for @homeNotebookShortcutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sổ từ cá nhân'**
  String get homeNotebookShortcutTitle;

  /// No description provided for @homeNotebookShortcutDescription.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại từ vựng và nội dung bạn đã lưu.'**
  String get homeNotebookShortcutDescription;

  /// No description provided for @homeSectionUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Phần này tạm thời chưa tải được.'**
  String get homeSectionUnavailable;

  /// No description provided for @homeRefreshSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới thống kê và thông báo'**
  String get homeRefreshSemantics;

  /// No description provided for @commonErrorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối tới RikiPath. Vui lòng kiểm tra mạng và thử lại.'**
  String get commonErrorNetwork;

  /// No description provided for @commonErrorUnauthorized.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'**
  String get commonErrorUnauthorized;

  /// No description provided for @commonErrorForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thao tác này.'**
  String get commonErrorForbidden;

  /// No description provided for @commonErrorNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này không còn khả dụng.'**
  String get commonErrorNotFound;

  /// No description provided for @commonErrorConflict.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.'**
  String get commonErrorConflict;

  /// No description provided for @commonErrorValidation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.'**
  String get commonErrorValidation;

  /// No description provided for @commonErrorServer.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang gặp sự cố. Vui lòng thử lại sau.'**
  String get commonErrorServer;

  /// No description provided for @commonErrorUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể hoàn tất thao tác. Vui lòng thử lại.'**
  String get commonErrorUnknown;

  /// No description provided for @notificationsUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể cập nhật thông báo'**
  String get notificationsUpdateFailed;

  /// No description provided for @notificationsCountUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Số thông báo chưa đọc tạm thời chưa cập nhật.'**
  String get notificationsCountUnavailable;

  /// No description provided for @analyticsSkillScore.
  ///
  /// In vi, this message translates to:
  /// **'{score}% • {attempts} lượt'**
  String analyticsSkillScore(String score, int attempts);

  /// No description provided for @learnerMentorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tư vấn cùng Mentor'**
  String get learnerMentorTitle;

  /// No description provided for @learnerMentorSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn gói và khung giờ phù hợp với hành trình học của bạn.'**
  String get learnerMentorSubtitle;

  /// No description provided for @learnerMentorExplore.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get learnerMentorExplore;

  /// No description provided for @learnerMentorPlansTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gói tư vấn'**
  String get learnerMentorPlansTitle;

  /// No description provided for @learnerMentorPlansEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa có gói tư vấn khả dụng.'**
  String get learnerMentorPlansEmpty;

  /// No description provided for @learnerMentorPlansError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải các gói tư vấn.'**
  String get learnerMentorPlansError;

  /// No description provided for @learnerMentorMyMeetings.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tư vấn của tôi'**
  String get learnerMentorMyMeetings;

  /// No description provided for @learnerMentorPlanDuration.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu lực {days} ngày'**
  String learnerMentorPlanDuration(int days);

  /// No description provided for @learnerMentorPlanSessions.
  ///
  /// In vi, this message translates to:
  /// **'{count} buổi tư vấn'**
  String learnerMentorPlanSessions(int count);

  /// No description provided for @learnerMentorChoosePlan.
  ///
  /// In vi, this message translates to:
  /// **'Chọn gói'**
  String get learnerMentorChoosePlan;

  /// No description provided for @learnerMentorAvailabilityTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn lịch tư vấn'**
  String get learnerMentorAvailabilityTitle;

  /// No description provided for @learnerMentorAvailabilitySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các khung giờ trống trong 30 ngày tới.'**
  String get learnerMentorAvailabilitySubtitle;

  /// No description provided for @learnerMentorAvailabilityEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có khung giờ trống trong ngày đã chọn.'**
  String get learnerMentorAvailabilityEmpty;

  /// No description provided for @learnerMentorAvailabilityError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải lịch trống của Mentor.'**
  String get learnerMentorAvailabilityError;

  /// No description provided for @learnerMentorSlotTime.
  ///
  /// In vi, this message translates to:
  /// **'{start} – {end}'**
  String learnerMentorSlotTime(String start, String end);

  /// No description provided for @learnerMentorSelectSlot.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khung giờ'**
  String get learnerMentorSelectSlot;

  /// No description provided for @learnerMentorPurchase.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục thanh toán'**
  String get learnerMentorPurchase;

  /// No description provided for @learnerMentorPurchaseBlockedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lịch đang tạm khóa'**
  String get learnerMentorPurchaseBlockedTitle;

  /// No description provided for @learnerMentorPurchaseBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Bạn vẫn có thể xem gói và lịch trống. RikiPath sẽ mở thanh toán khi Backend bảo đảm giữ chỗ an toàn, tránh hai người đặt cùng một khung giờ.'**
  String get learnerMentorPurchaseBlocked;

  /// No description provided for @learnerMentorBookingsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có lịch tư vấn Mentor.'**
  String get learnerMentorBookingsEmpty;

  /// No description provided for @learnerMentorBookingsError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải lịch tư vấn của bạn.'**
  String get learnerMentorBookingsError;

  /// No description provided for @learnerMentorMeetingDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết buổi tư vấn'**
  String get learnerMentorMeetingDetailTitle;

  /// No description provided for @learnerMentorMeetingNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy buổi tư vấn này.'**
  String get learnerMentorMeetingNotFound;

  /// No description provided for @learnerMentorMentorLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mentor'**
  String get learnerMentorMentorLabel;

  /// No description provided for @learnerMentorPaymentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get learnerMentorPaymentLabel;

  /// No description provided for @learnerMentorJoin.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia buổi tư vấn'**
  String get learnerMentorJoin;

  /// No description provided for @learnerMentorJoinUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Phòng họp chưa sẵn sàng hoặc liên kết không an toàn.'**
  String get learnerMentorJoinUnavailable;

  /// No description provided for @learnerMentorPurchaseStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái gói tư vấn'**
  String get learnerMentorPurchaseStatus;

  /// No description provided for @learnerMentorPurchaseStatusError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải trạng thái thanh toán.'**
  String get learnerMentorPurchaseStatusError;

  /// No description provided for @learnerMentorPaymentPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ thanh toán'**
  String get learnerMentorPaymentPending;

  /// No description provided for @learnerMentorPaymentPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get learnerMentorPaymentPaid;

  /// No description provided for @learnerMentorPaymentFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thất bại'**
  String get learnerMentorPaymentFailed;

  /// No description provided for @learnerMentorPaymentRefunded.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tiền'**
  String get learnerMentorPaymentRefunded;

  /// No description provided for @learnerMentorPaymentUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get learnerMentorPaymentUnknown;

  /// No description provided for @learnerMentorSessionsUsage.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng {used}/{included} buổi'**
  String learnerMentorSessionsUsage(int used, int included);

  /// No description provided for @learnerMentorRefreshStatus.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại trạng thái'**
  String get learnerMentorRefreshStatus;

  /// No description provided for @learnerMentorStatusPolling.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang đối chiếu trạng thái với Backend. Chuyển hướng thanh toán không được xem là xác nhận thành công.'**
  String get learnerMentorStatusPolling;

  /// No description provided for @learnerMentorUnknownMentor.
  ///
  /// In vi, this message translates to:
  /// **'Mentor chưa được xác định'**
  String get learnerMentorUnknownMentor;

  /// No description provided for @learnerMentorCheckoutExpired.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết thanh toán đã hết hạn'**
  String get learnerMentorCheckoutExpired;

  /// No description provided for @learnerMentorBookingReadOnly.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin lịch hẹn được đồng bộ trực tiếp từ Backend.'**
  String get learnerMentorBookingReadOnly;

  /// No description provided for @practiceSpeechTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện nói tiếng Nhật'**
  String get practiceSpeechTitle;

  /// No description provided for @practiceSpeechDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nói tiếng Nhật và xem nội dung được nhận dạng theo thời gian thực.'**
  String get practiceSpeechDescription;

  /// No description provided for @practiceSpeechStatus.
  ///
  /// In vi, this message translates to:
  /// **'Nhận dạng trực tiếp'**
  String get practiceSpeechStatus;

  /// No description provided for @practiceTextScanTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét văn bản tiếng Nhật'**
  String get practiceTextScanTitle;

  /// No description provided for @practiceTextScanDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh bài viết để nhận dạng và chỉnh sửa văn bản tiếng Nhật.'**
  String get practiceTextScanDescription;

  /// No description provided for @practiceTextScanStatus.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh → Văn bản'**
  String get practiceTextScanStatus;

  /// No description provided for @speechPracticeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện nói'**
  String get speechPracticeTitle;

  /// No description provided for @speechPracticeHeading.
  ///
  /// In vi, this message translates to:
  /// **'Biến giọng nói thành văn bản'**
  String get speechPracticeHeading;

  /// No description provided for @speechPracticeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đọc một câu tiếng Nhật thật tự nhiên. RikiPath sẽ hiển thị nội dung nhận dạng ngay khi bạn nói.'**
  String get speechPracticeSubtitle;

  /// No description provided for @speechSampleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Câu gợi ý'**
  String get speechSampleLabel;

  /// No description provided for @speechSampleSentence.
  ///
  /// In vi, this message translates to:
  /// **'日本語の話し方を練習しています。'**
  String get speechSampleSentence;

  /// No description provided for @speechTranscriptLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung nhận dạng'**
  String get speechTranscriptLabel;

  /// No description provided for @speechTranscriptEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Văn bản tiếng Nhật sẽ xuất hiện tại đây khi bạn bắt đầu nói.'**
  String get speechTranscriptEmpty;

  /// No description provided for @speechStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu nói'**
  String get speechStart;

  /// No description provided for @speechStop.
  ///
  /// In vi, this message translates to:
  /// **'Dừng ghi âm'**
  String get speechStop;

  /// No description provided for @speechConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị micro...'**
  String get speechConnecting;

  /// No description provided for @speechRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get speechRetry;

  /// No description provided for @speechSpeakAgain.
  ///
  /// In vi, this message translates to:
  /// **'Luyện nói lại'**
  String get speechSpeakAgain;

  /// No description provided for @speechCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép văn bản'**
  String get speechCopy;

  /// No description provided for @speechClear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa nội dung'**
  String get speechClear;

  /// No description provided for @speechCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép văn bản'**
  String get speechCopied;

  /// No description provided for @speechPermissionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền sử dụng micro'**
  String get speechPermissionTitle;

  /// No description provided for @speechPermissionMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hãy cho phép RikiPath sử dụng micro trong cài đặt thiết bị rồi thử lại.'**
  String get speechPermissionMessage;

  /// No description provided for @speechNetworkTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể kết nối'**
  String get speechNetworkTitle;

  /// No description provided for @speechNetworkMessage.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối mạng rồi bắt đầu lại buổi luyện nói.'**
  String get speechNetworkMessage;

  /// No description provided for @speechProviderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận dạng giọng nói bị gián đoạn'**
  String get speechProviderTitle;

  /// No description provided for @speechProviderMessage.
  ///
  /// In vi, this message translates to:
  /// **'Dừng lại một chút rồi thử bắt đầu lại. Nội dung đã nhận dạng vẫn được giữ nguyên.'**
  String get speechProviderMessage;

  /// No description provided for @speechListeningTitle.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath đang lắng nghe'**
  String get speechListeningTitle;

  /// No description provided for @speechListeningMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nói rõ ràng và giữ thiết bị gần bạn.'**
  String get speechListeningMessage;

  /// No description provided for @speechReadyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Micro chỉ hoạt động khi bạn nhấn bắt đầu và sẽ dừng khi rời màn hình.'**
  String get speechReadyMessage;

  /// No description provided for @textScanTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét văn bản'**
  String get textScanTitle;

  /// No description provided for @textScanHeading.
  ///
  /// In vi, this message translates to:
  /// **'Nhận dạng chữ viết tiếng Nhật'**
  String get textScanHeading;

  /// No description provided for @textScanSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh JPG, PNG hoặc WEBP rõ nét. Bạn có thể chỉnh sửa và sao chép kết quả ngay trên thiết bị.'**
  String get textScanSubtitle;

  /// No description provided for @textScanChooseImage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thư viện'**
  String get textScanChooseImage;

  /// No description provided for @textScanSelecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở thư viện...'**
  String get textScanSelecting;

  /// No description provided for @textScanDropTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh bài viết tiếng Nhật'**
  String get textScanDropTitle;

  /// No description provided for @textScanRequirements.
  ///
  /// In vi, this message translates to:
  /// **'JPG, PNG hoặc WEBP • tối đa 10 MB'**
  String get textScanRequirements;

  /// No description provided for @textScanPrivacyNote.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh được gửi tới dịch vụ RikiPath để nhận dạng văn bản và không được hiển thị như một bài đã lưu.'**
  String get textScanPrivacyNote;

  /// No description provided for @textScanAction.
  ///
  /// In vi, this message translates to:
  /// **'Quét văn bản'**
  String get textScanAction;

  /// No description provided for @textScanScanning.
  ///
  /// In vi, this message translates to:
  /// **'Đang nhận dạng...'**
  String get textScanScanning;

  /// No description provided for @textScanChooseAnother.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh khác'**
  String get textScanChooseAnother;

  /// No description provided for @textScanClear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ảnh và kết quả'**
  String get textScanClear;

  /// No description provided for @textScanResultLabel.
  ///
  /// In vi, this message translates to:
  /// **'Văn bản nhận dạng'**
  String get textScanResultLabel;

  /// No description provided for @textScanResultHint.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả nhận dạng sẽ xuất hiện tại đây.'**
  String get textScanResultHint;

  /// No description provided for @textScanLocalEditNote.
  ///
  /// In vi, this message translates to:
  /// **'Các chỉnh sửa trên màn hình này chưa được lưu vào lịch sử tài khoản.'**
  String get textScanLocalEditNote;

  /// No description provided for @textScanCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép kết quả'**
  String get textScanCopy;

  /// No description provided for @textScanCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép kết quả'**
  String get textScanCopied;

  /// No description provided for @textScanUnsupportedType.
  ///
  /// In vi, this message translates to:
  /// **'RikiPath chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.'**
  String get textScanUnsupportedType;

  /// No description provided for @textScanTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vượt quá giới hạn 10 MB. Hãy chọn ảnh nhỏ hơn.'**
  String get textScanTooLarge;

  /// No description provided for @textScanPickerFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể mở thư viện ảnh'**
  String get textScanPickerFailedTitle;

  /// No description provided for @textScanPickerError.
  ///
  /// In vi, this message translates to:
  /// **'Hãy kiểm tra quyền truy cập ảnh rồi thử lại.'**
  String get textScanPickerError;

  /// No description provided for @textScanFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể quét ảnh'**
  String get textScanFailedTitle;

  /// No description provided for @textScanNetworkError.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối mạng rồi thử quét lại.'**
  String get textScanNetworkError;

  /// No description provided for @textScanProviderError.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ nhận dạng văn bản hiện chưa sẵn sàng. Ảnh của bạn vẫn được giữ để thử lại.'**
  String get textScanProviderError;

  /// No description provided for @textScanCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận dạng xong. Bạn có thể kiểm tra, chỉnh sửa hoặc sao chép văn bản.'**
  String get textScanCompleted;

  /// No description provided for @practiceStudioTitle.
  ///
  /// In vi, this message translates to:
  /// **'Studio Riki'**
  String get practiceStudioTitle;

  /// No description provided for @practiceStudioSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện nói, luyện viết và khám phá tiếng Nhật bằng các công cụ tương tác.'**
  String get practiceStudioSubtitle;

  /// No description provided for @practiceWritingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện viết Kana & Kanji'**
  String get practiceWritingTitle;

  /// No description provided for @practiceWritingDescription.
  ///
  /// In vi, this message translates to:
  /// **'Xem thứ tự nét, viết trực tiếp và lưu tiến độ ôn tập.'**
  String get practiceWritingDescription;

  /// No description provided for @practiceWritingStatus.
  ///
  /// In vi, this message translates to:
  /// **'Nét chữ tương tác'**
  String get practiceWritingStatus;

  /// No description provided for @writingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện viết'**
  String get writingTitle;

  /// No description provided for @writingSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một ký tự rồi luyện theo đúng thứ tự và hướng nét.'**
  String get writingSubtitle;

  /// No description provided for @writingHiragana.
  ///
  /// In vi, this message translates to:
  /// **'Hiragana'**
  String get writingHiragana;

  /// No description provided for @writingKatakana.
  ///
  /// In vi, this message translates to:
  /// **'Katakana'**
  String get writingKatakana;

  /// No description provided for @writingKanji.
  ///
  /// In vi, this message translates to:
  /// **'Kanji'**
  String get writingKanji;

  /// No description provided for @writingDue.
  ///
  /// In vi, this message translates to:
  /// **'Đến hạn'**
  String get writingDue;

  /// No description provided for @writingAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get writingAll;

  /// No description provided for @writingQueueHint.
  ///
  /// In vi, this message translates to:
  /// **'Ký tự đến hạn được ưu tiên trước, sau đó là nội dung mới đã được duyệt.'**
  String get writingQueueHint;

  /// No description provided for @writingSelectCharacter.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ký tự để bắt đầu'**
  String get writingSelectCharacter;

  /// No description provided for @writingEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ký tự để luyện'**
  String get writingEmptyTitle;

  /// No description provided for @writingKanaEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Backend chưa trả về ký tự {script} đã được duyệt cho tài khoản này.'**
  String writingKanaEmptyMessage(String script);

  /// No description provided for @writingKanjiEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay chưa có Kanji phù hợp trong danh sách này.'**
  String get writingKanjiEmptyMessage;

  /// No description provided for @writingLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải danh sách luyện viết'**
  String get writingLoadFailed;

  /// No description provided for @writingStrokeCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} nét'**
  String writingStrokeCount(int count);

  /// No description provided for @writingNewCharacter.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get writingNewCharacter;

  /// No description provided for @writingReviewCharacter.
  ///
  /// In vi, this message translates to:
  /// **'Ôn lại'**
  String get writingReviewCharacter;

  /// No description provided for @writingLastScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gần nhất {score}/100'**
  String writingLastScore(int score);

  /// No description provided for @writingMeaningUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật nghĩa'**
  String get writingMeaningUnavailable;

  /// No description provided for @writingTargetLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ký tự mục tiêu'**
  String get writingTargetLabel;

  /// No description provided for @writingOnReading.
  ///
  /// In vi, this message translates to:
  /// **'Âm On'**
  String get writingOnReading;

  /// No description provided for @writingKunReading.
  ///
  /// In vi, this message translates to:
  /// **'Âm Kun'**
  String get writingKunReading;

  /// No description provided for @writingReadingUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật'**
  String get writingReadingUnavailable;

  /// No description provided for @writingGuidedMode.
  ///
  /// In vi, this message translates to:
  /// **'Theo nét mẫu'**
  String get writingGuidedMode;

  /// No description provided for @writingFreeMode.
  ///
  /// In vi, this message translates to:
  /// **'Tự viết'**
  String get writingFreeMode;

  /// No description provided for @writingGuidedHint.
  ///
  /// In vi, this message translates to:
  /// **'Nét mờ sẽ hướng dẫn vị trí. Hãy viết đúng thứ tự và hướng nét.'**
  String get writingGuidedHint;

  /// No description provided for @writingFreeHint.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu được ẩn để bạn tự nhớ thứ tự và hướng nét.'**
  String get writingFreeHint;

  /// No description provided for @writingGestureHint.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt trong khung để viết • Vuốt bên ngoài để cuộn'**
  String get writingGestureHint;

  /// No description provided for @writingShowStrokes.
  ///
  /// In vi, this message translates to:
  /// **'Xem nét mẫu'**
  String get writingShowStrokes;

  /// No description provided for @writingStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu viết'**
  String get writingStart;

  /// No description provided for @writingRewrite.
  ///
  /// In vi, this message translates to:
  /// **'Viết lại'**
  String get writingRewrite;

  /// No description provided for @writingNext.
  ///
  /// In vi, this message translates to:
  /// **'Ký tự tiếp theo'**
  String get writingNext;

  /// No description provided for @writingLoadingStrokeData.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị dữ liệu nét chữ...'**
  String get writingLoadingStrokeData;

  /// No description provided for @writingStrokeDataFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được nét chữ'**
  String get writingStrokeDataFailedTitle;

  /// No description provided for @writingStrokeDataFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối rồi thử lại. Dữ liệu đã tải trước đó vẫn có thể dùng khi ngoại tuyến.'**
  String get writingStrokeDataFailedMessage;

  /// No description provided for @writingQuizInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang viết • hoàn thành từng nét theo thứ tự'**
  String get writingQuizInProgress;

  /// No description provided for @writingAnimationInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang trình diễn thứ tự nét...'**
  String get writingAnimationInProgress;

  /// No description provided for @writingCompleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành bài viết'**
  String get writingCompleteTitle;

  /// No description provided for @writingMistakeCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} nét sai'**
  String writingMistakeCount(int count);

  /// No description provided for @writingResultScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm {score}/100'**
  String writingResultScore(int score);

  /// No description provided for @writingSavingResult.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu tiến độ...'**
  String get writingSavingResult;

  /// No description provided for @writingResultSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu lịch ôn tiếp theo'**
  String get writingResultSaved;

  /// No description provided for @writingResultSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả vẫn được giữ trên thiết bị nhưng chưa lưu được lên RikiPath.'**
  String get writingResultSaveFailed;

  /// No description provided for @writingRetrySave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu lại'**
  String get writingRetrySave;

  /// No description provided for @writingProgress.
  ///
  /// In vi, this message translates to:
  /// **'{current}/{total}'**
  String writingProgress(int current, int total);

  /// No description provided for @orDivider.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get orDivider;

  /// No description provided for @meetingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phòng họp'**
  String get meetingTitle;

  /// No description provided for @meetingJoinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia cuộc họp'**
  String get meetingJoinTitle;

  /// No description provided for @meetingJoinAction.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia cuộc họp'**
  String get meetingJoinAction;

  /// No description provided for @meetingContinueAction.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get meetingContinueAction;

  /// No description provided for @meetingLandingDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia bằng mã phòng hoặc liên kết RikiPath được chia sẻ với bạn.'**
  String get meetingLandingDescription;

  /// No description provided for @meetingJoinDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã phòng hoặc dán liên kết RikiPath để tham gia.'**
  String get meetingJoinDescription;

  /// No description provided for @meetingLinkLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã phòng hoặc liên kết'**
  String get meetingLinkLabel;

  /// No description provided for @meetingLinkHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã phòng hoặc dán liên kết'**
  String get meetingLinkHint;

  /// No description provided for @meetingLinkRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã phòng hoặc liên kết.'**
  String get meetingLinkRequired;

  /// No description provided for @meetingLinkInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã phòng không hợp lệ. Vui lòng kiểm tra lại.'**
  String get meetingLinkInvalid;

  /// No description provided for @meetingPasteAction.
  ///
  /// In vi, this message translates to:
  /// **'Dán'**
  String get meetingPasteAction;

  /// No description provided for @meetingRoomCodeHelper.
  ///
  /// In vi, this message translates to:
  /// **'Mã phòng nằm ở cuối liên kết cuộc họp.'**
  String get meetingRoomCodeHelper;

  /// No description provided for @meetingErrorRoomNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy phòng họp này. Vui lòng kiểm tra lại mã phòng.'**
  String get meetingErrorRoomNotFound;

  /// No description provided for @meetingErrorNotAuthorized.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn không có quyền tham gia phòng họp này.'**
  String get meetingErrorNotAuthorized;

  /// No description provided for @meetingErrorAuthRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đăng nhập để tham gia phòng họp.'**
  String get meetingErrorAuthRequired;

  /// No description provided for @meetingErrorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối tới phòng họp. Vui lòng kiểm tra mạng và thử lại.'**
  String get meetingErrorNetwork;

  /// No description provided for @meetingAuthorizationNotice.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết không tự động cấp quyền truy cập. Phòng họp sẽ kiểm tra tài khoản và quyền tham gia của bạn.'**
  String get meetingAuthorizationNotice;

  /// No description provided for @meetingAuthRequiredTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để tham gia cuộc họp'**
  String get meetingAuthRequiredTitle;

  /// No description provided for @meetingAuthRequiredDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mã phòng đã được giữ tạm thời trên thiết bị này. Sau khi đăng nhập, bạn sẽ tự động quay lại phòng họp.'**
  String get meetingAuthRequiredDescription;

  /// No description provided for @meetingReadyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng mở phòng họp'**
  String get meetingReadyTitle;

  /// No description provided for @meetingEnterRoom.
  ///
  /// In vi, this message translates to:
  /// **'Vào phòng họp'**
  String get meetingEnterRoom;

  /// No description provided for @meetingOpenFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể mở phòng họp'**
  String get meetingOpenFailedTitle;

  /// No description provided for @meetingOpenFailedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra trình duyệt và kết nối mạng rồi thử lại.'**
  String get meetingOpenFailedDescription;

  /// No description provided for @meetingDetailsAction.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get meetingDetailsAction;

  /// No description provided for @meetingNativeParticipantsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} người tham gia'**
  String meetingNativeParticipantsCount(int count);

  /// No description provided for @meetingNativeConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối phòng họp...'**
  String get meetingNativeConnecting;

  /// No description provided for @meetingNativeJoining.
  ///
  /// In vi, this message translates to:
  /// **'Đang vào phòng...'**
  String get meetingNativeJoining;

  /// No description provided for @meetingNativeReconnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối lại...'**
  String get meetingNativeReconnecting;

  /// No description provided for @meetingNativeFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối phòng họp'**
  String get meetingNativeFailedTitle;

  /// No description provided for @meetingNativeFailedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra kết nối và quyền tham gia phòng rồi thử lại.'**
  String get meetingNativeFailedDescription;

  /// No description provided for @meetingNativeRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get meetingNativeRetry;

  /// No description provided for @meetingNativeOpenWeb.
  ///
  /// In vi, this message translates to:
  /// **'Mở phiên bản web'**
  String get meetingNativeOpenWeb;

  /// No description provided for @meetingNativeMicrophone.
  ///
  /// In vi, this message translates to:
  /// **'Mic'**
  String get meetingNativeMicrophone;

  /// No description provided for @meetingNativeCamera.
  ///
  /// In vi, this message translates to:
  /// **'Camera'**
  String get meetingNativeCamera;

  /// No description provided for @meetingNativeSwitchCamera.
  ///
  /// In vi, this message translates to:
  /// **'Đổi camera'**
  String get meetingNativeSwitchCamera;

  /// No description provided for @meetingNativeRaiseHand.
  ///
  /// In vi, this message translates to:
  /// **'Giơ tay'**
  String get meetingNativeRaiseHand;

  /// No description provided for @meetingNativeLowerHand.
  ///
  /// In vi, this message translates to:
  /// **'Hạ tay'**
  String get meetingNativeLowerHand;

  /// No description provided for @meetingNativeChat.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện'**
  String get meetingNativeChat;

  /// No description provided for @meetingNativeParticipants.
  ///
  /// In vi, this message translates to:
  /// **'Người tham gia'**
  String get meetingNativeParticipants;

  /// No description provided for @meetingNativeMoreActions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn khác'**
  String get meetingNativeMoreActions;

  /// No description provided for @meetingNativeMinimize.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhỏ'**
  String get meetingNativeMinimize;

  /// No description provided for @meetingNativeLeave.
  ///
  /// In vi, this message translates to:
  /// **'Rời phòng'**
  String get meetingNativeLeave;

  /// No description provided for @meetingNativeLeaveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời cuộc họp?'**
  String get meetingNativeLeaveTitle;

  /// No description provided for @meetingNativeLeaveDescription.
  ///
  /// In vi, this message translates to:
  /// **'Camera và microphone sẽ được tắt khi bạn rời phòng.'**
  String get meetingNativeLeaveDescription;

  /// No description provided for @meetingNativeStay.
  ///
  /// In vi, this message translates to:
  /// **'Ở lại'**
  String get meetingNativeStay;

  /// No description provided for @meetingNativeNoParticipants.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ người khác tham gia'**
  String get meetingNativeNoParticipants;

  /// No description provided for @meetingNativeChatEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nhắn nào.'**
  String get meetingNativeChatEmpty;

  /// No description provided for @meetingNativeChatHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tin nhắn...'**
  String get meetingNativeChatHint;

  /// No description provided for @meetingNativeSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get meetingNativeSend;

  /// No description provided for @meetingNativeYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get meetingNativeYou;

  /// No description provided for @meetingNativeMentor.
  ///
  /// In vi, this message translates to:
  /// **'Mentor'**
  String get meetingNativeMentor;

  /// No description provided for @meetingNativeLearner.
  ///
  /// In vi, this message translates to:
  /// **'Học viên'**
  String get meetingNativeLearner;

  /// No description provided for @meetingNativePermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể tiếp tục nghe/xem. Hãy cấp quyền Camera và Microphone trong Cài đặt để phát hình và âm thanh.'**
  String get meetingNativePermissionDenied;

  /// No description provided for @meetingNativeCameraDenied.
  ///
  /// In vi, this message translates to:
  /// **'Camera chưa được cấp quyền. Bạn vẫn có thể tham gia bằng âm thanh.'**
  String get meetingNativeCameraDenied;

  /// No description provided for @meetingNativeMicrophoneDenied.
  ///
  /// In vi, this message translates to:
  /// **'Microphone chưa được cấp quyền. Bạn vẫn có thể tham gia ở chế độ nghe.'**
  String get meetingNativeMicrophoneDenied;

  /// No description provided for @meetingNativeMediaUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở Camera hoặc Microphone. Bạn vẫn có thể xem và trò chuyện.'**
  String get meetingNativeMediaUnavailable;

  /// No description provided for @meetingNativeScreenShareDeferred.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ màn hình hiện dùng phiên bản web.'**
  String get meetingNativeScreenShareDeferred;

  /// No description provided for @homeMeetingFallbackTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phòng họp'**
  String get homeMeetingFallbackTitle;

  /// No description provided for @homeMeetingFallbackDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia bằng mã phòng hoặc liên kết.'**
  String get homeMeetingFallbackDescription;

  /// No description provided for @homeUpcomingMeetingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Buổi tư vấn sắp tới'**
  String get homeUpcomingMeetingTitle;

  /// No description provided for @homeMeetingSchedule.
  ///
  /// In vi, this message translates to:
  /// **'{date} • {time}'**
  String homeMeetingSchedule(String date, String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
