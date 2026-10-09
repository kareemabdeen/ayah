extension DateTimeX on DateTime {
  /// Local midnight of this day.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Last instant of this day.
  DateTime get endOfDay =>
      DateTime(year, month, day).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

  /// Midnight of the next calendar day (DST-safe: built from components).
  DateTime get startOfNextDay => DateTime(year, month, day + 1);

  /// Adds whole calendar days, preserving the time of day across DST changes.
  DateTime addDays(int days) => DateTime(year, month, day + days, hour, minute, second);

  /// Stable `yyyy-MM-dd` key used for per-day records.
  String get dayKey {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// Number of calendar days from [other] to this (ignores time of day).
  int calendarDaysSince(DateTime other) {
    final a = DateTime.utc(year, month, day);
    final b = DateTime.utc(other.year, other.month, other.day);
    return a.difference(b).inDays;
  }
}
