import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/l10n/app_localization.dart';

/// Takipli görünüm için yükleme widget'ı
class QuranTakipliLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
          ),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)?.quranPageLoading ?? 'Sayfa yükleniyor...'),
        ],
      ),
    );
  }
}

/// Takipli görünüm için hata widget'ı
class QuranTakipliError extends StatelessWidget {
  final String error;

  const QuranTakipliError({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text('${AppLocalizations.of(context)?.quranError ?? 'Hata'}: $error'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Sayfayı yeniden yükleme işlemi
              // Bu kısım, sayfayı yeniden yüklemek için bir callback alabilir
            },
            child: Text(AppLocalizations.of(context)?.quranRetry ?? 'Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
