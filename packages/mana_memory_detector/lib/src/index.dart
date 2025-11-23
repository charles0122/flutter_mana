import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_memory_detector/src/ume_kit_memory_detector.dart';

import 'icon.dart';

/// Mana 插件：内存泄漏检测器入口
/// 提供悬浮按钮入口与开关逻辑，切换监听并插入/移除 Overlay
class ManaMemoryDetector extends ManaPluggable {
  OverlayEntry? entry;

  bool isOpen = false;

  BuildContext? ctx;

  @override
  Widget? buildWidget(BuildContext? context) {
    ctx = context;
    return MemoryDetectorButton();
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_memory_detector';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '内存泄漏检测器';
    }
    return 'Memory Detector';
  }

  @override
  void onTrigger() {
    /// 切换检测器开关，并在 UI 层插入/移除按钮
    isOpen = !isOpen;
    UmeKitMemoryDetector().switchDetector(!isOpen);
    if (isOpen) {
      if (entry == null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          entry = OverlayEntry(builder: (_) => MemoryDetectorButton());
          Overlay.of(ctx!).insert(entry!);
        });
      }
    } else {
      entry?.remove();
      entry = null;
    }
  }
}
