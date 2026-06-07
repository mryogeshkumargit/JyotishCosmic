import 'lib/core/ephemeris.dart';

void main() {
  double lat = 28.6139;
  double lon = 77.2090;
  double utcOffset = 5.5;
  ChartData chartData = Ephemeris.computeChart(
    1983, 10, 25, 4, 20, lat, lon, utcOffset
  );
  
  print("Ascendant Sidereal: ${chartData.ascendantSidereal}");
  print("Lagna Sign: ${(chartData.ascendantSidereal / 30).floor() + 1}");
  print("Planet Longitudes:");
  chartData.planetLongitudes.forEach((k, v) => print("$k: $v (Sign ${(v/30).floor() + 1})"));
  
  print("House Planets:");
  chartData.housePlanets.forEach((k, v) => print("House $k: $v"));
}
