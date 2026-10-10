// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'RikiPath';

  @override
  String get toastRegisterSuccessTitle => 'アカウントを作成しました';

  @override
  String get toastRegisterSuccessDescription => '続行するにはメール認証を行ってください。';

  @override
  String get toastVerifyEmailSuccessTitle => 'メール認証が完了しました';

  @override
  String get toastVerifyEmailSuccessDescription => 'ログインできます。';

  @override
  String get toastLoginSuccessTitle => 'ログインしました';

  @override
  String get toastLoginSuccessDescription => 'RikiPathへお帰りなさい。';

  @override
  String get toastProfileUpdateSuccessTitle => 'プロフィールを更新しました';

  @override
  String get toastEmailUpdateSuccessTitle => 'メールアドレスを更新しました';

  @override
  String get toastPasswordChangeSuccessTitle => 'パスワードを変更しました';

  @override
  String get toastAvatarUploadSuccessTitle => 'プロフィール画像を更新しました';

  @override
  String get toastNotificationUpdateSuccessTitle => '通知設定を更新しました';

  @override
  String get toastJlptGoalUpdateSuccessTitle => 'JLPT目標を更新しました';

  @override
  String get toastActionFailedTitle => '操作を完了できませんでした';

  @override
  String get toastAudioFailedTitle => '音声を再生できません';

  @override
  String get languagePickerSemantics => '言語を選択';

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
  String get back => '戻る';

  @override
  String get retry => '再試行';

  @override
  String get clearFilters => '絞り込みを解除';

  @override
  String get all => 'すべて';

  @override
  String get close => '閉じる';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get continueLabel => '次へ';

  @override
  String get finish => '完了';

  @override
  String get loading => '読み込み中...';

  @override
  String get preparingLearningContent => '学習内容を準備しています…';

  @override
  String get preparingLearningSubtext => 'あなたの学習プランを整えています。';

  @override
  String get notAvailable => '現在利用できません';

  @override
  String pageNotFound(String uri) {
    return 'ページが見つかりません: $uri';
  }

  @override
  String get navigationHome => 'ホーム';

  @override
  String get navigationLearn => '学習';

  @override
  String get navigationPractice => '練習';

  @override
  String get navigationNotebook => '単語帳';

  @override
  String get navigationProfile => 'マイページ';

  @override
  String get splashTagline => '日本語学習 • JLPT対策';

  @override
  String get authPromotion => 'AIで自分に合った日本語学習';

  @override
  String get loginWelcome => 'おかえりなさい！ 👋';

  @override
  String get loginSubtitle => 'RikiPathでJLPT合格への学習を続けましょう。';

  @override
  String get studentEmail => 'メールアドレス';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get emailHint => 'learner@example.com';

  @override
  String get password => 'パスワード';

  @override
  String get passwordHint => 'パスワードを入力';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get rememberSession => 'この端末でログイン状態を保持する';

  @override
  String get login => 'ログイン';

  @override
  String get loggingIn => 'ログイン中...';

  @override
  String get loggingInSemantics => 'ログイン中';

  @override
  String get loginSecureConnection => 'アカウントへ安全に接続しています...';

  @override
  String get loginTipTitle => 'ログインのヒント';

  @override
  String get loginTipMessage => '受講登録済みのアカウントでログインすると、学習記録とAI学習プランを同期できます。';

  @override
  String get loginFailedTitle => 'ログインできません';

  @override
  String get noAccount => 'アカウントをお持ちでないですか？';

  @override
  String get register => '新規登録';

  @override
  String get securityFooter => 'Riki Learningの暗号化セキュリティ';

  @override
  String get registerTitle => 'RikiPathアカウントを作成';

  @override
  String get registerSubtitle => 'あなただけのJLPT学習プランを始めましょう。';

  @override
  String get fullName => '氏名';

  @override
  String get fullNameHint => '山田 太郎';

  @override
  String get minimumSixCharacters => '6文字以上';

  @override
  String get confirmPassword => 'パスワードの確認';

  @override
  String get confirmPasswordHint => 'パスワードを再入力';

  @override
  String get termsPrefix => '登録すると、RikiPathの';

  @override
  String get termsOfService => '利用規約';

  @override
  String get termsJoiner => 'と';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsSuffix => 'に同意したものとみなされます。';

  @override
  String get registerFailedTitle => 'アカウントを作成できません';

  @override
  String get creatingAccount => 'アカウントを作成中...';

  @override
  String get creatingAccountSemantics => 'アカウントを作成中';

  @override
  String get creatingAccountMessage => '学習者アカウントを作成し、確認メールを送信しています...';

  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？';

  @override
  String get accountCreatedStatus => '作成完了';

  @override
  String get accountCreatedTitle => 'アカウントを作成しました';

  @override
  String accountCreatedMessage(String email) {
    return '確認コードを次のメールアドレスに送信しました。\n$email';
  }

  @override
  String get checkEmailVerification => 'メールを確認してアカウントを認証してください。';

  @override
  String get verificationBackendBlocker =>
      'メールに6桁の確認コードが届きます。有効期限は30分です。安全にコード入力へ進むためのアカウント情報がまだ揃っていません。';

  @override
  String get returnToLogin => 'ログインに戻る';

  @override
  String get verifyEmailStatus => 'メール認証';

  @override
  String get emailVerifiedStatus => '認証済み';

  @override
  String get verifyEmailTitle => '確認コードを入力';

  @override
  String get verifyEmailSubtitle => 'メールに届いた6桁のコードを入力してください。';

  @override
  String get verificationCodeSentTo => '確認コードの送信先';

  @override
  String get verificationCodeSentToYourEmail => '確認コードをメールアドレスに送信しました。';

  @override
  String get verificationCode => '確認コード';

  @override
  String get verificationCodeHint => '000000';

  @override
  String get didNotReceiveVerificationCode => 'コードが届きませんか？';

  @override
  String get resendVerificationCode => 'コードを再送信';

  @override
  String resendVerificationCodeIn(String time) {
    return '$time後にコードを再送信';
  }

  @override
  String get resendingVerificationCode => '再送信中...';

  @override
  String get verificationCodeResentMessage => '新しい確認コードをメールに送信しました。';

  @override
  String get resendVerificationFailedTitle => 'コードを再送信できません';

  @override
  String get verify => '認証する';

  @override
  String get verifying => '認証中...';

  @override
  String get verifyEmailSuccessTitle => 'メール認証が完了しました';

  @override
  String get verifyEmailSuccessMessage => 'アカウントでログインできます。';

  @override
  String get forgotPasswordTitle => 'パスワードをお忘れですか？';

  @override
  String get forgotPasswordSubtitle => '登録済みのメールアドレスを入力すると、再設定方法をお送りします。';

  @override
  String get registeredEmail => '登録済みメールアドレス';

  @override
  String get sendRequest => '送信';

  @override
  String get sendingRequest => '送信中...';

  @override
  String get requestSentStatus => 'メール送信済み';

  @override
  String get requestSentTitle => 'リクエストを送信しました';

  @override
  String requestSentMessage(String email) {
    return '$email の受信トレイを確認して、パスワードの再設定を続けてください。';
  }

  @override
  String resendCountdown(int seconds) {
    return '再送信（$seconds秒）';
  }

  @override
  String get passwordRecoveryUnavailableTitle => '現在送信できません';

  @override
  String get account => 'アカウント';

  @override
  String get accountSecurity => 'アカウントのセキュリティ';

  @override
  String get accountSecuritySubtitle => 'ログイン用メール、パスワード、現在のセッションを管理します。';

  @override
  String get changeEmail => 'メールアドレスを変更';

  @override
  String get changeEmailSubtitle => '新しいメールアドレスに確認コードを送信';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get changePasswordSubtitle => '現在のパスワードが必要です';

  @override
  String get logout => 'ログアウト';

  @override
  String get newEmail => '新しいメールアドレス';

  @override
  String get newEmailHint => 'new-email@example.com';

  @override
  String get updateEmail => 'メールを更新';

  @override
  String get updatingEmail => '更新中...';

  @override
  String get emailUpdatedTitle => 'メールを更新しました';

  @override
  String get emailUpdatedMessage => '新しいメールを確認して認証を完了してください。';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmNewPassword => '新しいパスワードの確認';

  @override
  String get changePasswordAction => 'パスワードを更新';

  @override
  String get changingPassword => '更新中...';

  @override
  String get passwordChangedTitle => 'パスワードを変更しました';

  @override
  String get passwordChangedMessage => 'パスワードが更新されました。';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get hidePassword => 'パスワードを隠す';

  @override
  String get validationEmailRequired => 'メールアドレスを入力してください。';

  @override
  String get validationEmailInvalid => '有効なメールアドレスを入力してください。';

  @override
  String get validationPasswordRequired => 'パスワードを入力してください。';

  @override
  String get validationPasswordLength => 'パスワードは6文字以上で入力してください。';

  @override
  String get validationConfirmPasswordRequired => '確認用パスワードを入力してください。';

  @override
  String get validationPasswordMismatch => 'パスワードが一致しません。';

  @override
  String get validationVerificationCodeRequired => '確認コードを入力してください。';

  @override
  String get validationVerificationCodeLength => '確認コードは6桁の数字で入力してください。';

  @override
  String get validationTermsRequired => '登録前に利用規約への同意が必要です。';

  @override
  String get authErrorPasswordRecoveryUnavailable =>
      'パスワード再設定は現在アプリで利用できません。サポートへお問い合わせください。';

  @override
  String get authErrorUnsupportedRole => 'モバイルアプリは学習者とメンターのアカウントに対応しています。';

  @override
  String get mentorLandingTitle => 'メンターエリア';

  @override
  String get mentorLandingDescription => '公開中の空き時間と今後の相談予定を確認できます。';

  @override
  String get mentorHomeGreeting => 'おかえりなさい';

  @override
  String get mentorAvailabilityTitle => '自分の空き時間';

  @override
  String get mentorAvailabilityDescription => '学習者に公開されている時間枠です。';

  @override
  String mentorAvailabilityCount(int count) {
    return '$count件の時間枠';
  }

  @override
  String get mentorAvailabilityEmpty => '空き時間はまだ登録されていません。';

  @override
  String get mentorAvailabilityError => '空き時間を読み込めませんでした。もう一度お試しください。';

  @override
  String get mentorAvailabilityReadOnlyTitle => '閲覧のみ';

  @override
  String get mentorAvailabilityReadOnlyMessage =>
      'アプリでは空き時間を確認できます。タイムゾーンの取り扱いが確定後、編集機能を提供します。';

  @override
  String get mentorViewAvailability => '空き時間を見る';

  @override
  String get mentorMeetingsTitle => '自分の相談予定';

  @override
  String get mentorMeetingsDescription => '学習者との確定した相談予定です。';

  @override
  String mentorMeetingsCount(int count) {
    return '$count件の相談';
  }

  @override
  String get mentorMeetingsEmpty => '相談予定はまだありません。';

  @override
  String get mentorMeetingsError => '相談予定を読み込めませんでした。もう一度お試しください。';

  @override
  String get mentorViewMeetings => '相談予定を見る';

  @override
  String get mentorMeetingDetailTitle => '相談の詳細';

  @override
  String get mentorLearnerLabel => '学習者';

  @override
  String get mentorLearnerUnknown => '学習者情報はまだありません';

  @override
  String get mentorScheduleLabel => '日時';

  @override
  String get mentorSchedulePending => '日時未定';

  @override
  String get mentorStartTimeLabel => '開始';

  @override
  String get mentorEndTimeLabel => '終了';

  @override
  String get mentorStatusLabel => 'ステータス';

  @override
  String get mentorSlotOpen => '空きあり';

  @override
  String get mentorSlotBooked => '予約済み';

  @override
  String get mentorJoinMeeting => '相談に参加';

  @override
  String get mentorMeetingLinkUnavailable => 'この相談のミーティングルームはまだ利用できません。';

  @override
  String get mentorMeetingNotFound => 'あなたの予定にこの相談はありません。';

  @override
  String get mentorJoinFailedTitle => 'ミーティングルームを開けません';

  @override
  String get mentorJoinFailedDescription => 'この端末ではミーティングルームのリンクを開けませんでした。';

  @override
  String get mentorStatusAwaitingPayment => '支払い待ち';

  @override
  String get mentorStatusPendingAssignment => '割り当て待ち';

  @override
  String get mentorStatusAssigned => '割り当て済み';

  @override
  String get mentorStatusAccepted => '承認済み';

  @override
  String get mentorStatusCompleted => '完了';

  @override
  String get mentorStatusCancelled => 'キャンセル済み';

  @override
  String get mentorStatusUnknown => '未確定';

  @override
  String get unsupportedRoleTitle => '未対応のロール';

  @override
  String unsupportedRoleDescription(String role) {
    return 'ロール $role はモバイルアプリの対象外です。ログアウトして学習者またはメンターのアカウントをご利用ください。';
  }

  @override
  String get authErrorNetwork => 'RikiPathに接続できません。通信環境を確認して再試行してください。';

  @override
  String get authErrorInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません。';

  @override
  String get authErrorSessionExpired => 'ログインセッションが無効です。もう一度ログインしてください。';

  @override
  String get authErrorForbidden => 'この操作を実行する権限がありません。';

  @override
  String get authErrorNotFound => '更新するアカウントが見つかりません。';

  @override
  String get authErrorLoginValidation => 'ログイン情報を確認してください。';

  @override
  String get authErrorRegisterValidation => '登録情報が正しくないか、メールアドレスがすでに使用されています。';

  @override
  String get authErrorVerifyValidation => '確認コードが無効、期限切れ、または使用済みです。';

  @override
  String get authErrorResendValidation =>
      'このメールアドレスにコードを再送信できません。内容を確認して再試行してください。';

  @override
  String get authErrorResendRateLimited => '再送信の回数が上限に達しました。しばらくしてから再試行してください。';

  @override
  String get authErrorUpdateEmailValidation => '新しいメールアドレスが無効、または使用済みです。';

  @override
  String get authErrorChangePasswordValidation =>
      '現在のパスワードが正しくないか、新しいパスワードが無効です。';

  @override
  String get authErrorRecoveryValidation => 'メールアドレスを確認してください。';

  @override
  String get authErrorServer => 'RikiPathで問題が発生しています。しばらくしてから再試行してください。';

  @override
  String get authErrorUnknown => '予期しないエラーが発生しました。再試行してください。';

  @override
  String get authErrorVerifyMissingUserId => 'メール認証に必要なアカウント情報がまだ揃っていません。';

  @override
  String get authErrorResendMissingEmail => '確認コードの再送信に必要なメールアドレスがありません。';

  @override
  String get authErrorSessionMissingUserId =>
      '現在のセッションに必要なアカウント情報がありません。もう一度ログインしてください。';

  @override
  String get profileTitle => 'マイページ';

  @override
  String get learner => '学習者';

  @override
  String get currentGoal => '現在の目標';

  @override
  String get learningStatistics => '学習統計';

  @override
  String get latestScore => '直近のスコア';

  @override
  String get progressAndHistory => '進捗と学習履歴';

  @override
  String get consultation => '相談';

  @override
  String get settings => '設定';

  @override
  String get languageSettings => '言語';

  @override
  String get emailVerifiedMessage => 'RikiPathでメールアドレスが認証されました。';

  @override
  String get verifyEmailInputSubtitle => 'メールに届いたコードを入力して認証を完了してください。';

  @override
  String get verifyEmailBlockedTitle => '登録画面から続行できません';

  @override
  String get verifyEmailBlockedMessage => '安全に確認コードを送信するためのアカウント情報がまだ揃っていません。';

  @override
  String get verificationCodeValidity => 'コードは6桁の数字で、有効期限は30分です。';

  @override
  String get verifyEmailFailedTitle => 'メールを認証できません';

  @override
  String get verifiedPrompt => '認証済みですか？';

  @override
  String forgotPasswordSentBody(String email) {
    return 'パスワード再設定の案内を $email に送信しました。';
  }

  @override
  String get forgotPasswordCheckEmail => 'メールを確認してパスワードの再設定を続けてください。';

  @override
  String get forgotPasswordSpamHint => 'メールが見つからない場合は、迷惑メールフォルダもご確認ください。';

  @override
  String get forgotPasswordResend => 'メールが届きませんか？ 再送信（58秒）';

  @override
  String get helpDirectPrefix => 'サポートが必要ですか？';

  @override
  String get helpSensei => '先生に問い合わせる';

  @override
  String get helpAccountPrefix => 'アカウントについてお困りですか？';

  @override
  String get helpCenter => 'ヘルプセンター';

  @override
  String get newLoginEmailTitle => '新しいログイン用メール';

  @override
  String get newLoginEmailSubtitle => '更新後、新しいメールアドレスに確認コードが送信されます。';

  @override
  String get missingSessionTitle => 'セッション情報がありません';

  @override
  String get missingSessionMessage =>
      '現在のセッションに必要な情報がありません。ログアウトしてから、もう一度ログインしてください。';

  @override
  String get changeEmailFailedTitle => 'メールを変更できません';

  @override
  String get emailUpdatedVerificationMessage =>
      'メールを更新しました。新しいメールに届いたコードを入力してください。';

  @override
  String get enterVerificationCode => '確認コードを入力';

  @override
  String get protectAccountTitle => 'アカウントを保護';

  @override
  String get passwordContractHint => '現在の仕様では、新しいパスワードは6文字以上必要です。';

  @override
  String get currentPasswordHint => '現在のパスワードを入力';

  @override
  String get newPasswordHint => '新しいパスワードを入力';

  @override
  String get confirmNewPasswordHint => '新しいパスワードを再入力';

  @override
  String get changePasswordFailedTitle => 'パスワードを変更できません';

  @override
  String get passwordUpdatedSessionMessage => 'パスワードを更新しました。現在のログイン状態は維持されます。';

  @override
  String dayCount(int count) {
    return '$count日目';
  }

  @override
  String get notifications => '通知';

  @override
  String get openProfile => 'マイページを開く';

  @override
  String get homeToolsTitle => '学習ツールを使ってみましょう';

  @override
  String get homeLoadFailed => 'ホームを読み込めません';

  @override
  String get checkConnectionRetry => '通信環境を確認して再試行してください。';

  @override
  String greetingName(String name) {
    return 'こんにちは、$nameさん！ 👋';
  }

  @override
  String jlptGoal(String level) {
    return 'JLPT $levelを目標に学習中';
  }

  @override
  String get notStarted => '未開始';

  @override
  String lessonPartsCompleted(int completed, int total) {
    return ' • $completed/$total項目完了';
  }

  @override
  String lessonProgressSemantics(int percentage) {
    return 'レッスンの進捗は$percentageパーセントです';
  }

  @override
  String get startLearning => '学習を始める';

  @override
  String stageCount(int count) {
    return '$countステージ';
  }

  @override
  String get personalizedByAbility => '習熟度に合わせて最適化';

  @override
  String get viewRoadmap => '学習プランを見る';

  @override
  String get initialSetup => '初期設定';

  @override
  String get initialSetupSubtitle => '学習を始めるためのステップ';

  @override
  String completedCount(int completed, int total) {
    return '$completed/$total完了';
  }

  @override
  String get leaveSetup => '設定を終了';

  @override
  String get onboardingJlptTitle => '目標とするJLPTレベルは？';

  @override
  String get onboardingJlptDescription =>
      '目標レベルを選ぶと、RikiPathがあなた向けの学習プランを作成します。';

  @override
  String get popular => '人気';

  @override
  String get mostPopular => '一番人気';

  @override
  String get onboardingJlptHelper => 'N5、N4、N3から選択してください。';

  @override
  String get jlptN5Description => '日本語の基礎を身につける';

  @override
  String get jlptN4Description => '初級から中級の知識を強化する';

  @override
  String get jlptN3Description => '中級レベルを目指す';

  @override
  String get backToGoalSelection => '目標選択に戻る';

  @override
  String get onboardingStudyTimeTitle => '1日にどのくらい学習しますか？';

  @override
  String get onboardingStudyTimeDescription =>
      '生活リズムに合うペースを選びましょう。速さより継続することが大切です。';

  @override
  String studyMinutesPerDay(int minutes) {
    return '1日$minutes分';
  }

  @override
  String get studyPaceGentle => '気軽に';

  @override
  String get studyPaceBalanced => 'バランス';

  @override
  String get studyPaceActive => 'しっかり';

  @override
  String get studyPaceIntensive => '集中';

  @override
  String get finishSetup => '設定を完了';

  @override
  String get onboardingAdjustHelper => '戻って選択内容を変更することもできます。';

  @override
  String get setupCompleteStatus => '設定完了';

  @override
  String get readyToStart => '準備ができました！ 🎉';

  @override
  String get learningPlanReady => '学習プランの設定が完了しました。';

  @override
  String studySummary(int minutes, String description) {
    return '1日$minutes分 · $description';
  }

  @override
  String get goalPrefix => '目標:';

  @override
  String stepOfTwo(int step) {
    return 'ステップ $step / 2';
  }

  @override
  String setupProgressSemantics(int step) {
    return '設定の進捗: 全2ステップ中$stepステップ目';
  }

  @override
  String get setupCompleteSemantics => '学習プランの設定が完了しました';

  @override
  String get mockTestTitle => 'JLPT模擬試験';

  @override
  String get mockTestSubtitle => '語彙・文法、読解、聴解の試験形式を練習します';

  @override
  String get notAttempted => '未受験';

  @override
  String get latestResult => '直近の結果';

  @override
  String get view => '見る';

  @override
  String get aiGrading => 'AI採点';

  @override
  String get writingAndKanjiPractice => '作文・漢字練習';

  @override
  String get library => 'ライブラリ';

  @override
  String get vocabulary => '語彙';

  @override
  String get vocabularyDetail => '語彙の詳細';

  @override
  String get vocabularyAudioFailed => '語彙の音声を再生できません。';

  @override
  String get chooseNotebook => '単語帳を選択';

  @override
  String wordCount(int count) {
    return '$count語';
  }

  @override
  String savedToCollection(String name) {
    return '「$name」に保存しました。';
  }

  @override
  String get vocabularySearchHint => '日本語、読み方、意味を検索...';

  @override
  String get clearSearch => '検索をクリア';

  @override
  String get illustrationData => '補足コンテンツ';

  @override
  String get saved => '保存済み';

  @override
  String get audioUnavailable => '音声はありません';

  @override
  String get listenPronunciation => '発音を聞く';

  @override
  String get loadMore => 'さらに読み込む';

  @override
  String get vocabularyEmptyTitle => '語彙が見つかりません';

  @override
  String get vocabularyEmptyMessage => '別のキーワードを試すか、JLPTの絞り込みを解除してください。';

  @override
  String get vocabularyLoadFailed => '語彙ライブラリを読み込めません';

  @override
  String get localFixtureNotice => '以下の補足内容は端末に保存されています。';

  @override
  String get meaning => '意味';

  @override
  String get examples => '例文';

  @override
  String get usageNuance => '使い方のニュアンス';

  @override
  String get commonCollocations => 'よく使う組み合わせ';

  @override
  String get kanjiAnalysis => '漢字の分析';

  @override
  String get relatedLessons => '関連レッスン';

  @override
  String get wordAlreadySaved => 'この語彙は保存済みです。';

  @override
  String get personalNotebook => '自分の単語帳';

  @override
  String get saveWordDescription => 'この語彙を単語帳に保存して復習できます。';

  @override
  String get saveToNotebook => '単語帳に保存';

  @override
  String get processing => '処理中...';

  @override
  String get kanjiDetail => '漢字の詳細';

  @override
  String get strokeOrder => '筆順';

  @override
  String get kanjiAudioFailed => '漢字の音声を再生できません。';

  @override
  String itemCount(int count) {
    return '$count件';
  }

  @override
  String get kanjiSearchHint => '漢字または意味を検索';

  @override
  String get search => '検索';

  @override
  String kanjiCount(int count) {
    return '漢字$count字';
  }

  @override
  String get sampleData => '補足コンテンツ';

  @override
  String get showMore => 'さらに表示';

  @override
  String strokeCount(int count) {
    return '$count画';
  }

  @override
  String get onReading => '音読み';

  @override
  String get kunReading => '訓読み';

  @override
  String get listenReading => '読み方を聞く';

  @override
  String get kanjiEmptyTitle => '漢字が見つかりません';

  @override
  String get kanjiLoadFailed => '漢字ライブラリを読み込めません';

  @override
  String get memoryTip => '覚え方のヒント';

  @override
  String get commonCompounds => 'よく使う熟語';

  @override
  String get savedToNotebook => '単語帳に保存済み';

  @override
  String radicalLabel(String radical) {
    return '部首: $radical';
  }

  @override
  String get stitchFixtureNotice => '補足内容は端末に保存されています。';

  @override
  String get reading => '読み方';

  @override
  String get noData => 'データがありません';

  @override
  String get viewStrokeOrder => '筆順の詳細を見る';

  @override
  String get sampleBadge => '補足';

  @override
  String strokeProgress(int current, int total) {
    return '$current/$total画';
  }

  @override
  String get restartStroke => '最初から再生';

  @override
  String get previousStroke => '前の画';

  @override
  String get nextStroke => '次の画';

  @override
  String get strokeProgressTitle => '画ごとの進捗';

  @override
  String strokeNumber(int number) {
    return '第$number画';
  }

  @override
  String get strokeRules => '筆順の規則';

  @override
  String get strokeFixtureWarning => 'この筆順例は学習の参考として表示しています。';

  @override
  String get strokeImageOnlyWarning => '現在は筆順画像のみ利用でき、画ごとの再生には対応していません。';

  @override
  String backToKanjiDetail(String character) {
    return '「$character」の詳細に戻る';
  }

  @override
  String get grammar => '文法';

  @override
  String get grammarDetail => '文法の詳細';

  @override
  String get grammarSearchHint => '文法表現または意味を検索…';

  @override
  String grammarPatternCount(int count) {
    return '$count文型';
  }

  @override
  String grammarStructureInline(String structure) {
    return '接続: $structure';
  }

  @override
  String get grammarEmptyTitle => '文法が見つかりません';

  @override
  String get grammarLoadFailed => '文法ライブラリを読み込めません';

  @override
  String get grammarMeaningNature => '意味とポイント';

  @override
  String get grammarStructure => '文法の接続';

  @override
  String get usage => '使い方';

  @override
  String get grammarFixtureNotice => '補足説明は端末に保存されています。';

  @override
  String get practicalExamples => '実用例';

  @override
  String get usageCautions => '使用上の注意';

  @override
  String get relatedGrammar => '関連・類似文法';

  @override
  String get collectionCreated => '新しいリストを作成しました。';

  @override
  String get wordAddedToNotebook => '単語帳に追加しました。';

  @override
  String get removeFromNotebookQuestion => '単語帳から削除しますか？';

  @override
  String removeEntryMessage(String term) {
    return '「$term」をリストと関連する復習キューから削除します。';
  }

  @override
  String get delete => '削除';

  @override
  String get removedFromNotebook => '単語帳から削除しました。';

  @override
  String get createCollection => '新しいリストを作成';

  @override
  String get collectionNameRequiredLabel => 'リスト名 *';

  @override
  String get collectionNameRequired => 'リスト名を入力してください。';

  @override
  String get optionalDescription => '説明（任意）';

  @override
  String get createCollectionAction => 'リストを作成';

  @override
  String get addNewWord => '単語を追加';

  @override
  String get notebookApiFieldsHint => '保存する単語、読み方、意味、メモを入力してください。';

  @override
  String get japaneseWordRequiredLabel => '日本語の単語 *';

  @override
  String get wordRequired => '保存する単語を入力してください。';

  @override
  String get optionalReading => '読み方（任意）';

  @override
  String get meaningRequiredLabel => '意味 *';

  @override
  String get meaningRequired => '単語の意味を入力してください。';

  @override
  String get optionalPersonalNote => 'メモ（任意）';

  @override
  String get yourCollections => '自分のコレクション';

  @override
  String get notebookSearchHint => '漢字、かな、意味を検索…';

  @override
  String get savedWords => '保存した単語';

  @override
  String savedItemCount(int count) {
    return '$count件保存済み';
  }

  @override
  String personalCollectionCount(int count) {
    return '個人リスト$count件';
  }

  @override
  String openWordDetail(String term) {
    return '「$term」の詳細を開く';
  }

  @override
  String get removeFromNotebook => '単語帳から削除';

  @override
  String get detail => '詳細';

  @override
  String get personalWord => '個人単語';

  @override
  String get savedItem => '保存済み項目';

  @override
  String get notebookEmptyTitle => '単語帳はまだ空です';

  @override
  String get notebookEmptyMessage => '最初のリストを作成して語彙を保存しましょう。';

  @override
  String get noMatchingWord => '一致する単語が見つかりません';

  @override
  String get collectionHasNoWords => 'このリストには単語がありません';

  @override
  String get notebookSearchEmptyMessage => '別のキーワードを試すか、現在の検索をクリアしてください。';

  @override
  String get notebookCollectionEmptyMessage => '最初の単語を追加して、このリストで復習を始めましょう。';

  @override
  String get notebookLoadFailed => '単語帳を読み込めません';

  @override
  String get checkConnectionShort => '通信環境を確認して再試行してください。';

  @override
  String get loadingRoadmap => '学習プランを読み込み中';

  @override
  String roadmapSummary(int chapters, int lessons) {
    return '$chapters章 • $lessonsレッスン';
  }

  @override
  String jlptRoadmap(String level) {
    return 'JLPT$level 学習プラン';
  }

  @override
  String jlptProgress(String level) {
    return 'JLPT$level 進捗';
  }

  @override
  String get fiveSkillBreakdown => '5技能の進捗詳細';

  @override
  String get lesson => 'レッスン';

  @override
  String get completeLesson => 'レッスン完了';

  @override
  String lessonNumber(int number) {
    return 'レッスン$number';
  }

  @override
  String get loadingContent => '内容を読み込み中';

  @override
  String chapterLessonSummary(int chapter, String category, String level) {
    return '第$chapter章 • $category $level';
  }

  @override
  String dayShort(int count) {
    return '$count日';
  }

  @override
  String get mainLearningSections => '主な学習コンテンツ';

  @override
  String get viewAll => 'すべて見る';

  @override
  String get roadmap => '学習プラン';

  @override
  String get lessonPlural => 'レッスン';

  @override
  String get overallProgressUpper => '全体の進捗';

  @override
  String overallProgressSemantics(int percentage) {
    return '全体の進捗は$percentageパーセントです';
  }

  @override
  String completedLessons(int completed, int total) {
    return '$totalレッスン中$completed件完了';
  }

  @override
  String studyStreak(int days) {
    return '連続学習: $days日 🔥';
  }

  @override
  String get continueRoadmap => '学習プランを続ける';

  @override
  String get inProgressUpper => '学習中';

  @override
  String chapterAndLesson(int chapter, int lesson) {
    return '第$chapter章 • レッスン$lesson';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get continueLearning => '続ける';

  @override
  String get learningLoadFailed => '学習内容を読み込めません';

  @override
  String get continueStudy => '学習を続ける';

  @override
  String get viewDetailedRoadmap => '学習プランの詳細を見る';

  @override
  String targetLevel(String level) {
    return '目標レベル: $level';
  }

  @override
  String get courseOverallProgress => 'コース全体の進捗';

  @override
  String courseProgressSemantics(int percentage) {
    return 'コース全体の進捗は$percentageパーセントです';
  }

  @override
  String completedOverallLessons(int completed, int total) {
    return '全$totalレッスン中$completed件完了';
  }

  @override
  String expectedExam(String date) {
    return '受験予定: $date';
  }

  @override
  String get skillProgressDetail => '技能別の進捗';

  @override
  String skillCount(int count) {
    return '5技能中$count技能';
  }

  @override
  String progressSemantics(String category, int percentage) {
    return '$categoryの進捗は$percentageパーセントです';
  }

  @override
  String get overallProgressTitle => '全体の進捗';

  @override
  String get onTrack => '予定どおり';

  @override
  String completedChapters(int completed, int total) {
    return '全$total章中$completed章完了';
  }

  @override
  String achievedLessons(int completed, int total) {
    return '全$totalレッスン中$completed件達成';
  }

  @override
  String get reviewResults => '結果を確認';

  @override
  String get continueLessonNineteen => '続き: レッスン19 – 〜たり〜たりする';

  @override
  String chapterNumberUpper(int number) {
    return '第$number章';
  }

  @override
  String lessonRange(int first, int last) {
    return '• レッスン$first～$last';
  }

  @override
  String get skillsAchievedUpper => '習得済み技能:';

  @override
  String get fiveSkillProgressUpper => '5技能の進捗:';

  @override
  String lessonCountUpper(int completed, int total) {
    return '$total件中$completedレッスン';
  }

  @override
  String get statusCompleted => '完了';

  @override
  String get statusLearning => '学習中';

  @override
  String get statusReady => '開始可能';

  @override
  String get statusNotStarted => '未開始';

  @override
  String lessonContentCount(int count) {
    return 'レッスン内容（$count項目）';
  }

  @override
  String totalDuration(int minutes) {
    return '合計時間 約$minutes分';
  }

  @override
  String get focusVocabulary => 'このレッスンの重要語彙';

  @override
  String vocabularyCount(int count) {
    return '語彙$count語';
  }

  @override
  String get relatedGrammarShort => '関連文法';

  @override
  String continueLessonProgress(int percentage) {
    return 'レッスンを続ける（$percentage%）';
  }

  @override
  String get startLesson => 'レッスンを始める';

  @override
  String get focusLabel => 'ポイント:';

  @override
  String partProgress(int current, int total) {
    return '$total項目中$current項目目';
  }

  @override
  String get lessonObjective => '学習目標';

  @override
  String streakMotivation(int days) {
    return '$days日連続学習中';
  }

  @override
  String get keepStreakMessage => 'このレッスンを終えて連続記録を守りましょう！';

  @override
  String get done => '完了';

  @override
  String get videoLoadFailed => '講義動画を読み込めません';

  @override
  String get watchingInProgress => '視聴途中';

  @override
  String get hdLecture => 'HD講義';

  @override
  String get pauseVideo => '動画を一時停止';

  @override
  String resumeVideoFrom(String time) {
    return '$timeから動画を再開';
  }

  @override
  String get articleFallbackMessage => '下の要約を使って学習を続けることもできます。';

  @override
  String get viewArticle => 'テキスト版を見る';

  @override
  String get contentTab => '内容';

  @override
  String notesTab(int count) {
    return 'メモ（$count）';
  }

  @override
  String vocabularyTab(int count) {
    return '語彙（$count）';
  }

  @override
  String get coreStructure => '基本構造';

  @override
  String get usageAndContext => '使い方と場面';

  @override
  String get practicalExamplesTitle => '代表的な実用例';

  @override
  String get importantGrammarNotes => '文法上の重要ポイント';

  @override
  String get importantVocabulary => 'レッスンの重要語彙';

  @override
  String wordsAppearing(int count) {
    return '$count語';
  }

  @override
  String topicUpper(String category) {
    return 'テーマ: $category';
  }

  @override
  String get topicSubtitle => '代表的な動作や状態を列挙する表現';

  @override
  String get openLessonVideo => 'レッスン動画を開く';

  @override
  String get excellentCompletion => 'すばらしい成果です';

  @override
  String get completionCongratulations => 'レッスン完了、おめでとうございます！';

  @override
  String lessonUpper(int number) {
    return 'レッスン $number';
  }

  @override
  String streakConsecutive(int days) {
    return '連続学習: $days日';
  }

  @override
  String get masteredContent => '今回身につけた内容';

  @override
  String masteredItemCount(int count) {
    return '$count/$count項目';
  }

  @override
  String nextLessonAction(int number) {
    return '次のレッスンへ（レッスン$number）';
  }

  @override
  String backToLevelRoadmap(String level) {
    return '$levelの学習プランに戻る';
  }

  @override
  String get nextLessonInRoadmap => '学習プランの次のレッスン';

  @override
  String get lockedContentUpper => '進捗によりロック中';

  @override
  String get lessonLockedDefault => 'このレッスンはまだ開放されていません。';

  @override
  String get unlockConditionUpper => '開放条件';

  @override
  String prerequisiteProgress(int completed, int total) {
    return '進捗: $total項目中$completed項目';
  }

  @override
  String remainingMinutes(int minutes) {
    return '残り約$minutes分';
  }

  @override
  String previewLesson(int number) {
    return 'レッスン$numberの内容をプレビュー';
  }

  @override
  String lessonPartsDuration(int parts, int minutes) {
    return '$parts項目 • 約$minutes分';
  }

  @override
  String continuePrerequisite(int number, int remaining) {
    return 'レッスン$numberを続ける（残り$remaining%）';
  }

  @override
  String get backToLearningRoadmap => '学習プランに戻る';

  @override
  String get lessonLoadFailed => 'レッスンを読み込めません';

  @override
  String get lessonProgressTitle => 'レッスンの進捗';

  @override
  String get completedUpper => '100% 完了';

  @override
  String learningProgressValue(int percentage) {
    return '$percentage% • 学習中';
  }

  @override
  String get notebookShort => '単語帳';

  @override
  String get processingSemantics => '処理中';

  @override
  String jlptLevelSemantics(String level) {
    return 'JLPTレベル $level';
  }

  @override
  String get vocabularyLoadMoreFailed => '語彙を追加で読み込めませんでした。もう一度お試しください。';

  @override
  String get fixtureDefaultNotebookName => 'レッスンから保存';

  @override
  String get notebookListsLoadFailed => '単語帳の一覧を読み込めませんでした。';

  @override
  String get vocabularySaveFailed => '語彙を単語帳に保存できませんでした。';

  @override
  String get kanjiLoadMoreFailed => '漢字を追加で読み込めませんでした。もう一度お試しください。';

  @override
  String get kanjiFixtureNotebookName => 'レッスンから保存';

  @override
  String get kanjiSaveFailed => '漢字を単語帳に保存できませんでした。';

  @override
  String get grammarLoadMoreFailed => '文法を追加で読み込めませんでした。もう一度お試しください。';

  @override
  String get notebookEntriesLoadFailed => 'リストの内容を読み込めませんでした。もう一度お試しください。';

  @override
  String get notebookCreateFailed => 'リストを作成できませんでした。もう一度お試しください。';

  @override
  String get notebookAddFailed => '単語帳に単語を追加できませんでした。もう一度お試しください。';

  @override
  String get notebookRemoveFailed => '単語帳から項目を削除できませんでした。もう一度お試しください。';

  @override
  String get notebookLocalRemoveFailed => '端末に保存した項目を更新できませんでした。';

  @override
  String get notebookLocalRestoreUnavailable =>
      '端末内の保存データを一時的に読み込めません。オンラインデータには影響しません。';

  @override
  String get selectLiveCollectionForManualEntry =>
      '手動で追加するには同期可能なリストを選択してください。';

  @override
  String get notebookKanjiLabel => '漢字';

  @override
  String get wordAndMeaningRequired => '日本語の単語と意味は必須です。';

  @override
  String grammarDetailSemantics(String title) {
    return '文法「$title」の詳細を開く';
  }

  @override
  String kanjiDetailSemantics(String character) {
    return '漢字「$character」の詳細を開く';
  }

  @override
  String get lessonDetailsComingSoon => 'レッスンの詳細は準備中です';

  @override
  String examDateLabel(String date) {
    return '試験日 $date';
  }

  @override
  String mockDurationStatus(int minutes, String status) {
    return '$minutes分 • $status';
  }

  @override
  String mockScoreReading(int score, int total, int percentage) {
    return '$score / $total • 読解: $percentage%';
  }

  @override
  String get successSemantics => '成功';

  @override
  String get skillVocabulary => '語彙';

  @override
  String get skillKanji => '漢字';

  @override
  String get skillGrammar => '文法';

  @override
  String get skillReading => '読解';

  @override
  String get skillListening => '聴解';

  @override
  String get unitWords => '語';

  @override
  String get unitCharacters => '字';

  @override
  String get unitLessons => 'レッスン';

  @override
  String get writing => '作文';

  @override
  String mockTestName(String level, String number) {
    return '模擬試験 $level #$number';
  }

  @override
  String levelProgress(String level) {
    return '$level進捗';
  }

  @override
  String get streakMetric => '連続学習';

  @override
  String get authErrorEmailNotVerified => 'ログインする前にメールアドレスを認証してください。';

  @override
  String get profileLoading => 'プロフィールを読み込んでいます...';

  @override
  String get profileLoadFailedTitle => 'プロフィールを読み込めませんでした';

  @override
  String get profileLoadFailedMessage => '現在プロフィール情報を読み込めません。もう一度お試しください。';

  @override
  String get profileEdit => 'プロフィールを編集';

  @override
  String get profileEditSubtitle => '表示する氏名を更新します。';

  @override
  String get profileProgressSubtitle => 'JLPT学習プランと進捗を確認します。';

  @override
  String get profileSettingsSubtitle => 'アカウント、セキュリティ、通知を管理します。';

  @override
  String get profileServicesSection => 'サービス';

  @override
  String get configure => '設定する';

  @override
  String get firstName => '名';

  @override
  String get lastName => '姓';

  @override
  String get firstNameHint => 'ミン・アイン';

  @override
  String get lastNameHint => 'グエン';

  @override
  String get validationFirstNameRequired => '名を入力してください。';

  @override
  String get validationLastNameRequired => '姓を入力してください。';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get savingChanges => '保存しています...';

  @override
  String get profileUpdateSuccess => 'プロフィールを更新しました。';

  @override
  String get profileUpdateFailed => 'プロフィールを更新できませんでした。もう一度お試しください。';

  @override
  String get learningProfile => '学習プロフィール';

  @override
  String get dailyStudyGoal => '1日の学習目標';

  @override
  String get notConfigured => '未設定';

  @override
  String get emailVerification => 'メール認証';

  @override
  String get verified => '認証済み';

  @override
  String get unverified => '未認証';

  @override
  String get editAvatar => 'プロフィール画像を変更';

  @override
  String get chooseAvatar => '端末から画像を選択';

  @override
  String get confirmAvatarTitle => 'プロフィール画像を更新しますか？';

  @override
  String get confirmAvatarMessage => 'JPEG、PNG、またはWEBP画像をプロフィールにアップロードします。';

  @override
  String get confirmUpload => 'アップロード';

  @override
  String get uploadingAvatar => '画像をアップロードしています...';

  @override
  String get avatarUploadSuccess => 'プロフィール画像を更新しました。';

  @override
  String get avatarUploadFailed => 'プロフィール画像を更新できませんでした。もう一度お試しください。';

  @override
  String get avatarUnsupportedType => 'JPEG、PNG、またはWEBP画像のみ使用できます。';

  @override
  String get avatarTooLarge => 'プロフィール画像は5MB以下にしてください。';

  @override
  String get avatarPickerFailed => 'この端末で画像ライブラリを開けませんでした。';

  @override
  String get notificationSettingsTitle => '通知設定';

  @override
  String get notificationSettingsSubtitle => '利用可能な設定はアカウントと同期されます。';

  @override
  String get emailNotifications => 'メール通知';

  @override
  String get emailNotificationsDescription => '学習に関する更新をメールで受け取ります。';

  @override
  String get systemNotifications => 'アプリ内通知';

  @override
  String get systemNotificationsDescription => 'RikiPathのシステム通知を受け取ります。';

  @override
  String get notificationUpdateSuccess => '通知設定を更新しました。';

  @override
  String get notificationUpdateFailed => '通知設定を更新できませんでした。変更は保存されていません。';

  @override
  String get jlptGoalSettings => 'JLPT目標';

  @override
  String get jlptGoalSettingsSubtitle => 'JLPT目標と1日の学習時間を確認します。';

  @override
  String get jlptGoalMappingUnavailableTitle => 'JLPT目標を変更できません';

  @override
  String get jlptGoalMappingUnavailableMessage =>
      '現在JLPT目標を同期できません。現在の選択はそのまま保持されます。';

  @override
  String get currentJlptGoal => '現在の目標';

  @override
  String get currentDailyStudyTime => '現在の学習時間';

  @override
  String get profileErrorUnauthorized => 'ログインセッションが無効です。もう一度ログインしてください。';

  @override
  String get profileErrorForbidden => 'このアカウントでは学習者プロフィールにアクセスできません。';

  @override
  String get profileErrorNetwork => 'サーバーに接続できません。通信環境を確認してもう一度お試しください。';

  @override
  String get profileErrorValidation => 'プロフィール情報が正しくありません。入力内容を確認してください。';

  @override
  String get profileErrorServer => 'プロフィールの処理を完了できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get profileErrorUnknown => 'プロフィールの処理中にエラーが発生しました。もう一度お試しください。';

  @override
  String get accountSecuritySection => 'セキュリティ';

  @override
  String get accountOptionsSection => '設定';

  @override
  String get accountSessionSection => 'セッション';

  @override
  String get accountVerifiedTitle => '確認済みのアカウント';

  @override
  String get accountUnverifiedTitle => '未確認のアカウント';

  @override
  String get logoutConfirmationTitle => 'RikiPathからログアウトしますか？';

  @override
  String get logoutConfirmationMessage => 'この端末で学習を続けるには、もう一度ログインする必要があります。';

  @override
  String get profileNameSection => '表示情報';

  @override
  String get notificationPreferencesSection => '通知設定';

  @override
  String get currentEmailLabel => '現在のメールアドレス';

  @override
  String get passwordRequirementsTitle => 'パスワード要件';

  @override
  String get passwordMinimumRequirement => '新しいパスワードは6文字以上';

  @override
  String get jlptSelectionTitle => 'JLPT目標を選択';

  @override
  String get dailyStudySelectionTitle => '1日の学習時間';

  @override
  String get jlptSelectionSafeHint => '選択内容はこの端末に保存され、あとから変更できます。';

  @override
  String get profileConsultationSubtitle => '相談プランと予約状況を確認できます。';

  @override
  String get savedFromLessons => 'レッスンで保存した単語';

  @override
  String get localJlptPreferenceSaved => '端末に学習目標を保存しました';

  @override
  String get dailyReviewTitle => '今日の復習';

  @override
  String get reviewLoadingTitle => '復習カードを準備しています…';

  @override
  String reviewProgress(int current, int total) {
    return '$current / $total 枚';
  }

  @override
  String get reviewRecallPrompt => 'この内容を覚えていますか？';

  @override
  String get revealAnswer => '答えを見る';

  @override
  String get reviewAgain => 'もう一度';

  @override
  String get reviewHard => '難しい';

  @override
  String get reviewGood => '覚えた';

  @override
  String get reviewEasy => '簡単';

  @override
  String get reviewCompleteTitle => '復習が完了しました';

  @override
  String reviewCompleteCount(int count) {
    return 'このセッションで$count枚を復習しました。';
  }

  @override
  String reviewResponseCount(String label, int count) {
    return '$label：$count';
  }

  @override
  String get reviewAgainAction => 'もう一度復習する';

  @override
  String get backToPractice => '練習に戻る';

  @override
  String get reviewQueueEmpty => '今日は復習するカードがありません。';

  @override
  String get reviewLoadFailed => '復習を読み込めませんでした';

  @override
  String reviewDueCount(int count) {
    return '$count枚のカードが復習待ちです';
  }

  @override
  String get mockLoadingTitle => '模擬試験を準備しています…';

  @override
  String get mockLoadFailed => '模擬試験を読み込めませんでした。';

  @override
  String get mockTestUnavailable => 'この模擬試験は現在利用できません。';

  @override
  String get leaveMockTitle => '試験を終了しますか？';

  @override
  String get leaveMockMessage => '戻ったときに現在の解答は保持されます。';

  @override
  String get continueAction => '試験を続ける';

  @override
  String get leaveAction => '試験を終了';

  @override
  String get submitMockTitle => '模擬試験を提出しますか？';

  @override
  String get submitMockMessage => '未回答の問題があっても提出できます。採点は端末内で行われます。';

  @override
  String get submitAction => '提出する';

  @override
  String mockMinutes(int minutes) {
    return '時間：$minutes分';
  }

  @override
  String mockQuestionCount(int count) {
    return '問題数：$count';
  }

  @override
  String get mockLocalScoringNotice => 'この練習問題は端末内で採点され、公式JLPT結果ではありません。';

  @override
  String get startMockTest => '試験を始める';

  @override
  String questionProgress(int current, int total) {
    return '問題 $current / $total';
  }

  @override
  String get previousQuestion => '前の問題';

  @override
  String get nextQuestion => '次の問題';

  @override
  String get mockResultTitle => '模擬試験の結果';

  @override
  String get mockResultUnavailable => 'この試験の結果はまだありません。';

  @override
  String mockCorrectCount(int correct, int total) {
    return '$total問中$correct問正解';
  }

  @override
  String get mockLocalResultNotice => 'この結果は練習用で、公式JLPTスコアではありません。';

  @override
  String get sectionBreakdown => 'セクション別結果';

  @override
  String mockSectionResult(int correct, int total, int percentage) {
    return '$total問中$correct問正解・$percentage%';
  }

  @override
  String get detailedReview => '解答を詳しく確認';

  @override
  String get retakeMockTest => 'もう一度受ける';

  @override
  String questionNumber(int number) {
    return '問題 $number';
  }

  @override
  String selectedAnswer(String answer) {
    return '選んだ答え：$answer';
  }

  @override
  String correctAnswer(String answer) {
    return '正解：$answer';
  }

  @override
  String get notAnswered => '未回答';

  @override
  String get practiceLoadingTitle => '練習内容を準備しています…';

  @override
  String get practiceJourneyTitle => '自分のペースで練習';

  @override
  String get practiceJourneySubtitle => '復習、JLPT模擬試験、学習の振り返りを一つの流れで進めます。';

  @override
  String mockSummary(String level, int minutes, int count) {
    return '$level・$minutes分・$count問';
  }

  @override
  String mockInProgress(int answered, int total) {
    return '$total問中$answered問回答済み';
  }

  @override
  String mockCompletedStatus(int percentage) {
    return '完了・$percentage%';
  }

  @override
  String get additionalPractice => '追加練習';

  @override
  String get aiWritingPractice => 'AIと作文練習';

  @override
  String get practiceAnswerLabel => '練習の回答';

  @override
  String get gradePractice => '練習を採点';

  @override
  String get gradingPractice => '採点中…';

  @override
  String aiGradingResult(int score, String feedback) {
    return 'スコア $score/100・$feedback';
  }

  @override
  String get mentorConsultation => 'メンター相談';

  @override
  String get openDemoBooking => '相談予定をプレビュー';

  @override
  String get confirmDemoBooking => 'プレビューを確認';

  @override
  String get demoBookingConfirmed => '相談予定のプレビューを完了しました。';

  @override
  String get practiceLoadFailed => '練習内容を読み込めませんでした';

  @override
  String get learningAnalyticsTitle => '学習進捗';

  @override
  String get analyticsLoadingTitle => '学習進捗を集計しています…';

  @override
  String get analyticsEmpty => '表示できる学習データがまだありません。';

  @override
  String get studyStreakLabel => '連続学習日数';

  @override
  String streakDaysValue(int days) {
    return '$days日';
  }

  @override
  String get completedLessonsLabel => '完了したレッスン';

  @override
  String analyticsCompletedLessons(int completed, int total) {
    return '$completed / $total レッスン';
  }

  @override
  String get skillBreakdown => 'スキル別進捗';

  @override
  String get analyticsSkillsEmpty => 'スキルデータがまだありません。';

  @override
  String get analyticsSectionUnavailable => 'このデータは一時的に読み込めません。';

  @override
  String get analyticsLoadFailed => '学習進捗を読み込めませんでした';

  @override
  String get markAllNotificationsRead => 'すべて既読';

  @override
  String get notificationsEmpty => 'アプリ内通知はまだありません。';

  @override
  String get notificationsLoadFailed => '通知を読み込めませんでした';

  @override
  String get notebookEntryTitle => '保存した単語';

  @override
  String get notebookEntryUnavailable => 'この保存項目は利用できなくなりました。';

  @override
  String get homeChooseJlptTitle => 'JLPT目標を選んで始めましょう';

  @override
  String get homeChooseJlptDescription => 'N5・N4・N3から選ぶと、RikiPathが学習プランを準備します。';

  @override
  String get homeChooseJlptAction => '目標を選ぶ';

  @override
  String get homeContinueLearningTitle => '学習を続ける';

  @override
  String homeCurrentLessonMeta(int lesson, int minutes) {
    return 'レッスン$lesson・$minutes分';
  }

  @override
  String get homeRoadmapProgressTitle => '学習プランの進捗';

  @override
  String get homeRoadmapProgressDescription => 'レッスン進捗はこの端末に保存されています。';

  @override
  String homeRoadmapProgressValue(int completed, int total, int percentage) {
    return '$completed/$totalレッスン・$percentage%';
  }

  @override
  String get homeLiveProgressTitle => '学習統計';

  @override
  String get homeLiveProgressDescription => 'RikiPathアカウントから集計したデータです。';

  @override
  String get homeViewProgress => '進捗を見る';

  @override
  String get homeAnalyticsUnavailable => 'オンライン統計を一時的に読み込めません。';

  @override
  String get homeReviewDescription => '現在の学習ペースに合わせて復習しましょう。';

  @override
  String get homeResumeReview => '復習を続ける';

  @override
  String get homeReviewNow => '今すぐ復習';

  @override
  String get homePracticeTitle => '模擬練習';

  @override
  String get homeStartPractice => '練習を始める';

  @override
  String get homeResumeMock => '模擬試験を続ける';

  @override
  String get homeResumeMockDescription => 'この端末の解答は保存されています。';

  @override
  String get homeRecentMockResult => '最近の結果';

  @override
  String homeRecentMockScore(int score, int total, int percentage) {
    return '$total問中$score問正解・$percentage%';
  }

  @override
  String get homeViewResult => '結果を見る';

  @override
  String get homeNotebookShortcutTitle => '単語ノート';

  @override
  String get homeNotebookShortcutDescription => '保存した単語や学習内容を確認します。';

  @override
  String get homeSectionUnavailable => 'このセクションを一時的に読み込めません。';

  @override
  String get homeRefreshSemantics => '学習統計と通知を更新';

  @override
  String get commonErrorNetwork => 'RikiPathに接続できません。通信環境を確認して再試行してください。';

  @override
  String get commonErrorUnauthorized => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get commonErrorForbidden => 'この操作を行う権限がありません。';

  @override
  String get commonErrorNotFound => 'この内容は現在利用できません。';

  @override
  String get commonErrorConflict => 'データが更新されました。読み込み直してお試しください。';

  @override
  String get commonErrorValidation => '入力内容を確認してください。';

  @override
  String get commonErrorServer => 'RikiPathで問題が発生しています。しばらく後に再試行してください。';

  @override
  String get commonErrorUnknown => '操作を完了できませんでした。再試行してください。';

  @override
  String get notificationsUpdateFailed => '通知を更新できませんでした';

  @override
  String get notificationsCountUnavailable => '未読数を一時的に更新できません。';

  @override
  String analyticsSkillScore(String score, int attempts) {
    return '$score%・$attempts回';
  }

  @override
  String get learnerMentorTitle => 'メンター相談';

  @override
  String get learnerMentorSubtitle => '学習プランに合うパッケージと時間を選びましょう。';

  @override
  String get learnerMentorExplore => '見る';

  @override
  String get learnerMentorPlansTitle => '相談パッケージ';

  @override
  String get learnerMentorPlansEmpty => '現在利用できる相談パッケージはありません。';

  @override
  String get learnerMentorPlansError => '相談パッケージを読み込めませんでした。';

  @override
  String get learnerMentorMyMeetings => '相談予定';

  @override
  String learnerMentorPlanDuration(int days) {
    return '有効期間 $days日';
  }

  @override
  String learnerMentorPlanSessions(int count) {
    return '相談 $count回';
  }

  @override
  String get learnerMentorChoosePlan => 'パッケージを選ぶ';

  @override
  String get learnerMentorAvailabilityTitle => '相談日時を選ぶ';

  @override
  String get learnerMentorAvailabilitySubtitle => '今後30日間の空き時間です。';

  @override
  String get learnerMentorAvailabilityEmpty => '選択した日に空き時間はありません。';

  @override
  String get learnerMentorAvailabilityError => 'メンターの空き時間を読み込めませんでした。';

  @override
  String learnerMentorSlotTime(String start, String end) {
    return '$start～$end';
  }

  @override
  String get learnerMentorSelectSlot => '時間を選ぶ';

  @override
  String get learnerMentorPurchase => '支払いへ進む';

  @override
  String get learnerMentorPurchaseBlockedTitle => '予約は一時停止中です';

  @override
  String get learnerMentorPurchaseBlocked =>
      'パッケージと空き時間は確認できます。同じ時間の重複予約を防ぐ安全な枠確保がBackendで保証された後に、支払いを有効にします。';

  @override
  String get learnerMentorBookingsEmpty => 'メンター相談の予定はまだありません。';

  @override
  String get learnerMentorBookingsError => '相談予定を読み込めませんでした。';

  @override
  String get learnerMentorMeetingDetailTitle => '相談の詳細';

  @override
  String get learnerMentorMeetingNotFound => 'この相談予定は見つかりませんでした。';

  @override
  String get learnerMentorMentorLabel => 'メンター';

  @override
  String get learnerMentorPaymentLabel => '支払い';

  @override
  String get learnerMentorJoin => '相談に参加';

  @override
  String get learnerMentorJoinUnavailable => 'ミーティングルームが未準備、またはリンクが安全ではありません。';

  @override
  String get learnerMentorPurchaseStatus => 'パッケージの状態';

  @override
  String get learnerMentorPurchaseStatusError => '支払い状態を読み込めませんでした。';

  @override
  String get learnerMentorPaymentPending => '支払い待ち';

  @override
  String get learnerMentorPaymentPaid => '支払い済み';

  @override
  String get learnerMentorPaymentFailed => '支払い失敗';

  @override
  String get learnerMentorPaymentRefunded => '返金済み';

  @override
  String get learnerMentorPaymentUnknown => '不明';

  @override
  String learnerMentorSessionsUsage(int used, int included) {
    return '$included回中$used回利用';
  }

  @override
  String get learnerMentorRefreshStatus => '状態を再確認';

  @override
  String get learnerMentorStatusPolling =>
      'RikiPathはBackendの状態を確認します。支払い画面から戻っただけでは支払い完了になりません。';

  @override
  String get learnerMentorUnknownMentor => 'メンター未定';

  @override
  String get learnerMentorCheckoutExpired => '支払いリンクの有効期限が切れました';

  @override
  String get learnerMentorBookingReadOnly => '予約情報はBackendから直接同期されています。';

  @override
  String get practiceSpeechTitle => '日本語スピーキング練習';

  @override
  String get practiceSpeechDescription => '日本語を話して、リアルタイムの認識結果を確認できます。';

  @override
  String get practiceSpeechStatus => 'リアルタイム認識';

  @override
  String get practiceTextScanTitle => '日本語テキストスキャン';

  @override
  String get practiceTextScanDescription => '作文の画像から日本語テキストを読み取り、編集できます。';

  @override
  String get practiceTextScanStatus => '画像 → テキスト';

  @override
  String get speechPracticeTitle => 'スピーキング練習';

  @override
  String get speechPracticeHeading => '音声をテキストに変換';

  @override
  String get speechPracticeSubtitle => '日本語の文を自然に読んでみましょう。話した内容がリアルタイムで表示されます。';

  @override
  String get speechSampleLabel => '練習文';

  @override
  String get speechSampleSentence => '日本語の話し方を練習しています。';

  @override
  String get speechTranscriptLabel => '認識したテキスト';

  @override
  String get speechTranscriptEmpty => '話し始めると、認識した日本語がここに表示されます。';

  @override
  String get speechStart => '話し始める';

  @override
  String get speechStop => '録音を停止';

  @override
  String get speechConnecting => 'マイクを準備中...';

  @override
  String get speechRetry => 'もう一度試す';

  @override
  String get speechSpeakAgain => 'もう一度練習';

  @override
  String get speechCopy => 'テキストをコピー';

  @override
  String get speechClear => '内容を消去';

  @override
  String get speechCopied => 'テキストをコピーしました';

  @override
  String get speechPermissionTitle => 'マイクの許可が必要です';

  @override
  String get speechPermissionMessage =>
      '端末の設定でRikiPathのマイク使用を許可してから、もう一度お試しください。';

  @override
  String get speechNetworkTitle => '接続できません';

  @override
  String get speechNetworkMessage => '通信環境を確認して、スピーキング練習を再開してください。';

  @override
  String get speechProviderTitle => '音声認識が中断されました';

  @override
  String get speechProviderMessage => '少し待ってから再開してください。認識済みの内容は保持されています。';

  @override
  String get speechListeningTitle => '聞き取り中です';

  @override
  String get speechListeningMessage => 'はっきり話し、端末を近くに置いてください。';

  @override
  String get speechReadyMessage => 'マイクは開始ボタンを押したときだけ動作し、画面を離れると停止します。';

  @override
  String get textScanTitle => 'テキストスキャン';

  @override
  String get textScanHeading => '日本語の手書き文字を認識';

  @override
  String get textScanSubtitle => '鮮明なJPG・PNG・WEBP画像を選んでください。結果は端末上で編集、コピーできます。';

  @override
  String get textScanChooseImage => 'ライブラリから画像を選ぶ';

  @override
  String get textScanSelecting => 'ライブラリを開いています...';

  @override
  String get textScanDropTitle => '日本語作文の画像を選択';

  @override
  String get textScanRequirements => 'JPG・PNG・WEBP • 最大10 MB';

  @override
  String get textScanPrivacyNote =>
      '画像は文字認識のためRikiPathサービスへ送信されますが、保存済み作文としては表示されません。';

  @override
  String get textScanAction => 'テキストをスキャン';

  @override
  String get textScanScanning => '文字を認識中...';

  @override
  String get textScanChooseAnother => '別の画像を選ぶ';

  @override
  String get textScanClear => '画像と結果を消去';

  @override
  String get textScanResultLabel => '認識結果';

  @override
  String get textScanResultHint => '認識したテキストがここに表示されます。';

  @override
  String get textScanLocalEditNote => 'この画面での編集内容は、まだアカウント履歴に保存されません。';

  @override
  String get textScanCopy => '結果をコピー';

  @override
  String get textScanCopied => '結果をコピーしました';

  @override
  String get textScanUnsupportedType => 'JPG・PNG・WEBP画像のみ対応しています。';

  @override
  String get textScanTooLarge => '画像が10 MBを超えています。小さい画像を選んでください。';

  @override
  String get textScanPickerFailedTitle => '写真ライブラリを開けません';

  @override
  String get textScanPickerError => '写真へのアクセス権を確認して、もう一度お試しください。';

  @override
  String get textScanFailedTitle => '画像をスキャンできません';

  @override
  String get textScanNetworkError => '通信環境を確認して、もう一度スキャンしてください。';

  @override
  String get textScanProviderError => '文字認識サービスは現在利用できません。画像は再試行できるよう保持されています。';

  @override
  String get textScanCompleted => '認識が完了しました。テキストを確認、編集、コピーできます。';

  @override
  String get practiceStudioTitle => 'Studio Riki';

  @override
  String get practiceStudioSubtitle => '話す・書く・読み取るインタラクティブな練習ツールです。';

  @override
  String get practiceWritingTitle => 'かな・漢字の書き取り';

  @override
  String get practiceWritingDescription => '書き順を確認し、画面に書いて復習記録を保存します。';

  @override
  String get practiceWritingStatus => 'インタラクティブ書写';

  @override
  String get writingTitle => '書き取り練習';

  @override
  String get writingSubtitle => '文字を選び、正しい書き順と方向で練習しましょう。';

  @override
  String get writingHiragana => 'ひらがな';

  @override
  String get writingKatakana => 'カタカナ';

  @override
  String get writingKanji => '漢字';

  @override
  String get writingDue => '復習';

  @override
  String get writingAll => 'すべて';

  @override
  String get writingQueueHint => '復習期限の文字を優先し、その後に承認済みの新しい文字を表示します。';

  @override
  String get writingSelectCharacter => '練習する文字を選択';

  @override
  String get writingEmptyTitle => '練習できる文字がありません';

  @override
  String writingKanaEmptyMessage(String script) {
    return 'Backendから承認済みの$script文字が返されていません。';
  }

  @override
  String get writingKanjiEmptyMessage => 'この一覧には現在練習できる漢字がありません。';

  @override
  String get writingLoadFailed => '書き取り一覧を読み込めませんでした';

  @override
  String writingStrokeCount(int count) {
    return '$count画';
  }

  @override
  String get writingNewCharacter => '新規';

  @override
  String get writingReviewCharacter => '復習';

  @override
  String writingLastScore(int score) {
    return '前回 $score/100';
  }

  @override
  String get writingMeaningUnavailable => '意味は未登録です';

  @override
  String get writingTargetLabel => '練習する文字';

  @override
  String get writingOnReading => '音読み';

  @override
  String get writingKunReading => '訓読み';

  @override
  String get writingReadingUnavailable => '未登録';

  @override
  String get writingGuidedMode => 'なぞり書き';

  @override
  String get writingFreeMode => '自分で書く';

  @override
  String get writingGuidedHint => '薄いガイドに沿って、正しい順番と方向で書いてください。';

  @override
  String get writingFreeHint => '見本を隠して、書き順と方向を思い出しながら書きます。';

  @override
  String get writingGestureHint => '枠内で指を動かして書く • 枠外でスクロール';

  @override
  String get writingShowStrokes => '書き順を見る';

  @override
  String get writingStart => '書き始める';

  @override
  String get writingRewrite => 'もう一度書く';

  @override
  String get writingNext => '次の文字';

  @override
  String get writingLoadingStrokeData => '書き順データを準備中...';

  @override
  String get writingStrokeDataFailedTitle => '書き順を読み込めません';

  @override
  String get writingStrokeDataFailedMessage =>
      '通信環境を確認して再試行してください。一度読み込んだデータはオフラインでも利用できます。';

  @override
  String get writingQuizInProgress => '書き取り中・順番どおりに一画ずつ書いてください';

  @override
  String get writingAnimationInProgress => '書き順を表示中...';

  @override
  String get writingCompleteTitle => '書き取り完了';

  @override
  String writingMistakeCount(int count) {
    return '間違い $count回';
  }

  @override
  String writingResultScore(int score) {
    return 'スコア $score/100';
  }

  @override
  String get writingSavingResult => '学習記録を保存中...';

  @override
  String get writingResultSaved => '次の復習予定を保存しました';

  @override
  String get writingResultSaveFailed =>
      '結果は端末に保持されていますが、RikiPathにはまだ保存できていません。';

  @override
  String get writingRetrySave => 'もう一度保存';

  @override
  String writingProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get orDivider => 'または';

  @override
  String get meetingTitle => 'ミーティングルーム';

  @override
  String get meetingJoinTitle => 'ミーティングに参加';

  @override
  String get meetingJoinAction => 'ミーティングに参加';

  @override
  String get meetingContinueAction => '次へ';

  @override
  String get meetingLandingDescription =>
      '共有されたミーティングリンクを入力してください。RikiPathが安全にブラウザでルームを開きます。';

  @override
  String get meetingJoinDescription =>
      'http:// または https:// で始まる完全なリンクを貼り付けてください。';

  @override
  String get meetingLinkLabel => 'ミーティングリンク';

  @override
  String get meetingLinkHint => 'https://example.com/meeting/...';

  @override
  String get meetingLinkRequired => 'ミーティングリンクを入力してください。';

  @override
  String get meetingLinkInvalid =>
      'リンクが正しくありません。完全な http または https アドレスのみ使用できます。';

  @override
  String get meetingAuthorizationNotice =>
      'リンクだけでは参加権限は付与されません。ルーム側でアカウントと参加権限が確認されます。';

  @override
  String get meetingAuthRequiredTitle => 'ログインしてミーティングに参加';

  @override
  String get meetingAuthRequiredDescription =>
      'リンクはこの端末に一時的に保持されます。ログイン後、参加画面に戻ります。';

  @override
  String get meetingReadyTitle => 'ミーティングを開く準備ができました';

  @override
  String get meetingEnterRoom => 'ルームに入る';

  @override
  String get meetingOpenFailedTitle => 'ミーティングを開けません';

  @override
  String get meetingOpenFailedDescription => 'ブラウザと通信環境を確認して、もう一度お試しください。';

  @override
  String get meetingDetailsAction => '詳細';

  @override
  String get homeMeetingFallbackTitle => 'ミーティングルーム';

  @override
  String get homeMeetingFallbackDescription => 'ミーティングリンクから参加します。';

  @override
  String get homeUpcomingMeetingTitle => '次の相談予定';

  @override
  String homeMeetingSchedule(String date, String time) {
    return '$date • $time';
  }
}
