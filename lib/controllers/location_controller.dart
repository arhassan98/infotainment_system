/// Controller for managing location data, navigation, and route calculation.
/// Handles current location, searched location, navigation steps, and polylines.
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class LocationController extends ChangeNotifier {
  /// The current location and navigation data.
  LocationDataModel _locationData = LocationDataModel();

  /// The list of navigation steps for the current route.
  List<NavigationStep> _navigationSteps = [];

  /// The current step index in the navigation steps.
  int _currentStepIndex = 0;

  /// Whether navigation is active.
  bool _isNavigating = false;

  /// Whether auto-navigation is enabled.
  bool _isAutoNavigating = false;

  /// Whether to show the journey on the map.
  bool _showJourney = false;

  /// The Google Places API key.
  String _placesApiKey = ApiConfig.googleCloudApiKey;

  /// Gets the current location and navigation data.
  LocationDataModel get locationData => _locationData;

  /// Gets the list of navigation steps.
  List<NavigationStep> get navigationSteps => _navigationSteps;

  /// Gets the current step index.
  int get currentStepIndex => _currentStepIndex;

  /// Returns true if navigation is active.
  bool get isNavigating => _isNavigating;

  /// Returns true if auto-navigation is enabled.
  bool get isAutoNavigating => _isAutoNavigating;

  /// Returns true if the journey is shown on the map.
  bool get showJourney => _showJourney;

  /// Fetches the current device location and updates [_locationData].
  Future<void> getCurrentLocation() async {
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }
    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }
    final locationData = await location.getLocation();
    _locationData = LocationDataModel(
      currentLocation: LatLng(locationData.latitude!, locationData.longitude!),
      searchedLocation: _locationData.searchedLocation,
      searchedAddress: _locationData.searchedAddress,
      polylines: _locationData.polylines,
      eta: _locationData.eta,
    );
    notifyListeners();
  }

  /// Fetches the route and ETA between the current and searched locations.
  Future<void> getRouteAndEta() async {
    if (_locationData.currentLocation == null ||
        _locationData.searchedLocation == null)
      return;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${_locationData.currentLocation!.latitude},${_locationData.currentLocation!.longitude}&destination=${_locationData.searchedLocation!.latitude},${_locationData.searchedLocation!.longitude}&key=$_placesApiKey&alternatives=true&traffic_model=best_guess&departure_time=now',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];
        final points = _decodePolyline(polyline);
        _locationData = LocationDataModel(
          currentLocation: _locationData.currentLocation,
          searchedLocation: _locationData.searchedLocation,
          searchedAddress: _locationData.searchedAddress,
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Color.fromRGBO(138, 180, 248, 1),
              width: 6,
              points: points,
            ),
          },
          eta: route['legs'][0]['duration']['text'],
        );
        _navigationSteps = [];
        if (route['legs'][0]['steps'] != null) {
          for (var step in route['legs'][0]['steps']) {
            _navigationSteps.add(
              NavigationStep(_stripHtmlTags(step['html_instructions'] ?? '')),
            );
          }
        }
        _currentStepIndex = 0;
        notifyListeners();
      }
    }
  }

  /// Decodes a Google Maps encoded polyline string into a list of [LatLng] points.
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

  /// Removes HTML tags from a string.
  String _stripHtmlTags(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // Add more methods for search, navigation, etc. as needed
}
