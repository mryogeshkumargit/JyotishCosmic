import 'database.dart';
import 'ephemeris.dart';

extension ProfileBirth on Profile {
  /// Birth date/time as entered (local wall clock at the birth place).
  /// Stored as a UTC-encoded wall clock, see [Profiles.dob].
  DateTime get birthWallClock => dob.toUtc();

  ChartData computeChart() {
    final b = birthWallClock;
    return Ephemeris.computeChart(
      b.year, b.month, b.day, b.hour.toDouble(), b.minute.toDouble(), lat, lon, timezone,
    );
  }
}

/// Encodes a wall-clock birth time for storage (see [Profiles.dob]).
DateTime encodeWallClock(int year, int month, int day, int hour, int minute) =>
    DateTime.utc(year, month, day, hour, minute);
