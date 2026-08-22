# Basic ProGuard rules for Flutter
# Keep Flutter embedding and plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin Metadata
-keepclassmembers class kotlin.Metadata { *; }

# Keep common JSON/Moshi/Gson model methods if reflection used by plugins
# (add plugin-specific rules if you encounter missing class errors)

# Suppress R8 missing class warnings for Google Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Preserve Chaquopy Python bindings & Native Interfaces
-keep class com.chaquo.python.** { *; }
-dontwarn com.chaquo.python.**

# Prevent strip/obfuscation of native Python methods
-keepclasseswithmembernames class * {
    native <methods>;
}