class AppConfig {
  AppConfig._();

  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_placeholder',
  );

  static const String streamBaseUrl = String.fromEnvironment(
    'STREAM_BASE_URL',
    defaultValue: '',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.lionfm.online',
  );

  static const String appBaseUrl = 'https://www.lionfm.online';

  /// Google OAuth 2.0 Web Client ID — required for Google Sign-In on Flutter
  /// web. Obtain this from: Firebase Console → Authentication → Sign-in
  /// method → Google → Web SDK configuration → Web client ID.
  /// Inject at build time via --dart-define=GOOGLE_WEB_CLIENT_ID=xxx or
  /// set it directly in the string below.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com',
  );
}
