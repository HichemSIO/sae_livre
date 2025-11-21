class Book {
  final int? id;
  final String titre;
  final String auteur;
  final String genre;
  final double noteMoyenne;
  final String description;
  final String imageUrl;
  final DateTime dateAjout;

  Book({
    this.id,
    required this.titre,
    required this.auteur,
    required this.genre,
    required this.noteMoyenne,
    required this.description,
    required this.imageUrl,
    DateTime? dateAjout,
  }) : dateAjout = dateAjout ?? DateTime.now();

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'auteur': auteur,
      'genre': genre,
      'note_moyenne': noteMoyenne,
      'description': description,
      'image_url': imageUrl,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  // Créer un Book depuis une Map
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      titre: map['titre'] as String,
      auteur: map['auteur'] as String,
      genre: map['genre'] as String,
      noteMoyenne: (map['note_moyenne'] as num).toDouble(),
      description: map['description'] as String,
      imageUrl: map['image_url'] as String,
      dateAjout: map['date_ajout'] != null 
          ? DateTime.parse(map['date_ajout'] as String)
          : DateTime.now(),
    );
  }

  // Créer un Book depuis JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      titre: json['titre'] as String,
      auteur: json['auteur'] as String,
      genre: json['genre'] as String,
      noteMoyenne: (json['note_moyenne'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  Book copyWith({
    int? id,
    String? titre,
    String? auteur,
    String? genre,
    double? noteMoyenne,
    String? description,
    String? imageUrl,
    DateTime? dateAjout,
  }) {
    return Book(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      auteur: auteur ?? this.auteur,
      genre: genre ?? this.genre,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }
}