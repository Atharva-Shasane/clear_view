// lib/main.dart
import 'package:clear_view/pages/astronomy_page.dart';
import 'package:clear_view/pages/forecast_page.dart';
import 'package:clear_view/pages/home_page.dart';
import 'package:clear_view/pages/marine_page.dart';
import 'package:clear_view/pages/sports_page.dart';
import 'package:clear_view/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your state and all your pages



void main() {
  runApp(
    /*
      We wrap the entire app in a 'ChangeNotifierProvider'.
      This makes our 'AppState' available to any widget in the app
      that needs to access it.
    */
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: ClearViewApp(),
    ),
  );
}

class ClearViewApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clear View',
      theme: ThemeData(
        // A dark theme looks great for weather apps.
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF0F172A), // A dark blue-grey
        // Define a text theme for consistent font styles
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      debugShowCheckedModeBanner: false, // Hides the "debug" banner
      home: AppNavigator(),
    );
  }
}

// This widget builds the Bottom Navigation Bar
class AppNavigator extends StatefulWidget {
  @override
  _AppNavigatorState createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _selectedIndex = 0;

  // This list holds all your pages. The BottomNavBar just switches the index.
  static final List<Widget> _pages = <Widget>[
    HomePage(),
    ForecastPage(),
    AstronomyPage(),
    SportsPage(),
    MarinePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
        This 'IndexedStack' is a performance optimization.
        It keeps all pages in the widget tree and just shows one at a time.
        This preserves the state of each page, so when you scroll down
        on the 'Sports' page and switch tabs, it will still be scrolled
        down when you come back.
      */
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // Icon changes when selected
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Forecast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nightlight_outlined),
            activeIcon: Icon(Icons.nightlight_round),
            label: 'Astronomy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: 'Sports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.waves_outlined),
            activeIcon: Icon(Icons.waves),
            label: 'Marine',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlueAccent[100], // Color for selected
        unselectedItemColor: Colors.grey[600], // Color for unselected
        backgroundColor: Color(0xFF1E293B), // A darker blue-grey for the bar
        type: BottomNavigationBarType.fixed, // Ensures all 5 tabs are visible
        onTap: _onItemTapped,
      ),
    );
  }
}