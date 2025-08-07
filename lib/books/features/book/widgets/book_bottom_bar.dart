// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/books/features/book/screens/bookmarks_screen.dart';
import 'package:namaz_vakti_app/books/features/book/services/bookmark_service.dart';

class BookBottomBar extends StatelessWidget {
  final Color appBarColor;
  final int currentPage;
  final bool isFirstPage;
  final bool isLastPage;
  final Function() onPreviousPage;
  final Function() onNextPage;
  final Function() onMenuPressed;
  final Function() onPlayAudio;
  final bool hasAudio;
  final bool isAudioPlaying;
  final bool isPlaying;
  final String bookCode;
  final Function(int) onPageNumberEntered;
  final Function()? onBookmarksReturn;
  final bool hasBookmarks;

  const BookBottomBar({
    super.key,
    required this.appBarColor,
    required this.currentPage,
    required this.isFirstPage,
    required this.isLastPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onMenuPressed,
    required this.onPlayAudio,
    required this.hasAudio,
    required this.isAudioPlaying,
    this.isPlaying = false,
    required this.bookCode,
    required this.onPageNumberEntered,
    this.onBookmarksReturn,
    this.hasBookmarks = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Desen arka plan
            Image.asset(
              'assets/img/appbar3.png',
              fit: BoxFit.cover,
            ),
            // Renk overlay
            Container(
              decoration: BoxDecoration(
                color: appBarColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            // Orta kısım - Sayfa navigasyonu (tam ortada)
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left,
                        color: isFirstPage ? Colors.white.withOpacity(0.3) : Colors.white,
                        size: 30),
                    onPressed: isFirstPage ? null : onPreviousPage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    visualDensity: VisualDensity.compact,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        _showPageInputDialog(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '$currentPage',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right,
                        color: isLastPage ? Colors.white.withOpacity(0.3) : Colors.white, size: 30),
                    onPressed: isLastPage ? null : onNextPage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Sol butonlar (menu, bookmarks)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                      onPressed: onMenuPressed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (hasBookmarks)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.bookmarks_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () async {
                          BookmarkService().clearCache();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookmarksScreen(
                                initialBookCode: bookCode,
                              ),
                            ),
                          );
                          if (onBookmarksReturn != null) {
                            onBookmarksReturn!();
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            // Sağ buton (play/stop)
            if (hasAudio)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      isAudioPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: onPlayAudio,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPageInputDialog(BuildContext context) {
    String pageInput = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sayfa Numarası Gir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  pageInput = value;
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    int? page = int.tryParse(value);
                    if (page != null) {
                      Navigator.of(context).pop();
                      onPageNumberEntered(page);
                    }
                  }
                },
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Sayfa numarası',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (pageInput.isNotEmpty) {
                  int? page = int.tryParse(pageInput);
                  if (page != null) {
                    Navigator.of(context).pop();
                    onPageNumberEntered(page);
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Gir'),
            ),
          ],
        );
      },
    );
  }
}
