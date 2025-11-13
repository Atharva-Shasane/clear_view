// lib/pages/forecast_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/weather_service.dart';
import '../models/weather_models.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({Key? key}) : super(key: key);

  @override
  _ForecastPageState createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> with AutomaticKeepAliveClientMixin {
  final WeatherService _weatherService = WeatherService();
  Future<Weather>? _weatherFuture;
  String? _currentCity; // Can be current location or searched city
  final TextEditingController _citySearchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchWeatherDataForCurrentLocation(); // Initial fetch for current location
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    super.dispose();
  }

  // Fetches weather for the device's current location
  Future<void> _fetchWeatherDataForCurrentLocation() async {
    setState(() {
      _currentCity = "Fetching location..."; // Indicate loading state
      _weatherFuture = null; // Clear previous future
    });
    try {
      String city = await _weatherService.getCurrentCity();
      setState(() {
        _currentCity = city;
        _weatherFuture = _weatherService.getWeather(city);
      });
    } catch (e) {
      print("Error fetching current city for forecast: $e");
      setState(() {
        _currentCity = "Location Error"; // Indicate error
        _weatherFuture = Future.error("Could not get current location. Please allow location access or search manually: $e");
      });
    }
  }

  // Fetches weather for a specified city
  Future<void> _fetchWeatherDataForCity(String cityName) async {
    if (cityName.isEmpty) return;
    setState(() {
      _currentCity = cityName; // Update current city to the searched one
      _weatherFuture = _weatherService.getWeather(cityName);
    });
  }

  // Helper to get image path based on weather condition
  String _getWeatherImageForCondition(String condition) {
    return _weatherService.getWeatherImage(condition);
  }

  // --- Search functionality ---
  void _showCitySearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[800],
          title: Text("Search City", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _citySearchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Enter city name",
              hintStyle: TextStyle(color: Colors.white54),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.lightBlueAccent[100]!)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            ),
            style: TextStyle(color: Colors.white),
            onSubmitted: (value) {
              Navigator.pop(dialogContext); // Close dialog
              _fetchWeatherDataForCity(value); // Fetch weather for the entered city
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _fetchWeatherDataForCity(_citySearchController.text); // Fetch weather
              },
              child: Text("Search", style: TextStyle(color: Colors.lightBlueAccent[100])),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "7-Day Forecast",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: _showCitySearchDialog,
          ),
          IconButton( // Button to re-fetch current location
            icon: Icon(Icons.my_location, color: Colors.white),
            onPressed: _fetchWeatherDataForCurrentLocation,
          ),
        ],
      ),
      body: FutureBuilder<Weather>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _currentCity == "Fetching location...") {
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
                      onPressed: () {
                        if (_currentCity != null && _currentCity != "Location Error") {
                          _fetchWeatherDataForCity(_currentCity!); // Retry for last searched city
                        } else {
                          _fetchWeatherDataForCurrentLocation(); // Retry for current location
                        }
                      },
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
            return Center(child: Text("No forecast data available for this location."));
          }

          final Weather weatherData = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _currentCity!,
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
                  itemCount: weatherData.forecast.length,
                  itemBuilder: (context, index) {
                    final ForecastDay day = weatherData.forecast[index];
                    return _DailyForecastCard(
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

class _DailyForecastCard extends StatelessWidget {
  final ForecastDay day;
  final Function(String) getWeatherImage;

  const _DailyForecastCard({
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${day.maxTempC.round()}°C / ${day.minTempC.round()}°C",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Flexible(
                  child: Text(
                    day.conditionText,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            _buildHourlyForecast(context, day.hour, getWeatherImage),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(BuildContext context, List<HourForecast> hourlyData, Function(String) getWeatherImage) {
    if (hourlyData.isEmpty) {
      return Container();
    }
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          final HourForecast hour = hourlyData[index];
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
              ],
            ),
          );
        },
      ),
    );
  }
}