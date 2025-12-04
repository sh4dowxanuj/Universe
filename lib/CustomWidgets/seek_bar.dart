/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, SH4DOWXANUJ
 */

import 'dart:math';

import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SeekBar extends StatefulWidget {
  final AudioPlayerHandler audioHandler;
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final bool offline;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    required this.duration,
    required this.position,
    required this.offline,
    required this.audioHandler,
    this.bufferedPosition = Duration.zero,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final value = min(
      _dragValue ?? widget.position.inMilliseconds.toDouble(),
      widget.duration.inMilliseconds.toDouble(),
    );
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                StreamBuilder<double>(
                  stream: widget.audioHandler.speed,
                  builder: (context, snapshot) {
                    final String speedValue =
                        '${snapshot.data?.toStringAsFixed(1) ?? 1.0}x';
                    final bool isDefault = speedValue == '1.0x';
                    return GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDefault
                              ? Colors.transparent
                              : accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: isDefault
                              ? Border.all(
                                  color: Theme.of(context).iconTheme.color!.withOpacity(0.3),
                                )
                              : null,
                        ),
                        child: Text(
                          speedValue,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDefault
                                ? Theme.of(context).iconTheme.color!.withOpacity(0.6)
                                : accentColor,
                          ),
                        ),
                      ),
                      onTap: () {
                        showSliderDialog(
                          context: context,
                          title: AppLocalizations.of(context)!.adjustSpeed,
                          divisions: 25,
                          min: 0.5,
                          max: 3.0,
                          audioHandler: widget.audioHandler,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Modern seek bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 5.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7.0,
                      elevation: 2,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16.0,
                    ),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: Theme.of(context).iconTheme.color!.withOpacity(0.15),
                    thumbColor: Colors.white,
                    overlayColor: accentColor.withOpacity(0.2),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    max: widget.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                    value: value.clamp(0.0, widget.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity)),
                    onChanged: (value) {
                      if (!_dragging) {
                        _dragging = true;
                      }
                      setState(() {
                        _dragValue = value;
                      });
                      widget.onChanged
                          ?.call(Duration(milliseconds: value.round()));
                    },
                    onChangeEnd: (value) {
                      widget.onChangeEnd
                          ?.call(Duration(milliseconds: value.round()));
                      _dragging = false;
                    },
                  ),
                ),
                // Time display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).iconTheme.color!.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).iconTheme.color!.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Duration get _duration => widget.duration;
  Duration get _position => widget.position;
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  required AudioPlayerHandler audioHandler,
  String valueSuffix = '',
}) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color accentColor = Theme.of(context).colorScheme.secondary;
  
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      title: Text(
        title, 
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
      ),
      content: StreamBuilder<double>(
        stream: audioHandler.speed,
        builder: (context, snapshot) {
          double value = snapshot.data ?? audioHandler.speed.value;
          if (value > max) {
            value = max;
          }
          if (value < min) {
            value = min;
          }
          return SizedBox(
            height: 120.0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSpeedButton(
                      context: context,
                      icon: CupertinoIcons.minus,
                      onPressed: audioHandler.speed.value > min
                          ? () {
                              audioHandler
                                  .setSpeed(audioHandler.speed.value - 0.1);
                            }
                          : null,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28.0,
                          color: accentColor,
                        ),
                      ),
                    ),
                    _buildSpeedButton(
                      context: context,
                      icon: CupertinoIcons.plus,
                      onPressed: audioHandler.speed.value < max
                          ? () {
                              audioHandler
                                  .setSpeed(audioHandler.speed.value + 0.1);
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4.0,
                    activeTrackColor: accentColor,
                    inactiveTrackColor: accentColor.withOpacity(0.2),
                    thumbColor: accentColor,
                    overlayColor: accentColor.withOpacity(0.15),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                    ),
                  ),
                  child: Slider(
                    divisions: divisions,
                    min: min,
                    max: max,
                    value: value,
                    onChanged: audioHandler.setSpeed,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildSpeedButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback? onPressed,
}) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      color: isDark 
          ? Colors.white.withOpacity(0.1) 
          : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      color: onPressed != null
          ? (isDark ? Colors.white : Colors.grey[800])
          : (isDark ? Colors.white38 : Colors.grey[400]),
    ),
  );
}
