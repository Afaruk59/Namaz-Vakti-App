import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Normal Kuran görünümü için bileşen
class QuranRegularView extends StatefulWidget {
  final int pageNumber;
  final NetworkImage pageImage;
  final Color backgroundColor;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const QuranRegularView({
    Key? key,
    required this.pageNumber,
    required this.pageImage,
    required this.backgroundColor,
    required this.onTap,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  _QuranRegularViewState createState() => _QuranRegularViewState();
}

class _QuranRegularViewState extends State<QuranRegularView> {
  bool _isZoomed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PhotoView widget'ı
        Container(
          color: widget.backgroundColor,
          child: PhotoView(
            imageProvider: widget.pageImage,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: BoxDecoration(
              color: widget.backgroundColor,
            ),
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Text('Resim yüklenemedi: $error'));
            },
            loadingBuilder: (context, event) {
              return Center(child: CircularProgressIndicator());
            },
            // Zoom durumunu takip et
            scaleStateChangedCallback: (state) {
              setState(() {
                final wasZoomed = _isZoomed;
                _isZoomed = state != PhotoViewScaleState.initial;
                print(
                    'QuranRegularView: Zoom durumu değişti: $_isZoomed (önceki: $wasZoomed)');
              });
            },
            // Çift tıklama ile zoom için
            scaleStateCycle: (scaleState) {
              switch (scaleState) {
                case PhotoViewScaleState.initial:
                  return PhotoViewScaleState.covering;
                case PhotoViewScaleState.covering:
                  return PhotoViewScaleState.originalSize;
                case PhotoViewScaleState.originalSize:
                default:
                  return PhotoViewScaleState.initial;
              }
            },
          ),
        ),
        // Tam ekran geçişi için dokunma alanı
        // Zoom yapılmadığında aktif olacak
        if (!_isZoomed)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                print('QuranRegularView: Tam ekran için dokunma algılandı');
                widget.onTap();
              },
              onDoubleTap: widget.onDoubleTap,
              behavior: HitTestBehavior
                  .translucent, // Dokunma olayını her zaman yakala
            ),
          ),
      ],
    );
  }
}

/// Sayfa numarası giriş iletişim kutusu
class QuranPageInputDialog extends StatelessWidget {
  final Function(int) onPageSelected;

  const QuranPageInputDialog({
    Key? key,
    required this.onPageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String pageInput = '';

    return AlertDialog(
      title: Text('Sayfa Numarası Gir'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Geçerli sayfa aralığı: 1 - 609',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) => pageInput = value,
            onSubmitted: (value) => _handlePageInput(value, context),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Sayfa numarası',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        TextButton(
          onPressed: () => _handlePageInput(pageInput, context),
          child: Text('Git'),
        ),
      ],
    );
  }

  void _handlePageInput(String input, BuildContext context) {
    if (input.isNotEmpty) {
      int? page = int.tryParse(input);
      if (page != null) {
        page = page.clamp(1, 609);
        onPageSelected(page);
      }
    }
    Navigator.pop(context);
  }
}
