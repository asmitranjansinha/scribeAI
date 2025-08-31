import 'package:ai_note_taker/models/summary.dart';
import 'package:ai_note_taker/services/hive_service.dart';
import 'package:flutter/material.dart';

class SummariesVm extends ChangeNotifier {
  final List<Summary> _summaries = [];

  List<Summary> get summaries => _summaries;

  final _hiveService = HiveService();

  Future<void> loadSummaries() async {
    _summaries.clear();
    _summaries.addAll(await _hiveService.getAllSummaries());
    notifyListeners();
  }

  Future<void> addSummary(Summary summary) async {
    await _hiveService.saveSummary(summary);
    _summaries.add(summary);
    notifyListeners();
  }

  Future<void> removeSummary(Summary summary) async {
    await _hiveService.deleteSummary(summary.id);
    _summaries.remove(summary);
    notifyListeners();
  }
}
