import 'dart:math';
import 'package:ai_note_taker/models/summary.dart';
import 'package:ai_note_taker/viewmodels/record_vm.dart';
import 'package:ai_note_taker/viewmodels/summaries_vm.dart';
import 'package:ai_note_taker/viewmodels/summarize_vm.dart';
import 'package:ai_note_taker/viewmodels/transcribe_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

class RecordView extends StatefulWidget {
  const RecordView({super.key});
  @override
  State<RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> with TickerProviderStateMixin {
  String path = '';

  bool isRecording = false;
  late final AudioRecorder _audioRecorder;
  String? _audioPath;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    _audioRecorder = AudioRecorder();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    super.initState();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
      growable: false,
    ).join();
  }

  Future<void> _startRecording() async {
    try {
      // Check and request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission not granted');
      }

      debugPrint(
        '=========>>>>>>>>>>> RECORDING!!!!!!!!!!!!!!! <<<<<<===========',
      );

      String filePath = await getApplicationDocumentsDirectory().then(
        (value) => '${value.path}/${_generateRandomId()}.wav',
      );

      // Use more compatible settings
      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // Standard sample rate
        bitRate: 128000, // Standard bit rate
        numChannels: 1, // Mono is more compatible
      );

      bool hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw Exception('No recording permission');
      }

      await _audioRecorder.start(config, path: filePath);

      // Start animations
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } catch (e) {
      debugPrint('ERROR WHILE RECORDING: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecorder.stop();

      setState(() {
        _audioPath = path!;
      });

      // Stop animations
      _pulseController.stop();
      _waveController.stop();
      _pulseController.reset();
      _waveController.reset();

      debugPrint('=========>>>>>> PATH: $_audioPath <<<<<<===========');
    } catch (e) {
      debugPrint('ERROR WHILE STOP RECORDING: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<RecordVm, TranscribeVm, SummarizeVm>(
      builder: (context, recordVm, transcribeVm, summarizeVm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: false,
            title: Text(
              'Start Recording',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.9),
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF8F9FA),
                  Colors.grey.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Recording status indicator
                    if (recordVm.isRecording) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFF007AFF).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recording in progress',
                              style: TextStyle(
                                color: const Color(0xFF007AFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // Main recording button with animations
                    GestureDetector(
                      onTapDown: (_) => _scaleController.forward(),
                      onTapUp: (_) => _scaleController.reverse(),
                      onTapCancel: () => _scaleController.reverse(),
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await _startRecording();
                        recordVm.startRecording();
                        recordVm.startTimer();
                      },
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer pulsing ring when recording
                                if (recordVm.isRecording)
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          height: 220,
                                          width: 220,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(
                                                0xFF007AFF,
                                              ).withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // Main button
                                Container(
                                  height: 180,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors:
                                          recordVm.isRecording
                                              ? [
                                                const Color(0xFFFF3B30),
                                                const Color(0xFFFF6B6B),
                                              ]
                                              : [
                                                const Color(0xFF007AFF),
                                                const Color(0xFF4DA6FF),
                                              ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (recordVm.isRecording
                                                ? const Color(0xFFFF3B30)
                                                : const Color(0xFF007AFF))
                                            .withOpacity(0.4),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                        spreadRadius:
                                            recordVm.isRecording ? 5 : 0,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(90),
                                      splashColor: Colors.white.withOpacity(
                                        0.3,
                                      ),
                                      highlightColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          child: Icon(
                                            recordVm.isRecording
                                                ? Icons.stop_rounded
                                                : Icons.mic_rounded,
                                            key: ValueKey(recordVm.isRecording),
                                            size: 80,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Timer display
                    AnimatedOpacity(
                      opacity: recordVm.isRecording ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          recordVm.formattedTime,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF1C1C1E),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Stop recording button
                    if (recordVm.isRecording)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: CupertinoButton(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            await _stopRecording();
                            recordVm.stopRecording();
                            recordVm.stopTimer();
                            await transcribeVm.transcribeAudio(_audioPath!);
                            await summarizeVm.summarizeNotes(
                              transcribeVm.transcriptionResult,
                            );
                            if (context.mounted) {
                              _showActionSheet(context);
                            }
                          },
                          child: Text(
                            'Stop Recording',
                            style: TextStyle(
                              color: const Color(0xFF007AFF),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Processing indicators
                    if (transcribeVm.transcribing ||
                        summarizeVm.isSummarizing) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF007AFF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              transcribeVm.transcribing
                                  ? 'Transcribing audio...'
                                  : 'Summarizing notes...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1C1C1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder:
          (
            BuildContext context,
          ) => Consumer3<TranscribeVm, SummarizeVm, SummariesVm>(
            builder: (context, transcribeVm, summarizeVm, summariesVm, child) {
              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CupertinoActionSheet(
                  title: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Summary Complete',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E8E93),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  message: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Text(
                        summarizeVm.summary,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1C1C1E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  actions: <CupertinoActionSheetAction>[
                    CupertinoActionSheetAction(
                      isDefaultAction: true,
                      onPressed:
                          summarizeVm.isSummarizing
                              ? () {}
                              : () async {
                                HapticFeedback.selectionClick();
                                await summariesVm.addSummary(
                                  Summary(
                                    id: DateTime.now().toString(),
                                    transcription:
                                        transcribeVm.transcriptionResult,
                                    summary: summarizeVm.summary,
                                    eventId:
                                        'selfStarted${DateTime.now().millisecondsSinceEpoch}',
                                    audioPath: _audioPath!,
                                    createdAt: DateTime.now(),
                                    eventName: 'Self-Started',
                                    eventDescription: 'Self-Started Event',
                                    eventStartTime: DateTime.now(),
                                    eventEndTime: DateTime.now().add(
                                      const Duration(hours: 1),
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              },
                      child:
                          summarizeVm.isSummarizing
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF007AFF),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Processing...'),
                                ],
                              )
                              : const Text(
                                'Save Recording',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Discard',
                        style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
