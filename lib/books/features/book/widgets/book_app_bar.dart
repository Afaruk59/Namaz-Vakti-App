// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';

class BookAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Color appBarColor;
  final double fontSize;
  final Function(double) onFontSizeChanged;
  final Color backgroundColor;
  final Function(Color) onBackgroundColorChanged;
  final bool isAutoBackground;
  final Function(bool) onAutoBackgroundChanged;
  final String bookCode;
  final int currentPage;
  final Function(bool) onBookmarkToggled;

  const BookAppBar({
    super.key,
    required this.title,
    required this.appBarColor,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
    required this.isAutoBackground,
    required this.onAutoBackgroundChanged,
    required this.bookCode,
    required this.currentPage,
    required this.onBookmarkToggled,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _BookAppBarState createState() => _BookAppBarState();
}

class _BookAppBarState extends State<BookAppBar> {
  // Yerel değişkenler
  late double _currentFontSize;
  late bool _isAutoBackground;
  late Color _backgroundColor;

  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.fontSize;
    _isAutoBackground = widget.isAutoBackground;
    _backgroundColor = widget.backgroundColor;
  }

  @override
  void didUpdateWidget(BookAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget güncellendiğinde değerleri güncelle
    if (oldWidget.fontSize != widget.fontSize) {
      _currentFontSize = widget.fontSize;
    }
    if (oldWidget.isAutoBackground != widget.isAutoBackground) {
      _isAutoBackground = widget.isAutoBackground;
    }
    if (oldWidget.backgroundColor != widget.backgroundColor) {
      _backgroundColor = widget.backgroundColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/appbar3.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: widget.appBarColor.withOpacity(0.7),
          ),
        ],
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      actions: [
        PopupMenuButton<Map<String, dynamic>>(
          icon: const Icon(Icons.format_size, color: Colors.white),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<Map<String, dynamic>>(
              value: const {'type': 'settings'},
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFontSizeSection(context),
                    const Divider(),
                    _buildBackgroundSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontSizeSection(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Yazı Boyutu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                    trackHeight: 4.0,
                  ),
                  child: Slider(
                    min: 14.0,
                    max: 20.0,
                    divisions: 6,
                    value: _currentFontSize,
                    onChanged: (newValue) {
                      // StatefulBuilder'ın setState'ini kullan
                      setState(() {
                        _currentFontSize = newValue;
                      });
                      // Ana widget'a değişikliği bildir
                      widget.onFontSizeChanged(newValue);
                    },
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('T', style: TextStyle(fontSize: 14.0)),
                    Text('T', style: TextStyle(fontSize: 20.0)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundSection(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Arka Plan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [Colors.white, const Color(0xFFF5E6D3), const Color(0xFFE5F9E0)]
                              .map(
                                (color) => GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _isAutoBackground = false;
                                      _backgroundColor = color;
                                    });
                                    await widget.onBackgroundColorChanged(color);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: !_isAutoBackground && _backgroundColor == color
                                            ? Colors.blue
                                            : Colors.grey,
                                        width:
                                            !_isAutoBackground && _backgroundColor == color ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        Row(
                          children: [
                            const Color(0xFFE0F1F9),
                            const Color(0xFF2C3E50),
                            const Color(0xFF2E1810)
                          ]
                              .map(
                                (color) => GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _isAutoBackground = false;
                                      _backgroundColor = color;
                                    });
                                    await widget.onBackgroundColorChanged(color);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: !_isAutoBackground && _backgroundColor == color
                                            ? Colors.blue
                                            : Colors.grey,
                                        width:
                                            !_isAutoBackground && _backgroundColor == color ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
