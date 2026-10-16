package org.abookoflife.core.data

import kotlinx.serialization.json.Json

object JsonCodec {
    val json: Json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        explicitNulls = false
    }
}
