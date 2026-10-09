import 'package:flutter/widgets.dart';

/// All user-facing copy. Hand-written (no codegen) and Arabic-first.
/// Tone rules: short, warm, never judgmental. No "wrong", no "failed".
abstract class AppStrings {
  const AppStrings();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? const ArStrings();

  static const supportedLocales = [Locale('ar'), Locale('en')];

  static AppStrings forLocale(Locale locale) => locale.languageCode == 'en' ? const EnStrings() : const ArStrings();

  // General
  String get appName;
  String get next;
  String get back;
  String get finish;
  String get retry;
  String get close;
  String get continueLabel;
  String get languageToggle;

  // Plurals / counts
  String ayahs(int n);
  String minutes(int n);
  String days(int n);
  String ayahNumber(int n);
  String surahName(String name);

  // Onboarding
  String get onbWelcomeTitle;
  String get onbWelcomeBody;
  String get onbStart;
  String get onbGoalTitle;
  String goalOption(int n);
  String get onbChangeLater;
  String get onbTimeTitle;
  String get onbTimeHint;
  String get timeAfterFajr;
  String get timeMorning;
  String get timeAfternoon;
  String get timeAfterMaghrib;
  String get timeBeforeSleep;
  String get onbStartTitle;
  String get startFatihah;
  String get startJuzAmma;
  String get startChooseSurah;
  String get startLetAyahChoose;
  String get startLetAyahChooseHint;
  String get chooseSurahTitle;
  String get onbBegin;

  // Home
  String get greeting;
  String get welcomeBackTitle;
  String get welcomeBackBody;
  String get todaysAyah;
  String get listen;
  String get pause;
  String get startMemorizing;
  String minutesToday(int n);
  String get goalReachedTitle;
  String get goalReachedBody;
  String get oneMoreAyah;
  String reviewWaiting(int n);
  String get startReview;
  String statMemorized(int n);
  String statToReview(int n);
  String statDays(int n);
  String get quranCompleteTitle;
  String get quranCompleteBody;
  String get offlineFirstTime;
  String get genericProblem;
  String get progressTooltip;
  String get settingsTooltip;

  // Memorization
  String get stepListen;
  String get stepRepeat;
  String get stepRecall;
  String get listenCarefully;
  String get repeatWithReciter;
  String get goRepeat;
  String repetitionProgress(int done, int total);
  String get iRepeatedIt;
  String get tryFromMemory;
  String get recallInstruction;
  String get ayahHidden;
  String get showFirstWord;
  String get iRemembered;
  String get needAnotherTry;
  String get iForgot;
  String get forgotTitle;
  String get forgotBody;
  String get listenAgain;
  String get replay;
  String get slow;
  String get normalSpeed;
  String get mashaAllah;
  String get memorizedToday;
  String get reviewTomorrow;
  String memorizedTodayCount(int n);
  String verseCounter(int current, int total);

  // Review
  String get reviewTitle;
  String reviewCount(int n);
  String estimatedTime(int minutes);
  String get welcomeBackReview;
  String get deferredNote;
  String get noReviewTitle;
  String get noReviewBody;
  String get backHome;
  String get reviewRecallInstruction;
  String get revealAyah;
  String get howDidItFeel;
  String get rateEasy;
  String get rateGood;
  String get rateHard;
  String get rateForgot;
  String get forgotInReview;
  String get reviewDoneBody;

  // Progress
  String get progressTitle;
  String ayahsOfTotal(int done, int total);
  String legendMemorized(int n);
  String legendNeedsReview(int n);
  String legendNotStarted(int n);
  String get stateMemorized;
  String get stateNeedsReview;
  String get stateNotStarted;
  String surahCompleted(String name);
  String get fullSurahTest;
  String get surahTestTitle;
  String get nothingYet;

  // Settings
  String get settingsTitle;
  String get dailyGoal;
  String get reminder;
  String get reminderTime;
  String get language;
  String get arabic;
  String get english;
}

final class ArStrings extends AppStrings {
  const ArStrings();

