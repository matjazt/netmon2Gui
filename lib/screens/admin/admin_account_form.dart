import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../utils/constants.dart';

/// Create or edit a single account.
class AdminAccountFormScreen extends StatefulWidget {
  /// Null when creating a new account.
  final Account? account;

  const AdminAccountFormScreen({super.key, this.account});

  @override
  State<AdminAccountFormScreen> createState() => _AdminAccountFormScreenState();
}

class _AdminAccountFormScreenState extends State<AdminAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AccountService();

  late TextEditingController _username;
  late TextEditingController _password;
  late TextEditingController _fullName;
  late TextEditingController _email;
  int _accountTypeId = kAccountTypeUser;
  bool _saving = false;
  bool _obscure = true;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _username = TextEditingController(text: a?.username ?? '');
    _password = TextEditingController();
    _fullName = TextEditingController(text: a?.fullName ?? '');
    _email = TextEditingController(text: a?.email ?? '');
    _accountTypeId = a?.accountTypeId ?? kAccountTypeUser;
  }

  @override
  void dispose() {
    for (final c in [_username, _password, _fullName, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final req = SaveAccountRequest(
        username: _username.text.trim(),
        accountTypeId: _accountTypeId,
        password: _password.text.isNotEmpty ? _password.text : null,
        fullName: _fullName.text.trim().isNotEmpty
            ? _fullName.text.trim()
            : null,
        email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
      );
      if (_isEdit) {
        await _service.updateAccount(widget.account!.id, req);
      } else {
        await _service.createAccount(req);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save failed.')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit account' : 'New account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: _isEdit
                        ? 'New password (leave blank to keep)'
                        : 'Password *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) {
                    if (!_isEdit && (v == null || v.isEmpty)) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _accountTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: kAccountTypeAdmin,
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: kAccountTypeUser,
                      child: Text('User'),
                    ),
                    DropdownMenuItem(
                      value: kAccountTypeDevice,
                      child: Text('Device'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _accountTypeId = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
