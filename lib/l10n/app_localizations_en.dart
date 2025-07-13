// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Infotainment System';

  @override
  String get settings => 'Settings';

  @override
  String get weather => 'Weather';

  @override
  String get language => 'Language';

  @override
  String get about => 'About system';

  @override
  String get home => 'Home';

  @override
  String get music => 'Music';

  @override
  String get phone => 'Phone';

  @override
  String get ok => 'OK';

  @override
  String get noMusicFiles => 'No music files found on device.';

  @override
  String get troubleshootingTips => 'Troubleshooting tips:';

  @override
  String get grantPermissions => '- Make sure you have granted storage/media permissions.';

  @override
  String get placeMusicFiles => '- Place music files in /Music, /Download, or /Documents.';

  @override
  String get supportedFormats => '- Only mp3, wav, aac, m4a, flac, ogg files are supported.';

  @override
  String get refreshButton => '- Use the refresh button after adding files.';

  @override
  String get restartApp => '- Try restarting the app after adding files.';

  @override
  String get avoidProtectedFolders => '- Avoid protected folders like /Android/data.';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get mobile => 'Mobile';

  @override
  String get startJourney => 'Start Journey';

  @override
  String get stopJourney => 'Stop Journey';

  @override
  String get eta => 'ETA';

  @override
  String get searchPlace => 'Search for a place';

  @override
  String get searchMusic => 'Search music...';

  @override
  String get playlist => 'Playlist';

  @override
  String get close => 'Close';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get storagePermissionMessage => 'This app needs access to your device storage to find music files. Please grant permission in app settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get mediaEntertainment => 'Media & Entertainment';

  @override
  String get deviceTemperature => 'Device Temperature';

  @override
  String get driveConnected => 'Drive Connected. Drive Inspired.';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get german => 'Deutsch';

  @override
  String get getWeatherApi => 'Get weather from API';

  @override
  String get getWeatherExternal => 'Get weather from External System';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String get precipitation => 'Precipitation';

  @override
  String get wind => 'Wind';

  @override
  String get pressure => 'Pressure';

  @override
  String lastUpdate(Object time) {
    return 'Last update: $time';
  }

  @override
  String get noData => 'No data';

  @override
  String get zoomIn => 'Zoom In';

  @override
  String get zoomOut => 'Zoom Out';

  @override
  String get recenter => 'Recenter';

  @override
  String get toggleTraffic => 'Toggle Traffic';

  @override
  String get toggleMapMode => 'Toggle Map Mode';

  @override
  String get refreshLocationWeather => 'Refresh location & weather';

  @override
  String get weatherSource => 'Weather Source';

  @override
  String get getWeatherFromAPI => 'Get weather from API';

  @override
  String get useOnlineWeatherAPI => 'Use online weather API';

  @override
  String get getWeatherFromExternalSystem => 'Get weather from External System';

  @override
  String get useDataProvidedByExternalSystem => 'Use data provided by external system';

  @override
  String get infotainmentSystem => 'Infotainment System';

  @override
  String get experienceFutureOfDriving => 'Experience the future of driving.';

  @override
  String get driveConnectedDriveInspired => 'Drive Connected. Drive Inspired.';

  @override
  String get developerInfo => 'Developer Info';

  @override
  String get developedByAhmedHassan => 'Developed by Ahmed Hassan';

  @override
  String contentForTitleWillAppearHere(Object title) {
    return 'Content for $title will appear here.';
  }

  @override
  String get deutsch => 'German';

  @override
  String get apiKeyNotSet => 'API Key Not Set';

  @override
  String get apiKeyNotSetDescription => 'To use weather and map features, you must set your Google Cloud API key.';

  @override
  String get apiKeyNotSetSteps => '1. Go to lib/config/api_config.dart\n2. Replace YOUR_API_KEY_HERE with your Google Cloud API key\n3. See API_SETUP.md for detailed instructions';

  @override
  String get viewApiSetupGuide => 'View API Setup Guide';
}
