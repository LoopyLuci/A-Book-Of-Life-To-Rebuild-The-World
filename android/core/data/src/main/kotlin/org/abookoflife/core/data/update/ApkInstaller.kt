package org.abookoflife.core.data.update

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File

/**
 * Hands a downloaded package to the platform installer.
 *
 * Android never allows an application to install another package silently, so
 * the platform installer is always shown to the user and the user always
 * confirms. The package source must be allowed first, which the user grants
 * on the "install unknown apps" screen.
 */
object ApkInstaller {

    /** Whether the user has allowed this app to install packages. */
    fun canInstall(context: Context): Boolean =
        context.packageManager.canRequestPackageInstalls()

    /** Rejects wrong-package, stale, or differently signed release packages. */
    fun isValidUpdate(context: Context, apk: File): Boolean {
        if (!apk.isFile || apk.length() == 0L) return false

        val packageManager = context.packageManager
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            PackageManager.GET_SIGNATURES
        }
        val downloaded = packageManager.getPackageArchiveInfo(apk.absolutePath, flags) ?: return false
        if (downloaded.packageName != context.packageName) return false

        val installed = packageManager.getPackageInfo(context.packageName, flags)
        val downloadedVersion = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            downloaded.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            downloaded.versionCode.toLong()
        }
        val installedVersion = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            installed.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            installed.versionCode.toLong()
        }
        if (downloadedVersion <= installedVersion) return false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val downloadedSigners = downloaded.signingInfo?.apkContentsSigners ?: return false
            return downloadedSigners.isNotEmpty() && downloadedSigners.all { signer ->
                packageManager.hasSigningCertificate(
                    context.packageName,
                    signer.toByteArray(),
                    PackageManager.CERT_INPUT_SHA256,
                )
            }
        }

        @Suppress("DEPRECATION")
        val downloadedSignatures = downloaded.signatures ?: return false
        @Suppress("DEPRECATION")
        val installedSignatures = installed.signatures ?: return false
        return downloadedSignatures.isNotEmpty() &&
            downloadedSignatures.toSet() == installedSignatures.toSet()
    }

    /** The screen where the user grants permission to install packages. */
    fun permissionIntent(context: Context): Intent =
        Intent(
            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:${context.packageName}"),
        )

    /** The intent that opens the platform installer for a downloaded package. */
    fun installIntent(context: Context, apk: File): Intent {
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            apk,
        )
        return Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, UpdateDownloader.APK_MIME)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
