import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/comb_screen.dart';
import 'screens/detail_sheet.dart';
import 'screens/hive_screen.dart';
import 'screens/market_screen.dart';
import 'screens/mates_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'state/hive_state.dart';
import 'widgets/hive_tab_bar.dart';

/// Builds the app's router: an indexed-stack shell for the five tabs plus a
/// top-level `/settings` route reached from the home header gear button.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/hive',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return _Shell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/hive',
                builder: (BuildContext context, GoRouterState state) =>
                    const HiveScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/report',
                builder: (BuildContext context, GoRouterState state) =>
                    const ReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/market',
                builder: (BuildContext context, GoRouterState state) =>
                    const MarketScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/comb',
                builder: (BuildContext context, GoRouterState state) =>
                    const CombScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/mates',
                builder: (BuildContext context, GoRouterState state) =>
                    const MatesScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
    ],
  );
}

/// The router, available to `MaterialApp.router` via `ref.watch`.
final routerProvider = Provider<GoRouter>((ref) => buildRouter());

/// The shell around the five tabs, plus the shared detail sheet overlay.
///
/// Watches [hiveStateProvider]'s `sheet` so the scrim + sheet rebuild on
/// open/close. The sheet covers the whole screen (including the tab bar) via a
/// full-screen [Stack] over the [Scaffold].
class _Shell extends ConsumerWidget {
  const _Shell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SheetKind? sheet =
        ref.watch(hiveStateProvider.select((HiveState s) => s.sheet));

    return Stack(
      children: <Widget>[
        Scaffold(
          body: navigationShell,
          bottomNavigationBar: HiveTabBar(
            selectedIndex: navigationShell.currentIndex,
            onSelected: (int i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
          ),
        ),
        if (sheet != null) ...<Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(hiveStateProvider.notifier).closeSheet(),
              child: const ColoredBox(color: Color(0x6633251A)), // ink @ 40%.
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DetailSheet(kind: sheet),
          ),
        ],
      ],
    );
  }
}
