import 'package:flutter/material.dart';
import '../../models/network.dart';
import '../../services/network_service.dart';
import '../../widgets/network_config_form.dart';

/// Create or edit a single network (name + configuration).
class AdminNetworkFormScreen extends StatefulWidget {
  final Network? network;

  const AdminNetworkFormScreen({super.key, this.network});

  @override
  State<AdminNetworkFormScreen> createState() => _AdminNetworkFormScreenState();
}

class _AdminNetworkFormScreenState extends State<AdminNetworkFormScreen> {
  final _service = NetworkService();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.network != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.network?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(NetworkConfiguration cfg) async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final req = SaveNetworkRequest(name: _nameCtrl.text.trim(), configuration: cfg);
      if (_isEdit) {
        await _service.updateNetwork(widget.network!.id, req);
      } else {
        await _service.createNetwork(req);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Save failed.')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit network' : 'New network'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Network name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text('Configuration',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              NetworkConfigForm(
                initial: widget.network?.config ??
                    const NetworkConfiguration(timezone: 'UTC'),
                onSave: _saving ? (_) {} : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
