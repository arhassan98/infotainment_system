import 'package:location/location.dart';
import 'package:flutter/foundation.dart';

/// Helper for obtaining the device's current location using the location package.
/// Handles permission requests and service checks.
class LocationHelper {
  /// Gets the current device location, requesting permissions and enabling services as needed.
  /// Returns a [LocationData] object if successful, or null if permissions are denied or service is unavailable.
  static Future<LocationData?> getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    LocationData locationData = await location.getLocation();
    if (kDebugMode) {
      print(
        'Lat:  [32m [1m [4m [7m${locationData.latitude} [0m, Lng:  [32m [1m [4m [7m${locationData.longitude} [0m',
      );
    }
    return locationData;
  }
}
