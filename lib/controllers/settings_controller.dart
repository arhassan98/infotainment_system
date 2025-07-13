import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

/// Controller for managing app settings such as language and weather source.
/// Handles loading, updating, and persisting user preferences.
class SettingsController extends ChangeNotifier {
  Settings _settings = Settings(languageIndex: 2, weatherSource: 0);

  Settings get settings => _settings;
  int get languageIndex => _settings.languageIndex;
  int get weatherSource => _settings.weatherSource;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = Settings(
      languageIndex: prefs.getInt('languageIndex') ?? 2,
      weatherSource: prefs.getInt('weatherSource') ?? 0,
    );
    notifyListeners();
  }

  Future<void> setLanguageIndex(int index) async {
    _settings.languageIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('languageIndex', index);
    notifyListeners();
  }

  Future<void> setWeatherSource(int source) async {
    _settings.weatherSource = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weatherSource', source);
    notifyListeners();
  }
}
