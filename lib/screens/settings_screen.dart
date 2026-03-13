import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

/// Lets the user change the theme and log out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _themeOption(context, settings, ThemeMode.system, 'System default'),
        _themeOption(context, settings, ThemeMode.light, 'Light'),
        _themeOption(context, settings, ThemeMode.dark, 'Dark'),
        const Divider(height: 32),
        Text('Account', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (auth.currentUser != null)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(auth.currentUser!.username),
            subtitle: auth.currentUser!.fullName != null
                ? Text(auth.currentUser!.fullName!)
                : null,
          ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () async {
            // Pop everything then log out so the login screen is shown.
            Navigator.of(context).popUntil((r) => r.isFirst);
            await context.read<AuthProvider>().logout();
          },
        ),
      ],
    );
  }

  Widget _themeOption(
    BuildContext context,
    SettingsProvider settings,
    ThemeMode mode,
    String label,
  ) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: settings.themeMode,
      title: Text(label),
      onChanged: (v) => settings.setThemeMode(v!),
    );
  }
}
