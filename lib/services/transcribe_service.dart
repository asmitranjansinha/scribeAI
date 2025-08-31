import 'package:whisper_ggml/whisper_ggml.dart';

class TranscribeService {
  late WhisperController _whisperController;

  Future<String?> transcribeAudio(String audioPath) async {
    try {
      _whisperController = WhisperController();
      await _whisperController.downloadModel(WhisperModel.base);
      final result = await _whisperController.transcribe(
        model: WhisperModel.base,
        audioPath: audioPath,
      );
      return result?.transcription.text;
    } catch (e) {
      print('Error transcribing audio: $e');
    }
    return null;
  }
}
