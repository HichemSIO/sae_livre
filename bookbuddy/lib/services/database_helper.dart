import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/user_interaction.dart'; // Importe UserInteraction et PerformanceMetric

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String tableBooks = 'books';
  static const String tableInteractions = 'interactions';
  static const String tableMetrics = 'metrics';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bookbuddy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const realNull = 'REAL';

    // 1. Table des Livres (Catalogue)
    await db.execute('''
CREATE TABLE $tableBooks ( 
  id $idType, 
  titre $textType,
  auteur $textType,
  genre $textType,
  note_moyenne $realType,
  description $textType,
  image_url $textType
)
''');

    // 2. Table des Interactions (Historique utilisateur)
    await db.execute('''
CREATE TABLE $tableInteractions ( 
  id $idType, 
  book_id $intType,
  action_type $textType,
  rating INTEGER, 
  timestamp $textType
)
''');

    // 3. Table des Métriques (Performance)
    await db.execute('''
CREATE TABLE $tableMetrics ( 
  id $idType, 
  operation_type $textType,
  duration_ms $intType,
  cpu_usage $realNull,
  memory_usage $realNull,
  timestamp $textType
)
''');
    
    await _loadInitialBooks(db);
  }

  /// Charge le catalogue de livres depuis le JSON et les insère
  Future<void> _loadInitialBooks(Database db) async {
    final String jsonString = await rootBundle.loadString('assets/data/books.json');
    final List<dynamic> jsonList = json.decode(jsonString);

    final batch = db.batch();
    for (int i = 0; i < jsonList.length; i++) {
        final book = Book.fromJson(jsonList[i]).copyWith(id: i + 1); 
        batch.insert(tableBooks, book.toMap());
    }
    await batch.commit(noResult: true);
  }


  // --- CRUD BASIQUE ---

  Future<List<Book>> getAllBooks() async {
    final db = await instance.database;
    final result = await db.query(tableBooks);
    return result.map((json) => Book.fromMap(json)).toList();
  }

  Future<Book?> getBookById(int id) async {
    final db = await instance.database;
    final result = await db.query(tableBooks, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Book.fromMap(result.first) : null;
  }

  Future<List<UserInteraction>> getAllInteractions() async {
    final db = await instance.database;
    final result = await db.query(tableInteractions);
    return result.map((json) => UserInteraction.fromMap(json)).toList();
  }

  Future<void> insertInteraction(UserInteraction interaction) async {
    final db = await instance.database;
    await db.insert(tableInteractions, interaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<void> insertMetric(PerformanceMetric metric) async {
    final db = await instance.database;
    await db.insert(tableMetrics, metric.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<List<PerformanceMetric>> getMetrics() async {
      final db = await instance.database;
      final result = await db.query(tableMetrics);
      return result.map((json) => PerformanceMetric.fromMap(json)).toList(); 
  }

  // --- LOGIQUE MÉTIER SPÉCIFIQUE ---

  Future<List<Book>> getFavoriteBooks() async {
    final db = await instance.database;
    // Sélectionner les IDs de livre marqués comme 'favorite'
    final favInteractions = await db.query(
      tableInteractions,
      columns: ['book_id'],
      where: 'action_type = ?',
      whereArgs: ['favorite'],
    );
    
    // Récupérer les IDs uniques
    final uniqueBookIds = favInteractions.map((i) => i['book_id'] as int).toSet().toList();
    
    if (uniqueBookIds.isEmpty) return [];

    // Récupérer les détails des livres
    final books = await db.query(
      tableBooks,
      where: 'id IN (${List.filled(uniqueBookIds.length, '?').join(', ')})',
      whereArgs: uniqueBookIds,
    );
    return books.map((json) => Book.fromMap(json)).toList();
  }
  
  Future<bool> isFavorite(int bookId) async {
    final db = await instance.database;
    final count = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableInteractions WHERE book_id = ? AND action_type = ?',
      [bookId, 'favorite']
    );
    // Vérifie si le count est supérieur à 0
    return Sqflite.firstIntValue(count) != null && Sqflite.firstIntValue(count)! > 0;
  }

  Future<void> removeFavorite(int bookId) async {
    final db = await instance.database;
    // Supprime toutes les interactions de type 'favorite' pour ce livre
    await db.delete(
      tableInteractions,
      where: 'book_id = ? AND action_type = ?',
      whereArgs: [bookId, 'favorite'],
    );
  }

  Future<void> resetDatabase() async {
    final db = await instance.database;
    await db.delete(tableInteractions);
    await db.delete(tableMetrics);
  }
}