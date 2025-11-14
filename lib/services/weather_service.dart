// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// Your existing models
import '../models/weather_models.dart';
import '../models/astronomy_models.dart';
import '../models/marine_models.dart'; // NEW: Added import for Marine models
import '../models/sports_models.dart'; // NEW: Added import for Sports models

class WeatherService {
  // Renamed to lowerCamelCase for linting consistency
  static const String baseUrl = "http://api.weatherapi.com/v1";
  static const String apiKey = "5636def6f6ad4112a4091527251311"; // Replace with your actual API key

  // --- Weather and Forecast ---
  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$cityName&days=7'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> getCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request locations.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final response = await http.get(
      Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=${position.latitude},${position.longitude}&days=1'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['location']['name'];
    } else {
      throw Exception('Failed to get current city from coordinates: ${response.statusCode} ${response.body}');
    }
  }

  // --- Image path resolver for weather conditions ---
  String getWeatherImage(String? condition) {
    if (condition == null || condition.isEmpty) {
      return 'assets/images/default.png';
    }

    final lowerCaseCondition = condition.toLowerCase();

    switch (lowerCaseCondition) {
      case 'clear':
      case 'sunny':
        return 'assets/images/sunny.jpg';
      case 'clouds':
      case 'cloudy':
      case 'partly cloudy':
      case 'overcast':
        return 'assets/images/cloudy.jpg';
      case 'rain':
      case 'drizzle':
      case 'showers':
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
      case 'patchy rain possible':
        return 'assets/images/rainy.jpg';
      case 'snow':
      case 'sleet':
      case 'freezing drizzle':
      case 'blizzard':
        return 'assets/images/snowy.jpg';
      case 'thunderstorm':
      case 'thundery outbreaks possible':
        return 'assets/images/thunder.jpg';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
        return 'assets/images/fog.jpg';
      case 'squall':
      case 'tornado':
        return 'assets/images/thunder.jpg';
      case 'night':
        return 'assets/images/night.jpg';
      default:
        return 'assets/images/default.png';
    }
  }


  // --- Astronomy Data ---
  Future<Map<String, dynamic>> getAstronomy(String cityName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/astronomy.json?key=$apiKey&q=$cityName'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'sunrise': data['astronomy']['astro']['sunrise'],
        'sunset': data['astronomy']['astro']['sunset'],
        'moonrise': data['astronomy']['astro']['moonrise'],
        'moonset': data['astronomy']['astro']['moonset'],
        'moon_phase': data['astronomy']['astro']['moon_phase'],
        'moon_illumination': data['astronomy']['astro']['moon_illumination'],
      };
    } else {
      throw Exception('Failed to load astronomy data: ${response.statusCode} ${response.body}');
    }
  }

  // --- Marine Data (Hypothetical, as WeatherAPI free tier doesn't include it) ---
  // If you use a different API for marine data, you'd adjust this.
  // For now, it returns dummy data that matches MarineForecast structure.
  Future<MarineForecast> getMarineForecast(String location) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay

    // Dummy MarineForecast data
    final dummyMarineJson = {
      'location': {'name': location},
      'forecast': {
        'forecastday': [
          {
            'date': '2025-11-15',
            'day': {
              'maxtemp_c': 15.0,
              'mintemp_c': 10.0, // Assuming min wind is needed, adding a default
              'maxwind_kph': 30.0,
              'condition': {'text': 'Patchy rain possible', 'icon': '//cdn.weatherapi.com/weather/64x64/day/302.png'},
              'avgvis_miles': 10.0, // Used as placeholder for wave height
            },
            'hour': List.generate(24, (index) {
              final time = DateTime.parse('2025-11-15 00:00:00Z').add(Duration(hours: index));
              return {
                'time': time.toIso8601String(),
                'temp_c': 10.0 + (index % 5).toDouble(),
                'wind_kph': 15.0 + (index % 10).toDouble(),
                'vis_miles': 5.0 + (index % 3).toDouble(), // Used as placeholder for wave height
                'condition': {'text': 'Cloudy', 'icon': '//cdn.weatherapi.com/weather/64x64/day/116.png'},
              };
            }),
            'tides': [ // Dummy tide data for the day
              {'type': 'High Tide', 'time': '2025-11-15T05:00:00Z'},
              {'type': 'Low Tide', 'time': '2025-11-15T11:00:00Z'},
              {'type': 'High Tide', 'time': '2025-11-15T17:00:00Z'},
              {'type': 'Low Tide', 'time': '2025-11-15T23:00:00Z'},
            ],
          },
          // You can add more forecast days here
        ]
      }
    };
    return MarineForecast.fromJson(dummyMarineJson);
  }


  // --- Sports Data ---
  Future<List<SportsEvent>> getSports(String location) async{ // Changed return type to List<SportsEvent>
    // Dummy data for sports as WeatherAPI free tier doesn't include it.
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay

    final List<Map<String, dynamic>> dummySportsEvents = [
      {
        'match': 'Real Madrid vs Barcelona',
        'tournament': 'La Liga',
        'stadium': 'Santiago Bernabéu',
        'country': 'Spain',
        'start_time': '2025-12-25T19:00:00Z',
      },
      {
        'match': 'Manchester Utd vs Liverpool',
        'tournament': 'Premier League',
        'stadium': 'Old Trafford',
        'country': 'England',
        'start_time': '2025-12-26T15:00:00Z',
      },
      {
        'match': 'PSG vs Bayern Munich',
        'tournament': 'Champions League',
        'stadium': 'Parc des Princes',
        'country': 'France',
        'start_time': '2025-12-27T20:00:00Z',
      },
      // cricket events...
      {
        'match': 'India vs Australia (Test)',
        'tournament': 'Border-Gavaskar Trophy',
        'stadium': 'MCG',
        'country': 'Australia',
        'start_time': '2025-12-28T00:30:00Z',
      },
      {
        'match': 'England vs South Africa (ODI)',
        'tournament': 'ICC World Cup',
        'stadium': 'Lord\'s',
        'country': 'England',
        'start_time': '2025-12-29T10:00:00Z',
      },
      // golf events...
      {
        'match': 'The Masters',
        'tournament': 'PGA Tour',
        'stadium': 'Augusta National',
        'country': 'USA',
        'start_time': '2026-04-10T12:00:00Z',
      },
    ];

    return dummySportsEvents.map((e) => SportsEvent.fromJson(e)).toList();
  }
}