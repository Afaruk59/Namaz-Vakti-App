import 'package:shared_preferences/shared_preferences.dart';

class QuranProgressService {
  static const String _currentPageKey = 'quran_current_page';
  static const String _formatKey = 'quran_format';
  static const String _progressKey = 'quran_progress';

  // Cache the progress value
  double? _cachedProgress;

  // Constructor to initialize the cache
  QuranProgressService() {
    // Load the progress value into cache
    _loadProgressCache();
  }

  // Load progress into cache
  Future<void> _loadProgressCache() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedProgress = prefs.getDouble(_progressKey) ?? 0.0;
  }

  // Add this public method to refresh the cache
  Future<void> refreshProgressCache() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedProgress = prefs.getDouble(_progressKey) ?? 0.0;
  }

  /// İlerleme yüzdesini ayarlar
  Future<void> setProgress(double progress) async {
    if (progress < 0 || progress > 1) {
      throw ArgumentError('Progress must be between 0 and 1');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_progressKey, progress);
    // Update the cache
    _cachedProgress = progress;
  }

  /// Mevcut sayfa numarasını ayarlar
  Future<void> setCurrentPage(int pageNumber) async {
    if (pageNumber < 0 || pageNumber > 604) {
      throw ArgumentError('Page number must be between 0 and 604');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentPageKey, pageNumber);
  }

  Future<int> getCurrentPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentPageKey) ?? 0;
  }

  Future<void> setFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formatKey, format);
  }

  Future<String> getFormat() async {
    final prefs = await SharedPreferences.getInstance();
    String format = prefs.getString(_formatKey) ?? 'Mukabele';
    // Eski 'Takipli' formatını 'Mukabele' olarak güncelle
    if (format == 'Takipli') {
      format = 'Mukabele';
      // Kalıcı olarak güncelle
      await setFormat(format);
    }
    // Eski 'Hat 4' formatını 'Hat 2' olarak güncelle
    if (format == 'Hat 4') {
      format = 'Hat 2';
      // Kalıcı olarak güncelle
      await setFormat(format);
    }
    return format;
  }

  Future<double> getProgressAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_progressKey) ?? 0.0;
  }

  // Synchronous method to get progress from cache
  double? getProgress() {
    return _cachedProgress;
  }

  // Removed duplicate getProgressAsync() method
}
