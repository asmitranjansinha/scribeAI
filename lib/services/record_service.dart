import 'dart:developer';

import 'package:record/record.dart';

class RecordService {
  final _record = AudioRecorder();

  startRecording() async {
    // Check and request permission if needed
    if (await _record.hasPermission()) {
      log('Recording started');
      // Start recording to file
      await _record.start(const RecordConfig(), path: 'aFullPath/myFile.m4a');
    }
  }

  Future<String?> stopRecording() async {
    // Stop recording...
    final path = await _record.stop();
    return path;
  }
}
