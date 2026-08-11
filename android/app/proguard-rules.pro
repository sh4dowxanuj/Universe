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

# You can add more keep rules for third-party libraries if minification breaks them.
