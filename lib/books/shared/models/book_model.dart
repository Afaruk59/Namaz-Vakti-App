class Book {
  final String code;
  final String title;
  final String coverImageUrl;
  final String author;
  final String description; // Kitap açıklaması

  Book({
    required this.code,
    String? coverImageUrl,
    String? title,
    String? author,
    String? description,
  })  : coverImageUrl = coverImageUrl ?? 'assets/book_covers/$code.png',
        title = title ?? "Kitap $code",
        author = author ?? "Hakikat Kitabevi",
        description = description ?? "Bu kitap $code numaralı kitaptır. Açıklama eklenmedi.";

  // Sample book for testing
  Book.sample()
      : code = '001',
        coverImageUrl = 'assets/book_covers/001.png',
        title = "Kitap 001",
        author = "Hakikat Kitabevi",
        description = "Bu örnek kitap, test amaçlıdır.";

  // Create a list of sample books
  static List<Book> samples() {
    return List.generate(14, (index) {
      final code = (index + 1).toString().padLeft(3, '0');
      return Book(code: code, description: "Açıklama eklenmedi.");
    });
  }
}
