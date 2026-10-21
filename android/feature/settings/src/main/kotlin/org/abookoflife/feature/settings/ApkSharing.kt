package org.abookoflife.feature.settings

import android.content.ClipData
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File

private const val APK_MIME_TYPE = "application/vnd.android.package-archive"

/**
 * Copies this installation's APK into the cache and opens the system share
 * sheet so the app can be handed to another device without an app store.
 *
 * A [FileProvider] URI is required because Android forbids sharing `file://`
 * URIs with other apps.
 *
 * @return `true` when the chooser was opened.
 */
fun shareAppApk(context: Context): Boolean = runCatching {
    val apk = File(context.applicationInfo.sourceDir)
    val shareDir = File(context.cacheDir, "share").apply { mkdirs() }
    shareDir.listFiles()?.forEach { it.delete() }

    val shared = File(shareDir, apkFileName(context))
    apk.copyTo(shared, overwrite = true)

    val uri = FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        shared,
    )
    val label = context.applicationInfo
        .loadLabel(context.packageManager)
        .toString()

    val intent = Intent(Intent.ACTION_SEND).apply {
        type = APK_MIME_TYPE
        putExtra(Intent.EXTRA_STREAM, uri)
        putExtra(Intent.EXTRA_SUBJECT, label)
        clipData = ClipData.newRawUri(label, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(intent, null))
    true
}.getOrDefault(false)
