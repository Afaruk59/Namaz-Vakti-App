import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';

/// Kuran ayarları için sağ taraftan açılan drawer
class QuranSettingsDrawer extends StatefulWidget {
  final double fontSize;
  final Function(double) onFontSizeChanged;
  final bool isAutoBackground;
  final Function(bool) onAutoBackgroundChanged;
  final Color backgroundColor;
  final Function(Color) onBackgroundColorChanged;
  final String selectedFont;
  final List<Map<String, String>> availableFonts;
  final Function(String) onFontChanged;
  final bool isAutoScroll; // Otomatik kaydırma ayarı için değişken
  final Function(bool) onAutoScrollChanged; // Otomatik kaydırma ayarını değiştirmek için callback
  final Function() onResetSettings; // Ayarları sıfırlamak için callback
  // Translation parameters removed

  const QuranSettingsDrawer({
    Key? key,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.isAutoBackground,
    required this.onAutoBackgroundChanged,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
    required this.selectedFont,
    required this.availableFonts,
    required this.onFontChanged,
    required this.isAutoScroll, // Yeni parametre
    required this.onAutoScrollChanged, // Yeni parametre
    required this.onResetSettings,
    // Translation parameters removed
  }) : super(key: key);

  @override
  _QuranSettingsDrawerState createState() => _QuranSettingsDrawerState();
}

class _QuranSettingsDrawerState extends State<QuranSettingsDrawer> with TickerProviderStateMixin {
  late double _fontSize;
  late bool _isAutoBackground;
  late Color _backgroundColor;
  late String _selectedFont;
  late bool _isAutoScroll; // Otomatik kaydırma ayarı için değişken
  bool _isScrolling = false; // Font kaydırma durumu için
  // Translation state removed

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _isAutoBackground = widget.isAutoBackground;
    _backgroundColor = widget.backgroundColor;
    _selectedFont = widget.selectedFont;
    _isAutoScroll = widget.isAutoScroll; // Değişkeni başlat
    // Translation initialization removed

