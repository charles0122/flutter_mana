import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'device_info_content.dart';

class DeviceInfo extends StatelessWidget {
  final String name;

  const DeviceInfo({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      showBarrier: false,
      content: DeviceInfoContent(),
    );
  }
}
