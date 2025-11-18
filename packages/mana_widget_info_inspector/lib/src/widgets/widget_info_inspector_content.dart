import 'package:flutter/material.dart';

class WidgetInfoInspectorContent extends StatelessWidget {
  final InspectorSelection selection;
  final ValueChanged<bool>? onChanged;
  const WidgetInfoInspectorContent({super.key, required this.selection, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Switch drawing mode', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          Switch(value: true, onChanged: onChanged),
        ]),
      ]),
    );
  }
}