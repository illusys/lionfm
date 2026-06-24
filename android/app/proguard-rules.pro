# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# just_audio
-keep class com.ryanheise.just_audio.** { *; }

# audio_service
-keep class com.ryanheise.audioservice.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Paystack
-keep class co.paystack.android.** { *; }

# Hive
-keep class com.hivedb.** { *; }

# Connectivity
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# General rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes EnclosingMethod
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
# Kotlin metadata preserved for reflection-based serialisation
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings { <fields>; }

# Flutter Play Core (deferred components) — classes referenced by the Flutter
# engine but not present when deferred loading is disabled; suppress R8 warnings.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
