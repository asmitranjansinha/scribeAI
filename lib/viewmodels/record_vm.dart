import 'dart:async';

import 'package:flutter/material.dart';

class RecordVm extends ChangeNotifier {
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  void startRecording() {
    _isRecording = true;
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }

  Timer _timer = Timer(const Duration(), () {});
  int _elapsedTime = 0;
  String get formattedTime {
    final minutes = (_elapsedTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording) {
        _elapsedTime++;
        notifyListeners();
      }
    });
  }

  void stopTimer() {
    _timer.cancel();
  }
}
