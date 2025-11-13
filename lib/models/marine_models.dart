// lib/models/marine_models.dart

// This model assumes the structure from a Marine Weather API response.
// If your actual API is different, you'll need to adjust the fromJson methods.
class MarineForecast {
  final String locationName;
  final List<MarineDayForecast> forecastDays;

  MarineForecast({
    required this.locationName,
    required this.forecastDays,
  });

  factory MarineForecast.fromJson(Map<String, dynamic> json) {
    // This is a placeholder; you'll need to map your actual API response structure
    // from the marine endpoint to fill these fields.
    // Example: WeatherAPI's marine data is often nested similarly to its regular forecast.
    List<MarineDayForecast> days = [];
    if (json['forecast'] != null && json['forecast']['forecastday'] != null) {
      days = (json['forecast']['forecastday'] as List)
          .map((dayJson) => MarineDayForecast.fromJson(dayJson))
          .toList();
    }

    return MarineForecast(
      locationName: json['location']['name'] ?? 'Marine Area', // Adjust based on API
      forecastDays: days,
    );
  }
}


class MarineDayForecast {
  final DateTime date;
  final double maxWindKph;
  final double minWindKph;
  final int maxWaveHeightFt; // Assuming feet for marine
  final String conditionText;
  final String conditionIcon;
  final List<MarineHourForecast> hour;
  final List<Tide> tides; // List of tides for the day

  MarineDayForecast({
    required this.date,
    required this.maxWindKph,
    required this.minWindKph,
    required this.maxWaveHeightFt,
    required this.conditionText,
    required this.conditionIcon,
    required this.hour,
    required this.tides,
  });

  factory MarineDayForecast.fromJson(Map<String, dynamic> json) {
    List<MarineHourForecast> hourlyForecast = [];
    if (json['hour'] != null) {
      hourlyForecast = (json['hour'] as List)
          .map((hourJson) => MarineHourForecast.fromJson(hourJson))
          .toList();
    }

    List<Tide> dailyTides = [];
    // Assuming 'tides' is a separate array in the JSON or needs to be parsed from somewhere
    // For WeatherAPI's marine data, tide data might be within the 'hour' objects or a separate endpoint.
    // This is a placeholder:
    if (json['tides'] != null) { // Hypothetical 'tides' key in daily forecast
      dailyTides = (json['tides'] as List)
          .map((tideJson) => Tide.fromJson(tideJson))
          .toList();
    } else {
      // Dummy tides if no real data is available or a simplified structure
      dailyTides = [
        Tide(type: 'High Tide', time: DateTime.parse("${json['date']} 05:00:00Z")),
        Tide(type: 'Low Tide', time: DateTime.parse("${json['date']} 11:00:00Z")),
        Tide(type: 'High Tide', time: DateTime.parse("${json['date']} 17:00:00Z")),
        Tide(type: 'Low Tide', time: DateTime.parse("${json['date']} 23:00:00Z")),
      ];
    }


    return MarineDayForecast(
      date: DateTime.parse(json['date']),
      maxWindKph: json['day']['maxwind_kph'].toDouble(),
      minWindKph: (json['day']['minwind_kph'] ?? 0.0).toDouble(), // Added default for min wind
      maxWaveHeightFt: (json['day']['avgvis_miles'] * 1.5).toInt(), // Placeholder, replace with actual wave height if API provides
      conditionText: json['day']['condition']['text'],
      conditionIcon: json['day']['condition']['icon'],
      hour: hourlyForecast,
      tides: dailyTides,
    );
  }
}

class MarineHourForecast {
  final DateTime time;
  final double tempC;
  final double windKph;
  final int waveHeightFt;
  final String conditionText;
  final String conditionIcon;

  MarineHourForecast({
    required this.time,
    required this.tempC,
    required this.windKph,
    required this.waveHeightFt,
    required this.conditionText,
    required this.conditionIcon,
  });

  factory MarineHourForecast.fromJson(Map<String, dynamic> json) {
    return MarineHourForecast(
      time: DateTime.parse(json['time']),
      tempC: json['temp_c'].toDouble(),
      windKph: json['wind_kph'].toDouble(),
      waveHeightFt: (json['vis_miles'] * 1.5).toInt(), // Placeholder, replace with actual wave height if API provides
      conditionText: json['condition']['text'],
      conditionIcon: json['condition']['icon'],
    );
  }
}

class Tide {
  final String type; // e.g., "High Tide", "Low Tide"
  final DateTime time;

  Tide({
    required this.type,
    required this.time,
  });

  factory Tide.fromJson(Map<String, dynamic> json) {
    return Tide(
      type: json['type'],
      time: DateTime.parse(json['time']),
    );
  }
}