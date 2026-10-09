/// Source of "now". Injected everywhere time matters so that scheduling,
/// streaks and missed-day logic are deterministic in tests.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Test clock that can be moved forward.
final class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void setNow(DateTime value) => _now = value;

  void advance(Duration duration) => _now = _now.add(duration);
}
