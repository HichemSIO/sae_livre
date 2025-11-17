import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/user_interaction.dart';
import '../services/database_helper.dart';
import '../services/recommendation_engine.dart';


class BookProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final RecommendationEngine _recommendationEngine = RecommendationEngine();

  List<Book> _allBooks = [];
  List<Book> _recommendedBooks = [];
  List<Book> _favoriteBooks = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get allBooks => _allBooks;
  List<Book> get recommendedBooks => _recommendedBooks;
  List<Book> get favoriteBooks => _favoriteBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger tous les livres
  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final startTime = DateTime.now();
      _allBooks = await _db.getAllBooks();
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      await _db.insertMetric(PerformanceMetric(
        operationType: 'list_load',
        durationMs: duration,
      ));
      
      await loadRecommendations();
      await loadFavorites();
    } catch (e) {
      _error = 'Erreur de chargement: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les recommandations
  Future<void> loadRecommendations({bool useSmartAlgorithm = true}) async {
    try {
      if (useSmartAlgorithm) {
        _recommendedBooks = await _recommendationEngine.getSmartRecommendations(limit: 20);
      } else {
        _recommendedBooks = await _recommendationEngine.getBasicRecommendations(limit: 20);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de recommandation: $e';
      notifyListeners();
    }
  }

  // Charger les favoris
  Future<void> loadFavorites() async {
    try {
      _favoriteBooks = await _db.getFavoriteBooks();
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement des favoris: $e';
      notifyListeners();
    }
  }

  // Ajouter/retirer des favoris
  Future<void> toggleFavorite(Book book) async {
    try {
      final isFav = await _db.isFavorite(book.id!);
      
      if (isFav) {
        await _db.removeFavorite(book.id!);
      } else {
        await _db.insertInteraction(UserInteraction(
          bookId: book.id!,
          actionType: 'favorite',
        ));
      }
      
      await loadFavorites();
      await loadRecommendations();
    } catch (e) {
      _error = 'Erreur de favoris: $e';
      notifyListeners();
    }
  }

  // Vérifier si un livre est favori
  Future<bool> isFavorite(int bookId) async {
    return await _db.isFavorite(bookId);
  }

  // Liker un livre
  Future<void> likeBook(Book book) async {
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: book.id!,
        actionType: 'like',
      ));
      await loadRecommendations();
    } catch (e) {
      _error = 'Erreur de like: $e';
      notifyListeners();
    }
  }

  // Disliker un livre
  Future<void> dislikeBook(Book book) async {
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: book.id!,
        actionType: 'dislike',
      ));
      await loadRecommendations();
    } catch (e) {
      _error = 'Erreur de dislike: $e';
      notifyListeners();
    }
  }

  // Noter un livre
  Future<void> rateBook(Book book, int rating) async {
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: book.id!,
        actionType: 'rating',
        rating: rating,
      ));
      await loadRecommendations();
    } catch (e) {
      _error = 'Erreur de notation: $e';
      notifyListeners();
    }
  }

  // Enregistrer une vue
  Future<void> viewBook(Book book) async {
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: book.id!,
        actionType: 'view',
      ));
    } catch (e) {
      // Vue silencieuse, pas d'erreur affichée
      debugPrint('Erreur de vue: $e');
    }
  }

  // Filtrer par genre
  List<Book> getBooksByGenre(String genre) {
    return _allBooks.where((book) => book.genre == genre).toList();
  }

  // Obtenir tous les genres
  List<String> getAllGenres() {
    final genres = _allBooks.map((book) => book.genre).toSet().toList();
    genres.sort();
    return genres;
  }

  // Réinitialiser les données
  Future<void> resetData() async {
    try {
      await _db.resetDatabase();
      await loadBooks();
    } catch (e) {
      _error = 'Erreur de réinitialisation: $e';
      notifyListeners();
    }
  }
}