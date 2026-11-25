package org.abookoflife.core.model

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class UpdatePolicyTest {

    @Test
    fun defaultsToManualWhenPreferenceIsMissingOrUnknown() {
        assertThat(UpdatePolicy.fromId(null)).isEqualTo(UpdatePolicy.MANUAL)
        assertThat(UpdatePolicy.fromId("future-policy")).isEqualTo(UpdatePolicy.MANUAL)
        assertThat(UserSettings().updatePolicy).isEqualTo(UpdatePolicy.MANUAL)
    }

    @Test
    fun readsPersistedPolicyIdsWithoutCaseSensitivity() {
        assertThat(UpdatePolicy.fromId("auto_check")).isEqualTo(UpdatePolicy.AUTO_CHECK)
        assertThat(UpdatePolicy.fromId("AUTO_DOWNLOAD")).isEqualTo(UpdatePolicy.AUTO_DOWNLOAD)
        assertThat(UpdatePolicy.fromId("auto_download_and_install"))
            .isEqualTo(UpdatePolicy.AUTO_DOWNLOAD_AND_INSTALL)
    }
}
