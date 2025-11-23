/// 记录一次平台通道调用的完整信息
class ChannelRecord {
  // channel 传输方向
  final ChannelDirection direction;
  // channel 名称
  final String channelName;
  // 方法名称
  final String methodName;
  // channel 类型（Method / Event / Basic）
  final ChannelType type;
  // 发送时间
  final DateTime timestamp;
  // 发送耗时
  final Duration duration;
  // 输入数据大小（可能为空）
  final int? sendDataSize;
  // 返回数据大小（可能为空）
  final int? receiveDataSize;
  // 是否为系统channel
  bool get isSystemChannel => channelName.startsWith('flutter/');
  // 发送数据内容（可能为空）
  final dynamic sendData;
  // 接收的数据内容（可能为空）
  final dynamic receiveData;

  ChannelRecord({
    required this.channelName,
    required this.direction,
    required this.methodName,
    required this.timestamp,
    required this.duration,
    required this.sendDataSize,
    required this.type,
    this.receiveDataSize,
    this.sendData,
    this.receiveData,
  });

  @override
  String toString() {
    return 'ChannelRecord{direction: $direction, channelName: $channelName, methodName: $methodName, type: $type, timestamp: $timestamp, duration: $duration, sendDataSize: $sendDataSize, receiveDataSize: $receiveDataSize, sendData: $sendData, receiveData: $receiveData}';
  }
}

/// 调用方向
enum ChannelDirection { flutterToNative, nativeToFlutter }

enum ChannelType { event, method, basic }
