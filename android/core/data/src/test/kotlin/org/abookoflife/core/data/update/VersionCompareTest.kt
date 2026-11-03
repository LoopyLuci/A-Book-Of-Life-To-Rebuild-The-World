package org.abookoflife.core.data.update

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class VersionCompareTest {

    @Test
    fun `a higher patch version is newer`() {
        assertThat(VersionCompare.isNewer("v1.0.1", "1.0.0")).isTrue()
        assertThat(VersionCompare.isNewer("v1.0.0", "1.0.1")).isFalse()
    }

    @Test
    fun `a higher minor version is newer`() {
        assertThat(VersionCompare.isNewer("v1.2.0", "1.1.9")).isTrue()
    }

    @Test
    fun `a leading v is ignored on either side`() {
        assertThat(VersionCompare.isNewer("v2.0.0", "1.9.9")).isTrue()
        assertThat(VersionCompare.isNewer("2.0.0", "v1.9.9")).isTrue()
    }

    @Test
    fun `a release is newer than its own pre-release`() {
        assertThat(VersionCompare.isNewer("1.0.0", "1.0.0-rc1")).isTrue()
        assertThat(VersionCompare.isNewer("1.0.0-rc1", "1.0.0")).isFalse()
    }

    @Test
    fun `an equal version is not newer`() {
        assertThat(VersionCompare.isNewer("v1.0.0", "1.0.0")).isFalse()
        assertThat(VersionCompare.compare("v1.0.0", "1.0.0")).isEqualTo(0)
    }

    @Test
    fun `missing components count as zero`() {
        assertThat(VersionCompare.isNewer("1.1", "1.0.5")).isTrue()
        assertThat(VersionCompare.isNewer("1.0", "1.0.0")).isFalse()
    }

    @Test
    fun `an alpha build is older than a release of the same number`() {
        assertThat(VersionCompare.isNewer("0.1.0", "0.1.0-alpha")).isTrue()
    }
}
