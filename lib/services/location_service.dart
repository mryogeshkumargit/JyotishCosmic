import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationResult {
  final String displayName;
  final double lat;
  final double lon;

  LocationResult({required this.displayName, required this.lat, required this.lon});
}

class LocationService {
  /// Queries Open-Meteo Geocoding API for city suggestions.
  Future<List<LocationResult>> searchCity(String query) async {
    if (query.trim().length < 3) return [];
    
    final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=\${Uri.encodeComponent(query.trim())}&count=5&language=en&format=json');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final List<dynamic> results = data['results'];
          return results.map((json) {
            final name = json['name'] as String;
            final admin1 = json['admin1'] as String?;
            final country = json['country'] as String?;
            
            final List<String> parts = [name];
            if (admin1 != null && admin1.isNotEmpty) parts.add(admin1);
            if (country != null && country.isNotEmpty) parts.add(country);
            
            return LocationResult(
              displayName: parts.join(', '),
              lat: double.parse(json['latitude'].toString()),
              lon: double.parse(json['longitude'].toString()),
            );
          }).toList();
        } else {
            return [];
        }
      } else {
        return [LocationResult(displayName: "API Error: \${response.statusCode}", lat: 0, lon: 0)];
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        return [LocationResult(displayName: "Network error. Please check your internet connection.", lat: 0, lon: 0)];
      }
      return [LocationResult(displayName: "Error: \$e", lat: 0, lon: 0)];
    }
  }
}
