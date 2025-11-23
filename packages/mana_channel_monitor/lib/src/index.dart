import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_channel_monitor/src/ui/channel_pages.dart';

import 'icon.dart';

class ManaChannelMonitor extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => ChannelMonitorPages(name: name);

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_channel_monitor';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '通道监控器';
    }
    return 'Channel Monitor';
  }
}
