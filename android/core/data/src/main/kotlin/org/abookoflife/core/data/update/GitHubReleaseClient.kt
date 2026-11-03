package org.abookoflife.core.data.update

import java.io.BufferedReader
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.abookoflife.core.data.JsonCodec

@Serializable
internal data class GitHubReleaseDto(
    @SerialName("tag_name") val tagName: String = "",
    @SerialName("name") val name: String? = null,
    @SerialName("body") val body: String? = null,
    @SerialName("published_at") val publishedAt: String? = null,
    @SerialName("draft") val draft: Boolean = false,
    @SerialName("prerelease") val prerelease: Boolean = false,
    @SerialName("assets") val assets: List<GitHubAssetDto> = emptyList(),
)

@Serializable
internal data class GitHubAssetDto(
    @SerialName("name") val name: String = "",
    @SerialName("size") val size: Long = 0,
    @SerialName("browser_download_url") val browserDownloadUrl: String = "",
    @SerialName("content_type") val contentType: String? = null,
)

/**
 * Reads the latest published release for a repository from the GitHub
 * Releases API. The app is offline-first, so every call is explicit and
 * failure is reported to the caller rather than thrown.
 */
internal class GitHubReleaseClient(
    private val owner: String,
    private val repository: String,
) {
    private val json: Json = JsonCodec.json

    fun latestRelease(): GitHubReleaseDto {
        val endpoint = "https://api.github.com/repos/$owner/$repository/releases/latest"
        val connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = CONNECT_TIMEOUT_MS
            readTimeout = READ_TIMEOUT_MS
            setRequestProperty("Accept", "application/vnd.github+json")
            setRequestProperty("User-Agent", USER_AGENT)
            setRequestProperty("X-GitHub-Api-Version", "2022-11-28")
        }
        try {
            val code = connection.responseCode
            if (code != HttpURLConnection.HTTP_OK) {
                val detail = connection.errorStream?.bufferedReader()?.use(BufferedReader::readText)
                throw IllegalStateException("HTTP $code${detail?.let { ": $it" }.orEmpty()}")
            }
            val body = connection.inputStream.bufferedReader().use(BufferedReader::readText)
            return json.decodeFromString(GitHubReleaseDto.serializer(), body)
        } finally {
            connection.disconnect()
        }
    }

    private companion object {
        const val CONNECT_TIMEOUT_MS = 15_000
        const val READ_TIMEOUT_MS = 20_000
        const val USER_AGENT = "A-Book-Of-Life-Android"
    }
}
