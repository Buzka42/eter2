package com.eterhealth.eter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * One sentence on the home screen.
 *
 * Deliberately the smallest thing that could be useful: today's synthesis, in
 * Eter's own type, with no controls, no counts and no numbers. A widget that
 * showed a step total would be a scoreboard on somebody's home screen, which is
 * the register this product exists not to have.
 *
 * **RemoteViews rather than Glance.** Glance means adding Jetpack Compose and
 * its compiler plugin to a build that has already broken three times over
 * toolchain versions — desugaring, AGP 9 and a Kotlin/Java target mismatch —
 * for a surface that is one `TextView`. RemoteViews needs nothing that is not
 * already here.
 *
 * **It reads a preference, never the database.** The app writes the sentence
 * through the `eter/widget` channel when guidance composes. A widget process
 * opening the Drift database would mean a second reader of a schema that
 * migrates, holding a lock, outside the lifetime of the app — and it would put
 * a person's whole record within reach of a process that only needs one line of
 * it.
 */
class EterWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        ids.forEach { id -> render(context, manager, id) }
    }

    private fun render(context: Context, manager: AppWidgetManager, id: Int) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val sentence = preferences.getString(KEY_SENTENCE, null)
        val forDate = preferences.getString(KEY_DATE, null)
        val today = preferences.getString(KEY_TODAY, null)

        val views = RemoteViews(context.packageName, R.layout.eter_widget)

        // A sentence written on another day is not today's, and showing it as
        // though it were would be the one thing this surface must not do. The
        // app tells the widget which day it is when it writes, so the widget
        // never has to decide from a clock of its own — a widget updated at
        // 00:03 by the system reads the same answer the app would give.
        val current = sentence != null && forDate != null && forDate == today
        if (current) {
            views.setTextViewText(R.id.eter_widget_sentence, sentence)
            views.setViewVisibility(R.id.eter_widget_sentence, android.view.View.VISIBLE)
        } else {
            // Nothing rather than something stale, and nothing rather than an
            // invitation: a widget that nags is a widget people remove.
            views.setViewVisibility(R.id.eter_widget_sentence, android.view.View.GONE)
        }

        // Three targets, and each one is a different request.
        //
        // The sentence opens the app where the person left it. The two
        // controls open it *into* the journal — one already listening, one
        // with the keyboard up — because the fastest thing somebody wants from
        // a home screen is to get a thought down before it goes.
        views.setOnClickPendingIntent(R.id.eter_widget_root, open(context, null))
        views.setOnClickPendingIntent(
            R.id.eter_widget_speak,
            open(context, ACTION_SPEAK),
        )
        views.setOnClickPendingIntent(
            R.id.eter_widget_write,
            open(context, ACTION_WRITE),
        )

        manager.updateAppWidget(id, views)
    }

    /**
     * A launch intent carrying [action], or a plain one when it is null.
     *
     * `FLAG_ACTIVITY_SINGLE_TOP` rather than a fresh task: the app is usually
     * already running, and a second instance would be a second database
     * connection to the same file. The extra reaches a running app through
     * `onNewIntent`, which `MainActivity` forwards.
     *
     * The request code is the action, so the three pending intents are three
     * *different* intents. Without that Android reuses the first one it made
     * and every control on the widget does whatever the first one did — a
     * silent fault, and the classic one for widgets.
     */
    private fun open(context: Context, action: String?): PendingIntent? {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: return null
        launch.flags =
            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        if (action != null) launch.putExtra(EXTRA_ACTION, action)
        return PendingIntent.getActivity(
            context,
            action?.hashCode() ?: 0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val EXTRA_ACTION = "eter.widget.action"

        /** Open the journal and start listening. */
        const val ACTION_SPEAK = "speak"

        /** Open the journal with the keyboard up. */
        const val ACTION_WRITE = "write"

        const val PREFERENCES = "eter_widget"
        const val KEY_SENTENCE = "sentence"

        /** The local day the sentence was written for, `YYYY-MM-DD`. */
        const val KEY_DATE = "date"

        /** The local day the app last knew about, in the same form. */
        const val KEY_TODAY = "today"

        /**
         * Redraws every placed widget. Called after the app writes, because a
         * preference change is not something the home screen notices.
         */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, EterWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            context.sendBroadcast(
                Intent(context, EterWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                },
            )
        }
    }
}
