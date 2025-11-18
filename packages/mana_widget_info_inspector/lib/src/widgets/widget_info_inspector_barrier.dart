import 'package:flutter/material.dart';

class WidgetInfoInspectorBarrier extends StatefulWidget {
  final InspectorSelection selection;
  final void Function(TapDownDetails details)? onTapDown;

  const WidgetInfoInspectorBarrier({super.key, required this.selection, this.onTapDown});

  @override
  State<WidgetInfoInspectorBarrier> createState() => _WidgetInfoInspectorBarrierState();
}

class _WidgetInfoInspectorBarrierState extends State<WidgetInfoInspectorBarrier> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTapDown,
      behavior: HitTestBehavior.translucent,
      child: Container(color: Colors.transparent),
    );
  }
}