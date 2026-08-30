import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/api_client.dart';
import 'legacy_app.dart' show MyApp;
import 'screens/comb_screen.dart';
import 'screens/connect_bank_screen.dart';
import 'screens/detail_sheet.dart';
import 'screens/hive_screen.dart';
import 'screens/market_screen.dart';
import 'screens/mates_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spending_screen.dart';
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

      // The two screens that actually talk to the backend. The five tabs above
      // render from static data; these read real transactions, so without them
      // the app cannot do the thing it claims. Reached from Settings.
      GoRoute(
        path: '/connect-bank',
        builder: (BuildContext context, GoRouterState state) =>
            ConnectBankScreen(api: _api),
      ),
      GoRoute(
        path: '/spending',
        builder: (BuildContext context, GoRouterState state) =>
            SpendingScreen(api: _api),
      ),

      // The whole Forest app, one tap from Settings.
      //
      // Merging two UIs properly is days of work; this is the honest shortcut.
      // MyApp brings its own MaterialApp and Navigator, which nests fine here
      // and keeps every Forest feature reachable — questionnaire, the
      // plan-rebuild dialog, tree, streaks, calendar, shop, circle — while
      // Hivewise stays the shell we open on.
      GoRoute(
        path: '/forest',
        builder: (BuildContext context, GoRouterState state) =>
            const _ForestHost(),
      ),
    ],
  );
}

/// One client for the whole app. Cheap to construct, but a single instance
/// keeps the base-URL override in one place.
final ApiClient _api = ApiClient();

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


/// Hosts the Forest app with a way back.
///
/// MyApp brings its own MaterialApp and Navigator, so nothing inside it can
/// pop this route — an inner Navigator only knows its own stack. The bar sits
/// OUTSIDE that subtree, so its context is the shell's and `pop()` returns to
/// Hivewise. Cheaper and safer than threading a callback through a whole app.
class _ForestHost extends StatelessWidget {
  const _ForestHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF33251A), // ink
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back,
                      size: 18, color: Color(0xFFF6EFE0)),
                  label: const Text(
                    'Back to Tallycomb',
                    style: TextStyle(
                      color: Color(0xFFF6EFE0),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const Expanded(child: MyApp()),
          ],
        ),
      ),
    );
  }
}