  @override
  String get appName => 'آية';
  @override
  String get next => 'التالي';
  @override
  String get back => 'رجوع';
  @override
  String get finish => 'إنهاء';
  @override
  String get retry => 'حاول مرة أخرى';
  @override
  String get close => 'إغلاق';
  @override
  String get continueLabel => 'متابعة';
  @override
  String get languageToggle => 'English';

  @override
  String ayahs(int n) => switch (n) {
        1 => 'آية واحدة',
        2 => 'آيتان',
        >= 3 && <= 10 => '$n آيات',
        _ => '$n آية',
      };
  @override
  String minutes(int n) => switch (n) {
        1 => 'دقيقة',
        2 => 'دقيقتان',
        >= 3 && <= 10 => '$n دقائق',
        _ => '$n دقيقة',
      };
  @override
  String days(int n) => switch (n) {
        1 => 'يوم واحد',
        2 => 'يومان',
        >= 3 && <= 10 => '$n أيام',
        _ => '$n يومًا',
      };
  @override
  String ayahNumber(int n) => 'الآية $n';
  @override
  String surahName(String name) => 'سورة $name';

  @override
  String get onbWelcomeTitle => 'تحب تبدأ حفظ القرآن؟';
  @override
  String get onbWelcomeBody => 'آية واحدة كل يوم.\nثلاث دقائق فقط.\nوسنكمل معًا.';
  @override
  String get onbStart => 'يلا نبدأ';
  @override
  String get onbGoalTitle => 'كم تحب أن تحفظ كل يوم؟';
  @override
  String goalOption(int n) => '${ayahs(n)} / يوم';
  @override
  String get onbChangeLater => 'القليل الدائم أفضل. يمكنك التغيير لاحقًا.';
  @override
  String get onbTimeTitle => 'متى تفضّل أن تحفظ؟';
  @override
  String get onbTimeHint => 'سنذكّرك بلطف في هذا الوقت.';
  @override
  String get timeAfterFajr => 'بعد الفجر';
  @override
  String get timeMorning => 'الصباح';
  @override
  String get timeAfternoon => 'بعد الظهر';
  @override
  String get timeAfterMaghrib => 'بعد المغرب';
  @override
  String get timeBeforeSleep => 'قبل النوم';
  @override
  String get onbStartTitle => 'من أين تحب أن تبدأ؟';
  @override
  String get startFatihah => 'الفاتحة';
  @override
  String get startJuzAmma => 'جزء عمّ';
  @override
  String get startChooseSurah => 'اختر سورة';
  @override
  String get startLetAyahChoose => 'دع «آية» تختار';
  @override
  String get startLetAyahChooseHint => 'نبدأ بالفاتحة ثم قصار السور';
  @override
  String get chooseSurahTitle => 'اختر سورة';
  @override
  String get onbBegin => 'ابدأ';

