package com.eterhealth.eter

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Publishing an export into the phone's own Downloads folder.
 *
 * The export used to be written to the application documents directory, which
 * no file manager and no document picker can see — so a person could export
 * their record and then not hand it to anything, including Eter's own restore.
 * Moving it to the app-specific external Downloads did not fix that:
 * `Android/data` is hidden from the picker on Android 11 and later, which this
 * device confirmed.
 *
 * The shared Downloads collection is the answer, and it is reachable through
 * MediaStore **with no permission at all** on API 29+. The alternative —
 * writing to `/storage/emulated/0/Download` directly — needs
 * `MANAGE_EXTERNAL_STORAGE`, which is permission to read every file on the
 * phone. A product whose whole argument is that your record stays yours does
 * not get to ask for that in order to save a JSON file.
 */
class MainActivity : FlutterFragmentActivity() {

    /**
     * What the home-screen widget asked for, if anything.
     *
     * Held rather than delivered, because the intent arrives before Flutter is
     * listening. The Dart side asks for it once it is ready and the field is
     * cleared by the asking — a request to start dictating is answered once,
     * not every time the app is resumed.
     */
    private var pendingWidgetAction: String? = null

    /** The channel, kept so `onNewIntent` can reach it while running. */
    private var widgetChannel: MethodChannel? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // The app was already open. `setIntent` matters: without it
        // `getIntent()` keeps returning the one the app was launched with, and
        // the second press of the widget's button does nothing at all.
        setIntent(intent)
        val action = intent.getStringExtra(EterWidgetProvider.EXTRA_ACTION)
            ?: return
        // Straight through, because nothing is waiting to ask for it: Flutter
        // is running and has already taken whatever was pending.
        widgetChannel?.invokeMethod("action", action)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Redraw whatever is placed, every time the app opens.
        //
        // The widget's own update period is zero — the sentence changes once a
        // day and the app pushes it then — so nothing else asks the provider
        // to draw. That is fine until the app is *replaced*: the launcher
        // re-inflates the new layout, the provider is not called, and the
        // widget sits blank with yesterday's preferences right there beside
        // it. Seen on the phone the first time the layout changed under a
        // placed widget, which is exactly what a store update is.
        EterWidgetProvider.refresh(this)

        pendingWidgetAction = intent?.getStringExtra(EterWidgetProvider.EXTRA_ACTION)
        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "eter/widget-launch",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    // Asked for once, on the first frame Flutter can act on.
                    "take" -> {
                        result.success(pendingWidgetAction)
                        pendingWidgetAction = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "eter/downloads",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    val sourcePath = call.argument<String>("path")
                    val folder = call.argument<String>("folder")
                    if (sourcePath == null || folder == null) {
                        result.error("bad-arguments", "path and folder", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(publish(File(sourcePath), folder))
                    } catch (error: Exception) {
                        // The caller keeps the copy it already wrote, so a
                        // failure here costs discoverability, never the export.
                        result.error("publish-failed", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // The home-screen widget's only supply line.
        //
        // The widget process reads a preference and never the database. A
        // second reader of a schema that migrates, holding a lock outside the
        // app's own lifetime, would be a bad trade for one line of text — and
        // it would put a whole record within reach of a process that needs a
        // sentence.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "eter/widget",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    getSharedPreferences(
                        EterWidgetProvider.PREFERENCES,
                        MODE_PRIVATE,
                    ).edit().apply {
                        // A null sentence clears it. Withdrawing consent, or a
                        // day nothing composed, has to be able to take the
                        // words off the home screen — leaving them there would
                        // be the one place in this product where revoking
                        // something changed nothing.
                        val sentence = call.argument<String>("sentence")
                        if (sentence == null) {
                            remove(EterWidgetProvider.KEY_SENTENCE)
                            remove(EterWidgetProvider.KEY_DATE)
                        } else {
                            putString(EterWidgetProvider.KEY_SENTENCE, sentence)
                            putString(
                                EterWidgetProvider.KEY_DATE,
                                call.argument<String>("date"),
                            )
                        }
                        // Which day the app believes it is. The widget compares
                        // rather than reading a clock of its own, so a redraw
                        // the system triggers at midnight cannot disagree with
                        // the app about what "today" means.
                        putString(
                            EterWidgetProvider.KEY_TODAY,
                            call.argument<String>("today"),
                        )
                        apply()
                    }
                    EterWidgetProvider.refresh(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Copies [source] into `Downloads/<folder>/` and returns the path a person
     * would recognise. Null below API 29, where the caller keeps its own copy.
     */
    private fun publish(source: File, folder: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, source.name)
            put(
                MediaStore.Downloads.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/$folder",
            )
            // Not `application/json`. Android's picker filters by MIME type and
            // hides a `.json` from pickers asking for documents; octet-stream is
            // what most file managers report for it anyway, and Eter's own
            // picker is deliberately unfiltered.
            put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: return null
        resolver.openOutputStream(uri)?.use { out ->
            source.inputStream().use { input -> input.copyTo(out) }
        }
        values.clear()
        values.put(MediaStore.Downloads.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return "${Environment.DIRECTORY_DOWNLOADS}/$folder/${source.name}"
    }
}
