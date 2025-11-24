class Env {
  static const String openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const String sentryDSN = String.fromEnvironment('SENTRY_DSN');
  
  static bool get isDevelopment => const String.fromEnvironment('ENV') == 'development';
  static bool get isProduction => const String.fromEnvironment('ENV') == 'production';
}
