package org.abookoflife.app

import android.app.Application
import android.util.Log
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.abookoflife.core.data.preferences.UserSettingsRepository
import org.abookoflife.core.data.update.AutoUpdateScheduler

@HiltAndroidApp
class AbookApp : Application() {

    @Inject
    lateinit var settingsRepository: UserSettingsRepository

    @Inject
    lateinit var updateScheduler: AutoUpdateScheduler

    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        appScope.launch {
            try {
                updateScheduler.setPolicy(settingsRepository.settings.first().updatePolicy)
            } catch (error: Exception) {
                Log.e(TAG, "Could not restore automatic update schedule", error)
            }
        }
    }

    private companion object {
        const val TAG = "AbookApp"
    }
}
