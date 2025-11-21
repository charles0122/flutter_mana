import 'dart:math' show Random;

import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/table_column_control_handles_popup_route.dart';
import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_database/src/databases/databases.dart';
import 'package:mana_database/src/databases/hive_database.dart';
import 'package:mana_database/src/databases/shared_preferences.dart';
import 'package:mana_database/src/databases/sql_database.dart';
import 'package:mana_database/src/widgets/database_manager.dart';

class _DBTableColumn extends TableColumn {
  _DBTableColumn({
    required int index,
    required super.width,
    super.freezePriority = 0,
    super.sticky = false,
    super.flex = 0,
    super.translation = 0,
    super.minResizeWidth,
    super.maxResizeWidth,
  }) : key = ValueKey<int>(index),
       index = index;

  final int index;

  @override
  final ValueKey<int> key;

  @override
  _DBTableColumn copyWith({
    double? width,
    int? freezePriority,
    bool? sticky,
    int? flex,
    double? translation,
    double? minResizeWidth,
    double? maxResizeWidth,
  }) => _DBTableColumn(
    index: index,
    width: width ?? this.width,
    freezePriority: freezePriority ?? this.freezePriority,
    sticky: sticky ?? this.sticky,
    flex: flex ?? this.flex,
    translation: translation ?? this.translation,
    minResizeWidth: minResizeWidth ?? this.minResizeWidth,
    maxResizeWidth: maxResizeWidth ?? this.maxResizeWidth,
  );
}

class DatabasePanelController extends ChangeNotifier {
  DatabasePanelController(this._initialDatabases);
  final List<UMEDatabase> _initialDatabases;
  final DatabaseManager databaseManager = DatabaseManager();
  List<TableData> tableDatas = [];
  List<Map<String, dynamic>> datas = [];
  int currentDatabaseIndex = 0;
  int currentTableIndex = 0;
  DatabaseType? currentDatabaseType;
  bool dbIsOpen = false;

  Future<void> openDB() async {
    await databaseManager.openDatabases(databases: _initialDatabases);
    if (databaseManager.databases.isNotEmpty) {
      var db = databaseManager.databases[currentDatabaseIndex];
      if (db is SqliteDatabase) {
        tableDatas = await databaseManager.sqliteHelper.findAllTableData(db);
        currentDatabaseType = DatabaseType.sqlite;
      } else if (db is HiveDatabase) {
        tableDatas = await databaseManager.hiveHelper.findAllTable(db);
        currentDatabaseType = DatabaseType.hive;
      } else if (db is SharedPreferencesDatabase) {
        tableDatas = [db.tableData];
        currentDatabaseType = DatabaseType.sharedPreferences;
      }
    }
    if (tableDatas.isNotEmpty) {
      await updateTableSelect(tableDatas[0]);
    }
    dbIsOpen = true;
    notifyListeners();
  }

  void updateCurrentDatabaseType() {
    var databases = databaseManager.databases[currentDatabaseIndex];
    if (databases is SqliteDatabase) {
      currentDatabaseType = DatabaseType.sqlite;
    } else if (databases is HiveDatabase) {
      currentDatabaseType = DatabaseType.hive;
    } else if (databases is CustomDatabase) {
      currentDatabaseType = DatabaseType.customDB;
    } else if (databases is SharedPreferencesDatabase) {
      currentDatabaseType = DatabaseType.sharedPreferences;
    }
    currentTableIndex = 0;
    if (tableDatas.isNotEmpty) {
      updateTableSelect(tableDatas[currentTableIndex]);
    }
    notifyListeners();
  }

  Future<void> updateDatabaseSelect(UMEDatabase database) async {
    if (database is SqliteDatabase) {
      tableDatas = await databaseManager.sqliteHelper.findAllTableData(
        database,
      );
    } else if (database is HiveDatabase) {
      tableDatas = await databaseManager.hiveHelper.findAllTable(database);
    } else if (database is SharedPreferencesDatabase) {
      tableDatas = [database.tableData];
    }
    updateCurrentDatabaseType();
    notifyListeners();
  }