  @override
  String get greeting => 'السلام عليكم';
  @override
  String get welcomeBackTitle => 'أهلًا بعودتك';
  @override
  String get welcomeBackBody => 'لنكمل من حيث توقفت.';
  @override
  String get todaysAyah => 'آية اليوم';
  @override
  String get listen => 'استمع';
  @override
  String get pause => 'إيقاف مؤقت';
  @override
  String get startMemorizing => 'ابدأ الحفظ';
  @override
  String minutesToday(int n) => '${minutes(n)} اليوم';
  @override
  String get goalReachedTitle => 'ما شاء الله';
  @override
  String get goalReachedBody => 'أتممت حفظ اليوم. غدًا نراجع معًا.';
  @override
  String get oneMoreAyah => 'آية إضافية؟';
  @override
  String reviewWaiting(int n) => '${ayahs(n)} للمراجعة';
  @override
  String get startReview => 'ابدأ المراجعة';
  @override
  String statMemorized(int n) => '$n محفوظة';
  @override
  String statToReview(int n) => '$n للمراجعة';
  @override
  String statDays(int n) => '${days(n)} حفظ';
  @override
  String get quranCompleteTitle => 'ما شاء الله تبارك الله';
  @override
  String get quranCompleteBody => 'أتممت المسار كاملًا. استمر في المراجعة.';
  @override
  String get offlineFirstTime => 'نحتاج اتصالًا بالإنترنت مرة واحدة لتنزيل الآيات، ثم تعمل بدونه.';
  @override
  String get genericProblem => 'حدث شيء غير متوقع. لنحاول مرة أخرى.';
  @override
  String get progressTooltip => 'تقدّمي';
  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get stepListen => 'استمع';
  @override
  String get stepRepeat => 'كرّر';
  @override
  String get stepRecall => 'سمِّع';
  @override
  String get listenCarefully => 'استمع بتركيز.';
  @override
  String get repeatWithReciter => 'كرّر مع القارئ.';
  @override
  String get goRepeat => 'كرّر مع القارئ';
  @override
  String repetitionProgress(int done, int total) => '$done من $total';
  @override
  String get iRepeatedIt => 'كرّرتها';
  @override
  String get tryFromMemory => 'جرّب من حفظك';
  @override
  String get recallInstruction => 'حاول أن تقرأ الآية من حفظك.';
  @override
  String get ayahHidden => 'الآية مخفية';
  @override
  String get showFirstWord => 'أظهر أول كلمة';
  @override
  String get iRemembered => 'تذكّرتها';
  @override
  String get needAnotherTry => 'أحتاج محاولة أخرى';
  @override
  String get iForgot => 'نسيتها';
  @override
  String get forgotTitle => 'لا بأس.';
  @override
  String get forgotBody => 'لنستمع إليها مرة أخرى.';
  @override
  String get listenAgain => 'نستمع مرة أخرى';
  @override
  String get replay => 'إعادة';
  @override
  String get slow => 'أبطأ';
  @override
  String get normalSpeed => 'عادي';
  @override
  String get mashaAllah => 'ما شاء الله';
  @override
  String get memorizedToday => 'حفظت آية اليوم.';
  @override
  String get reviewTomorrow => 'غدًا سنراجعها معًا.';
  @override
  String memorizedTodayCount(int n) => '${ayahs(n)} محفوظة اليوم';
  @override
  String verseCounter(int current, int total) => '$current من $total';

  @override
  String get reviewTitle => 'مراجعة اليوم';
  @override
  String reviewCount(int n) => 'لديك ${ayahs(n)} للمراجعة.';
  @override
  String estimatedTime(int m) => 'الوقت المتوقع: ${minutes(m)}.';
  @override
  String get welcomeBackReview => 'أهلًا بعودتك. سنراجع بهدوء، خطوة بخطوة.';
  @override
  String get deferredNote => 'والباقي سنراجعه في الأيام القادمة.';
  @override
  String get noReviewTitle => 'لا مراجعة اليوم';
  @override
  String get noReviewBody => 'كل آياتك في موعدها.';
  @override
  String get backHome => 'العودة للرئيسية';
  @override
  String get reviewRecallInstruction => 'اقرأها من حفظك، ثم أظهرها.';
  @override
  String get revealAyah => 'أظهر الآية';
  @override
  String get howDidItFeel => 'كيف كانت؟';
  @override
  String get rateEasy => 'سهلة';
  @override
  String get rateGood => 'جيدة';
  @override
  String get rateHard => 'صعبة';
  @override
  String get rateForgot => 'نسيتها';
  @override
  String get forgotInReview => 'لا بأس، سنعيدها بعد قليل.';
  @override
  String get reviewDoneBody => 'أتممت مراجعة اليوم.';

  @override
  String get progressTitle => 'تقدّمي';
  @override
  String ayahsOfTotal(int done, int total) => '$done / $total آية';
  @override
  String legendMemorized(int n) => 'محفوظة: $n';
  @override
  String legendNeedsReview(int n) => 'تحتاج مراجعة: $n';
  @override
  String legendNotStarted(int n) => 'لم تبدأ: $n';
  @override
  String get stateMemorized => 'محفوظة';
  @override
  String get stateNeedsReview => 'تحتاج مراجعة';
  @override
  String get stateNotStarted => 'لم تبدأ';
  @override
  String surahCompleted(String name) => 'أتممت حفظ سورة $name.';
  @override
  String get fullSurahTest => 'اختبار السورة كاملة';
  @override
  String get surahTestTitle => 'اختبار السورة';
  @override
  String get nothingYet => 'ابدأ بآية واحدة، وستظهر هنا.';

