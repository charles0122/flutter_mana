import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:mana_channel_monitor/src/core/channel_info_model.dart';
import 'package:mana_channel_monitor/src/core/channel_store.dart';

class _Decoded {
  final String method;
  final dynamic payload;
  final ChannelType type;
  const _Decoded(this.method, this.payload, this.type);
}

/// 负责从平台消息中解码并生成记录
class ChannelTracker {
  final StandardMethodCodec standardMethodCodec = const StandardMethodCodec();
  final JSONMethodCodec jsonMethodCodec = const JSONMethodCodec();
  final StandardMessageCodec standardMessageCodec =
      const StandardMessageCodec();
  final JSONMessageCodec jsonMessageCodec = const JSONMessageCodec();
  final StringCodec stringMessageCodec = const StringCodec();
  final BinaryCodec binaryMessageCodec = const BinaryCodec();

  /// 记录一次入站/出站的通道事件
  void trackChannelEvent(
    String channel,
    DateTime sendTime,
    bool send, {
    ByteData? data,
    MessageHandler? handler,
    ui.PlatformMessageResponseCallback? callback,
  }) {
    String method = 'unknown';
    dynamic payload;
    ChannelType type = ChannelType.basic;
    if (data == null) {
      final ChannelRecord model = ChannelRecord(
        type: type,
        channelName: channel,
        direction:
            send
                ? ChannelDirection.flutterToNative
                : ChannelDirection.nativeToFlutter,
        methodName: 'no_payload',
        timestamp: sendTime,
        duration: DateTime.now().difference(sendTime),
        sendDataSize: send ? 0 : 0,
        sendData: null,
        receiveData: null,
        receiveDataSize: send ? 0 : 0,
      );
      channelStore.saveChannelInfo(model);
      return;
    }
    final _Decoded? decoded = _decode(data);
    if (decoded != null) {
      method = decoded.method;
      payload = decoded.payload;
      type = decoded.type;
    }
    method = _heuristicMethodName(channel, payload, method);
    final ChannelRecord model = ChannelRecord(
      type: type,
      channelName: channel,
      direction:
          send
              ? ChannelDirection.flutterToNative
              : ChannelDirection.nativeToFlutter,
      methodName: method,
      timestamp: sendTime,
      duration: DateTime.now().difference(sendTime),
      sendDataSize: send ? data.elementSizeInBytes : 0,
      sendData: send ? payload : null,
      receiveData: send ? null : payload,
      receiveDataSize: send ? 0 : data.elementSizeInBytes,
    );
    channelStore.saveChannelInfo(model);
  }

  /// 依据请求与回复构建一条完整的记录
  ChannelRecord buildRecordFromPair(
    String channel,
    DateTime sendTime,
    Duration duration,
    ByteData? request,
    ByteData? reply,
  ) {
    String method = 'unknown';
    dynamic sendPayload;
    dynamic replyPayload;
    ChannelType type = ChannelType.basic;

    if (request != null) {
      final _Decoded? d = _decode(request);
      if (d != null) {
        method = d.method;
        sendPayload = d.payload;
        type = d.type;
      }
    }
    if (reply != null) {
      final _Decoded? r = _decode(reply);
      if (r != null) {
        replyPayload = r.payload;
      }
    }

    method = _heuristicMethodName(channel, sendPayload, method);

    return ChannelRecord(
      type: type,
      channelName: channel,
      direction: ChannelDirection.flutterToNative,
      methodName: method,
      timestamp: sendTime,
      duration: duration,
      sendDataSize: request?.elementSizeInBytes ?? 0,
      sendData: sendPayload,
      receiveData: replyPayload,
      receiveDataSize: reply?.elementSizeInBytes ?? 0,
    );
  }

  /// 尝试以不同编解码器解析载荷
  _Decoded? _decode(ByteData data) {
    return _decodeEnvelopeWithMethodCodecs(data) ??
        _decodeWithMethodCodecs(data) ??
        _decodeWithJsonMessageCodec(data) ??
        _decodeWithStringCodec(data) ??
        _decodeWithStandardMessageCodec(data) ??
        _decodeWithBinaryCodec(data);
  }

