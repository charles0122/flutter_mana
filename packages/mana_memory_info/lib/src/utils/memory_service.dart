import 'package:flutter/cupertino.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:vm_service/vm_service.dart';

class Property {
  final bool isConst;
  final bool isStatic;
  final bool isFinal;
  final String type;
  final String name;
  const Property({
    required this.isConst,
    required this.isStatic,
    required this.isFinal,
    required this.type,
    required this.name,
  });
  String get propertyStr {
    final String modifier =
        isStatic
            ? "static"
            : isConst
            ? "const"
            : isFinal
            ? "final"
            : "";
    return "$modifier $type $name".trim();
  }
}

class ClsModel {
  final List<Property> properties;
  final List<String> functions;
  const ClsModel({required this.properties, required this.functions});
}

class VmInfo {
  final int? pid;
  final String? hostCPU;
  final String? version;
  const VmInfo({this.pid, this.hostCPU, this.version});
}

class MemoryInfo {
  final int externalUsageBytes;
  final String externalUsageFormatted;
  final int heapCapacityBytes;
  final String heapCapacityFormatted;
  final int heapUsageBytes;
  final String heapUsageFormatted;
  const MemoryInfo({
    required this.externalUsageBytes,
    required this.externalUsageFormatted,
    required this.heapCapacityBytes,
    required this.heapCapacityFormatted,
    required this.heapUsageBytes,
    required this.heapUsageFormatted,
  });
}

class FormattedClassHeapStats extends ClassHeapStats {
  final String accumulatedSizeFormatted;
  FormattedClassHeapStats({
    super.classRef,
    super.accumulatedSize,
    super.bytesCurrent,
    super.instancesAccumulated,
    super.instancesCurrent,
    required this.accumulatedSizeFormatted,
  });
  factory FormattedClassHeapStats.fromClassHeapStats(ClassHeapStats stats) {
    return FormattedClassHeapStats(
      classRef: stats.classRef,
      accumulatedSize: stats.accumulatedSize,
      bytesCurrent: stats.bytesCurrent,
      instancesAccumulated: stats.instancesAccumulated,
      instancesCurrent: stats.instancesCurrent,
      accumulatedSizeFormatted: MemoryService.byteToString(
        stats.accumulatedSize ?? 0,
      ),
    );
  }
}

class MemoryService with VmInspectorMixin {
  List<FormattedClassHeapStats> classHeapStatsList = [];
  VmInfo? vmInfo;
  MemoryInfo? memoryUsageInfo;
  Future<void> getInfos(void Function() completion) async {
    try {
      final results = await Future.wait([
        vmInspector.getClassHeapStats(),
        vmInspector.getMemoryUsage(),
        vmInspector.getVM(),
      ]);
      if (results case [
        List<ClassHeapStats> heapStats,
        MemoryUsage memoryUsage,
        VM vm,
      ]) {
        classHeapStatsList =
            heapStats
                .map(
                  (stats) => FormattedClassHeapStats.fromClassHeapStats(stats),
                )
                .toList()
              ..sort(
                (a, b) =>
                    b.accumulatedSize?.compareTo(a.accumulatedSize ?? 0) ?? 0,
              );
        vmInfo = VmInfo(pid: vm.pid, hostCPU: vm.hostCPU, version: vm.version);
        memoryUsageInfo = MemoryInfo(
          externalUsageBytes: memoryUsage.externalUsage ?? 0,
          externalUsageFormatted: byteToString(memoryUsage.externalUsage ?? 0),
          heapCapacityBytes: memoryUsage.heapCapacity ?? 0,
          heapCapacityFormatted: byteToString(memoryUsage.heapCapacity ?? 0),
          heapUsageBytes: memoryUsage.heapUsage ?? 0,
          heapUsageFormatted: byteToString(memoryUsage.heapUsage ?? 0),
        );
        completion();
      } else {
        debugPrint("Get vm info failed or unexpected result type.");
      }
    } catch (e) {
      debugPrint('Get vm info error: $e');
    }
  }

  Future<void> getInstanceIds(
    String classId,
    int limit,
    void Function(List<String>?) completion,
  ) async {
    final instanceSet = await vmInspector.getInstances(classId, limit);
    final instanceIds =
        instanceSet.instances?.map((e) => e.id).whereType<String>().toList();
    completion(instanceIds);
  }

  Future<void> getClassDetailInfo(
    String classId,
    void Function(ClsModel?) completion,
  ) async {
    if (classId.isEmpty) {
      completion(null);
      return;
    }
    final obj = await vmInspector.getObject(classId);
    if (obj is! Class) {
      completion(null);
      return;
    }
    final cls = obj;
    final List<Property> properties = [];
    final List<String> functions = [];
    for (final fieldRef in cls.fields ?? []) {
      if (fieldRef.declaredType?.name != null) {
        properties.add(
          Property(
            isConst: fieldRef.isConst ?? false,
            isStatic: fieldRef.isStatic ?? false,
            isFinal: fieldRef.isFinal ?? false,
            type: fieldRef.declaredType!.name!,
            name: fieldRef.name ?? 'N/A',
          ),
        );
      }
    }
    for (final funcRef in cls.functions ?? []) {
      if (funcRef.id == null) continue;
      final funcObj = await vmInspector.getObject(funcRef.id!);
      if (funcObj is Func) {
        if (funcObj.code?.name != null &&
            !funcObj.code!.name!.contains("[Stub]")) {
          String cleanedCodeName = funcObj.code!.name!
              .replaceAll('[Unoptimized] ', '')
              .replaceAll('[Optimized] ', '');
          functions.add(cleanedCodeName);
        }
      }
    }
    final clsModel = ClsModel(properties: properties, functions: functions);
    completion(clsModel);
  }

  void sortClassHeapStats<T extends Comparable<Object?>>(
    T Function(FormattedClassHeapStats d) getField,
    bool descending,
    void Function() completion,
  ) {
    classHeapStatsList.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
    });
    completion();
  }

  static const int kiloByte = 1024;
  static const int megaByte = kiloByte * 1024;
  static const int gigaByte = megaByte * 1024;
  static String byteToString(int size) {
    if (size >= gigaByte) {
      return "${(size / gigaByte).toStringAsFixed(1)} G";
    } else if (size >= megaByte) {
      return "${(size / megaByte).toStringAsFixed(1)} M";
    } else if (size >= kiloByte) {
      return "${(size / kiloByte).toStringAsFixed(1)} K";
    } else {
      return "$size B";
    }
  }
}
