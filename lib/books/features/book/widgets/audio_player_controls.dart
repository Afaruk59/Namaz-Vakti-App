import 'package:flutter/material.dart';
import 'dart:async';
import 'package:namaz_vakti_app/books/features/book/audio/audio_player_service.dart';

class AudioPlayerControls extends StatefulWidget {
  final AudioPlayerService audioPlayerService;
  final Function(double) onSeek;
  final Function() onSpeedChange;
  final Function()? onPlayPauseProgress;
  final Color appBarColor; // yeni parametre

  const AudioPlayerControls({
    Key? key,
    required this.audioPlayerService,
    required this.onSeek,
    required this.onSpeedChange,
    this.onPlayPauseProgress,
    required this.appBarColor, // yeni parametre
  }) : super(key: key);

  @override
  State<AudioPlayerControls> createState() => _AudioPlayerControlsState();
}

class _AudioPlayerControlsState extends State<AudioPlayerControls>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  double _dragValue = 0.0;
  Timer? _debounceTimer;

  // For debugging
  int _rebuildCounter = 0;
  DateTime _lastPosition = DateTime.now();
  Duration _lastPositionValue = Duration.zero;
  Duration _lastDurationValue = Duration.zero;
  double _lastPlaybackRate = 1.0;
  bool _lastPlaybackState = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Debounce function to limit the frequency of UI updates
  void _debounceAction(VoidCallback action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 50), action);
  }

  @override
  Widget build(BuildContext context) {
    _rebuildCounter++;

    return StreamBuilder<bool>(
      stream: widget.audioPlayerService.playingStateStream,
      initialData: widget.audioPlayerService.isPlaying,
      builder: (context, playingSnapshot) {
        final isPlaying = playingSnapshot.data ?? false;

        // Log if playback state changed
        if (_lastPlaybackState != isPlaying) {
          print(
              'AudioPlayerControls: Playback state changed to $isPlaying (rebuild #$_rebuildCounter)');
          _lastPlaybackState = isPlaying;
        }

        return StreamBuilder<Duration>(
          stream: widget.audioPlayerService.positionStream,
          initialData: widget.audioPlayerService.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            // Log position updates (throttled)
            final now = DateTime.now();
            if (now.difference(_lastPosition).inSeconds >= 1 &&
                (position.inSeconds != _lastPositionValue.inSeconds)) {
              print(
                  'AudioPlayerControls: Position updated to ${position.inSeconds}s (rebuild #$_rebuildCounter)');
              _lastPosition = now;
              _lastPositionValue = position;
            }

            return StreamBuilder<Duration>(
              stream: widget.audioPlayerService.durationStream,
              initialData: widget.audioPlayerService.duration,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;

                // Log if duration changed
                if (_lastDurationValue != duration) {
                  print(
                      'AudioPlayerControls: Duration updated to ${duration.inSeconds}s (rebuild #$_rebuildCounter)');
                  _lastDurationValue = duration;
                }

                // Initialize drag value if not dragging
                if (!_isDragging) {
                  _dragValue = position.inMilliseconds
                      .toDouble()
                      .clamp(0.0, duration.inMilliseconds.toDouble());
                }

                return StreamBuilder<double>(
                  stream: widget.audioPlayerService.playbackRateStream,
                  initialData: widget.audioPlayerService.playbackSpeed,
                  builder: (context, playbackRateSnapshot) {
                    final playbackRate = playbackRateSnapshot.data ?? 1.0;

                    // Log if playback rate changed
                    if (_lastPlaybackRate != playbackRate) {
                      print(
                          'AudioPlayerControls: Playback rate changed to ${playbackRate}x (rebuild #$_rebuildCounter)');
                      _lastPlaybackRate = playbackRate;
                    }

                    return Container(
                      height: 45,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/appbar3.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Stack(
                        children: [
                          // Overlay for darkening (same as AppBar/BottomBar)
                          Container(
                            color: widget.appBarColor.withOpacity(0.7),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                // Play/Pause button - optimize by using RepaintBoundary
                                RepaintBoundary(
                                  child: IconButton(
                                    iconSize: 24,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      print(
                                          'AudioPlayerControls: Play/Pause button pressed, current state: $isPlaying');
                                      if (widget.onPlayPauseProgress != null) {
                                        widget.onPlayPauseProgress!();
                                      }
                                    },
                                  ),
                                ),

                                // Add spacing
                                SizedBox(width: 4),

                                // Current position
                                RepaintBoundary(
                                  child: Text(
                                    _formatDuration(_isDragging
                                        ? Duration(milliseconds: _dragValue.toInt())
                                        : position),
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),

                                // Slider for seeking
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.0,
                                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: _isDragging
                                          ? _dragValue
                                          : position.inMilliseconds
                                              .toDouble()
                                              .clamp(0.0, duration.inMilliseconds.toDouble()),
                                      min: 0,
                                      max: duration.inMilliseconds.toDouble() > 0
                                          ? duration.inMilliseconds.toDouble()
                                          : 1,
                                      onChanged: (value) {
                                        _debounceAction(() {
                                          setState(() {
                                            _isDragging = true;
                                            _dragValue = value.clamp(
                                                0.0, duration.inMilliseconds.toDouble());
                                          });
                                        });
                                      },
                                      onChangeStart: (value) {
                                        setState(() {
                                          _isDragging = true;
                                          _dragValue =
                                              value.clamp(0.0, duration.inMilliseconds.toDouble());
                                        });
                                        print(
                                            'AudioPlayerControls: Seeking started at ${value / 1000}s');
                                      },
                                      onChangeEnd: (value) {
                                        // Clamp the value to ensure it's within valid range
                                        final clampedValue =
                                            value.clamp(0.0, duration.inMilliseconds.toDouble());
                                        print(
                                            'AudioPlayerControls: Seeking to position ${clampedValue / 1000}s');
                                        widget.onSeek(clampedValue);
                                        setState(() {
                                          _isDragging = false;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                // Remaining time
                                RepaintBoundary(
                                  child: Text(
                                    "- ${_formatDuration(_isDragging ? Duration(milliseconds: (duration.inMilliseconds - _dragValue.toInt())) : duration - position)}",
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),

                                // Playback speed button (compact)
                                RepaintBoundary(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(32, 32),
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      print('AudioPlayerControls: Speed change button pressed');
                                      widget.onSpeedChange();
                                    },
                                    child: Text(
                                      "${playbackRate}x",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
