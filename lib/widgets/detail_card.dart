import 'package:flutter/material.dart';

/// A zero-margin [Card] with standard vertical/horizontal padding, used on
/// detail screens to group a set of [DetailRow] widgets.
class DetailCard extends StatelessWidget {
  final List<Widget> children;

  const DetailCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// A labelled row used inside [DetailCard].
///
/// Supply either [value] (a plain string) or [child] (an arbitrary widget).
/// [labelWidth] controls the fixed width of the label column (default 100).
/// [softWrap] only applies when [value] is used.
class DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;
  final double labelWidth;
  final bool softWrap;

  const DetailRow({
    super.key,
    required this.label,
    this.value,
    this.child,
    this.labelWidth = 100,
    this.softWrap = false,
  }) : assert(
         value != null || child != null,
         'Supply either value or child to DetailRow',
       );

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: labelStyle),
          ),
          Expanded(
            child:
                child ??
                Text(
                  value!,
                  softWrap: softWrap,
                  overflow: softWrap
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
          ),
        ],
      ),
    );
  }
}