  @override
  String get settingsTitle => 'الإعدادات';
  @override
  String get dailyGoal => 'الهدف اليومي';
  @override
  String get reminder => 'التذكير اليومي';
  @override
  String get reminderTime => 'وقت التذكير';
  @override
  String get language => 'اللغة';
  @override
  String get arabic => 'العربية';
  @override
  String get english => 'English';
}

final class EnStrings extends AppStrings {
  const EnStrings();

  @override
  String get appName => 'Ayah';
  @override
  String get next => 'Next';
  @override
  String get back => 'Back';
  @override
  String get finish => 'Finish';
  @override
  String get retry => 'Try again';
  @override
  String get close => 'Close';
  @override
  String get continueLabel => 'Continue';
  @override
  String get languageToggle => 'العربية';

  @override
  String ayahs(int n) => n == 1 ? '1 Ayah' : '$n Ayahs';
  @override
  String minutes(int n) => n == 1 ? '1 minute' : '$n minutes';
  @override
  String days(int n) => n == 1 ? '1 day' : '$n days';
  @override
  String ayahNumber(int n) => 'Ayah $n';
  @override
  String surahName(String name) => 'Surah $name';

  @override
  String get onbWelcomeTitle => 'Want to start memorizing the Quran?';
  @override
  String get onbWelcomeBody => 'One Ayah a day.\nJust three minutes.\nWe’ll do it together.';
  @override
  String get onbStart => "Let's start";
  @override
  String get onbGoalTitle => 'How much would you like to memorize?';
  @override
  String goalOption(int n) => '${ayahs(n)} / day';
  @override
  String get onbChangeLater => 'Small and steady wins. You can change this later.';
  @override
  String get onbTimeTitle => 'When do you prefer to memorize?';
  @override
  String get onbTimeHint => "We'll gently remind you then.";
  @override
  String get timeAfterFajr => 'After Fajr';
  @override
  String get timeMorning => 'Morning';
  @override
  String get timeAfternoon => 'Afternoon';
  @override
  String get timeAfterMaghrib => 'After Maghrib';
  @override
  String get timeBeforeSleep => 'Before sleep';
  @override
  String get onbStartTitle => 'Where would you like to start?';
  @override
  String get startFatihah => 'Al-Fatihah';
  @override
  String get startJuzAmma => 'Juz Amma';
  @override
  String get startChooseSurah => 'Choose a Surah';
  @override
  String get startLetAyahChoose => 'Let Ayah choose';
  @override
  String get startLetAyahChooseHint => 'Al-Fatihah, then the short surahs';
  @override
  String get chooseSurahTitle => 'Choose a Surah';
  @override
  String get onbBegin => 'Begin';

  @override
  String get greeting => 'As-salamu alaykum';
  @override
  String get welcomeBackTitle => 'Welcome back';
  @override
  String get welcomeBackBody => "Let's continue where you stopped.";
  @override
  String get todaysAyah => "Today's Ayah";
  @override
  String get listen => 'Listen';
  @override
  String get pause => 'Pause';
  @override
  String get startMemorizing => 'Start memorizing';
  @override
  String minutesToday(int n) => '${minutes(n)} today';
  @override
  String get goalReachedTitle => 'Masha’Allah';
  @override
  String get goalReachedBody => "You're done for today. We'll review tomorrow.";
  @override
  String get oneMoreAyah => 'One more Ayah?';
  @override
  String reviewWaiting(int n) => '${ayahs(n)} to review';
  @override
  String get startReview => 'Start review';
  @override
  String statMemorized(int n) => '$n memorized';
  @override
  String statToReview(int n) => '$n to review';
  @override
  String statDays(int n) => '${days(n)} of memorizing';
  @override
  String get quranCompleteTitle => 'Masha’Allah, Tabarak Allah';
  @override
  String get quranCompleteBody => 'You completed the whole path. Keep reviewing.';
  @override
  String get offlineFirstTime => 'We need internet once to download the Ayahs. After that, it works offline.';
  @override
  String get genericProblem => "Something unexpected happened. Let's try again.";
  @override
  String get progressTooltip => 'My progress';
  @override
  String get settingsTooltip => 'Settings';

