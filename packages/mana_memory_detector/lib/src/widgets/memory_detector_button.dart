import 'package:flutter/material.dart';

import '../model/leak_info.dart';
import '../memory_detector.dart';
import '../ume_kit_memory_detector.dart';
import 'leaked_info_page.dart';

/// 悬浮检测按钮
/// 展示检测任务进度与告警图标，点击弹出泄漏详情页；支持拖拽移动
class MemoryDetectorButton extends StatefulWidget {
  MemoryDetectorButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MemoryDetectorButtonState();
  }
}

class MemoryDetectorButtonState extends State<MemoryDetectorButton> {
  List<LeakedInfo> cache = [];

  double btnLeft = 10;
  double btnTop = 200;

  OverlayEntry? entry;

  void _dragUpdate(DragUpdateDetails details) {
    setState(() {
      btnLeft += details.delta.dx;
      btnTop += details.delta.dy;
    });
  }

  @override
  void initState() {
    super.initState();
    UmeKitMemoryDetector().infoStream.listen((event) {
      cache.add(event!);
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
            if (cache.isEmpty) return;
            if (entry == null) {
              entry = OverlayEntry(
                builder:
                    (_) => MemoryLeakDetailsPage(
                      leakInfoList: cache,
                      popCallback: () {
                        entry?.remove();
                        entry = null;
                        cache.clear();
                        setState(() {});
                      },
                    ),
              );
              Overlay.of(context).insert(entry!);
            }
          },
          onPanUpdate: _dragUpdate,
          child: Container(
            width: btnWidth,
            height: btnWidth,
            //padding: const EdgeInsets.all(5),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: StreamBuilder(
              stream: UmeKitMemoryDetector().taskPhaseStream,
              builder: (
                BuildContext context,
                AsyncSnapshot<DetectTaskEvent> snapshot,
              ) {
                if (snapshot.data?.phase == null)
                  return const Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white,
                    size: 40,
                  );
                final double progress =
                    ((snapshot.data!.phase.index + 1) / 6) * 100;
                switch (snapshot.data!.phase) {
                  case TaskPhase.startDetect:
                  case TaskPhase.startGC:
                  case TaskPhase.endGC:
                  case TaskPhase.startAnalyze:
                  case TaskPhase.endAnalyze:
                    return Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    );
                  case TaskPhase.endDetect:
                    if (cache.isEmpty) {
                      return const Icon(
                        Icons.remove_red_eye_outlined,
                        color: Colors.white,
                        size: 40,
                      );
                    } else {
                      return const Icon(
                        Icons.system_security_update_warning_rounded,
                        color: Colors.red,
                      );
                    }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
