import 'package:ai_note_taker/models/summary.dart';
import 'package:hive/hive.dart';

class HiveService {
  Future<void> saveSummary(Summary summary) async {
    final box = await Hive.openBox<Summary>('summaries');
    await box.put(summary.id, summary);
  }

  Future<Summary?> getSummary(String id) async {
    final box = await Hive.openBox<Summary>('summaries');
    return box.get(id);
  }

  Future<List<Summary>> getAllSummaries() async {
    final box = await Hive.openBox<Summary>('summaries');
    return box.values.toList();
  }

  Future<void> deleteSummary(String id) async {
    final box = await Hive.openBox<Summary>('summaries');
    await box.delete(id);
  }
}
