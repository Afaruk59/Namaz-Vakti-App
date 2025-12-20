import 'package:flutter/material.dart';
import 'arabic_letter_icon.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

/// Kuran sayfası ekranı için AppBar bileşeni
class QuranAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedFormat;
  final List<String> availableFormats;
  final Function(String) onFormatChanged;
  final VoidCallback onBackPressed;
  final VoidCallback? onSettingsPressed;
  final List<Widget> actions;

  const QuranAppBar({
    Key? key,
    required this.selectedFormat,
    required this.availableFormats,
    required this.onFormatChanged,
    required this.onBackPressed,
    this.onSettingsPressed,
    this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/img/appbar3.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.green.shade700.withOpacity(0.7),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed,
      ),
      centerTitle: true,
      title: DropdownButton<String>(
        value: selectedFormat,
        dropdownColor: Colors.green.shade700,
        underline: Container(),
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        style: TextStyle(color: Colors.white, fontSize: 16),
        items: availableFormats.map((format) {
          String localizedName = format;
          final l10n = AppLocalizations.of(context);
          switch (format) {
            case 'Mukabele':
              localizedName = l10n?.quranFormatMukabele ?? 'Mukabele';
              break;
            case 'Hat 1':
              localizedName = l10n?.quranFormatHat1 ?? 'Hat 1';
              break;
            case 'Hat 2':
              localizedName = l10n?.quranFormatHat2 ?? 'Hat 2';
              break;
          }
          return DropdownMenuItem<String>(
            value: format,
            child: Text(localizedName),
          );
        }).toList(),
        onChanged: (String? newFormat) {
          if (newFormat != null) {
            onFormatChanged(newFormat);
          }
        },
      ),
      actions: [
        if (onSettingsPressed != null)
          IconButton(
            icon: ArabicLetterIcon(
              letter: 'ع',
              size: 24.0,
              color: Colors.white,
              backgroundColor: Colors.green.shade600,
              onPressed: onSettingsPressed,
            ),
            onPressed: onSettingsPressed,
          ),
        ...actions,
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