  Future<void> updateTableSelect(TableData tableData) async {
    datas.clear();
    if (tableData is SqliteTableData) {
      var dd = await databaseManager.sqliteHelper.findSingleTableAllData(
        tableData.tableName(),
      );
      datas.addAll(dd);
    } else if (tableData is HiveTableData) {
      var dd = await databaseManager.hiveHelper.findSingleBoxData(
        tableData.box,
      );
      datas.addAll(dd);
    } else if (tableData is SharedPreferencesTableData) {
      var dd = databaseManager.sharedPreferencesHelper.findAllData(tableData);
      datas.addAll(dd);
    }
    notifyListeners();
  }

  Future<bool> sharedPreferencesDataUpdate(
    ColumnDataType columnDataType,
    String key,
    Object value,
  ) async {
    return databaseManager.sharedPreferencesHelper.updateKey(
      columnDataType,
      key,
      value,
    );
  }

  Map<String, dynamic> sqliteUpdateColumnData({
    required Map<String, dynamic> map,
    required String column,
    required String writeText,
    required UpdateConditions updateConditions,
    required String tableName,
  }) {
    var data = Map<String, dynamic>.from(map);
    data[column] = writeText;
    List<String> args = [];
    for (var c in updateConditions.getUpdateNeedColumnKey!) {
      if (data[c] != null) {
        args.add(data[c].toString());
      }
    }
    databaseManager.sqliteHelper.updateData(
      tableName,
      updateMaps: [data],
      where: updateConditions.getUpdateNeedWhere,
      whereArgs: args,
    );
    return data;
  }
}

class DatabasePanel extends StatefulWidget with I18nMixin {
  final String name;

  const DatabasePanel({super.key, required this.name, required this.databases});

  ///need developer the databases
  ///sqlite path is null we using database name create database
  ///if isDeleteDB = [true] to we do delete the db
  ///PluginManager.instance.register(
  ///DatabasePanel(
  ///databases: [
  ///SqliteDatabase('test.db', path: null,,isDeleteDB: true)
  ///]
  ///))
  final List<UMEDatabase> databases;

  @override
  State<DatabasePanel> createState() => _DatabasePanelState();
}

