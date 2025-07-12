class QuranBook {
  final String id;
  final String title;
  final int totalPages;
  final String selectedFormat;

  static const Map<String, Map<String, dynamic>> quranFormats = {
    'Hat 1': {
      'url': 'https://kuran-ikerim.org/resimler/hayrat700px/',
      'extension': 'jpg'
    },
    'Hat 2': {
      'url': 'https://kuran-ikerim.org/resimler/hizmethamit_2048px/',
      'extension': 'png'
    },
    'Mukabele': {'url': '', 'extension': '', 'isTakipli': true},
  };

  QuranBook({
    this.id = 'quran',
    this.title = "Kur'an-ı Kerim",
    this.totalPages = 604,
    this.selectedFormat = 'Hat 1',
  });

  String getPageImageUrl(int pageNumber) {
    int apiPageNumber = pageNumber + 1;

    if (pageNumber < 0 || pageNumber > 604) {
      throw ArgumentError('Page number must be between 0 and 604');
    }

    final formatData = quranFormats[selectedFormat];
    if (formatData != null) {
      return '${formatData['url']}$apiPageNumber.${formatData['extension']}';
    }

    // Default to Hayrat Vakfı format if selected format is not found
    return 'https://kuran-ikerim.org/resimler/hayrat700px/$apiPageNumber.jpg';
  }

  String getPageAudioUrl(int pageNumber) {
    if (pageNumber < 0 || pageNumber > 604) {
      throw ArgumentError('Page number must be between 0 and 604');
    }

    return 'https://storage.feyyaz.org/apps/sharingpath/depo.feyyaz.org/public/kuranikerim.org/mm/kuranses2/$pageNumber.mp3';
  }

  bool isValidPage(int pageNumber) {
    return pageNumber >= 0 && pageNumber <= 604;
  }

  bool isValidAudioPage(int pageNumber) {
    return pageNumber >= 0 && pageNumber <= 604;
  }

  List<String> getAvailableFormats() {
    return quranFormats.keys.toList();
  }

  QuranBook copyWith({
    String? id,
    String? title,
    int? totalPages,
    String? selectedFormat,
  }) {
    return QuranBook(
      id: id ?? this.id,
      title: title ?? this.title,
      totalPages: totalPages ?? this.totalPages,
      selectedFormat: selectedFormat ?? this.selectedFormat,
    );
  }
}
