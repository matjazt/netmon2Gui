import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/shell_menu_leading.dart';

/// Lets the user change the theme and log out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [ShellMenuAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
            child: Text('Appearance', style: labelStyle),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (v) {
                if (v != null) settings.setThemeMode(v);
              },
              child: Column(
                children: [
                  _themeOption(ThemeMode.system, 'System default'),
                  _themeOption(ThemeMode.light, 'Light'),
                  _themeOption(ThemeMode.dark, 'Dark'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
            child: Text('Account', style: labelStyle),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                if (auth.currentUser != null) ...[
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(auth.currentUser!.username),
                    subtitle: auth.currentUser!.fullName != null
                        ? Text(auth.currentUser!.fullName!)
                        : null,
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: Icon(Icons.logout, color: cs.error),
                  title: Text('Sign out', style: TextStyle(color: cs.error)),
                  onTap: () async {
                    // Pop everything then log out so the login screen is shown.
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    await context.read<AuthProvider>().logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(ThemeMode mode, String label) {
    return RadioListTile<ThemeMode>(value: mode, title: Text(label));
  }
}
