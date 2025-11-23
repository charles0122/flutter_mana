import 'dart:async';
import 'package:rxdart/subjects.dart';

import 'channel_info_model.dart';

class ChannelRecordStore {
  final BehaviorSubject<List<String>> _orderedChannelNamePublisher =
      BehaviorSubject();

  final Map<String, List<ChannelRecord>> _orderedChannelEvents = {};

  int maxPerChannel = 100;

  Stream<List<String>> get channelNamePublisher =>
      _orderedChannelNamePublisher.stream;

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

  void getChannelByName(String name, Sink sink,
      {ChannelDirection? direction,
      ChannelType? type,
      String? methodContains,
      DateTime? from,
      DateTime? to}) {
    if (name == '') {
      return;
    }
    final list = _orderedChannelEvents[name] ?? const [];
    final filtered = list.where((e) {
      if (direction != null && e.direction != direction) return false;
      if (type != null && e.type != type) return false;
      if (methodContains != null && methodContains.isNotEmpty) {
        if (!e.methodName.toLowerCase().contains(methodContains.toLowerCase())) {
          return false;
        }
      }
      if (from != null && e.timestamp.isBefore(from)) return false;
      if (to != null && e.timestamp.isAfter(to)) return false;
      return true;
    }).toList();
    sink.add(filtered);
  }

  void clearChannelRecords({String? channel}) {
    if (channel != null) {
      _orderedChannelEvents.remove(channel);
    } else {
      _orderedChannelEvents.clear();
    }
    refresh();
  }

  void refresh() {
    _orderedChannelNamePublisher.add(_orderedChannelEvents.keys.toList());
  }
}

ChannelRecordStore channelStore = ChannelRecordStore();
