import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Models for location data and navigation steps.
/// Used by the LocationController for navigation and mapping features.
class LocationDataModel {
  /// The current device location as a [LatLng].
  final LatLng? currentLocation;

  /// The searched location as a [LatLng].
  final LatLng? searchedLocation;

  /// The address of the searched location.
  final String? searchedAddress;

  /// The set of polylines representing routes on the map.
  final Set<Polyline> polylines;

  /// The estimated time of arrival (ETA) for the route.
  final String? eta;

  /// Creates a new [LocationDataModel] instance.
  LocationDataModel({
    this.currentLocation,
    this.searchedLocation,
    this.searchedAddress,
    this.polylines = const {},
    this.eta,
  });
}

/// Model representing a single navigation instruction step.
class NavigationStep {
  /// The navigation instruction text.
  final String instruction;

  /// Creates a new [NavigationStep] with the given instruction.
  NavigationStep(this.instruction);
}