  /// 优先以 MethodCodec envelope 解析（事件流）
  _Decoded? _decodeEnvelopeWithMethodCodecs(ByteData data) {
    try {
      final dynamic v = standardMethodCodec.decodeEnvelope(data);
      return _Decoded('event', v, ChannelType.event);
    } catch (_) {
      try {
        final dynamic v = jsonMethodCodec.decodeEnvelope(data);
        return _Decoded('event', v, ChannelType.event);
      } catch (_) {
        return null;
      }
    }
  }

  /// 以 MethodCodec 解析调用（listen/cancel 视为事件）
  _Decoded? _decodeWithMethodCodecs(ByteData data) {
    try {
      final MethodCall call = standardMethodCodec.decodeMethodCall(data);
      final String m = call.method;
      final dynamic p = call.arguments;
      final ChannelType t =
          (m == 'listen' || m == 'cancel')
              ? ChannelType.event
              : ChannelType.method;
      return _Decoded(m, p, t);
    } catch (_) {
      try {
        final MethodCall call = jsonMethodCodec.decodeMethodCall(data);
        final String m = call.method;
        final dynamic p = call.arguments;
        final ChannelType t =
            (m == 'listen' || m == 'cancel')
                ? ChannelType.event
                : ChannelType.method;
        return _Decoded(m, p, t);
      } catch (_) {
        return null;
      }
    }
  }

  /// 以 JSONMessageCodec 解析载荷
  _Decoded? _decodeWithJsonMessageCodec(ByteData data) {
    try {
      final dynamic j = jsonMessageCodec.decodeMessage(data);
      if (j is Map) {
        final String m =
            (j['method'] ?? j['type'] ?? j['action'] ?? 'json').toString();
        return _Decoded(m, j, ChannelType.basic);
      }
      if (j is List) {
        return _Decoded('json_list', j, ChannelType.basic);
      }
      return _Decoded('json', j, ChannelType.basic);
    } catch (_) {
      return null;
    }
  }

  /// 以 StringCodec 解析载荷
  _Decoded? _decodeWithStringCodec(ByteData data) {
    try {
      final String? s = stringMessageCodec.decodeMessage(data);
      if (s == null) return null;
      return _Decoded(s, s, ChannelType.basic);
    } catch (_) {
      return null;
    }
  }

  /// 以 StandardMessageCodec 解析载荷
  _Decoded? _decodeWithStandardMessageCodec(ByteData data) {
    try {
      final dynamic v = standardMessageCodec.decodeMessage(data);
      if (v is Map) {
        final String m =
            (v['method'] ?? v['type'] ?? v['action'] ?? 'binary').toString();
        return _Decoded(m, v, ChannelType.basic);
      }
      return _Decoded('binary', v, ChannelType.basic);
    } catch (_) {
      return null;
    }
  }

  /// 以 BinaryCodec 解析载荷
  _Decoded? _decodeWithBinaryCodec(ByteData data) {
    try {
      final ByteData? b = binaryMessageCodec.decodeMessage(data);
      if (b == null) return null;
      return _Decoded('binary_raw', b, ChannelType.basic);
    } catch (_) {
      return null;
    }
  }

  /// 根据 channel 与载荷启发式推断更语义化的 method 名称
  String _heuristicMethodName(String channel, dynamic payload, String method) {
    if (channel == 'flutter/lifecycle') {
      if (payload is String && payload.isNotEmpty) return payload;
    }
    if (channel == 'flutter/keyboard') {
      if (payload is Map) {
        final v = payload['type'] ?? payload['action'] ?? payload['method'];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    if (method == 'unknown' || method == 'json' || method == 'binary') {
      if (payload is Map) {
        final v =
            payload['method'] ??
            payload['type'] ??
            payload['action'] ??
            payload['name'];
        if (v != null) return v.toString();
      } else if (payload is String && payload.isNotEmpty) {
        return payload;
      }
    }
    return method;
  }
}

ChannelTracker channelTracker = ChannelTracker();
