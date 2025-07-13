import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:weather_icons/weather_icons.dart';
import 'package:weather_animation/weather_animation.dart';
import 'dart:ui'; // Add this for ImageFilter
import 'package:infotainment_system/l10n/app_localizations.dart';
import 'package:infotainment_system/controllers/weather_controller.dart';
import 'package:infotainment_system/models/weather.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:infotainment_system/constants/app_colors.dart';

/// Weather details screen showing current, hourly, and daily weather information.
/// Uses WeatherController and WeatherData models via Provider.
class WeatherDetailsScreen extends StatefulWidget {
  /// The latitude for the weather location.
  final double latitude;

  /// The longitude for the weather location.
  final double longitude;

  /// The optional location name.
  final String? locationName;

  /// Creates a new [WeatherDetailsScreen].
  const WeatherDetailsScreen({
    Key? key,
    this.latitude = 40.7128, // Default: New York
    this.longitude = -74.0060,
    this.locationName,
  }) : super(key: key);

  @override
  State<WeatherDetailsScreen> createState() => _WeatherDetailsScreenState();
}

/// State for [WeatherDetailsScreen]. Handles UI and weather data logic.
class _WeatherDetailsScreenState extends State<WeatherDetailsScreen> {
  late Timer _clockTimer;
  late Timer _refreshTimer;
  DateTime _now = DateTime.now();

  /// Gets the sunrise and sunset times for the current day from the daily forecast.
  Map<String, String> getCurrentDaySunTimes() {
    final dailyForecast = Provider.of<WeatherController>(
      context,
      listen: false,
    ).dailyForecast;
    if (dailyForecast.isEmpty) return {'sunrise': '--', 'sunset': '--'};

    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Find today's forecast
    final todayForecast = dailyForecast.firstWhere(
      (day) =>
          day.date != null &&
          day.date!.toIso8601String().startsWith(todayString),
      orElse: () =>
          dailyForecast.first, // fallback to first day if today not found
    );

    // Get sunrise and sunset from sunEvents object
    final sunEvents = todayForecast.sunEvents;
    final sunrise = sunEvents?['sunriseTime'] ?? '--';
    final sunset = sunEvents?['sunsetTime'] ?? '--';

    // Format the times if they exist (add 2 hours for local timezone)
    String formatTime(String time) {
      if (time == '--') return '--';
      try {
        final dateTime = DateTime.parse(time);
        final localTime = dateTime.add(const Duration(hours: 2));
        return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return time;
      }
    }

    return {'sunrise': formatTime(sunrise), 'sunset': formatTime(sunset)};
  }

