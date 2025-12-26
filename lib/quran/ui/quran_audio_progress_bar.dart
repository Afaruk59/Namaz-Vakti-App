import 'package:flutter/material.dart';

/// Kuran ses çalma ilerleme çubuğu widget'ı
class QuranAudioProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final double playbackRate;
  final Function(Duration) onSeek;
  final VoidCallback onPlayPause;
  final Function(double) onPlaybackRateChanged;
  final VoidCallback onPreviousAyah;
  final VoidCallback onNextAyah;
  final String currentSurahAndAyah;
  final bool isFirstAyah;
  final bool isLastAyah;
  final Color appBarColor; // yeni parametre

  const QuranAudioProgressBar({
    Key? key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.playbackRate,
    required this.onSeek,
    required this.onPlayPause,
    required this.onPlaybackRateChanged,
    required this.onPreviousAyah,
    required this.onNextAyah,
    required this.currentSurahAndAyah,
    required this.isFirstAyah,
    required this.isLastAyah,
    this.appBarColor = const Color(0xFF388E3C), // default green
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // isPlaying değeri hem normal çalma hem de besmele çalma durumunu içeriyor
    // Burada isPlaying değerini doğrudan kullanıyoruz, çünkü QuranAudioService'de
    // pause() metodunda _isBesmelePlaying'i false yapıyoruz
    final bool isAudioActive = isPlaying;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/appbar3.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Stack(
        children: [
          // Overlay for darkening (same as AppBar/BottomBar)
          Container(
            color: appBarColor.withOpacity(0.7),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                // Önceki ayet butonu
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: isFirstAyah
                        ? Colors.white
                            .withOpacity(0.3) // İlk ayetteyse pasif renk
                        : Colors.white,
                    size: 20,
                  ),
                  onPressed:
                      isFirstAyah ? null : onPreviousAyah, // İlk ayetteyse null
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  visualDensity: VisualDensity.compact,
                ),
                // Oynat/Duraklat butonu
                IconButton(
                  icon: Icon(
                    isAudioActive ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: onPlayPause,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  visualDensity: VisualDensity.compact,
                ),
                // Sonraki ayet butonu
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: isLastAyah
                        ? Colors.white
                            .withOpacity(0.3) // Son ayetteyse pasif renk
                        : Colors.white,
                    size: 20,
                  ),
                  onPressed:
                      isLastAyah ? null : onNextAyah, // Son ayetteyse null
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  visualDensity: VisualDensity.compact,
                ),
                // Mevcut sure ve ayet bilgisi - Slider yerine sadece metin gösteriyoruz
                Expanded(
                  child: Center(
                    child: Text(
                      currentSurahAndAyah,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Oynatma hızı butonu - Menü yerine tıklandıkça artan hız
                InkWell(
                  onTap: () {
                    // Hız değerlerini sırayla değiştir
                    double nextRate;
                    if (playbackRate >= 2.0) {
                      nextRate = 0.5; // Sona gelince başa dön
                    } else if (playbackRate >= 1.5) {
                      nextRate = 2.0;
                    } else if (playbackRate >= 1.25) {
                      nextRate = 1.5;
                    } else if (playbackRate >= 1.0) {
                      nextRate = 1.25;
                    } else if (playbackRate >= 0.75) {
                      nextRate = 1.0;
                    } else if (playbackRate >= 0.5) {
                      nextRate = 0.75;
                    } else {
                      nextRate = 0.5;
                    }
                    onPlaybackRateChanged(nextRate);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${playbackRate.toStringAsFixed(1)}x',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
