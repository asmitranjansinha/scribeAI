import 'package:hive/hive.dart';

part 'summary.g.dart';

@HiveType(typeId: 0) // <-- Must be unique across your app
class Summary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String transcription;

  @HiveField(2)
  final String summary;

  @HiveField(3)
  final String eventId;

  @HiveField(4)
  final String audioPath;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String eventName;

  @HiveField(7)
  final String eventDescription;

  @HiveField(8)
  final DateTime eventStartTime;

  @HiveField(9)
  final DateTime eventEndTime;

  Summary({
    required this.id,
    required this.transcription,
    required this.summary,
    required this.eventId,
    required this.audioPath,
    required this.createdAt,
    required this.eventName,
    required this.eventDescription,
    required this.eventStartTime,
    required this.eventEndTime,
  });
}
