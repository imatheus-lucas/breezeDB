abstract class Condition {
  bool evaluate(Map<String, dynamic> row);
}

class Query {
  final List<Condition> conditions = [];
  String? _sortingColumn;
  bool _sortAscending = true;

  bool get sortAscending => _sortAscending;
  String? get sortingColumn => _sortingColumn;

  Query where(Condition condition) {
    conditions.add(condition);
    return this;
  }

  bool evaluate(Map<String, dynamic> row) {
    for (var condition in conditions) {
      if (!condition.evaluate(row)) {
        return false;
      }
    }
    return true;
  }

  Query sortBy(String column, {bool ascending = true}) {
    _sortingColumn = column;
    _sortAscending = ascending;
    return this;
  }
}

class Eq extends Condition {
  final String column;
  final dynamic value;

  Eq(this.column, this.value);

  @override
  bool evaluate(Map<String, dynamic> row) {
    return row[column] == value;
  }
}

class Gt extends Condition {
  final String column;
  final num value;

  Gt(this.column, this.value);

  @override
  bool evaluate(Map<String, dynamic> row) {
    return (row[column] as num? ?? double.negativeInfinity) > value;
  }
}

class Lt extends Condition {
  final String column;
  final num value;

  Lt(this.column, this.value);

  @override
  bool evaluate(Map<String, dynamic> row) {
    return (row[column] as num? ?? double.infinity) < value;
  }
}

/// Suport to 'not equal'
class Ne extends Condition {
  final String column;
  final dynamic value;

  Ne(this.column, this.value);

  @override
  bool evaluate(Map<String, dynamic> row) {
    return row[column] != value;
  }
}

class And extends Condition {
  final Condition left;
  final Condition right;

  And(this.left, this.right);

  @override
  bool evaluate(Map<String, dynamic> row) {
    return (left.evaluate(row) && right.evaluate(row));
  }
}

class Or extends Condition {
  final Condition left;
  final Condition right;

  Or(this.left, this.right);

  @override
  bool evaluate(Map<String, dynamic> row) {
    return (left.evaluate(row) || right.evaluate(row));
  }
}
