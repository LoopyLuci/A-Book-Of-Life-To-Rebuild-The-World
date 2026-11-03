package org.abookoflife.core.data.update

/**
 * Compares release tags against the installed version name.
 *
 * Tags look like `v1.2.0`, `v1.2.0-rc1` or `1.2.0-alpha.3`. A missing
 * pre-release suffix sorts after any pre-release of the same number, so
 * `1.2.0` is newer than `1.2.0-rc1`.
 */
object VersionCompare {

    fun isNewer(candidate: String, current: String): Boolean =
        compare(candidate, current) > 0

    fun compare(left: String, right: String): Int {
        val (leftCore, leftPre) = split(left)
        val (rightCore, rightPre) = split(right)

        val leftParts = leftCore.split('.').map { it.toIntOrNull() ?: 0 }
        val rightParts = rightCore.split('.').map { it.toIntOrNull() ?: 0 }
        val size = maxOf(leftParts.size, rightParts.size)
        for (index in 0 until size) {
            val a = leftParts.getOrElse(index) { 0 }
            val b = rightParts.getOrElse(index) { 0 }
            if (a != b) return a.compareTo(b)
        }

        return when {
            leftPre == rightPre -> 0
            leftPre == null -> 1
            rightPre == null -> -1
            else -> leftPre.compareTo(rightPre)
        }
    }

    private fun split(version: String): Pair<String, String?> {
        val cleaned = version.trim().removePrefix("v").removePrefix("V")
        val core = cleaned.substringBefore('-')
        val pre = cleaned.substringAfter('-', "").ifBlank { null }
        return core to pre
    }
}
