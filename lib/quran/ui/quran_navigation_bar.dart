import 'package:flutter/material.dart';

/// Kuran sayfası ekranı için alt navigasyon çubuğu
class QuranNavigationBar extends StatelessWidget {
  final int currentPage;
  final void Function() onMenuPressed;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onPageNumberTap;
  final VoidCallback onPlayAudio;
  final bool isPlaying;
  final List<Widget> leadingWidgets;

  const QuranNavigationBar({
    Key? key,
    required this.currentPage,
    required this.onMenuPressed,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageNumberTap,
    required this.onPlayAudio,
    required this.isPlaying,
    this.leadingWidgets = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
        height: 54, // Yüksekliği artırdık
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
              color: Colors.green.shade700.withOpacity(0.7),
            ),
            // İçerik
            Row(
              children: [
                // Menü butonu
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: 26),
                    onPressed: onMenuPressed,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...leadingWidgets,
                // Sayfa numarası ve navigasyon
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Önceki sayfa butonu
                      IconButton(
                        icon: Icon(Icons.chevron_left,
                            color: currentPage < 604
                                ? Colors.white
                                : Colors.white
                                    .withOpacity(0.3), // Sayfa 604'te pasif
                            size: 30),
                        onPressed: currentPage < 604 ? onPreviousPage : null,
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 40, minHeight: 40),
                        visualDensity: VisualDensity.compact,
                      ),
                      // Sayfa numarası - daha fazla boşluk ekle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: GestureDetector(
                          onTap: onPageNumberTap,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Text(
                              '$currentPage',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Sonraki sayfa butonu
                      IconButton(
                        icon: Icon(Icons.chevron_right,
                            color: currentPage > 0
                                ? Colors.white
                                : Colors.white
                                    .withOpacity(0.3), // Sayfa 0'da pasif
                            size: 30),
                        onPressed: currentPage > 0 ? onNextPage : null,
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 40, minHeight: 40),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                // Play/Stop butonu
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: onPlayAudio,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
