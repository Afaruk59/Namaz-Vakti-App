import 'package:flutter/material.dart';

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
  final Function(bool)
      onAutoScrollChanged; // Otomatik kaydırma ayarını değiştirmek için callback
  final Function() onResetSettings; // Ayarları sıfırlamak için callback
  final bool showMeal;
  final Function(bool) onShowMealChanged;

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
    required this.showMeal,
    required this.onShowMealChanged,
  }) : super(key: key);

  @override
  _QuranSettingsDrawerState createState() => _QuranSettingsDrawerState();
}

class _QuranSettingsDrawerState extends State<QuranSettingsDrawer> {
  late double _fontSize;
  late bool _isAutoBackground;
  late Color _backgroundColor;
  late String _selectedFont;
  late bool _isAutoScroll; // Otomatik kaydırma ayarı için değişken
  late bool _showMeal;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _isAutoBackground = widget.isAutoBackground;
    _backgroundColor = widget.backgroundColor;
    _selectedFont = widget.selectedFont;
    _isAutoScroll = widget.isAutoScroll; // Değişkeni başlat
    _showMeal = widget.showMeal; // Default olarak kapalı

    // Değerlerin varsayılan değerlerini ayarla
    if (_selectedFont.isEmpty) {
      _selectedFont = widget.availableFonts.isNotEmpty
          ? widget.availableFonts.first['name'] ?? 'Shaikh Hamdullah'
          : 'Shaikh Hamdullah';
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
    if (oldWidget.showMeal != widget.showMeal) {
      _showMeal = widget.showMeal;
    }
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
          ? widget.availableFonts.first['name'] ?? 'Shaikh Hamdullah'
          : 'Shaikh Hamdullah';
    }

    return Drawer(
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
                  _buildFontSection(),
                  Divider(),
                  _buildFontSizeSection(),
                  Divider(),
                  _buildBackgroundSection(),
                  Divider(),
                  _buildAutoScrollSection(),
                  _buildMealSection(),
                  Divider(),
                ],
              ),
            ),
            _buildFooter(),
          ],
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
          'Sayfa Ayarları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFontSection() {
    // availableFonts listesinin null veya boş olma durumunu kontrol et
    final availableFonts = widget.availableFonts.isNotEmpty
        ? widget.availableFonts
        : [
            {'name': 'Shaikh Hamdullah', 'displayName': 'Şeyh Hamdullah'}
          ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedFont,
            icon: Icon(Icons.arrow_drop_down, color: Colors.green.shade700),
            items: availableFonts.map((font) {
              final name = font['name'] ?? 'Shaikh Hamdullah';
              final displayName = font['displayName'] ?? 'Şeyh Hamdullah';

              return DropdownMenuItem<String>(
                value: name,
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: _selectedFont == name
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedFont == name
                        ? Colors.green.shade700
                        : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (String? newFont) {
              if (newFont != null) {
                setState(() {
                  _selectedFont = newFont;
                });
                widget.onFontChanged(newFont);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeSection() {
    // Null kontrolü ve sınırlar içinde olduğundan emin ol
    double currentFontSize = _fontSize.clamp(24.0, 40.0);

    // Debug için
    print(
        'Current font size: $_fontSize, Widget font size: ${widget.fontSize}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('A',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    max: 40.0,
                    divisions: 8,
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
              Text('A',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
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
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  size: 24,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildAutoScrollSection() {
    return SwitchListTile(
      title: Text('Otomatik Kaydırma'),
      value: _isAutoScroll,
      onChanged: (value) {
        setState(() {
          _isAutoScroll = value;
        });
        widget.onAutoScrollChanged(value);
      },
    );
  }

  Widget _buildMealSection() {
    return SwitchListTile(
      title: Text('Terceme'),
      value: _showMeal,
      onChanged: (value) {
        setState(() {
          _showMeal = value;
        });
        widget.onShowMealChanged(value);
      },
    );
  }

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
              'Sıfırla',
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
            child: Text('Kapat'),
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
}
