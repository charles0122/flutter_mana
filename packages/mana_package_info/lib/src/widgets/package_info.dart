import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'package_info_content.dart';

class PackageInfo extends StatelessWidget {
  final String name;

  const PackageInfo({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: name,
      showBarrier: false,
      content: PackageInfoContent(),
    );
  }
}
