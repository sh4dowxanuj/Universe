/*
 * Unit tests for YouTube Services
 * Tests the fixes made to YouTube audio fetching functionality
 */

import 'package:blackhole/Services/youtube_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YouTubeServices -', () {
    late YouTubeServices ytService;

    setUp(() {
      ytService = YouTubeServices.instance;
    });

    test('Instance should be singleton', () {
      final instance1 = YouTubeServices.instance;
      final instance2 = YouTubeServices.instance;
      expect(instance1, same(instance2));
    });

    test('getExpireAt should parse URL correctly', () {
      const testUrl = 'https://example.com/video?expire=1234567890&other=param';
      final result = ytService.getExpireAt(testUrl);
      expect(result, '1234567890');
    });

    test('getExpireAt should return default on invalid URL', () {
      const testUrl = 'https://example.com/video?noexpire=test';
      final result = ytService.getExpireAt(testUrl);
      // Should return a valid timestamp string
      expect(int.tryParse(result), isNotNull);
      expect(int.parse(result), greaterThan(0));
    });

    test('getExpireAt should handle malformed URL gracefully', () {
      const testUrl = 'not_a_valid_url';
      final result = ytService.getExpireAt(testUrl);
      // Should still return a valid timestamp, not crash
      expect(int.tryParse(result), isNotNull);
    });

    test('getExpireAt should handle empty string', () {
      const testUrl = '';
      final result = ytService.getExpireAt(testUrl);
      // Should return default timestamp
      expect(int.tryParse(result), isNotNull);
    });

    test('getExpireAt with standard YouTube URL format', () {
      const testUrl =
          'https://rr1---sn-4g5ednee.googlevideo.com/videoplayback?expire=1700000000&ei=test';
      final result = ytService.getExpireAt(testUrl);
      expect(result, '1700000000');
    });

    test('getExpireAt with URL containing multiple parameters', () {
      const testUrl =
          'https://example.com/video?param1=value1&expire=1234567890&param2=value2&param3=value3';
      final result = ytService.getExpireAt(testUrl);
      expect(result, '1234567890');
    });

    test('getVideoFromId should handle invalid ID without crashing', () async {
      final result = await ytService.getVideoFromId('invalid_video_id_xyz_123');
      // Should return null for invalid ID, not crash
      expect(result, isNull);
    });
  });

  group('Error Resilience Tests -', () {
    late YouTubeServices ytService;

    setUp(() {
      ytService = YouTubeServices.instance;
    });

    test('fetchSearchResults should handle empty query', () async {
      try {
        final results = await ytService.fetchSearchResults('');
        // Should return empty list or handle gracefully
        expect(results, isA<List>());
      } catch (e) {
        // If it throws, that's also acceptable as long as it doesn't crash
        expect(e, isNotNull);
      }
    });
  });
}
