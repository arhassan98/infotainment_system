import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Infotainment System'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About system'**
  String get about;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noMusicFiles.
  ///
  /// In en, this message translates to:
  /// **'No music files found on device.'**
  String get noMusicFiles;

  /// No description provided for @troubleshootingTips.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting tips:'**
  String get troubleshootingTips;

  /// No description provided for @grantPermissions.
  ///
  /// In en, this message translates to:
  /// **'- Make sure you have granted storage/media permissions.'**
  String get grantPermissions;

  /// No description provided for @placeMusicFiles.
  ///
  /// In en, this message translates to:
  /// **'- Place music files in /Music, /Download, or /Documents.'**
  String get placeMusicFiles;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'- Only mp3, wav, aac, m4a, flac, ogg files are supported.'**
  String get supportedFormats;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'- Use the refresh button after adding files.'**
  String get refreshButton;

  /// No description provided for @restartApp.
  ///
  /// In en, this message translates to:
  /// **'- Try restarting the app after adding files.'**
  String get restartApp;

  /// No description provided for @avoidProtectedFolders.
  ///
  /// In en, this message translates to:
  /// **'- Avoid protected folders like /Android/data.'**
  String get avoidProtectedFolders;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Journey'**
  String get startJourney;

  /// No description provided for @stopJourney.
  ///
  /// In en, this message translates to:
  /// **'Stop Journey'**
  String get stopJourney;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get eta;

  /// No description provided for @searchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get searchPlace;

  /// No description provided for @searchMusic.
  ///
  /// In en, this message translates to:
  /// **'Search music...'**
  String get searchMusic;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @storagePermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'This app needs access to your device storage to find music files. Please grant permission in app settings.'**
  String get storagePermissionMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @mediaEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Media & Entertainment'**
  String get mediaEntertainment;

  /// No description provided for @deviceTemperature.
  ///
  /// In en, this message translates to:
  /// **'Device Temperature'**
  String get deviceTemperature;

  /// No description provided for @driveConnected.
  ///
  /// In en, this message translates to:
  /// **'Drive Connected. Drive Inspired.'**
  String get driveConnected;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @getWeatherApi.
  ///
  /// In en, this message translates to:
  /// **'Get weather from API'**
  String get getWeatherApi;

  /// No description provided for @getWeatherExternal.
  ///
  /// In en, this message translates to:
  /// **'Get weather from External System'**
  String get getWeatherExternal;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @precipitation.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get precipitation;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update: {time}'**
  String lastUpdate(Object time);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get recenter;

  /// No description provided for @toggleTraffic.
  ///
  /// In en, this message translates to:
  /// **'Toggle Traffic'**
  String get toggleTraffic;

  /// No description provided for @toggleMapMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Map Mode'**
  String get toggleMapMode;

  /// No description provided for @refreshLocationWeather.
  ///
  /// In en, this message translates to:
  /// **'Refresh location & weather'**
  String get refreshLocationWeather;

  /// No description provided for @weatherSource.
  ///
  /// In en, this message translates to:
  /// **'Weather Source'**
  String get weatherSource;

  /// No description provided for @getWeatherFromAPI.
  ///
  /// In en, this message translates to:
  /// **'Get weather from API'**
  String get getWeatherFromAPI;

  /// No description provided for @useOnlineWeatherAPI.
  ///
  /// In en, this message translates to:
  /// **'Use online weather API'**
  String get useOnlineWeatherAPI;

  /// No description provided for @getWeatherFromExternalSystem.
  ///
  /// In en, this message translates to:
  /// **'Get weather from External System'**
  String get getWeatherFromExternalSystem;

  /// No description provided for @useDataProvidedByExternalSystem.
  ///
  /// In en, this message translates to:
  /// **'Use data provided by external system'**
  String get useDataProvidedByExternalSystem;

  /// No description provided for @infotainmentSystem.
  ///
  /// In en, this message translates to:
  /// **'Infotainment System'**
  String get infotainmentSystem;

  /// No description provided for @experienceFutureOfDriving.
  ///
  /// In en, this message translates to:
  /// **'Experience the future of driving.'**
  String get experienceFutureOfDriving;

  /// No description provided for @driveConnectedDriveInspired.
  ///
  /// In en, this message translates to:
  /// **'Drive Connected. Drive Inspired.'**
  String get driveConnectedDriveInspired;

  /// No description provided for @developerInfo.
  ///
  /// In en, this message translates to:
  /// **'Developer Info'**
  String get developerInfo;

  /// No description provided for @developedByAhmedHassan.
  ///
  /// In en, this message translates to:
  /// **'Developed by Ahmed Hassan'**
  String get developedByAhmedHassan;

  /// No description provided for @contentForTitleWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Content for {title} will appear here.'**
  String contentForTitleWillAppearHere(Object title);

  /// No description provided for @deutsch.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get deutsch;

  /// No description provided for @apiKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'API Key Not Set'**
  String get apiKeyNotSet;

  /// No description provided for @apiKeyNotSetDescription.
  ///
  /// In en, this message translates to:
  /// **'To use weather and map features, you must set your Google Cloud API key.'**
  String get apiKeyNotSetDescription;

  /// No description provided for @apiKeyNotSetSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Go to lib/config/api_config.dart\n2. Replace YOUR_API_KEY_HERE with your Google Cloud API key\n3. See API_SETUP.md for detailed instructions'**
  String get apiKeyNotSetSteps;

  /// No description provided for @viewApiSetupGuide.
  ///
  /// In en, this message translates to:
  /// **'View API Setup Guide'**
  String get viewApiSetupGuide;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
