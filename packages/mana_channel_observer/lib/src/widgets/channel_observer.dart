import 'package:flutter/material.dart';
import 'package:mana_channel_observer/src/model/package_model.dart';
import 'package:mana_channel_observer/src/widgets/recent_channel_record_page.dart';

import '../mana_channel_observer.dart';

/// 悬浮按钮：监听错误流并提供拖拽与点击查看记录
class ChannelObserverOverlay extends StatefulWidget {
  ChannelObserverOverlay({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChannelObserverOverlayState();
  }
}

class ChannelObserverOverlayState extends State<ChannelObserverOverlay> {
  final List<ChannelModel> _cacheBucket = [];

  OverlayEntry? entry;

  bool _showWarning = false;

  double btnLeft = 10;

  double btnTop = 200;

  void _dragUpdate(DragUpdateDetails details) {
    setState(() {
      btnLeft += details.delta.dx;
      btnTop += details.delta.dy;
    });
  }

  @override
  void initState() {
    super.initState();
    ManaChannelObserver.errorStream.listen((event) {
      setState(() {
        _showWarning = true;
      });
      _cacheBucket.addAll(
        ManaChannelObserver.getBindingInstance()?.popChannelRecorders() ?? [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const double btnWidth = 48;
    final Size size = MediaQuery.of(context).size;
    return Positioned(
      left: btnLeft.clamp(0, size.width - btnWidth),
      top: btnTop.clamp(0, size.height - btnWidth),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () async {
            if (_showWarning && _cacheBucket.isNotEmpty) {
              List<ChannelModel> tem = List.from(_cacheBucket);
              setState(() {
                _showWarning = false;
                _cacheBucket.clear();
              });
              if (entry == null) {
                entry = OverlayEntry(
                  builder:
                      (_) => ChannelRecordListPage(
                        records: tem,
                        popCallback: () {
                          entry?.remove();
                          entry = null;
                        },
                      ),
                );
                Overlay.of(context).insert(entry!);
              }
            }
          },
          onPanUpdate: _dragUpdate,
          child: Container(
            width: btnWidth,
            height: btnWidth,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child:
                _showWarning
                    ? const Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                      size: 40,
                    )
                    : const Icon(
                      Icons.wifi_protected_setup,
                      color: Colors.white,
                      size: 40,
                    ),
          ),
        ),
      ),
    );
  }
}
