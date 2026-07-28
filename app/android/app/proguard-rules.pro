# Eter release shrink rules.
#
# Flutter's own engine classes are kept by the plugin's default configuration;
# everything here covers native or reflective surfaces R8 cannot see.

# Health Connect / Apple Health bridge (health plugin) reaches androidx.health
# request classes reflectively through the permission controller.
-keep class androidx.health.connect.client.** { *; }
-keep class androidx.health.platform.** { *; }
-dontwarn androidx.health.**

# sqlite3_flutter_libs loads the native library through JNI.
-keep class com.tekartik.** { *; }
-keep class io.requery.android.database.** { *; }

# speech_to_text binds to the platform recognition service.
-keep class com.csdcorp.speech_to_text.** { *; }

# Play Core split-install stubs referenced by the Flutter embedding but absent
# from a non-Play build.
-dontwarn com.google.android.play.core.**
