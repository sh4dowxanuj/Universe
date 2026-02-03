# 🎵 Universe Music Player

<div align="center">

![Universe Music Player](assets/ic_launcher.png)

**An Open-Source Music Player App for all your needs!**

[![GitHub stars](https://img.shields.io/github/stars/sh4dowxanuj/Universe?style=social)](https://github.com/sh4dowxanuj/Universe/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/sh4dowxanuj/Universe?style=social)](https://github.com/sh4dowxanuj/Universe/network/members)
[![GitHub license](https://img.shields.io/github/license/sh4dowxanuj/Universe)](https://github.com/sh4dowxanuj/Universe/blob/main/LICENSE)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.3.0%2B-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS-green.svg)](https://github.com/sh4dowxanuj/Universe)

[Features](#-features) • [Installation](#-installation) • [Building](#-building-from-source) • [Usage](#-usage) • [Contributing](#-contributing) • [License](#-license)

</div>

---

## 📖 About

Universe is a feature-rich, open-source music player application built with Flutter. It provides a seamless music streaming and playback experience with support for both online and offline music. With Universe, you can enjoy high-quality audio streaming, manage playlists, import music from various sources, and much more—all without ads or subscriptions!

The app is designed to work across multiple platforms including Android, iOS, Windows, Linux, and macOS, making it your universal music companion.

## ✨ Features

### 🎧 Audio Playback
- **Best Streaming Quality** - Stream music at 320kbps bitrate
- **Play Online & Offline** - Enjoy music with or without internet
- **Queue Management** - Full control over your playback queue
- **Sleep Timer** - Set a timer to automatically stop playback
- **Background Playback** - Keep listening while using other apps

### 🔍 Discovery & Search
- **Music Search** - Find any song, artist, or album
- **Trending Songs** - Discover what's hot right now
- **Top Charts** - Local and Global Top Spotify songs
- **15+ Music Languages** - Multi-language music support
- **YouTube Integration** - Search and play music from YouTube

### 📚 Library Management
- **Playlists Support** - Create and manage custom playlists
- **Import from Spotify** - Bring your Spotify playlists
- **Favorites** - Add songs to your favorites collection
- **Downloads** - Save music for offline playback (320kbps with ID3 tags)
- **Listening History** - Track your music listening habits
- **Statistics** - View your music listening statistics

### 🎨 Customization
- **Dark Mode** - Easy on the eyes
- **Accent Colors** - Customize the app's appearance
- **Lyrics Support** - Sing along with synchronized lyrics
- **Widget Support** - Control playback from your home screen

### 🔧 Additional Features
- **Android Auto Support** - Safe music control while driving
- **Cache Support** - Faster loading and data saving
- **Deep Linking** - Open songs from external links
- **File Format Support** - Play various audio formats (MP3, M4A, AAC, FLAC, OGG, WAV, and more)
- **Share Music** - Share songs with friends
- **Auto Update Check** - Stay up to date with the latest version
- **No Ads** - Completely ad-free experience
- **No Subscription** - Free forever

## 📥 Installation

### Android

#### Option 1: Download APK
1. Go to the [Releases](https://github.com/sh4dowxanuj/Universe/releases) page
2. Download the latest APK file
3. Install the APK on your Android device
   - You may need to enable "Install from Unknown Sources" in your device settings

#### Option 2: Build from Source
See the [Building from Source](#-building-from-source) section below.

### iOS
Currently, the iOS version needs to be built from source. See the [Building from Source](#-building-from-source) section.

### Windows
Download the MSIX installer from the [Releases](https://github.com/sh4dowxanuj/Universe/releases) page and install it on your Windows 10/11 device.

### Linux
Build from source following the instructions in the [Building from Source](#-building-from-source) section.

### macOS
Build from source following the instructions in the [Building from Source](#-building-from-source) section.

## 🛠️ Building from Source

### Prerequisites

Before building Universe, ensure you have the following installed:

- **Flutter SDK** (3.3.0 or higher)
  - Install from [flutter.dev](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (3.1.0 or higher) - Usually comes with Flutter
- **Git** - For cloning the repository

#### Platform-Specific Requirements

**Android:**
- Android SDK (API level 21 or higher)
- Android Studio or VS Code with Flutter extensions
- Java Development Kit (JDK) 11 or higher
- Python 3.11 (for yt-dlp integration)

**iOS:**
- Xcode 12 or higher
- CocoaPods
- macOS (iOS apps can only be built on macOS)

**Windows:**
- Visual Studio 2019 or higher with C++ desktop development tools

**Linux:**
- Clang
- CMake
- GTK development libraries
- Ninja build system

**macOS:**
- Xcode 12 or higher
- CocoaPods

### Build Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/sh4dowxanuj/Universe.git
   cd Universe
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Build for Your Platform**

   **Android:**
   ```bash
   # Debug build
   flutter build apk --debug
   
   # Release build
   flutter build apk --release
   
   # Split APK by ABI (smaller file sizes)
   flutter build apk --split-per-abi --release
   ```

   **iOS:**
   ```bash
   # Debug build
   flutter build ios --debug
   
   # Release build
   flutter build ios --release
   ```

   **Windows:**
   ```bash
   flutter build windows --release
   
   # To create MSIX installer
   flutter pub run msix:create
   ```

   **Linux:**
   ```bash
   flutter build linux --release
   ```

   **macOS:**
   ```bash
   flutter build macos --release
   ```

4. **Run the App**
   ```bash
   # Connect your device or start an emulator
   flutter devices
   
   # Run the app
   flutter run
   ```

### Troubleshooting Build Issues

- **Flutter Doctor**: Run `flutter doctor` to check for any missing dependencies
- **Clean Build**: If you encounter issues, try cleaning the build:
  ```bash
  flutter clean
  flutter pub get
  ```
- **Android Build Issues**: Ensure you have the correct Android SDK tools installed
- **iOS Build Issues**: Run `pod install` in the `ios` directory if dependencies fail

## 🚀 Usage

### First Launch
1. Open the Universe app
2. Grant necessary permissions (Storage, Internet access)
3. Start exploring music!

### Basic Operations

#### Searching for Music
- Tap the search icon in the home screen
- Enter song name, artist, or album
- Browse results from multiple sources (JioSaavn, YouTube, etc.)

#### Playing Music
- Tap any song to start playback
- Use the mini player at the bottom for quick controls
- Tap the mini player to open the full player screen

#### Managing Playlists
- Go to Library → Playlists
- Tap "+" to create a new playlist
- Long press on songs to add them to playlists

#### Downloading Music
- Open any song
- Tap the download button
- Access downloaded songs in Library → Downloads

#### Importing from Spotify
1. Go to Settings
2. Select "Import Playlist from Spotify"
3. Log in with your Spotify account
4. Select playlists to import

### Keyboard Shortcuts (Desktop)

When running on desktop platforms, the following keyboard shortcuts are available:
- **Space**: Play/Pause
- **Right Arrow**: Next track
- **Left Arrow**: Previous track
- **Up Arrow**: Volume up
- **Down Arrow**: Volume down

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### Ways to Contribute

1. **Report Bugs**: Open an issue describing the bug with steps to reproduce
2. **Suggest Features**: Open an issue with your feature idea
3. **Submit Pull Requests**: Fix bugs or implement new features
4. **Improve Documentation**: Help us make our docs better
5. **Translate**: Help translate the app to more languages

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

### Code Style

- Follow Dart's [official style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure your code passes `flutter analyze` without errors

### Testing

Before submitting a PR:
- Test your changes on relevant platforms
- Ensure the app builds without errors
- Verify no existing functionality is broken

## 📝 License

Universe is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.

```
Copyright (c) 2021-2023 SH4DOWXANUJ

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Music streaming powered by JioSaavn API
- YouTube integration via [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart)
- Audio playback by [just_audio](https://pub.dev/packages/just_audio)
- Special thanks to all [contributors](https://github.com/sh4dowxanuj/Universe/graphs/contributors)

## 📞 Support

If you like this project, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs via [Issues](https://github.com/sh4dowxanuj/Universe/issues)
- 💡 Suggesting new features
- 🔀 Contributing via Pull Requests

## 🔗 Links

- **GitHub Repository**: [https://github.com/sh4dowxanuj/Universe](https://github.com/sh4dowxanuj/Universe)
- **Issue Tracker**: [https://github.com/sh4dowxanuj/Universe/issues](https://github.com/sh4dowxanuj/Universe/issues)
- **Releases**: [https://github.com/sh4dowxanuj/Universe/releases](https://github.com/sh4dowxanuj/Universe/releases)

---

<div align="center">

**Made with ❤️ by SH4DOWXANUJ**

If you found this project helpful, please give it a ⭐!

@sh4dowxanuj ➜ /workspaces/BlackHole (main) $ flutter --version
Flutter 3.16.9 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 41456452f2 (2 years ago) • 2024-01-25 10:06:23 -0800
Engine • revision f40e976bed
Tools • Dart 3.2.6 • DevTools 2.28.5
@sh4dowxanuj ➜ /workspaces/BlackHole (main) $ 

</div>
