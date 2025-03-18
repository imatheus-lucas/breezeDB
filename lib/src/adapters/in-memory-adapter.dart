import 'package:breezedb/src/query_builder.dart';
import 'package:breezedb/src/type.dart';

class InMemoryAdapter implements BreezeDbAdapter {
  final Map<String, Map<String, dynamic>> tables = {};
  final Map<String, dynamic> values = {};

  final List<Map<String, dynamic>> _transactionHistory = [];

  @override
  int count(String tableName, Query query) {
    return this.query(tableName, query).length;
  }

  @override
  void delCell(String tableName, String rowId, String cellId) {
    tables[tableName]![rowId]!.remove(cellId);
  }

  @override
  void delRow(String tableName, String rowId) {
    tables[tableName]!.remove(rowId);
  }

  @override
  void delTable(String tableName) {
    tables.remove(tableName);
  }

  @override
  void delValue(String key) {
    values.remove(key);
  }

  @override
  getCell(String tableName, String rowId, String cellId) {
    return tables[tableName]![rowId]![cellId];
  }

  @override
  getCellIds(String tableName, String rowId) {
    return tables[tableName]![rowId]!.keys;
  }

  @override
  Map<String, dynamic> getRow(String tableName, String rowId) {
    return tables[tableName]![rowId] ??= {};
  }

  @override
  getRowIds(String tableName) {
    return tables[tableName]!.keys;
  }

  @override
  Map<String, dynamic> getTable(String tableName) {
    return tables[tableName] ??= {};
  }

  @override
  getTableIds(String tableName) {
    return tables[tableName]!.keys;
  }

  @override
  Map<String, Map<String, dynamic>> getTables() {
    return tables;
  }

  @override
  getValue(String key) {
    return values[key];
  }

  @override
  Map<String, dynamic> getValues() {
    return Map.from(values);
  }

  @override
  bool hasCell(String tableName, String rowId, String cellId) {
    return tables[tableName]![rowId]!.containsKey(cellId);
  }

  @override
  bool hasRow(String tableName, String rowId) {
    return tables[tableName]!.containsKey(rowId);
  }

  @override
  bool hasTable(String tableName) {
    return tables.containsKey(tableName);
  }

  @override
  bool hasValue(String key) {
    return values.containsKey(key);
  }

  @override
  Map<String, Map<String, dynamic>> query(String tableName, Query query) {
    final table = tables[tableName] ?? {};

    Map<String, Map<String, dynamic>> results = {};

    for (var row in table.entries) {
      final rowId = row.key;
      final rowData = row.value;

      if (query.evaluate(rowData)) {
        results[rowId] = rowData;
      }
    }
    if (query.sortingColumn != null) {
      final sortedEntries = results.entries.toList()
        ..sort((a, b) {
          var aValue = a.value[query.sortingColumn];
          var bValue = b.value[query.sortingColumn];

          if (aValue is Comparable && bValue is Comparable) {
            return query.sortAscending
                ? aValue.compareTo(bValue)
                : bValue.compareTo(aValue);
          }
          return 0;
        });

      results = Map.fromEntries(sortedEntries);
    }
    return results;
  }

  @override
  void setCell(String tableName, String rowId, String cellId, value) {
    if (!tables.containsKey(tableName) ||
        !tables[tableName]!.containsKey(rowId)) {
      throw Exception('Record "$rowId" does not exist in table "$tableName".');
    }
    tables[tableName]![rowId]![cellId] = value;
  }

  @override
  void setRow(String tableName, String rowId, Map<String, dynamic> row) {
    final table = tables[tableName] ??= {};
    table[rowId] = row;
  }

  @override
  void setTable(String tableName, Map<String, dynamic> table) {
    tables[tableName] = table;
  }

  @override
  void setTables(Map<String, Map<String, dynamic>> newTables) {
    tables.addAll(newTables);
  }

  @override
  void setValues(Map<String, dynamic> newValues) {
    values.addAll(newValues);
  }

  @override
  num sum(String tableName, Query query, String column) {
    num sum = 0;
    for (var row in this.query(tableName, query).values) {
      sum += row[column];
    }
    return sum;
  }

  void rollback() {
    if (_transactionHistory.isNotEmpty) {
      final lastState = _transactionHistory.removeLast();
      tables.clear();
      tables.addAll(lastState['tables']);
      values.clear();
      values.addAll(lastState['values']);
    }
  }

  @override
  void transaction(void Function() operations) {
    _transactionHistory.add({
      'tables': Map.from(tables),
      'values': Map.from(values),
    });

    try {
      operations();
    } catch (e) {
      rollback();
      throw Exception('Transaction failed: $e');
    }
  }
}
