import 'package:ai_note_taker/services/summarize_service.dart';
import 'package:flutter/material.dart';

class SummarizeVm extends ChangeNotifier {
  bool _isSummarizing = false;
  bool get isSummarizing => _isSummarizing;

  void startSummarizing() {
    _isSummarizing = true;
    notifyListeners();
  }

  void stopSummarizing() {
    _isSummarizing = false;
    notifyListeners();
  }

  String get summary => _summary;
  String _summary = '';

  final _summarizeService = SummarizeService();

  Future<void> summarizeNotes(String notes) async {
    startSummarizing();
    _summary = '';
    notifyListeners();
    final summary = await _summarizeService.summarizeMeetingNotes(notes);
    _summary = summary;
    notifyListeners();
    stopSummarizing();
  }
}
