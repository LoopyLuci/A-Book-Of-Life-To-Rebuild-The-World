package org.abookoflife.core.designsystem.component

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material.icons.outlined.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.theme.AbookAccents
import org.abookoflife.core.designsystem.theme.LocalDarkTheme
import org.abookoflife.core.model.Difficulty
import org.abookoflife.core.model.SafetyLevel
import org.abookoflife.core.model.VerificationStatus

@Composable
fun StatusPill(
    text: String,
    containerColor: Color,
    contentColor: Color,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
) {
    Row(
        modifier = modifier
            .background(containerColor, RoundedCornerShape(percent = 50))
            .padding(horizontal = 10.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = contentColor,
                modifier = Modifier.size(13.dp),
            )
        }
        Text(
            text = text,
            color = contentColor,
            style = MaterialTheme.typography.labelMedium,
        )
    }
}

@Composable
fun SafetyBadge(level: SafetyLevel, modifier: Modifier = Modifier) {
    if (level == SafetyLevel.UNKNOWN) return
    val dark = LocalDarkTheme.current
    val accent = AbookAccents.safety(level, dark)
    val icon = when (level) {
        SafetyLevel.RED -> Icons.Outlined.Warning
        SafetyLevel.YELLOW -> Icons.Outlined.Warning
        else -> Icons.Outlined.Shield
    }
    StatusPill(
        text = safetyLabel(level),
        containerColor = accent.container,
        contentColor = accent.content,
        icon = icon,
        modifier = modifier,
    )
}

@Composable
fun DifficultyBadge(difficulty: Difficulty, modifier: Modifier = Modifier) {
    if (difficulty == Difficulty.UNKNOWN) return
    val accent = AbookAccents.difficulty(difficulty, LocalDarkTheme.current)
    StatusPill(
        text = difficultyLabel(difficulty),
        containerColor = accent.container,
        contentColor = accent.content,
        modifier = modifier,
    )
}

@Composable
fun VerificationBadge(status: VerificationStatus, modifier: Modifier = Modifier) {
    if (status == VerificationStatus.UNKNOWN) return
    val accent = AbookAccents.verification(status, LocalDarkTheme.current)
    val icon = if (status.isVerified) Icons.Outlined.CheckCircle else null
    StatusPill(
        text = verificationLabel(status),
        containerColor = accent.container,
        contentColor = accent.content,
        icon = icon,
        modifier = modifier,
    )
}

@Composable
fun TagPill(text: String, modifier: Modifier = Modifier) {
    StatusPill(
        text = text,
        containerColor = MaterialTheme.colorScheme.surfaceVariant,
        contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier,
    )
}

@Composable
@ReadOnlyComposable
fun safetyLabel(level: SafetyLevel): String = when (level) {
    SafetyLevel.GREEN -> stringResource(R.string.safety_green)
    SafetyLevel.YELLOW -> stringResource(R.string.safety_yellow)
    SafetyLevel.RED -> stringResource(R.string.safety_red)
    SafetyLevel.UNKNOWN -> ""
}

@Composable
@ReadOnlyComposable
fun difficultyLabel(difficulty: Difficulty): String = when (difficulty) {
    Difficulty.BEGINNER -> stringResource(R.string.difficulty_beginner)
    Difficulty.INTERMEDIATE -> stringResource(R.string.difficulty_intermediate)
    Difficulty.ADVANCED -> stringResource(R.string.difficulty_advanced)
    Difficulty.EXPERT -> stringResource(R.string.difficulty_expert)
    Difficulty.UNKNOWN -> ""
}

@Composable
@ReadOnlyComposable
fun verificationLabel(status: VerificationStatus): String = when (status) {
    VerificationStatus.DRAFT -> stringResource(R.string.status_draft)
    VerificationStatus.PEER_REVIEWED -> stringResource(R.string.status_peer_reviewed)
    VerificationStatus.FIELD_TESTED -> stringResource(R.string.status_field_tested)
    VerificationStatus.DEPRECATED -> stringResource(R.string.status_deprecated)
    VerificationStatus.UNKNOWN -> ""
}
