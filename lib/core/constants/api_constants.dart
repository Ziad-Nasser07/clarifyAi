class ApiConstants {
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String groqChatUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqTextModel = 'openai/gpt-oss-120b';
  static const String groqVisionModel = 'qwen/qwen3.8-27b';

  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String youtubeSearchEndpoint = '$youtubeBaseUrl/search';

  static const String tavilyBaseUrl = 'https://api.tavily.com';
  static const String tavilySearchEndpoint = '$tavilyBaseUrl/search';

  static const String usersCollection = 'users';
  static const String librariesCollection = 'libraries';
  static const String sessionsCollection = 'sessions';
}