  @override
  String get stepListen => 'Listen';
  @override
  String get stepRepeat => 'Repeat';
  @override
  String get stepRecall => 'Recall';
  @override
  String get listenCarefully => 'Listen carefully.';
  @override
  String get repeatWithReciter => 'Repeat with the reciter.';
  @override
  String get goRepeat => 'Repeat with the reciter';
  @override
  String repetitionProgress(int done, int total) => '$done of $total';
  @override
  String get iRepeatedIt => 'I repeated it';
  @override
  String get tryFromMemory => 'Try from memory';
  @override
  String get recallInstruction => 'Try to say the Ayah from memory.';
  @override
  String get ayahHidden => 'Ayah hidden';
  @override
  String get showFirstWord => 'Show first word';
  @override
  String get iRemembered => 'I remembered it';
  @override
  String get needAnotherTry => 'I need another try';
  @override
  String get iForgot => 'I forgot';
  @override
  String get forgotTitle => "That's okay.";
  @override
  String get forgotBody => "Let's listen one more time.";
  @override
  String get listenAgain => 'Listen again';
  @override
  String get replay => 'Replay';
  @override
  String get slow => 'Slower';
  @override
  String get normalSpeed => 'Normal';
  @override
  String get mashaAllah => 'Masha’Allah';
  @override
  String get memorizedToday => "You memorized today's Ayah.";
  @override
  String get reviewTomorrow => "Tomorrow we'll review it.";
  @override
  String memorizedTodayCount(int n) => '${ayahs(n)} memorized today';
  @override
  String verseCounter(int current, int total) => '$current of $total';

  @override
  String get reviewTitle => "Today's review";
  @override
  String reviewCount(int n) => 'You have ${ayahs(n)} to review.';
  @override
  String estimatedTime(int m) => 'Estimated time: ${minutes(m)}.';
  @override
  String get welcomeBackReview => "Welcome back. We'll review gently, step by step.";
  @override
  String get deferredNote => "The rest will come over the next days.";
  @override
  String get noReviewTitle => 'No review today';
  @override
  String get noReviewBody => 'All your Ayahs are on schedule.';
  @override
  String get backHome => 'Back home';
  @override
  String get reviewRecallInstruction => 'Recite it from memory, then reveal it.';
  @override
  String get revealAyah => 'Reveal Ayah';
  @override
  String get howDidItFeel => 'How did it feel?';
  @override
  String get rateEasy => 'Easy';
  @override
  String get rateGood => 'Okay';
  @override
  String get rateHard => 'Hard';
  @override
  String get rateForgot => 'I forgot';
  @override
  String get forgotInReview => "That's okay, we'll come back to it shortly.";
  @override
  String get reviewDoneBody => "You finished today's review.";

  @override
  String get progressTitle => 'My progress';
  @override
  String ayahsOfTotal(int done, int total) => '$done / $total Ayahs';
  @override
  String legendMemorized(int n) => 'Memorized: $n';
  @override
  String legendNeedsReview(int n) => 'Needs review: $n';
  @override
  String legendNotStarted(int n) => 'Not started: $n';
  @override
  String get stateMemorized => 'Memorized';
  @override
  String get stateNeedsReview => 'Needs review';
  @override
  String get stateNotStarted => 'Not started';
  @override
  String surahCompleted(String name) => 'You completed Surah $name.';
  @override
  String get fullSurahTest => 'Full Surah test';
  @override
  String get surahTestTitle => 'Surah test';
  @override
  String get nothingYet => 'Start with one Ayah and it will show up here.';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get dailyGoal => 'Daily goal';
  @override
  String get reminder => 'Daily reminder';
  @override
  String get reminderTime => 'Reminder time';
  @override
  String get language => 'Language';
  @override
  String get arabic => 'العربية';
  @override
  String get english => 'English';
}

final class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings.forLocale(locale);

  @override
  bool shouldReload(AppStringsDelegate old) => false;
}

extension AppStringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
