package org.abookoflife.feature.settings

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.SystemUpdate
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import java.io.File
import kotlinx.coroutines.launch
import org.abookoflife.core.data.update.ReleaseInfo
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.theme.LocalDarkTheme
import org.abookoflife.core.designsystem.theme.palettePrimaryColor
import org.abookoflife.core.model.ColorPalette
import org.abookoflife.core.model.ThemeMode

@Composable
fun SettingsRoute(
    modifier: Modifier = Modifier,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    SettingsScreen(
        state = state,
        onThemeChange = viewModel::setTheme,
        onDynamicColorChange = viewModel::setDynamicColor,
        onPaletteChange = viewModel::setPalette,
        onFontScaleChange = viewModel::setFontScale,
        onSerifChange = viewModel::setSerif,
        onReindex = viewModel::reindex,
        onCheckForUpdate = viewModel::checkForUpdate,
        onDownloadUpdate = viewModel::downloadUpdate,
        onCancelUpdate = viewModel::cancelUpdate,
        onResumePendingDownload = viewModel::resumePendingDownload,
        installPackage = { apk ->
            val intent = installPackageIntent(context, apk)
            runCatching { context.startActivity(intent) }.isSuccess
        },
        requestInstallPermission = {
            val intent = installPermissionIntent(context)
            runCatching { context.startActivity(intent) }.isSuccess
        },
        modifier = modifier,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    state: SettingsUiState,
    onThemeChange: (ThemeMode) -> Unit,
    onDynamicColorChange: (Boolean) -> Unit,
    onPaletteChange: (ColorPalette) -> Unit,
    onFontScaleChange: (Float) -> Unit,
    onSerifChange: (Boolean) -> Unit,
    onReindex: () -> Unit,
    onCheckForUpdate: () -> Unit,
    onDownloadUpdate: (ReleaseInfo) -> Unit,
    onCancelUpdate: () -> Unit,
    onResumePendingDownload: () -> Unit,
    installPackage: (File) -> Boolean,
    requestInstallPermission: () -> Boolean,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    val reindexDoneMessage = stringResource(R.string.settings_reindex_done)
    val shareFailedMessage = stringResource(R.string.settings_share_apk_failed)
    var exporting by remember { mutableStateOf(false) }

    LaunchedEffect(state.reindexTick) {
        if (state.reindexTick > 0) {
            snackbarHostState.showSnackbar(reindexDoneMessage)
        }
    }

    // A download started earlier, possibly before the app was closed, is
    // picked up again so the reader can install it.
    LaunchedEffect(Unit) {
        onResumePendingDownload()
    }

    val appVersion = remember {
        runCatching {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName
        }.getOrNull() ?: "-"
    }

    suspend fun saveApkToDownloads() {
        if (exporting) return
        exporting = true
        val saved = exportAppApkToDownloads(context)
        exporting = false
        val message = if (saved == null) {
            context.getString(R.string.settings_export_apk_failed)
        } else {
            context.getString(R.string.settings_export_apk_done, saved)
        }
        snackbarHostState.showSnackbar(message)
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        scope.launch {
            if (granted) {
                saveApkToDownloads()
            } else {
                snackbarHostState.showSnackbar(
                    context.getString(R.string.settings_export_apk_permission),
                )
            }
        }
    }

    val requestExportApk: () -> Unit = {
        if (!exporting) {
            val needsPermission = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                ) != PackageManager.PERMISSION_GRANTED
            if (needsPermission) {
                permissionLauncher.launch(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            } else {
                scope.launch { saveApkToDownloads() }
            }
        }
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0.dp),
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.nav_settings)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SectionLabel(stringResource(R.string.settings_appearance))

            Text(
                text = stringResource(R.string.settings_theme),
                style = MaterialTheme.typography.titleSmall,
            )
            ThemeOption(
                label = stringResource(R.string.theme_system),
                selected = state.settings.themeMode == ThemeMode.SYSTEM,
                onSelect = { onThemeChange(ThemeMode.SYSTEM) },
            )
            ThemeOption(
                label = stringResource(R.string.theme_light),
                selected = state.settings.themeMode == ThemeMode.LIGHT,
                onSelect = { onThemeChange(ThemeMode.LIGHT) },
            )
            ThemeOption(
                label = stringResource(R.string.theme_dark),
                selected = state.settings.themeMode == ThemeMode.DARK,
                onSelect = { onThemeChange(ThemeMode.DARK) },
            )

            Text(
                text = stringResource(R.string.settings_palette),
                style = MaterialTheme.typography.titleSmall,
            )
            Text(
                text = stringResource(R.string.settings_palette_desc),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            val darkTheme = LocalDarkTheme.current
            ColorPalette.entries.forEach { palette ->
                PaletteOption(
                    label = stringResource(paletteLabelRes(palette)),
                    swatch = palettePrimaryColor(palette, darkTheme),
                    selected = state.settings.palette == palette,
                    onSelect = { onPaletteChange(palette) },
                )
            }

            SwitchRow(
                title = stringResource(R.string.settings_dynamic_color),
                subtitle = stringResource(R.string.settings_dynamic_color_desc),
                checked = state.settings.dynamicColor,
                onCheckedChange = onDynamicColorChange,
            )

            HorizontalDivider()

            SectionLabel(stringResource(R.string.settings_reading))

            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(
                        text = stringResource(R.string.settings_font_scale),
                        style = MaterialTheme.typography.titleSmall,
                    )
                    Text(
                        text = "${(state.settings.fontScale * 100).toInt()}%",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }
                Slider(
                    value = state.settings.fontScale,
                    onValueChange = onFontScaleChange,
                    valueRange = 0.85f..1.5f,
                    steps = 12,
                )
            }

            SwitchRow(
                title = stringResource(R.string.settings_serif),
                subtitle = stringResource(R.string.settings_serif_desc),
                checked = state.settings.serif,
                onCheckedChange = onSerifChange,
            )

            HorizontalDivider()

            SectionLabel(stringResource(R.string.settings_content))

            InfoRow(stringResource(R.string.settings_kb_version), state.kbVersion)
            InfoRow(stringResource(R.string.settings_entries_count), state.entryCount.toString())

            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Button(
                    onClick = onReindex,
                    enabled = !state.isReindexing,
                ) {
                    Text(stringResource(R.string.settings_reindex))
                }
                Text(
                    text = stringResource(R.string.settings_reindex_desc),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            HorizontalDivider()

            SectionLabel(stringResource(R.string.settings_updates))

            when (val update = state.updateState) {
                UpdateState.Idle -> {
                    ActionRow(
                        icon = Icons.Outlined.SystemUpdate,
                        title = stringResource(R.string.settings_check_updates),
                        subtitle = stringResource(R.string.settings_check_updates_desc),
                        onClick = onCheckForUpdate,
                    )
                    Text(
                        text = stringResource(R.string.settings_update_source),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                UpdateState.Checking -> {
                    InfoRow(
                        stringResource(R.string.settings_check_updates),
                        stringResource(R.string.settings_update_checking),
                    )
                }

                is UpdateState.UpToDate -> {
                    InfoRow(
                        stringResource(R.string.settings_check_updates),
                        stringResource(R.string.settings_update_up_to_date),
                    )
                    Text(
                        text = stringResource(
                            R.string.settings_update_up_to_date_desc,
                            update.latestTag,
                        ),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                is UpdateState.Available -> {
                    InfoRow(
                        stringResource(R.string.settings_update_available),
                        update.release.tag,
                    )
                    Text(
                        text = stringResource(
                            R.string.settings_update_available_desc,
                            update.release.tag,
                        ),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Button(onClick = { onDownloadUpdate(update.release) }) {
                        Text(stringResource(R.string.settings_update_download))
                    }
                    Text(
                        text = stringResource(R.string.settings_update_download_desc),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                is UpdateState.Downloading -> {
                    InfoRow(
                        stringResource(R.string.settings_check_updates),
                        stringResource(R.string.settings_update_downloading, update.percent),
                    )
                    Text(
                        text = stringResource(R.string.settings_update_downloading_desc),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    ActionRow(
                        icon = Icons.Outlined.Close,
                        title = stringResource(R.string.settings_update_cancel),
                        subtitle = "",
                        onClick = onCancelUpdate,
                    )
                }

                is UpdateState.ReadyToInstall -> {
                    InfoRow(
                        stringResource(R.string.settings_update_ready),
                        update.releaseTag,
                    )
                    Text(
                        text = stringResource(
                            R.string.settings_update_ready_desc,
                            update.releaseTag,
                        ),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Button(
                        onClick = {
                            if (!installPackage(update.apk)) {
                                requestInstallPermission()
                            }
                        },
                    ) {
                        Text(stringResource(R.string.settings_update_install))
                    }
                    Text(
                        text = stringResource(R.string.settings_update_install_desc),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                is UpdateState.Failed -> {
                    InfoRow(
                        stringResource(R.string.settings_update_failed),
                        update.reason,
                    )
                    ActionRow(
                        icon = Icons.Outlined.SystemUpdate,
                        title = stringResource(R.string.settings_check_updates),
                        subtitle = "",
                        onClick = onCheckForUpdate,
                    )
                }
            }

            HorizontalDivider()

            SectionLabel(stringResource(R.string.settings_about))
            InfoRow(stringResource(R.string.settings_version), appVersion)
            ActionRow(
                icon = Icons.Outlined.Share,
                title = stringResource(R.string.settings_share_apk),
                subtitle = stringResource(R.string.settings_share_apk_desc),
                onClick = {
                    if (!shareAppApk(context)) {
                        scope.launch { snackbarHostState.showSnackbar(shareFailedMessage) }
                    }
                },
            )
            ActionRow(
                icon = Icons.Outlined.Download,
                title = stringResource(R.string.settings_export_apk),
                subtitle = stringResource(R.string.settings_export_apk_desc),
                onClick = requestExportApk,
            )
            InfoRow(stringResource(R.string.settings_license), "CC BY-SA 4.0")
            Text(
                text = stringResource(R.string.license_summary),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Spacer(Modifier.width(1.dp))
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = FontWeight.SemiBold,
    )
}

@Composable
private fun ThemeOption(label: String, selected: Boolean, onSelect: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = selected, role = Role.RadioButton, onClick = onSelect),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        RadioButton(selected = selected, onClick = null)
        Text(text = label, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
private fun PaletteOption(
    label: String,
    swatch: Color,
    selected: Boolean,
    onSelect: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = selected, role = Role.RadioButton, onClick = onSelect),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(22.dp)
                .background(color = swatch, shape = CircleShape),
        )
        Spacer(Modifier.width(12.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f),
        )
        RadioButton(selected = selected, onClick = null)
    }
}

private fun paletteLabelRes(palette: ColorPalette): Int = when (palette) {
    ColorPalette.FOREST -> R.string.palette_forest
    ColorPalette.OCEAN -> R.string.palette_ocean
    ColorPalette.SUNSET -> R.string.palette_sunset
    ColorPalette.LILAC -> R.string.palette_lilac
    ColorPalette.GRAPHITE -> R.string.palette_graphite
}

@Composable
private fun SwitchRow(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onCheckedChange(!checked) },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, style = MaterialTheme.typography.titleSmall)
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@Composable
private fun ActionRow(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, style = MaterialTheme.typography.titleSmall)
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(text = label, style = MaterialTheme.typography.bodyLarge)
        Text(
            text = value,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
