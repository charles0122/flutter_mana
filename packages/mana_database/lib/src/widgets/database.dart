import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

class Database extends StatelessWidget with I18nMixin {
  final String name;

  const Database({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(name: name, content: Text('Database'));
  }
}
