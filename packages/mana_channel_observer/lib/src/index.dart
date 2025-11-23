import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'icon.dart';
import 'widgets/channel_observer.dart';

class ManaChannelObserver extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) {
    ctx = context;
    return ChannelObserverOverlay();
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_channel_observer';

  OverlayEntry? entry;
  BuildContext? ctx;

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '通道观测器';
    }
    return 'Channel Observer';
  }

  @override
  void onTrigger() {
    if (entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        entry = OverlayEntry(builder: (_) => ChannelObserverOverlay());
        Overlay.of(ctx!).insert(entry!);
      });
    } else {
      entry?.remove();
      entry = null;
    }
  }
}
