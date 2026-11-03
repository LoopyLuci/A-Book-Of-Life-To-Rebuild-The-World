package org.abookoflife.core.data.update

/** A published release that carries an installable application package. */
data class ReleaseInfo(
    val tag: String,
    val name: String,
    val notes: String,
    val apkUrl: String,
    val apkSizeBytes: Long,
    val publishedAt: String,
)

/** Outcome of asking the release service whether a newer build exists. */
sealed interface UpdateCheckResult {
    /** The installed build is the newest one published. */
    data class UpToDate(
        val currentVersion: String,
        val latestTag: String,
    ) : UpdateCheckResult

    /** A newer build is published and can be downloaded. */
    data class Available(val release: ReleaseInfo) : UpdateCheckResult

    /** The check could not be completed. */
    data class Failed(val reason: String) : UpdateCheckResult
}
