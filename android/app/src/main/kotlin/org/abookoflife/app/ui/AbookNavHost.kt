package org.abookoflife.app.ui

import android.net.Uri
import androidx.annotation.StringRes
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavHostController
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import org.abookoflife.core.designsystem.R
import org.abookoflife.feature.bookmarks.BookmarksRoute
import org.abookoflife.feature.home.DomainRoute
import org.abookoflife.feature.home.HomeRoute
import org.abookoflife.feature.reader.ReaderRoute
import org.abookoflife.feature.search.SearchRoute
import org.abookoflife.feature.settings.SettingsRoute

object Routes {
    const val HOME = "home"
    const val SEARCH = "search"
    const val SAVED = "saved"
    const val SETTINGS = "settings"
    const val DOMAIN = "domain/{slug}"
    const val READER = "reader/{entryId}"

    fun domain(slug: String): String = "domain/${Uri.encode(slug)}"
    fun reader(entryId: String): String = "reader/${Uri.encode(entryId)}"
}

private data class TopLevelDestination(
    val route: String,
    @StringRes val labelRes: Int,
    val icon: ImageVector,
)

@Composable
fun AbookNavHost(modifier: Modifier = Modifier) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    val destinations = listOf(
        TopLevelDestination(Routes.HOME, R.string.nav_home, Icons.AutoMirrored.Outlined.MenuBook),
        TopLevelDestination(Routes.SEARCH, R.string.nav_search, Icons.Outlined.Search),
        TopLevelDestination(Routes.SAVED, R.string.nav_bookmarks, Icons.Outlined.BookmarkBorder),
        TopLevelDestination(Routes.SETTINGS, R.string.nav_settings, Icons.Outlined.Settings),
    )
    val showBottomBar = destinations.any { it.route == currentRoute }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    destinations.forEach { destination ->
                        NavigationBarItem(
                            selected = currentRoute == destination.route,
                            onClick = { navController.switchTab(destination.route) },
                            icon = {
                                Icon(
                                    imageVector = destination.icon,
                                    contentDescription = null,
                                )
                            },
                            label = { Text(stringResource(destination.labelRes)) },
                        )
                    }
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = Routes.HOME,
            modifier = Modifier.padding(padding),
        ) {
            composable(Routes.HOME) {
                HomeRoute(
                    onSearchClick = { navController.switchTab(Routes.SEARCH) },
                    onEntryClick = { navController.navigate(Routes.reader(it)) },
                    onDomainClick = { navController.navigate(Routes.domain(it)) },
                )
            }

            composable(Routes.SEARCH) {
                SearchRoute(
                    onEntryClick = { navController.navigate(Routes.reader(it)) },
                    onBack = null,
                )
            }

            composable(Routes.SAVED) {
                BookmarksRoute(
                    onEntryClick = { navController.navigate(Routes.reader(it)) },
                )
            }

            composable(Routes.SETTINGS) {
                SettingsRoute()
            }

            composable(
                route = Routes.DOMAIN,
                arguments = listOf(navArgument("slug") { type = NavType.StringType }),
            ) {
                DomainRoute(
                    onBack = { navController.popBackStack() },
                    onEntryClick = { navController.navigate(Routes.reader(it)) },
                )
            }

            composable(
                route = Routes.READER,
                arguments = listOf(navArgument("entryId") { type = NavType.StringType }),
            ) {
                ReaderRoute(
                    onBack = { navController.popBackStack() },
                    onEntryClick = { entryId -> navController.navigate(Routes.reader(entryId)) },
                )
            }
        }
    }
}

private fun NavHostController.switchTab(route: String) {
    navigate(route) {
        popUpTo(graph.findStartDestination().id) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }
}
