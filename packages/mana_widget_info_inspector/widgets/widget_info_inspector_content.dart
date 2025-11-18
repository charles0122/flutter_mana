import 'package:flutter/material.dart';
import '../../mana/lib/flutter_mana.dart';

import 'widget_info_inspector_detail.dart';

class WidgetInfoInspectorContent extends StatefulWidget {
  final InspectorSelection selection;

  final ValueChanged<bool>? onChanged;

  const WidgetInfoInspectorContent({
    super.key,
    required this.selection,
    this.onChanged,
  });

  @override
  State<WidgetInfoInspectorContent> createState() =>
      _WidgetInfoInspectorContentState();
}

class _WidgetInfoInspectorContentState extends State<WidgetInfoInspectorContent>
    with I18nMixin {
  bool _debugPaintSizeEnabled = false;

  void _onChange(bool value) {
    _debugPaintSizeEnabled = value;
    widget.onChanged?.call(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 8,
            children: [
              Switch(value: _debugPaintSizeEnabled, onChanged: _onChange),
              Text(
                t('widget_info_inspector.tip'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed:
                    widget.selection.currentElement == null
                        ? null
                        : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) {
                                return InfoPage(
                                  elements:
                                      widget.selection.currentElement!
                                          .debugGetDiagnosticChain(),
                                );
                              },
                            ),
                          );
                        },
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(KitIcons.eye),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
