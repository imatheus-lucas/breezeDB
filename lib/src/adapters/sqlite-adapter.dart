import 'dart:convert';
import 'dart:io';

import 'package:breezedb/src/constants.dart';
import 'package:breezedb/src/query_builder.dart';
import 'package:breezedb/src/type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class SqliteAdapter implements BreezeDbAdapter {
  static Database? _db;
  static bool _initialized = false;
  final List<Transaction> _transactionStack = [];

  // Cache em memória
  static final Map<String, Map<String, Map<String, dynamic>>> _memoryCache = {};
  static final Map<String, dynamic> _valuesCache = {};

  SqliteAdapter() {
    assert(
      _initialized,
      'Database not initialized. Call SqliteAdapter.initialize() first',
    );
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    // Configuração multiplataforma
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else {
      databaseFactory = databaseFactoryFfiWeb;
    }

    _db = await databaseFactory.openDatabase(
      DEFAULT_TABLE_NAME,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );

    // Carrega dados iniciais no cache
    final results = await _db!.query(DEFAULT_TABLE_NAME_STORE);
    _loadDataIntoCache(results);

    _initialized = true;
  }

  static void _loadDataIntoCache(List<Map<String, dynamic>> results) {
    _memoryCache.clear();
    _valuesCache.clear();

    for (final row in results) {
      final table = row['table_name'].toString();
      final rowId = row['row_id'].toString();
      final data = jsonDecode(row['data'] as String);

      if (table == '_values') {
        _valuesCache[rowId] = data;
      } else {
        _memoryCache.putIfAbsent(table, () => {});
        _memoryCache[table]![rowId] = data;
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $DEFAULT_TABLE_NAME_STORE (
        table_name TEXT,
        row_id TEXT,
        data TEXT,
        PRIMARY KEY (table_name, row_id)
      );
    ''');
  }

  DatabaseExecutor _getActiveDatabase() {
    return _transactionStack.isNotEmpty ? _transactionStack.last : _db!;
  }

  @override
  int count(String tableName, Query query) {
    return this.query(tableName, query).length;
  }

  @override
  void delCell(String tableName, String rowId, String cellId) {
    final row = getRow(tableName, rowId);
    row.remove(cellId);
    setRow(tableName, rowId, row);
  }

  @override
  void delRow(String tableName, String rowId) {
    _memoryCache[tableName]?.remove(rowId);
    _getActiveDatabase().execute(
      'DELETE FROM $DEFAULT_TABLE_NAME_STORE WHERE table_name = ? AND row_id = ?',
      [tableName, rowId],
    );
  }

  @override
  void delTable(String tableName) {
    _memoryCache.remove(tableName);
    _getActiveDatabase().execute(
      'DELETE FROM $DEFAULT_TABLE_NAME_STORE WHERE table_name = ?',
      [tableName],
    );
  }

  @override
  void delValue(String key) {
    _valuesCache.remove(key);
    _getActiveDatabase().execute(
      'DELETE FROM $DEFAULT_TABLE_NAME_STORE WHERE table_name = ? AND row_id = ?',
      ['_values', key],
    );
  }

  @override
  dynamic getCell(String tableName, String rowId, String cellId) {
    return getRow(tableName, rowId)[cellId];
  }

  @override
  List<String> getCellIds(String tableName, String rowId) {
    return getRow(tableName, rowId).keys.toList();
  }

  @override
  Map<String, dynamic> getRow(String tableName, String rowId) {
    return _memoryCache[tableName]?[rowId] ?? {};
  }

  @override
  List<String> getRowIds(String tableName) {
    return _memoryCache[tableName]?.keys.toList() ?? [];
  }

  @override
  Map<String, dynamic> getTable(String tableName) {
    return _memoryCache[tableName] ?? {};
  }

  @override
  dynamic getTableIds(String tableName) {
    return _memoryCache[tableName]?.keys.toList() ?? [];
  }

  @override
  Map<String, Map<String, dynamic>> getTables() {
    return Map.from(_memoryCache);
  }

  @override
  dynamic getValue(String key) {
    return _valuesCache[key];
  }

  @override
  Map<String, dynamic> getValues() {
    return Map.from(_valuesCache);
  }

  @override
  bool hasCell(String tableName, String rowId, String cellId) {
    return getRow(tableName, rowId).containsKey(cellId);
  }

  @override
  bool hasRow(String tableName, String rowId) {
    return _memoryCache[tableName]?.containsKey(rowId) ?? false;
  }

  @override
  bool hasTable(String tableName) {
    return _memoryCache.containsKey(tableName);
  }

  @override
  bool hasValue(String key) {
    return _valuesCache.containsKey(key);
  }

  @override
  Map<String, Map<String, dynamic>> query(String tableName, Query query) {
    final tableData = getTable(tableName);

    Map<String, Map<String, dynamic>> results = {};

    for (var row in tableData.entries) {
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
  void setCell(String tableName, String rowId, String cellId, dynamic value) {
    final row = getRow(tableName, rowId);
    row[cellId] = value;
    setRow(tableName, rowId, row);
  }

  @override
  void setRow(String tableName, String rowId, Map<String, dynamic> row) {
    _memoryCache.putIfAbsent(tableName, () => {});
    _memoryCache[tableName]![rowId] = Map.from(row);

    final dataJson = jsonEncode(row);
    _getActiveDatabase().execute(
      '''
      INSERT OR REPLACE INTO $DEFAULT_TABLE_NAME_STORE (table_name, row_id, data)
      VALUES (?, ?, ?);
      ''',
      [tableName, rowId, dataJson],
    );
  }

  @override
  void setTable(String tableName, Map<String, dynamic> table) {
    _memoryCache[tableName] = Map.from(table);
    for (final entry in table.entries) {
      setRow(tableName, entry.key, entry.value);
    }
  }

  @override
  void setTables(Map<String, Map<String, dynamic>> newTables) {
    for (final entry in newTables.entries) {
      setTable(entry.key, entry.value);
    }
  }

  @override
  void setValues(Map<String, dynamic> newValues) {
    _valuesCache.addAll(newValues);
    for (final entry in newValues.entries) {
      _getActiveDatabase().execute(
        '''
        INSERT OR REPLACE INTO $DEFAULT_TABLE_NAME_STORE (table_name, row_id, data)
        VALUES (?, ?, ?);
        ''',
        ['_values', entry.key, jsonEncode(entry.value)],
      );
    }
  }

  @override
  num sum(String tableName, Query query, String column) {
    final filtered = this.query(tableName, query);
    return filtered.values.fold(0, (sum, row) {
      final value = row[column] is num ? row[column] : 0;
      return sum + value;
    });
  }

  @override
  void transaction(void Function() operations) {
    _db?.transaction((txn) async {
      _transactionStack.add(txn);
      try {
        operations();
        _transactionStack.removeLast();
      } catch (e) {
        _transactionStack.clear();
        rethrow;
      }
    });
  }
}
