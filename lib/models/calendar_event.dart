import 'package:intl/intl.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime? start;
  final DateTime? end;
  final bool isAllDay;
  final String location;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.isAllDay,
    required this.location,
  });

  String get formattedDate {
    if (start == null) return 'Date not set';

    if (isAllDay) {
      return DateFormat('MMM dd, yyyy').format(start!);
    }

    final startFormat = DateFormat('MMM dd, yyyy HH:mm');
    final endFormat = DateFormat('HH:mm');

    return '${startFormat.format(start!)} - ${end != null ? endFormat.format(end!) : "?"}';
  }
}
