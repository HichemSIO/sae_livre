📚 BookBuddy - Application de Recommandation de Livres
🎯 Description
BookBuddy est une application mobile de recommandation de livres intelligente qui apprend de vos préférences pour vous suggérer des lectures adaptées à vos goûts. L'application fonctionne entièrement hors ligne avec un système de recommandation adaptatif.

✨ Fonctionnalités
Version 1 (03 décembre)
✅ Liste complète de livres avec images, titres, auteurs
✅ Page détaillée pour chaque livre
✅ Système de notation (1-5 étoiles)
✅ Boutons Like/Dislike
✅ Gestion des favoris
✅ Algorithme de recommandation basique (content-based)
✅ Stockage local SQLite
Version 2 (20 janvier)
✅ Interface UI/UX améliorée avec branding
✅ Filtre par genre
✅ Thème clair/sombre
✅ Algorithme de recommandation adaptatif avancé
✅ Page de statistiques avec graphiques
✅ Métriques de performance
✅ Informations système (batterie, appareil)
🛠️ Stack Technique
Framework: Flutter 3.0+
Langage: Dart
Base de données: SQLite (via sqflite)
Gestion d'état: Provider
Graphiques: fl_chart
Fonts: Google Fonts
Autres: battery_plus, device_info_plus, flutter_rating_bar
📁 Structure du Projet
bookbuddy/
├── lib/
│   ├── main.dart                          # Point d'entrée
│   ├── models/
│   │   ├── book.dart                      # Modèle Livre
│   │   └── user_interaction.dart          # Modèle Interaction
│   ├── providers/
│   │   ├── book_provider.dart             # État global des livres
│   │   └── theme_provider.dart            # Gestion du thème
│   ├── screens/
│   │   ├── home_page.dart                 # Page d'accueil
│   │   ├── book_detail_page.dart          # Détails d'un livre
│   │   ├── favorites_page.dart            # Page favoris
│   │   ├── stats_page.dart                # Statistiques
│   │   └── settings_page.dart             # Paramètres
│   ├── services/
│   │   ├── database_helper.dart           # Gestion SQLite
│   │   └── recommendation_engine.dart     # Algorithmes de recommandation
│   └── widgets/
│       └── book_card.dart                 # Widget carte de livre
├── assets/
│   └── data/
│       └── books.json                     # Dataset initial
└── pubspec.yaml                           # Dépendances
🚀 Installation
Prérequis
Flutter SDK 3.0 ou supérieur
Dart 3.0 ou supérieur
Android Studio / VS Code
Un émulateur Android/iOS ou un appareil physique
Étapes d'installation
Cloner le projet
bash
git clone <votre-repo>
cd bookbuddy
Installer les dépendances
bash
flutter pub get
Créer le dossier assets
bash
mkdir -p assets/data
mkdir -p assets/images
Copier books.json Copiez le fichier books.json dans assets/data/
Lancer l'application
bash
flutter run
📊 Algorithmes de Recommandation
Algorithme Basique (V1)
Content-Based Filtering
Analyse des genres et auteurs aimés
Score = 40% genre + 30% auteur + 30% note moyenne
Simple et rapide
Algorithme Avancé (V2)
Algorithme Adaptatif
Facteurs pondérés dynamiquement :
35% affinité de genre (avec historique)
25% affinité d'auteur
20% bonus de nouveauté (évite la bulle de filtre)
20% popularité (note moyenne)
Diversification des résultats
Apprentissage progressif des préférences
📈 Métriques de Performance
L'application mesure automatiquement :

⏱️ Temps de chargement des listes
⏱️ Temps de génération des recommandations
⏱️ Temps d'affichage des détails
📊 Nombre d'opérations effectuées
🔋 Niveau de batterie
📱 Informations système
🎨 Design
Palette de couleurs

Primaire : Bleu nuit (
#1A237E)
Secondaire : Doré/Ambre
Accent : Blanc cassé
Typographie

Titres : Merriweather (Google Fonts)
Corps : Open Sans (Google Fonts)
📝 Utilisation
Découvrir des livres
Ouvrez l'application
Parcourez les recommandations ou tous les livres
Filtrez par genre si nécessaire
Tapez sur un livre pour voir les détails
Donner votre avis
Ouvrez un livre
Notez-le avec les étoiles (1-5)
Appuyez sur "J'aime" ou "Pas pour moi"
Ajoutez aux favoris avec le bouton ❤️
Voir vos statistiques
Allez dans l'onglet "Stats"
Consultez vos genres préférés
Découvrez vos auteurs favoris
Vérifiez les métriques de performance
🔧 Configuration
Changer le thème
Allez dans "Paramètres"
Tapez sur "Thème"
Choisissez : Clair, Sombre ou Système
Réinitialiser les données
Allez dans "Paramètres"
Tapez sur "Réinitialiser les données"
Confirmez l'action
🧪 Tests
Pour tester l'algorithme de recommandation :

Test genre : Likez 5 livres de Fantasy → Vérifiez que les recommandations sont principalement de Fantasy
Test auteur : Notez 5/5 plusieurs livres de Tolkien → Vérifiez que d'autres livres de Tolkien apparaissent
Test diversité : Likez des livres de genres différents → Vérifiez que l'algorithme propose de la diversité
📦 Build Production
Android (APK)
bash
flutter build apk --release
iOS (IPA)
bash
flutter build ios --release
🐛 Dépannage
Erreur de base de données

bash
flutter clean
flutter pub get
Problème d'assets

Vérifiez que books.json existe dans assets/data/
Vérifiez pubspec.yaml contient la section assets
Performance lente

Utilisez un appareil physique plutôt qu'un émulateur
Activez le mode Release : flutter run --release
📄 Licence
Ce projet est développé dans un cadre éducatif.

👥 Auteur
Projet réalisé pour le cours de développement mobile.

🔮 Améliorations Futures
 Recherche de livres par titre/auteur
 Import de livres personnalisés
 Partage de recommandations
 Synchronisation cloud
 Mode lecture avec timer
 Listes de lecture personnalisées
 Intégration API externe (Google Books)
Note : Cette application ne nécessite aucune connexion internet et fonctionne entièrement hors ligne.

