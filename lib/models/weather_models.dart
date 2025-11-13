// lib/models/weather_models.dart

class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final List<ForecastDay> forecast; // For 7-day forecast

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.forecast,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    List<ForecastDay> dailyForecast = [];
    if (json['forecast'] != null && json['forecast']['forecastday'] != null) {
      dailyForecast = (json['forecast']['forecastday'] as List)
          .map((dayJson) => ForecastDay.fromJson(dayJson))
          .toList();
    }

    return Weather(
      cityName: json['location']['name'],
      temperature: json['current']['temp_c'].toDouble(),
      mainCondition: json['current']['condition']['text'],
      forecast: dailyForecast,
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final String conditionText;
  final String conditionIcon; // New: to store the icon URL/path
  final List<HourForecast> hour; // Hourly forecast for the day

  ForecastDay({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.conditionText,
    required this.conditionIcon,
    required this.hour,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    List<HourForecast> hourlyForecast = [];
    if (json['hour'] != null) {
      hourlyForecast = (json['hour'] as List)
          .map((hourJson) => HourForecast.fromJson(hourJson))
          .toList();
    }

    return ForecastDay(
      date: DateTime.parse(json['date']),
      maxTempC: json['day']['maxtemp_c'].toDouble(),
      minTempC: json['day']['mintemp_c'].toDouble(),
      conditionText: json['day']['condition']['text'],
      conditionIcon: json['day']['condition']['icon'], // Get icon URL
      hour: hourlyForecast,
    );
  }
}

class HourForecast {
  final DateTime time;
  final double tempC;
  final String conditionText;
  final String conditionIcon;

  HourForecast({
    required this.time,
    required this.tempC,
    required this.conditionText,
    required this.conditionIcon,
  });

  factory HourForecast.fromJson(Map<String, dynamic> json) {
    return HourForecast(
      time: DateTime.parse(json['time']),
      tempC: json['temp_c'].toDouble(),
      conditionText: json['condition']['text'],
      conditionIcon: json['condition']['icon'],
    );
  }
}