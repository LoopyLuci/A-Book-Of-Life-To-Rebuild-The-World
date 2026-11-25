package org.abookoflife.app

import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.google.common.truth.Truth.assertThat
import org.abookoflife.core.data.update.ApkInstaller
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The install checks run on every API level the app supports. Calling a platform
 * method that a device does not have crashes the app, so these tests make sure the
 * checks and the settings screen they open exist on the oldest supported device too.
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
}
