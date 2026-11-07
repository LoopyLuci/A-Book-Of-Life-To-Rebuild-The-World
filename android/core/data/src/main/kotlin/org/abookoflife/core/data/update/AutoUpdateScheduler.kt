package org.abookoflife.core.data.update

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton
import org.abookoflife.core.model.UpdatePolicy

@Singleton
class AutoUpdateScheduler @Inject constructor(
    @ApplicationContext context: Context,
) {
    private val workManager = WorkManager.getInstance(context)

    fun setPolicy(policy: UpdatePolicy) {
        if (policy == UpdatePolicy.MANUAL) {
            workManager.cancelUniqueWork(INITIAL_CHECK_WORK)
            workManager.cancelUniqueWork(PERIODIC_CHECK_WORK)
            return
        }

        val requestConstraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
        workManager.enqueueUniquePeriodicWork(
            PERIODIC_CHECK_WORK,
            ExistingPeriodicWorkPolicy.UPDATE,
            PeriodicWorkRequestBuilder<AutoUpdateWorker>(CHECK_INTERVAL_HOURS, TimeUnit.HOURS)
                .setConstraints(requestConstraints)
                .build(),
        )
        workManager.enqueueUniqueWork(
            INITIAL_CHECK_WORK,
            ExistingWorkPolicy.KEEP,
            OneTimeWorkRequestBuilder<AutoUpdateWorker>()
                .setConstraints(requestConstraints)
                .build(),
        )
    }

    private companion object {
        const val INITIAL_CHECK_WORK = "automatic-update-initial-check"
        const val PERIODIC_CHECK_WORK = "automatic-update-periodic-check"
        const val CHECK_INTERVAL_HOURS = 24L
    }
}
