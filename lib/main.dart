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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Named routes for simple imperative navigation.
      routes: {
        '/': (_) => const AppShell(),
        '/network': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return NetworkDetailScreen(networkId: id);
        },
        '/device': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return DeviceDetailScreen(deviceId: id);
        },
        '/admin/accounts': (_) => const AdminAccountsScreen(),
        '/admin/networks': (_) => const AdminNetworksScreen(),
      },
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

  Widget _body(bool isAdmin, int index) {
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final items = _navItems(isAdmin);
    // Clamp in case items count shifts after login state change.
    final safeIndex = _selectedIndex.clamp(0, items.length - 1);
    final isWide = MediaQuery.of(context).size.width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
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
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey('$isAdmin/$safeIndex'),
                  child: _body(isAdmin, safeIndex),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Narrow layout uses a Drawer.
    return Scaffold(
      appBar: AppBar(title: const Text('netmon2')),
      drawer: NavigationDrawer(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) {
          Navigator.of(context).pop(); // close drawer
          setState(() => _selectedIndex = i);
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey('$isAdmin/$safeIndex'),
          child: _body(isAdmin, safeIndex),
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
