package org.abookoflife.feature.settings

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

private const val APK_MIME = "application/vnd.android.package-archive"

internal fun apkFileName(context: Context): String {
    val version = runCatching {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName
    }.getOrNull()?.takeIf { it.isNotBlank() }?.replace(' ', '-')
    return if (version == null) "A-Book-Of-Life.apk" else "A-Book-Of-Life-$version.apk"
}

/**
 * Copies the installed APK into the shared Downloads collection.
 *
 * On Android 10+ this uses [MediaStore] and needs no storage permission. Older
 * releases fall back to the public Downloads directory and require
 * `WRITE_EXTERNAL_STORAGE`.
 *
 * @return the saved file name, or `null` when the copy failed.
 */
suspend fun exportAppApkToDownloads(context: Context): String? = withContext(Dispatchers.IO) {
    runCatching {
        val source = File(context.applicationInfo.sourceDir)
        if (!source.exists()) return@runCatching null
        val name = apkFileName(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            writeViaMediaStore(context, source, name)
        } else {
            writeToLegacyDownloads(context, source, name)
        }
    }.getOrNull()
}

@RequiresApi(Build.VERSION_CODES.Q)
private fun writeViaMediaStore(context: Context, source: File, name: String): String? {
    val resolver = context.contentResolver
    val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
    deleteExistingDownloads(resolver, collection, name)

    val values = ContentValues().apply {
        put(MediaStore.Downloads.DISPLAY_NAME, name)
        put(MediaStore.Downloads.MIME_TYPE, APK_MIME)
        put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/")
        put(MediaStore.Downloads.IS_PENDING, 1)
    }
    val uri = resolver.insert(collection, values) ?: return null
    return try {
        resolver.openOutputStream(uri)?.use { output ->
            source.inputStream().use { input -> input.copyTo(output) }
        } ?: error("Could not open $uri")

        resolver.update(
            uri,
            ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
            null,
            null,
        )
        name
    } catch (throwable: Throwable) {
        resolver.delete(uri, null, null)
        throw throwable
    }
}

@RequiresApi(Build.VERSION_CODES.Q)
private fun deleteExistingDownloads(
    resolver: android.content.ContentResolver,
    collection: Uri,
    name: String,
) {
    val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ? AND " +
        "${MediaStore.Downloads.RELATIVE_PATH} = ?"
    val args = arrayOf(name, "${Environment.DIRECTORY_DOWNLOADS}/")
    resolver.query(
        collection,
        arrayOf(MediaStore.Downloads._ID),
        selection,
        args,
        null,
    )?.use { cursor ->
        val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
        while (cursor.moveToNext()) {
            resolver.delete(ContentUris.withAppendedId(collection, cursor.getLong(idColumn)), null, null)
        }
    }
}

private fun writeToLegacyDownloads(context: Context, source: File, name: String): String? {
    val granted = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.WRITE_EXTERNAL_STORAGE,
    ) == PackageManager.PERMISSION_GRANTED
    if (!granted) return null

    val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
    if (!directory.exists() && !directory.mkdirs()) return null

    val target = uniqueTarget(directory, name)
    source.inputStream().use { input ->
        target.outputStream().use { output -> input.copyTo(output) }
    }
    return target.name
}

private fun uniqueTarget(directory: File, name: String): File {
    val base = name.removeSuffix(".apk")
    var candidate = File(directory, name)
    var index = 1
    while (candidate.exists()) {
        candidate = File(directory, "$base ($index).apk")
        index += 1
    }
    return candidate
}
