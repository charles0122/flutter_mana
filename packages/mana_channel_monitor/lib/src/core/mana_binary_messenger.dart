import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mana_channel_monitor/src/core/channel_controller.dart';
import 'package:mana_channel_monitor/src/core/channel_store.dart';

/// 在默认 BinaryMessenger 的基础上增加通道数据监控
class ChannelMonitorBinaryMessenger extends BinaryMessenger {
  static ChannelMonitorBinaryMessenger binaryMessenger =
      ChannelMonitorBinaryMessenger._();

  ChannelMonitorBinaryMessenger._();

  /// 转发平台消息（不记录响应以避免重复）
  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) async {
    ui.channelBuffers.push(channel, data, (ByteData? data) {
      if (callback != null) {
        callback(data);
      }
      // 可选：响应载荷通常为 null，不必重复记录
      // print(
      //     '\n handlePlatformMessage: channel: $channel \n  data:${data.toString()} \n');
    });
  }

  /// 发送平台消息并在收到回复后生成一次记录
  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    final DateTime start = DateTime.now();
    final Completer<ByteData?> completer = Completer<ByteData?>();
    // ui.PlatformDispatcher.instance is accessed directly instead of using
    // ServicesBinding.instance.platformDispatcher because this method might be
    // invoked before any binding is initialized. This issue was reported in
    // #27541. It is not ideal to statically access
    // ui.PlatformDispatcher.instance because the PlatformDispatcher may be
    // dependency injected elsewhere with a different instance. However, static
    // access at this location seems to be the least bad option.
    // TODO(ianh): Use ServicesBinding.instance once we have better diagnostics
    // on that getter.
    ui.PlatformDispatcher.instance.sendPlatformMessage(channel, message, (
      ByteData? reply,
    ) {
      try {
        final Duration duration = DateTime.now().difference(start);
        final record = channelTracker.buildRecordFromPair(
          channel,
          start,
          duration,
          message,
          reply,
        );
        channelStore.saveChannelInfo(record);
        completer.complete(reply);
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'services library',
            context: ErrorDescription(
              'during a platform message response callback',
            ),
          ),
        );
      }
    });
    // print('\n send \n channel: $channel \n message: ${message.toString()} \n}');
    return completer.future;
  }

  /// 设置消息处理器，处理完成后记录一次入站事件
  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    if (handler == null) {
      ui.channelBuffers.clearListener(channel);
    } else {
      ui.channelBuffers.setListener(channel, (
        ByteData? data,
        ui.PlatformMessageResponseCallback callback,
      ) async {
        final DateTime start = DateTime.now();
        ByteData? response;
        try {
          response = await handler(data);
        } catch (exception, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: exception,
              stack: stack,
              library: 'services library',
              context: ErrorDescription('during a platform message callback'),
            ),
          );
        } finally {
          callback(response);
          try {
            // 在 handler 完成后记录一次入站事件，duration 通过 sendTime 与当前时间差得到
            channelTracker.trackChannelEvent(
              channel,
              start,
              false,
              data: data,
              callback: callback,
            );
          } catch (_) {}
        }
      });
    }
  }
}
