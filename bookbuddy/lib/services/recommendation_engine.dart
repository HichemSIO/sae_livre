import '../models/book.dart';
import '../models/user_interaction.dart';
import 'database_helper.dart';

class UserPreferences {
  final Map<String, int> genreCount;
  final Map<String, int> authorCount;
  final List<String> likedGenres;
  final List<String> likedAuthors;
  final double averageRating;

  UserPreferences({
    required this.genreCount,
    required this.authorCount,
    required this.likedGenres,
    required this.likedAuthors,
    required this.averageRating,
  });
}

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

  // Version 1: Algorithme simple Content-Based
  Future<List<Book>> getBasicRecommendations({int limit = 10}) async {
    final startTime = DateTime.now();
    
    final preferences = await _analyzeUserPreferences();
    final allBooks = await _db.getAllBooks();
    final interactions = await _db.getAllInteractions();
    
    // Livres déjà interagis
    final interactedBookIds = interactions.map((i) => i.bookId).toSet();
    
    // Filtrer les livres non lus
    final unreadBooks = allBooks.where((book) => 
      !interactedBookIds.contains(book.id)
    ).toList();
    
    // Scorer les livres
    final scored = unreadBooks.map((book) {
      final score = _calculateBasicScore(book, preferences);
      return ScoredBook(
        book: book,
        score: score,
        scoreBreakdown: {'basic': score},
      );
    }).toList();
    
    // Trier par score
    scored.sort((a, b) => b.score.compareTo(a.score));
    
    // Enregistrer métrique de performance
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    await _db.insertMetric(PerformanceMetric(
      operationType: 'basic_recommendation',
      durationMs: duration,
    ));
    
    return scored.take(limit).map((s) => s.book).toList();
  }

  // Version 2: Algorithme adaptatif avancé
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
    
    // Scorer avec algorithme avancé
    final scored = unreadBooks.map((book) {
      final genreScore = _calculateGenreAffinity(book, preferences) * 0.35;
      final authorScore = _calculateAuthorAffinity(book, preferences) * 0.25;
      final noveltyScore = _calculateNoveltyBonus(book, preferences) * 0.20;
      final popularityScore = (book.noteMoyenne / 5.0) * 0.20;
      
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
    
    // Trier et diversifier
    scored.sort((a, b) => b.score.compareTo(a.score));
    final diversified = _diversifyResults(scored, limit);
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    await _db.insertMetric(PerformanceMetric(
      operationType: 'smart_recommendation',
      durationMs: duration,
    ));
    
    return diversified;
  }

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
    );
  }

  // Score basique (V1)
  double _calculateBasicScore(Book book, UserPreferences prefs) {
    double score = 0.0;
    
    // Genre match (40%)
    if (prefs.likedGenres.contains(book.genre)) {
      score += 0.4;
    }
    
    // Auteur match (30%)
    if (prefs.likedAuthors.contains(book.auteur)) {
      score += 0.3;
    }
    
    // Note du livre (30%)
    score += (book.noteMoyenne / 5.0) * 0.3;
    
    return score;
  }

  // Affinité de genre (V2)
  double _calculateGenreAffinity(Book book, UserPreferences prefs) {
    if (prefs.genreCount.isEmpty) {
      return book.noteMoyenne / 5.0;
    }
    
    final genreScore = prefs.genreCount[book.genre] ?? 0;
    final maxGenreScore = prefs.genreCount.values.reduce((a, b) => a > b ? a : b);
    
    return maxGenreScore > 0 ? genreScore / maxGenreScore : 0.0;
  }

  // Affinité d'auteur (V2)
  double _calculateAuthorAffinity(Book book, UserPreferences prefs) {
    if (prefs.authorCount.isEmpty) {
      return 0.0;
    }
    
    final authorScore = prefs.authorCount[book.auteur] ?? 0;
    final maxAuthorScore = prefs.authorCount.values.reduce((a, b) => a > b ? a : b);
    
    return maxAuthorScore > 0 ? authorScore / maxAuthorScore : 0.0;
  }

  // Bonus de nouveauté (évite la bulle de filtre)
  double _calculateNoveltyBonus(Book book, UserPreferences prefs) {
    // Bonus pour explorer de nouveaux genres
    if (!prefs.likedGenres.contains(book.genre)) {
      return 0.3;
    }
    
    // Bonus pour nouveaux auteurs du même genre aimé
    if (prefs.likedGenres.contains(book.genre) && 
        !prefs.likedAuthors.contains(book.auteur)) {
      return 0.5;
    }
    
    return 0.0;
  }

  // Diversifier les résultats
  List<Book> _diversifyResults(List<ScoredBook> scored, int limit) {
    if (scored.length <= limit) {
      return scored.map((s) => s.book).toList();
    }
    
    final result = <Book>[];
    final seenGenres = <String>{};
    final seenAuthors = <String>{};
    
    // Première passe: meilleurs scores avec diversité
    for (var scoredBook in scored) {
      if (result.length >= limit) break;
      
      final book = scoredBook.book;
      
      // Favoriser la diversité des genres
      if (!seenGenres.contains(book.genre) || result.length < limit ~/ 2) {
        result.add(book);
        seenGenres.add(book.genre);
        seenAuthors.add(book.auteur);
      }
    }
    
    // Deuxième passe: compléter si nécessaire
    for (var scoredBook in scored) {
      if (result.length >= limit) break;
      if (!result.contains(scoredBook.book)) {
        result.add(scoredBook.book);
      }
    }
    
    return result.take(limit).toList();
  }
}