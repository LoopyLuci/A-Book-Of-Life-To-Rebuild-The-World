package org.abookoflife.core.data.update

import android.content.Context
import android.content.SharedPreferences

/**
 * Remembers which background download belongs to the current update so the
 * app can pick it up again after it was closed or the screen was left.
 */
internal class UpdateStateStore(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("app_update", Context.MODE_PRIVATE)

    var downloadId: Long
        get() = prefs.getLong(KEY_DOWNLOAD_ID, 0L)
        set(value) = prefs.edit().putLong(KEY_DOWNLOAD_ID, value).apply()

    var releaseTag: String
        get() = prefs.getString(KEY_RELEASE_TAG, "").orEmpty()
        set(value) = prefs.edit().putString(KEY_RELEASE_TAG, value).apply()

    var installWhenDownloaded: Boolean
        get() = prefs.getBoolean(KEY_INSTALL_WHEN_DOWNLOADED, false)
        set(value) = prefs.edit().putBoolean(KEY_INSTALL_WHEN_DOWNLOADED, value).apply()

    var lastNotifiedTag: String
        get() = prefs.getString(KEY_LAST_NOTIFIED_TAG, "").orEmpty()
        set(value) = prefs.edit().putString(KEY_LAST_NOTIFIED_TAG, value).apply()

    var installPromptedTag: String
        get() = prefs.getString(KEY_INSTALL_PROMPTED_TAG, "").orEmpty()
        set(value) = prefs.edit().putString(KEY_INSTALL_PROMPTED_TAG, value).apply()

    fun clear() {
        prefs.edit()
            .remove(KEY_DOWNLOAD_ID)
            .remove(KEY_RELEASE_TAG)
            .remove(KEY_INSTALL_WHEN_DOWNLOADED)
            .apply()
    }

    private companion object {
        const val KEY_DOWNLOAD_ID = "download_id"
        const val KEY_RELEASE_TAG = "release_tag"
        const val KEY_INSTALL_WHEN_DOWNLOADED = "install_when_downloaded"
        const val KEY_LAST_NOTIFIED_TAG = "last_notified_tag"
        const val KEY_INSTALL_PROMPTED_TAG = "install_prompted_tag"
    }
}
