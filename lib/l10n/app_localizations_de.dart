// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Infotainment-System';

  @override
  String get settings => 'Einstellungen';

  @override
  String get weather => 'Wetter';

  @override
  String get language => 'Sprache';

  @override
  String get about => 'Über das System';

  @override
  String get home => 'Startseite';

  @override
  String get music => 'Musik';

  @override
  String get phone => 'Telefon';

  @override
  String get ok => 'OK';

  @override
  String get noMusicFiles => 'Keine Musikdateien auf dem Gerät gefunden.';

  @override
  String get troubleshootingTips => 'Tipps zur Fehlerbehebung:';

  @override
  String get grantPermissions => '- Stellen Sie sicher, dass Sie Speicher-/Medienberechtigungen erteilt haben.';

  @override
  String get placeMusicFiles => '- Legen Sie Musikdateien in /Music, /Download oder /Documents ab.';

  @override
  String get supportedFormats => '- Nur mp3, wav, aac, m4a, flac, ogg Dateien werden unterstützt.';

  @override
  String get refreshButton => '- Verwenden Sie die Schaltfläche \'Aktualisieren\' nach dem Hinzufügen von Dateien.';

  @override
  String get restartApp => '- Versuchen Sie, die App nach dem Hinzufügen von Dateien neu zu starten.';

  @override
  String get avoidProtectedFolders => '- Vermeiden Sie geschützte Ordner wie /Android/data.';

  @override
  String get temperature => 'Temperatur';

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get mobile => 'Gerät';

  @override
  String get startJourney => 'Fahrt starten';

  @override
  String get stopJourney => 'Fahrt beenden';

  @override
  String get eta => 'ETA';

  @override
  String get searchPlace => 'Ort suchen';

  @override
  String get searchMusic => 'Musik suchen...';

  @override
  String get playlist => 'Wiedergabeliste';

  @override
  String get close => 'Schließen';

  @override
  String get permissionRequired => 'Berechtigung erforderlich';

  @override
  String get storagePermissionMessage => 'Diese App benötigt Zugriff auf den Gerätespeicher, um Musikdateien zu finden. Bitte erteilen Sie die Berechtigung in den App-Einstellungen.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get mediaEntertainment => 'Medien & Unterhaltung';

  @override
  String get deviceTemperature => 'Gerätetemperatur';

  @override
  String get driveConnected => 'Fahrt verbunden. Fahrt inspiriert.';

  @override
  String get arabic => 'Arabisch';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get getWeatherApi => 'Wetter von API abrufen';

  @override
  String get getWeatherExternal => 'Wetter vom externen System abrufen';

  @override
  String get sunrise => 'Sonnenaufgang';

  @override
  String get sunset => 'Sonnenuntergang';

  @override
  String get precipitation => 'Niederschlag';

  @override
  String get wind => 'Wind';

  @override
  String get pressure => 'Druck';

  @override
  String lastUpdate(Object time) {
    return 'Letzte Aktualisierung: $time';
  }

  @override
  String get noData => 'Keine Daten';

  @override
  String get zoomIn => 'Vergrößern';

  @override
  String get zoomOut => 'Verkleinern';

  @override
  String get recenter => 'Zentrieren';

  @override
  String get toggleTraffic => 'Verkehr umschalten';

  @override
  String get toggleMapMode => 'Kartenmodus wechseln';

  @override
  String get refreshLocationWeather => 'Standort & Wetter aktualisieren';

  @override
  String get weatherSource => 'Wetterquelle';

  @override
  String get getWeatherFromAPI => 'Wetter von API abrufen';

  @override
  String get useOnlineWeatherAPI => 'Online-Wetter-API verwenden';

  @override
  String get getWeatherFromExternalSystem => 'Wetter vom externen System abrufen';

  @override
  String get useDataProvidedByExternalSystem => 'Daten vom externen System verwenden';

  @override
  String get infotainmentSystem => 'Infotainment-System';

  @override
  String get experienceFutureOfDriving => 'Erleben Sie die Zukunft des Fahrens.';

  @override
  String get driveConnectedDriveInspired => 'Fahrt verbunden. Fahrt inspiriert.';

  @override
  String get developerInfo => 'Entwicklerinformationen';

  @override
  String get developedByAhmedHassan => 'Entwickelt von Ahmed Hassan';

  @override
  String contentForTitleWillAppearHere(Object title) {
    return 'Inhalt für $title wird hier angezeigt.';
  }

  @override
  String get deutsch => 'Deutsch';

  @override
  String get apiKeyNotSet => 'API-Schlüssel nicht gesetzt';

  @override
  String get apiKeyNotSetDescription => 'Um Wetter- und Kartenfunktionen zu nutzen, müssen Sie Ihren Google Cloud API-Schlüssel eintragen.';

  @override
  String get apiKeyNotSetSteps => '1. Gehen Sie zu lib/config/api_config.dart\n2. Ersetzen Sie YOUR_API_KEY_HERE durch Ihren Google Cloud API-Schlüssel\n3. Siehe API_SETUP.md für detaillierte Anweisungen';

  @override
  String get viewApiSetupGuide => 'API-Setup-Anleitung anzeigen';
}
