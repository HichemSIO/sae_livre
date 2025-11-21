import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import 'book_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Charger le catalogue au cas où il n'a pas été chargé par le Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).loadBooks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Fonction pour obtenir les genres depuis le provider (méthode déjà définie dans votre BookProvider)
  List<String> _getAllGenres(BookProvider provider) {
      return provider.allBooks.map((book) => book.genre).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    // Utilisation de context.watch pour écouter les changements dans BookProvider
    final bookProvider = context.watch<BookProvider>(); 
    final genres = _getAllGenres(bookProvider);

    // Fonction de filtrage simple
    List<Book> _filterBooks(List<Book> books) {
      if (_selectedGenre == null) return books;
      return books.where((book) => book.genre == _selectedGenre).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 BookBuddy'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Recommandations', icon: Icon(Icons.auto_awesome)),
            Tab(text: 'Tous les livres', icon: Icon(Icons.library_books)),
          ],
        ),
        actions: [
          if (_selectedGenre != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedGenre = null;
                });
              },
              tooltip: 'Effacer le filtre',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer par genre',
            onSelected: (genre) {
              setState(() {
                _selectedGenre = genre;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tous les genres'),
              ),
              ...genres.map((genre) => PopupMenuItem(
                value: genre,
                child: Text(genre),
              )),
            ],
          ),
        ],
      ),
      body: bookProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(bookProvider.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => bookProvider.loadBooks(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookGrid(
                      context,
                      _filterBooks(bookProvider.recommendedBooks),
                      emptyMessage: 'Aucune recommandation disponible.\nCommencez par aimer des livres !',
                      bookProvider: bookProvider, // Passer le provider
                    ),
                    _buildBookGrid(
                      context,
                      _filterBooks(bookProvider.allBooks),
                      emptyMessage: 'Aucun livre disponible.',
                      bookProvider: bookProvider, // Passer le provider
                    ),
                  ],
                ),
    );
  }

  Widget _buildBookGrid(BuildContext context, List<Book> books, {required String emptyMessage, required BookProvider bookProvider}) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await bookProvider.loadBooks();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCard(
            book: book,
            onTap: () => _navigateToDetail(context, book, bookProvider),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Book book, BookProvider bookProvider) {
    // Enregistre la vue avant de naviguer
    bookProvider.viewBook(book);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(book: book),
      ),
    );
  }
}