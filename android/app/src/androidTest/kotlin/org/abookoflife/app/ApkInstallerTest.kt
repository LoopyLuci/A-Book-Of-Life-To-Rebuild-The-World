package org.abookoflife.app

import android.os.Build
import android.os.Environment
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.google.common.truth.Truth.assertThat
import java.io.File
import org.abookoflife.core.data.update.ApkInstaller
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The install checks run on every API level the app supports. Calling a platform
 * method that a device does not have crashes the app, so these tests make sure the
 * checks, the settings screen they open and the installer intent all work on the
 * oldest supported device too.
 */
@RunWith(AndroidJUnit4::class)
class ApkInstallerTest {

    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @Test
    fun canInstallReturnsWithoutCrashing() {
        // Before Android 8.0 this must read the "unknown sources" switch instead.
        ApkInstaller.canInstall(context)
    }

    @Test
    fun permissionIntentOpensASettingsScreen() {
        val screen = context.packageManager.resolveActivity(ApkInstaller.permissionIntent(context), 0)

        assertThat(screen).isNotNull()
    }

    @Test
    fun installIntentOpensThePlatformInstaller() {
        // Before Android 7.0 the platform installer opens only file:// addresses, and the
        // app's downloads are in the app's external files folder, which it can read.
        assumeTrue(Build.VERSION.SDK_INT < Build.VERSION_CODES.N)
        val folder = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
        assertThat(folder).isNotNull()
        val apk = File(folder, "install-check.apk").apply { writeText("not a real package") }
        try {
            val installer = context.packageManager.resolveActivity(
                ApkInstaller.installIntent(context, apk),
                0,
            )

            assertThat(installer).isNotNull()
        } finally {
            apk.delete()
        }
    }
}
