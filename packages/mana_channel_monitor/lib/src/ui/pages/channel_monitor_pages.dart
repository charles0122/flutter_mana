import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_channel_monitor/src/ui/components/all_records_list.dart';
import 'package:mana_channel_monitor/src/ui/components/channel_detail.dart';
import 'package:mana_channel_monitor/src/core/channel_info_model.dart';

class ChannelMonitorPages extends StatefulWidget {
  const ChannelMonitorPages({Key? key, required this.name}) : super(key: key);

  final String name;

  @override
  State<ChannelMonitorPages> createState() => _ChannelMonitorPagesState();
}

class _ChannelMonitorPagesState extends State<ChannelMonitorPages> {
  ChannelRecord? currentModel;

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      showBarrier: false,
      initialWidth: double.infinity,
      position: PositionType.bottom,
      drag: false,
      content: Stack(
        children: [
          /// 列表页
          Positioned.fill(
            child: AllRecordsList(
              onTap: (model) {
                currentModel = model;
                setState(() {});
              },
            ),
          ),

          /// 详情页
          if (currentModel != null)
            Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                child: ChannelDetailPage(
                  channelInfoModel: currentModel,
                  onBackPressed: () {
                    currentModel = null;
                    setState(() {});
                  },
                ),
              ),
            ),
        ],
      ),
      name: widget.name,
    );
  }
}
