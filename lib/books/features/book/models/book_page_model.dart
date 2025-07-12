class BookPageModel {
  final int audio;
  final List<String> mp3;
  final String pageText;

  BookPageModel({
    required this.audio,
    required this.mp3,
    required this.pageText,
  });

  factory BookPageModel.fromJson(Map<String, dynamic> json) {
    return BookPageModel(
      audio: json['audio'] as int,
      mp3: List<String>.from(json['mp3'] as List),
      pageText: json['pageText'] as String,
    );
  }
}
