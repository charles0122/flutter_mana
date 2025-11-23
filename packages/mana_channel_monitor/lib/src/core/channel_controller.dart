import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:mana_channel_monitor/src/core/channel_info_model.dart';
import 'package:mana_channel_monitor/src/core/channel_store.dart';

/// 负责从平台消息中解码并生成记录
class ChannelTracker {
  final StandardMethodCodec codec = const StandardMethodCodec();

  void trackChannelEvent(
    String channel,
    DateTime sendTime,
    bool send, {
    ByteData? data,
    MessageHandler? handler,
    ui.PlatformMessageResponseCallback? callback,
  }) {
    MethodCall call = const MethodCall('unknown');
    try {
      call = codec.decodeMethodCall(data);
    } catch (e) {
      debugPrint('decode data failed, caused by: $e');
      debugPrint('data: ${data.toString()}');
    }
    final ChannelRecord model = ChannelRecord(
      type: ChannelType.method,
      channelName: channel,
      direction:
          send
              ? ChannelDirection.flutterToNative
              : ChannelDirection.nativeToFlutter,
      methodName: call.method,
      timestamp: sendTime,
      duration: DateTime.now().difference(sendTime),
      sendDataSize: send ? (data?.elementSizeInBytes ?? 0) : 0,
      sendData: send ? call.arguments : null,
      receiveData: send ? null : call.arguments,
      receiveDataSize: send ? 0 : (data?.elementSizeInBytes ?? 0),
    );
    channelStore.saveChannelInfo(model);
  }
}

ChannelTracker channelTracker = ChannelTracker();
