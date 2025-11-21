import '../models/book.dart';
import '../models/user_interaction.dart';
import 'database_helper.dart';

// Enum pour la catégorisation temporelle (pour l'adaptation)
enum ReadingTime { morning, day, evening, transport }

// Modèle pour stocker les préférences utilisateur analysées
class UserPreferences {
  final Map<String, int> genreCount;
  final Map<String, int> authorCount;
  final List<String> likedGenres;
  final List<String> likedAuthors;
  final double averageRating;
  final double averageSessionDuration;
  final Map<ReadingTime, double> timeSlotSuccess;

  UserPreferences({
    required this.genreCount,
    required this.authorCount,
    required this.likedGenres,
    required this.likedAuthors,
    required this.averageRating,
    this.averageSessionDuration = 0.0,
    this.timeSlotSuccess = const {},
  });
}

// Modèle pour scorer les livres
class ScoredBook {
  final Book book;
  final double score;
  final Map<String, double> scoreBreakdown;

  ScoredBook({
    required this.book,
    required this.score,
    required this.scoreBreakdown,
  });
}

class RecommendationEngine {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // --- LOGIQUE GLOBALE ---

  // Analyser les préférences utilisateur
  Future<UserPreferences> _analyzeUserPreferences() async {
    final interactions = await _db.getAllInteractions();
    
    if (interactions.isEmpty) {
      return UserPreferences(
        genreCount: {},
        authorCount: {},
        likedGenres: [],
        likedAuthors: [],
        averageRating: 0.0,
      );
    }
    
    final Map<String, int> genreCount = {};
    final Map<String, int> authorCount = {};
    final List<int> ratings = [];
    
    // Simplification : le code de contexte sera ajouté par l'utilisateur plus tard
    // Pour l'instant, on se concentre sur les goûts :
    for (var interaction in interactions) {
      final book = await _db.getBookById(interaction.bookId);
      if (book == null) continue;
      
      // Compter les genres et auteurs pour les interactions positives
      if (interaction.actionType == 'like' || 
          interaction.actionType == 'favorite' ||
          (interaction.rating != null && interaction.rating! >= 4)) {
        genreCount[book.genre] = (genreCount[book.genre] ?? 0) + 1;
        authorCount[book.auteur] = (authorCount[book.auteur] ?? 0) + 1;
      }
      
      if (interaction.rating != null) {
        ratings.add(interaction.rating!);
      }
    }
    
    // Top genres et auteurs
    final sortedGenres = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedAuthors = authorCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final avgRating = ratings.isEmpty 
        ? 0.0 
        : ratings.reduce((a, b) => a + b) / ratings.length;
    
    return UserPreferences(
      genreCount: genreCount,
      authorCount: authorCount,
      likedGenres: sortedGenres.take(3).map((e) => e.key).toList(),
      likedAuthors: sortedAuthors.take(3).map((e) => e.key).toList(),
      averageRating: avgRating,
      // Les données de contexte sont initialisées à 0/vide pour l'instant (V1)
      averageSessionDuration: 0.0,
      timeSlotSuccess: {},
    );
  }

  // --- ALGORITHMES DE RECOMMANDATION ---

  // Version 1: Algorithme simple Content-Based
  Future<List<Book>> getBasicRecommendations({int limit = 10}) async {
    final startTime = DateTime.now();
    
    final preferences = await _analyzeUserPreferences();
    final allBooks = await _db.getAllBooks();
    final interactions = await _db.getAllInteractions();
    
    final interactedBookIds = interactions.map((i) => i.bookId).toSet();
    
    final unreadBooks = allBooks.where((book) => 
      !interactedBookIds.contains(book.id)
    ).toList();
    
    final scored = unreadBooks.map((book) {
      final score = _calculateBasicScore(book, preferences);
      return ScoredBook(
        book: book,
        score: score,
        scoreBreakdown: {'basic': score},
      );
    }).toList();
    
    scored.sort((a, b) => b.score.compareTo(a.score));
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    await _db.insertMetric(PerformanceMetric(
      operationType: 'basic_recommendation',
      durationMs: duration,
    ));
    
    return scored.take(limit).map((s) => s.book).toList();
  }

