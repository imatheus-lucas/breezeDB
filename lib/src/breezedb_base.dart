import 'package:breezedb/src/query_builder.dart';
import 'package:breezedb/src/type.dart';

typedef VoidCallback = void Function();

class BreezeDb {
  final List<VoidCallback> _listeners = [];

  final BreezeDbAdapter adapter;

  BreezeDb({required this.adapter});

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  setRow(String tableName, String rowId, Map<String, dynamic> row) {
    adapter.setRow(tableName, rowId, row);
    _notifyListeners();
  }

  void setValues(Map<String, dynamic> newValues) {
    adapter.setValues(newValues);
    _notifyListeners();
  }

  void setTable(String tableName, Map<String, dynamic> table) {
    adapter.setTable(tableName, table);
    _notifyListeners();
  }

  void setCell(String tableName, String rowId, String cellId, dynamic value) {
    adapter.setCell(tableName, rowId, cellId, value);
    _notifyListeners();
  }

  void setTables(Map<String, Map<String, dynamic>> newTables) {
    adapter.setTables(newTables);
    _notifyListeners();
  }

  void delValue(String key) {
    adapter.delValue(key);
    _notifyListeners();
  }

  void delTable(String tableName) {
    adapter.delTable(tableName);
    _notifyListeners();
  }

  void delRow(String tableName, String rowId) {
    adapter.delRow(tableName, rowId);
    _notifyListeners();
  }

  void delCell(String tableName, String rowId, String cellId) {
    adapter.delCell(tableName, rowId, cellId);
    _notifyListeners();
  }

  Map<String, Map<String, dynamic>> getTables() {
    return adapter.getTables();
  }

  Map<String, dynamic> getTable(String tableName) {
    return adapter.getTable(tableName);
  }

  Map<String, dynamic> getValues() {
    return adapter.getValues();
  }

  dynamic getValue(String key) {
    return adapter.getValue(key);
  }

  Map<String, dynamic> getRow(String tableName, String rowId) {
    return adapter.getRow(tableName, rowId);
  }

  dynamic getCell(String tableName, String rowId, String cellId) {
    return adapter.getCell(tableName, rowId, cellId);
  }

  bool hasTable(String tableName) {
    return adapter.hasTable(tableName);
  }

  bool hasRow(String tableName, String rowId) {
    return adapter.hasRow(tableName, rowId);
  }

  bool hasCell(String tableName, String rowId, String cellId) {
    return adapter.hasCell(tableName, rowId, cellId);
  }

  bool hasValue(String key) {
    return adapter.hasValue(key);
  }

  dynamic getTableIds(String tableName) {
    return adapter.getTableIds(tableName);
  }

  dynamic getRowIds(String tableName) {
    return adapter.getRowIds(tableName);
  }

  dynamic getCellIds(String tableName, String rowId) {
    return adapter.getCellIds(tableName, rowId);
  }

  void transaction(void Function() operations) {
    adapter.transaction(operations);
  }

  Map<String, Map<String, dynamic>> query(String tableName, Query query) {
    return adapter.query(tableName, query);
  }

  int count(String tableName, Query query) {
    return adapter.count(tableName, query);
  }

  num sum(String tableName, Query query, String column) {
    return adapter.sum(tableName, query, column);
  }
}
