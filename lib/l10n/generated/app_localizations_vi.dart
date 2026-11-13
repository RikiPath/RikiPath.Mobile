// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'RikiPath';

  @override
  String get toastRegisterSuccessTitle => 'Tạo tài khoản thành công';

  @override
  String get toastRegisterSuccessDescription =>
      'Vui lòng xác thực email để tiếp tục.';

  @override
  String get toastVerifyEmailSuccessTitle => 'Xác thực email thành công';

  @override
  String get toastVerifyEmailSuccessDescription =>
      'Bạn có thể đăng nhập ngay bây giờ.';

  @override
  String get toastLoginSuccessTitle => 'Đăng nhập thành công';

  @override
  String get toastLoginSuccessDescription =>
      'Chào mừng bạn trở lại với RikiPath.';

  @override
  String get toastProfileUpdateSuccessTitle => 'Cập nhật hồ sơ thành công';

  @override
  String get toastEmailUpdateSuccessTitle => 'Cập nhật email thành công';

  @override
  String get toastPasswordChangeSuccessTitle => 'Đổi mật khẩu thành công';

  @override
  String get toastAvatarUploadSuccessTitle =>
      'Cập nhật ảnh đại diện thành công';

  @override
  String get toastNotificationUpdateSuccessTitle =>
      'Cập nhật thông báo thành công';

  @override
  String get toastJlptGoalUpdateSuccessTitle =>
      'Cập nhật mục tiêu JLPT thành công';

  @override
  String get toastActionFailedTitle => 'Không thể hoàn tất thao tác';

  @override
  String get toastAudioFailedTitle => 'Không thể phát âm thanh';

  @override
  String get languagePickerSemantics => 'Chọn ngôn ngữ';

  @override
  String get languageMenuTitle => 'Ngôn ngữ / 言語';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageCodeVietnamese => 'VI';

  @override
  String get languageCodeJapanese => 'JA';

  @override
  String get appLanguageTitle => 'Ngôn ngữ ứng dụng';

  @override
  String get appLanguageSubtitle => 'Chọn ngôn ngữ hiển thị trong ứng dụng';

  @override
  String get vietnameseSubLabel => 'Vietnamese';

  @override
  String get japaneseSubLabel => 'Japanese';

  @override
  String get back => 'Quay lại';

  @override
  String get retry => 'Thử lại';

  @override
  String get clearFilters => 'Xóa bộ lọc';

  @override
  String get all => 'Tất cả';

  @override
  String get close => 'Đóng';

  @override
  String get cancel => 'Hủy';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get save => 'Lưu';

  @override
  String get continueLabel => 'Tiếp tục';

  @override
  String get finish => 'Hoàn tất';

  @override
  String get loading => 'Đang tải...';

  @override
  String get preparingLearningContent => 'Đang mở RikiPath...';

  @override
  String get preparingLearningSubtext =>
      'Đang kiểm tra phiên đăng nhập để đưa bạn vào không gian học tập.';

  @override
  String get learnerStartupLoadingTitle =>
      'Đang xác định bước học tiếp theo...';

  @override
  String get learnerStartupLoadingSubtitle =>
      'RikiPath đang kiểm tra hồ sơ và mục tiêu JLPT của bạn.';

  @override
  String get learnerStartupOnboardingTitle =>
      'Đang mở phần thiết lập học tập...';

  @override
  String get learnerStartupPlacementTitle => 'Đang mở bài kiểm tra đầu vào...';

  @override
  String get learnerStartupHomeTitle => 'Đang mở trang học tập của bạn...';

  @override
  String get notAvailable => 'Chưa khả dụng';

  @override
  String pageNotFound(String uri) {
    return 'Không tìm thấy trang: $uri';
  }

  @override
  String get navigationHome => 'Trang chủ';

  @override
  String get navigationLearn => 'Học tập';

  @override
  String get navigationPractice => 'Luyện tập';

  @override
  String get navigationNotebook => 'Sổ từ';

  @override
  String get navigationProfile => 'Cá nhân';

  @override
  String get splashTagline => 'Học tiếng Nhật • Luyện thi JLPT';

  @override
  String get authPromotion => 'Học tiếng Nhật cá nhân hoá cùng AI';

  @override
  String get loginWelcome => 'Chào mừng trở lại!';

  @override
  String get loginSubtitle =>
      'Tiếp tục hành trình chinh phục JLPT cùng RikiPath.';

  @override
  String get studentEmail => 'Email học viên';

  @override
  String get emailAddress => 'Email';

  @override
  String get emailHint => 'hocvien@example.com';

  @override
  String get password => 'Mật khẩu';

  @override
  String get passwordHint => 'Nhập mật khẩu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get rememberSession => 'Ghi nhớ phiên đăng nhập trên thiết bị này';

  @override
  String get login => 'Đăng nhập';

  @override
  String get loggingIn => 'Đang đăng nhập...';

  @override
  String get loggingInSemantics => 'Đang đăng nhập';

  @override
  String get loginSecureConnection =>
      'Đang kết nối an toàn với tài khoản của bạn...';

  @override
  String get loginFailedTitle => 'Không thể đăng nhập';

  @override
  String get noAccount => 'Chưa có tài khoản?';

  @override
  String get register => 'Đăng ký';

  @override
  String get registerAsMentor => 'Đăng ký làm Cố vấn';

  @override
  String get mentorRegistrationPromotion =>
      'Chia sẻ kiến thức, đồng hành cùng học viên JLPT';

  @override
  String get mentorRegistrationTitle => 'Đăng ký trở thành Cố vấn';

  @override
  String get mentorRegistrationSubtitle =>
      'Tạo tài khoản để hoàn thiện hồ sơ và tham gia xét duyệt Cố vấn tại RikiPath.';

  @override
  String get mentorRegistrationEmail => 'Email liên hệ';

  @override
  String get mentorRegistrationEmailHint => 'covan@example.com';

  @override
  String get mentorRegistrationSubmit => 'Tạo tài khoản và tiếp tục';

  @override
  String get mentorRegistrationLoginPrompt =>
      'Đã có tài khoản? Đăng nhập để tiếp tục ứng tuyển';

  @override
  String get mentorCreatingAccountMessage =>
      'Đang tạo tài khoản và gửi email xác thực...';

  @override
  String mentorRegistrationCreatedMessage(String email) {
    return 'RikiPath đã gửi mã xác thực tới\n$email. Xác thực email rồi đăng nhập để hoàn thiện hồ sơ ứng tuyển Cố vấn.';
  }

  @override
  String get mentorApplicationTitle => 'Hồ sơ ứng tuyển Cố vấn';

  @override
  String get mentorApplicationIntro =>
      'Hoàn thiện hồ sơ và tải chứng chỉ để Quản trị viên xét duyệt. Bạn chỉ có quyền Cố vấn sau khi được phê duyệt.';

  @override
  String get mentorApplicationPersonal => 'Thông tin cá nhân';

  @override
  String get mentorApplicationExpertise => 'Chuyên môn và kinh nghiệm';

  @override
  String get mentorApplicationBioRequired => 'Giới thiệu bản thân *';

  @override
  String get mentorApplicationExpertiseRequired => 'Lĩnh vực chuyên môn *';

  @override
  String get mentorApplicationJlptRequired => 'Trình độ tiếng Nhật *';

  @override
  String get mentorApplicationDocumentRequired =>
      'Bắt buộc: tải chứng chỉ PDF, JPEG hoặc PNG (tối đa 5 MB) trước khi gửi.';

  @override
  String get mentorApplicationDocumentUploaded =>
      'Đã tải chứng chỉ xác minh lên kho riêng tư.';

  @override
  String get mentorApplicationIncomplete =>
      'Vui lòng lưu giới thiệu, chuyên môn và trình độ tiếng Nhật trước khi gửi hồ sơ.';

  @override
  String get mentorApplicationSubmit => 'Gửi hồ sơ xét duyệt';

  @override
  String get mentorApplicationSubmitting => 'Đang gửi hồ sơ...';

  @override
  String get mentorApplicationPending => 'Đang chờ xét duyệt';

  @override
  String get mentorApplicationStatusLabel => 'Trạng thái xét duyệt';

  @override
  String get mentorApplicationUpload => 'Chọn và tải chứng chỉ';

  @override
  String get mentorApplicationUploading => 'Đang tải chứng chỉ...';

  @override
  String get securityFooter => 'Bảo mật chuẩn mã hóa Riki Learning';

  @override
  String get registerTitle => 'Tạo tài khoản RikiPath';

  @override
  String get registerSubtitle =>
      'Bắt đầu xây dựng lộ trình học JLPT của riêng bạn.';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get fullNameHint => 'Nguyễn Minh Anh';

  @override
  String get minimumSixCharacters => 'Tối thiểu 6 ký tự';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get confirmPasswordHint => 'Nhập lại mật khẩu';

  @override
  String get termsPrefix => 'Bằng việc đăng ký, bạn đồng ý với ';

  @override
  String get termsOfService => 'Điều khoản dịch vụ';

  @override
  String get termsJoiner => ' & ';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get termsSuffix => ' của RikiPath.';

  @override
  String get registerFailedTitle => 'Không thể tạo tài khoản';

  @override
  String get creatingAccount => 'Đang tạo tài khoản...';

  @override
  String get creatingAccountSemantics => 'Đang tạo tài khoản';

  @override
  String get creatingAccountMessage =>
      'Đang tạo tài khoản học viên và gửi email xác thực...';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản?';

  @override
  String get accountCreatedStatus => 'Đã tạo tài khoản';

  @override
  String get accountCreatedTitle => 'Tạo tài khoản thành công';

  @override
  String accountCreatedMessage(String email) {
    return 'RikiPath đã gửi mã xác thực tới\n$email.';
  }

  @override
  String get checkEmailVerification =>
      'Vui lòng kiểm tra email để xác thực tài khoản.';

  @override
  String get verificationBackendBlocker =>
      'Mã xác thực gồm 6 chữ số và có hiệu lực trong 30 phút. Chúng tôi chưa nhận đủ thông tin tài khoản để tiếp tục; vui lòng thử đăng ký lại.';

  @override
  String get returnToLogin => 'Quay lại đăng nhập';

  @override
  String get verifyEmailStatus => 'Xác thực email';

  @override
  String get emailVerifiedStatus => 'Email đã xác thực';

  @override
  String get verifyEmailTitle => 'Nhập mã xác thực';

  @override
  String get verifyEmailSubtitle =>
      'Nhập mã 6 chữ số đã được gửi tới email của bạn.';

  @override
  String get verificationCodeSentTo => 'Mã xác thực đã được gửi đến';

  @override
  String get verificationCodeSentToYourEmail =>
      'Mã xác thực đã được gửi đến email của bạn.';

  @override
  String get verificationCode => 'Mã xác thực';

  @override
  String get verificationCodeHint => '000000';

  @override
  String get didNotReceiveVerificationCode => 'Không nhận được mã?';

  @override
  String get resendVerificationCode => 'Gửi lại mã';

  @override
  String resendVerificationCodeIn(String time) {
    return 'Gửi lại mã sau $time';
  }

  @override
  String get resendingVerificationCode => 'Đang gửi lại...';

  @override
  String get verificationCodeResentMessage =>
      'RikiPath đã gửi một mã xác thực mới tới email của bạn.';

  @override
  String get resendVerificationFailedTitle => 'Không thể gửi lại mã';

  @override
  String get verify => 'Xác thực';

  @override
  String get verifying => 'Đang xác thực...';

  @override
  String get verifyEmailSuccessTitle => 'Xác thực email thành công';

  @override
  String get verifyEmailSuccessMessage =>
      'Tài khoản của bạn đã sẵn sàng để đăng nhập.';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu?';

  @override
  String get forgotPasswordSubtitle =>
      'Nhập email đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.';

  @override
  String get registeredEmail => 'EMAIL ĐÃ ĐĂNG KÝ';

  @override
  String get sendRequest => 'Gửi yêu cầu';

  @override
  String get sendingRequest => 'Đang gửi yêu cầu...';

  @override
  String get requestSentStatus => 'Đã gửi email';

  @override
  String get requestSentTitle => 'Yêu cầu đã được gửi';

  @override
  String requestSentMessage(String email) {
    return 'Kiểm tra hộp thư $email để tiếp tục đặt lại mật khẩu.';
  }

  @override
  String resendCountdown(int seconds) {
    return 'Gửi lại (${seconds}s)';
  }

  @override
  String get passwordRecoveryUnavailableTitle => 'Chưa thể gửi yêu cầu';

  @override
  String get account => 'Tài khoản';

  @override
  String get accountSecurity => 'Bảo mật tài khoản';

  @override
  String get accountSecuritySubtitle =>
      'Quản lý email đăng nhập, mật khẩu và phiên hiện tại.';

  @override
  String get changeEmail => 'Đổi email';

  @override
  String get changeEmailSubtitle => 'Gửi mã xác thực tới email mới';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get changePasswordSubtitle => 'Yêu cầu mật khẩu hiện tại';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get newEmail => 'Email mới';

  @override
  String get newEmailHint => 'emailmoi@example.com';

  @override
  String get updateEmail => 'Cập nhật email';

  @override
  String get updatingEmail => 'Đang cập nhật...';

  @override
  String get emailUpdatedTitle => 'Đã cập nhật email';

  @override
  String get emailUpdatedMessage =>
      'Vui lòng kiểm tra email mới để hoàn tất xác thực.';

  @override
  String get currentPassword => 'Mật khẩu hiện tại';

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get confirmNewPassword => 'Xác nhận mật khẩu mới';

  @override
  String get changePasswordAction => 'Cập nhật mật khẩu';

  @override
  String get changingPassword => 'Đang cập nhật...';

  @override
  String get passwordChangedTitle => 'Đã đổi mật khẩu';

  @override
  String get passwordChangedMessage => 'Mật khẩu của bạn đã được cập nhật.';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get validationEmailRequired => 'Vui lòng nhập email.';

  @override
  String get validationEmailInvalid =>
      'Email không hợp lệ. Vui lòng kiểm tra lại định dạng.';

  @override
  String get validationPasswordRequired => 'Vui lòng nhập mật khẩu.';

  @override
  String get validationPasswordLength => 'Mật khẩu phải có ít nhất 6 ký tự.';

  @override
  String get validationConfirmPasswordRequired => 'Vui lòng xác nhận mật khẩu.';

  @override
  String get validationPasswordMismatch => 'Mật khẩu xác nhận không khớp.';

  @override
  String get validationVerificationCodeRequired => 'Vui lòng nhập mã xác thực.';

  @override
  String get validationVerificationCodeLength =>
      'Mã xác thực phải gồm đúng 6 chữ số.';

  @override
  String get validationTermsRequired =>
      'Vui lòng đồng ý với điều khoản trước khi đăng ký.';

  @override
  String get authErrorPasswordRecoveryUnavailable =>
      'Tính năng lấy lại mật khẩu hiện chưa khả dụng trong ứng dụng. Vui lòng liên hệ trung tâm trợ giúp.';

  @override
  String get authErrorUnsupportedRole =>
      'Ứng dụng di động hiện chỉ hỗ trợ tài khoản học viên và cố vấn.';

  @override
  String get mentorLandingTitle => 'Không gian cố vấn';

  @override
  String get mentorLandingDescription =>
      'Theo dõi khung giờ trống và các buổi tư vấn sắp tới của bạn.';

  @override
  String get mentorHomeGreeting => 'Chào mừng trở lại';

  @override
  String get mentorAvailabilityTitle => 'Lịch trống của tôi';

  @override
  String get mentorAvailabilityDescription =>
      'Các khung giờ đang được hiển thị cho học viên.';

  @override
  String mentorAvailabilityCount(int count) {
    return '$count khung giờ';
  }

  @override
  String get mentorAvailabilityEmpty => 'Bạn chưa có khung giờ trống nào.';

  @override
  String get mentorAvailabilityError =>
      'Chưa thể tải lịch trống. Vui lòng thử lại.';

  @override
  String get mentorAvailabilityReadOnlyTitle => 'Chế độ chỉ đọc';

  @override
  String get mentorAvailabilityReadOnlyMessage =>
      'Bạn có thể xem lịch trống trên ứng dụng. Tính năng thay đổi lịch sẽ được mở khi cách xử lý múi giờ được thống nhất.';

  @override
  String get mentorViewAvailability => 'Xem lịch trống';

  @override
  String get mentorMeetingsTitle => 'Lịch tư vấn của tôi';

  @override
  String get mentorMeetingsDescription =>
      'Các buổi tư vấn đã được xác nhận với học viên.';

  @override
  String mentorMeetingsCount(int count) {
    return '$count buổi tư vấn';
  }

  @override
  String get mentorMeetingsEmpty => 'Bạn chưa có lịch tư vấn nào.';

  @override
  String get mentorMeetingsError =>
      'Chưa thể tải lịch tư vấn. Vui lòng thử lại.';

  @override
  String get mentorViewMeetings => 'Xem lịch tư vấn';

  @override
  String get mentorMeetingDetailTitle => 'Chi tiết buổi tư vấn';

  @override
  String get mentorLearnerLabel => 'Học viên';

  @override
  String get mentorLearnerUnknown => 'Chưa có thông tin học viên';

  @override
  String get mentorScheduleLabel => 'Thời gian';

  @override
  String get mentorSchedulePending => 'Chưa xác định thời gian';

  @override
  String get mentorStartTimeLabel => 'Bắt đầu';

  @override
  String get mentorEndTimeLabel => 'Kết thúc';

  @override
  String get mentorStatusLabel => 'Trạng thái';

  @override
  String get mentorSlotOpen => 'Còn trống';

  @override
  String get mentorSlotBooked => 'Đã được đặt';

  @override
  String get mentorJoinMeeting => 'Vào phòng tư vấn';

  @override
  String get mentorMeetingLinkUnavailable =>
      'Phòng tư vấn chưa sẵn sàng cho lịch hẹn này.';

  @override
  String get mentorMeetingNotFound =>
      'Không tìm thấy buổi tư vấn trong lịch của bạn.';

  @override
  String get mentorJoinFailedTitle => 'Không thể mở phòng tư vấn';

  @override
  String get mentorJoinFailedDescription =>
      'Không thể mở phòng tư vấn trên thiết bị này.';

  @override
  String get mentorStatusAwaitingPayment => 'Chờ thanh toán';

  @override
  String get mentorStatusPendingAssignment => 'Chờ phân công';

  @override
  String get mentorStatusAssigned => 'Đã xác nhận';

  @override
  String get learnerMentorStatusAssigned => 'Đã xác nhận lịch';

  @override
  String get mentorStatusAccepted => 'Đã xác nhận';

  @override
  String get mentorStatusCompleted => 'Đã hoàn thành';

  @override
  String get mentorStatusCancelled => 'Đã hủy';

  @override
  String get mentorStatusUnknown => 'Chưa xác định';

  @override
  String get unsupportedRoleTitle => 'Vai trò chưa được hỗ trợ';

  @override
  String get unsupportedRoleDescription =>
      'Tài khoản này chưa được hỗ trợ trên ứng dụng di động. Vui lòng đăng xuất và dùng tài khoản học viên hoặc cố vấn.';

  @override
  String get authErrorNetwork =>
      'Không thể kết nối tới RikiPath. Vui lòng kiểm tra mạng và thử lại.';

  @override
  String get authErrorInvalidCredentials =>
      'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';

  @override
  String get authErrorSessionExpired =>
      'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.';

  @override
  String get authErrorForbidden => 'Bạn không có quyền thực hiện thay đổi này.';

  @override
  String get authErrorNotFound => 'Không tìm thấy tài khoản cần cập nhật.';

  @override
  String get authErrorLoginValidation =>
      'Thông tin đăng nhập chưa hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get authErrorRegisterValidation =>
      'Thông tin đăng ký chưa hợp lệ hoặc email đã được sử dụng.';

  @override
  String get authErrorVerifyValidation =>
      'Mã xác thực không hợp lệ, đã hết hạn hoặc đã được sử dụng.';

  @override
  String get authErrorResendValidation =>
      'Không thể gửi lại mã cho email này. Vui lòng kiểm tra và thử lại.';

  @override
  String get authErrorResendRateLimited =>
      'Bạn đã yêu cầu gửi lại mã quá nhiều lần. Vui lòng thử lại sau.';

  @override
  String get authErrorUpdateEmailValidation =>
      'Email mới chưa hợp lệ hoặc đã được sử dụng.';

  @override
  String get authErrorChangePasswordValidation =>
      'Mật khẩu hiện tại không đúng hoặc mật khẩu mới chưa hợp lệ.';

  @override
  String get authErrorRecoveryValidation =>
      'Email chưa hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get authErrorServer =>
      'RikiPath đang gặp sự cố. Vui lòng thử lại sau ít phút.';

  @override
  String get authErrorUnknown => 'Đã có lỗi ngoài dự kiến. Vui lòng thử lại.';

  @override
  String get authErrorVerifyMissingUserId =>
      'RikiPath chưa nhận đủ thông tin tài khoản cần thiết để xác thực email.';

  @override
  String get authErrorResendMissingEmail =>
      'RikiPath chưa nhận được email cần gửi lại mã xác thực.';

  @override
  String get authErrorSessionMissingUserId =>
      'Phiên hiện tại thiếu thông tin tài khoản cần thiết. Vui lòng đăng nhập lại.';

  @override
  String get profileTitle => 'Cá nhân';

  @override
  String get learner => 'Học viên';

  @override
  String get currentGoal => 'Mục tiêu hiện tại';

  @override
  String get learningStatistics => 'Thống kê học tập';

  @override
  String get latestScore => 'Điểm gần nhất';

  @override
  String get progressAndHistory => 'Tiến độ & lịch sử học';

  @override
  String get consultation => 'Tư vấn 1-1';

  @override
  String get settings => 'Cài đặt';

  @override
  String get languageSettings => 'Ngôn ngữ';

  @override
  String get emailVerifiedMessage =>
      'Email của bạn đã được xác thực trên RikiPath.';

  @override
  String get verifyEmailInputSubtitle =>
      'Nhập mã được gửi tới email của bạn để hoàn tất xác thực.';

  @override
  String get verifyEmailBlockedTitle => 'Chưa thể tiếp tục từ đăng ký';

  @override
  String get verifyEmailBlockedMessage =>
      'RikiPath chưa nhận đủ thông tin tài khoản để gửi mã xác thực một cách an toàn.';

  @override
  String get verificationCodeValidity =>
      'Mã gồm 6 chữ số và có hiệu lực trong 30 phút.';

  @override
  String get verifyEmailFailedTitle => 'Không thể xác thực email';

  @override
  String get verifiedPrompt => 'Đã xác thực?';

  @override
  String forgotPasswordSentBody(String email) {
    return 'Chúng tôi đã gửi hướng dẫn lấy lại mật khẩu tới $email.';
  }

  @override
  String get forgotPasswordCheckEmail =>
      'Vui lòng kiểm tra email để tiếp tục đặt lại mật khẩu.';

  @override
  String get forgotPasswordSpamHint =>
      'Nếu không thấy email trong Hộp thư đến, vui lòng kiểm tra Thư rác hoặc Spam.';

  @override
  String get forgotPasswordResend => 'Không nhận được thư? Gửi lại (58s)';

  @override
  String get helpDirectPrefix => 'Cần trợ giúp trực tiếp?';

  @override
  String get helpSensei => 'Liên hệ Sensei hỗ trợ';

  @override
  String get helpAccountPrefix => 'Cần hỗ trợ về tài khoản?';

  @override
  String get helpCenter => 'Trung tâm trợ giúp';

  @override
  String get newLoginEmailTitle => 'Email đăng nhập mới';

  @override
  String get newLoginEmailSubtitle =>
      'Sau khi cập nhật, máy chủ sẽ gửi mã xác thực tới email mới.';

  @override
  String get missingSessionTitle => 'Thiếu thông tin phiên';

  @override
  String get missingSessionMessage =>
      'Phiên đăng nhập hiện tại thiếu thông tin cần thiết. Vui lòng đăng xuất rồi đăng nhập lại.';

  @override
  String get changeEmailFailedTitle => 'Không thể đổi email';

  @override
  String get emailUpdatedVerificationMessage =>
      'Email đã được cập nhật. Hãy nhập mã được gửi tới email mới.';

  @override
  String get enterVerificationCode => 'Nhập mã xác thực';

  @override
  String get protectAccountTitle => 'Bảo vệ tài khoản';

  @override
  String get passwordContractHint =>
      'Mật khẩu mới phải có ít nhất 6 ký tự theo hợp đồng hiện tại.';

  @override
  String get currentPasswordHint => 'Nhập mật khẩu hiện tại';

  @override
  String get newPasswordHint => 'Nhập mật khẩu mới';

  @override
  String get confirmNewPasswordHint => 'Nhập lại mật khẩu mới';

  @override
  String get changePasswordFailedTitle => 'Không thể đổi mật khẩu';

  @override
  String get passwordUpdatedSessionMessage =>
      'Mật khẩu đã được cập nhật. Phiên đăng nhập hiện tại vẫn được giữ.';

  @override
  String dayCount(int count) {
    return 'Ngày $count';
  }

  @override
  String get notifications => 'Thông báo';

  @override
  String get openProfile => 'Mở trang cá nhân';

  @override
  String get homeToolsTitle => 'Làm quen với công cụ học tập';

  @override
  String get homeLoadFailed => 'Chưa thể tải Trang chủ';

  @override
  String get checkConnectionRetry => 'Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String greetingName(String name) {
    return 'Xin chào, $name!';
  }

  @override
  String jlptGoal(String level) {
    return 'Mục tiêu JLPT $level';
  }

  @override
  String get notStarted => 'Chưa bắt đầu';

  @override
  String lessonPartsCompleted(int completed, int total) {
    return ' • $completed/$total phần hoàn thành';
  }

  @override
  String lessonProgressSemantics(int percentage) {
    return 'Tiến độ bài học $percentage phần trăm';
  }

  @override
  String get startLearning => 'Bắt đầu học';

  @override
  String stageCount(int count) {
    return '$count chặng';
  }

  @override
  String get personalizedByAbility => 'Được cá nhân hóa theo năng lực';

  @override
  String get viewRoadmap => 'Xem lộ trình';

  @override
  String get initialSetup => 'Thiết lập ban đầu';

  @override
  String get initialSetupSubtitle => 'Các bước khởi đầu cho người mới';

  @override
  String completedCount(int completed, int total) {
    return '$completed/$total hoàn tất';
  }

  @override
  String get leaveSetup => 'Rời thiết lập';

  @override
  String get onboardingPlacementChoiceTitle => 'Chọn cách bắt đầu học';

  @override
  String get onboardingPlacementChoiceDescription =>
      'Bài đánh giá là tùy chọn. Bạn có thể bỏ qua và tự chọn cấp độ đang học.';

  @override
  String get onboardingSkipPlacement => 'Bỏ qua bài đánh giá';

  @override
  String get onboardingStudyLevelsTitle => 'Chọn cấp độ và mục tiêu';

  @override
  String get onboardingStudyLevelsDescription =>
      'Hãy cho RikiPath biết trình độ hiện tại và mục tiêu bạn muốn đạt được.';

  @override
  String get onboardingCurrentStudyLevelTitle => 'Cấp độ bạn đang học';

  @override
  String get onboardingCurrentStudyLevelDescription =>
      'Lộ trình chuẩn hiện hỗ trợ từ N5 đến N3.';

  @override
  String get onboardingTargetJlptTitle => 'Mục tiêu JLPT';

  @override
  String get onboardingTargetJlptDescription =>
      'Mục tiêu thi độc lập với cấp độ bạn đang học.';

  @override
  String get onboardingPlacementCanTakeLater =>
      'Bạn vẫn có thể làm bài đánh giá sau trong Hồ sơ.';

  @override
  String get standardRoadmapTitle => 'Lộ trình học chuẩn';

  @override
  String standardRoadmapProgress(int completed, int total) {
    return 'Tiến độ chuẩn: $completed/$total bài';
  }

  @override
  String get standardRoadmapNextLesson => 'Bài tiếp theo';

  @override
  String get aiPersonalizedPathTitle => 'Lộ trình cá nhân hóa bằng AI';

  @override
  String get aiPlacementRequired =>
      'Hoàn thành bài Placement để mở khóa tạo lộ trình AI. Bạn vẫn có thể tiếp tục học theo lộ trình chuẩn.';

  @override
  String get aiLearningGoalRequired =>
      'Placement đã hoàn tất. Hãy lưu mục tiêu JLPT và thông tin học tập hợp lệ để tạo lộ trình AI.';

  @override
  String get changeStudyLevelTitle => 'Đổi cấp độ đang học?';

  @override
  String get changeStudyLevelConfirmation =>
      'Cấp độ lộ trình chuẩn sẽ được cập nhật. Mục tiêu JLPT, ngày thi, thời lượng học, tiến độ và lịch sử vẫn được giữ nguyên.';

  @override
  String get onboardingJlptTitle => 'Mục tiêu JLPT của bạn là gì?';

  @override
  String get onboardingJlptDescription =>
      'Chọn trình độ bạn muốn hướng tới để RikiPath cá nhân hóa lộ trình học.';

  @override
  String get popular => 'Phổ biến';

  @override
  String get mostPopular => 'Phổ biến nhất';

  @override
  String get onboardingJlptHelper => 'Chọn một cấp độ JLPT để tiếp tục.';

  @override
  String get jlptCatalogLoadFailed => 'Không thể tải danh mục cấp độ JLPT.';

  @override
  String get jlptCatalogEmpty => 'Hiện chưa có cấp độ JLPT khả dụng.';

  @override
  String get learningLessonsEmptyTitle => 'Chưa có bài học khả dụng';

  @override
  String get learningLessonsEmptyMessage =>
      'Hiện chưa có bài học cho cấp độ JLPT này. Hãy thử lại sau.';

  @override
  String get jlptN5Description => 'Nền tảng tiếng Nhật cơ bản';

  @override
  String get jlptN4Description => 'Củng cố kiến thức sơ – trung cấp';

  @override
  String get jlptN3Description => 'Hướng tới trình độ trung cấp';

  @override
  String get jlptN2Description => 'Phát triển năng lực tiếng Nhật nâng cao';

  @override
  String get jlptN1Description => 'Hướng tới năng lực tiếng Nhật chuyên sâu';

  @override
  String get backToGoalSelection => 'Quay lại bước chọn mục tiêu';

  @override
  String get onboardingStudyTimeTitle => 'Thiết lập kế hoạch học tập';

  @override
  String get onboardingStudyTimeDescription =>
      'Chọn thời lượng học phù hợp với lịch sinh hoạt của bạn.';

  @override
  String get onboardingCustomMinutesLabel => 'Số phút khác mỗi ngày';

  @override
  String get onboardingCustomMinutesHelper =>
      'Từ 1 đến 1.440 phút theo giới hạn hồ sơ.';

  @override
  String get onboardingCustomMinutesError =>
      'Vui lòng nhập từ 1 đến 1.440 phút.';

  @override
  String studyMinutesPerDay(int minutes) {
    return '$minutes phút/ngày';
  }

  @override
  String get studyPaceGentle => 'Nhẹ nhàng';

  @override
  String get studyPaceBalanced => 'Cân bằng';

  @override
  String get studyPaceActive => 'Tích cực';

  @override
  String get studyPaceIntensive => 'Chuyên sâu';

  @override
  String get finishSetup => 'Hoàn tất thiết lập';

  @override
  String get onboardingAdjustHelper =>
      'Bạn có thể quay lại để điều chỉnh các lựa chọn.';

  @override
  String get setupCompleteStatus => 'Thiết lập hoàn tất';

  @override
  String get readyToStart => 'Sẵn sàng bắt đầu!';

  @override
  String get learningPlanReady =>
      'Mục tiêu học tập của bạn đã được lưu thành công.';

  @override
  String studySummary(int minutes, String description) {
    return '$minutes phút/ngày · $description';
  }

  @override
  String get goalPrefix => 'Mục tiêu:';

  @override
  String stepOfTwo(int step) {
    return 'Bước $step / 2';
  }

  @override
  String setupProgressSemantics(int step) {
    return 'Tiến độ thiết lập: bước $step trên 2';
  }

  @override
  String get setupCompleteSemantics => 'Thiết lập lộ trình hoàn tất';

  @override
  String get mockTestTitle => 'Thi thử JLPT';

  @override
  String get mockTestSubtitle =>
      'Mô phỏng cấu trúc từ vựng/ngữ pháp, đọc và nghe';

  @override
  String get notAttempted => 'Chưa làm';

  @override
  String get latestResult => 'Kết quả gần nhất';

  @override
  String get view => 'Xem';

  @override
  String get aiGrading => 'Chấm bài AI';

  @override
  String get writingAndKanjiPractice => 'Luyện viết & Kanji';

  @override
  String get library => 'THƯ VIỆN';

  @override
  String get vocabulary => 'Từ vựng';

  @override
  String get vocabularyDetail => 'Chi tiết từ vựng';

  @override
  String get vocabularyAudioFailed => 'Không thể phát âm thanh từ vựng.';

  @override
  String get chooseNotebook => 'Chọn Sổ từ';

  @override
  String wordCount(int count) {
    return '$count từ';
  }

  @override
  String savedToCollection(String name) {
    return 'Đã lưu vào $name.';
  }

  @override
  String get vocabularySearchHint =>
      'Tìm từ tiếng Nhật, cách đọc hoặc nghĩa...';

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get illustrationData => 'Nội dung bổ sung';

  @override
  String get saved => 'Đã lưu';

  @override
  String get audioUnavailable => 'Chưa có âm thanh';

  @override
  String get listenPronunciation => 'Nghe phát âm';

  @override
  String get loadMore => 'Tải thêm';

  @override
  String get vocabularyEmptyTitle => 'Không tìm thấy từ vựng';

  @override
  String get vocabularyEmptyMessage => 'Thử từ khóa khác hoặc bỏ bộ lọc JLPT.';

  @override
  String get vocabularyLoadFailed => 'Chưa thể tải thư viện từ vựng';

  @override
  String get localFixtureNotice =>
      'Nội dung bổ sung bên dưới được lưu sẵn trên thiết bị.';

  @override
  String get meaning => 'Ý nghĩa';

  @override
  String get examples => 'Ví dụ';

  @override
  String get usageNuance => 'Sắc thái sử dụng';

  @override
  String get commonCollocations => 'Cụm từ thường gặp';

  @override
  String get kanjiAnalysis => 'Phân tích Kanji';

  @override
  String get relatedLessons => 'Bài học liên quan';

  @override
  String get wordAlreadySaved => 'Từ này đã được lưu.';

  @override
  String get personalNotebook => 'Sổ từ cá nhân';

  @override
  String get saveWordDescription =>
      'Lưu từ này để ôn tập trong danh sách của bạn.';

  @override
  String get saveToNotebook => 'Lưu vào Sổ từ';

  @override
  String get processing => 'Đang xử lý...';

  @override
  String get kanjiDetail => 'Chi tiết Kanji';

  @override
  String get strokeOrder => 'Thứ tự nét viết';

  @override
  String get kanjiAudioFailed => 'Không thể phát âm thanh Kanji.';

  @override
  String itemCount(int count) {
    return '$count mục';
  }

  @override
  String get kanjiSearchHint => 'Tìm theo Kanji hoặc ý nghĩa';

  @override
  String get search => 'Tìm kiếm';

  @override
  String kanjiCount(int count) {
    return '$count Kanji';
  }

  @override
  String get sampleData => 'Nội dung bổ sung';

  @override
  String get showMore => 'Xem thêm';

  @override
  String strokeCount(int count) {
    return '$count nét';
  }

  @override
  String get onReading => 'Âm On';

  @override
  String get kunReading => 'Âm Kun';

  @override
  String get listenReading => 'Nghe cách đọc';

  @override
  String get kanjiEmptyTitle => 'Không tìm thấy Kanji';

  @override
  String get kanjiLoadFailed => 'Chưa thể tải thư viện Kanji';

  @override
  String get memoryTip => 'Mẹo ghi nhớ';

  @override
  String get commonCompounds => 'Từ ghép thường gặp';

  @override
  String get savedToNotebook => 'Đã lưu vào Sổ từ';

  @override
  String radicalLabel(String radical) {
    return 'Bộ $radical';
  }

  @override
  String get stitchFixtureNotice =>
      'Nội dung bổ sung được lưu sẵn trên thiết bị.';

  @override
  String get reading => 'Cách đọc';

  @override
  String get noData => 'Chưa có dữ liệu';

  @override
  String get viewStrokeOrder => 'Xem chi tiết thứ tự nét';

  @override
  String get sampleBadge => 'BỔ SUNG';

  @override
  String strokeProgress(int current, int total) {
    return 'Nét $current/$total';
  }

  @override
  String get restartStroke => 'Phát lại từ đầu';

  @override
  String get previousStroke => 'Nét trước';

  @override
  String get nextStroke => 'Nét tiếp theo';

  @override
  String get strokeProgressTitle => 'Tiến trình từng nét';

  @override
  String strokeNumber(int number) {
    return 'Nét $number';
  }

  @override
  String get strokeRules => 'Quy tắc bút thuận';

  @override
  String get strokeFixtureWarning =>
      'Phần minh họa nét viết này được cung cấp để bạn tham khảo.';

  @override
  String get strokeImageOnlyWarning =>
      'Hiện chỉ có ảnh thứ tự nét; chưa hỗ trợ phát từng nét.';

  @override
  String backToKanjiDetail(String character) {
    return 'Quay lại chi tiết chữ $character';
  }

  @override
  String get grammar => 'Ngữ pháp';

  @override
  String get grammarDetail => 'Chi tiết ngữ pháp';

  @override
  String get grammarSearchHint => 'Tìm cấu trúc ngữ pháp hoặc ý nghĩa…';

  @override
  String grammarPatternCount(int count) {
    return '$count cấu trúc';
  }

  @override
  String grammarStructureInline(String structure) {
    return 'Cấu trúc: $structure';
  }

  @override
  String get grammarEmptyTitle => 'Không tìm thấy ngữ pháp';

  @override
  String get grammarLoadFailed => 'Chưa thể tải thư viện ngữ pháp';

  @override
  String get grammarMeaningNature => 'Ý nghĩa & bản chất';

  @override
  String get grammarStructure => 'Cấu trúc ngữ pháp';

  @override
  String get usage => 'Cách sử dụng';

  @override
  String get grammarFixtureNotice =>
      'Nội dung giải thích bổ sung được lưu sẵn trên thiết bị.';

  @override
  String get practicalExamples => 'Ví dụ thực tế';

  @override
  String get usageCautions => 'Lưu ý khi dùng';

  @override
  String get relatedGrammar => 'Ngữ pháp liên quan & phân biệt';

  @override
  String get collectionCreated => 'Đã tạo danh sách mới.';

  @override
  String get wordAddedToNotebook => 'Đã thêm từ vào Sổ từ.';

  @override
  String get removeFromNotebookQuestion => 'Xóa khỏi Sổ từ?';

  @override
  String removeEntryMessage(String term) {
    return '“$term” sẽ bị xóa khỏi danh sách và hàng đợi ôn tập liên kết.';
  }

  @override
  String get delete => 'Xóa';

  @override
  String get removedFromNotebook => 'Đã xóa khỏi Sổ từ.';

  @override
  String get createCollection => 'Tạo danh sách mới';

  @override
  String get collectionNameRequiredLabel => 'Tên danh sách *';

  @override
  String get collectionNameRequired => 'Vui lòng nhập tên danh sách.';

  @override
  String get optionalDescription => 'Mô tả (tùy chọn)';

  @override
  String get createCollectionAction => 'Tạo danh sách';

  @override
  String get addNewWord => 'Thêm từ mới';

  @override
  String get notebookApiFieldsHint =>
      'Nhập từ, cách đọc, ý nghĩa và ghi chú bạn muốn lưu.';

  @override
  String get japaneseWordRequiredLabel => 'Từ tiếng Nhật *';

  @override
  String get wordRequired => 'Vui lòng nhập từ cần lưu.';

  @override
  String get optionalReading => 'Cách đọc (tùy chọn)';

  @override
  String get meaningRequiredLabel => 'Nghĩa tiếng Việt *';

  @override
  String get meaningRequired => 'Vui lòng nhập nghĩa của từ.';

  @override
  String get optionalPersonalNote => 'Ghi chú cá nhân (tùy chọn)';

  @override
  String get yourCollections => 'Bộ sưu tập của bạn';

  @override
  String get collectionSearchHint => 'Tìm bộ sưu tập…';

  @override
  String get noMatchingCollection => 'Không tìm thấy bộ sưu tập phù hợp';

  @override
  String get collectionSearchEmptyMessage =>
      'Thử từ khóa khác hoặc xóa tìm kiếm hiện tại.';

  @override
  String openCollection(String name) {
    return 'Mở bộ sưu tập $name';
  }

  @override
  String get notebookCollectionUnavailable =>
      'Bộ sưu tập này không còn khả dụng.';

  @override
  String get notebookSearchHint => 'Tìm Kanji, Kana hoặc nghĩa…';

  @override
  String get savedWords => 'Từ đã lưu';

  @override
  String savedItemCount(int count) {
    return '$count mục đã lưu';
  }

  @override
  String personalCollectionCount(int count) {
    return '$count danh sách cá nhân';
  }

  @override
  String openWordDetail(String term) {
    return 'Mở chi tiết từ $term';
  }

  @override
  String get removeFromNotebook => 'Xóa khỏi Sổ từ';

  @override
  String get detail => 'Chi tiết';

  @override
  String get personalWord => 'Từ cá nhân';

  @override
  String get savedItem => 'Mục đã lưu';

  @override
  String get personalNoteLabel => 'Ghi chú cá nhân';

  @override
  String get addedToNotebookLabel => 'Đã thêm vào Sổ từ';

  @override
  String get notebookEmptyTitle => 'Sổ từ của bạn đang trống';

  @override
  String get notebookEmptyMessage => 'Tạo danh sách đầu tiên để lưu từ vựng.';

  @override
  String get noMatchingWord => 'Không tìm thấy từ phù hợp';

  @override
  String get collectionHasNoWords => 'Danh sách chưa có từ nào';

  @override
  String get notebookSearchEmptyMessage =>
      'Thử từ khóa khác hoặc xóa tìm kiếm hiện tại.';

  @override
  String get notebookCollectionEmptyMessage =>
      'Thêm từ đầu tiên để bắt đầu ôn tập.';

  @override
  String get notebookLoadFailed => 'Không thể tải Sổ từ';

  @override
  String get checkConnectionShort => 'Kiểm tra kết nối rồi thử lại.';

  @override
  String get loadingRoadmap => 'Đang tải lộ trình';

  @override
  String get generateLearningPath => 'Tạo lộ trình cá nhân hóa';

  @override
  String get regenerateLearningPath => 'Tạo lại lộ trình';

  @override
  String get generatingLearningPath => 'Đang tạo lộ trình cá nhân hóa…';

  @override
  String get recommendedLearningPathTitle => 'Lộ trình đề xuất';

  @override
  String get learningPathRequirements =>
      'Để tạo lộ trình cá nhân hóa bằng AI, hãy hoàn thành bài đánh giá đầu vào và thiết lập mục tiêu JLPT. Bạn vẫn có thể học theo lộ trình chuẩn mà không cần đánh giá.';

  @override
  String get learningPathGenerateFailed =>
      'Chưa thể tạo lộ trình cá nhân hóa. Vui lòng thử lại.';

  @override
  String learningPathDay(int day) {
    return 'Ngày $day';
  }

  @override
  String learningPathLessonCount(int count) {
    return '$count bài học';
  }

  @override
  String get recommendedNextLessonAction => 'Học bài được đề xuất tiếp theo';

  @override
  String get lessonAttachment => 'Mở tài liệu đính kèm';

  @override
  String get openAttachmentFailed => 'Không thể mở tài liệu đính kèm.';

  @override
  String roadmapSummary(int chapters, int lessons) {
    return '$chapters chương • $lessons bài học';
  }

  @override
  String jlptRoadmap(String level) {
    return 'Lộ trình JLPT$level';
  }

  @override
  String jlptProgress(String level) {
    return 'Tiến độ JLPT$level';
  }

  @override
  String get fiveSkillBreakdown => 'Chi tiết phân bổ 5 kỹ năng';

  @override
  String get lesson => 'Bài học';

  @override
  String get completeLesson => 'Hoàn thành bài học';

  @override
  String lessonNumber(int number) {
    return 'Bài $number';
  }

  @override
  String get loadingContent => 'Đang tải nội dung';

  @override
  String chapterLessonSummary(int chapter, String category, String level) {
    return 'Chương $chapter • $category $level';
  }

  @override
  String dayShort(int count) {
    return '$count ngày';
  }

  @override
  String get mainLearningSections => 'Các phần học chính';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get roadmap => 'Lộ trình';

  @override
  String get lessonPlural => 'Bài học';

  @override
  String get overallProgressUpper => 'TIẾN ĐỘ TỔNG';

  @override
  String overallProgressSemantics(int percentage) {
    return 'Tiến độ tổng $percentage phần trăm';
  }

  @override
  String completedLessons(int completed, int total) {
    return 'Đã hoàn thành $completed/$total bài học';
  }

  @override
  String studyStreak(int days) {
    return 'Chuỗi học: $days ngày';
  }

  @override
  String get continueRoadmap => 'Tiếp tục lộ trình';

  @override
  String get inProgressUpper => 'ĐANG HỌC DỞ';

  @override
  String chapterAndLesson(int chapter, int lesson) {
    return 'Chương $chapter • Bài $lesson';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get continueLearning => 'Học tiếp';

  @override
  String get learningLoadFailed => 'Chưa thể tải nội dung học tập';

  @override
  String get continueStudy => 'Tiếp tục học';

  @override
  String get viewDetailedRoadmap => 'Xem lộ trình chi tiết';

  @override
  String targetLevel(String level) {
    return 'Cấp độ mục tiêu: $level';
  }

  @override
  String get courseOverallProgress => 'Tổng tiến độ toàn khóa';

  @override
  String courseProgressSemantics(int percentage) {
    return 'Tổng tiến độ toàn khóa $percentage phần trăm';
  }

  @override
  String completedOverallLessons(int completed, int total) {
    return 'Đã hoàn thành $completed/$total bài học tổng thể';
  }

  @override
  String expectedExam(String date) {
    return 'Kỳ thi dự kiến: $date';
  }

  @override
  String get skillProgressDetail => 'Chi tiết tiến độ kỹ năng';

  @override
  String skillCount(int count) {
    return '$count/5 kỹ năng';
  }

  @override
  String progressSemantics(String category, int percentage) {
    return 'Tiến độ $category $percentage phần trăm';
  }

  @override
  String get overallProgressTitle => 'TIẾN ĐỘ TỔNG THỂ';

  @override
  String get onTrack => 'Đang đúng tiến độ';

  @override
  String completedChapters(int completed, int total) {
    return 'Đã hoàn thành $completed/$total chương học';
  }

  @override
  String achievedLessons(int completed, int total) {
    return '$completed / $total bài đã đạt';
  }

  @override
  String get reviewResults => 'Xem lại kết quả';

  @override
  String get continueLessonNineteen => 'Học tiếp: Bài 19 – 〜たり〜たりする';

  @override
  String chapterNumberUpper(int number) {
    return 'CHƯƠNG $number';
  }

  @override
  String lessonRange(int first, int last) {
    return '• Bài $first – Bài $last';
  }

  @override
  String get skillsAchievedUpper => 'KỸ NĂNG ĐẠT CHUẨN:';

  @override
  String get fiveSkillProgressUpper => 'TIẾN ĐỘ 5 KỸ NĂNG:';

  @override
  String lessonCountUpper(int completed, int total) {
    return '$completed/$total BÀI HỌC';
  }

  @override
  String get statusCompleted => 'Hoàn thành';

  @override
  String get statusLearning => 'Đang học';

  @override
  String get statusReady => 'Sẵn sàng';

  @override
  String get statusNotStarted => 'Chưa bắt đầu';

  @override
  String lessonContentCount(int count) {
    return 'Nội dung bài học ($count phần)';
  }

  @override
  String totalDuration(int minutes) {
    return 'Tổng thời lượng ~${minutes}m';
  }

  @override
  String get focusVocabulary => 'Từ vựng trọng tâm trong bài';

  @override
  String vocabularyCount(int count) {
    return '$count từ vựng';
  }

  @override
  String get relatedGrammarShort => 'Ngữ pháp liên quan';

  @override
  String continueLessonProgress(int percentage) {
    return 'Tiếp tục bài học ($percentage%)';
  }

  @override
  String get startLesson => 'Bắt đầu bài học';

  @override
  String get focusLabel => 'Trọng tâm:';

  @override
  String partProgress(int current, int total) {
    return 'Phần $current / $total';
  }

  @override
  String get lessonObjective => 'Mục tiêu bài học';

  @override
  String streakMotivation(int days) {
    return 'Chuỗi $days ngày bền bỉ';
  }

  @override
  String get keepStreakMessage => 'Hoàn thành bài này để giữ lửa streak!';

  @override
  String get done => 'Đã xong';

  @override
  String get videoLoadFailed => 'Không thể tải video bài giảng';

  @override
  String get watchingInProgress => 'Đang xem dở';

  @override
  String get hdLecture => 'Bài giảng HD';

  @override
  String get pauseVideo => 'Tạm dừng video';

  @override
  String resumeVideoFrom(String time) {
    return 'Tiếp tục video từ $time';
  }

  @override
  String get articleFallbackMessage =>
      'Bạn vẫn có thể học tiếp bằng phần tóm tắt bên dưới.';

  @override
  String get viewArticle => 'Xem bản chữ';

  @override
  String get contentTab => 'Nội dung';

  @override
  String notesTab(int count) {
    return 'Ghi chú ($count)';
  }

  @override
  String vocabularyTab(int count) {
    return 'Từ vựng ($count)';
  }

  @override
  String get coreStructure => 'Cấu trúc cốt lõi';

  @override
  String get usageAndContext => 'Cách sử dụng & Ngữ cảnh';

  @override
  String get practicalExamplesTitle => 'Các ví dụ thực tế tiêu biểu';

  @override
  String get importantGrammarNotes => 'Lưu ý ngữ pháp quan trọng';

  @override
  String get importantVocabulary => 'Từ vựng quan trọng trong bài';

  @override
  String wordsAppearing(int count) {
    return '$count từ xuất hiện';
  }

  @override
  String topicUpper(String category) {
    return 'CHUYÊN ĐỀ $category';
  }

  @override
  String get topicSubtitle => 'Liệt kê hành động và trạng thái tiêu biểu';

  @override
  String get openLessonVideo => 'Mở video bài học';

  @override
  String get excellentCompletion => 'Xuất sắc hoàn thành';

  @override
  String get completionCongratulations => 'Chúc mừng bạn đã hoàn thành!';

  @override
  String lessonUpper(int number) {
    return 'BÀI $number';
  }

  @override
  String streakConsecutive(int days) {
    return 'Chuỗi học tập: $days ngày liên tiếp';
  }

  @override
  String get masteredContent => 'Nội dung bạn đã nắm vững';

  @override
  String masteredItemCount(int count) {
    return '$count/$count mục';
  }

  @override
  String nextLessonAction(int number) {
    return 'Học bài tiếp theo (Bài $number)';
  }

  @override
  String backToLevelRoadmap(String level) {
    return 'Quay lại Lộ trình học $level';
  }

  @override
  String get nextLessonInRoadmap => 'Bài học tiếp theo trong lộ trình';

  @override
  String get lockedContentUpper => 'NỘI DUNG CÓ KHÓA TIẾN TRÌNH';

  @override
  String get lessonLockedDefault => 'Bài học này chưa được mở.';

  @override
  String get unlockConditionUpper => 'ĐIỀU KIỆN MỞ KHÓA';

  @override
  String prerequisiteProgress(int completed, int total) {
    return 'Tiến độ: $completed/$total phần';
  }

  @override
  String remainingMinutes(int minutes) {
    return 'Còn ~$minutes phút';
  }

  @override
  String previewLesson(int number) {
    return 'Xem trước nội dung Bài $number';
  }

  @override
  String lessonPartsDuration(int parts, int minutes) {
    return '$parts phần học • ~$minutes phút';
  }

  @override
  String continuePrerequisite(int number, int remaining) {
    return 'Tiếp tục Bài $number (còn $remaining%)';
  }

  @override
  String get backToLearningRoadmap => 'Quay lại lộ trình học tập';

  @override
  String get lessonLoadFailed => 'Chưa thể tải bài học';

  @override
  String get lessonProgressTitle => 'Tiến độ bài học';

  @override
  String get completedUpper => '100% HOÀN THÀNH';

  @override
  String learningProgressValue(int percentage) {
    return '$percentage% • Đang học';
  }

  @override
  String get notebookShort => 'Sổ từ';

  @override
  String get processingSemantics => 'Đang xử lý';

  @override
  String jlptLevelSemantics(String level) {
    return 'Trình độ JLPT $level';
  }

  @override
  String get vocabularyLoadMoreFailed =>
      'Không thể tải thêm từ vựng. Vui lòng thử lại.';

  @override
  String get fixtureDefaultNotebookName => 'Đã lưu từ bài học';

  @override
  String get notebookListsLoadFailed => 'Không thể tải danh sách Sổ từ.';

  @override
  String get vocabularySaveFailed => 'Không thể lưu từ vựng vào Sổ từ.';

  @override
  String get kanjiLoadMoreFailed =>
      'Không thể tải thêm Kanji. Vui lòng thử lại.';

  @override
  String get kanjiFixtureNotebookName => 'Đã lưu từ bài học';

  @override
  String get kanjiSaveFailed => 'Không thể lưu Kanji vào Sổ từ.';

  @override
  String get grammarLoadMoreFailed =>
      'Không thể tải thêm ngữ pháp. Vui lòng thử lại.';

  @override
  String get grammarBookmark => 'Đánh dấu ngữ pháp';

  @override
  String get grammarBookmarked => 'Đã đánh dấu ngữ pháp';

  @override
  String get grammarSaveFailed => 'Không thể đánh dấu ngữ pháp.';

  @override
  String get notebookEntriesLoadFailed =>
      'Không thể tải nội dung danh sách. Vui lòng thử lại.';

  @override
  String get notebookCreateFailed =>
      'Không thể tạo danh sách. Vui lòng thử lại.';

  @override
  String get notebookAddFailed =>
      'Không thể thêm từ vào Sổ từ. Vui lòng thử lại.';

  @override
  String get notebookRemoveFailed =>
      'Không thể xóa mục khỏi Sổ từ. Vui lòng thử lại.';

  @override
  String get notebookLocalRemoveFailed =>
      'Không thể cập nhật mục đã lưu trên thiết bị.';

  @override
  String get notebookLocalRestoreUnavailable =>
      'Dữ liệu đã lưu trên thiết bị tạm thời không khả dụng. Dữ liệu trực tuyến vẫn được giữ nguyên.';

  @override
  String get selectLiveCollectionForManualEntry =>
      'Hãy chọn một danh sách có thể đồng bộ để thêm mục thủ công.';

  @override
  String get notebookKanjiLabel => 'Kanji';

  @override
  String get wordAndMeaningRequired =>
      'Từ tiếng Nhật và nghĩa tiếng Việt là bắt buộc.';

  @override
  String grammarDetailSemantics(String title) {
    return 'Mở chi tiết ngữ pháp $title';
  }

  @override
  String kanjiDetailSemantics(String character) {
    return 'Mở chi tiết Kanji $character';
  }

  @override
  String get lessonDetailsComingSoon => 'Chi tiết bài học đang được hoàn thiện';

  @override
  String examDateLabel(String date) {
    return 'Kỳ thi $date';
  }

  @override
  String mockDurationStatus(int minutes, String status) {
    return '$minutes phút • $status';
  }

  @override
  String mockScoreReading(int score, int total, int percentage) {
    return '$score / $total • Đọc hiểu: $percentage%';
  }

  @override
  String get successSemantics => 'Thành công';

  @override
  String get skillVocabulary => 'Từ vựng';

  @override
  String get skillKanji => 'Kanji';

  @override
  String get skillGrammar => 'Ngữ pháp';

  @override
  String get skillReading => 'Đọc hiểu';

  @override
  String get skillListening => 'Nghe hiểu';

  @override
  String get unitWords => 'từ';

  @override
  String get unitCharacters => 'chữ';

  @override
  String get unitLessons => 'bài';

  @override
  String get writing => 'Viết';

  @override
  String mockTestName(String level, String number) {
    return 'Đề thi thử $level #$number';
  }

  @override
  String levelProgress(String level) {
    return 'Tiến độ $level';
  }

  @override
  String get streakMetric => 'Chuỗi học';

  @override
  String get authErrorEmailNotVerified =>
      'Vui lòng xác thực email trước khi đăng nhập.';

  @override
  String get profileLoading => 'Đang tải hồ sơ...';

  @override
  String get profileLoadFailedTitle => 'Chưa thể tải hồ sơ';

  @override
  String get profileLoadFailedMessage =>
      'Không thể tải dữ liệu hồ sơ lúc này. Vui lòng thử lại.';

  @override
  String get profileEdit => 'Chỉnh sửa hồ sơ';

  @override
  String get profileEditSubtitle => 'Cập nhật họ và tên hiển thị của bạn.';

  @override
  String get profileProgressSubtitle => 'Xem lộ trình và tiến độ JLPT của bạn.';

  @override
  String get profileSettingsSubtitle =>
      'Quản lý tài khoản, bảo mật và thông báo.';

  @override
  String get profileServicesSection => 'Dịch vụ';

  @override
  String get configure => 'Thiết lập';

  @override
  String get firstName => 'Tên';

  @override
  String get lastName => 'Họ';

  @override
  String get firstNameHint => 'Minh Anh';

  @override
  String get lastNameHint => 'Nguyễn';

  @override
  String get validationFirstNameRequired => 'Vui lòng nhập tên.';

  @override
  String get validationLastNameRequired => 'Vui lòng nhập họ.';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get savingChanges => 'Đang lưu...';

  @override
  String get profileUpdateSuccess => 'Hồ sơ đã được cập nhật.';

  @override
  String get profileUpdateFailed =>
      'Không thể cập nhật hồ sơ. Vui lòng thử lại.';

  @override
  String get learningProfile => 'Hồ sơ học tập';

  @override
  String get dailyStudyGoal => 'Mục tiêu mỗi ngày';

  @override
  String get notConfigured => 'Chưa thiết lập';

  @override
  String get emailVerification => 'Xác thực email';

  @override
  String get verified => 'Đã xác thực';

  @override
  String get unverified => 'Chưa xác thực';

  @override
  String get editAvatar => 'Đổi ảnh đại diện';

  @override
  String get chooseAvatar => 'Chọn ảnh từ thiết bị';

  @override
  String get confirmAvatarTitle => 'Cập nhật ảnh đại diện?';

  @override
  String get confirmAvatarMessage =>
      'Ảnh JPEG, PNG hoặc WEBP sẽ được tải lên hồ sơ của bạn.';

  @override
  String get confirmUpload => 'Tải ảnh lên';

  @override
  String get uploadingAvatar => 'Đang tải ảnh...';

  @override
  String get avatarUploadSuccess => 'Ảnh đại diện đã được cập nhật.';

  @override
  String get avatarUploadFailed =>
      'Không thể cập nhật ảnh đại diện. Vui lòng thử lại.';

  @override
  String get avatarUnsupportedType => 'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WEBP.';

  @override
  String get avatarTooLarge => 'Ảnh đại diện phải nhỏ hơn hoặc bằng 5MB.';

  @override
  String get avatarPickerFailed =>
      'Không thể mở thư viện ảnh trên thiết bị này.';

  @override
  String get notificationSettingsTitle => 'Cài đặt thông báo';

  @override
  String get notificationSettingsSubtitle =>
      'Các tùy chọn khả dụng sẽ được đồng bộ với tài khoản của bạn.';

  @override
  String get emailNotifications => 'Thông báo qua email';

  @override
  String get emailNotificationsDescription =>
      'Nhận cập nhật học tập qua email.';

  @override
  String get systemNotifications => 'Thông báo trong ứng dụng';

  @override
  String get systemNotificationsDescription =>
      'Nhận thông báo hệ thống của RikiPath.';

  @override
  String get notificationUpdateSuccess => 'Cài đặt thông báo đã được cập nhật.';

  @override
  String get notificationUpdateFailed =>
      'Không thể cập nhật cài đặt thông báo. Thay đổi chưa được lưu.';

  @override
  String get jlptGoalSettings => 'Mục tiêu JLPT';

  @override
  String get jlptGoalSettingsSubtitle =>
      'Xem mục tiêu JLPT và thời gian học mỗi ngày.';

  @override
  String get jlptGoalMappingUnavailableTitle => 'Chưa thể đổi mục tiêu JLPT';

  @override
  String get jlptGoalMappingUnavailableMessage =>
      'Chưa thể đồng bộ mục tiêu JLPT lúc này. Lựa chọn hiện tại của bạn vẫn được giữ nguyên.';

  @override
  String get currentJlptGoal => 'Mục tiêu hiện tại';

  @override
  String get currentDailyStudyTime => 'Thời gian học hiện tại';

  @override
  String get profileErrorUnauthorized =>
      'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.';

  @override
  String get profileErrorForbidden =>
      'Tài khoản này không có quyền truy cập hồ sơ học viên.';

  @override
  String get profileErrorNetwork =>
      'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.';

  @override
  String get profileErrorValidation =>
      'Dữ liệu hồ sơ chưa hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get profileErrorServer =>
      'Máy chủ chưa thể xử lý yêu cầu hồ sơ. Vui lòng thử lại sau.';

  @override
  String get profileErrorUnknown =>
      'Đã xảy ra lỗi khi xử lý hồ sơ. Vui lòng thử lại.';

  @override
  String get accountSecuritySection => 'BẢO MẬT';

  @override
  String get accountOptionsSection => 'TÙY CHỌN';

  @override
  String get accountSessionSection => 'PHIÊN';

  @override
  String get accountVerifiedTitle => 'Tài khoản đã được xác thực';

  @override
  String get accountUnverifiedTitle => 'Tài khoản chưa được xác thực';

  @override
  String get logoutConfirmationTitle => 'Bạn muốn đăng xuất?';

  @override
  String get logoutConfirmationMessage =>
      'Bạn sẽ cần đăng nhập lại để tiếp tục học trên thiết bị này.';

  @override
  String get logoutStay => 'Ở lại';

  @override
  String get logoutSuccessTitle => 'Đã đăng xuất';

  @override
  String get logoutFailureTitle =>
      'Không thể xóa phiên đăng nhập trên thiết bị. Vui lòng thử lại.';

  @override
  String get profileNameSection => 'THÔNG TIN HIỂN THỊ';

  @override
  String get notificationPreferencesSection => 'TÙY CHỌN THÔNG BÁO';

  @override
  String get currentEmailLabel => 'Email hiện tại';

  @override
  String get passwordRequirementsTitle => 'YÊU CẦU MẬT KHẨU';

  @override
  String get passwordMinimumRequirement => 'Mật khẩu mới có ít nhất 6 ký tự';

  @override
  String get jlptSelectionTitle => 'CHỌN MỤC TIÊU JLPT';

  @override
  String get dailyStudySelectionTitle => 'THỜI GIAN HỌC MỖI NGÀY';

  @override
  String get jlptSelectionSafeHint =>
      'Lựa chọn được lưu trên thiết bị này và bạn có thể thay đổi sau.';

  @override
  String get profileConsultationSubtitle =>
      'Khám phá các gói tư vấn và lịch hẹn của bạn.';

  @override
  String get savedFromLessons => 'Từ đã lưu trong bài học';

  @override
  String get localJlptPreferenceSaved => 'Đã lưu mục tiêu học trên thiết bị';

  @override
  String get dailyReviewTitle => 'Ôn tập hôm nay';

  @override
  String get reviewLoadingTitle => 'RikiPath đang chuẩn bị thẻ ôn tập...';

  @override
  String reviewProgress(int current, int total) {
    return '$current / $total thẻ';
  }

  @override
  String get reviewRecallPrompt => 'Bạn còn nhớ nội dung này không?';

  @override
  String get revealAnswer => 'Hiện đáp án';

  @override
  String get reviewAgain => 'Học lại';

  @override
  String get reviewHard => 'Khó';

  @override
  String get reviewGood => 'Tốt';

  @override
  String get reviewEasy => 'Dễ';

  @override
  String get reviewCompleteTitle => 'Hoàn thành phiên ôn tập';

  @override
  String reviewCompleteCount(int count) {
    return 'Bạn đã ôn $count thẻ trong phiên này.';
  }

  @override
  String reviewResponseCount(String label, int count) {
    return '$label: $count';
  }

  @override
  String get reviewAgainAction => 'Ôn lại phiên này';

  @override
  String get backToPractice => 'Quay lại Luyện tập';

  @override
  String get reviewQueueEmpty => 'Hôm nay chưa có thẻ cần ôn.';

  @override
  String get reviewLoadFailed => 'Chưa thể tải phiên ôn tập';

  @override
  String reviewDueCount(int count) {
    return '$count thẻ đang chờ bạn ôn lại';
  }

  @override
  String get mockLoadingTitle => 'RikiPath đang chuẩn bị đề thi...';

  @override
  String get mockLoadFailed => 'Chưa thể tải đề thi thử.';

  @override
  String get mockTestUnavailable => 'Đề thi thử này hiện không khả dụng.';

  @override
  String get mockTargetLevelRequired =>
      'Hãy chọn cấp độ mục tiêu trong hồ sơ để xem đề thi phù hợp.';

  @override
  String get mockNoTestsAvailable =>
      'Hiện chưa có đề thi thử được phát hành cho cấp độ mục tiêu của bạn.';

  @override
  String get leaveMockTitle => 'Rời khỏi bài thi?';

  @override
  String get leaveMockMessage =>
      'Các đáp án trong phiên hiện tại vẫn được giữ khi bạn quay lại.';

  @override
  String get continueAction => 'Tiếp tục làm bài';

  @override
  String get leaveAction => 'Rời bài thi';

  @override
  String get submitMockTitle => 'Nộp bài thi thử?';

  @override
  String get submitMockMessage =>
      'Bạn có thể nộp dù vẫn còn câu chưa trả lời. RikiPath sẽ chấm điểm và hoàn tất lượt thi.';

  @override
  String get submitAction => 'Nộp bài';

  @override
  String get mockStarting => 'Đang bắt đầu...';

  @override
  String get mockSubmitting => 'Đang nộp bài...';

  @override
  String mockMinutes(int minutes) {
    return 'Thời gian: $minutes phút';
  }

  @override
  String mockQuestionCount(int count) {
    return 'Số câu: $count';
  }

  @override
  String get mockLocalScoringNotice =>
      'Đề luyện tập được chấm trên thiết bị và không phải kết quả JLPT chính thức.';

  @override
  String get mockBackendScoringNotice =>
      'Thời gian và điểm số được xác định bởi hệ thống RikiPath.';

  @override
  String get mockMediaAvailable => 'Câu hỏi này có nội dung media từ đề thi.';

  @override
  String get mockActionFailed => 'Chưa thể hoàn tất thao tác';

  @override
  String get mockExpired =>
      'Lượt thi đã hết thời gian theo đồng hồ của hệ thống.';

  @override
  String get mockAlreadyCompleted => 'Lượt thi này đã được nộp trước đó.';

  @override
  String get mockNetworkUncertain =>
      'Kết nối bị gián đoạn nên chưa thể xác nhận trạng thái nộp bài. Hãy thử tải lại kết quả.';

  @override
  String get mockAttemptConflict =>
      'Dữ liệu lượt thi không còn hợp lệ. Hãy quay lại và bắt đầu một lượt mới.';

  @override
  String get mockValidationFailed =>
      'Hệ thống không chấp nhận dữ liệu bài làm. Vui lòng kiểm tra và thử lại.';

  @override
  String get mockSubmitFailed =>
      'Đã xảy ra lỗi khi xử lý lượt thi. Vui lòng thử lại.';

  @override
  String get startMockTest => 'Bắt đầu làm bài';

  @override
  String questionProgress(int current, int total) {
    return 'Câu $current / $total';
  }

  @override
  String get previousQuestion => 'Câu trước';

  @override
  String get nextQuestion => 'Câu tiếp';

  @override
  String get mockResultTitle => 'Kết quả thi thử';

  @override
  String get mockResultUnavailable => 'Chưa có kết quả cho đề thi này.';

  @override
  String mockCorrectCount(int correct, int total) {
    return 'Đúng $correct / $total câu';
  }

  @override
  String get mockLocalResultNotice =>
      'Kết quả này dùng để luyện tập và không phải điểm JLPT chính thức.';

  @override
  String get mockBackendResultNotice =>
      'Kết quả này được chấm và trả về từ hệ thống RikiPath.';

  @override
  String get sectionBreakdown => 'Kết quả theo phần';

  @override
  String mockSectionResult(int correct, int total, int percentage) {
    return '$correct/$total đúng • $percentage%';
  }

  @override
  String get detailedReview => 'Xem chi tiết đáp án';

  @override
  String get retakeMockTest => 'Làm lại đề';

  @override
  String questionNumber(int number) {
    return 'Câu $number';
  }

  @override
  String selectedAnswer(String answer) {
    return 'Bạn chọn: $answer';
  }

  @override
  String correctAnswer(String answer) {
    return 'Đáp án đúng: $answer';
  }

  @override
  String get notAnswered => 'Chưa trả lời';

  @override
  String get mockAnswerUnavailable => 'Không có dữ liệu';

  @override
  String get practiceLoadingTitle =>
      'RikiPath đang chuẩn bị nội dung luyện tập...';

  @override
  String get practiceJourneyTitle => 'Luyện tập theo nhịp của bạn';

  @override
  String get practiceJourneySubtitle =>
      'Thử sức với đề thi JLPT và theo dõi kết quả.';

  @override
  String mockSummary(String level, int minutes, int count) {
    return '$level • $minutes phút • $count câu';
  }

  @override
  String mockInProgress(int answered, int total) {
    return 'Đang làm $answered/$total câu';
  }

  @override
  String mockCompletedStatus(int percentage) {
    return 'Đã hoàn thành • $percentage%';
  }

  @override
  String get additionalPractice => 'Luyện tập bổ sung';

  @override
  String get aiWritingPractice => 'Luyện viết cùng AI';

  @override
  String get practiceAnswerLabel => 'Câu trả lời luyện tập';

  @override
  String get gradePractice => 'Chấm bài luyện tập';

  @override
  String get gradingPractice => 'Đang chấm...';

  @override
  String aiGradingResult(int score, String feedback) {
    return 'Điểm $score/100 • $feedback';
  }

  @override
  String get mentorConsultation => 'Tư vấn 1-1';

  @override
  String get openDemoBooking => 'Xem trước lịch học';

  @override
  String get confirmDemoBooking => 'Xác nhận xem trước';

  @override
  String get demoBookingConfirmed => 'Bạn đã hoàn tất phần xem trước lịch học.';

  @override
  String get practiceLoadFailed => 'Chưa thể tải nội dung luyện tập';

  @override
  String get learningAnalyticsTitle => 'Tiến độ học tập';

  @override
  String get analyticsLoadingTitle =>
      'RikiPath đang tổng hợp tiến độ của bạn...';

  @override
  String get analyticsEmpty => 'Chưa có dữ liệu học tập để hiển thị.';

  @override
  String get studyStreakLabel => 'Chuỗi ngày học';

  @override
  String streakDaysValue(int days) {
    return '$days ngày';
  }

  @override
  String get completedLessonsLabel => 'Bài đã học';

  @override
  String get weeklyActivityNoDailyData => 'Chưa có chi tiết học từng ngày';

  @override
  String analyticsPercentComplete(int percent) {
    return '$percent% hoàn thành';
  }

  @override
  String analyticsRemainingLessons(int remaining) {
    return 'Còn $remaining bài chưa hoàn thành';
  }

  @override
  String get analyticsNoLessons => 'Chưa có bài học trong lộ trình';

  @override
  String get analyticsInvalidProgress => 'Dữ liệu tiến độ cần được kiểm tra';

  @override
  String analyticsCompletedLessons(int completed, int total) {
    return '$completed / $total bài';
  }

  @override
  String get skillBreakdown => 'Tiến độ theo kỹ năng';

  @override
  String get analyticsSkillsEmpty => 'Chưa có dữ liệu kỹ năng.';

  @override
  String get analyticsSectionUnavailable =>
      'Phần dữ liệu này tạm thời chưa tải được.';

  @override
  String get analyticsLoadFailed => 'Chưa thể tải tiến độ học tập';

  @override
  String get markAllNotificationsRead => 'Đọc tất cả';

  @override
  String get notificationsEmpty => 'Chưa có thông báo trong ứng dụng.';

  @override
  String get notificationsLoadFailed => 'Chưa thể tải thông báo';

  @override
  String get notebookEntryTitle => 'Từ đã lưu';

  @override
  String get notebookEntryUnavailable => 'Mục đã lưu này không còn khả dụng.';

  @override
  String get homeChooseJlptTitle => 'Chọn mục tiêu JLPT để bắt đầu';

  @override
  String get homeChooseJlptDescription =>
      'RikiPath sẽ chuẩn bị lộ trình phù hợp sau khi bạn chọn N5, N4 hoặc N3.';

  @override
  String get homeChooseJlptAction => 'Chọn mục tiêu';

  @override
  String get homeContinueLearningTitle => 'Tiếp tục học';

  @override
  String homeCurrentLessonMeta(int lesson, int minutes) {
    return 'Bài $lesson • $minutes phút';
  }

  @override
  String get homeRoadmapProgressTitle => 'Tiến độ lộ trình';

  @override
  String get homeRoadmapProgressDescription =>
      'Tiến độ bài học được lưu trên thiết bị này.';

  @override
  String homeRoadmapProgressValue(int completed, int total, int percentage) {
    return '$completed/$total bài • $percentage%';
  }

  @override
  String get homeLiveProgressTitle => 'Thống kê học tập';

  @override
  String get homeLiveProgressDescription =>
      'Dữ liệu tổng hợp từ tài khoản RikiPath của bạn.';

  @override
  String get homeViewProgress => 'Xem tiến độ';

  @override
  String get homeAnalyticsUnavailable =>
      'Thống kê trực tuyến tạm thời chưa tải được.';

  @override
  String get homeReviewDescription => 'Ôn lại kiến thức theo nhịp học của bạn.';

  @override
  String get homeResumeReview => 'Tiếp tục ôn tập';

  @override
  String get homeReviewNow => 'Ôn tập ngay';

  @override
  String get homePracticeTitle => 'Luyện đề';

  @override
  String get homeStartPractice => 'Bắt đầu luyện tập';

  @override
  String get homeResumeMock => 'Tiếp tục đề thi thử';

  @override
  String get homeResumeMockDescription =>
      'Bài làm trên thiết bị vẫn đang được lưu.';

  @override
  String get homeRecentMockResult => 'Kết quả gần đây';

  @override
  String homeRecentMockScore(int score, int total, int percentage) {
    return 'Đúng $score/$total câu • $percentage%';
  }

  @override
  String get homeViewResult => 'Xem kết quả';

  @override
  String get homeNotebookShortcutTitle => 'Sổ từ cá nhân';

  @override
  String get homeNotebookShortcutDescription =>
      'Xem lại từ vựng và nội dung bạn đã lưu.';

  @override
  String get homeSectionUnavailable => 'Phần này tạm thời chưa tải được.';

  @override
  String get homeRefreshSemantics => 'Làm mới thống kê và thông báo';

  @override
  String get homeAlphabetShortcutTitle => 'Bảng chữ cái';

  @override
  String get homeAlphabetShortcutSubtitle => 'Hiragana • Katakana';

  @override
  String get homeGrammarShortcutTitle => 'Ngữ pháp';

  @override
  String get homeGrammarShortcutSubtitle => 'Từ cơ bản đến nâng cao';

  @override
  String get homeLearningCategories => 'Danh mục học tập';

  @override
  String get homeQuickStudy => 'Học tập';

  @override
  String get homeQuickVocabulary => 'Từ vựng';

  @override
  String get homeQuickGrammar => 'Ngữ pháp';

  @override
  String get homeQuickListening => 'Luyện nghe';

  @override
  String get homeDailyMotivation => 'Học mỗi ngày';

  @override
  String get homeDailyMotivationSubtitle =>
      'Mỗi ngày một chút, chạm mục tiêu JLPT.';

  @override
  String get homeTargetGoalTitle => 'Mục tiêu JLPT';

  @override
  String get commonErrorNetwork =>
      'Không thể kết nối tới RikiPath. Vui lòng kiểm tra mạng và thử lại.';

  @override
  String get commonErrorUnauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get commonErrorForbidden =>
      'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get commonErrorNotFound => 'Nội dung này không còn khả dụng.';

  @override
  String get commonErrorConflict =>
      'Dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.';

  @override
  String get commonErrorValidation =>
      'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get commonErrorServer =>
      'RikiPath đang gặp sự cố. Vui lòng thử lại sau.';

  @override
  String get commonErrorUnknown =>
      'Chưa thể hoàn tất thao tác. Vui lòng thử lại.';

  @override
  String get notificationsUpdateFailed => 'Chưa thể cập nhật thông báo';

  @override
  String get notificationsCountUnavailable =>
      'Số thông báo chưa đọc tạm thời chưa cập nhật.';

  @override
  String analyticsSkillScore(String score, int attempts) {
    return '$score% • $attempts lượt';
  }

  @override
  String get learnerMentorTitle => 'Tư vấn 1-1';

  @override
  String get learnerMentorSubtitle =>
      'Chọn gói và khung giờ phù hợp với hành trình học của bạn.';

  @override
  String get learnerMentorExplore => 'Khám phá';

  @override
  String get learnerMentorPlansTitle => 'Gói tư vấn';

  @override
  String get learnerMentorPlansEmpty => 'Hiện chưa có gói tư vấn khả dụng.';

  @override
  String get learnerMentorPlansError => 'Chưa thể tải các gói tư vấn.';

  @override
  String get learnerMentorMyMeetings => 'Lịch tư vấn của tôi';

  @override
  String learnerMentorPlanDuration(int days) {
    return 'Hiệu lực $days ngày';
  }

  @override
  String learnerMentorPlanSessions(int count) {
    return '$count vé tư vấn';
  }

  @override
  String get learnerMentorChoosePlan => 'Chọn gói';

  @override
  String get learnerMentorAvailabilityTitle => 'Chọn lịch tư vấn';

  @override
  String get learnerMentorAvailabilitySubtitle =>
      'Các khung giờ trống trong 30 ngày tới.';

  @override
  String get learnerMentorAvailabilityEmpty =>
      'Không có khung giờ trống trong ngày đã chọn.';

  @override
  String get learnerMentorAvailabilityError =>
      'Chưa thể tải lịch trống của cố vấn.';

  @override
  String get mentorFinderTitle => 'Tìm lịch tư vấn';

  @override
  String get mentorFinderChooseDate => 'Chọn ngày phù hợp với bạn';

  @override
  String get mentorFinderPickDate => 'Chọn ngày trên lịch';

  @override
  String get mentorFinderJlptLevel => 'Trình độ JLPT';

  @override
  String get mentorFinderChooseLevel =>
      'Chọn trình độ JLPT để xem lịch phù hợp.';

  @override
  String get mentorFinderNoSlotsTitle => 'Chưa có lịch tư vấn phù hợp';

  @override
  String get mentorFinderNoSlotsDescription =>
      'Hãy thử chọn ngày khác hoặc thay đổi bộ lọc.';

  @override
  String get mentorFinderChooseAnotherDate => 'Xem ngày khác';

  @override
  String get mentorFinderViewMyBookings => 'Xem lịch của tôi';

  @override
  String get mentorFinderBackToCalendar => 'Quay lại Lịch học';

  @override
  String get mentorFinderAvailableSlots => 'Khung giờ còn trống · 90 phút';

  @override
  String get mentorFinderCreditError =>
      'Không tải được số lượt tư vấn. Vui lòng thử lại.';

  @override
  String mentorFinderAvailableTickets(int count, String level) {
    return '$count lượt JLPT $level khả dụng';
  }

  @override
  String mentorFinderNeedCredit(String level) {
    return 'Bạn cần có lượt tư vấn JLPT $level để đặt lịch này.';
  }

  @override
  String get mentorFinderChooseSlot => 'Chọn khung giờ';

  @override
  String get mentorFinderReviewBooking => 'Xem và xác nhận đặt lịch';

  @override
  String get mentorFinderChoosePlan => 'Chọn gói tư vấn';

  @override
  String get mentorFinderNoPlans =>
      'Chưa có gói tư vấn phù hợp. Vui lòng tải lại danh sách gói.';

  @override
  String get mentorFinderPlansError =>
      'Không tải được các gói tư vấn. Vui lòng thử lại.';

  @override
  String mentorFinderPlanSummary(int count, int days) {
    return '$count lượt · $days ngày';
  }

  @override
  String get mentorFinderTimeAll => 'Tất cả giờ';

  @override
  String get mentorFinderTimeMorning => 'Buổi sáng';

  @override
  String get mentorFinderTimeAfternoon => 'Buổi chiều';

  @override
  String get mentorFinderTimeEvening => 'Buổi tối';

  @override
  String learnerMentorSlotTime(String start, String end) {
    return '$start – $end';
  }

  @override
  String get learnerMentorSelectSlot => 'Chọn khung giờ';

  @override
  String get learnerMentorPurchase => 'Tiếp tục thanh toán';

  @override
  String get learnerMentorPurchaseBlockedTitle => 'Đặt lịch đang tạm khóa';

  @override
  String get learnerMentorPurchaseBlocked =>
      'Bạn vẫn có thể xem gói và khung giờ trống. Tính năng thanh toán sẽ mở khi việc đặt lịch được bảo đảm an toàn.';

  @override
  String get learnerMentorBookingsEmpty => 'Bạn chưa có lịch tư vấn nào.';

  @override
  String get learnerMentorBookingsError => 'Chưa thể tải lịch tư vấn của bạn.';

  @override
  String get learnerMentorMeetingDetailTitle => 'Chi tiết buổi tư vấn';

  @override
  String get learnerMentorMeetingNotFound => 'Không tìm thấy buổi tư vấn này.';

  @override
  String get learnerMentorMentorLabel => 'Cố vấn';

  @override
  String get learnerMentorPaymentLabel => 'Thanh toán';

  @override
  String get learnerMentorJoin => 'Vào phòng tư vấn';

  @override
  String get learnerMentorJoinUnavailable =>
      'Phòng tư vấn chưa sẵn sàng hoặc liên kết không an toàn.';

  @override
  String get learnerMentorPurchaseStatus => 'Trạng thái gói tư vấn';

  @override
  String get learnerMentorPurchaseStatusError =>
      'Chưa thể tải trạng thái thanh toán.';

  @override
  String get learnerMentorPaymentPending => 'Đang chờ thanh toán';

  @override
  String get learnerMentorPaymentPaid => 'Đã thanh toán';

  @override
  String get learnerMentorPaymentFailed => 'Thanh toán thất bại';

  @override
  String get learnerMentorPaymentRefunded => 'Đã hoàn tiền';

  @override
  String get learnerMentorPaymentUnknown => 'Chưa xác định';

  @override
  String learnerMentorSessionsUsage(int used, int included) {
    return 'Đã dùng $used/$included vé tư vấn';
  }

  @override
  String get learnerMentorRefreshStatus => 'Kiểm tra lại trạng thái';

  @override
  String get learnerMentorStatusPolling =>
      'RikiPath đang kiểm tra trạng thái thanh toán. Việc quay lại ứng dụng không có nghĩa là thanh toán đã thành công.';

  @override
  String get learnerMentorUnknownMentor => 'Chưa xác định cố vấn';

  @override
  String get learnerMentorCheckoutExpired => 'Liên kết thanh toán đã hết hạn';

  @override
  String get learnerMentorBookingReadOnly =>
      'Thông tin lịch tư vấn được cập nhật từ RikiPath.';

  @override
  String get learnerMentorConfirmBookingTitle => 'Xác nhận đặt lịch tư vấn 1-1';

  @override
  String get learnerMentorConfirmPackage => 'Gói tư vấn';

  @override
  String get learnerMentorConfirmMentor => 'Cố vấn hỗ trợ';

  @override
  String get learnerMentorConfirmTime => 'Thời gian tư vấn dự kiến';

  @override
  String get learnerMentorConfirmPrice => 'Giá gói tư vấn';

  @override
  String get learnerMentorConfirmNote =>
      'Khung giờ đã chọn sẽ được xác nhận sau khi hoàn tất thanh toán.';

  @override
  String get learnerMentorPayWithPayOs => 'Tiếp tục thanh toán';

  @override
  String get learnerMentorOpenPayOs => 'Tiếp tục thanh toán';

  @override
  String get learnerMentorBookingSuccess => 'Đặt lịch thành công!';

  @override
  String get learnerMentorBookingSuccessDesc =>
      'Buổi tư vấn 1-1 với cố vấn đã được đặt thành công.';

  @override
  String get learnerMentorSlotConflict =>
      'Khung giờ này vừa có người đặt. Vé tư vấn của bạn vẫn được bảo lưu; vui lòng chọn khung giờ khác.';

  @override
  String get learnerMentorChooseAnotherSlot => 'Chọn khung giờ khác';

  @override
  String get learnerMentorViewBookingDetail => 'Xem chi tiết buổi tư vấn';

  @override
  String get learnerMentorBookNow => 'Đặt lịch ngay';

  @override
  String get learnerMentorIncludedSession => 'Dùng 1 vé tư vấn trong gói';

  @override
  String get learnerMentorConfirmBooking => 'Xác nhận đặt lịch';

  @override
  String get learnerMentorSelectedSlot => 'Khung giờ đã chọn';

  @override
  String get learnerMentorPleaseSelectSlot => 'Vui lòng chọn khung giờ tư vấn';

  @override
  String get practiceSpeechTitle => 'Luyện nói tiếng Nhật';

  @override
  String get practiceSpeechDescription =>
      'Luyện phát âm với nhận diện giọng nói AI.';

  @override
  String get practiceSpeechStatus => 'Nhận dạng trực tiếp';

  @override
  String get practiceTextScanTitle => 'Quét văn bản tiếng Nhật';

  @override
  String get practiceTextScanDescription =>
      'Quét bài viết từ hình ảnh để chỉnh sửa.';

  @override
  String get practiceTextScanStatus => 'Ảnh → Văn bản';

  @override
  String get speechPracticeTitle => 'Luyện nói';

  @override
  String get speechPracticeHeading => 'Biến giọng nói thành văn bản';

  @override
  String get speechPracticeSubtitle =>
      'Đọc một câu tiếng Nhật thật tự nhiên. RikiPath sẽ hiển thị nội dung nhận dạng ngay khi bạn nói.';

  @override
  String get speechSampleLabel => 'Câu gợi ý';

  @override
  String get speechSampleSentence => '日本語の話し方を練習しています。';

  @override
  String get speechTranscriptLabel => 'Nội dung nhận dạng';

  @override
  String get speechTranscriptEmpty =>
      'Văn bản tiếng Nhật sẽ xuất hiện tại đây khi bạn bắt đầu nói.';

  @override
  String get speechStart => 'Bắt đầu nói';

  @override
  String get speechStop => 'Dừng ghi âm';

  @override
  String get speechConnecting => 'Đang chuẩn bị micro...';

  @override
  String get speechRetry => 'Thử lại';

  @override
  String get speechSpeakAgain => 'Luyện nói lại';

  @override
  String get speechCopy => 'Sao chép văn bản';

  @override
  String get speechClear => 'Xóa nội dung';

  @override
  String get speechCopied => 'Đã sao chép văn bản';

  @override
  String get speechPermissionTitle => 'Cần quyền sử dụng micro';

  @override
  String get speechPermissionMessage =>
      'Hãy cho phép RikiPath sử dụng micro trong cài đặt thiết bị rồi thử lại.';

  @override
  String get speechNetworkTitle => 'Chưa thể kết nối';

  @override
  String get speechNetworkMessage =>
      'Kiểm tra kết nối mạng rồi bắt đầu lại buổi luyện nói.';

  @override
  String get speechProviderTitle => 'Nhận dạng giọng nói bị gián đoạn';

  @override
  String get speechProviderMessage =>
      'Dừng lại một chút rồi thử bắt đầu lại. Nội dung đã nhận dạng vẫn được giữ nguyên.';

  @override
  String get speechListeningTitle => 'RikiPath đang lắng nghe';

  @override
  String get speechListeningMessage =>
      'Hãy nói rõ ràng và giữ thiết bị gần bạn.';

  @override
  String get speechReadyMessage =>
      'Micro chỉ hoạt động khi bạn nhấn bắt đầu và sẽ dừng khi rời màn hình.';

  @override
  String get textScanTitle => 'Quét văn bản';

  @override
  String get textScanHeading => 'Nhận dạng chữ viết tiếng Nhật';

  @override
  String get textScanSubtitle =>
      'Chọn ảnh JPG, PNG hoặc WEBP rõ nét. Bạn có thể chỉnh sửa và sao chép kết quả ngay trên thiết bị.';

  @override
  String get textScanChooseImage => 'Chọn ảnh từ thư viện';

  @override
  String get textScanSelecting => 'Đang mở thư viện...';

  @override
  String get textScanDropTitle => 'Chọn ảnh bài viết tiếng Nhật';

  @override
  String get textScanRequirements => 'JPG, PNG hoặc WEBP • tối đa 10 MB';

  @override
  String get textScanPrivacyNote =>
      'Ảnh được gửi tới dịch vụ RikiPath để nhận dạng văn bản và không được hiển thị như một bài đã lưu.';

  @override
  String get textScanAction => 'Quét văn bản';

  @override
  String get textScanScanning => 'Đang nhận dạng...';

  @override
  String get textScanChooseAnother => 'Chọn ảnh khác';

  @override
  String get textScanClear => 'Xóa ảnh và kết quả';

  @override
  String get textScanResultLabel => 'Văn bản nhận dạng';

  @override
  String get textScanResultHint => 'Kết quả nhận dạng sẽ xuất hiện tại đây.';

  @override
  String get textScanLocalEditNote =>
      'Các chỉnh sửa trên màn hình này chưa được lưu vào lịch sử tài khoản.';

  @override
  String get textScanCopy => 'Sao chép kết quả';

  @override
  String get textScanCopied => 'Đã sao chép kết quả';

  @override
  String get textScanUnsupportedType =>
      'RikiPath chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.';

  @override
  String get textScanTooLarge =>
      'Ảnh vượt quá giới hạn 10 MB. Hãy chọn ảnh nhỏ hơn.';

  @override
  String get textScanPickerFailedTitle => 'Chưa thể mở thư viện ảnh';

  @override
  String get textScanPickerError =>
      'Hãy kiểm tra quyền truy cập ảnh rồi thử lại.';

  @override
  String get textScanFailedTitle => 'Chưa thể quét ảnh';

  @override
  String get textScanNetworkError => 'Kiểm tra kết nối mạng rồi thử quét lại.';

  @override
  String get textScanProviderError =>
      'Dịch vụ nhận dạng văn bản hiện chưa sẵn sàng. Ảnh của bạn vẫn được giữ để thử lại.';

  @override
  String get textScanCompleted =>
      'Đã nhận dạng xong. Bạn có thể kiểm tra, chỉnh sửa hoặc sao chép văn bản.';

  @override
  String get practiceStudioTitle => 'Studio Riki';

  @override
  String get practiceStudioSubtitle =>
      'Luyện nói, luyện viết và khám phá tiếng Nhật bằng các công cụ tương tác.';

  @override
  String get practiceWritingTitle => 'Luyện viết Kana & Kanji';

  @override
  String get practiceWritingDescription =>
      'Luyện viết nét và theo dõi tiến độ ôn tập.';

  @override
  String get practiceWritingStatus => 'Nét chữ tương tác';

  @override
  String get writingTitle => 'Luyện viết';

  @override
  String get writingSubtitle =>
      'Chọn một ký tự rồi luyện theo đúng thứ tự và hướng nét.';

  @override
  String get writingHiragana => 'Hiragana';

  @override
  String get writingKatakana => 'Katakana';

  @override
  String get writingKanji => 'Kanji';

  @override
  String get writingDue => 'Đến hạn';

  @override
  String get writingAll => 'Tất cả';

  @override
  String get writingQueueHint =>
      'Ký tự đến hạn được ưu tiên trước, sau đó là nội dung mới đã được duyệt.';

  @override
  String get writingSelectCharacter => 'Chọn ký tự để bắt đầu';

  @override
  String get writingEmptyTitle => 'Chưa có ký tự để luyện';

  @override
  String writingKanaEmptyMessage(String script) {
    return 'Hiện chưa có ký tự $script phù hợp cho tài khoản này.';
  }

  @override
  String get writingKanjiEmptyMessage =>
      'Hôm nay chưa có Kanji phù hợp trong danh sách này.';

  @override
  String get writingLoadFailed => 'Chưa thể tải danh sách luyện viết';

  @override
  String writingStrokeCount(int count) {
    return '$count nét';
  }

  @override
  String get writingNewCharacter => 'Mới';

  @override
  String get writingReviewCharacter => 'Ôn lại';

  @override
  String writingLastScore(int score) {
    return 'Điểm gần nhất $score/100';
  }

  @override
  String get writingMeaningUnavailable => 'Chưa cập nhật nghĩa';

  @override
  String get writingTargetLabel => 'Ký tự mục tiêu';

  @override
  String get writingOnReading => 'Âm On';

  @override
  String get writingKunReading => 'Âm Kun';

  @override
  String get writingReadingUnavailable => 'Chưa cập nhật';

  @override
  String get writingGuidedMode => 'Theo nét mẫu';

  @override
  String get writingFreeMode => 'Tự viết';

  @override
  String get writingGuidedHint =>
      'Nét mờ sẽ hướng dẫn vị trí. Hãy viết đúng thứ tự và hướng nét.';

  @override
  String get writingFreeHint =>
      'Mẫu được ẩn để bạn tự nhớ thứ tự và hướng nét.';

  @override
  String get writingGestureHint =>
      'Vuốt trong khung để viết • Vuốt bên ngoài để cuộn';

  @override
  String get writingShowStrokes => 'Xem nét mẫu';

  @override
  String get writingStart => 'Bắt đầu viết';

  @override
  String get writingRewrite => 'Viết lại';

  @override
  String get writingNext => 'Ký tự tiếp theo';

  @override
  String get writingLoadingStrokeData => 'Đang chuẩn bị dữ liệu nét chữ...';

  @override
  String get writingStrokeDataFailedTitle => 'Chưa tải được nét chữ';

  @override
  String get writingStrokeDataFailedMessage =>
      'Kiểm tra kết nối rồi thử lại. Dữ liệu đã tải trước đó vẫn có thể dùng khi ngoại tuyến.';

  @override
  String get writingQuizInProgress =>
      'Đang viết • hoàn thành từng nét theo thứ tự';

  @override
  String get writingAnimationInProgress => 'Đang trình diễn thứ tự nét...';

  @override
  String get writingCompleteTitle => 'Hoàn thành bài viết';

  @override
  String writingMistakeCount(int count) {
    return '$count nét sai';
  }

  @override
  String writingResultScore(int score) {
    return 'Điểm $score/100';
  }

  @override
  String get writingSavingResult => 'Đang lưu tiến độ...';

  @override
  String get writingResultSaved => 'Đã lưu lịch ôn tiếp theo';

  @override
  String get writingResultSaveFailed =>
      'Kết quả vẫn được giữ trên thiết bị nhưng chưa lưu được lên RikiPath.';

  @override
  String get writingRetrySave => 'Lưu lại';

  @override
  String writingProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get meetingTitle => 'Phòng họp';

  @override
  String get meetingJoinTitle => 'Tham gia cuộc họp';

  @override
  String get meetingJoinAction => 'Tham gia cuộc họp';

  @override
  String get meetingContinueAction => 'Tiếp tục';

  @override
  String get meetingLandingDescription =>
      'Tham gia bằng mã phòng hoặc liên kết RikiPath được chia sẻ với bạn.';

  @override
  String get meetingJoinDescription =>
      'Nhập mã phòng hoặc dán liên kết RikiPath để tham gia.';

  @override
  String get meetingLinkLabel => 'Mã phòng hoặc liên kết';

  @override
  String get meetingLinkHint => 'Nhập mã phòng hoặc dán liên kết';

  @override
  String get meetingLinkRequired => 'Vui lòng nhập mã phòng hoặc liên kết.';

  @override
  String get meetingLinkInvalid =>
      'Mã phòng không hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get meetingPasteAction => 'Dán';

  @override
  String get meetingRoomCodeHelper => 'Mã phòng nằm ở cuối liên kết cuộc họp.';

  @override
  String get meetingErrorRoomNotFound =>
      'Không tìm thấy phòng họp này. Vui lòng kiểm tra lại mã phòng.';

  @override
  String get meetingErrorNotAuthorized =>
      'Tài khoản của bạn không có quyền tham gia phòng họp này.';

  @override
  String get meetingErrorAuthRequired =>
      'Vui lòng đăng nhập để tham gia phòng họp.';

  @override
  String get meetingErrorNetwork =>
      'Không thể kết nối tới phòng họp. Vui lòng kiểm tra mạng và thử lại.';

  @override
  String get meetingAuthorizationNotice =>
      'Liên kết không tự động cấp quyền truy cập. Phòng họp sẽ kiểm tra tài khoản và quyền tham gia của bạn.';

  @override
  String get meetingAuthRequiredTitle => 'Đăng nhập để tham gia cuộc họp';

  @override
  String get meetingAuthRequiredDescription =>
      'Mã phòng đã được giữ tạm thời trên thiết bị này. Sau khi đăng nhập, bạn sẽ tự động quay lại phòng họp.';

  @override
  String get meetingReadyTitle => 'Sẵn sàng mở phòng họp';

  @override
  String get meetingEnterRoom => 'Vào phòng họp';

  @override
  String get meetingOpenFailedTitle => 'Chưa thể mở phòng họp';

  @override
  String get meetingOpenFailedDescription =>
      'Vui lòng kiểm tra trình duyệt và kết nối mạng rồi thử lại.';

  @override
  String get meetingDetailsAction => 'Chi tiết';

  @override
  String meetingNativeParticipantsCount(int count) {
    return '$count người tham gia';
  }

  @override
  String get meetingNativeConnecting => 'Đang kết nối phòng họp...';

  @override
  String get meetingNativeJoining => 'Đang vào phòng...';

  @override
  String get meetingNativeReconnecting => 'Đang kết nối lại...';

  @override
  String get meetingNativeFailedTitle => 'Không thể kết nối phòng họp';

  @override
  String get meetingNativeFailedDescription =>
      'Vui lòng kiểm tra kết nối và quyền tham gia phòng rồi thử lại.';

  @override
  String get meetingNativeRetry => 'Thử lại';

  @override
  String get meetingNativeOpenWeb => 'Mở phiên bản web';

  @override
  String get meetingNativeMicrophone => 'Mic';

  @override
  String get meetingNativeCamera => 'Camera';

  @override
  String get meetingNativeSwitchCamera => 'Đổi camera';

  @override
  String get meetingNativeRaiseHand => 'Giơ tay';

  @override
  String get meetingNativeLowerHand => 'Hạ tay';

  @override
  String get meetingNativeChat => 'Trò chuyện';

  @override
  String get meetingNativeParticipants => 'Người tham gia';

  @override
  String get meetingNativeMoreActions => 'Tùy chọn khác';

  @override
  String get meetingNativeMinimize => 'Thu nhỏ';

  @override
  String get meetingNativeLeave => 'Rời phòng';

  @override
  String get meetingNativeLeaveTitle => 'Rời cuộc họp?';

  @override
  String get meetingNativeLeaveDescription =>
      'Camera và microphone sẽ được tắt khi bạn rời phòng.';

  @override
  String get meetingNativeStay => 'Ở lại';

  @override
  String get meetingNativeNoParticipants => 'Đang chờ người khác tham gia';

  @override
  String get meetingNativeChatEmpty => 'Chưa có tin nhắn nào.';

  @override
  String get meetingNativeChatHint => 'Nhập tin nhắn...';

  @override
  String get meetingNativeSend => 'Gửi';

  @override
  String get meetingNativeYou => 'Bạn';

  @override
  String get meetingNativeMentor => 'Cố vấn';

  @override
  String get meetingNativeLearner => 'Học viên';

  @override
  String get meetingNativePermissionDenied =>
      'Bạn có thể tiếp tục nghe/xem. Hãy cấp quyền Camera và Microphone trong Cài đặt để phát hình và âm thanh.';

  @override
  String get meetingNativeCameraDenied =>
      'Camera chưa được cấp quyền. Bạn vẫn có thể tham gia bằng âm thanh.';

  @override
  String get meetingNativeMicrophoneDenied =>
      'Microphone chưa được cấp quyền. Bạn vẫn có thể tham gia ở chế độ nghe.';

  @override
  String get meetingNativeMediaUnavailable =>
      'Không thể mở Camera hoặc Microphone. Bạn vẫn có thể xem và trò chuyện.';

  @override
  String get meetingNativeScreenShareDeferred =>
      'Chia sẻ màn hình hiện dùng phiên bản web.';

  @override
  String get homeMeetingFallbackTitle => 'Phòng họp';

  @override
  String get homeMeetingFallbackDescription =>
      'Tham gia bằng mã phòng hoặc liên kết.';

  @override
  String get homeUpcomingMeetingTitle => 'Buổi học sắp tới';

  @override
  String homeMeetingSchedule(String date, String time) {
    return '$date • $time';
  }

  @override
  String get placementTitle => 'Đánh giá năng lực JLPT';

  @override
  String get placementLoading => 'Đang tải thông tin bài kiểm tra năng lực...';

  @override
  String get placementLoadErrorTitle => 'Không thể tải bài kiểm tra năng lực';

  @override
  String get placementLoadErrorDescription =>
      'Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get placementIntroTitle => 'Kiểm tra trình độ đầu vào';

  @override
  String get placementIntroDescription =>
      'Đánh giá nhanh năng lực từ N5 đến N3 để hệ thống đề xuất mục tiêu JLPT và mở khóa lộ trình học cá nhân hóa.';

  @override
  String placementLatestScore(String score) {
    return 'Kết quả đánh giá gần nhất: $score%';
  }

  @override
  String placementLatestLevels(String assessed, String recommended) {
    return 'Trình độ hiện tại: $assessed · Đề xuất mục tiêu: $recommended';
  }

  @override
  String get placementStarting => 'Đang khởi tạo đề kiểm tra...';

  @override
  String get placementRecoverResult => 'Thử khôi phục kết quả';

  @override
  String get placementRetake => 'Làm lại bài đánh giá';

  @override
  String get placementStart => 'Bắt đầu kiểm tra ngay';

  @override
  String placementQuestionProgress(int current, int total, int answered) {
    return 'Câu $current/$total · Đã chọn $answered/$total';
  }

  @override
  String get placementPreviousQuestion => 'Câu trước';

  @override
  String get placementNextQuestion => 'Câu tiếp theo';

  @override
  String get placementGrading => 'Đang chấm điểm...';

  @override
  String get placementSubmit => 'Nộp bài đánh giá';

  @override
  String get placementQuestionImageSemantics => 'Hình minh họa cho câu hỏi';

  @override
  String get placementQuestionImageUnavailable =>
      'Không thể tải hình ảnh câu hỏi.';

  @override
  String get placementAudioUnavailableSemantics =>
      'Âm thanh câu hỏi hiện không được hỗ trợ hoặc không khả dụng';

  @override
  String get placementAudioUnavailableDescription =>
      'Âm thanh của câu hỏi này chưa được hỗ trợ hoặc hiện không khả dụng.';

  @override
  String get placementResultTitle => 'Kết quả đánh giá năng lực';

  @override
  String placementResultScore(String score, int correct, int total) {
    return 'Điểm tổng: $score% ($correct/$total câu đúng)';
  }

  @override
  String get placementAssessedLevel => 'Trình độ hiện tại';

  @override
  String get placementRecommendedLevel => 'Mục tiêu đề xuất';

  @override
  String get placementBreakdownTitle => 'Chi tiết theo cấp độ JLPT';

  @override
  String get placementApplyingGoal => 'Đang áp dụng mục tiêu JLPT...';

  @override
  String get placementGeneratingPath => 'Đang tạo lộ trình học...';

  @override
  String get placementRefreshingPath => 'Đang làm mới lộ trình...';

  @override
  String placementApplyGoalAndPath(String level) {
    return 'Áp dụng JLPT $level và tạo lộ trình';
  }

  @override
  String get placementIssueValidation =>
      'Dữ liệu bài kiểm tra chưa hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get placementIssueExpired =>
      'Thời gian làm bài đã kết thúc. Vui lòng bắt đầu lượt đánh giá mới.';

  @override
  String get placementIssueBankNotReady =>
      'Ngân hàng câu hỏi N5–N3 chưa sẵn sàng. Vui lòng thử lại sau.';

  @override
  String get placementIssueInvalidAnswer =>
      'Một đáp án không còn hợp lệ. Vui lòng kiểm tra lựa chọn và nộp lại.';

  @override
  String get placementIssueNotCompleted =>
      'Lượt đánh giá chưa hoàn tất. Vui lòng tiếp tục hoặc thử đồng bộ lại.';

  @override
  String get placementIssueAlreadyCompleted =>
      'Bài đánh giá này đã được nộp trước đó.';

  @override
  String get placementIssueConflict =>
      'Không thể đồng bộ bộ câu hỏi. Vui lòng bắt đầu lại.';

  @override
  String get placementIssueNotFound => 'Không tìm thấy lượt làm bài đánh giá.';

  @override
  String get placementIssueNetwork =>
      'Kết nối mạng không ổn định. Vui lòng thử lại.';

  @override
  String get placementIssuePersistence =>
      'Không thể lưu tạm câu trả lời trên thiết bị. Vui lòng thử lại.';

  @override
  String get placementIssueUnknown =>
      'Đã xảy ra lỗi khi xử lý bài đánh giá năng lực.';

  @override
  String get onboardingPlacementTitle => 'Chưa rõ trình độ hiện tại?';

  @override
  String get onboardingPlacementDescription =>
      'Làm bài kiểm tra đánh giá năng lực đầu vào để nhận đề xuất cấp độ JLPT phù hợp.';

  @override
  String get onboardingPlacementAction => 'Kiểm tra trình độ đầu vào';

  @override
  String get onboardingStartingLevel => 'Trình độ bắt đầu';

  @override
  String get onboardingSkipComplete =>
      'Đã bỏ qua. Bạn vẫn có thể làm bài đánh giá sau trong Hồ sơ.';

  @override
  String get onboardingSkipRequired =>
      'Chọn làm bài đánh giá hoặc bỏ qua để tiếp tục.';

  @override
  String get onboardingSupportedLevels => 'Lộ trình tự động hiện hỗ trợ N5–N3.';

  @override
  String get pathAdjustTitle => 'Điều chỉnh lộ trình';

  @override
  String get pathAdjustIntro =>
      'Chọn trình độ bắt đầu và mục tiêu mới. Xem trước trước khi thay đổi lộ trình đang học.';

  @override
  String get pathStartingLevel => 'Trình độ bắt đầu';

  @override
  String get pathTargetLevel => 'Mục tiêu JLPT';

  @override
  String get pathPreviewAction => 'Xem trước lộ trình';

  @override
  String get pathPreviewTitle => 'Bản xem trước';

  @override
  String get pathConfirmAction => 'Xác nhận lộ trình mới';

  @override
  String get pathCancelPreviewAction => 'Hủy bản xem trước';

  @override
  String get pathKeepsProgress =>
      'Bài đã hoàn thành, Sổ từ và lịch sử học vẫn được giữ nguyên khi đổi lộ trình.';

  @override
  String get pathHistoryTitle => 'Lịch sử lộ trình';

  @override
  String get pathNoHistory => 'Chưa có lộ trình đã xác nhận.';

  @override
  String pathVersionLabel(int version) {
    return 'Phiên bản $version';
  }

  @override
  String get pathStatusActive => 'Đang dùng';

  @override
  String get pathStatusSuperseded => 'Trước đây';

  @override
  String get pathPreviewError =>
      'Không thể xem trước lộ trình. Kiểm tra cấp độ và nội dung học rồi thử lại.';

  @override
  String get pathConfirmError =>
      'Không thể xác nhận bản xem trước. Lộ trình hiện tại vẫn được giữ nguyên.';

  @override
  String get pathCancelError =>
      'Không thể hủy bản xem trước. Vui lòng thử lại.';

  @override
  String get pathChooseDifferentLevels =>
      'Chọn trình độ hoặc mục tiêu khác với lộ trình hiện tại.';

  @override
  String get pathInitialRequired =>
      'Hãy hoàn tất thiết lập ban đầu trước khi điều chỉnh lộ trình.';

  @override
  String get placementSectionBreakdownTitle => 'Kết quả theo phần';

  @override
  String placementWrongQuestionsSummary(int count, String questions) {
    return 'Câu cần ôn lại ($count): $questions';
  }

  @override
  String get learningPathPreviewTitle => 'Bản xem trước lộ trình AI';

  @override
  String learningPathPreviewVersion(int version) {
    return 'Phiên bản $version sẽ chỉ thay thế lộ trình hiện tại sau khi bạn xác nhận. Lịch sử học tập vẫn được giữ nguyên.';
  }

  @override
  String get learningPathPreviewFailed =>
      'Không thể xem trước hoặc xác nhận lộ trình học. Lộ trình hiện tại được giữ nguyên.';

  @override
  String get lessonMaterialsUnavailable =>
      'Bài học này chưa có nội dung chi tiết. Vui lòng quay lại sau khi nội dung được cập nhật.';

  @override
  String homeCurrentLessonLabel(int lesson) {
    return 'Bài học $lesson';
  }

  @override
  String get placementIssueExamDateRequired =>
      'Kết quả đánh giá năng lực đã được lưu. Trước khi tạo lộ trình học AI, vui lòng chọn ngày thi dự kiến trong mục Mục tiêu JLPT tại trang cá nhân.';

  @override
  String get placementSetExamDate => 'Chọn ngày thi trong trang cá nhân';

  @override
  String get placementOpenStandardRoadmap => 'Tiếp tục lộ trình học tiêu chuẩn';

  @override
  String get greetingGeneric => 'Xin chào bạn!';

  @override
  String get homeEduBannerTag => 'Thói quen học';

  @override
  String get homeEduBannerTitle => 'Duy trì nhịp học đều đặn';

  @override
  String get homeEduBannerMessage =>
      'Duy trì thói quen học mỗi ngày 15–20 phút giúp não bộ củng cố trí nhớ và chuyển hóa kiến thức tiếng Nhật thành phản xạ tự nhiên. Hãy bắt đầu ngay!';

  @override
  String get roadmapEduBannerTag => 'Bí quyết JLPT';

  @override
  String get roadmapEduBannerTitle => 'Học theo chặng kiến thức';

  @override
  String get roadmapEduBannerMessage =>
      'Nắm vững ngữ pháp và từ vựng cốt lõi từng chặng trước khi bước sang chặng tiếp theo để giữ kiến thức lâu dài.';

  @override
  String get kanaEduBannerTag => 'Kỹ thuật viết';

  @override
  String get kanaEduBannerTitle => 'Quy tắc thuận bút tiếng Nhật';

  @override
  String get kanaEduBannerMessage =>
      'Viết nét từ trên xuống dưới, từ trái sang phải để hình thành nét chữ cân đối và kích hoạt trí nhớ cơ bắp.';

  @override
  String get grammarEduBannerTag => 'Ngữ cảnh';

  @override
  String get grammarEduBannerTitle => 'Học ngữ pháp qua ví dụ thực tế';

  @override
  String get grammarEduBannerMessage =>
      'Đặt câu với ngữ cảnh hội thoại hàng ngày thay vì chỉ ghi nhớ công thức khô khan.';

  @override
  String get notebookEduBannerTag => 'Phương pháp SRS';

  @override
  String get notebookEduBannerTitle => 'Lặp lại ngắt quãng thông minh';

  @override
  String get notebookEduBannerMessage =>
      'Lưu các từ khó vào sổ từ và ôn lại sau 1, 3, và 7 ngày để chuyển hóa vào trí nhớ dài hạn.';

  @override
  String get vocabularyEduBannerTag => 'Mẹo từ vựng';

  @override
  String get vocabularyEduBannerTitle => 'Học từ theo ngữ cảnh & Collocation';

  @override
  String get vocabularyEduBannerMessage =>
      'Ghi nhớ từ vựng kết hợp trợ từ và động từ đi kèm để hình thành phản xạ tự nhiên khi giao tiếp.';

  @override
  String get practiceEduBannerTag => 'Chiến lược ôn luyện';

  @override
  String get practiceEduBannerTitle => 'Luyện đề có chủ đích';

  @override
  String get practiceEduBannerMessage =>
      'Kết hợp làm đề thi thử có bấm giờ cùng ôn tập ngắt quãng (SRS) mỗi ngày giúp bạn quen áp lực phòng thi và củng cố phản xạ tự nhiên.';

  @override
  String homeGreetingLearningLevel(String level) {
    return 'Bạn đang học JLPT $level · Cùng tiến bộ mỗi ngày!';
  }

  @override
  String homeGreetingCurrentAndTargetLevel(String current, String target) {
    return 'Đang học $current · Hướng đến $target';
  }

  @override
  String get homeGreetingNoLevel => 'Khám phá lộ trình học phù hợp với bạn.';

  @override
  String get heroBannerTag => 'がんばろう！';

  @override
  String get heroBannerMorningTitle => 'Chào buổi sáng!';

  @override
  String get heroBannerMorningSubtitle => 'Khởi đầu một ngày học thật vui.';

  @override
  String get heroBannerNoonTitle => 'Học một chút nhé!';

  @override
  String get heroBannerNoonSubtitle => 'Nạp thêm kiến thức mới.';

  @override
  String get heroBannerAfternoonTitle => 'Tiếp tục cố gắng!';

  @override
  String get heroBannerAfternoonSubtitle => 'Mỗi bước nhỏ đều đáng giá.';

  @override
  String get heroBannerEveningTitle => 'Cùng ôn tập nào!';

  @override
  String get heroBannerEveningSubtitle => 'Củng cố những điều đã học.';

  @override
  String get heroBannerLateNightTitle => 'Nghỉ ngơi thật tốt!';

  @override
  String get heroBannerLateNightSubtitle => 'Ngày mai mình lại tiếp tục nhé.';

  @override
  String get mockLibraryTitle => 'Đề thi thử JLPT';

  @override
  String get mockLibraryDescription =>
      'Luyện đề theo trình độ và theo dõi kết quả.';

  @override
  String mockLibraryAvailableCount(int count) {
    return '$count đề khả dụng';
  }

  @override
  String get mockLibraryOpenFailed =>
      'Không thể mở đề thi lúc này. Vui lòng thử lại.';

  @override
  String get mockLibraryActiveAttempt =>
      'Hãy hoàn thành đề đang làm trước khi chọn đề khác.';

  @override
  String get essayWritingTitle => 'Luyện viết tiếng Nhật';

  @override
  String get essayWritingDescription => 'Viết bài và nhận đánh giá.';

  @override
  String get essayWritingIntro =>
      'Viết một đoạn tiếng Nhật. Bài chỉ được gửi khi bạn nhấn nút chấm.';

  @override
  String get essayWritingNoLevel => 'Chưa có cấp độ JLPT để luyện viết.';

  @override
  String get essayWritingLevelLoadError =>
      'Không tải được cấp độ JLPT. Thử lại';

  @override
  String get essayWritingLevelLabel => 'Cấp độ JLPT';

  @override
  String get essayWritingInputHint => 'Nhập bài viết tiếng Nhật của bạn';

  @override
  String get essayWritingSubmit => 'Chấm bài luyện tập';

  @override
  String get essayWritingSubmitting => 'Đang chấm bài...';

  @override
  String get essayWritingSubmitUncertain =>
      'Không thể xác nhận bài nộp. Vui lòng kiểm tra trước khi gửi lại.';

  @override
  String essayWritingSaved(int id) {
    return 'Đã lưu bài nộp #$id';
  }

  @override
  String get essayWritingNew => 'Viết bài mới';

  @override
  String essayWritingScore(String score) {
    return 'Điểm: $score/100';
  }

  @override
  String get essayWritingStrengths => 'Điểm mạnh';

  @override
  String get essayWritingImprovements => 'Cần cải thiện';

  @override
  String get essayWritingCorrections => 'Gợi ý sửa lỗi';

  @override
  String get practiceHeroBadge => 'がんばろう！';

  @override
  String get practiceHeroTitle => 'Sẵn sàng luyện tập?';

  @override
  String get practiceHeroSubtitle => 'Mỗi bài tập, thêm một bước tiến.';

  @override
  String get profilePlacementSubtitle =>
      'Đánh giá năng lực và gợi ý cấp độ phù hợp.';

  @override
  String get profileLogoutSubtitle => 'Đăng xuất tài khoản khỏi thiết bị này.';

  @override
  String get profileMentorApplicationTitle => 'Đăng ký trở thành Cố vấn';

  @override
  String get profileMentorApplicationSubtitle =>
      'Nộp hồ sơ chuyên môn để xét duyệt.';

  @override
  String get notebookEmptyHeroBadge => 'がんばろう！';

  @override
  String get notebookEmptyHeroTitle => 'Bắt đầu sổ từ của bạn!';

  @override
  String get notebookEmptyHeroDescription =>
      'Lưu lại những từ vựng và mẫu câu yêu thích.';

  @override
  String get createFirstCollectionAction => 'Tạo danh sách đầu tiên';

  @override
  String get addFirstWordAction => 'Thêm từ đầu tiên';
}
