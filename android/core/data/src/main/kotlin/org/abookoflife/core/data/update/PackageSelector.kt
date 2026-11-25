package org.abookoflife.core.data.update

/**
 * Chooses which release package a device can install.
 *
 * A release carries two packages. The current build needs Android 8.0 or
 * newer. The legacy build runs on Android 5.1 and newer, and is the only one a
 * device older than 8.0 can install. Both are named after their build flavour,
 * as `abook-of-life-<tag>-current.apk` and `abook-of-life-<tag>-legacy.apk`.
 */
object PackageSelector {

    /** The lowest Android API level the current build supports (Android 8.0). */
    const val CURRENT_MIN_SDK = 26

    fun isLegacyPackage(fileName: String): Boolean =
        fileName.contains("-legacy", ignoreCase = true)

    /**
     * True when the package at [fileName] is the one for a device running
     * Android API level [sdkInt]. A release that predates the split has a
     * single package with no flavour in its name, which counts as current.
     */
    fun matchesDevice(fileName: String, sdkInt: Int): Boolean =
        isLegacyPackage(fileName) == (sdkInt < CURRENT_MIN_SDK)
}
