// API Configuration
// IMPORTANT: Never commit API keys to version control
class ApiConfig {
  // Tenor GIF API Key
  // Get your free key at: https://developers.google.com/tenor/guides/quickstart
  // For production, use environment variables or Firebase Remote Config
  static const String tenorApiKey = 'AIzaSyABhG8AuvmS_NnDBa9GyvsP4UGITIg7F1Y';

  static bool get hasValidTenorKey => tenorApiKey.isNotEmpty;
}
