import 'dart:async';
import 'package:rxdart/subjects.dart';

import 'channel_info_model.dart';

/// 管理通道调用记录的存储、筛选与发布
class ChannelRecordStore {
  final BehaviorSubject<List<String>> _orderedChannelNamePublisher =
      BehaviorSubject();

  final Map<String, List<ChannelRecord>> _orderedChannelEvents = {};

  final BehaviorSubject<List<ChannelRecord>> _allRecordsPublisher =
      BehaviorSubject.seeded(const []);

  int maxPerChannel = 100;

  ChannelRecordStore() {
    refresh();
  }

  /// 发布当前已记录的 channel 名称列表
  Stream<List<String>> get channelNamePublisher =>
      _orderedChannelNamePublisher.stream;

  /// 发布所有记录的流（按时间排序）
  Stream<List<ChannelRecord>> get allRecordsPublisher =>
      _allRecordsPublisher.stream;

  /// 是否存在指定 channel 的记录
  bool hasChannel(String name) => _orderedChannelEvents.containsKey(name);

  /// 保存一条通道调用记录，并触发刷新
  void saveChannelInfo(ChannelRecord model) {
    if (_orderedChannelEvents[model.channelName] == null) {
      _orderedChannelEvents[model.channelName] = [];
    }
    final bucket = _orderedChannelEvents[model.channelName]!;
    if (bucket.length >= maxPerChannel) {
      bucket.removeAt(0);
    }
    bucket.add(model);
    refresh();
  }

  /// 按 channelName 获取记录并通过 Sink 发布（支持筛选）
  void getChannelByName(
    String name,
    Sink sink, {
    ChannelDirection? direction,
    ChannelType? type,
    String? methodContains,
    DateTime? from,
    DateTime? to,
  }) {
    if (name == '') {
      return;
    }
    final list = _orderedChannelEvents[name] ?? const [];
    final filtered =
        list.where((e) {
          if (direction != null && e.direction != direction) return false;
          if (type != null && e.type != type) return false;
          if (methodContains != null && methodContains.isNotEmpty) {
            if (!e.methodName.toLowerCase().contains(
              methodContains.toLowerCase(),
            )) {
              return false;
            }
          }
          if (from != null && e.timestamp.isBefore(from)) return false;
          if (to != null && e.timestamp.isAfter(to)) return false;
          return true;
        }).toList();
    sink.add(filtered);
  }

  /// 清除某个 channel 或全部记录
  void clearChannelRecords({String? channel}) {
    if (channel != null) {
      _orderedChannelEvents.remove(channel);
    } else {
      _orderedChannelEvents.clear();
    }
    refresh();
  }

  /// 刷新内部缓存并更新发布流
  void refresh() {
    _orderedChannelNamePublisher.add(_orderedChannelEvents.keys.toList());
    final List<ChannelRecord> flattened = [];
    for (final entry in _orderedChannelEvents.entries) {
      flattened.addAll(entry.value);
    }
    flattened.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _allRecordsPublisher.add(flattened);
  }

  /// 获取所有记录并通过 Sink 发布（支持筛选）
  void getAllRecords(
    Sink sink, {
    ChannelDirection? direction,
    ChannelType? type,
    String? methodContains,
    DateTime? from,
    DateTime? to,
  }) {
    final List<ChannelRecord> flattened = [];
    for (final entry in _orderedChannelEvents.entries) {
      flattened.addAll(entry.value);
    }
    final filtered =
        flattened.where((e) {
          if (direction != null && e.direction != direction) return false;
          if (type != null && e.type != type) return false;
          if (methodContains != null && methodContains.isNotEmpty) {
            if (!e.methodName.toLowerCase().contains(
              methodContains.toLowerCase(),
            )) {
              return false;
            }
          }
          if (from != null && e.timestamp.isBefore(from)) return false;
          if (to != null && e.timestamp.isAfter(to)) return false;
          return true;
        }).toList();
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    sink.add(filtered);
  }
}

ChannelRecordStore channelStore = ChannelRecordStore();
