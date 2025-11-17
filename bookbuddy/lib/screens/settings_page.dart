import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../providers/book_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _deviceInfo = 'Chargement...';
  int _batteryLevel = 0;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadBatteryLevel();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String info = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info = '${androidInfo.brand} ${androidInfo.model}\nAndroid ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info = '${iosInfo.name}\niOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      info = 'Non disponible';
    }

    setState(() {
      _deviceInfo = info;
    });
  }

  Future<void> _loadBatteryLevel() async {
    final battery = Battery();
    try {
      final level = await battery.batteryLevel;
      setState(() {
        _batteryLevel = level;
      });
    } catch (e) {
      setState(() {
        _batteryLevel = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Section Apparence
          _buildSectionHeader(context, 'Apparence'),
          ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('Thème'),
            subtitle: Text(themeProvider.themeModeString),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeDialog(context, themeProvider);
            },
          ),
          const Divider(),

          // Section Algorithme
          _buildSectionHeader(context, 'Algorithme de recommandation'),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome),
            title: const Text('Algorithme intelligent'),
            subtitle: const Text('Utilise l\'algorithme adaptatif avancé'),
            value: true,
            onChanged: (value) async {
              await bookProvider.loadRecommendations(useSmartAlgorithm: value);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Algorithme intelligent activé'
                        : 'Algorithme basique activé',
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // Section Données
          _buildSectionHeader(context, 'Données'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Recharger les livres'),
            subtitle: const Text('Actualiser la bibliothèque'),
            onTap: () async {
              await bookProvider.loadBooks();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Livres rechargés')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Réinitialiser les données'),
            subtitle: const Text('Effacer l\'historique et les préférences'),
            onTap: () {
              _showResetDialog(context, bookProvider);
            },
          ),
          const Divider(),

          // Section Info système
          _buildSectionHeader(context, 'Informations système'),
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text('Appareil'),
            subtitle: Text(_deviceInfo),
          ),
          ListTile(
            leading: Icon(
              Icons.battery_full,
              color: _batteryLevel > 20 ? Colors.green : Colors.red,
            ),
            title: const Text('Batterie'),
            subtitle: Text(
              _batteryLevel >= 0 ? '$_batteryLevel%' : 'Non disponible',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBatteryLevel,
            ),
          ),
          const Divider(),

          // Section À propos
          _buildSectionHeader(context, 'À propos'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('À propos de BookBuddy'),
            subtitle: const Text('Application de recommandation de livres intelligente'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'BookBuddy',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.book, size: 48),
                children: [
                  const Text(
                    'BookBuddy est une application de recommandation de livres '
                    'qui apprend de vos préférences pour vous suggérer '
                    'des lectures adaptées à vos goûts.',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Clair'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sombre'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Système'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, BookProvider bookProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les données'),
        content: const Text(
          'Cette action effacera votre historique de lectures, vos notes et vos favoris. '
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await bookProvider.resetData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données réinitialisées')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}