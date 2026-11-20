class ApiConstants {
  // Vertex AI Express Endpoint (يعمل مع مفاتيح AQ.Ab8...)
  static const String geminiVertexUrl =
      'https://aiplatform.googleapis.com/v1/publishers/google/models/gemini-2.5-flash:generateContent';

  // YouTube Data API v3
  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String youtubeSearchEndpoint = '$youtubeBaseUrl/search';

  // Tavily Search API
  static const String tavilyBaseUrl = 'https://api.tavily.com';
  static const String tavilySearchEndpoint = '$tavilyBaseUrl/search';

  // مجموعات Firestore
  static const String usersCollection = 'users';
  static const String librariesCollection = 'libraries';
  static const String sessionsCollection = 'sessions';
}