  // Version 2: Algorithme adaptatif avancé (à compléter pour l'adaptation contextuelle)
  Future<List<Book>> getSmartRecommendations({int limit = 10}) async {
    final startTime = DateTime.now();
    
    final preferences = await _analyzeUserPreferences();
    final allBooks = await _db.getAllBooks();
    final interactions = await _db.getAllInteractions();
    
    final interactedBookIds = interactions.map((i) => i.bookId).toSet();
    final unreadBooks = allBooks.where((book) => 
      !interactedBookIds.contains(book.id)
    ).toList();
    
    if (unreadBooks.isEmpty) {
      return [];
    }
    
    // L'ajout de l'adaptation contextuelle (heure/durée) sera fait ici plus tard.
    // Pour l'instant, c'est une version améliorée du score de contenu.
    final scored = unreadBooks.map((book) {
      final genreScore = _calculateGenreAffinity(book, preferences) * 0.40;
      final authorScore = _calculateAuthorAffinity(book, preferences) * 0.30;
      final noveltyScore = _calculateNoveltyBonus(book, preferences) * 0.20;
      final popularityScore = (book.noteMoyenne / 5.0) * 0.10;
      
      final totalScore = genreScore + authorScore + noveltyScore + popularityScore;
      
      return ScoredBook(
        book: book,
        score: totalScore,
        scoreBreakdown: {
          'genre': genreScore,
          'author': authorScore,
          'novelty': noveltyScore,
          'popularity': popularityScore,
        },
      );
    }).toList();
    
    scored.sort((a, b) => b.score.compareTo(a.score));
    final diversified = _diversifyResults(scored, limit);
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    await _db.insertMetric(PerformanceMetric(
      operationType: 'smart_recommendation',
      durationMs: duration,
    ));
    
    return diversified.map((s) => s.book).toList();
  }

  // --- FONCTIONS DE SCORING ---

  double _calculateBasicScore(Book book, UserPreferences prefs) {
    double score = 0.0;
    if (prefs.likedGenres.contains(book.genre)) score += 0.4;
    if (prefs.likedAuthors.contains(book.auteur)) score += 0.3;
    score += (book.noteMoyenne / 5.0) * 0.3;
    return score;
  }

  double _calculateGenreAffinity(Book book, UserPreferences prefs) {
    if (prefs.genreCount.isEmpty) return book.noteMoyenne / 5.0;
    final genreScore = prefs.genreCount[book.genre] ?? 0;
    if (prefs.genreCount.values.isEmpty) return 0.0;
    final maxGenreScore = prefs.genreCount.values.reduce((a, b) => a > b ? a : b);
    return maxGenreScore > 0 ? genreScore / maxGenreScore : 0.0;
  }

  double _calculateAuthorAffinity(Book book, UserPreferences prefs) {
    if (prefs.authorCount.isEmpty) return 0.0;
    final authorScore = prefs.authorCount[book.auteur] ?? 0;
    if (prefs.authorCount.values.isEmpty) return 0.0;
    final maxAuthorScore = prefs.authorCount.values.reduce((a, b) => a > b ? a : b);
    return maxAuthorScore > 0 ? authorScore / maxAuthorScore : 0.0;
  }

  double _calculateNoveltyBonus(Book book, UserPreferences prefs) {
    if (!prefs.likedGenres.contains(book.genre)) {
      return 0.3;
    }
    if (prefs.likedGenres.contains(book.genre) && 
        !prefs.likedAuthors.contains(book.auteur)) {
      return 0.5;
    }
    return 0.0;
  }

  List<ScoredBook> _diversifyResults(List<ScoredBook> scored, int limit) {
    if (scored.length <= limit) return scored;
    
    final result = <ScoredBook>[];
    final seenGenres = <String>{};
    
    for (var scoredBook in scored) {
      if (result.length >= limit) break;
      final book = scoredBook.book;
      
      // Favoriser la diversité des genres
      if (!seenGenres.contains(book.genre) || result.length < limit ~/ 2) {
        result.add(scoredBook);
        seenGenres.add(book.genre);
      }
    }
    
    // Compléter avec les meilleurs scores si la limite n'est pas atteinte
    for (var scoredBook in scored) {
      if (result.length >= limit) break;
      if (!result.contains(scoredBook)) {
        result.add(scoredBook);
      }
    }
    
    return result.take(limit).toList();
  }
}