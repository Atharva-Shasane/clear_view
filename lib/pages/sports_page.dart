// lib/pages/sports_page.dart
import 'package:clear_view/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Use relative paths
import '../services/weather_service.dart';
import '../models/sports_models.dart'; // Correct import for SportsEvent

class SportsPage extends StatefulWidget {
  const SportsPage({Key? key}) : super(key: key);

  @override
  _SportsPageState createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  // We remove the future from here

  late TabController _tabController;

  @override
  bool get wantKeepAlive => true; // Required for mixin

  @override
  void initState() {
    super.initState();
    // We don't fetch the future here anymore
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for mixin

    // Get the AppState.
    final appState = Provider.of<AppState>(context);
    final String currentCity = appState.searchedCityQuery;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text(
                "Upcoming Sports",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              centerTitle: true,
              pinned: true,
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.lightBlueAccent[100],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: "Football"),
                  Tab(text: "Cricket"),
                  Tab(text: "Golf"),
                ],
              ),
            ),
          ];
        },
        body: FutureBuilder<List<SportsEvent>>(
          // Future now depends on the 'currentCity' from AppState
          future: _weatherService.getSports(currentCity),
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

            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return Center(child: Text("No sports data available."));
            }

            final List<SportsEvent> allEvents = snapshot.data!;

            // Filter events by sport type for each tab
            // You might need to adjust this filtering based on how your dummy data 'tournament' strings are structured
            final List<SportsEvent> football = allEvents
                .where((e) =>
            e.tournament.contains('League') ||
                e.tournament.contains('Copa'))
                .toList();
            final List<SportsEvent> cricket = allEvents
                .where((e) =>
            e.tournament.contains('Trophy') ||
                e.tournament.contains('World Cup'))
                .toList();
            final List<SportsEvent> golf = allEvents
                .where((e) =>
            e.tournament.contains('PGA Tour') ||
                e.tournament.contains('Masters'))
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _SportsList(events: football, sportName: "Football"),
                _SportsList(events: cricket, sportName: "Cricket"),
                _SportsList(events: golf, sportName: "Golf"),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ... (The _SportsList, _SportsCard, and _DetailRow widgets
//     remain exactly the same) ...
// (Make sure to paste the rest of the file from your original, I am omitting
//  the unchanged widget classes here for brevity)

/// A reusable widget to display a list of sports events.
class _SportsList extends StatelessWidget {
  final List<SportsEvent> events;
  final String sportName;

  const _SportsList({Key? key, required this.events, required this.sportName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(child: Text("No upcoming $sportName events."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _SportsCard(event: events[index]);
      },
    );
  }
}

/// A card to display a single sports event.
class _SportsCard extends StatelessWidget {
  final SportsEvent event;

  const _SportsCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We use 'intl' to format the date and time
    final String date = DateFormat('MMM d, yyyy').format(event.startTime);
    final String time = DateFormat('h:mm a').format(event.startTime);

    return Card(
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Match Name ---
            Text(
              event.match,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.lightBlueAccent[100],
              ),
            ),
            SizedBox(height: 12),

            // --- Tournament ---
            _DetailRow(
              icon: Icons.emoji_events_outlined,
              label: event.tournament,
            ),
            SizedBox(height: 8),

            // --- Stadium & Country ---
            _DetailRow(
              icon: Icons.stadium_outlined,
              label: "${event.stadium}, ${event.country}",
            ),
            SizedBox(height: 12),

            // --- Date & Time ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: date,
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: time,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small helper widget for a text row with an icon.
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
        // Flexible ensures the text wraps if it's too long
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