import '../../../../core/extensions/date_time_x.dart';
import '../entities/daily_progress.dart';

/// Pure helpers over daily history. Deliberately no "streak that breaks":
/// we count total active days and how long since the last one.
abstract final class ActivityStats {
  static int activeDays(Iterable<DailyProgress> days) => days.where((d) => d.hasActivity).length;

  /// Days since the most recent active day *before today*.
  /// `null` if there is no earlier activity.
  static int? daysSinceLastActivity(Iterable<DailyProgress> days, DateTime now) {
    final todayKey = now.dayKey;
    DateTime? last;
    for (final d in days) {
      if (!d.hasActivity || d.dayKey == todayKey) continue;
      final date = DateTime.parse(d.dayKey);
      if (last == null || date.isAfter(last)) last = date;
    }
    return last == null ? null : now.calendarDaysSince(last);
  }

  static bool isReturningAfterBreak(Iterable<DailyProgress> days, DateTime now, {required int afterDays}) {
    final gap = daysSinceLastActivity(days, now);
    return gap != null && gap >= afterDays;
  }
}
