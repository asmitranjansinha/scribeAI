import 'package:ai_note_taker/models/calendar_event.dart';
import 'package:ai_note_taker/views/event_record_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EventDetailView extends StatefulWidget {
  final CalendarEvent event;
  final Color eventColor;

  const EventDetailView({
    super.key,
    required this.event,
    required this.eventColor,
  });

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getEventTimeString() {
    if (widget.event.start == null) return 'No time';

    if (widget.event.isAllDay) {
      return 'All day';
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
      return 'Today, ${DateFormat('MMMM dd, yyyy').format(eventDate)}';
    } else if (eventDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${DateFormat('MMMM dd, yyyy').format(eventDate)}';
    } else if (eventDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('MMMM dd, yyyy').format(eventDate)}';
    } else {
      return DateFormat('EEEE, MMMM dd, yyyy').format(eventDate);
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

  Duration? _getEventDuration() {
    if (widget.event.start == null || widget.event.end == null) {
      return null;
    }
    return widget.event.end!.difference(widget.event.start!);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  bool _isEventToday() {
    if (widget.event.start == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      widget.event.start!.year,
      widget.event.start!.month,
      widget.event.start!.day,
    );

    return eventDay == today;
  }

  bool _isEventUpcoming() {
    if (widget.event.start == null) return false;
    return widget.event.start!.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final duration = _getEventDuration();

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
        actions: [
          Container(
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
              icon: const Icon(Icons.more_horiz_rounded),
              color: const Color(0xFF1C1C1E),
              onPressed: () {
                HapticFeedback.selectionClick();
                _showMoreOptions();
              },
            ),
          ),
        ],
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
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Event Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.eventColor,
                            widget.eventColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: widget.eventColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _getEventIcon(),
                                  color: Colors.white,
                                  size: 28,
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
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (_isEventToday())
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'TODAY',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        if (_isEventUpcoming() &&
                                            !_isEventToday())
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'UPCOMING',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Event Details Cards
                    _buildDetailCard(
                      icon: Icons.schedule_rounded,
                      title: 'Time',
                      content: _getEventTimeString(),
                      subtitle:
                          duration != null ? _formatDuration(duration) : null,
                    ),

                    const SizedBox(height: 16),

                    _buildDetailCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Date',
                      content: _getEventDateString(),
                    ),

                    if (widget.event.location.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        content: widget.event.location,
                        isClickable: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          // TODO: Open location in maps
                        },
                      ),
                    ],

                    if (widget.event.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        content: widget.event.description,
                        isExpanded: true,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit Event',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              // TODO: Navigate to edit event
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              // TODO: Share event
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildActionButton(
                      icon: Icons.mic_rounded,
                      label: 'Record Event',
                      isPrimary: true,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    EventRecordView(
                                      event: widget.event,
                                      eventColor: widget.eventColor,
                                    ),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              const begin = Offset(0.0, 1.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;

                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
    bool isClickable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isClickable ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.eventColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: widget.eventColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                            height: isExpanded ? 1.4 : 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isClickable)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.eventColor,
                      size: 20,
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 56),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.eventColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.eventColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isPrimary ? widget.eventColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                isPrimary
                    ? null
                    : Border.all(
                      color: Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
            boxShadow: [
              BoxShadow(
                color:
                    isPrimary
                        ? widget.eventColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                blurRadius: isPrimary ? 20 : 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF1C1C1E),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showCupertinoModalPopup<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: CupertinoActionSheet(
            title: Text(
              'Event Options',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Add to Apple Calendar
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, color: Color(0xFF007AFF)),
                    SizedBox(width: 8),
                    Text(
                      'Add to Calendar',
                      style: TextStyle(color: Color(0xFF007AFF)),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Set reminder
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF007AFF),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Set Reminder',
                      style: TextStyle(color: Color(0xFF007AFF)),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Duplicate event
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_outlined, color: Color(0xFF007AFF)),
                    SizedBox(width: 8),
                    Text(
                      'Duplicate Event',
                      style: TextStyle(color: Color(0xFF007AFF)),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Delete event
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                    SizedBox(width: 8),
                    Text(
                      'Delete Event',
                      style: TextStyle(color: Color(0xFFFF3B30)),
                    ),
                  ],
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
    );
  }
}
