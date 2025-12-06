# Testing Guide - YouTube Audio Functionality

## Quick Start Testing

### Prerequisites
```bash
# Ensure you're in the project directory
cd /workspaces/Universe

# Install dependencies
flutter pub get

# Run the app (choose your platform)
flutter run        # For connected device
flutter run -d linux     # For Linux
flutter run -d windows   # For Windows
```

---

## Test Scenarios

### 1. Basic Search Test 🔍

**Steps:**
1. Launch the app
2. Navigate to YouTube section
3. Search for: "Bohemian Rhapsody"
4. Verify results appear

**Expected:**
- Search results load within 3-5 seconds
- Multiple results displayed
- Thumbnails load correctly
- Artist and duration shown

**Log Check:**
```bash
# Look for these logs
"Searching YouTube for: Bohemian Rhapsody"
"Found X search results"
```

---

### 2. Audio Playback Test 🎵

**Steps:**
1. Search for a song
2. Tap on a result to play
3. Wait for playback to start
4. Check audio quality

**Expected:**
- Playback starts within 2-3 seconds
- Audio is clear and uninterrupted
- Progress bar updates smoothly
- Controls respond correctly

**Log Check:**
```bash
# Look for these logs
"Fetching stream manifest for video: VIDEO_ID"
"Found X audio streams"
"Valid cache found for VIDEO_ID" (on subsequent plays)
```

---

### 3. Download Test ⬇️

**Steps:**
1. Search for a song
2. Long-press or use download button
3. Select quality (High/Low)
4. Start download

**Expected:**
- Download progress shows
- File saves to correct location
- Metadata tagged correctly
- Album art embedded

**Log Check:**
```bash
# Look for these logs
"Downloading from YouTube: VIDEO_ID"
"Selected stream: QUALITY (BITRATE kbps)"
"Download complete, modifying file"
```

---

### 4. Cache Validation Test 💾

**Steps:**
1. Play a song completely
2. Play the same song again
3. Check if cached link is used

**Expected:**
- Second play should be faster
- No unnecessary API calls
- Smooth playback

**Log Check:**
```bash
# First play
"No cache found for VIDEO_ID, fetching fresh URLs"

# Second play (within 10 minutes)
"Valid cache found for VIDEO_ID"
```

---

### 5. Link Refresh Test 🔄

**Steps:**
1. Play a song
2. Keep it in queue for 10+ minutes
3. Skip back to it

**Expected:**
- Link refreshes automatically
- No playback errors
- Smooth transition

**Log Check:**
```bash
"YouTube link expired for SONG_TITLE, refreshing..."
"Successfully refreshed link for SONG_TITLE"
```

---

### 6. Error Handling Test ⚠️

**Steps:**
1. Search for invalid content
2. Try to play age-restricted video
3. Test with no internet (airplane mode)

**Expected:**
- Graceful error messages
- App doesn't crash
- Clear user feedback

**Log Check:**
```bash
"Error in fetchSearchResults"
"No audio streams available"
"Failed to refresh link"
```

---

## Debug Mode Testing

### Enable Verbose Logging

Add to your run configuration:
```bash
flutter run --verbose
```

### Key Log Patterns to Monitor

1. **Successful Operations:**
   ```
   [INFO] Valid cache found for VIDEO_ID
   [INFO] Successfully fetched X URLs
   [INFO] Found X audio streams
   ```

2. **Cache Operations:**
   ```
   [INFO] Cache expired for VIDEO_ID, fetching new URLs
   [INFO] Using cached link for SONG_TITLE
   ```

3. **Errors:**
   ```
   [SEVERE] Error fetching stream info for VIDEO_ID
   [SEVERE] Failed to refresh link
   [WARNING] No search results found
   ```

---

## Performance Benchmarks

### Expected Performance

| Operation | Expected Time | Acceptable Range |
|-----------|--------------|------------------|
| Search | 2-3 seconds | 1-5 seconds |
| First Play | 2-3 seconds | 1-5 seconds |
| Cached Play | <1 second | <2 seconds |
| Download Start | 1-2 seconds | 1-4 seconds |
| Link Refresh | 2-3 seconds | 1-5 seconds |

---

## Common Issues & Solutions

### Issue 1: "No audio streams available"
**Diagnosis:**
```bash
# Check logs for
"Error fetching stream info for VIDEO_ID"
```
**Solutions:**
- Video may be region-restricted
- Try a different video
- Check internet connection

### Issue 2: Playback stops after 10 minutes
**Diagnosis:**
```bash
# Check logs for
"Cache expired for VIDEO_ID"
"Failed to refresh link"
```
**Solutions:**
- Should auto-refresh (check implementation)
- Manually restart playback
- Clear app cache

### Issue 3: Download fails
**Diagnosis:**
```bash
# Check logs for
"Error fetching YouTube stream"
"No URLs available"
```
**Solutions:**
- Check storage permissions
- Verify internet connection
- Try lower quality setting

---

## Automated Testing Commands

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/youtube_services_test.dart
```

### Generate Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Manual Test Checklist

### Basic Functionality
- [ ] App launches successfully
- [ ] YouTube section loads
- [ ] Search works
- [ ] Results display correctly
- [ ] Playback starts
- [ ] Audio quality is good
- [ ] Download completes
- [ ] Metadata is correct

### Advanced Functionality
- [ ] Cache works correctly
- [ ] Link refresh works
- [ ] Quality selection works
- [ ] Playlists load
- [ ] Queue management works
- [ ] Offline playback (downloaded)

### Error Cases
- [ ] Invalid search handled
- [ ] Network errors handled
- [ ] Age-restricted content handled
- [ ] Region restrictions handled
- [ ] No crashes observed

---

## Reporting Issues

When reporting issues, include:

1. **Steps to reproduce**
2. **Expected vs actual behavior**
3. **Relevant logs** (especially [SEVERE] and [WARNING])
4. **Device/platform information**
5. **App version**

Example Issue Report:
```
Title: Search fails for specific query

Steps:
1. Open YouTube section
2. Search for "test song"
3. No results appear

Expected: Results should appear
Actual: Empty list

Logs:
[SEVERE] Error in fetchSearchResults for "test song": ...

Device: Android 14
App Version: 1.15.10+41
```

---

## Performance Monitoring

### Check Memory Usage
```bash
flutter run --profile
# Use DevTools to monitor memory
```

### Check Network Calls
```bash
# Enable network logging
flutter run --verbose
# Look for HTTP requests in logs
```

### Check Cache Size
```bash
# Check Hive boxes
# Location: Application Documents/hive/
# Check ytlinkcache.hive size
```

---

## Success Criteria

The YouTube functionality is considered working if:

1. ✅ Search returns results consistently
2. ✅ Playback starts within 5 seconds
3. ✅ No crashes during normal use
4. ✅ Downloads complete successfully
5. ✅ Cache reduces API calls
6. ✅ Link refresh works automatically
7. ✅ Error messages are clear and helpful

---

**Happy Testing! 🎉**

For questions or issues, check the logs and refer to YOUTUBE_FIX_SUMMARY.md for detailed implementation information.
