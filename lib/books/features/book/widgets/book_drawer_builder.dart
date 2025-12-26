import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/models/book_page_model.dart';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';
import 'package:namaz_vakti_app/books/shared/models/index_item_model.dart';
import 'package:namaz_vakti_app/books/shared/widgets/index_drawer.dart';

/// Drawer oluşturucu yardımcı sınıf
class BookDrawerBuilder {
  /// Drawer widget'ını oluşturur
  static Widget? buildDrawer({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required bool isFullScreen,
    required bool showAudioProgress,
    required Future<List<IndexItem>> indexFuture,
    required String bookTitleText,
    required String bookCode,
    required Color appBarColor,
    required Function(int) onPageSelected,
    required Future<List<Map<String, dynamic>>> Function(String, String)? searchFunction,
    String? searchText,
    required AudioPlayerService audioPlayerService,
    required BookPageModel? currentBookPage,
  }) {
    if (isFullScreen) return null;

    return SizedBox(
      width: 280,
      height: MediaQuery.of(context).size.height -
          AppBar().preferredSize.height -
          MediaQuery.of(context).padding.top -
          60,
      child: Drawer(
        child: IndexDrawer(
          indexFuture: indexFuture,
          bookTitle: bookTitleText,
          onPageSelected: (page) {
            // Önce sayfayı yükle, sonra drawer'ı kapat
            try {
              onPageSelected(page);

              // Drawer'ı güvenli bir şekilde kapat
              if (scaffoldKey.currentState != null && scaffoldKey.currentState!.isDrawerOpen) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              debugPrint('Drawer kapatma veya sayfa güncelleme hatası: $e');
              // Hata durumunda drawer'ı kapatmayı tekrar dene
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
          bookCode: bookCode,
          appBarColor: appBarColor,
          searchFunction: searchFunction,
          initialSearchText: searchText,
        ),
      ),
    );
  }
}
