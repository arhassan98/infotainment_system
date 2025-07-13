import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/weather_api_service.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Controller for fetching and managing weather data, forecasts, and city name.
/// Handles API calls, loading states, and error management for weather features.
class WeatherController extends ChangeNotifier {
  WeatherData? weatherData;
  List<HourlyForecast> hourlyForecast = [];
  List<DailyForecast> dailyForecast = [];
  bool isLoading = true;
  bool isHourlyLoading = true;
  bool isDailyLoading = true;
  String? error;
  String? cityName;
  bool isCityLoading = false;

  Future<void> fetchCityName(double latitude, double longitude) async {
    isCityLoading = true;
    notifyListeners();
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=${ApiConfig.googleCloudApiKey}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        String? foundCity;
        for (final result in results) {
          for (final comp in result['address_components']) {
            if ((comp['types'] as List).contains('locality')) {
              foundCity = comp['long_name'];
              break;
            }
          }
          if (foundCity != null) break;
        }
        cityName = foundCity ?? 'Unknown Location';
      } else {
        cityName = 'Unknown Location';
      }
    } catch (e) {
      cityName = 'Unknown Location';
    }
    isCityLoading = false;
    notifyListeners();
  }

  Future<void> fetchWeather(double latitude, double longitude) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await WeatherApiService.fetchWeather(
        latitude: latitude,
        longitude: longitude,
      );
      weatherData = WeatherData.fromJson(data);
      isLoading = false;
    } catch (e) {
      error = e.toString();
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> fetchHourly(double latitude, double longitude) async {
    isHourlyLoading = true;
    notifyListeners();
    try {
      final data = await WeatherApiService.fetchHourlyForecast(
        latitude: latitude,
        longitude: longitude,
      );
      hourlyForecast = List<HourlyForecast>.from(
        data.map((e) => HourlyForecast.fromJson(e)),
      );
      isHourlyLoading = false;
    } catch (e) {
      isHourlyLoading = false;
    }
    notifyListeners();
  }

  Future<void> fetchDaily(double latitude, double longitude) async {
    isDailyLoading = true;
    notifyListeners();
    try {
      final data = await WeatherApiService.fetchDailyForecast(
        latitude: latitude,
        longitude: longitude,
        days: 10,
      );
      dailyForecast = List<DailyForecast>.from(
        data.map((e) => DailyForecast.fromJson(e)),
      );
      isDailyLoading = false;
    } catch (e) {
      isDailyLoading = false;
    }
    notifyListeners();
  }

  void reset() {
    weatherData = null;
    hourlyForecast = [];
    dailyForecast = [];
    isLoading = true;
    isHourlyLoading = true;
    isDailyLoading = true;
    error = null;
    cityName = null;
    isCityLoading = false;
    notifyListeners();
  }
}
