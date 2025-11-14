// lib/pages/astronomy_page.dart
import 'package:clear_view/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Use relative paths
import '../services/weather_service.dart';
import '../models/astronomy_models.dart'; // <--- CHANGE TO THIS

class AstronomyPage extends StatefulWidget {
  const AstronomyPage({Key? key}) : super(key: key);

  @override
  _AstronomyPageState createState() => _AstronomyPageState();
}

class _AstronomyPageState extends State<AstronomyPage>
    with AutomaticKeepAliveClientMixin {
  final WeatherService _weatherService = WeatherService();
  // We remove the future and city from here

  @override
  bool get wantKeepAlive => true; // Required for mixin

  // We don't need initState or _fetchAstronomyData anymore
  // as the FutureBuilder will use the AppState

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for mixin

    // Get the AppState. This widget will now rebuild when AppState changes.
    final appState = Provider.of<AppState>(context);
    final String currentCity = appState.searchedCityQuery;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Astronomy",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _weatherService.getAstronomy(currentCity),
        builder: (context, snapshot) {
          // --- 1. Loading State ---
          if (currentCity == "Fetching location..." ||
              snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // --- 2. Error State ---
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
                        // We can't retry, so just ask user to search
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Please try searching for a city on the Home page."),
                          ),
                        );
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

          // --- 3. Success State ---
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("No astronomy data available."));
          }

          final data = snapshot.data!;
          final MoonPhase moonPhase = MoonPhase(
            phaseName: data['moon_phase'],
            illumination: data['moon_illumination'],
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              // Allow content to scroll
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentCity, // Show the city from AppState
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Moon Phase Card
                  _buildMoonPhaseCard(context, moonPhase),
                  SizedBox(height: 20),

                  // Sun and Moon Times
                  _buildTimesCard(
                    context,
                    sunrise: data['sunrise'],
                    sunset: data['sunset'],
                    moonrise: data['moonrise'],
                    moonset: data['moonset'],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ... (The _buildMoonPhaseCard, _buildTimesCard, and _TimeRow widgets
  //     remain exactly the same) ...
  // (Make sure to paste the rest of the file from your original, I am omitting
  //  the unchanged widget methods here for brevity)

  Widget _buildMoonPhaseCard(BuildContext context, MoonPhase moonPhase) {
    String moonImagePath;
    // All these are now .jpg
    switch (moonPhase.phaseName.toLowerCase()) {
      case 'new moon':
        moonImagePath = 'assets/images/moon_new.jpg';
        break;
      case 'first quarter':
      case 'last quarter':
      case 'waning gibbous':
      case 'waxing gibbous':
      case 'waning crescent':
      case 'waxing crescent':
        moonImagePath = 'assets/images/moon_phase.jpg'; // General phase image
        break;
      case 'full moon':
        moonImagePath = 'assets/images/moon_full.jpg';
        break;
      default:
        moonImagePath = 'assets/images/moon_phase.jpg'; // Fallback
        break;
    }

    return Card(
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Moon Phase",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlueAccent[100],
              ),
            ),
            SizedBox(height: 15),
            // Ensure the image has constrained dimensions for better layout
            SizedBox(
              height: 150, // Fixed height for the moon image
              child: Image.asset(
                moonImagePath,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 15),
            Text(
              moonPhase.phaseName,
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Illumination: ${moonPhase.illumination}%",
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesCard(BuildContext context, {
    required String sunrise,
    required String sunset,
    required String moonrise,
    required String moonset,
  }) {
    return Card(
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Times",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlueAccent[100],
              ),
            ),
            SizedBox(height: 20),
            _TimeRow(icon: Icons.wb_sunny_outlined, label: "Sunrise", time: sunrise),
            SizedBox(height: 15),
            _TimeRow(icon: Icons.nights_stay_outlined, label: "Sunset", time: sunset),
            SizedBox(height: 15),
            _TimeRow(icon: Icons.brightness_2_outlined, label: "Moonrise", time: moonrise),
            SizedBox(height: 15),
            _TimeRow(icon: Icons.brightness_2_outlined, label: "Moonset", time: moonset),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;

  const _TimeRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Colors.white70),
            SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        Text(
          time,
          style: TextStyle(fontSize: 18, color: Colors.lightBlueAccent[100]),
        ),
      ],
    );
  }
}