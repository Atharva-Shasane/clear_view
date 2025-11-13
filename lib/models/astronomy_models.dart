// lib/models/astronomy_models.dart

class MoonPhase {
  final String phaseName;
  final int illumination;

  MoonPhase({
    required this.phaseName,
    required this.illumination,
  });

  factory MoonPhase.fromJson(Map<String, dynamic> json) {
    return MoonPhase(
      phaseName: json['phaseName'], // Assuming your API returns 'phaseName' directly
      illumination: json['illumination'], // Assuming your API returns 'illumination' directly
    );
  }
}