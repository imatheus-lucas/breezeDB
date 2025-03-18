# BreezeDB: A Lightweight NoSQL Database for Flutter and Dart


[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**BreezeDB** is a simple, lightweight, and easy-to-use NoSQL database for Flutter and Dart applications. It's designed for scenarios where you need a local database solution without the complexity of setting up and managing a full-fledged database system. BreezeDB offers:

*   **Simplicity:**  Easy to learn and use API.
*   **Lightweight:** Minimal footprint, ideal for mobile and resource-constrained environments.
*   **NoSQL:** Document-based storage, flexible schema.
*   **Adapters:** Supports different storage adapters:
    *   **InMemoryAdapter:** For fast, in-memory storage (data is lost when the app closes). Ideal for testing or caching.
    *   **SqliteAdapter:** For persistent storage using SQLite (data is saved across app sessions).
*   **Query Builder:**  A fluent and expressive query builder to filter and sort your data.
*   **Transactions:** Support for transactions to ensure data integrity.
*   **Reactivity:**  Built-in listener mechanism for reactive updates in Flutter apps.

## Getting Started

### Installation

Add `breezedb` to your `pubspec.yaml` file:

```yaml
dependencies:
  breezedb: ^0.0.1 # Use the latest version from pub.dev
```

### Initialization

Before using BreezeDB, you need to initialize the desired adapter. For SqliteAdapter, you need to call SqliteAdapter.initialize() once in your application's initialization phase (e.g., in main() before running your app).


```dart
import 'package:tidydb/sqlite_adapter.dart';
import 'package:tidydb/breezedb.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Flutter plugins
  await SqliteAdapter.initialize(); // Initialize SqliteAdapter

  final db = BreezeDb(adapter: SqliteAdapter()); // Create BreezeDb instance with SqliteAdapter

  // ... your app code ...

  runApp(MyApp());
}
```

For InMemoryAdapter, no initialization is needed. You can directly create a BreezeDb instance:

```dart
final db = BreezeDb(adapter: InMemoryAdapter()); // Create BreezeDb instance with InMemoryAdapter
```

## Core Concepts

### BreezeDb

The main class to interact with your database. It provides methods for:

*   Setting and getting values, rows, and tables.
*   Deleting data.
*   Querying data.
*   Managing transactions.
*   Adding listeners for reactive updates.

### BreezeDbAdapter

An abstract class defining the interface for storage adapters. You can implement your own adapters if needed. BreezeDb comes with two built-in adapters:

*   InMemoryAdapter: Stores data in memory. Fast but non-persistent.
*   SqliteAdapter: Stores data persistently using SQLite.

### Condition

An abstract class representing a condition for filtering data in queries. BreezeDb provides several built-in condition classes:

*   **Eq**: Equal to (==)
*   **Ne**: Not equal to (!=)
*   **Gt**: Greater than (>)
*   **Lt**: Less than (<)
*   **And**: Logical AND (&&)
*   **Or**: Logical OR (||)


## Usage Examples
### Setting and Getting Values

```dart
db.setValues({'theme': 'dark', 'language': 'en'});
print(db.getValues()); // Output: {theme: dark, language: en}
print(db.getValue('theme')); // Output: dark

db.setValue('theme', 'light');
print(db.getValue('theme')); // Output: light
```

Setting and Getting Rows and Tables
```dart
// Set rows in the 'users' table
db.setRow('users', 'john123', {'name': 'John Doe', 'age': 30, 'city': 'New York'});
db.setRow('users', 'alice456', {'name': 'Alice Smith', 'age': 25, 'city': 'London'});

// Get a row
print(db.getRow('users', 'john123')); // Output: {name: John Doe, age: 30, city: New York}

// Get the entire 'users' table
print(db.getTable('users'));
/* Output:
{
  john123: {name: John Doe, age: 30, city: New York},
  alice456: {name: Alice Smith, age: 25, city: London}
}
*/

// Set a table directly (overwrites existing table)
db.setTable('products', {
  'product1': {'name': 'Laptop', 'price': 1200},
  'product2': {'name': 'Mouse', 'price': 25},
});
```


## Querying Data with Query

### Filter and sort data using the queries:

```dart
// Example data setup (if not already set)
db.setRow('users', 'john123', {'name': 'John Doe', 'age': 30, 'city': 'New York'});
db.setRow('users', 'alice456', {'name': 'Alice Smith', 'age': 25, 'city': 'London'});
db.setRow('users', 'bob789', {'name': 'Bob Johnson', 'age': 35, 'city': 'New York'});

// Query users older than 28, sorted by age in ascending order
final query = Query()
  .where(Gt('age', 28))
  .sortBy('age', ascending: true);

final results = db.query('users', query);
print(results);
/* Output (order may vary slightly depending on internal map order):
{
  john123: {name: John Doe, age: 30, city: New York},
  bob789: {name: Bob Johnson, age: 35, city: New York}
}
*/

// Query users named "Alice" OR older than 30
final orQuery = Query()
  .where(Or(Eq('name', 'Alice Smith'), Gt('age', 30)));
final orResults = db.query('users', orQuery);
print(orResults);
/* Output:
{
  alice456: {name: Alice Smith, age: 25, city: London},
  bob789: {name: Bob Johnson, age: 35, city: New York}
}
*/

// Count users younger than 30
final countQuery = Query().where(Lt('age', 30)).count();
int count = db.count('users', countQuery);
print('Count of users younger than 30: $count'); // Output: Count of users younger than 30: 1

// Sum of ages of users in New York
final sumQuery = Query().where(Eq('city', 'New York'));
num sumOfAges = db.sum('users', sumQuery, 'age');
print('Sum of ages in New York: $sumOfAges'); // Output: Sum of ages in New York: 65
```

## Reactive Updates with addListener (Flutter)
```dart
import 'package:flutter/material.dart';
import 'package:breezedb/query_builder.dart';
import 'package:breezedb/sqlite_adapter.dart';
import 'package:breezedb/breezedb.dart';

class UserListWidget extends StatefulWidget {
  @override
  _UserListWidgetState createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  final db = BreezeDb(adapter: SqliteAdapter()); // Or InMemoryAdapter
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    db.addListener(_dataChangeListener); // Add listener
    _loadUsers(); // Initial load
  }

  @override
  void dispose() {
    db.removeListener(_dataChangeListener); // Important: Remove listener on dispose
    super.dispose();
  }

  void _dataChangeListener() {
    _loadUsers(); // Reload data when BreezeDB notifies changes
  }

  _loadUsers() async {
    final userMap = db.getTable('users');
    setState(() {
      users = userMap.values.toList();
    });
  }

  _addUser(String name, int age) {
    final rowId = DateTime.now().millisecondsSinceEpoch.toString();
    db.setRow('users', rowId, {'name': name, 'age': age});
    // No need to call _loadUsers() here, listener will trigger update
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _addUser('New User', 28),
          child: Text('Add New User'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(title: Text('Name: ${user['name']}, Age: ${user['age']}'));
            },
          ),
        ),
      ],
    );
  }
}
```


## Transactions

```dart
try {
  db.transaction(() {
    db.setRow('accounts', 'acc123', {'balance': 100});
    db.setRow('accounts', 'acc456', {'balance': 50});

    // Simulate an error (e.g., invalid operation)
    if (true) {
      throw Exception('Simulated transaction error');
    }

    db.setCell('accounts', 'acc123', 'balance', 200); // This will not be executed if transaction fails
  });
} catch (e) {
  print('Transaction failed: $e');
  // Transaction will be rolled back, no changes will be saved.
}
```

## Conclusion
BreezeDB offers a straightforward and efficient way to manage local data in Flutter and Dart applications. Its simple API, adapter-based architecture, query builder, and reactivity features make it a valuable tool for various use cases.

Contributions are welcome! If you find issues or have suggestions for improvements, please feel free to open issues or pull requests on the GitHub repository. 

License: MIT License