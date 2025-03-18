import 'package:breezedb/src/query_builder.dart';

typedef VoidCallback = void Function();

abstract class BreezeDbAdapter {
  // Operações CRUD Básicas
  void setRow(String tableName, String rowId, Map<String, dynamic> row);
  void setValues(Map<String, dynamic> newValues);
  void setTable(String tableName, Map<String, dynamic> table);
  void setCell(String tableName, String rowId, String cellId, dynamic value);
  void setTables(Map<String, Map<String, dynamic>> newTables);

  // Operações de Exclusão
  void delValue(String key);
  void delTable(String tableName);
  void delRow(String tableName, String rowId);
  void delCell(String tableName, String rowId, String cellId);

  // Métodos de Recuperação de Dados
  Map<String, Map<String, dynamic>> getTables();
  Map<String, dynamic> getTable(String tableName);
  Map<String, dynamic> getValues();
  dynamic getValue(String key);
  Map<String, dynamic> getRow(String tableName, String rowId);
  dynamic getCell(String tableName, String rowId, String cellId);

  // Métodos de Verificação
  bool hasTable(String tableName);
  bool hasRow(String tableName, String rowId);
  bool hasCell(String tableName, String rowId, String cellId);
  bool hasValue(String key);

  // Métodos de IDs
  dynamic getTableIds(String tableName);
  dynamic getRowIds(String tableName);
  dynamic getCellIds(String tableName, String rowId);

  // Transações
  void transaction(void Function() operations);

  // Métodos de Consulta
  Map<String, Map<String, dynamic>> query(String tableName, Query query);
  int count(String tableName, Query query);
  num sum(String tableName, Query query, String column);
}
