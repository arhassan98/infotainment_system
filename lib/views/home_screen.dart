import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:infotainment_system/views/music_player.dart';
import 'package:thermal/thermal.dart';
import 'dart:ui';
import 'package:hugeicons/hugeicons.dart';
import 'package:infotainment_system/views/settings_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'package:location/location.dart';
import 'dart:async';
import 'package:infotainment_system/views/weather_details_screen.dart';
import 'package:infotainment_system/l10n/app_localizations.dart';
import 'package:weather_animation/weather_animation.dart';
import '../config/api_config.dart';
import 'package:infotainment_system/controllers/location_controller.dart';
import 'package:infotainment_system/models/location.dart';
import 'package:infotainment_system/controllers/music_player_controller.dart';
import '../main.dart'; // for WeatherSourceProvider
import 'package:infotainment_system/services/weather_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infotainment_system/constants/app_colors.dart';
import 'package:infotainment_system/views/weather_details_screen.dart'
    show getWeatherScene;

/// Home screen of the infotainment system app.
/// Provides navigation to music, phone, weather, and settings features.
/// Uses LocationController, MusicPlayerController, and WeatherController via Provider.
final GlobalKey<_HomeContentState> homeContentKey =
    GlobalKey<_HomeContentState>();

/// Converts Western Arabic numerals in a string to Eastern Arabic numerals.
String toArabicNumbers(String input) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < western.length; i++) {
    input = input.replaceAll(western[i], arabic[i]);
  }

  return input;
}

