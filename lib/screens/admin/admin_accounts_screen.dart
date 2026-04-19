import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../widgets/async_list_view.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/shell_menu_leading.dart';
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
      accounts.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load accounts.\n${errorMessage(e)}';
          _loading = false;
        });
      }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${errorMessage(e)}')),
        );
      }
    }
  }

  String _typeName(int id) => switch (id) {
    kAccountTypeAdmin => 'Admin',
    kAccountTypeUser => 'User',
    kAccountTypeDevice => 'Device',
    kAccountTypeViewer => 'Viewer',
    _ => 'Unknown',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: const [ShellMenuAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('New account'),
      ),
      body: AsyncListView<Account>(
        items: _accounts,
        isLoading: _loading,
        error: _error,
        onRefresh: _load,
        emptyMessage: 'No accounts',
        itemBuilder: (ctx, a) => ListTile(
          leading: CircleAvatar(child: Text(a.username[0].toUpperCase())),
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
                color: Theme.of(ctx).colorScheme.error,
                onPressed: () => _delete(a),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
