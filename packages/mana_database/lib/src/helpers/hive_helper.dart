import 'package:hive/hive.dart';
import 'package:mana_database/src/databases/databases.dart';
import 'package:mana_database/src/databases/hive_database.dart';
import 'package:mana_database/src/helpers/helpers.dart';

class HiveHelper implements ManaDatabaseHelper {
  Future<List<TableData>> findAllTable(HiveDatabase database) async {
    List<TableData> tableDatas = [];
    for (var boxItem in database.boxItems) {
      tableDatas.add(HiveTableData(boxItem.name, box: boxItem.box));
    }
    return tableDatas;
  }

  Future<List<Map<String, dynamic>>> findSingleBoxData(
    Box<UMEHiveData> box,
  ) async {
    List<Map<String, dynamic>> datas = [];
    // print(box.values);
    datas = box.values.map((d) => d.toJson()).toList();
    return datas;
  }
}
