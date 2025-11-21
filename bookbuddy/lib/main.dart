import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/book_provider.dart';
import 'providers/theme_provider.dart'; // Ajouté car vous avez un theme_provider
import 'services/database_helper.dart';
import 'screens/home_page.dart';
import 'screens/favorites_page.dart';
import 'screens/stats_page.dart';
import 'screens/settings_page.dart';

void main() async {
  // Obligatoire pour utiliser les plugins (comme sqflite) avant runApp
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Initialise la base de données
  await DatabaseHelper.instance.database; 
  
  runApp(
    MultiProvider(
      providers: [
        // ThemeProvider pour la gestion du thème
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // BookProvider pour la gestion des données et des favoris
        ChangeNotifierProvider(create: (context) => BookProvider()..loadBooks()), // Charge les livres au démarrage
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Écoute le thème actuel
    final themeProvider = context.watch<ThemeProvider>(); 
    
    return MaterialApp(
      title: 'BookBuddy',
      // Utilise le ThemeProvider pour définir le thème
      themeMode: themeProvider.themeMode, 
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light, 
        useMaterial3: true,
        fontFamily: 'Roboto', 
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark, 
        useMaterial3: true,
        fontFamily: 'Roboto', 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // Pour le look épuré sombre
        )
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Liste des pages
  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const FavoritesPage(), 
    const StatsPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    // Si l'utilisateur clique sur Favoris ou Stats, on force le chargement des données
    if (index == 1) {
      Provider.of<BookProvider>(context, listen: false).loadFavorites();
    }
    // La page StatsPage se recharge elle-même via initState
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), 
      
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.tealAccent[400],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}