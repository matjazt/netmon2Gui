import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'providers/auth_provider.dart';
import 'providers/network_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/admin/admin_accounts_screen.dart';
import 'screens/admin/admin_networks_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_detail_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/network_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/theme.dart';
import 'widgets/shell_menu_leading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted settings before the first frame.
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
      ],
      child: const NetmonApp(),
    ),
  );
}

class NetmonApp extends StatelessWidget {
  const NetmonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsProvider>().themeMode;

    return MaterialApp(
      title: 'netmon2',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Detail screens are handled by the inner Navigator inside
      // MainScaffold so the nav rail / drawer stays visible at all times.
      routes: {'/': (_) => const AppShell()},
    );
  }
}

/// Root shell that shows the login screen until the user is authenticated,
/// then shows the main navigation scaffold.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sessionChecked = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final auth = context.read<AuthProvider>();
    await auth.tryRestoreSession();
    if (auth.isLoggedIn) {
      await _loadNetworks();
    }
    if (mounted) setState(() => _sessionChecked = true);
  }

  Future<void> _loadNetworks() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.currentUser == null) return;
    await context.read<NetworkProvider>().loadNetworks(
      isAdmin: auth.isAdmin,
      accountId: auth.currentUser!.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return LoginScreen(onLoginSuccess: _loadNetworks);
    }
    return const MainScaffold();
  }
}

/// Wraps the main content with adaptive NavigationRail (wide) or Drawer (narrow).
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isAdmin = false;

  List<_NavItem> _navItems(bool isAdmin) => [
    const _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    const _NavItem(Icons.list_alt_outlined, Icons.list_alt, 'Logs'),
    const _NavItem(Icons.history_outlined, Icons.history, 'History'),
    if (isAdmin) ...[
      const _NavItem(
        Icons.manage_accounts_outlined,
        Icons.manage_accounts,
        'Accounts',
      ),
      const _NavItem(Icons.lan_outlined, Icons.lan, 'Networks'),
    ],
    const _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  Widget _tabBody(bool isAdmin, int index) {
    final items = _navItems(isAdmin);
    final label = items[index].label;
    return switch (label) {
      'Dashboard' => const DashboardScreen(),
      'Logs' => const LogsScreen(),
      'History' => const HistoryScreen(),
      'Accounts' => const AdminAccountsScreen(),
      'Networks' => const AdminNetworksScreen(),
      'Settings' => const SettingsScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  void _onDestinationSelected(int i) {
    setState(() => _selectedIndex = i);
    // Reset the inner navigator stack to the new tab's home screen.
    _navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
  }

  Route? _generateRoute(RouteSettings settings) {
    final safeIndex = _selectedIndex.clamp(0, _navItems(_isAdmin).length - 1);
    switch (settings.name) {
      case '/':
        // No transition animation for tab switches.
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => _tabBody(_isAdmin, safeIndex),
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      case '/network':
        return MaterialPageRoute(
          builder: (_) =>
              NetworkDetailScreen(networkId: settings.arguments as int),
          settings: settings,
        );
      case '/device':
        return MaterialPageRoute(
          builder: (_) =>
              DeviceDetailScreen(deviceId: settings.arguments as int),
          settings: settings,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    _isAdmin = isAdmin;
    final items = _navItems(isAdmin);
    final safeIndex = _selectedIndex.clamp(0, items.length - 1);
    final isWide = MediaQuery.of(context).size.width >= 600;

    final innerNav = Navigator(
      key: _navigatorKey,
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: safeIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: innerNav),
          ],
        ),
      );
    }

    // Narrow layout: drawer-based navigation.
    // PopScope intercepts the system back button to pop the inner navigator.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && (_navigatorKey.currentState?.canPop() ?? false)) {
          _navigatorKey.currentState?.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: NavigationDrawer(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) {
            Navigator.of(context).pop(); // close drawer
            _onDestinationSelected(i);
          },
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                'netmon2',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            for (final item in items)
              NavigationDrawerDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ),
          ],
        ),
        body: ShellScope(
          openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          child: innerNav,
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}
