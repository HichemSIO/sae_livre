import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io show Platform;
// NOTE: Ces modèles doivent exister dans votre dossier '../models/'
import '../models/book.dart'; 
import '../models/user_interaction.dart'; 

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String tableBooks = 'books';
  static const String tableInteractions = 'interactions';
  static const String tableMetrics = 'metrics';

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite n\'est pas supporté sur le web. Cette application nécessite une plateforme native (Windows, Linux, macOS, Android, iOS).');
    }
    if (_database != null) return _database!;
    _database = await _initDB('bookbuddy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbPath;
    
    try {
      if (kIsWeb) {
        throw UnsupportedError('sqflite n\'est pas supporté sur le web. Utilisez une autre solution comme IndexedDB.');
      }
      
      final isDesktop = io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS;
      
      if (isDesktop) {
        final directory = await getApplicationDocumentsDirectory();
        dbPath = directory.path;
      } else {
        dbPath = await getDatabasesPath();
      }
      
      final path = join(dbPath, filePath);
      debugPrint('Chemin de la base de données: $path');
      
      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de l\'initialisation de la base de données: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE $tableBooks ADD COLUMN date_ajout TEXT');
        await db.execute(
          'UPDATE $tableBooks SET date_ajout = ? WHERE date_ajout IS NULL',
          [DateTime.now().toIso8601String()],
        );
      } catch (e) {
        debugPrint('Erreur lors de la mise à jour de la base de données: $e');
      }
    }
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
  image_url $textType,
  date_ajout $textType
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
    try {
      final String jsonString = await rootBundle.loadString('assets/data/books.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final batch = db.batch();
      for (int i = 0; i < jsonList.length; i++) {
          final book = Book.fromJson(jsonList[i]).copyWith(id: i + 1); 
          batch.insert(tableBooks, book.toMap());
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Erreur lors du chargement des livres depuis JSON: $e');
    }
  }


  // --- CRUD BASIQUE ET LOGIQUE MÉTIER ---

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

  /// Ajouter un nouveau livre dans la base de données
  Future<int> insertBook(Book book) async {
    final db = await instance.database;
    return await db.insert(tableBooks, book.toMap());
  }

  /// Ajouter plusieurs livres en une seule transaction
  Future<void> insertBooks(List<Book> books) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var book in books) {
      batch.insert(tableBooks, book.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Mettre à jour un livre existant
  Future<int> updateBook(Book book) async {
    if (book.id == null) {
      throw ArgumentError('Le livre doit avoir un ID pour être mis à jour');
    }
    final db = await instance.database;
    return await db.update(
      tableBooks,
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  /// Supprimer un livre
  Future<int> deleteBook(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableBooks,
      where: 'id = ?',
      whereArgs: [id],
    );
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
  
  // NOTE: PerformanceMetric doit être un modèle importé et mappable
  Future<void> insertMetric(PerformanceMetric metric) async {
    final db = await instance.database;
    await db.insert(tableMetrics, metric.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  // NOTE: PerformanceMetric doit être un modèle importé et mappable
  Future<List<PerformanceMetric>> getMetrics() async {
      final db = await instance.database;
      final result = await db.query(tableMetrics);
      return result.map((json) => PerformanceMetric.fromMap(json)).toList(); 
  }

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
    final firstValue = Sqflite.firstIntValue(count);
    return firstValue != null && firstValue > 0;
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