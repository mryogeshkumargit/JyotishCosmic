import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final query = 'agra';
  final url = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=\$query&count=5&language=en&format=json');
  
  try {
    print('Fetching from \$url...');
    final response = await http.get(url).timeout(const Duration(seconds: 5));
    
    print('Status Code: \${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null) {
        final List<dynamic> results = data['results'];
        for (var json in results) {
          final name = json['name'] as String;
          final admin1 = json['admin1'] as String?;
          final country = json['country'] as String?;
          
          final List<String> parts = [name];
          if (admin1 != null && admin1.isNotEmpty) parts.add(admin1);
          if (country != null && country.isNotEmpty) parts.add(country);
          print(parts.join(', '));
        }
      } else {
        print('No results found.');
      }
    } else {
      print('Response: \${response.body}');
    }
  } catch (e) {
    print('Error: \$e');
  }
}