    // Değerlerin varsayılan değerlerini ayarla
    if (_selectedFont.isEmpty) {
      _selectedFont = widget.availableFonts.isNotEmpty
          ? widget.availableFonts.first['name'] ?? 'ShaikhHamdullah'
          : 'ShaikhHamdullah';
    }
    
  }

  @override
  void didUpdateWidget(QuranSettingsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Widget özellikleri değiştiğinde state'i güncelle
    if (oldWidget.fontSize != widget.fontSize) {
      _fontSize = widget.fontSize;
    }
    if (oldWidget.isAutoBackground != widget.isAutoBackground) {
      _isAutoBackground = widget.isAutoBackground;
    }
    if (oldWidget.backgroundColor != widget.backgroundColor) {
      _backgroundColor = widget.backgroundColor;
    }
    if (oldWidget.selectedFont != widget.selectedFont) {
      _selectedFont = widget.selectedFont;
    }
    if (oldWidget.isAutoScroll != widget.isAutoScroll) {
      _isAutoScroll = widget.isAutoScroll;
    }
    if (oldWidget.selectedFont != widget.selectedFont) {
      _selectedFont = widget.selectedFont;
    }
    // Translation update removed
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Her build işleminde güncel değerleri kullan
    _fontSize = widget.fontSize;
    _isAutoBackground = widget.isAutoBackground;
    _backgroundColor = widget.backgroundColor;
    _selectedFont = widget.selectedFont;
    _isAutoScroll = widget.isAutoScroll;

    // Değerlerin varsayılan değerlerini ayarla
    if (_selectedFont.isEmpty) {
      _selectedFont = widget.availableFonts.isNotEmpty
          ? widget.availableFonts.first['name'] ?? 'ShaikhHamdullah'
          : 'ShaikhHamdullah';
    }

    // Arabic locale için RTL text direction belirle
    final isArabic = Provider.of<ChangeSettings>(context).locale?.languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: _isScrolling 
      ? Container(
          width: MediaQuery.of(context).size.width * 0.75,
          color: Colors.transparent, // Tamamen şeffaf
          child: Align(
            alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 100), // Header'dan sonraki mesafe
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Font seçim alanı
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(
                            Provider.of<ChangeSettings>(context).rounded == true ? 25 : 12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _buildFontSectionOnly(),
                    ),
                    const SizedBox(height: 16),
                    // Font size slider - ayrı container
                    Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(
                            Provider.of<ChangeSettings>(context).rounded == true ? 25 : 12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _buildFontSizeSliderOnly(),
                    ),
                    const SizedBox(height: 16),
                    // Tamam butonu - ayrı container
                    Container(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          // Drawer'a geri dön
                          setState(() {
                            _isScrolling = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                Provider.of<ChangeSettings>(context).rounded == true ? 25 : 8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.quranOk ?? 'Tamam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ),
        )
      : Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildFontButtonSection(),
                      Divider(),
                      _buildBackgroundSection(),
                      Divider(),
                      _buildAutoScrollSection(),
                      Divider(),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 16),
      color: Colors.green.shade700,
      child: Center(
        child: Text(
          AppLocalizations.of(context)?.quranPageSettings ?? 'Sayfa Ayarları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFontSectionOnly() {
    // availableFonts listesinin null veya boş olma durumunu kontrol et
    final availableFonts = widget.availableFonts.isNotEmpty
        ? widget.availableFonts
        : [
            {'name': 'ShaikhHamdullah', 'displayName': 'Şeyh Hamdullah'}
          ];

    return SizedBox(
      height: 80, // Font seçim alanının yüksekliğini artırdık
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollStartNotification) {
              // Kaydırma başladığında drawer'ı tamamen gizle
              setState(() {
                _isScrolling = true;
              });
            }
            return false;
          },
          child: PageView.builder(
          controller: PageController(
            initialPage: _getFontIndex(_selectedFont),
            viewportFraction: 0.4,
          ),
          scrollDirection: Axis.vertical,
          onPageChanged: (index) {
            final selectedFont = availableFonts[index]['name'] ?? 'ShaikhHamdullah';
            setState(() {
              _selectedFont = selectedFont;
            });
            widget.onFontChanged(selectedFont);
          },
          physics: const ClampingScrollPhysics(),
          itemCount: availableFonts.length,
          itemBuilder: (context, index) {
            final font = availableFonts[index];
            final name = font['name'] ?? 'ShaikhHamdullah';
            final displayName = font['displayName'] ?? 'Şeyh Hamdullah';
            final isSelected = name == _selectedFont;
            final currentIndex = _getFontIndex(_selectedFont);
            final distance = (index - currentIndex).abs();
            final opacity = distance == 0 ? 1.0 : distance == 1 ? 0.6 : 0.3;
            final scale = distance == 0 ? 1.0 : distance == 1 ? 0.9 : 0.8;
            
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (Theme.of(context).brightness == Brightness.dark 
                            ? Colors.blue.shade400 
                            : Theme.of(context).primaryColor)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                        Provider.of<ChangeSettings>(context).rounded == true ? 25 : 8),
                  ),
                  child: Center(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: isSelected ? 18 : 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? Colors.white
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black, // Tema duyarlı renk
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          },
          ),
        ),
    );
  }

  Widget _buildFontSizeSliderOnly() {
    // Null kontrolü ve sınırlar içinde olduğundan emin ol
    double currentFontSize = _fontSize.clamp(24.0, 80.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCEC7C7) : const Color(0xFF3F3E3E))),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.green.shade700,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Colors.green.shade700,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
                  trackHeight: 4.0,
                ),
                child: Slider(
                  min: 24.0,
                  max: 80.0,
                  divisions: 14,
                  value: currentFontSize,
                  onChanged: (newValue) {
                    setState(() {
                      _fontSize = newValue;
                    });
                    widget.onFontSizeChanged(newValue);
                  },
                ),
              ),
            ),
            Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCEC7C7) : const Color(0xFF3F3E3E))),
          ],
        ),
      ],
    );
  }

  Widget _buildFontButtonSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.quranFontType ?? 'Yazı Tipi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Font seçim davranışını tetikle
              setState(() {
                _isScrolling = true;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getCurrentFontDisplayName(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${AppLocalizations.of(context)?.quranFontSize ?? 'Size'}: ${_fontSize.toInt()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.settings,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBackgroundSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildColorPalette(),
    );
  }

  Widget _buildColorPalette() {
    // Sadece 6 renk bırakıyoruz, oto ve siyah yok
    final List<List<dynamic>> colorRows = [
      [
        {'type': 'color', 'value': Colors.white},
        {'type': 'color', 'value': Color(0xFFF5E6D3)},
        {'type': 'color', 'value': Color(0xFFE5F9E0)}
      ],
      [
        {'type': 'color', 'value': Color(0xFFE0F1F9)},
        {'type': 'color', 'value': Color(0xFF2C3E50)},
        {'type': 'color', 'value': Color(0xFF2E1810)}
      ],
    ];

    return Column(
      children: colorRows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((item) {
              if (item == null) {
                return SizedBox(width: 48, height: 48);
              }
              if (item['type'] == 'color' && item['value'] != null) {
                return _buildColorButton(item['value']);
              } else {
                return SizedBox(width: 48, height: 48);
              }
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorButton(Color color) {
    final bool isSelected = !_isAutoBackground && _backgroundColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAutoBackground = false;
          _backgroundColor = color;
        });
        widget.onAutoBackgroundChanged(false);
        widget.onBackgroundColorChanged(color);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  size: 24,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildAutoScrollSection() {
    return SwitchListTile(
      title: Text(AppLocalizations.of(context)?.quranAutoScroll ?? 'Otomatik Kaydırma'),
      value: _isAutoScroll,
      onChanged: (value) {
        setState(() {
          _isAutoScroll = value;
        });
        widget.onAutoScrollChanged(value);
      },
    );
  }

  // Translation section removed

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sıfırlama butonu
          TextButton.icon(
            icon: Icon(Icons.refresh, color: Colors.red.shade700),
            label: Text(
              AppLocalizations.of(context)?.quranReset ?? 'Sıfırla',
              style: TextStyle(color: Colors.red.shade700),
            ),
            onPressed: _resetSettings,
          ),
          // Kapat butonu
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)?.quranClose ?? 'Kapat'),
          ),
        ],
      ),
    );
  }

  // Ayarları sıfırlama metodu
  void _resetSettings() {
    // Doğrudan sıfırlama işlemini yap
    widget.onResetSettings();
  }

  // Font index'ini bulma metodu
  int _getFontIndex(String fontName) {
    final availableFonts = widget.availableFonts.isNotEmpty
        ? widget.availableFonts
        : [
            {'name': 'ShaikhHamdullah', 'displayName': 'Şeyh Hamdullah'}
          ];
    
    for (int i = 0; i < availableFonts.length; i++) {
      if (availableFonts[i]['name'] == fontName) {
        return i;
      }
    }
    return 0; // Varsayılan olarak ilk font'u döndür
  }

  // Mevcut font'un görünen adını döndüren metod
  String _getCurrentFontDisplayName() {
    final availableFonts = widget.availableFonts.isNotEmpty
        ? widget.availableFonts
        : [
            {'name': 'ShaikhHamdullah', 'displayName': 'Şeyh Hamdullah'}
          ];
    
    for (final font in availableFonts) {
      if (font['name'] == _selectedFont) {
        return font['displayName'] ?? 'Şeyh Hamdullah';
      }
    }
    return 'Şeyh Hamdullah';
  }
}
