# Keep Play Core Library Classes
-keep class com.google.android.play.core.** { *; }

# Keep Flutter Deferred Components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Keep Tasks and SplitInstallManager
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Keep Agora SDK (jika Anda menggunakannya)
-keep class io.agora.** { *; }
-keepattributes *Annotation*

# Keep desugar runtime classes
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }

# Prevent R8 from shrinking or removing Play Core and related classes
-keep class com.google.android.play.** { *; }

# Prevent R8 from shrinking methods or classes used by Play Install
-keepnames class com.google.android.** { *; }
-dontwarn com.google.android.**