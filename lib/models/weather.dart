/// Models for weather data, hourly and daily forecasts.
/// Used by the WeatherController for weather features.
class WeatherData {
  /// The current temperature in degrees.
  final double? temperature;

  /// The current humidity percentage.
  final int? humidity;

  /// The weather type (e.g., 'CLEAR', 'RAIN').
  final String? weatherType;

  /// The weather description.
  final String? description;

  /// The base URI for the weather icon.
  final String? iconBaseUri;

  /// Creates a new [WeatherData] instance.
  WeatherData({
    this.temperature,
    this.humidity,
    this.weatherType,
    this.description,
    this.iconBaseUri,
  });

  /// Creates a [WeatherData] instance from a JSON map.
  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
    temperature: (json['temperature']?['degrees'] as num?)?.toDouble(),
    humidity: (json['relativeHumidity'] as num?)?.toInt(),
    weatherType: json['weatherCondition']?['type']?.toString(),
    description: json['weatherCondition']?['description']?['text'],
    iconBaseUri: json['weatherCondition']?['iconBaseUri'],
  );
}

/// Model for hourly weather forecast data.
class HourlyForecast {
  /// The forecast time.
  final DateTime? time;

  /// The forecasted temperature.
  final double? temperature;

  /// The forecasted cloud cover percentage.
  final double? cloudCover;

  /// The forecasted weather type.
  final String? weatherType;

  /// Creates a new [HourlyForecast] instance.
  HourlyForecast({
    this.time,
    this.temperature,
    this.cloudCover,
    this.weatherType,
  });

  /// Creates a [HourlyForecast] instance from a JSON map.
  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
    time: DateTime.tryParse(json['interval']?['startTime'] ?? ''),
    temperature: (json['temperature']?['degrees'] as num?)?.toDouble(),
    cloudCover: (json['cloudCover'] as num?)?.toDouble(),
    weatherType: json['weatherCondition']?['type'],
  );
}

/// Model for daily weather forecast data.
class DailyForecast {
  /// The forecast date.
  final DateTime? date;

  /// The minimum forecasted temperature.
  final double? minTemperature;

  /// The maximum forecasted temperature.
  final double? maxTemperature;

  /// The forecasted weather type.
  final String? weatherType;

  /// The sun events (e.g., sunrise, sunset) for the day.
  final Map<String, dynamic>? sunEvents;

  /// Creates a new [DailyForecast] instance.
  DailyForecast({
    this.date,
    this.minTemperature,
    this.maxTemperature,
    this.weatherType,
    this.sunEvents,
  });

  /// Creates a [DailyForecast] instance from a JSON map.
  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
    date: DateTime.tryParse(json['interval']?['startTime'] ?? ''),
    minTemperature: (json['minTemperature']?['degrees'] as num?)?.toDouble(),
    maxTemperature: (json['maxTemperature']?['degrees'] as num?)?.toDouble(),
    weatherType: json['daytimeForecast']?['weatherCondition']?['type'],
    sunEvents: json['sunEvents'],
  );
}
