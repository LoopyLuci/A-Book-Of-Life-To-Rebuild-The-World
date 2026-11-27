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

    /**
     * Whether the user has allowed this app to install packages.
     *
     * Android 8.0 gives each app its own install permission. Older versions
     * have one "unknown sources" switch for every app, so that switch is what
     * this checks. `canRequestPackageInstalls` only exists from Android 8.0,
     * and calling it earlier crashes the app.
     */
    @Suppress("DEPRECATION")
    fun canInstall(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return context.packageManager.canRequestPackageInstalls()
        }
        return Settings.Secure.getInt(
            context.contentResolver,
            Settings.Secure.INSTALL_NON_MARKET_APPS,
            0,
        ) == 1
    }

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

    /**
     * The screen where the user grants permission to install packages.
     *
     * `ACTION_MANAGE_UNKNOWN_APP_SOURCES` only exists from Android 8.0. Before
     * that the switch sits in the general security settings.
     */
    fun permissionIntent(context: Context): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}"),
            )
        } else {
            Intent(Settings.ACTION_SECURITY_SETTINGS)
        }

    /**
     * The intent that opens the platform installer for a downloaded package.
     *
     * From Android 7.0 the installer takes a content address from FileProvider.
     * Before that it opens only file addresses, so the package is given as a file
     * address. Downloads are kept in the app's external files folder, which the
     * installer can read on those versions.
     */
    fun installIntent(context: Context, apk: File): Intent {
        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                apk,
            )
        } else {
            Uri.fromFile(apk)
        }
        return Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, UpdateDownloader.APK_MIME)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
