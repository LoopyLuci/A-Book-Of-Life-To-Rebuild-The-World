package org.abookoflife.core.data.update

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class PackageSelectorTest {

    private val current = "abook-of-life-v1.2.0-current.apk"
    private val legacy = "abook-of-life-v1.2.0-legacy.apk"
    private val singlePackage = "abook-of-life-v1.1.0.apk"

    @Test
    fun `a legacy package is recognised by its name`() {
        assertThat(PackageSelector.isLegacyPackage(legacy)).isTrue()
        assertThat(PackageSelector.isLegacyPackage(current)).isFalse()
        assertThat(PackageSelector.isLegacyPackage(singlePackage)).isFalse()
    }

    @Test
    fun `a device on Android 8 or newer takes the current package`() {
        assertThat(PackageSelector.matchesDevice(current, 26)).isTrue()
        assertThat(PackageSelector.matchesDevice(current, 35)).isTrue()
        assertThat(PackageSelector.matchesDevice(legacy, 26)).isFalse()
    }

    @Test
    fun `a device older than Android 8 takes the legacy package only`() {
        assertThat(PackageSelector.matchesDevice(legacy, 22)).isTrue()
        assertThat(PackageSelector.matchesDevice(legacy, 25)).isTrue()
        assertThat(PackageSelector.matchesDevice(current, 25)).isFalse()
    }

    @Test
    fun `a release from before the split still serves devices on Android 8 or newer`() {
        assertThat(PackageSelector.matchesDevice(singlePackage, 26)).isTrue()
        assertThat(PackageSelector.matchesDevice(singlePackage, 22)).isFalse()
    }
}
