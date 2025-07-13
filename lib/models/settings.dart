/// Model representing app settings such as language and weather source.
/// Used by the SettingsController to persist user preferences.
class Settings {
  /// The selected language index (0=ar, 1=de, 2=en).
  int languageIndex;

  /// The selected weather source (0=API, 1=External).
  int weatherSource;

  /// Creates a new [Settings] instance.
  Settings({required this.languageIndex, required this.weatherSource});

  /// Creates a [Settings] instance from a preferences map.
  factory Settings.fromPrefs(Map<String, dynamic> prefs) => Settings(
    languageIndex: prefs['languageIndex'] ?? 2,
    weatherSource: prefs['weatherSource'] ?? 0,
  );

  /// Converts the [Settings] instance to a preferences map.
  Map<String, dynamic> toPrefs() => {
    'languageIndex': languageIndex,
    'weatherSource': weatherSource,
  };
}
