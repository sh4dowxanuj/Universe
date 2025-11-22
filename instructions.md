You are updating the YouTube integration inside the BlackHole Flutter project.

Fix EVERYTHING that broke due to 2024–2025 YouTube updates.

Here is the full scope of required changes:
• Replace all YouTube Music HTML scraping with the new Innertube Music API.
• Update getMusicHome() to use: POST https://music.youtube.com/youtubei/v1/browse
  Required:
    - X-Goog-Visitor-Id (optional)
    - API key: key=AIzaSyA... (extract from client context)
    - clientContext = "WEB_REMIX" with correct version and locale
• Parse all home sections: CAROUSEL, SHELF, CHARTS, MOODS, QUICK PICKS, NEW RELEASES.

• Update playback logic:
  - Use youtube_explode_dart when possible
  - If extraction fails, implement fallback using YouTube Innertube “player” endpoint:
      POST https://www.youtube.com/youtubei/v1/player
  - Add full signatureCipher + sparam + n-param deobfuscation
  - Support formats: m4a (itag 140), webm/opus (itag 251), fallback to adaptiveFormats.

• Fix 403 forbidden errors:
  - Implement n-param deciphering using the latest player JS
  - Use "client=ANDROID" and "client=WEB_REMIX" fallbacks
  - Add throttling bypass logic (rewrite throttled signatures)
  - Refresh expired links automatically

• Fix YouTube playlist parsing:
  - Replace HTML-based playlist parsing with Innertube playlist browse endpoint

• Update getYtStreamUrls():
  - Add caching
  - Return multiple qualities
  - Add proper expireAt extraction
  - Ensure URLs remain valid for long playback sessions

• Update search suggestions:
  - Use YouTube’s suggestion API or new search endpoint
  - Ensure UTF-8 + HTML entity decoding works

• Make sure all models (video, playlist, stream) are updated to new JSON responses.

Goal:
Provide a single updated youtube_services.dart file with all the following:
  - New Innertube API wrapper
  - New getMusicHome()
  - New URL extractor (Innertube player API)
  - signatureCipher + n-parameter decoder
  - 403/429 resiliency logic
  - youtube_explode fallback
  - Playlist/video parsing fixes
  - Proper error handling with logging

Constraints:
Keep the public API of YouTubeServices the same (methods and return shapes)
Keep the file self-contained and ready to drop into BlackHole
Ensure all returned data matches the JSON structure expected by the UI
No breaking changes to calling code

Deliverables:
A full rewritten youtube_services.dart implementing all above points
Clean and readable Dart code
Uses async/await, no deprecated methods
Works on Flutter stable 3.24+
Must handle YouTube region differences (IN/US/EU)
Must avoid any HTML scraping

Now generate the complete improved youtube_services.dart file with all required functionality working for 2024–2025 YouTube updates.