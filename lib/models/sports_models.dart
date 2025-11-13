// lib/models/sports_models.dart

class SportsEvent {
  final String match;
  final String tournament;
  final String stadium;
  final String country;
  final DateTime startTime;

  SportsEvent({
    required this.match,
    required this.tournament,
    required this.stadium,
    required this.country,
    required this.startTime,
  });

  factory SportsEvent.fromJson(Map<String, dynamic> json) {
    return SportsEvent(
      match: json['match'],
      tournament: json['tournament'],
      stadium: json['stadium'],
      country: json['country'],
      startTime: DateTime.parse(json['start_time']),
    );
  }
}