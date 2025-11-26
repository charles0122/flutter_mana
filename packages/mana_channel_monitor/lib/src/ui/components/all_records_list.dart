import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:rxdart/subjects.dart';
import 'package:mana_channel_monitor/src/core/channel_info_model.dart';
import 'package:mana_channel_monitor/src/core/channel_store.dart';

typedef OnChannelModelSelected = void Function(ChannelRecord model);

/// 全部通道记录列表组件，支持筛选/滚动/锁定
class AllRecordsList extends StatefulWidget {
  /// 列表项点击回调，传递选中的通道记录
  final OnChannelModelSelected onTap;
  const AllRecordsList({Key? key, required this.onTap}) : super(key: key);

  @override
  State<AllRecordsList> createState() => _AllRecordsListState();
}

class _AllRecordsListState extends State<AllRecordsList> {
  /// 记录数据发布流（由 Store 推送筛选后的数据）
  final BehaviorSubject<List<ChannelRecord>> _publisher = BehaviorSubject();

  /// 列表滚动控制器
  final ScrollController _scrollController = ScrollController();

  /// 锁定滚动到最新（false 时自动滚到底部）
  bool _lock = false;

  /// 是否展示筛选输入框
  bool _filter = false;

  /// 筛选关键词（method/channel）
  String _filterKeywords = '';

  /// 筛选输入框控制器
  final TextEditingController _filterController = TextEditingController();

  /// 输入防抖定时器
  Timer? _debounceTimer;

  /// 列表分隔线
  static final Divider _divider = Divider(
    height: 1,
    color: Colors.grey.shade200,
  );

  /// 订阅 Store 发布流，用于触发筛选推送
  StreamSubscription<List<ChannelRecord>>? _storeSub;

  /// 滚动到列表底部
  void _scrollToBottom([bool animate = true]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final offset = _scrollController.position.maxScrollExtent;

      if (animate) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  /// 滚动到列表顶部
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  /// 切换锁定状态（锁定后不再自动滚到底部）
  void _toggleLock() {
    setState(() {
      _lock = !_lock;
    });
  }

  /// 切换筛选输入框展示
  void _toggleFilter() {
    setState(() {
      _filter = !_filter;
    });
  }

  /// 输入框内容变更（300ms 防抖），同时触发 Store 侧筛选
  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filterKeywords = _filterController.text.trim();
      });
      channelStore.getAllRecords(
        _publisher.sink,
        methodContains: _filterKeywords.isEmpty ? null : _filterKeywords,
      );
    });
  }

  /// 构建单条记录的列表项
  Widget _buildTile(ChannelRecord r) {
    final ts = r.timestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}.${ts.millisecond.toString().padLeft(3, '0')}';
    final directionStr =
        r.direction == ChannelDirection.flutterToNative ? 'F→N' : 'N→F';
    final typeStr = r.type.name;
    final durationStr = '${r.duration.inMilliseconds}ms';

    Color dirColor =
        r.direction == ChannelDirection.flutterToNative
            ? Colors.blue
            : Colors.green;
    Color typeColor;
    switch (r.type) {
      case ChannelType.method:
        typeColor = Colors.orange;
        break;
      case ChannelType.event:
        typeColor = Colors.purple;
        break;
      case ChannelType.basic:
        typeColor = Colors.teal;
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: const Border(),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Text(
            timeStr,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          Text(
            directionStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: dirColor,
            ),
          ),
          Text(
            typeStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
          Text(
            durationStr,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              r.methodName,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              r.channelName,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
      onTap: () {
        setState(() {
          _lock = true;
        });
        widget.onTap(r);
      },
    );
  }

  /// 底部操作区域：清空、顶/底滚动、锁定、筛选开关
  Widget _buildBottom() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          if (_filter) ...[
            TextField(
              controller: _filterController,
              decoration: const InputDecoration(
                hintText: '关键词（method/channel）',
                isDense: true,
                filled: true,
                fillColor: Color(0xFFE0E0E0),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
              ),
            ),
            _divider,
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              const selects = [false, false, false, false, false];
              final buttonWidth = constraints.maxWidth / selects.length;
              return ToggleButtons(
                isSelected: selects,
                renderBorder: false,
                constraints: BoxConstraints(
                  minHeight: 36.0,
                  minWidth: buttonWidth,
                ),
                onPressed: (index) {
                  switch (index) {
                    case 0:
                      channelStore.clearChannelRecords();
                      channelStore.getAllRecords(
                        _publisher.sink,
                        methodContains:
                            _filterKeywords.isEmpty ? null : _filterKeywords,
                      );
                      return;
                    case 1:
                      _scrollToTop();
                      return;
                    case 2:
                      _scrollToBottom();
                      return;
                    case 3:
                      _toggleLock();
                      return;
                    case 4:
                      _toggleFilter();
                      return;
                  }
                },
                children: [
                  const Icon(KitIcons.clear, size: 16),
                  const Icon(KitIcons.top, size: 16),
                  const Icon(KitIcons.down, size: 16),
                  Icon(_lock ? KitIcons.lock : KitIcons.lockOpen, size: 16),
                  Icon(
                    _filter ? KitIcons.filterOff : KitIcons.filterOn,
                    size: 16,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  /// 主体布局：顶部分割线 + 列表 + 底部操作
  Widget build(BuildContext context) {
    return Column(
      children: [
        _divider,
        Expanded(
          child: StreamBuilder<List<ChannelRecord>>(
            stream: _publisher,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              if (!_lock) {
                _scrollToBottom(false);
              }
              return ListView.separated(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) => _buildTile(data[index]),
                separatorBuilder: (_, __) => _divider,
              );
            },
          ),
        ),
        _divider,
        _buildBottom(),
      ],
    );
  }

  @override
  /// 初始化监听与默认筛选行为
  void initState() {
    super.initState();
    _filterController.addListener(_onTextChanged);
    _storeSub = channelStore.allRecordsPublisher.listen((_) {
      if (!mounted) return;
      channelStore.getAllRecords(
        _publisher.sink,
        methodContains: _filterKeywords.isEmpty ? null : _filterKeywords,
      );
    });
  }

  @override
  /// 释放资源：输入控制器、定时器、滚动控制器、发布流
  void dispose() {
    _filterController.dispose();
    _debounceTimer?.cancel();
    _storeSub?.cancel();
    _scrollController.dispose();
    _publisher.close();
    super.dispose();
  }
}
