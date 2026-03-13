import 'package:flutter/material.dart';
import '../../models/network.dart';
import '../../services/network_service.dart';
import '../../widgets/error_display.dart';
import '../../widgets/confirm_dialog.dart';
import 'admin_network_form.dart';

/// Admin screen listing all networks with create / edit / delete actions.
class AdminNetworksScreen extends StatefulWidget {
  const AdminNetworksScreen({super.key});

  @override
  State<AdminNetworksScreen> createState() => _AdminNetworksScreenState();
}

class _AdminNetworksScreenState extends State<AdminNetworksScreen> {
  final _service = NetworkService();
  List<Network> _networks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final networks = await _service.getAllNetworks();
      if (mounted) setState(() { _networks = networks; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load networks.'; _loading = false; });
    }
  }

  Future<void> _openForm([Network? network]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminNetworkFormScreen(network: network),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Network network) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete network',
      message: 'Delete "${network.name}"? All associated data will be lost.',
    );
    if (!confirmed) return;
    try {
      await _service.deleteNetwork(network.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Delete failed.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Networks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New network'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _load)
              : ListView.separated(
                  itemCount: _networks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final n = _networks[i];
                    return ListTile(
                      leading: Icon(
                        n.hasActiveAlert ? Icons.warning_amber_rounded : Icons.lan,
                        color: n.hasActiveAlert ? Colors.orange : null,
                      ),
                      title: Text(n.name),
                      subtitle: Text(n.config.timezone),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openForm(n),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () => _delete(n),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context)
                          .pushNamed('/network', arguments: n.id),
                    );
                  },
                ),
    );
  }
}
