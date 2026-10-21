package org.abookoflife.core.designsystem.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Architecture
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.Eco
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Handyman
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.LocalShipping
import androidx.compose.material.icons.outlined.WaterDrop
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.MedicalServices
import androidx.compose.material.icons.outlined.Public
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import org.abookoflife.core.model.Difficulty
import org.abookoflife.core.model.SafetyLevel
import org.abookoflife.core.model.VerificationStatus

data class AccentColors(val container: Color, val content: Color)

object AbookAccents {

    fun safety(level: SafetyLevel, dark: Boolean): AccentColors = when (level) {
        SafetyLevel.GREEN -> AccentColors(
            if (dark) SafeContainerDark else SafeContainerLight,
            if (dark) SafeContentDark else SafeContentLight,
        )
        SafetyLevel.YELLOW -> AccentColors(
            if (dark) CautionContainerDark else CautionContainerLight,
            if (dark) CautionContentDark else CautionContentLight,
        )
        SafetyLevel.RED -> AccentColors(
            if (dark) DangerContainerDark else DangerContainerLight,
            if (dark) DangerContentDark else DangerContentLight,
        )
        SafetyLevel.UNKNOWN -> AccentColors(
            if (dark) NeutralContainerDark else NeutralContainerLight,
            if (dark) NeutralContentDark else NeutralContentLight,
        )
    }

    fun difficulty(value: Difficulty, dark: Boolean): AccentColors = when (value) {
        Difficulty.BEGINNER -> AccentColors(
            if (dark) SafeContainerDark else SafeContainerLight,
            if (dark) SafeContentDark else SafeContentLight,
        )
        Difficulty.INTERMEDIATE -> AccentColors(
            if (dark) TealDarkContainer else TealContainer,
            if (dark) TealContainer else ForestOnContainer,
        )
        Difficulty.ADVANCED -> AccentColors(
            if (dark) CautionContainerDark else CautionContainerLight,
            if (dark) CautionContentDark else CautionContentLight,
        )
        Difficulty.EXPERT -> AccentColors(
            if (dark) DangerContainerDark else DangerContainerLight,
            if (dark) DangerContentDark else DangerContentLight,
        )
        Difficulty.UNKNOWN -> AccentColors(
            if (dark) NeutralContainerDark else NeutralContainerLight,
            if (dark) NeutralContentDark else NeutralContentLight,
        )
    }

    fun verification(status: VerificationStatus, dark: Boolean): AccentColors = when (status) {
        VerificationStatus.FIELD_TESTED -> AccentColors(
            if (dark) SafeContainerDark else SafeContainerLight,
            if (dark) SafeContentDark else SafeContentLight,
        )
        VerificationStatus.PEER_REVIEWED -> AccentColors(
            if (dark) TealDarkContainer else TealContainer,
            if (dark) TealContainer else ForestOnContainer,
        )
        VerificationStatus.DRAFT -> AccentColors(
            if (dark) NeutralContainerDark else NeutralContainerLight,
            if (dark) NeutralContentDark else NeutralContentLight,
        )
        VerificationStatus.DEPRECATED -> AccentColors(
            if (dark) DangerContainerDark else DangerContainerLight,
            if (dark) DangerContentDark else DangerContentLight,
        )
        VerificationStatus.UNKNOWN -> AccentColors(
            if (dark) NeutralContainerDark else NeutralContainerLight,
            if (dark) NeutralContentDark else NeutralContentLight,
        )
    }
}

fun domainIcon(name: String): ImageVector = when (name) {
    "local_fire_department" -> Icons.Outlined.LocalFireDepartment
    "water_drop" -> Icons.Outlined.WaterDrop
    "eco" -> Icons.Outlined.Eco
    "handyman" -> Icons.Outlined.Handyman
    "bolt" -> Icons.Outlined.Bolt
    "architecture" -> Icons.Outlined.Architecture
    "local_shipping" -> Icons.Outlined.LocalShipping
    "medical_services" -> Icons.Outlined.MedicalServices
    "menu_book" -> Icons.AutoMirrored.Outlined.MenuBook
    "groups" -> Icons.Outlined.Groups
    else -> Icons.Outlined.Public
}

/** Domain accent colors keyed by the palette defined in the knowledge base. */
@Composable
@ReadOnlyComposable
fun domainAccentColor(hex: String): Color = parseHexColor(hex, MaterialThemeFallback)

fun parseHexColor(hex: String, fallback: Color): Color {
    val normalized = hex.removePrefix("#")
    return try {
        when (normalized.length) {
            6 -> Color(0xFF000000 or normalized.toLong(16))
            8 -> Color(normalized.toLong(16))
            else -> fallback
        }
    } catch (_: NumberFormatException) {
        fallback
    }
}

private val MaterialThemeFallback = Color(0xFF2E6B3E)