/// The main home screen widget for the infotainment system.
class HomeScreen extends StatefulWidget {
  /// Creates a new [HomeScreen].
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State for [HomeScreen]. Handles navigation and UI state.
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  /// Builds the main UI for the home screen, including navigation and bottom bar.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeContent(),
          Center(
            child: Builder(
              builder: (context) => Text(
                AppLocalizations.of(context)!.music,
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ),
          Center(
            child: Builder(
              builder: (context) => Text(
                AppLocalizations.of(context)!.phone,
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ),
          SettingsScreen(
            onSettingsChanged: () {
              final homeContentState = homeContentKey.currentState;
              homeContentState?._loadWeatherSourceAndData();
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.35),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: AppColors.mainBlue.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.black.withOpacity(0.38),
                    AppColors.mainBlue.withOpacity(0.08),
                    AppColors.black.withOpacity(0.42),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.white.withOpacity(0.18),
                    width: 1.5,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.mainBlue,
                unselectedItemColor: AppColors.white54,
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: [
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedHome01,
                      size: 32,
                      color: _selectedIndex == 0
                          ? AppColors.mainBlue
                          : Theme.of(context)
                                    .bottomNavigationBarTheme
                                    .unselectedItemColor ??
                                AppColors.white54,
                    ),
                    label: AppLocalizations.of(context)!.home,
                  ),
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedMusicNote01,
                      size: 32,
                      color: _selectedIndex == 1
                          ? AppColors.mainBlue
                          : Theme.of(context)
                                    .bottomNavigationBarTheme
                                    .unselectedItemColor ??
                                AppColors.white54,
                    ),
                    label: AppLocalizations.of(context)!.music,
                  ),
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCall,
                      size: 32,
                      color: _selectedIndex == 2
                          ? AppColors.mainBlue
                          : Theme.of(context)
                                    .bottomNavigationBarTheme
                                    .unselectedItemColor ??
                                AppColors.white54,
                    ),
                    label: AppLocalizations.of(context)!.phone,
                  ),
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSettings01,
                      size: 32,
                      color: _selectedIndex == 3
                          ? AppColors.mainBlue
                          : Theme.of(context)
                                    .bottomNavigationBarTheme
                                    .unselectedItemColor ??
                                AppColors.white54,
                    ),
                    label: AppLocalizations.of(context)!.settings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late DateTime _now;
  late String _time;
  late String _date;
  late bool _showColon;
  GoogleMapController? _mapController;
  LatLng? _searchedLocation;
  String? _searchedAddress;
  LatLng? _currentLocation;
  Set<Polyline> _polylines = {};
  String? _eta;
  final List<String> _placeTypes = [
    'restaurant',
    'gas_station',
    'atm',
    'cafe',
    'parking',
    'hospital',
  ];
  String _selectedNearbyType = 'restaurant';
  List<Map<String, dynamic>> _nearbyPlaces = [];
  Map<String, dynamic>? _selectedPlace;
  bool _showJourney = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _autocompleteSuggestions = [];
  bool _isSearching = false;
  OverlayEntry? _autocompleteOverlay;
  String _placesApiKey = ApiConfig.googleCloudApiKey;
  bool _isNavigating = false;
  List<String> _navigationSteps = [];
  FlutterTts _tts = FlutterTts();
  int _currentStepIndex = 0;
  bool _isAutoNavigating = false;
  Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  bool _showTraffic = true;
  MapType _mapType = MapType.normal;
  List<String> _mapModes = ['normal', 'satellite', 'terrain', '3d'];
  int _mapModeIndex = 0;
  double? _apiTemperature;
  int? _apiHumidity;
  String? _weatherType;
  bool _loadingWeather = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
      _startColonBlink();
      _getCurrentLocation();
    });

    _now = DateTime.now();
    _updateTime();
    _showColon = true;

    _loadWeatherSourceAndData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final weatherSource = context.watch<WeatherSourceProvider>().weatherSource;
    // Update date with correct locale
    _updateTime(context);
    if (weatherSource == 0) {
      _fetchWeatherData();
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      final newNow = DateTime.now();
      if (mounted && (newNow.minute != _now.minute || newNow.day != _now.day)) {
        setState(() {
          _now = newNow;
          _updateTime();
        });
      }
      return mounted;
    });
  }

  void _startColonBlink() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _showColon = !_showColon;
        });
      }
      return mounted;
    });
  }

  void _updateTime([BuildContext? context]) {
    _time = DateFormat('HH:mm').format(_now);
    // Use Arabic locale if the app's language is Arabic
    final locale = context != null ? Localizations.localeOf(context) : null;
    if (locale != null && locale.languageCode == 'ar') {
      _date = DateFormat('EEE d MMM', 'ar').format(_now);
    } else {
      _date = DateFormat('EEE MMM d').format(_now);
    }
  }

  Future<void> _getCurrentLocation() async {
    loc.Location location = loc.Location();
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;
    loc.LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();

    // print("_locationData: 1");

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // print("_locationData: 2");

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    final newLocation = LatLng(
      _locationData.latitude!,
      _locationData.longitude!,
    );
    setState(() {
      _currentLocation = newLocation;
    });

    // print("_locationData: ${_locationData}");
    // Move camera if map is ready
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
    }
    // Fetch weather data if using API
    if (context.mounted &&
        context.read<WeatherSourceProvider>().weatherSource == 0) {
      _fetchWeatherData();
    }
  }

  Future<void> _getRouteAndEta() async {
    if (_currentLocation == null || _searchedLocation == null) return;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${_searchedLocation!.latitude},${_searchedLocation!.longitude}&key=$_placesApiKey&alternatives=true&traffic_model=best_guess&departure_time=now',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];
        final points = _decodePolyline(polyline);
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: AppColors.mainBlue,
              width: 6,
              points: points,
            ),
          };
          _eta = route['legs'][0]['duration']['text'];
          // Extract navigation steps
          _navigationSteps = [];
          if (route['legs'][0]['steps'] != null) {
            for (var step in route['legs'][0]['steps']) {
              _navigationSteps.add(
                _stripHtmlTags(step['html_instructions'] ?? ''),
              );
            }
          }
          _currentStepIndex = 0;
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  String _stripHtmlTags(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Future<void> _searchNearbyPlacesAroundSelected() async {
    if (_searchedLocation == null) return;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${_searchedLocation!.latitude},${_searchedLocation!.longitude}'
      '&radius=2000'
      '&type=$_selectedNearbyType'
      '&key=$_placesApiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      setState(() {
        _nearbyPlaces = List<Map<String, dynamic>>.from(data['results']);
      });
    } else {
      setState(() {
        _nearbyPlaces = [];
      });
    }
  }

  Future<void> _selectPlaceAndRoute(Map<String, dynamic> place) async {
    final lat = place['geometry']['location']['lat'] as double;
    final lng = place['geometry']['location']['lng'] as double;
    setState(() {
      _selectedPlace = place;
      _searchedLocation = LatLng(lat, lng);
      _searchedAddress = place['name'];
      _showJourney = false;
    });
    await _getRouteAndEta();
    setState(() {
      _showJourney = true;
    });
    // Move camera to selected place
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }
  }

  Future<void> _getAutocompleteSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _autocompleteSuggestions = []);
      return;
    }
    setState(() => _isSearching = true);
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&key=$_placesApiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      setState(() => _autocompleteSuggestions = data['predictions']);
    } else {
      setState(() => _autocompleteSuggestions = []);
    }
    setState(() => _isSearching = false);
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$_placesApiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      return data['result'];
    } else {
      return null;
    }
  }

  Future<void> _speakCurrentStep() async {
    if (_navigationSteps.isNotEmpty &&
        _currentStepIndex < _navigationSteps.length) {
      await _tts.speak(_navigationSteps[_currentStepIndex]);
    }
  }

  Future<void> _goToStep(int index) async {
    if (_navigationSteps.isEmpty ||
        index < 0 ||
        index >= _navigationSteps.length)
      return;
    setState(() {
      _currentStepIndex = index;
    });
    // Animate camera to step location
    final data = await _getRouteStepLatLng(index);
    if (data != null && _mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLng(data));
    }
    await _speakCurrentStep();
  }

  Future<LatLng?> _getRouteStepLatLng(int index) async {
    // Re-fetch the route to get step locations
    if (_currentLocation == null || _searchedLocation == null) return null;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${_searchedLocation!.latitude},${_searchedLocation!.longitude}&key=$_placesApiKey&alternatives=true&traffic_model=best_guess&departure_time=now',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final steps = data['routes'][0]['legs'][0]['steps'];
        if (steps != null && index < steps.length) {
          final lat = steps[index]['end_location']['lat'] as double;
          final lng = steps[index]['end_location']['lng'] as double;
          return LatLng(lat, lng);
        }
      }
    }
    return null;
  }

  Future<void> _autoNavigate() async {
    setState(() {
      _isAutoNavigating = true;
    });
    for (int i = _currentStepIndex; i < _navigationSteps.length; i++) {
      if (!_isAutoNavigating) break;
      await _goToStep(i);
      await Future.delayed(const Duration(seconds: 3));
    }
    setState(() {
      _isAutoNavigating = false;
    });
  }

  void _stopAutoNavigate() {
    setState(() {
      _isAutoNavigating = false;
    });
  }

  void _startFollowingLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      if (_isNavigating &&
          _mapController != null &&
          locationData.latitude != null &&
          locationData.longitude != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(locationData.latitude!, locationData.longitude!),
              zoom: 19.0,
              tilt: 70,
              bearing: locationData.heading ?? 0,
            ),
          ),
        );
      }
    });
  }

  void _stopFollowingLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _stopJourney() {
    setState(() {
      _isNavigating = false;
      _showJourney = false;
    });
    _stopFollowingLocation();
  }

  Future<void> _loadWeatherSourceAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final weatherSource = prefs.getInt('weatherSource') ?? 0;
    if (weatherSource == 0) {
      setState(() {
        _loadingWeather = true;
      });
      // Use a default location or get current location as needed
      final lat = _currentLocation?.latitude ?? 48.8287587;
      final lon = _currentLocation?.longitude ?? 12.9548628;
      try {
        final data = await WeatherApiService.fetchWeather(
          latitude: lat,
          longitude: lon,
        );
        setState(() {
          _apiTemperature = (data['temperature']?['degrees'] as num?)
              ?.toDouble();
          _apiHumidity = (data['relativeHumidity'] as num?)?.toInt();
          _weatherType = data['weatherCondition']?['type']?.toString();
          _loadingWeather = false;
        });
      } catch (e) {
        setState(() {
          _loadingWeather = false;
        });
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _loadingWeather = true;
    });
    final lat = _currentLocation?.latitude ?? 48.8287587;
    final lon = _currentLocation?.longitude ?? 12.9548628;
    if (kDebugMode) {
      print('Fetching current weather for location: lat=$lat, lon=$lon');
    }
    try {
      final data = await WeatherApiService.fetchWeather(
        latitude: lat,
        longitude: lon,
      );
      setState(() {
        _apiTemperature = (data['temperature']?['degrees'] as num?)?.toDouble();
        _apiHumidity = (data['relativeHumidity'] as num?)?.toInt();
        _weatherType = data['weatherCondition']?['type']?.toString();
        _loadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _loadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicController = Provider.of<MusicPlayerController>(context);
    final weatherSource = context.watch<WeatherSourceProvider>().weatherSource;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(),
            ),
            Row(
              children: [
                // Left column: Info + mini player
                Container(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Place type dropdown

                        // Enhanced Time and date
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _date, // e.g., "Tue Apr 1"
                              style: TextStyle(
                                fontSize:
                                    Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'ar'
                                    ? 20
                                    : 24,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white.withOpacity(0.7),
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: AppColors.black.withOpacity(0.3),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 0),
                            Builder(
                              builder: (context) {
                                final locale = Localizations.localeOf(context);
                                final hour = _time.substring(0, 2);
                                final minute = _time.substring(3, 5);
                                final isArabic = locale.languageCode == 'ar';
                                final hourDisplay = isArabic
                                    ? toArabicNumbers(hour)
                                    : hour;
                                final minuteDisplay = isArabic
                                    ? toArabicNumbers(minute)
                                    : minute;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isArabic ? minuteDisplay : hourDisplay,
                                      style: TextStyle(
                                        fontSize: isArabic ? 80 : 96,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.white.withOpacity(0.7),
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 16,
                                            color: AppColors.black.withOpacity(
                                              0.4,
                                            ),
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedOpacity(
                                      opacity: _showColon ? 1.0 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Text(
                                        ':',
                                        style: TextStyle(
                                          fontSize: isArabic ? 80 : 96,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.white.withOpacity(
                                            0.7,
                                          ),
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 16,
                                              color: AppColors.black
                                                  .withOpacity(0.4),
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isArabic ? hourDisplay : minuteDisplay,
                                      style: TextStyle(
                                        fontSize: isArabic ? 80 : 96,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.white.withOpacity(0.7),
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 16,
                                            color: AppColors.black.withOpacity(
                                              0.4,
                                            ),
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        // Temperature & Humidity
                        if (weatherSource == 0)
                          FutureBuilder<int?>(
                            future: _getDeviceTemperature(),
                            builder: (context, snapshot) {
                              final deviceTemp = snapshot.data?.toDouble();
                              return GestureDetector(
                                onTap: () {
                                  if (_currentLocation != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WeatherDetailsScreen(
                                              latitude:
                                                  _currentLocation!.latitude,
                                              longitude:
                                                  _currentLocation!.longitude,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                child: AnimatedWeatherHighlight(
                                  temperature: _apiTemperature,
                                  humidity: _apiHumidity,
                                  deviceTemperature: deviceTemp,
                                  weatherType: _weatherType,
                                ),
                              );
                            },
                          )
                        else
                          Opacity(
                            opacity: 1,
                            child: IgnorePointer(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InfoCard(
                                      title: 'Temperature',
                                      value: '22°C',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InfoCard(
                                      title: 'Humidity',
                                      value: '60%',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Mini music player
                        Consumer<MusicPlayerController>(
                          builder: (context, controller, child) {
                            return MiniMusicPlayer(
                              player: controller.player,
                              song: controller.currentSong,
                              isPlaying: controller.isPlaying,
                              position: controller.position,
                              duration: controller.duration,
                              onPlayPause: controller.playPause,
                              onNext: controller.nextSong,
                              onPrevious: controller.previousSong,
                              onOpenFullPlayer: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MusicPlayerScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Right column: Map view with search
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                _searchedLocation ??
                                _currentLocation ??
                                LatLng(48.8287587, 12.9548628),
                            zoom: 12,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          zoomGesturesEnabled: true,
                          compassEnabled: true,
                          mapToolbarEnabled: true,
                          trafficEnabled: _showTraffic,
                          buildingsEnabled: true,
                          indoorViewEnabled: true,
                          tiltGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          mapType: _mapType,
                          onMapCreated: (controller) {
                            _mapController = controller;
                            controller.setMapStyle(_darkMapStyle);
                            if (_currentLocation != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLng(_currentLocation!),
                              );
                            }
                          },
                          markers: {
                            // Marker for searched location
                            if (_searchedLocation != null)
                              Marker(
                                markerId: const MarkerId('searched'),
                                position: _searchedLocation!,
                                infoWindow: InfoWindow(
                                  title:
                                      _searchedAddress ?? 'Selected Location',
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueAzure,
                                ),
                              ),
                            // Markers for nearby places
                            ..._nearbyPlaces.map((place) {
                              final lat =
                                  place['geometry']['location']['lat']
                                      as double;
                              final lng =
                                  place['geometry']['location']['lng']
                                      as double;
                              final isSelected = _selectedPlace == place;
                              return Marker(
                                markerId: MarkerId(
                                  place['place_id'] ?? place['name'],
                                ),
                                position: LatLng(lat, lng),
                                infoWindow: InfoWindow(title: place['name']),
                                icon: isSelected
                                    ? BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueGreen,
                                      )
                                    : BitmapDescriptor.defaultMarker,
                                onTap: () => _selectPlaceAndRoute(place),
                              );
                            }),
                          },
                          polylines: _polylines,
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            children: [
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(16),
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(color: AppColors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search for a place',
                                    hintStyle: TextStyle(
                                      color: AppColors.white70,
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFF232B3A),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: AppColors.mainBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: AppColors.mainBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: AppColors.mainBlue,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: AppColors.mainBlue,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _getAutocompleteSuggestions(value);
                                  },
                                ),
                              ),
                              if (_autocompleteSuggestions.isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF232B3A),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: BoxConstraints(maxHeight: 220),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _autocompleteSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final suggestion =
                                          _autocompleteSuggestions[index];
                                      return ListTile(
                                        tileColor: Colors.transparent,
                                        title: Text(
                                          suggestion['description'] ?? '',
                                          style: TextStyle(
                                            color: AppColors.white,
                                          ),
                                        ),
                                        hoverColor: AppColors.mainBlue
                                            .withOpacity(0.08),
                                        onTap: () async {
                                          FocusScope.of(context).unfocus();
                                          setState(() {
                                            _searchController.text =
                                                suggestion['description'] ?? '';
                                            _autocompleteSuggestions = [];
                                            _showJourney = false;
                                          });
                                          final details =
                                              await _getPlaceDetails(
                                                suggestion['place_id'],
                                              );
                                          if (details != null &&
                                              details['geometry'] != null) {
                                            final lat =
                                                details['geometry']['location']['lat']
                                                    as double;
                                            final lng =
                                                details['geometry']['location']['lng']
                                                    as double;
                                            setState(() {
                                              _searchedLocation = LatLng(
                                                lat,
                                                lng,
                                              );
                                              _searchedAddress =
                                                  details['name'] ??
                                                  suggestion['description'];
                                            });
                                            _mapController?.animateCamera(
                                              CameraUpdate.newLatLng(
                                                LatLng(lat, lng),
                                              ),
                                            );
                                            await _getRouteAndEta();
                                            setState(() {
                                              _showJourney = true;
                                            });
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_eta != null)
                          Positioned(
                            top: 80,
                            right: 30,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    color: AppColors.mainBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ETA: $_eta',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_showJourney && _searchedLocation != null)
                          Positioned(
                            bottom: 32,
                            left: 32,
                            right: 32,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainBlue,
                                foregroundColor: AppColors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                _isNavigating
                                    ? Icons.stop
                                    : Icons.directions_car,
                              ),
                              label: Text(
                                _isNavigating
                                    ? AppLocalizations.of(context)!.stopJourney
                                    : AppLocalizations.of(
                                        context,
                                      )!.startJourney,
                              ),
                              onPressed: () async {
                                if (_isNavigating) {
                                  _stopJourney();
                                } else {
                                  setState(() {
                                    _isNavigating = true;
                                    _mapType = MapType.normal;
                                    _mapModeIndex = _mapModes.indexOf('3d');
                                  });
                                  if (_mapController != null &&
                                      _currentLocation != null) {
                                    await _mapController!.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: _currentLocation!,
                                          zoom: 19,
                                          tilt: 70,
                                          bearing: 0,
                                        ),
                                      ),
                                    );
                                  }
                                  _startFollowingLocation();
                                }
                              },
                            ),
                          ),
                        Positioned(
                          top: 20,
                          // Move controls to left for Arabic, right otherwise
                          left:
                              Localizations.localeOf(context).languageCode ==
                                  'ar'
                              ? 20
                              : null,
                          right:
                              Localizations.localeOf(context).languageCode ==
                                  'ar'
                              ? null
                              : 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(height: 70), // space below search bar
                              FloatingActionButton(
                                heroTag: 'zoom_in',
                                mini: true,
                                backgroundColor: AppColors.white,
                                child: Icon(Icons.add, color: AppColors.black),
                                onPressed: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.zoomIn(),
                                  );
                                },
                                tooltip: AppLocalizations.of(context)!.zoomIn,
                              ),
                              SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: 'zoom_out',
                                mini: true,
                                backgroundColor: AppColors.white,
                                child: Icon(
                                  Icons.remove,
                                  color: AppColors.black,
                                ),
                                onPressed: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.zoomOut(),
                                  );
                                },
                                tooltip: AppLocalizations.of(context)!.zoomOut,
                              ),
                              SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: 'recenter',
                                mini: true,
                                backgroundColor: AppColors.white,
                                child: Icon(
                                  Icons.my_location,
                                  color: AppColors.black,
                                ),
                                onPressed: () async {
                                  if (_currentLocation != null) {
                                    await _mapController?.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: _currentLocation!,
                                          zoom: 19.0,
                                          tilt: 70,
                                          bearing: 0,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                tooltip: AppLocalizations.of(context)!.recenter,
                              ),
                              SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: 'traffic',
                                mini: true,
                                backgroundColor: _showTraffic
                                    ? AppColors.mainBlue
                                    : AppColors.white,
                                child: Icon(
                                  Icons.traffic,
                                  color: _showTraffic
                                      ? AppColors.black
                                      : AppColors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showTraffic = !_showTraffic;
                                  });
                                },
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.toggleTraffic,
                              ),
                              SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: 'map_mode',
                                mini: true,
                                backgroundColor: AppColors.white,
                                child: Icon(
                                  Icons.threed_rotation,
                                  color: AppColors.black,
                                ),
                                onPressed: () async {
                                  setState(() {
                                    _mapModeIndex =
                                        (_mapModeIndex + 1) % _mapModes.length;
                                  });
                                  final mode = _mapModes[_mapModeIndex];
                                  if (mode == 'normal') {
                                    setState(() {
                                      _mapType = MapType.normal;
                                    });
                                    if (_mapController != null &&
                                        _currentLocation != null) {
                                      await _mapController!.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            target: _currentLocation!,
                                            zoom: 16,
                                            tilt: 0,
                                          ),
                                        ),
                                      );
                                    }
                                  } else if (mode == 'satellite') {
                                    setState(() {
                                      _mapType = MapType.satellite;
                                    });
                                  } else if (mode == 'terrain') {
                                    setState(() {
                                      _mapType = MapType.terrain;
                                    });
                                  } else if (mode == '3d') {
                                    setState(() {
                                      _mapType = MapType.normal;
                                    });
                                    if (_mapController != null &&
                                        _currentLocation != null) {
                                      await _mapController!.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            target: _currentLocation!,
                                            zoom: 19,
                                            tilt: 70,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.toggleMapMode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Overlay to dismiss keyboard when open
            if (MediaQuery.of(context).viewInsets.bottom > 0)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Container(color: Colors.transparent),
                ),
              ),
            // Floating action button to center on current location
            Positioned(
              bottom: 32,
              left: Localizations.localeOf(context).languageCode == 'ar'
                  ? 32
                  : null,
              right: Localizations.localeOf(context).languageCode == 'ar'
                  ? null
                  : 32,
              child: FloatingActionButton(
                backgroundColor: AppColors.mainBlue,
                child: const Icon(Icons.my_location, color: AppColors.black),
                onPressed: _getCurrentLocation,
                tooltip: AppLocalizations.of(context)!.refreshLocationWeather,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tts.stop();
    _stopFollowingLocation();
    super.dispose();
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (title == 'Temperature') {
      // Show two lines: climate and device temperature
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            SizedBox(
              height: Localizations.localeOf(context).languageCode == 'ar'
                  ? 0
                  : 8,
            ),
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isArabic
                        ? toArabicNumbers(value.replaceAll('°C', '°'))
                        : value.replaceAll('°C', '°'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.phone_android,
                  color: AppColors.mainBlue,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FutureBuilder<int?>(
                    future: _getDeviceTemperature(),
                    builder: (context, snapshot) {
                      final temp = snapshot.data;
                      final tempStr = temp != null ? '$temp°' : '--°';
                      return Text(
                        isArabic ? toArabicNumbers(tempStr) : tempStr,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(
              height: Localizations.localeOf(context).languageCode == 'ar'
                  ? 0
                  : 8,
            ),
            Text(
              isArabic ? toArabicNumbers(value) : value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
          ],
        ),
      );
    }
  }
}

Future<int?> _getDeviceTemperature() async {
  try {
    final _thermal = Thermal();
    final temp = await _thermal.onBatteryTemperatureChanged.first;
    return temp?.round();
  } catch (e) {
    return null;
  }
}

const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#212121"}
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#212121"}
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#9e9e9e"}
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#bdbdbd"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {"color": "#181818"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#616161"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#1b1b1b"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {"color": "#2c2c2c"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#8a8a8a"}
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {"color": "#373737"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {"color": "#3c3c3c"}
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [
      {"color": "#4e4e4e"}
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#616161"}
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {"color": "#2f2f2f"}
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#000000"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#3d3d3d"}
    ]
  }
]
''';

class AnimatedWeatherInfoCard extends StatelessWidget {
  final double? temperature;
  final String? weatherType;
  const AnimatedWeatherInfoCard({Key? key, this.temperature, this.weatherType})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      children: [
        if (weatherType != null)
          SizedBox(
            height: 48,
            child: WrapperScene.weather(scene: getWeatherScene(weatherType!)),
          ),
        InfoCard(
          title: 'Temperature',
          value: temperature != null ? '${temperature!.round()}°C' : '--',
        ),
      ],
    );
  }
}

class AnimatedWeatherHighlight extends StatelessWidget {
  final double? temperature;
  final int? humidity;
  final double? deviceTemperature;
  final String? weatherType;
  const AnimatedWeatherHighlight({
    Key? key,
    this.temperature,
    this.humidity,
    this.deviceTemperature,
    this.weatherType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (weatherType != null)
            WrapperScene.weather(scene: getWeatherScene(weatherType!)),
          // Subtle overlay for readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.black.withOpacity(0.35),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MetricHighlight(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: temperature != null
                      ? (isArabic
                            ? toArabicNumbers('${temperature!.round()}°')
                            : '${temperature!.round()}°C')
                      : (isArabic ? toArabicNumbers('--') : '--'),
                  color: Colors.orangeAccent,
                ),
                _MetricHighlight(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: humidity != null
                      ? (isArabic
                            ? toArabicNumbers('$humidity%')
                            : '$humidity%')
                      : (isArabic ? toArabicNumbers('--') : '--'),
                  color: Colors.blueAccent,
                ),
                _MetricHighlight(
                  icon: Icons.phone_android,
                  label: 'Mobile',
                  value: deviceTemperature != null
                      ? (isArabic
                            ? toArabicNumbers('${deviceTemperature!.round()}°')
                            : '${deviceTemperature!.round()}°C')
                      : (isArabic ? toArabicNumbers('--') : '--'),
                  color: AppColors.mainBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricHighlight extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricHighlight({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            shadows: [
              Shadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
