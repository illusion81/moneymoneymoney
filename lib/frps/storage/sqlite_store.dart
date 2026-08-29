import 'dart:convert';

import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/user.dart';
import 'package:sqflite/sqflite.dart';

import 'repository.dart';

class SqliteStore implements FrpsRepository {
  SqliteStore({DatabaseFactory? factory, String? path})
      : _factory = factory ?? databaseFactory,
        _path = path ?? 'frps.db';

  final DatabaseFactory _factory;
  final String _path;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _factory.openDatabase(
      _path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createTables,
      ),
    );
    return _db!;
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        date TEXT,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        date TEXT,
        data TEXT
      )
    ''');
  }

  @override
  Future<void> saveUser(User user) async {
    final db = await _database;
    await db.insert(
      'users',
      {'id': user.id, 'data': jsonEncode(user.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<User?> getUser(String id) async {
    final db = await _database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromJson(jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
  }

  @override
  Future<void> saveResponse(QuestionResponse response) async {
    final db = await _database;
    await db.insert('responses', {
      'user_id': response.userId,
      'data': jsonEncode(response.toJson()),
    });
  }

  @override
  Future<List<QuestionResponse>> responsesFor(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'responses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id',
    );
    return rows
        .map((row) =>
            QuestionResponse.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveSnapshot(FinancialSnapshot snapshot) async {
    final db = await _database;
    await db.insert('snapshots', {
      'user_id': snapshot.userId,
      'date': snapshot.date.toIso8601String(),
      'data': jsonEncode(snapshot.toJson()),
    });
  }

  @override
  Future<FinancialSnapshot?> latestSnapshot(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'snapshots',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FinancialSnapshot.fromJson(
        jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
  }

  @override
  Future<void> saveReport(Report report) async {
    final db = await _database;
    await db.insert('reports', {
      'user_id': report.userId,
      'date': report.date.toIso8601String(),
      'data': jsonEncode(report.toJson()),
    });
  }

  @override
  Future<Report?> latestReport(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'reports',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Report.fromJson(jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
  }
}