  @override
  void initState() {
    super.initState();
    final weatherController = Provider.of<WeatherController>(
      context,
      listen: false,
    );
    weatherController.fetchWeather(widget.latitude, widget.longitude);
    weatherController.fetchHourly(widget.latitude, widget.longitude);
    weatherController.fetchDaily(widget.latitude, widget.longitude);
    if (widget.locationName != null) {
      weatherController.cityName = widget.locationName;
    } else {
      weatherController.fetchCityName(widget.latitude, widget.longitude);
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
    _refreshTimer = Timer.periodic(const Duration(minutes: 60), (_) {
      final weatherController = Provider.of<WeatherController>(
        context,
        listen: false,
      );
      weatherController.fetchWeather(widget.latitude, widget.longitude);
      weatherController.fetchHourly(widget.latitude, widget.longitude);
      weatherController.fetchDaily(widget.latitude, widget.longitude);
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _refreshTimer.cancel();
    super.dispose();
  }

  /// Builds the weather details screen UI.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weatherController = Provider.of<WeatherController>(context);
    final weatherData = weatherController.weatherData;
    final hourlyForecast = weatherController.hourlyForecast;
    final dailyForecast = weatherController.dailyForecast;
    final cityName = weatherController.cityName;
    final isCityLoading = weatherController.isCityLoading;

    return Scaffold(
      backgroundColor: AppColors.black,
      body:
          weatherController.isLoading ||
              weatherController.isHourlyLoading ||
              weatherController.isDailyLoading
          ? _ShimmerLoader()
          : weatherController.error != null
          ? Center(
              child: Text(
                'Error: ${weatherController.error}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                ),
              ),
            )
          : weatherData == null
          ? Center(
              child: Builder(
                builder: (context) => Text(
                  AppLocalizations.of(context)!.noData,
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Stack(
                  children: [
                    // Weather animation background
                    Positioned.fill(
                      child: WrapperScene.weather(
                        scene: getWeatherScene(
                          weatherData.weatherType ?? 'CLEAR',
                          isDay: true,
                        ),
                      ),
                    ),
                    // Content overlay
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back Arrow
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              top: 16.0,
                              bottom: 8.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: AppColors.white,
                                  size: 15,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Main three-column Row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Left Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Clock and Date Card
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 8,
                                            sigmaY: 8,
                                          ),
                                          child: Container(
                                            color: AppColors.black.withOpacity(
                                              0.18,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16.0,
                                                    horizontal: 16.0,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _DigitalClock(now: _now),
                                                  const SizedBox(height: 0),
                                                  _DateRow(now: _now),
                                                  const SizedBox(height: 0),
                                                  // Location
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on,
                                                        color:
                                                            AppColors.white70,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          isCityLoading
                                                              ? 'Loading...'
                                                              : (cityName ??
                                                                    'Unknown'),
                                                          style:
                                                              const TextStyle(
                                                                color: AppColors
                                                                    .white70,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _WeatherChart(hourly: hourlyForecast),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // 2. Center Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 0),
                                      Card(
                                        color: AppColors.black.withOpacity(
                                          0.22,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        margin: EdgeInsets.zero,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18.0,
                                            horizontal: 18.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,

                                            children: [
                                              Center(
                                                child: _CurrentWeatherSummary(
                                                  data: weatherData,
                                                ),
                                              ),
                                              const SizedBox(height: 35),
                                              if (weatherData.description !=
                                                  null)
                                                Text(
                                                  weatherData.description!,
                                                  style: const TextStyle(
                                                    color: AppColors.white70,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              const SizedBox(height: 24),
                                              _MetricsColumn(
                                                data: weatherData,
                                                sunTimes:
                                                    getCurrentDaySunTimes(),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Last update: ${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  color: AppColors.white54,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // 3. Right Column
                                Expanded(
                                  flex: 1,
                                  child: Card(
                                    color: AppColors.black.withOpacity(0.22),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                        horizontal: 12.0,
                                      ),
                                      child: VerticalDailyForecast(
                                        daily: dailyForecast,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Horizontal forecast row (spans all three columns)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              right: 20.0,
                              bottom: 8.0,
                            ),
                            child: _HourlyForecastRow(hourly: hourlyForecast),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// --- Shimmer Loader ---
class _ShimmerLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: AppColors.white.withOpacity(0.7)),
    );
  }
}

// --- Digital Clock ---
class _DigitalClock extends StatelessWidget {
  final DateTime now;
  const _DigitalClock({required this.now});
  @override
  Widget build(BuildContext context) {
    final hour = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return Text(
      '$hour:$min',
      style: const TextStyle(
        fontSize: 40,
        color: AppColors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// --- Date Row ---
class _DateRow extends StatelessWidget {
  final DateTime now;
  const _DateRow({required this.now});
  @override
  Widget build(BuildContext context) {
    final weekday = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ][now.weekday % 7];
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][now.month - 1];
    return Row(
      children: [
        Text(
          '$weekday, $month ${now.day}, ${now.year}',
          style: const TextStyle(color: AppColors.white, fontSize: 18),
        ),
        const SizedBox(width: 8),
        //Icon(Icons.nightlight_round, color: AppColors.white70, size: 20),
      ],
    );
  }
}

// --- Weather Chart (Temperature & Cloud Cover) ---
class _WeatherChart extends StatelessWidget {
  final List<dynamic> hourly;
  const _WeatherChart({required this.hourly});
  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) {
      return Center(
        child: Text(
          'No hourly data available',
          style: TextStyle(color: AppColors.white70),
        ),
      );
    }
    final tempSpots = <FlSpot>[];
    final cloudBars = <BarChartGroupData>[];
    final xLabels = <String>[];
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;
    double maxCloud = 0;
    double? firstAvailableTemp;
    // Pass 1: Find first available temperature
    for (int i = 0; i < hourly.length; i++) {
      final temp = hourly[i]['temperature']?['degrees'];
      if (temp != null) {
        firstAvailableTemp = (temp as num).toDouble();
        break;
      }
    }
    // Find the first index where cloud cover is available
    int firstCloudIdx = hourly.indexWhere((h) => h['cloudCover'] != null);
    if (firstCloudIdx == -1) firstCloudIdx = 0; // fallback if all null
    int x = 0;
    for (int i = firstCloudIdx; i < hourly.length; i++) {
      final hour = hourly[i];
      final temp = hour['temperature']?['degrees'];
      final cloud = hour['cloudCover'];
      final tempVal = temp != null
          ? (temp as num).toDouble()
          : (firstAvailableTemp ?? 0);
      final cloudVal = cloud != null ? (cloud as num).toDouble() : 0.0;
      tempSpots.add(FlSpot(x.toDouble() + 1.4, tempVal));
      if (tempVal < minTemp) minTemp = tempVal;
      if (tempVal > maxTemp) maxTemp = tempVal;
      cloudBars.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: cloudVal,
              color: AppColors.mainBlue.withOpacity(0.7),
              width: 18,
            ),
          ],
        ),
      );
      if (cloudVal > maxCloud) maxCloud = cloudVal;
      xLabels.add(hour['interval']?['startTime']?.substring(11, 16) ?? '--');
      x++;
    }

    minTemp = minTemp == double.infinity ? 0 : minTemp;
    maxTemp = maxTemp == double.negativeInfinity ? 20 : maxTemp;
    maxCloud = maxCloud == 0 ? 100 : maxCloud;
    // Find the minimum and maximum x (hour) values for alignment
    final minX = 0.0;
    final maxX = (hourly.length - 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: AppColors.black.withOpacity(0.18),
                child: SizedBox(
                  height: 240,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tempSpots.length * 60.0,
                      child: Stack(
                        children: [
                          BarChart(
                            BarChartData(
                              barGroups: cloudBars,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  axisNameWidget: const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      'Cloud Cover (%)',
                                      style: TextStyle(
                                        color: AppColors.mainBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toInt()}%',
                                      style: const TextStyle(
                                        color: AppColors.mainBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    interval: ((maxCloud / 4).ceilToDouble()),
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  axisNameWidget: const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      'Temp (°C)',
                                      style: TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toInt()}°',
                                      style: const TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    interval: ((maxTemp - minTemp) / 4)
                                        .ceilToDouble(),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  axisNameWidget: const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Hour',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      return idx >= 0 && idx < xLabels.length
                                          ? Text(
                                              xLabels[idx],
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            )
                                          : const SizedBox.shrink();
                                    },
                                    interval: 1,
                                    reservedSize: 32,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: AppColors.white24),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: ((maxTemp - minTemp) / 4)
                                    .ceilToDouble(),
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: AppColors.white24,
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                ),
                              ),
                              barTouchData: BarTouchData(enabled: false),
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxCloud + 10,
                            ),
                          ),
                          LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: tempSpots,
                                  isCurved: false,
                                  color: AppColors.orange,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.orange.withOpacity(0.25),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, bar, index) {
                                      return FlDotCirclePainter(
                                        radius: 5,
                                        color: AppColors.orange,
                                        strokeWidth: 2,
                                        strokeColor: AppColors.white,
                                      );
                                    },
                                  ),
                                ),
                              ],
                              minX: 0,
                              clipData: FlClipData.all(),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: false),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor: AppColors.black87,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final idx = spot.x.toInt();
                                      final hour = hourly[idx];
                                      final temp =
                                          hour['temperature']?['degrees']
                                              ?.round() ??
                                          '--';
                                      final cloud =
                                          hour['cloudCover']?.round() ?? '--';
                                      final time =
                                          hour['interval']?['startTime']
                                              ?.substring(11, 16) ??
                                          '--';
                                      return LineTooltipItem(
                                        '$time\n$temp°C, $cloud%',
                                        const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              minY: minTemp - 2,
                              maxY: maxTemp + 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Modern Legend with subtle background
          Container(
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 18, height: 6, color: AppColors.orange),
                const SizedBox(width: 6),
                const Text(
                  'Temperature (°C)',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 18),
                Container(width: 18, height: 6, color: AppColors.mainBlue),
                const SizedBox(width: 6),
                const Text(
                  'Cloud cover (%)',
                  style: TextStyle(
                    color: AppColors.mainBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Current Weather Summary ---
class _CurrentWeatherSummary extends StatelessWidget {
  final WeatherData data;
  const _CurrentWeatherSummary({required this.data});
  @override
  Widget build(BuildContext context) {
    final temp = data.temperature?.round() ?? '--';
    final tempMin = '--'; // Not available in WeatherData, unless you add it
    final iconUrl = data.iconBaseUri;
    final desc = data.description ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (iconUrl != null)
          BoxedIcon(
            getWeatherIcon(data.weatherType ?? '', isDay: true),
            size: 48,
            color: AppColors.white,
          ),
        const SizedBox(width: 8),
        Text(
          '$temp°',
          style: const TextStyle(
            fontSize: 64,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$tempMin°',
          style: const TextStyle(
            fontSize: 36,
            color: AppColors.mainBlue,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// --- Metrics Column Widget ---
class _MetricsColumn extends StatelessWidget {
  final WeatherData data;
  final Map<String, String> sunTimes;
  const _MetricsColumn({required this.data, required this.sunTimes});
  @override
  Widget build(BuildContext context) {
    final precip = '--'; // Not available in WeatherData
    final wind = '--'; // Not available in WeatherData
    final windUnit = '';
    final pressure = '--'; // Not available in WeatherData
    final humidity = data.humidity?.toString() ?? '--';
    final sunrise = sunTimes['sunrise'] ?? '--';
    final sunset = sunTimes['sunset'] ?? '--';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricRow(
          icon: WeatherIcons.umbrella,
          value: '$precip%',
          label: 'Precipitation',
        ),
        const SizedBox(height: 8),
        _MetricRow(
          icon: WeatherIcons.strong_wind,
          value: '$wind km/h',
          label: 'Wind',
        ),
        const SizedBox(height: 8),
        _MetricRow(
          icon: WeatherIcons.barometer,
          value: '$pressure hPa',
          label: 'Pressure',
        ),
        const SizedBox(height: 8),
        _MetricRow(
          icon: WeatherIcons.humidity,
          value: '$humidity%',
          label: 'Humidity',
        ),
        const SizedBox(height: 8),
        _MetricRow(
          icon: WeatherIcons.sunrise,
          value: sunrise,
          label: 'Sunrise',
        ),
        const SizedBox(height: 8),
        _MetricRow(icon: WeatherIcons.sunset, value: sunset, label: 'Sunset'),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MetricRow({
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// --- Hourly Forecast Row ---
class _HourlyForecastRow extends StatelessWidget {
  final List<dynamic> hourly;
  const _HourlyForecastRow({required this.hourly});
  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) {
      return Center(
        child: Text(
          'No hourly data available',
          style: TextStyle(color: AppColors.white70),
        ),
      );
    }
    return SizedBox(
      height: 100, // Slightly increased for content
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        itemBuilder: (context, index) {
          final hour = hourly[index];
          final time =
              hour['interval']?['startTime']?.substring(11, 16) ?? '--';
          final temp = hour['temperature']?['degrees']?.round() ?? '--';
          final minTemp =
              hour['feelsLikeTemperature']?['degrees']?.round() ?? '';
          final iconUrl = hour['weatherCondition']?['iconBaseUri'];
          return Container(
            width: 90, // Increased width for better fit
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(
                0.22,
              ), // Darker background for readability
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconUrl != null)
                  BoxedIcon(
                    getWeatherIcon(
                      hour['weatherCondition']['type'],
                      isDay: hour['isDaytime'] ?? true,
                    ),
                    size: 26,
                    color: AppColors.white,
                  ),
                const SizedBox(height: 0),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minTemp°',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (minTemp != '')
                      Text(
                        '   $temp°',
                        style: const TextStyle(
                          color: AppColors.mainBlue,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Vertical Daily Forecast ---
class VerticalDailyForecast extends StatelessWidget {
  final List<dynamic> daily;
  const VerticalDailyForecast({required this.daily});

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return ListView.builder(
      shrinkWrap: true,
      itemCount: daily.length,
      itemBuilder: (context, index) {
        final day = daily[index];
        final date =
            DateTime.tryParse(day['interval']?['startTime'] ?? '') ??
            DateTime.now();
        final weekDay = weekDays[date.weekday % 7];
        final min = day['minTemperature']?['degrees']?.round() ?? '--';
        final max = day['maxTemperature']?['degrees']?.round() ?? '--';
        final type =
            day['daytimeForecast']?['weatherCondition']?['type'] ?? 'CLEAR';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 22.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Text(
                weekDay,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              BoxedIcon(
                getWeatherIcon(type, isDay: true),
                size: 26,
                color: AppColors.white,
              ),
              const SizedBox(width: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$max°',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$min°',
                    style: const TextStyle(
                      color: AppColors.mainBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

IconData getWeatherIcon(String type, {bool isDay = true}) {
  switch (type.toUpperCase()) {
    // Clear/Sunny
    case 'CLEAR':
    case 'SUNNY':
      return isDay ? WeatherIcons.day_sunny : WeatherIcons.night_clear;
    case 'MOSTLY_CLEAR':
    case 'MOSTLY SUNNY':
      return isDay
          ? WeatherIcons.day_sunny_overcast
          : WeatherIcons.night_alt_partly_cloudy;
    case 'PARTLY_SUNNY':
      return isDay
          ? WeatherIcons.day_sunny_overcast
          : WeatherIcons.night_alt_partly_cloudy;
    case 'PARTLY_CLOUDY':
      return isDay ? WeatherIcons.day_cloudy : WeatherIcons.night_alt_cloudy;
    case 'MOSTLY_CLOUDY':
      return isDay
          ? WeatherIcons.day_cloudy_high
          : WeatherIcons.night_alt_cloudy_high;
    case 'CLOUDY':
    case 'OVERCAST':
      return WeatherIcons.cloudy;
    // Wind
    case 'WINDY':
    case 'BREEZY':
      return WeatherIcons.strong_wind;
    case 'WIND_AND_RAIN':
      return isDay
          ? WeatherIcons.day_rain_wind
          : WeatherIcons.night_alt_rain_wind;
    // Rain
    case 'RAIN':
    case 'MODERATE_RAIN':
      return isDay ? WeatherIcons.day_rain : WeatherIcons.night_alt_rain;
    case 'HEAVY_RAIN':
    case 'RAIN_PERIODICALLY_HEAVY':
    case 'MODERATE_TO_HEAVY_RAIN':
      return isDay ? WeatherIcons.day_rain : WeatherIcons.night_alt_rain;
    case 'LIGHT_RAIN':
    case 'LIGHT_TO_MODERATE_RAIN':
      return isDay ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;
    case 'DRIZZLE':
      return isDay ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;
    case 'FREEZING_DRIZZLE':
      return WeatherIcons.sleet;
    // Showers
    case 'SHOWERS':
    case 'RAIN_SHOWERS':
    case 'SCATTERED_SHOWERS':
    case 'CHANCE_OF_SHOWERS':
    case 'LIGHT_RAIN_SHOWERS':
      return isDay ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;
    case 'HEAVY_RAIN_SHOWERS':
      return isDay ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;
    // Snow
    case 'SNOW':
    case 'MODERATE_SNOW':
      return WeatherIcons.snow;
    case 'HEAVY_SNOW':
    case 'SNOW_PERIODICALLY_HEAVY':
    case 'MODERATE_TO_HEAVY_SNOW':
    case 'HEAVY_SNOW_STORM':
      return WeatherIcons.snow_wind;
    case 'LIGHT_SNOW':
    case 'LIGHT_TO_MODERATE_SNOW':
      return WeatherIcons.snow;
    case 'FLURRIES':
    case 'LIGHT_SNOW_SHOWERS':
      return WeatherIcons.snow;
    case 'SNOW_SHOWERS':
    case 'SCATTERED_SNOW_SHOWERS':
    case 'CHANCE_OF_SNOW_SHOWERS':
      return WeatherIcons.snow;
    case 'BLOWING_SNOW':
      return WeatherIcons.snow_wind;
    case 'SNOWSTORM':
      return WeatherIcons.snow_wind;
    // Rain and Snow Mix
    case 'RAIN_AND_SNOW':
    case 'WINTRY_MIX':
      return WeatherIcons.rain_mix;
    // Hail
    case 'HAIL':
    case 'HAIL_SHOWERS':
      return WeatherIcons.hail;
    // Thunderstorm
    case 'THUNDERSTORM':
    case 'THUNDER':
    case 'THUNDERSTORMS':
    case 'THUNDERSHOWER':
    case 'LIGHT_THUNDERSTORM_RAIN':
    case 'SCATTERED_THUNDERSTORMS':
    case 'HEAVY_THUNDERSTORM':
    case 'CHANCE_OF_STORM':
    case 'CHANCE_OF_TSTORM':
      return WeatherIcons.thunderstorm;
    // Fog, Mist, Haze, Smoke, Dust
    case 'FOG':
    case 'MIST':
    case 'HAZE':
      return WeatherIcons.fog;
    case 'SMOKE':
      return WeatherIcons.smoke;
    case 'DUST':
    case 'SAND':
      return WeatherIcons.dust;
    case 'ASH':
      return WeatherIcons.dust;
    // Sleet, Ice, Freezing Rain
    case 'SLEET':
    case 'FREEZING_RAIN':
      return WeatherIcons.sleet;
    case 'ICY':
      return WeatherIcons.snowflake_cold;
    // Squalls, Tornado, Funnel Cloud, Water Spout
    case 'SQUALL':
      return WeatherIcons.strong_wind;
    case 'TORNADO':
      return WeatherIcons.tornado;
    case 'FUNNEL_CLOUD':
      return WeatherIcons.tornado;
    case 'WATER_SPOUT':
      return WeatherIcons.tornado;
    // Default fallback
    default:
      return isDay ? WeatherIcons.day_sunny : WeatherIcons.night_clear;
  }
}

WeatherScene getWeatherScene(String type, {bool isDay = true}) {
  final upperType = type.toUpperCase();

  const scorchingSunTypes = {'CLEAR', 'SUNNY', 'HOT'};
  const frostyTypes = {
    'FROST',
    'FROSTY',
    'ICY',
    'FOG',
    'MIST',
    'HAZE',
    'SMOKE',
    'DUST',
    'SAND',
    'ASH',
  };
  const snowTypes = {
    'SNOW',
    'MODERATE_SNOW',
    'HEAVY_SNOW',
    'SNOW_PERIODICALLY_HEAVY',
    'MODERATE_TO_HEAVY_SNOW',
    'HEAVY_SNOW_STORM',
    'LIGHT_SNOW',
    'LIGHT_TO_MODERATE_SNOW',
    'FLURRIES',
    'LIGHT_SNOW_SHOWERS',
    'SNOW_SHOWERS',
    'SCATTERED_SNOW_SHOWERS',
    'CHANCE_OF_SNOW_SHOWERS',
    'BLOWING_SNOW',
    'SNOWSTORM',
  };
  const sleetTypes = {
    'SLEET',
    'SHOWER_SLEET',
    'RAIN_AND_SNOW',
    'WINTRY_MIX',
    'FREEZING_RAIN',
    'FREEZING_DRIZZLE',
  };
  const stormyTypes = {
    'THUNDERSTORM',
    'THUNDER',
    'THUNDERSTORMS',
    'THUNDERSHOWER',
    'LIGHT_THUNDERSTORM_RAIN',
    'SCATTERED_THUNDERSTORMS',
    'HEAVY_THUNDERSTORM',
    'CHANCE_OF_STORM',
    'CHANCE_OF_TSTORM',
    'STORM',
    'TORNADO',
    'FUNNEL_CLOUD',
    'WATER_SPOUT',
    'HAIL',
    'HAIL_SHOWERS',
  };
  const rainyOvercastTypes = {
    'RAIN',
    'MODERATE_RAIN',
    'HEAVY_RAIN',
    'RAIN_PERIODICALLY_HEAVY',
    'MODERATE_TO_HEAVY_RAIN',
    'LIGHT_RAIN',
    'LIGHT_TO_MODERATE_RAIN',
    'DRIZZLE',
    'SHOWERS',
    'RAIN_SHOWERS',
    'SCATTERED_SHOWERS',
    'CHANCE_OF_SHOWERS',
    'LIGHT_RAIN_SHOWERS',
    'HEAVY_RAIN_SHOWERS',
    'CLOUDY',
    'OVERCAST',
    'MOSTLY_CLOUDY',
    'PARTLY_CLOUDY',
    'MOSTLY_CLEAR',
    'MOSTLY SUNNY',
    'PARTLY_SUNNY',
  };
  const windyTypes = {'WINDY', 'BREEZY', 'SQUALL'};

  if (scorchingSunTypes.contains(upperType)) return WeatherScene.scorchingSun;
  if (frostyTypes.contains(upperType)) return WeatherScene.frosty;
  if (snowTypes.contains(upperType)) return WeatherScene.snowfall;
  if (sleetTypes.contains(upperType)) return WeatherScene.showerSleet;
  if (stormyTypes.contains(upperType)) return WeatherScene.stormy;
  if (rainyOvercastTypes.contains(upperType)) return WeatherScene.rainyOvercast;
  if (windyTypes.contains(upperType)) return WeatherScene.weatherEvery;

  // Default fallback
  return WeatherScene.sunset;
}
