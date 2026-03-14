import 'package:flutter/material.dart';
import '../models/network.dart';

/// A structured form for editing all fields inside [NetworkConfiguration].
/// Wraps state inside the widget (no external provider needed for form state).
class NetworkConfigForm extends StatefulWidget {
  /// Pre-populated from an existing network, or defaults when creating.
  final NetworkConfiguration initial;
  final void Function(NetworkConfiguration config) onSave;

  const NetworkConfigForm({
    super.key,
    required this.initial,
    required this.onSave,
  });

  @override
  State<NetworkConfigForm> createState() => _NetworkConfigFormState();
}

class _NetworkConfigFormState extends State<NetworkConfigForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reportingInterval;
  late final TextEditingController _alertingDelay;
  late final TextEditingController _email;
  late final TextEditingController _reminderTime;
  late final TextEditingController _reminderDays;
  late final TextEditingController _timezone;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _reportingInterval = TextEditingController(
      text: c.reportingInterval?.toString() ?? '',
    );
    _alertingDelay = TextEditingController(
      text: c.alertingDelay?.toString() ?? '',
    );
    _email = TextEditingController(text: c.notificationEmailAddress ?? '');
    _reminderTime = TextEditingController(text: c.reminderTimeOfDay ?? '');
    _reminderDays = TextEditingController(
      text: c.reminderIntervalDays?.toString() ?? '',
    );
    _timezone = TextEditingController(text: c.timezone);
  }

  @override
  void dispose() {
    for (final c in [
      _reportingInterval,
      _alertingDelay,
      _email,
      _reminderTime,
      _reminderDays,
      _timezone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      NetworkConfiguration(
        reportingInterval: int.tryParse(_reportingInterval.text),
        alertingDelay: int.tryParse(_alertingDelay.text),
        notificationEmailAddress: _email.text.isNotEmpty ? _email.text : null,
        reminderTimeOfDay: _reminderTime.text.isNotEmpty
            ? _reminderTime.text
            : null,
        reminderIntervalDays: int.tryParse(_reminderDays.text),
        timezone: _timezone.text.isEmpty ? 'UTC' : _timezone.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _intField(
            _reportingInterval,
            'Reporting interval (seconds)',
            required: true,
          ),
          const SizedBox(height: 12),
          _intField(_alertingDelay, 'Alerting delay (seconds)', required: true),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Notification email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reminderTime,
            decoration: const InputDecoration(
              labelText: 'Reminder time (HH:mm)',
              border: OutlineInputBorder(),
              hintText: '08:00',
            ),
          ),
          const SizedBox(height: 12),
          _intField(_reminderDays, 'Reminder interval (days)'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _timezone,
            decoration: const InputDecoration(
              labelText: 'Timezone (IANA)',
              border: OutlineInputBorder(),
              hintText: 'Europe/Ljubljana',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _intField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Required';
        if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
          return 'Must be a whole number';
        }
        return null;
      },
    );
  }
}