class _DatabasePanelState extends State<DatabasePanel>
    with SingleTickerProviderStateMixin {
  late final DatabasePanelController _controller;
  List<bool> selected = [];
  int selectIndex = 0;
  final Color background = Colors.white;
  List<TableColumn> _tableColumns = [];
  List<int> _columnOrder = [];
  final Set<int> selection = <int>{};

  OverlayEntry _overlayEntry = OverlayEntry(builder: (ctx) => Container());

  //only show an overlay
  bool isShowOverlay = false;

  @override
  void initState() {
    _controller = DatabasePanelController(widget.databases);
    _controller.addListener(() {
      setState(() {});
    });
    _controller.openDB();
    super.initState();
  }

  @override
  void dispose() {
    if (_overlayEntry.mounted) {
      _overlayEntry.remove();
    }
    super.dispose();
  }

  Future<void> _updateDatabaseSelect(UMEDatabase database) async {
    await _controller.updateDatabaseSelect(database);
  }

  //listener table data
  Future<void> _updateTableSelect(TableData tableData) async {
    await _controller.updateTableSelect(tableData);
  }

  ///filter an map text
  String _filterShowText(String text) {
    return text.replaceAll(',', '\n').replaceAll('{', '').replaceAll('}', '');
  }

  ///show an overlay entry
  void _showOverlayEntry(Widget child) {
    if (isShowOverlay) return;
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return child;
      },
    );
    // overlayKey.currentState?.insert(_overlayEntry);
    isShowOverlay = true;
  }

  //the hide overlay entry
  void _hideOverlayEntry() {
    if (_overlayEntry.mounted) {
      _overlayEntry.remove();
      isShowOverlay = false;
    }
  }

  //show an simple dialog
  void _showSimpleDialog(String text) {
    var child = Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(top: 200, bottom: 200, left: 50, right: 50),
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.1)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _hideOverlayEntry();
            },
            child: const Text("关闭"),
          ),
        ],
      ),
    );
    _showOverlayEntry(child);
  }

  //   @override
  // Widget build(BuildContext context) {
  //   return ManaFloatingWindow(name: name, content: Text('Database'));
  // }

  @override
  Widget build(BuildContext context) {
    if (!_controller.dbIsOpen) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.dbIsOpen && _controller.databaseManager.databases.isEmpty) {
      return const Center(child: Text('not find database'));
    }

    return ManaFloatingWindow(
      name: widget.name,
      initialHeight: double.infinity,
      initialWidth: double.infinity,
      content: Container(
        alignment: Alignment.topCenter,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(3),
          ),
        ),
        child: Column(
          children: [
            buildDatabaseData(),

            ///--------table
            buildTableData(),

            ///column
            buildTableColumnData(),
          ],
        ),
      ),
    );
  }

  ///build table data
  Widget buildTableData() {
    return Container(
      color: Colors.white,
      height: 90,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(_controller.tableDatas.length, (index) {
                return GestureDetector(
                  onTap: () async {
                    _controller.currentTableIndex = index;
                    await _updateTableSelect(_controller.tableDatas[index]);
                  },
                  child: Container(
                    width:
                        _controller.tableDatas[index].tableName().length * 15,
                    margin: const EdgeInsets.all(5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          _controller.currentTableIndex == index
                              ? Colors.blueAccent
                              : Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _controller.tableDatas[index].tableName(),
                          style: TextStyle(
                            color:
                                _controller.currentTableIndex == index
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 16.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: 40,
            child: Container(
              height: 40,
              color: Colors.white,
              margin: const EdgeInsets.only(left: 10.0, top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'view table information',
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        var tableData =
                            _controller.tableDatas[_controller
                                .currentTableIndex];
                        _showSimpleDialog(
                          _filterShowText(tableData.toJson().toString()),
                        );
                      },
                      child: const Icon(Icons.info, size: 30),
                    ),
                  ),
                  const SizedBox(width: 15),
                  DatabaseType.sqlite == _controller.currentDatabaseType ||
                          DatabaseType.sharedPreferences ==
                              _controller.currentDatabaseType
                      ? Tooltip(
                        message: "add item",
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () async {
                            _addAnTableColumnData();
                          },
                          child: const Icon(Icons.add, size: 30),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///add an table the column data
  ///this function currently only works for [sqlite] and [shared_preferences]
  _addAnTableColumnData() {
    var table = _controller.tableDatas[_controller.currentTableIndex];

    if (DatabaseType.sqlite == _controller.currentDatabaseType) {
      var database =
          _controller.databaseManager.databases[_controller
                  .currentDatabaseIndex]
              as SqliteDatabase;
      var std = table as SqliteTableData;
      Map<String, dynamic> data = {};
      var conditions =
          _controller.databaseManager.sqliteHelper.updateMap[table.name];
      conditions ??=
          _controller.databaseManager.sqliteHelper.updateMap[_controller
              .databaseManager
              .sqliteHelper
              .defaultUpdateConditions];
      for (var column in std.columnData) {
        data[column.name] = '';
        if (conditions != null) {
          if (conditions.getUpdateNeedColumnKey.contains(column.name)) {
            data[column.name] =
                column.type == 'integer'
                    ? Random().nextInt(10000000)
                    : Random().nextInt(10000000).toString();
          }
        }
      }
      database.db?.insert(table.tableName(), data);
      _updateTableSelect(table);
    } else if (DatabaseType.sharedPreferences ==
        _controller.currentDatabaseType) {
      TextEditingController _key = TextEditingController();
      TextEditingController _value = TextEditingController();
      ColumnDataType selectType = ColumnDataType.string;
      _showOverlayEntry(
        SimpleDialog(
          title: const Text("创建数据"),
          children: [
            TextField(
              controller: _key,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Key',
                contentPadding: EdgeInsets.only(left: 10),
              ),
            ),
            TextField(
              controller: _value,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Value',
                contentPadding: EdgeInsets.only(left: 10),
              ),
            ),
            StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
                  children: [
                    for (var type in ColumnDataType.values)
                      if (type == ColumnDataType.invalid)
                        Container()
                      else
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: ChoiceChip(
                            onSelected: (b) {
                              if (b) {
                                setState.call(() {
                                  selectType = type;
                                });
                              }
                              // (context as Element).markNeedsBuild();
                              // print(b);
                            },
                            label: Text(
                              type.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            selected: selectType == type,
                            selectedColor: Colors.blue,
                            disabledColor: Colors.grey[500],
                          ),
                        ),
                  ],
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    var b = await _controller
                        .databaseManager
                        .sharedPreferencesHelper
                        .updateKey(selectType, _key.text, _value.text);
                    if (b) {
                      var tableData =
                          _controller.tableDatas[_controller.currentTableIndex]
                              as SharedPreferencesTableData;
                      //the data type need add, need use it update data
                      tableData.columnDataType[_key.text] = selectType;
                      _updateTableSelect(
                        _controller.tableDatas[_controller.currentTableIndex],
                      );
                    }
                    _hideOverlayEntry();
                  },
                  child: const Text("创建"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _hideOverlayEntry();
                  },
                  child: const Text("关闭"),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget buildDatabaseData() {
    return SizedBox(
      height: 44,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                _controller.databaseManager.databases.length,
                (index) => GestureDetector(
                  onTap: () {
                    _controller.currentDatabaseIndex = index;
                    _updateDatabaseSelect(
                      _controller.databaseManager.databases[index],
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.all(5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          _controller.currentDatabaseIndex == index
                              ? Colors.greenAccent
                              : Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Text(
                          _controller
                              .databaseManager
                              .databases[index]
                              .databaseName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: Colors.black, height: 0.2),
        ],
      ),
    );
  }

  ///builder table column data
  Widget buildTableColumnData() {
    return Expanded(
      child: Builder(
        builder: (context) {
          List<ColumnData> columns = [];
          UpdateConditions? updateConditions;
          var tableData = _controller.tableDatas[_controller.currentTableIndex];
          if (_controller.currentDatabaseType == DatabaseType.sqlite) {
            var std = tableData as SqliteTableData;
            columns = std.columnData;
            if (columns.isEmpty) {
              return const Center(child: Text("没有数据"));
            }
            updateConditions =
                _controller.databaseManager.sqliteHelper.updateMap[tableData
                    .tableName()];
            updateConditions ??=
                _controller.databaseManager.sqliteHelper.updateMap[_controller
                    .databaseManager
                    .sqliteHelper
                    .defaultUpdateConditions];
          } else if (_controller.currentDatabaseType == DatabaseType.hive) {
            var thd = tableData as HiveTableData;
            var values = thd.box.values;
            if (values.isNotEmpty) {
              var keys = values.first.toJson().keys;
              for (var key in keys) {
                columns.add(HiveColumnData(name: key));
              }
            }
          } else if (_controller.currentDatabaseType ==
              DatabaseType.sharedPreferences) {
            var sptd = tableData as SharedPreferencesTableData;
            updateConditions = SharedPreferencesUpdateConditions();
            columns.addAll(sptd.columns);
          }
          if (columns.isEmpty) {
            return const Center(child: Text("not data"));
          }

          final expectedColumnCount = columns.length + 2;
          if (_tableColumns.length != expectedColumnCount) {
            _tableColumns = [
              _DBTableColumn(
                index: 0,
                width: 56.0,
                freezePriority: 100,
                sticky: true,
              ),
              for (var i = 0; i < columns.length; i++)
                _DBTableColumn(index: i + 1, width: i == 0 ? 160.0 : 140.0),
              _DBTableColumn(index: -1, width: 48.0, freezePriority: 100),
            ];
            _columnOrder = List<int>.generate(columns.length, (i) => i);
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: ExcludeSemantics(
              child: TableView.builder(
                style: TableViewStyle(
                  dividers: TableViewDividersStyle(
                    vertical: TableViewVerticalDividersStyle.symmetric(
                      TableViewVerticalDividerStyle(
                        wiggleCount: 3,
                        wiggleOffset: 6.0,
                        wiggleInterval: 44.0,
                      ),
                    ),
                  ),
                  scrollbars: const TableViewScrollbarsStyle.symmetric(
                    TableViewScrollbarStyle(
                      interactive: true,
                      enabled: TableViewScrollbarEnabled.always,
                      thumbVisibility: WidgetStatePropertyAll(true),
                      trackVisibility: WidgetStatePropertyAll(true),
                    ),
                  ),
                ),
                columns: _tableColumns,
                headerHeight: 44.0,
                headerBuilder: (context, contentBuilder) {
                  return contentBuilder(context, (ctx, cIndex) {
                    final colIndex =
                        (_tableColumns[cIndex] as _DBTableColumn).index;
                    return Container(
                      height: 44.0,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(bottom: Divider.createBorderSide(ctx)),
                      ), 
                      child: Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                switch (colIndex) {
                                  case 0:
                                    return Checkbox(
                                      value:
                                          selection.isEmpty
                                              ? false
                                              : (selection.length ==
                                                      _controller.datas.length
                                                  ? true
                                                  : null),
                                      tristate: true,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selection
                                              ..clear()
                                              ..addAll(
                                                List<int>.generate(
                                                  _controller.datas.length,
                                                  (i) => i,
                                                ),
                                              );
                                          } else {
                                            selection.clear();
                                          }
                                        });
                                      },
                                    );
                                  case -1:
                                    return Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              _createColumnControlsRoute(
                                                ctx,
                                                cIndex,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  default:
                                    final dbPos = cIndex - 1;
                                    if (dbPos < 0 ||
                                        dbPos >= _columnOrder.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          _createColumnControlsRoute(
                                            ctx,
                                            cIndex,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        columns[_columnOrder[dbPos]]
                                            .columnName(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                }
                              },
                            ),
                          ),
                          if (colIndex != -1)
                            SizedBox(
                              width: 12.0,
                              height: double.infinity,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    final current = _tableColumns[cIndex];
                                    final newWidth =
                                        current.width + details.delta.dx;
                                    final clamped = newWidth.clamp(48.0, 400.0);
                                    _tableColumns[cIndex] = current.copyWith(
                                      width: clamped,
                                    );
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  });
                },
                footerHeight: 44.0,
                footerBuilder: (context, contentBuilder) {
                  return contentBuilder(context, (ctx, cIndex) {
                    final colIndex =
                        (_tableColumns[cIndex] as _DBTableColumn).index;
                    if (colIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('${selection.length}'),
                      );
                    }
                    if (colIndex == -1) {
                      return const SizedBox.shrink();
                    }
                    return const SizedBox.shrink();
                  });
                },
                rowCount: _controller.datas.length,
                rowHeight: 44.0,
                rowBuilder: (context, row, contentBuilder) {
                  final dataIndex = row;
                  Widget cellBuilder(BuildContext context, int cIndex) {
                    final colIndex =
                        (_tableColumns[cIndex] as _DBTableColumn).index;
                    if (colIndex == 0) {
                      return Checkbox(
                        value: selection.contains(dataIndex),
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              selection.add(dataIndex);
                            } else {
                              selection.remove(dataIndex);
                            }
                          });
                        },
                      );
                    }
                    if (colIndex == -1) {
                      return ReorderableDragStartListener(
                        index: dataIndex,
                        child: const SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Icon(Icons.drag_indicator),
                        ),
                      );
                    }
                    final dbPos = cIndex - 1;
                    if (dbPos < 0 || dbPos >= _columnOrder.length) {
                      return const SizedBox.shrink();
                    }
                    final mappedIndex = _columnOrder[dbPos];
                    String data = "";
                    if (_controller.currentDatabaseType ==
                            DatabaseType.sqlite ||
                        _controller.currentDatabaseType == DatabaseType.hive) {
                      dynamic value;
                      try {
                        value =
                            _controller.datas[dataIndex][columns[mappedIndex]
                                .columnName()];
                      } catch (_) {
                        value = null;
                      }
                      data = value == null ? '' : value.toString();
                    } else if (_controller.currentDatabaseType ==
                        DatabaseType.sharedPreferences) {
                      try {
                        final colName = columns[mappedIndex].columnName();
                        if (colName == 'key') {
                          data =
                              _controller.datas[dataIndex].keys.isEmpty
                                  ? ''
                                  : _controller.datas[dataIndex].keys.first;
                        } else {
                          data =
                              _controller.datas[dataIndex].values.isEmpty
                                  ? ''
                                  : _controller.datas[dataIndex].values.first
                                      .toString();
                        }
                      } catch (_) {
                        data = '';
                      }
                    }

                    if (tableData is HiveTableData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(data, overflow: TextOverflow.ellipsis),
                      );
                    }
 
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        data == 'null' ? '' : data,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    );
                  }

                  var rowContent = contentBuilder(context, cellBuilder);
                  final selectedRow = selection.contains(row);
                  return KeyedSubtree(
                    key: ObjectKey(_controller.datas[row]),
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: Divider.createBorderSide(context),
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selection.clear();
                              selection.add(row);
                            });
                          },
                          child: Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withAlpha(selectedRow ? 0x18 : 0),
                            child: rowContent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                // bodyContainerBuilder intentionally omitted: using outer RefreshIndicator
                rowReorder: TableRowReorder(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < 0 ||
                          oldIndex >= _controller.datas.length) {
                        return;
                      }
                      if (newIndex < 0 ||
                          newIndex >= _controller.datas.length) {
                        return;
                      }
                      final moved = _controller.datas.removeAt(oldIndex);
                      _controller.datas.insert(newIndex, moved);
                    });
                  },
                ),
                bodyContainerBuilder: (context, body) => RefreshIndicator.adaptive(
                  onRefresh: () async {
                    await _updateTableSelect(
                      _controller.tableDatas[_controller.currentTableIndex],
                    );
                  },
                  child: body,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //builder list widget
  Widget buildList() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(6),
          sliver: SliverFixedExtentList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return AnimatedScale(
                scale: 100,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedDefaultTextStyle(
                    child: Text(
                      _controller.databaseManager.databases[index].databaseName,
                    ),
                    style: const TextStyle(fontSize: 50, color: Colors.black),
                    duration: const Duration(milliseconds: 300),
                  ),
                ),
              );
            }, childCount: _controller.databaseManager.databases.length),
            itemExtent: 300,
          ),
        ),
      ],
    );
  }

  ModalRoute<void> _createColumnControlsRoute(
    BuildContext cellBuildContext,
    int columnIndex,
  ) {
    return TableColumnControlHandlesPopupRoute.realtime(
      controlCellBuildContext: cellBuildContext,
      columnIndex: columnIndex,
      tableViewChanged: null,
      onColumnTranslate: (index, newTranslation) {
        setState(() {
          _tableColumns[index] = _tableColumns[index].copyWith(
            translation: newTranslation,
          );
        });
      },
      onColumnResize: (index, newWidth) {
        setState(() {
          _tableColumns[index] = _tableColumns[index].copyWith(width: newWidth);
        });
      },
      onColumnMove: (fromIndex, toIndex) {
        setState(() {
          if (fromIndex < 0 || fromIndex >= _tableColumns.length) return;
          if (toIndex < 0 || toIndex >= _tableColumns.length) return;
          final moved = _tableColumns.removeAt(fromIndex);
          _tableColumns.insert(toIndex, moved);
          // update only data columns (exclude leading 0 and trailing -1)
          final lastIndex = _tableColumns.length - 1;
          if (fromIndex > 0 &&
              fromIndex < lastIndex &&
              toIndex > 0 &&
              toIndex < lastIndex) {
            final fromData = fromIndex - 1;
            final toData = toIndex - 1;
            if (fromData >= 0 &&
                toData >= 0 &&
                fromData < _columnOrder.length &&
                toData < _columnOrder.length) {
              final movedOrder = _columnOrder.removeAt(fromData);
              _columnOrder.insert(toData, movedOrder);
            }
          }
        });
      },
    );
  }
}
