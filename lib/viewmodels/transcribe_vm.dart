import 'package:ai_note_taker/services/transcribe_service.dart';
import 'package:flutter/material.dart';

class TranscribeVm extends ChangeNotifier {
  final TranscribeService _transcribeService = TranscribeService();

  String _transcriptionResult = '';
  String get transcriptionResult => _transcriptionResult;

  bool _transcribing = false;
  bool get transcribing => _transcribing;

  Future<void> transcribeAudio(String audioPath) async {
    try {
      _transcribing = true;
      notifyListeners();
      final result = await _transcribeService.transcribeAudio(audioPath);
      _transcriptionResult = result ?? '';
      notifyListeners();
    } catch (e) {
      print('Error transcribing audio: $e');
    } finally {
      _transcribing = false;
      notifyListeners();
    }
  }
}
