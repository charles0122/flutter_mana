import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'touch_indicator_barrier.dart';

class TouchIndicator extends StatelessWidget with I18nMixin {
  final String name;

  const TouchIndicator({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(name: name, barrier: TouchIndicatorBarrier());
  }
}
