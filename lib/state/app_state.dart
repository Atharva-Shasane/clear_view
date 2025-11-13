// lib/state/app_state.dart
import 'package:flutter/material.dart';

/*
  This class holds the application's shared state.
  We use 'ChangeNotifier' so that other widgets can listen for
  when this data changes and automatically update themselves.
*/
class AppState extends ChangeNotifier {
  // We set default values so the app doesn't crash on the first run
  // 'auto:ip' is a special query for WeatherAPI that finds the user's location by IP.
  String _currentLocationQuery = "auto:ip";
  String _searchedCityQuery = "New York"; // A default city to show

  // These are the 'getters' that other parts of the app will use to read the data.
  String get currentLocationQuery => _currentLocationQuery;
  String get searchedCityQuery => _searchedCityQuery;

  /*
    This function is called when the app finds the user's physical GPS location.
    It updates the query and notifies all listening widgets to rebuild.
  */
  void setCurrentLocation(String latLon) {
    _currentLocationQuery = latLon;
    notifyListeners(); // This is the most important part!
  }

  /*
    This function is called when the user types a new city into the search bar.
    It updates the query and notifies all listening widgets to rebuild.
  */
  void setSearchedCity(String city) {
    _searchedCityQuery = city;
    notifyListeners();
  }
}