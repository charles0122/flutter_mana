import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'screen_info_content.dart';

class ScreenInfo extends StatelessWidget with I18nMixin {
  final String name;

  const ScreenInfo({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      showBarrier: false,
      content: ScreenInfoContent(),
    );
  }
}
