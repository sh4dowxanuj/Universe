import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';

class LyricsReaderModel {
  final LyricController controller;
  final String lyric;
  final String? translationLyric;

  LyricsReaderModel({
    required this.controller,
    required this.lyric,
    this.translationLyric,
  });
}

class LyricsModelBuilder {
  String _mainLyric = '';
  String? _translationLyric;

  LyricsModelBuilder._();

  factory LyricsModelBuilder.create() => LyricsModelBuilder._();

  LyricsModelBuilder bindLyricToMain(String lyric) {
    _mainLyric = lyric;
    return this;
  }

  LyricsModelBuilder bindLyricToTranslation(String lyric) {
    _translationLyric = lyric;
    return this;
  }

  LyricsReaderModel getModel() {
    final LyricController controller = LyricController();
    if (_mainLyric.isNotEmpty) {
      controller.loadLyric(
        _mainLyric,
        translationLyric: _translationLyric,
      );
    }
    return LyricsReaderModel(
      controller: controller,
      lyric: _mainLyric,
      translationLyric: _translationLyric,
    );
  }
}

class UINetease extends LyricStyle {
  UINetease({bool highlight = true})
      : super(
          textStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          activeStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          translationStyle:
              const TextStyle(fontSize: 12, color: Colors.white70),
          translationActiveColor: Colors.white,
          lineTextAlign: TextAlign.center,
          lineGap: 18,
          translationLineGap: 8,
          contentAlignment: CrossAxisAlignment.center,
          contentPadding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          selectionAnchorPosition: 0.5,
          selectionAlignment: MainAxisAlignment.center,
          selectedColor: Colors.white,
          selectedTranslationColor: Colors.white,
          selectionAutoResumeDuration: const Duration(milliseconds: 320),
          activeAutoResumeDuration: const Duration(milliseconds: 3000),
          fadeRange: FadeRange(top: 80, bottom: 80),
          scrollDuration: const Duration(milliseconds: 240),
          scrollDurations: {
            500: const Duration(milliseconds: 500),
            1000: const Duration(milliseconds: 1000),
          },
          activeHighlightColor:
              highlight ? const Color(0xFFFFFFFF) : Colors.transparent,
          activeHighlightExtraFadeWidth: 40,
          enableSwitchAnimation: false,
          selectionAutoResumeMode: SelectionAutoResumeMode.selecting,
        );

  TextStyle getOtherMainTextStyle() {
    return const TextStyle(fontSize: 12, color: Colors.white70);
  }
}

class LyricsReader extends StatelessWidget {
  final LyricsReaderModel? model;
  final int position;
  final LyricStyle lyricUi;
  final bool playing;
  final Size size;
  final Widget Function()? emptyBuilder;

  const LyricsReader({
    super.key,
    required this.model,
    required this.position,
    required this.lyricUi,
    required this.playing,
    required this.size,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final LyricsReaderModel? readerModel = model;
    if (readerModel == null || readerModel.lyric.isEmpty) {
      return emptyBuilder?.call() ?? const SizedBox.shrink();
    }

    readerModel.controller.setProgress(Duration(milliseconds: position));
    return LyricView(
      controller: readerModel.controller,
      width: size.width,
      height: size.height,
      style: lyricUi,
    );
  }
}
