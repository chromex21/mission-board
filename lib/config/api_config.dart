// API Configuration
// IMPORTANT: Never commit API keys to version control
class ApiConfig {
  // Tenor GIF API Key
  // Get your free key at: https://developers.google.com/tenor/guides/quickstart
  // For production, use environment variables or Firebase Remote Config
  static const String tenorApiKey = String.fromEnvironment(
    'TENOR_API_KEY',
    defaultValue: '', // Empty in production - must be configured
  );
  
  static bool get hasValidTenorKey => tenorApiKey.isNotEmpty;
}
