package org.abookoflife.core.model

enum class Difficulty(val id: String) {
    BEGINNER("beginner"),
    INTERMEDIATE("intermediate"),
    ADVANCED("advanced"),
    EXPERT("expert"),
    UNKNOWN("unknown"),
    ;

    companion object {
        fun fromId(raw: String?): Difficulty =
            entries.firstOrNull { it.id == raw?.trim()?.lowercase() } ?: UNKNOWN
    }
}

enum class SafetyLevel(val id: String) {
    GREEN("green"),
    YELLOW("yellow"),
    RED("red"),
    UNKNOWN("unknown"),
    ;

    companion object {
        fun fromId(raw: String?): SafetyLevel =
            entries.firstOrNull { it.id == raw?.trim()?.lowercase() } ?: UNKNOWN
    }
}

enum class VerificationStatus(val id: String) {
    DRAFT("draft"),
    PEER_REVIEWED("peer_reviewed"),
    FIELD_TESTED("field_tested"),
    DEPRECATED("deprecated"),
    UNKNOWN("unknown"),
    ;

    val isVerified: Boolean
        get() = this == PEER_REVIEWED || this == FIELD_TESTED

    companion object {
        fun fromId(raw: String?): VerificationStatus {
            val normalized = raw?.trim()?.lowercase()?.replace('-', '_')?.replace(' ', '_')
            return entries.firstOrNull { it.id == normalized } ?: UNKNOWN
        }
    }
}
