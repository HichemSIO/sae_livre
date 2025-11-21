import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb, debugPrint;
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
  bool _useSmartAlgorithm = true;

  List<Book> get allBooks => _allBooks;
  List<Book> get recommendedBooks => _recommendedBooks;
  List<Book> get favoriteBooks => _favoriteBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useSmartAlgorithm => _useSmartAlgorithm;

  // Charger tous les livres
  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Vérifier si on est sur le web
      if (kIsWeb) {
        _error = 'Cette application nécessite une plateforme native (Windows, Linux, macOS, Android, iOS). Le mode web n\'est pas encore supporté.';
        _allBooks = [];
        _recommendedBooks = [];
        _favoriteBooks = [];
        return;
      }
      
      final startTime = DateTime.now();
      _allBooks = await _db.getAllBooks();
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      // PerformanceMetric est maintenant importé via user_interaction.dart
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
  Future<void> loadRecommendations({bool? useSmartAlgorithm}) async {
    if (useSmartAlgorithm != null) {
      _useSmartAlgorithm = useSmartAlgorithm;
    }
    
    try {
      if (_useSmartAlgorithm) {
        // La méthode getSmartRecommendations() renvoie List<Book> ou List<ScoredBook>
        // Le moteur retourne des Books, donc c'est correct.
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
    // On s'assure que l'ID n'est pas nul avant de continuer (ID requis pour la DB)
    if (book.id == null) return;
    final bookId = book.id!;
    
    try {
      final isFav = await _db.isFavorite(bookId);
      
      if (isFav) {
        await _db.removeFavorite(bookId);
      } else {
        await _db.insertInteraction(UserInteraction(
          bookId: bookId,
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
    if (book.id == null) return;
    final bookId = book.id!;
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: bookId,
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
    if (book.id == null) return;
    final bookId = book.id!;
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: bookId,
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
    if (book.id == null) return;
    final bookId = book.id!;
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: bookId,
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
    if (book.id == null) return;
    final bookId = book.id!;
    try {
      await _db.insertInteraction(UserInteraction(
        bookId: bookId,
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