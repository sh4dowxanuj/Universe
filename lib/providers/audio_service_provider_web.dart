import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:universe/Screens/Player/audioplayer.dart';

/// Web stub for audio handling. Provides minimal in-memory behavior to keep the
/// app responsive without background/media-session features.
class AudioHandlerHelper {
  static final AudioHandlerHelper _instance = AudioHandlerHelper._internal();
  factory AudioHandlerHelper() => _instance;
  AudioHandlerHelper._internal();

  static bool _isInitialized = false;
  static AudioPlayerHandler? audioHandler;

  Future<void> _initialize() async {
    audioHandler = WebAudioPlayerHandler();
  }

  Future<AudioPlayerHandler> getAudioHandler() async {
    if (!_isInitialized) {
      await _initialize();
      _isInitialized = true;
    }
    return audioHandler!;
  }
}

class WebAudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements AudioPlayerHandler {
  final BehaviorSubject<List<MediaItem>> _queueSubject =
      BehaviorSubject<List<MediaItem>>.seeded(<MediaItem>[]);
  final BehaviorSubject<QueueState> _queueStateSubject =
      BehaviorSubject<QueueState>.seeded(QueueState.empty);
  final BehaviorSubject<double> _volume = BehaviorSubject.seeded(1.0);
  final BehaviorSubject<double> _speed = BehaviorSubject.seeded(1.0);

  @override
  Stream<QueueState> get queueState => _queueStateSubject.stream;

  @override
  ValueStream<double> get volume => _volume;

  @override
  Future<void> setVolume(double volume) async {
    _volume.add(volume);
  }

  @override
  ValueStream<double> get speed => _speed;

  @override
  Future<void> setSpeed(double speed) async {
    _speed.add(speed);
    playbackState.add(
      playbackState.value.copyWith(
        speed: speed,
      ),
    );
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    final List<MediaItem> items = List.of(_queueSubject.value);
    if (currentIndex < 0 || currentIndex >= items.length) return;
    final MediaItem item = items.removeAt(currentIndex);
    final targetIndex = newIndex.clamp(0, items.length);
    items.insert(targetIndex, item);
    _queueSubject.add(items);
    _queueStateSubject.add(
      QueueState(items, 0, null, AudioServiceRepeatMode.none),
    );
    queue.add(items);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final List<MediaItem> items = List.of(_queueSubject.value)..add(mediaItem);
    _queueSubject.add(items);
    _queueStateSubject.add(
      QueueState(items, 0, null, AudioServiceRepeatMode.none),
    );
    queue.add(items);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final List<MediaItem> items = List.of(_queueSubject.value)..addAll(mediaItems);
    _queueSubject.add(items);
    _queueStateSubject.add(
      QueueState(items, 0, null, AudioServiceRepeatMode.none),
    );
    queue.add(items);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _queueStateSubject.add(
      QueueState(
        _queueSubject.value,
        index,
        _queueStateSubject.value.shuffleIndices,
        _queueStateSubject.value.repeatMode,
      ),
    );
    playbackState.add(playbackState.value.copyWith(queueIndex: index));
  }

  @override
  Future<void> play() async {
    playbackState.add(
      playbackState.value.copyWith(playing: true),
    );
  }

  @override
  Future<void> pause() async {
    playbackState.add(
      playbackState.value.copyWith(playing: false),
    );
  }

  @override
  Future<void> stop() async {
    playbackState.add(
      playbackState.value.copyWith(playing: false),
    );
  }
}
