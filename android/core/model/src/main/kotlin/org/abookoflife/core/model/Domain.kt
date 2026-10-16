package org.abookoflife.core.model

data class Domain(
    val slug: String,
    val title: String,
    val description: String,
    val icon: String,
    val colorHex: String,
    val entryCount: Int,
)
