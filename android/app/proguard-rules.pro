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

# General rules
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
