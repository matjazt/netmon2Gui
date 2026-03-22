import 'package:flutter/material.dart';

import '../models/network.dart';

/// Common IANA timezone identifiers, used to drive the timezone autocomplete.
const _kTimezones = [
  'UTC',
  'Africa/Abidjan',
  'Africa/Accra',
  'Africa/Addis_Ababa',
  'Africa/Algiers',
  'Africa/Cairo',
  'Africa/Casablanca',
  'Africa/Johannesburg',
  'Africa/Lagos',
  'Africa/Nairobi',
  'Africa/Tripoli',
  'Africa/Tunis',
  'America/Anchorage',
  'America/Argentina/Buenos_Aires',
  'America/Bogota',
  'America/Caracas',
  'America/Chicago',
  'America/Denver',
  'America/Halifax',
  'America/Lima',
  'America/Los_Angeles',
  'America/Mexico_City',
  'America/New_York',
  'America/Phoenix',
  'America/Santiago',
  'America/Sao_Paulo',
  'America/St_Johns',
  'America/Toronto',
  'America/Vancouver',
  'America/Winnipeg',
  'Asia/Almaty',
  'Asia/Amman',
  'Asia/Baghdad',
  'Asia/Baku',
  'Asia/Bangkok',
  'Asia/Beirut',
  'Asia/Colombo',
  'Asia/Dhaka',
  'Asia/Dubai',
  'Asia/Hong_Kong',
  'Asia/Jakarta',
  'Asia/Jerusalem',
  'Asia/Kabul',
  'Asia/Karachi',
  'Asia/Kathmandu',
  'Asia/Kolkata',
  'Asia/Kuala_Lumpur',
  'Asia/Kuwait',
  'Asia/Makassar',
  'Asia/Manila',
  'Asia/Muscat',
  'Asia/Nicosia',
  'Asia/Novosibirsk',
  'Asia/Omsk',
  'Asia/Qatar',
  'Asia/Riyadh',
  'Asia/Seoul',
  'Asia/Shanghai',
  'Asia/Singapore',
  'Asia/Taipei',
  'Asia/Tashkent',
  'Asia/Tehran',
  'Asia/Tbilisi',
  'Asia/Tokyo',
  'Asia/Ulaanbaatar',
  'Asia/Vladivostok',
  'Asia/Yakutsk',
  'Asia/Yekaterinburg',
  'Asia/Yerevan',
  'Atlantic/Azores',
  'Atlantic/Cape_Verde',
  'Atlantic/Reykjavik',
  'Australia/Adelaide',
  'Australia/Brisbane',
  'Australia/Darwin',
  'Australia/Hobart',
  'Australia/Melbourne',
  'Australia/Perth',
  'Australia/Sydney',
  'Europe/Amsterdam',
  'Europe/Athens',
  'Europe/Belgrade',
  'Europe/Berlin',
  'Europe/Brussels',
  'Europe/Bucharest',
  'Europe/Budapest',
  'Europe/Copenhagen',
  'Europe/Dublin',
  'Europe/Helsinki',
  'Europe/Istanbul',
  'Europe/Kiev',
  'Europe/Lisbon',
  'Europe/Ljubljana',
  'Europe/London',
  'Europe/Luxembourg',
  'Europe/Madrid',
  'Europe/Minsk',
  'Europe/Moscow',
  'Europe/Oslo',
  'Europe/Paris',
  'Europe/Prague',
  'Europe/Riga',
  'Europe/Rome',
  'Europe/Samara',
  'Europe/Sarajevo',
  'Europe/Skopje',
  'Europe/Sofia',
  'Europe/Stockholm',
  'Europe/Tallinn',
  'Europe/Tirane',
  'Europe/Vienna',
  'Europe/Vilnius',
  'Europe/Warsaw',
  'Europe/Zagreb',
  'Europe/Zurich',
  'Indian/Maldives',
  'Indian/Mauritius',
  'Pacific/Auckland',
  'Pacific/Fiji',
  'Pacific/Guam',
  'Pacific/Honolulu',
  'Pacific/Midway',
  'Pacific/Noumea',
  'Pacific/Port_Moresby',
  'Pacific/Tongatapu',
];

/// A structured form for editing all fields inside [NetworkConfiguration].
/// Wraps state inside the widget (no external provider needed for form state).
class NetworkConfigForm extends StatefulWidget {
  /// Pre-populated from an existing network, or defaults when creating.
  final NetworkConfiguration initial;
  final void Function(NetworkConfiguration config) onSave;
  final VoidCallback? onCancel;

  const NetworkConfigForm({
    super.key,
    required this.initial,
    required this.onSave,
    this.onCancel,
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
  late String _selectedTimezone;
  String? _timezoneError;

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
    _selectedTimezone = c.timezone;
  }

  @override
  void dispose() {
    for (final c in [
      _reportingInterval,
      _alertingDelay,
      _email,
      _reminderTime,
      _reminderDays,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final tzOk = _selectedTimezone.isNotEmpty;
    if (!_formKey.currentState!.validate() | !tzOk) {
      if (!tzOk) setState(() => _timezoneError = 'Required');
      return;
    }
    widget.onSave(
      NetworkConfiguration(
        reportingInterval: int.tryParse(_reportingInterval.text),
        alertingDelay: int.tryParse(_alertingDelay.text),
        notificationEmailAddress: _email.text.isNotEmpty ? _email.text : null,
        reminderTimeOfDay: _reminderTime.text.isNotEmpty
            ? _reminderTime.text
            : null,
        reminderIntervalDays: int.tryParse(_reminderDays.text),
        timezone: _selectedTimezone,
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
            decoration: const InputDecoration(labelText: 'Notification email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reminderTime,
            decoration: const InputDecoration(
              labelText: 'Reminder time (HH:mm)',
              hintText: '08:00',
            ),
          ),
          const SizedBox(height: 12),
          _intField(_reminderDays, 'Reminder interval (days)'),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _selectedTimezone),
            optionsBuilder: (TextEditingValue tv) {
              if (tv.text.isEmpty) return _kTimezones;
              final q = tv.text.toLowerCase();
              return _kTimezones.where((tz) => tz.toLowerCase().contains(q));
            },
            onSelected: (tz) => setState(() {
              _selectedTimezone = tz;
              _timezoneError = null;
            }),
            fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
              ctrl.addListener(() {
                // Keep _selectedTimezone in sync with free text so a valid
                // manually-typed IANA id is not rejected.
                if (_selectedTimezone != ctrl.text) {
                  _selectedTimezone = ctrl.text.trim();
                  if (_timezoneError != null && _selectedTimezone.isNotEmpty) {
                    setState(() => _timezoneError = null);
                  }
                }
              });
              return TextFormField(
                controller: ctrl,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Timezone (IANA)',
                  hintText: 'Europe/Ljubljana',
                  errorText: _timezoneError,
                ),
                onFieldSubmitted: (_) => onSubmit(),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null) ...[
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(onPressed: _submit, child: const Text('Save')),
            ],
          ),
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
      decoration: InputDecoration(labelText: label),
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
