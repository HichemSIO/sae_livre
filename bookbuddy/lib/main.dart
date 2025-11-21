import 'package:flutter/material.dart';
import 'services/database_helper.dart'; // Le chemin correct ! // Importe votre classe de base de données

// Fonction principale asynchrone pour initialiser la base de données
void main() async {
  // Obligatoire pour utiliser les plugins (comme sqflite) avant runApp
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Initialise la base de données (crée la base et les tables si elles n'existent pas)
  // Cette ligne est le point de connexion de sqflite.
  await DatabaseHelper.instance.database; 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookBuddy',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        // Utilisez le thème sombre pour correspondre à l'image précédente
        brightness: Brightness.dark, 
        useMaterial3: true,
      ),
      home: const MyHomePage(), // Votre page d'accueil
    );
  }
}

// Remplacez cette classe par votre vraie page d'accueil si elle est plus complexe
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookBuddy'),
      ),
      body: const Center(
        child: Text(
          'Application BookBuddy prête à l\'emploi !',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}