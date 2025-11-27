// Environment configuration
// NOTE: Never commit real API keys. Use environment variables or Firebase Remote Config
class Env {
  static const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
  static const String stripeSecretKey = String.fromEnvironment('STRIPE_SECRET_KEY', defaultValue: '');
  
  // Development/Demo keys (replace with real ones)
  static const String openaiApiKeyDemo = 'demo_key_replace_with_real';
  static const String stripePublishableKeyDemo = 'pk_test_demo_key_replace_with_real';
  
  // Current keys to use (prefer environment variables)
  static String get currentOpenaiKey => openaiApiKey.isNotEmpty ? openaiApiKey : openaiApiKeyDemo;
  static String get currentStripeKey => stripePublishableKey.isNotEmpty ? stripePublishableKey : stripePublishableKeyDemo;
}