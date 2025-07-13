class ApiConfig {
  // Template file - copy this to api_config.dart and add your actual API keys

  // Google Cloud API Key for Weather and Maps services
  static const String googleCloudApiKey = 'YOUR_API_KEY_HERE';

  /// Returns true if the API key is set and not the default placeholder.
  static bool get isValid =>
      googleCloudApiKey.isNotEmpty && googleCloudApiKey != 'YOUR_API_KEY_HERE';

  // Add other API keys here as needed
  // static const String otherApiKey = 'YOUR_OTHER_API_KEY_HERE';
}
