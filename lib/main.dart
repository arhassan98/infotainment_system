import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:infotainment_system/views/home_screen.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:location/location.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:infotainment_system/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/music_player_controller.dart';
import 'controllers/weather_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/location_controller.dart';
import 'helpers/location_helper.dart';
import 'package:infotainment_system/config/api_config.dart';

/// Provides the weather source selection for the app (API or external system).
class WeatherSourceProvider extends ChangeNotifier {
  int _weatherSource = 0; // 0 = API, 1 = External System
  int get weatherSource => _weatherSource;
  set weatherSource(int value) {
    if (_weatherSource != value) {
      _weatherSource = value;
      notifyListeners();
    }
  }
}

/// Provides the current locale for the app and allows changing it.
class LocaleProvider extends ChangeNotifier {
  Locale _locale;
  LocaleProvider(this._locale);
  Locale get locale => _locale;
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

/// Loads the saved language index from shared preferences.
Future<int> getSavedLanguageIndex() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('languageIndex') ?? 2;
}

/// The main entry point for the infotainment system app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await _requestStoragePermissions();
  final languageIndex = await getSavedLanguageIndex();
  Locale initialLocale;
  switch (languageIndex) {
    case 0:
      initialLocale = const Locale('ar');
      break;
    case 1:
      initialLocale = const Locale('de');
      break;
    default:
      initialLocale = const Locale('en');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(initialLocale)),
        ChangeNotifierProvider(create: (_) => WeatherSourceProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerController()),
        ChangeNotifierProvider(create: (_) => WeatherController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => LocationController()),
      ],
      child: const InfotainmentApp(),
    ),
  );
}

/// Requests storage permissions required for the app.
Future<void> _requestStoragePermissions() async {
  final storageStatus = await perm.Permission.storage.request();
  final manageStorageStatus = await perm.Permission.manageExternalStorage
      .request();
  // Optionally, handle denied or permanently denied cases here
}

/// The root widget for the infotainment system app.
class InfotainmentApp extends StatefulWidget {
  const InfotainmentApp({super.key});

  @override
  State<InfotainmentApp> createState() => _InfotainmentAppState();
}

/// State for [InfotainmentApp]. Handles location permission and app setup.
class _InfotainmentAppState extends State<InfotainmentApp> {
  @override
  void initState() {
    super.initState();
    _handleLocationPermissionAndFetch();
  }

  /// Handles location permission and fetches the current location.
  Future<void> _handleLocationPermissionAndFetch() async {
    if (kDebugMode) {
      print('Checking location permission...');
    }
    final loc = Location();
    PermissionStatus permissionGranted = await loc.hasPermission();
    if (kDebugMode) {
      print('Initial permission status: $permissionGranted');
    }
    if (permissionGranted == PermissionStatus.denied) {
      if (kDebugMode) {
        print('Requesting location permission...');
      }
      permissionGranted = await loc.requestPermission();
      if (kDebugMode) {
        print('Permission after request: $permissionGranted');
      }
      if (permissionGranted != PermissionStatus.granted) {
        if (kDebugMode) {
          print('Permission denied by user.');
        }
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: Text(
                AppLocalizations.of(context)!.storagePermissionMessage,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          );
        }
        return;
      }
    }
    if (kDebugMode) {
      print('Permission granted, fetching location...');
    }
    await LocationHelper.getCurrentLocation();
    if (kDebugMode) {
      print('Location fetch complete.');
    }
  }

  /// Builds the MaterialApp with localization and theme.
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    // Determine font family based on locale
    String fontFamily = localeProvider.locale.languageCode == 'ar'
        ? 'Cairo'
        : 'SFPRO';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Infotainment System',
      // Use localized app title
      // title: AppLocalizations.of(context)!.appTitle, // Uncomment if needed
      theme: ThemeData.dark(useMaterial3: false)
          .copyWith(scaffoldBackgroundColor: const Color(0xFF0F1B2B))
          .copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: fontFamily),
          ),
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ApiConfig.isValid ? const HomeScreen() : const HelloScreen(),
    );
  }
}

/// A screen that checks the API key and guides the user if it is not set.
class HelloScreen extends StatelessWidget {
  const HelloScreen({super.key});

  /// Builds the HelloScreen UI with API key instructions and language switcher.
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final appLoc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
              const SizedBox(height: 24),
              Text(
                appLoc.apiKeyNotSet,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                appLoc.apiKeyNotSetDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appLoc.apiKeyNotSetSteps,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(appLoc.viewApiSetupGuide),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // Optionally, open the API_SETUP.md or show more help
                },
              ),
              const SizedBox(height: 32),
              // Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appLoc.language + ':',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<Locale>(
                    value: localeProvider.locale,
                    dropdownColor: const Color(0xFF18181C),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: Container(height: 0),
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: Locale('de'),
                        child: Text('Deutsch'),
                      ),
                    ],
                    onChanged: (locale) {
                      if (locale != null) {
                        localeProvider.setLocale(locale);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.43,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2F45),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
