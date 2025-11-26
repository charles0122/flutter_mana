import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_channel_monitor/src/ui/pages/channel_monitor_pages.dart';

import 'icon.dart';

/// Mana 插件入口，提供图标与挂载的 UI 组件
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
