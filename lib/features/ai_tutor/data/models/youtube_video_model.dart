class YoutubeVideoModel {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnailUrl;

  YoutubeVideoModel({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
  });

  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';

  factory YoutubeVideoModel.fromYoutubeApi(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final idMap = json['id'] as Map<String, dynamic>;
    return YoutubeVideoModel(
      videoId: idMap['videoId'] ?? '',
      title: snippet['title'] ?? '',
      channelName: snippet['channelTitle'] ?? '',
      thumbnailUrl: snippet['thumbnails']?['high']?['url'] ??
          snippet['thumbnails']?['default']?['url'] ??
          '',
    );
  }

  factory YoutubeVideoModel.fromMap(Map<String, dynamic> map) {
    return YoutubeVideoModel(
      videoId: map['videoId'] ?? '',
      title: map['title'] ?? '',
      channelName: map['channelName'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}