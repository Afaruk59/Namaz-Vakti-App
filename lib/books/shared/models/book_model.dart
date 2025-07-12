class Book {
  final String code;
  final String title;
  final String coverImageUrl;
  final bool isQuran;
  final String author;
  final String description; // Kitap açıklaması

  Book({
    required this.code,
    String? coverImageUrl,
    this.isQuran = false,
    String? title,
    String? author,
    String? description,
  })  : coverImageUrl = coverImageUrl ?? 'assets/book_covers/${code}.png',
        title = title ?? (isQuran ? "Kur'an-ı Kerim" : "Kitap $code"),
        author = author ?? "Hakikat Kitabevi",
        description = description ??
            (isQuran
                ? "Kur'an-ı Kerim'in Türkçe ve Arapça tam metni."
                : "Bu kitap $code numaralı kitaptır. Açıklama eklenmedi.");

  // Sample book for testing
  Book.sample()
      : code = '001',
        isQuran = false,
        coverImageUrl = 'assets/book_covers/001.png',
        title = "Kitap 001",
        author = "Hakikat Kitabevi",
        description = "Bu örnek kitap, test amaçlıdır.";

  Book.quran()
      : code = 'quran',
        isQuran = true,
        coverImageUrl = 'assets/book_covers/quran.png',
        title = "Kur'an-ı Kerim",
        author = "Diyanet İşleri Başkanlığı",
        description = "Kur'an-ı Kerim'in tam metni ve Türkçe meali.";

  // Create a list of sample books
  static List<Book> samples() {
    List<Book> books = [Book.quran()];
    books.addAll(List.generate(14, (index) {
      final code = (index + 1).toString().padLeft(3, '0');
      return Book(
          code: code, isQuran: false, description: "Açıklama eklenmedi.");
    }));
    return books;
  }
}
