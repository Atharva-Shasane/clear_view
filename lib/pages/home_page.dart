// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/weather_service.dart';
import '../models/weather_models.dart';
// Removed astronomy_models.dart import if not strictly used for home page UI itself

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
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
      print("Error fetching current city: $e");
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
          "Current Weather",
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
            return Center(child: Text("No weather data available for this location."));
          }

          final Weather weatherData = snapshot.data!;
          final String imagePath = _getWeatherImageForCondition(weatherData.mainCondition);
          final String currentTime = DateFormat('h:mm a').format(DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  weatherData.cityName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  currentTime,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 30),

                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        imagePath,
                        width: 150,
                        height: 150,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/default.png',
                            width: 150,
                            height: 150,
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      Text(
                        "${weatherData.temperature.round()}°C",
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        weatherData.mainCondition,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.lightBlueAccent[100],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                if (weatherData.forecast.isNotEmpty && weatherData.forecast.first.hour.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hourly Today",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: weatherData.forecast.first.hour.length,
                          itemBuilder: (context, index) {
                            final HourForecast hour = weatherData.forecast.first.hour[index];
                            final String hourTime = DateFormat('h a').format(hour.time);
                            final String hourlyImagePath = _getWeatherImageForCondition(hour.conditionText);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(hourTime, style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  SizedBox(height: 5),
                                  Image.asset(hourlyImagePath, width: 40, height: 40,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/default.png',
                                        width: 40,
                                        height: 40,
                                      );
                                    },
                                  ),
                                  SizedBox(height: 5),
                                  Text("${hour.tempC.round()}°C", style: TextStyle(color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            );
                          },
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