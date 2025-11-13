// lib/pages/marine_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/weather_service.dart';
import '../models/marine_models.dart'; // Correct import for marine models

class MarinePage extends StatefulWidget {
  const MarinePage({Key? key}) : super(key: key);

  @override
  _MarinePageState createState() => _MarinePageState();
}

class _MarinePageState extends State<MarinePage> with AutomaticKeepAliveClientMixin {
  final WeatherService _weatherService = WeatherService();
  Future<MarineForecast>? _marineForecastFuture; // Use MarineForecast
  String? _currentCity;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchMarineData();
  }

  Future<void> _fetchMarineData() async {
    try {
      _currentCity = await _weatherService.getCurrentCity();
      setState(() {
        _marineForecastFuture = _weatherService.getMarineForecast(_currentCity!);
      });
    } catch (e) {
      print("Error fetching current city for marine: $e");
      setState(() {
        _marineForecastFuture = Future.error("Could not get current location for marine: $e");
      });
    }
  }

  // Helper to get image path based on weather condition
  String _getWeatherImageForCondition(String condition) {
    return _weatherService.getWeatherImage(condition);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Marine Forecast",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<MarineForecast>(
        future: _marineForecastFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                    SizedBox(height: 10),
                    Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: Colors.red[300]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchMarineData,
                      child: Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent[100],
                        foregroundColor: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("No marine forecast data available."));
          }

          final MarineForecast marineData = snapshot.data!;

          return Column(
            children: [
              if (_currentCity != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    marineData.locationName, // Use locationName from MarineForecast
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: marineData.forecastDays.length,
                  itemBuilder: (context, index) {
                    final MarineDayForecast day = marineData.forecastDays[index];
                    return _MarineDayForecastCard(
                      day: day,
                      getWeatherImage: _getWeatherImageForCondition,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarineDayForecastCard extends StatelessWidget {
  final MarineDayForecast day;
  final Function(String) getWeatherImage;

  const _MarineDayForecastCard({
    Key? key,
    required this.day,
    required this.getWeatherImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEE, MMM d').format(day.date);
    final String imagePath = getWeatherImage(day.conditionText);

    return Card(
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.lightBlueAccent[100],
                  ),
                ),
                Image.asset(
                  imagePath,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/default.png',
                      width: 40,
                      height: 40,
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            _DetailRow(
              icon: Icons.waves_outlined,
              label: "Max Wave Height: ${day.maxWaveHeightFt} ft",
            ),
            SizedBox(height: 8),
            _DetailRow(
              icon: Icons.wind_power,
              label: "Wind: ${day.minWindKph.round()}-${day.maxWindKph.round()} km/h",
            ),
            SizedBox(height: 8),
            _DetailRow(
              icon: Icons.thermostat_outlined,
              label: "Condition: ${day.conditionText}",
            ),
            SizedBox(height: 15),

            Text(
              "Tides:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            ...day.tides.map((tide) => _TideRow(tide: tide)).toList(),

            SizedBox(height: 15),
            _buildHourlyMarineForecast(context, day.hour, getWeatherImage),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyMarineForecast(BuildContext context, List<MarineHourForecast> hourlyData, Function(String) getWeatherImage) {
    if (hourlyData.isEmpty) {
      return Container();
    }
    return SizedBox(
      height: 100, // Height for horizontal scroll
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          final MarineHourForecast hour = hourlyData[index];
          final String hourTime = DateFormat('h a').format(hour.time);
          final String hourlyImagePath = getWeatherImage(hour.conditionText);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(hourTime, style: TextStyle(color: Colors.white70, fontSize: 12)),
                Image.asset(hourlyImagePath, width: 30, height: 30,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/default.png',
                      width: 30,
                      height: 30,
                    );
                  },
                ),
                Text("${hour.tempC.round()}°C", style: TextStyle(color: Colors.white, fontSize: 14)),
                Text("${hour.windKph.round()} km/h", style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailRow({
    Key? key,
    required this.icon,
    required this.label,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.8)),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _TideRow extends StatelessWidget {
  final Tide tide;

  const _TideRow({Key? key, required this.tide}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tide.type,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          Text(
            DateFormat('h:mm a').format(tide.time),
            style: TextStyle(color: Colors.lightBlueAccent[100], fontSize: 15),
          ),
        ],
      ),
    );
  }
}