import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for fetching weather data from the Google Weather API.
/// Provides static methods for current, hourly, and daily weather forecasts.
class WeatherApiService {
  static const String _baseUrl = 'https://weather.googleapis.com/v1';

  /// Fetch weather data for the given latitude and longitude.
  /// Returns the raw JSON response as a Map.
  static Future<Map<String, dynamic>> fetchWeather({
    required double latitude,
    required double longitude,
    String unitsSystem = 'METRIC', // or 'IMPERIAL'
  }) async {
    final url = Uri.parse(
      '$_baseUrl/currentConditions:lookup?key=${ApiConfig.googleCloudApiKey}&location.latitude=$latitude&location.longitude=$longitude&unitsSystem=$unitsSystem',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch weather data: ${response.statusCode}');
    }
  }

  /// Fetch hourly weather forecast data for the given location.
  static Future<List<dynamic>> fetchHourlyForecast({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/forecast/hours:lookup?key=${ApiConfig.googleCloudApiKey}&location.latitude=$latitude&location.longitude=$longitude',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['forecastHours'] ?? [];
    } else {
      throw Exception(
        'Failed to fetch hourly forecast: ${response.statusCode}',
      );
    }
  }

  /// Fetch daily weather forecast data for the given location and number of days.
  static Future<List<dynamic>> fetchDailyForecast({
    required double latitude,
    required double longitude,
    int days = 6,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/forecast/days:lookup?key=${ApiConfig.googleCloudApiKey}&location.latitude=$latitude&location.longitude=$longitude&days=$days',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['forecastDays'] ?? [];
    } else {
      throw Exception('Failed to fetch daily forecast: ${response.statusCode}');
    }
  }
}
