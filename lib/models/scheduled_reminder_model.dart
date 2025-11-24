// models/scheduled_reminder_model.dart
class ScheduledReminder {
  final int id;
  final String title;
  final String body;
  final String type;
  final String scheduledTime;

  ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledTime,
  });

  @override
  String toString() {
    return 'ScheduledReminder{id: $id, title: $title, type: $type, time: $scheduledTime}';
  }
}