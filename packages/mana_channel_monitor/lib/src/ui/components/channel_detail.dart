import 'package:flutter/material.dart';
import 'package:mana_channel_monitor/src/core/channel_info_model.dart';

/// 单条通道记录详情组件
class ChannelDetailPage extends StatelessWidget {
  /// 需要展示的通道记录
  final ChannelRecord? channelInfoModel;

  /// 返回按钮回调
  final VoidCallback onBackPressed;
  const ChannelDetailPage({
    Key? key,
    this.channelInfoModel,
    required this.onBackPressed,
  }) : super(key: key);

  /// 统一分割线样式
  static final _divider = Divider(height: 1, color: Colors.grey.shade200);

  @override
  /// 构建详情表格，包括基本信息与载荷数据
  Widget build(BuildContext context) {
    if (channelInfoModel == null) {
      return Container();
    }
    ChannelRecord model = channelInfoModel!;
    bool isFlutterToNative =
        model.direction == ChannelDirection.flutterToNative;
    return Container(
      child: Column(
        children: [
          _divider,
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey, size: 16),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onBackPressed,
              ),
              Expanded(
                child: Text(
                  model.methodName.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          _divider,
          Table(
            border: TableBorder(
              verticalInside: BorderSide(color: Colors.grey.shade200),
              horizontalInside: BorderSide(color: Colors.grey.shade200),
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
            columnWidths: const {
              0: FixedColumnWidth(120),
              1: FlexColumnWidth(),
            },
            children: [
              _detailRow('Channel Name', model.channelName),
              _detailRow(
                'Channel Type',
                '${model.type.toString().substring(12)} channel',
              ),
              _detailRow(
                'Is System Channel',
                model.isSystemChannel ? 'yes' : 'no',
              ),
              _detailRow(
                'Trans Direction',
                model.direction.toString().substring(15),
              ),
              _detailRow('Time Cost', '${model.duration.inMilliseconds} ms'),
              if (isFlutterToNative)
                _detailRow('Send Data Size', _formatBytes(model.sendDataSize)),
              if (isFlutterToNative)
                ..._buildKeyValueRows('Send Data', model.sendData),
              if (!isFlutterToNative)
                _detailRow(
                  'Receive Data Size',
                  _formatBytes(model.receiveDataSize),
                ),
              if (!isFlutterToNative)
                ..._buildKeyValueRows('Receive Data', model.receiveData),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建详情表格的一行（键值对）
  TableRow _detailRow(String key, String value) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              key,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SelectableText(value, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  /// 将 Map 或任意对象渲染为多行键值表格
  List<TableRow> _buildKeyValueRows(String title, dynamic data) {
    if (data is Map) {
      final rows = <TableRow>[_detailRow(title, '')];
      for (final entry in data.entries) {
        rows.add(_detailRow(entry.key.toString(), entry.value.toString()));
      }
      return rows;
    }
    return [_detailRow(title, data.toString())];
  }

  /// 字节大小格式化显示（B/KB/MB）
  String _formatBytes(int? size) {
    final s = size ?? 0;
    const kb = 1024;
    const mb = 1024 * 1024;
    if (s < kb) return '$s B';
    if (s < mb) return '${(s / kb).toStringAsFixed(1)} KB';
    return '${(s / mb).toStringAsFixed(1)} MB';
  }
}
