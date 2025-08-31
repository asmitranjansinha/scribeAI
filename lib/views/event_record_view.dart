import 'dart:math';
import 'package:ai_note_taker/models/calendar_event.dart';
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
import 'package:intl/intl.dart';

class EventRecordView extends StatefulWidget {
  final CalendarEvent event;
  final Color eventColor;

  const EventRecordView({
    super.key,
    required this.event,
    required this.eventColor,
  });

  @override
  State<EventRecordView> createState() => _EventRecordViewState();
}

class _EventRecordViewState extends State<EventRecordView>
    with TickerProviderStateMixin {
  String path = '';

  bool isRecording = false;
  late final AudioRecorder _audioRecorder;
  String? _audioPath;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
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
        '=========>>>>>>>>>>> RECORDING EVENT: ${widget.event.title}!!! <<<<<<===========',
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

      setState(() {
        isRecording = true;
      });
    } catch (e) {
      debugPrint('ERROR WHILE RECORDING: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecorder.stop();

      setState(() {
        _audioPath = path!;
        isRecording = false;
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

  String _getEventTimeString() {
    if (widget.event.start == null) return 'No time';

    if (widget.event.isAllDay) {
      return 'All day event';
    }

    final startTime = DateFormat('h:mm a').format(widget.event.start!);
    if (widget.event.end != null) {
      final endTime = DateFormat('h:mm a').format(widget.event.end!);
      return '$startTime - $endTime';
    }

    return startTime;
  }

  String _getEventDateString() {
    if (widget.event.start == null) return 'No date';

    final now = DateTime.now();
    final eventDate = widget.event.start!;
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

    if (eventDay == today) {
      return 'Today';
    } else if (eventDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (eventDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(eventDate);
    }
  }

  IconData _getEventIcon() {
    final title = widget.event.title.toLowerCase();

    if (title.contains('meeting') || title.contains('call')) {
      return Icons.video_call_rounded;
    } else if (title.contains('lunch') ||
        title.contains('dinner') ||
        title.contains('food')) {
      return Icons.restaurant_rounded;
    } else if (title.contains('workout') ||
        title.contains('gym') ||
        title.contains('exercise')) {
      return Icons.fitness_center_rounded;
    } else if (title.contains('travel') ||
        title.contains('flight') ||
        title.contains('trip')) {
      return Icons.flight_rounded;
    } else if (title.contains('appointment') ||
        title.contains('doctor') ||
        title.contains('medical')) {
      return Icons.local_hospital_rounded;
    } else if (title.contains('birthday') ||
        title.contains('party') ||
        title.contains('celebration')) {
      return Icons.celebration_rounded;
    } else {
      return Icons.event_rounded;
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
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: const Color(0xFF1C1C1E),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
              ),
            ),
            centerTitle: false,
            title: Text(
              'Record Event',
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Event Context Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.eventColor.withOpacity(0.1),
                              widget.eventColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.eventColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.eventColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getEventIcon(),
                                color: widget.eventColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.event.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C1C1E),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _getEventDateString(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.eventColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      Text(
                                        _getEventTimeString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Recording status indicator
                      if (isRecording) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: widget.eventColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: widget.eventColor.withOpacity(0.3),
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
                                'Recording ${widget.event.title}',
                                style: TextStyle(
                                  color: widget.eventColor,
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
                          if (!isRecording) {
                            HapticFeedback.mediumImpact();
                            await _startRecording();
                          }
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
                                  if (isRecording)
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
                                                color: widget.eventColor
                                                    .withOpacity(0.3),
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
                                            isRecording
                                                ? [
                                                  const Color(0xFFFF3B30),
                                                  const Color(0xFFFF6B6B),
                                                ]
                                                : [
                                                  widget.eventColor,
                                                  widget.eventColor.withOpacity(
                                                    0.8,
                                                  ),
                                                ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isRecording
                                                  ? const Color(0xFFFF3B30)
                                                  : widget.eventColor)
                                              .withOpacity(0.4),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                          spreadRadius: isRecording ? 5 : 0,
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
                                        highlightColor: Colors.white
                                            .withOpacity(0.1),
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            child: Icon(
                                              isRecording
                                                  ? Icons.stop_rounded
                                                  : Icons.mic_rounded,
                                              key: ValueKey(isRecording),
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

                      // Timer display (using a simple timer since RecordVm might not be available)
                      AnimatedOpacity(
                        opacity: isRecording ? 1.0 : 0.0,
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
                          child: const Text(
                            '00:00:00', // You can integrate with RecordVm timer here
                            style: TextStyle(
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
                      if (isRecording)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          child: CupertinoButton(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              await _stopRecording();
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
                                color: widget.eventColor,
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
                                    widget.eventColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                transcribeVm.transcribing
                                    ? 'Transcribing audio...'
                                    : 'Summarizing notes...',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1C1C1E),
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
                    child: Column(
                      children: [
                        Text(
                          'Event Recording Complete',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8E8E93),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C1C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                                    eventId: widget.event.id,
                                    audioPath: _audioPath!,
                                    createdAt: DateTime.now(),
                                    eventName: widget.event.title,
                                    eventDescription: widget.event.description,
                                    eventStartTime:
                                        widget.event.start ?? DateTime.now(),
                                    eventEndTime:
                                        widget.event.end ??
                                        DateTime.now().add(
                                          const Duration(hours: 1),
                                        ),
                                  ),
                                );
                                Navigator.of(context).pop();
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
                                        widget.eventColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Processing...'),
                                ],
                              )
                              : const Text(
                                'Save Event Recording',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Discard Recording',
                        style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
