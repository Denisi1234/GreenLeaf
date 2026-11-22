# Keep Flutter wrapper & generated plugin classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep flutter_local_notifications scheduled receivers & models
-keep class com.dexterous.** { *; }

# Keep Google Play Services Code Scanner / ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Ignore optional Flutter deferred-components Play Core references
-dontwarn com.google.android.play.core.**

# Preserve line numbers and source file names for Play Console deobfuscation
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
