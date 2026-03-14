import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../widgets/error_display.dart';
import '../../widgets/confirm_dialog.dart';
import '../../utils/constants.dart';
import 'admin_account_form.dart';

/// Admin screen listing all accounts with create / edit / delete actions.
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _service = AccountService();
  List<Account> _accounts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await _service.getAllAccounts();
      if (mounted)
        setState(() {
          _accounts = accounts;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Failed to load accounts.';
          _loading = false;
        });
    }
  }

  Future<void> _openForm([Account? account]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAccountFormScreen(account: account),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Account account) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete account',
      message: 'Delete "${account.username}"? This cannot be undone.',
    );
    if (!confirmed) return;
    try {
      await _service.deleteAccount(account.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Delete failed.')));
      }
    }
  }

  String _typeName(int id) => switch (id) {
    kAccountTypeAdmin => 'Admin',
    kAccountTypeUser => 'User',
    kAccountTypeDevice => 'Device',
    _ => 'Unknown',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('New account'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorDisplay(message: _error!, onRetry: _load)
          : ListView.separated(
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final a = _accounts[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(a.username[0].toUpperCase()),
                  ),
                  title: Text(a.username),
                  subtitle: Text(
                    [
                      _typeName(a.accountTypeId),
                      if (a.fullName != null) a.fullName!,
                      if (a.email != null) a.email!,
                    ].join('  ·  '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openForm(a),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _delete(a),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
