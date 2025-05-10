import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/location.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  static MapService get instance => _instance;

  List<DisneyLocation> _locations = [];

  MapService._internal();

  Future<void> loadLocations() async {
    try {
      // Load locations from asset file
      final String locationsJson =
          await rootBundle.loadString('assets/maps/disney_locations.json');
      final List<dynamic> locationsMap = json.decode(locationsJson);

      _locations =
          locationsMap.map((json) => DisneyLocation.fromMap(json)).toList();
    } catch (e) {
      print('Error loading locations: $e');
      // Fallback to some default locations if the file can't be loaded
      _locations = _getDefaultLocations();
    }
  }

  List<DisneyLocation> get locations => _locations;

  DisneyLocation? getNearestLocation(double latitude, double longitude) {
    if (_locations.isEmpty) return null;

    DisneyLocation nearest = _locations.first;
    double minDistance = _calculateDistance(
        latitude, longitude, nearest.latitude, nearest.longitude);

    for (var location in _locations) {
      final distance = _calculateDistance(
          latitude, longitude, location.latitude, location.longitude);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }

    return nearest;
  }

  // Simple Euclidean distance calculation (sufficient for nearby points)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return ((lat1 - lat2) * (lat1 - lat2) + (lon1 - lon2) * (lon1 - lon2));
  }

  List<DisneyLocation> getLocationsByArea(String area) {
    return _locations.where((location) => location.area == area).toList();
  }

  List<DisneyLocation> getLocationsByType(String type) {
    return _locations.where((location) => location.type == type).toList();
  }

  List<String> getAreas() {
    final Set<String> areas = {};
    for (var location in _locations) {
      areas.add(location.area);
    }
    return areas.toList()..sort();
  }

  // Fallback locations in case we can't load from the asset file
  List<DisneyLocation> _getDefaultLocations() {
    return [
      // Disney Land
      DisneyLocation(
          name: 'Cinderella Castle',
          area: 'Fantasyland',
          latitude: 35.6329,
          longitude: 139.8804,
          type: 'attraction'),
      DisneyLocation(
          name: 'Space Mountain',
          area: 'Tomorrowland',
          latitude: 35.6335,
          longitude: 139.8800,
          type: 'attraction'),
      DisneyLocation(
          name: 'Big Thunder Mountain',
          area: 'Westernland',
          latitude: 35.6322,
          longitude: 139.8789,
          type: 'attraction'),

      // Disney Sea
      DisneyLocation(
          name: 'Mediterranean Harbor',
          area: 'Mediterranean Harbor',
          latitude: 35.6267,
          longitude: 139.8853,
          type: 'area'),
      DisneyLocation(
          name: 'Tower of Terror',
          area: 'American Waterfront',
          latitude: 35.6256,
          longitude: 139.8872,
          type: 'attraction'),

      // Monorail Stations
      DisneyLocation(
          name: 'Resort Gateway Station',
          area: 'Resort Line',
          latitude: 35.6348,
          longitude: 139.8848,
          type: 'station'),
      DisneyLocation(
          name: 'Tokyo Disneyland Station',
          area: 'Resort Line',
          latitude: 35.6351,
          longitude: 139.8805,
          type: 'station'),

      // Hotels
      DisneyLocation(
          name: 'Disney Ambassador Hotel',
          area: 'Hotels',
          latitude: 35.6309,
          longitude: 139.8830,
          type: 'hotel'),
      DisneyLocation(
          name: 'Tokyo DisneySea Hotel MiraCosta',
          area: 'Hotels',
          latitude: 35.6270,
          longitude: 139.8860,
          type: 'hotel'),
    ];
  }
}
