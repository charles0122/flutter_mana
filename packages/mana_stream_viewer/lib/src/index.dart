import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'icon.dart';
import 'widgets/stream_viewer.dart';

class ManaStreamViewer extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => StreamViewer(name: name);

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_stream_viewer';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return 'Stream调试器';
    }
    return 'Stream Viewer';
  }
}
