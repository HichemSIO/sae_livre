import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isFavorite = false;
  bool _isLoading = true;
  late BookProvider _bookProvider;

  @override
  void initState() {
    super.initState();
    _bookProvider = Provider.of<BookProvider>(context, listen: false);
    _loadFavoriteStatus();
    _recordView();
  }

  Future<void> _loadFavoriteStatus() async {
    if (widget.book.id == null) {
      if (!mounted) return;
      setState(() {
        _isFavorite = false;
        _isLoading = false;
      });
      return;
    }
    
    final isFav = await _bookProvider.isFavorite(widget.book.id!);
    
    if (!mounted) return;
    
    setState(() {
      _isFavorite = isFav;
      _isLoading = false;
    });
  }

  Future<void> _recordView() async {
    await _bookProvider.viewBook(widget.book);
  }

  Future<void> _toggleFavorite() async {
    if (widget.book.id == null) return;
    
    await _bookProvider.toggleFavorite(widget.book);
    
    if (!mounted) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite
                  ? 'Ajouté aux favoris'
                  : 'Retiré des favoris',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.book.titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.book.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colorScheme.primaryContainer,
                          child: const Icon(Icons.book, size: 100),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(179),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : null,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Auteur et Genre
                      Row(
                        children: [
                          Icon(Icons.person, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.book.auteur,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(widget.book.genre),
                            backgroundColor: colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Note moyenne
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Text(
                            widget.book.noteMoyenne.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            ' / 5.0',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),

                      // Votre avis
                      Text(
                        'Donnez votre avis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Rating
                      Center(
                        child: RatingBar.builder(
                          initialRating: 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) async {
                            await bookProvider.rateBook(widget.book, rating.toInt());
                            
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Vous avez noté ce livre ${rating.toInt()}/5'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Boutons Like/Dislike
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await bookProvider.likeBook(widget.book);
                                
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('👍 Livre ajouté à vos préférences'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                });
                              },
                              icon: const Icon(Icons.thumb_up),
                              label: const Text('J\'aime'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await bookProvider.dislikeBook(widget.book);
                                
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('👎 Noté'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                });
                              },
                              icon: const Icon(Icons.thumb_down),
                              label: const Text('Pas pour moi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}