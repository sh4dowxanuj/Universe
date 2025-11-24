## Release APK Build Fixes (2025-11-24)

- Fixed duplicate and truncated Kotlin class in `YtDlpPlugin.kt`.
- Restored full, correct implementation of the YtDlpPlugin.
- Created a new release keystore (`release-keystore.jks`) and matching `key.properties`.
- Updated `android/key.properties` to set `keyAlias=blackhole` to match the keystore.
- Cleaned and rebuilt the project to resolve signing and build errors.
- Successfully built a signed release APK at `build/app/outputs/flutter-apk/app-release.apk`.
