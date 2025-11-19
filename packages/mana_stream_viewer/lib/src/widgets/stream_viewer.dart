import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

class StreamViewer extends StatelessWidget with I18nMixin {
  final String name;

  const StreamViewer({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(name: name, content: Text('StreamViewer'));
  }
}
