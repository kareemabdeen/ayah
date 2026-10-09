import '../services/notifications/reminder_service.dart';

/// Supportive, never guilt-based reminder copy. Context-free (no
/// BuildContext) because reminders are scheduled from use cases.
abstract final class ReminderCopy {
  static ReminderContent forLocale(String localeCode) => localeCode == 'en' ? _en : _ar;

  static const _ar = ReminderContent(
    title: 'آية',
    channelName: 'تذكير يومي',
    bodies: [
      'آية واحدة مستنياك.',
      '3 دقايق بس النهارده؟',
      'فاكر آية امبارح؟ خلينا نشوف.',
      'خطوة صغيرة النهارده تكفي.',
      'وقتك المفضل للحفظ جه 🌿',
      'آية واحدة، وبس.',
      'يلا نكمّل سوا من مكان ما وقفت.',
    ],
  );

  static const _en = ReminderContent(
    title: 'Ayah',
    channelName: 'Daily reminder',
    bodies: [
      'One Ayah is waiting for you.',
      'Just 3 minutes today?',
      "Remember yesterday's Ayah? Let's see.",
      'A small step today is enough.',
      "It's your favorite time to memorize 🌿",
      'Just one Ayah.',
      "Let's continue together from where you stopped.",
    ],
  );
}
