class AppConfig {
  AppConfig._();

  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_placeholder',
  );

  static const String streamBaseUrl = String.fromEnvironment(
    'STREAM_BASE_URL',
    defaultValue: 'https://stream.lionfm.unn.edu.ng',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.lionfm.unn.edu.ng',
  );
}
