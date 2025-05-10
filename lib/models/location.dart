class DisneyLocation {
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final String type; // 'attraction', 'restaurant', 'shop', 'hotel', 'station'

  DisneyLocation({
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
    };
  }

  factory DisneyLocation.fromMap(Map<String, dynamic> map) {
    return DisneyLocation(
      name: map['name'],
      area: map['area'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      type: map['type'],
    );
  }
}
