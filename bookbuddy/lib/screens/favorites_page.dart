import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../widgets/book_card.dart';
import 'book_detail_page.dart';

class FavoritesPage extends StatelessWidget {
 const FavoritesPage({super.key});

 @override
 Widget build(BuildContext context) {
 // Utilise context.watch pour se mettre à jour lorsque favoriteBooks change
 final bookProvider = context.watch<BookProvider>(); 
 final favoriteBooks = bookProvider.favoriteBooks;

 return Scaffold(
 appBar: AppBar(
 title: const Text('💖 Mes Favoris'),
 // Le reste du style est géré par le thème sombre
 ),
 body: favoriteBooks.isEmpty
? Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.favorite_border,
 size: 100,
 color: Colors.grey[400],
 ),
 const SizedBox(height: 16),
 Text(
 'Aucun livre favori',
 style: Theme.of(context).textTheme.titleLarge?.copyWith(
 color: Colors.grey[600],
 ),
 ),
 const SizedBox(height: 8),
  Text(
 'Ajoutez des livres à vos favoris\npour les retrouver ici',
textAlign: TextAlign.center,
 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
 color: Colors.grey[500],
 ),
),
 ],
 ),
 )
 : RefreshIndicator(
 onRefresh: bookProvider.loadFavorites, // Utilise la méthode du provider
 child: GridView.builder(
 padding: const EdgeInsets.all(16),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 2,
 childAspectRatio: 0.65,
 crossAxisSpacing: 16,
 mainAxisSpacing: 16,
 ),
 itemCount: favoriteBooks.length,
 itemBuilder: (context, index) {
 final book = favoriteBooks[index];
 return BookCard(
 book: book,
onTap: () {
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (context) => BookDetailPage(book: book),
 ),
 );
 },
 showFavoriteIcon: true,
 );
 },
 ),
),
 ); }
}