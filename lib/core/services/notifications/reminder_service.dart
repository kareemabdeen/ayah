import 'package:equatable/equatable.dart';

/// What a reminder says. Bodies rotate across the week so reminders
/// stay gentle and don't become noise.
final class ReminderContent extends Equatable {
  const ReminderContent({required this.title, required this.bodies, required this.channelName});

  final String title;
  final List<String> bodies;
  final String channelName;

  @override
  List<Object?> get props => [title, bodies, channelName];
}

/// Package-agnostic local notification contract.
abstract interface class ReminderService {
  Future<void> initialize();

  /// Returns whether notifications are allowed.
  Future<bool> requestPermission();

  /// Schedules a repeating daily reminder at [hour]:[minute] local time,
  /// replacing any previously scheduled reminder.
  Future<void> scheduleDaily({required int hour, required int minute, required ReminderContent content});

  Future<void> cancelAll();
}
