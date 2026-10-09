/// Product-level tunables. Anything a PM might want to tweak lives here,
/// not scattered as magic numbers in widgets.
abstract final class AppConstants {
  /// How many times the user repeats with the reciter before recall.
  static const int targetRepetitions = 3;

  /// Hard cap on reviews per day so returning users are never flooded.
  static const int maxDailyReviews = 10;

  /// Rough time cost used for "Estimated time" copy.
  static const Duration timePerNewVerse = Duration(minutes: 3);
  static const Duration timePerReview = Duration(minutes: 1);

  /// Gap (in days) after which Home/Review greet with "Welcome back".
  static const int welcomeBackAfterDays = 2;

  /// Slow playback speed for the "slow" toggle.
  static const double slowPlaybackSpeed = 0.75;
  static const double normalPlaybackSpeed = 1.0;

  static const List<int> dailyGoalOptions = [1, 2, 5];
  static const int defaultDailyGoal = 1;
}

/// External content endpoints. Kept in one place so we can swap providers.
abstract final class QuranSourceConstants {
  /// Tanzil-sourced Uthmani text served by AlQuran Cloud.
  static const String textApiBase = 'https://api.alquran.cloud/v1';
  static const String textEdition = 'quran-uthmani';

  /// Per-ayah audio by global ayah number (1..6236).
  static const String audioBase = 'https://cdn.islamic.network/quran/audio';
  static const int audioBitrate = 128;
  static const String defaultReciter = 'ar.alafasy';

  static String audioUrl(int globalAyahNumber, {String reciter = defaultReciter}) =>
      '$audioBase/$audioBitrate/$reciter/$globalAyahNumber.mp3';

  static const Duration requestTimeout = Duration(seconds: 15);
}
