// lib/pages/home_page.dart
import 'package:clear_view/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/weather_service.dart';
import '../models/weather_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final WeatherService _weatherService = WeatherService();
  // We remove the local _weatherFuture and _currentCity.
  // The AppState will provide the city.
  final TextEditingController _citySearchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // We can fetch data for the *initial* city from AppState here.
    // But it's better to do it in the build method with Provider.
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    super.dispose();
  }

  // Fetches weather for the device's current location
  Future<void> _fetchWeatherDataForCurrentLocation() async {
    // Show loading state
    Provider.of<AppState>(context, listen: false)
        .setSearchedCity("Fetching location...");
    try {
      String city = await _weatherService.getCurrentCity();
      // When found, update the *global* AppState
      Provider.of<AppState>(context, listen: false).setSearchedCity(city);
    } catch (e) {
      print("Error fetching current city: $e");
      // If error, update the *global* AppState
      Provider.of<AppState>(context, listen: false)
          .setSearchedCity("Location Error");
    }
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
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlueAccent[100]!)),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30)),
            ),
            style: TextStyle(color: Colors.white),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                // THIS IS THE KEY CHANGE:
                // Update the *global* AppState instead of local state
                Provider.of<AppState>(context, listen: false)
                    .setSearchedCity(value);
              }
              Navigator.pop(dialogContext); // Close dialog
              _citySearchController.clear();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                if (_citySearchController.text.isNotEmpty) {
                  // THIS IS THE KEY CHANGE:
                  // Update the *global* AppState instead of local state
                  Provider.of<AppState>(context, listen: false)
                      .setSearchedCity(_citySearchController.text);
                }
                Navigator.pop(dialogContext); // Close dialog
                _citySearchController.clear();
              },
              child: Text("Search",
                  style: TextStyle(color: Colors.lightBlueAccent[100])),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Get the AppState. This widget will now rebuild when AppState changes.
    final appState = Provider.of<AppState>(context);
    final String currentCity = appState.searchedCityQuery;

    // Helper to get image path based on weather condition
    String _getWeatherImageForCondition(String condition) {
      return _weatherService.getWeatherImage(condition);
    }

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
          IconButton(
            // Button to re-fetch current location
            icon: Icon(Icons.my_location, color: Colors.white),
            onPressed: _fetchWeatherDataForCurrentLocation,
          ),
        ],
      ),
      // We now use the 'currentCity' from AppState to build the Future
      body: FutureBuilder<Weather>(
        future: _weatherService.getWeather(currentCity),
        builder: (context, snapshot) {
          if (currentCity == "Fetching location..." ||
              snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || currentCity == "Location Error") {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red[300], size: 40),
                    SizedBox(height: 10),
                    Text(
                      "Error: ${snapshot.error ?? 'Could not find location.'}",
                      style: TextStyle(color: Colors.red[300]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Retry the last search by just notifying listeners
                        // Or retry current location
                        _fetchWeatherDataForCurrentLocation();
                      },
                      child: Text("Retry Location"),
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
            return Center(
                child:
                Text("No weather data available for this location."));
          }

          final Weather weatherData = snapshot.data!;
          final String imagePath =
          _getWeatherImageForCondition(weatherData.mainCondition);
          final String currentTime =
          DateFormat('h:mm a').format(DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  weatherData.cityName, // Show city from weather data
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white70),
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
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        weatherData.mainCondition,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          color: Colors.lightBlueAccent[100],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                if (weatherData.forecast.isNotEmpty &&
                    weatherData.forecast.first.hour.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hourly Today",
                        style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
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
                            final HourForecast hour =
                            weatherData.forecast.first.hour[index];
                            final String hourTime =
                            DateFormat('h a').format(hour.time);
                            final String hourlyImagePath =
                            _getWeatherImageForCondition(
                                hour.conditionText);

                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(hourTime,
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14)),
                                  SizedBox(height: 5),
                                  Image.asset(hourlyImagePath,
                                      width: 40,
                                      height: 40,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/default.png',
                                          width: 40,
                                          height: 40,
                                        );
                                      }),
                                  SizedBox(height: 5),
                                  Text("${hour.tempC.round()}°C",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16)),
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