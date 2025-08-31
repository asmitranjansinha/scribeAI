import 'package:ai_note_taker/models/calendar_event.dart';
import 'package:ai_note_taker/viewmodels/event_vm.dart';
import 'package:ai_note_taker/views/event_detail_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _refreshAnimation;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // Full rotation
    ).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Load events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    final eventVm = context.read<EventVm>();
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final end = start.add(const Duration(days: 7));

    eventVm.fetchEvents(start, end);
  }

  void _refreshEvents() async {
    HapticFeedback.selectionClick();
    _refreshController.forward().then((_) {
      _refreshController.reset();
    });
    _loadEvents();
  }

  String _getEventTimeString(CalendarEvent event) {
    if (event.start == null) return 'No time';

    if (event.isAllDay) {
      return 'All day';
    }

    final startTime = DateFormat('h:mm a').format(event.start!);
    if (event.end != null) {
      final endTime = DateFormat('h:mm a').format(event.end!);
      return '$startTime - $endTime';
    }

    return startTime;
  }

  String _getEventDateString(CalendarEvent event) {
    if (event.start == null) return 'No date';

    final now = DateTime.now();
    final eventDate = event.start!;
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

  Color _getEventColor(int index) {
    final colors = [
      const Color(0xFF007AFF), // Blue
      const Color(0xFF34C759), // Green
      const Color(0xFFFF9500), // Orange
      const Color(0xFFFF3B30), // Red
      const Color(0xFF5856D6), // Purple
      const Color(0xFFFF2D92), // Pink
    ];
    return colors[index % colors.length];
  }

  IconData _getEventIcon(CalendarEvent event) {
    final title = event.title.toLowerCase();

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

  List<CalendarEvent> _getEventsForToday(List<CalendarEvent> events) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return events.where((event) {
      if (event.start == null) return false;
      return event.start!.isAfter(
            todayStart.subtract(const Duration(milliseconds: 1)),
          ) &&
          event.start!.isBefore(todayEnd);
    }).toList();
  }

  List<CalendarEvent> _getUpcomingEvents(List<CalendarEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final oneWeekFromToday = today.add(const Duration(days: 7));

    return events.where((event) {
      if (event.start == null) return false;

      return event.start!.isAfter(
            tomorrow.subtract(const Duration(milliseconds: 1)),
          ) &&
          event.start!.isBefore(oneWeekFromToday.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'Calendar Events',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.9),
            letterSpacing: -0.5,
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
              icon: AnimatedBuilder(
                animation: _refreshAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _refreshAnimation.value,
                    child: const Icon(Icons.refresh, color: Color(0xFF007AFF)),
                  );
                },
              ),
              onPressed: _refreshEvents,
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
          child: Consumer<EventVm>(
            builder: (context, eventVm, child) {
              final todayEvents = _getEventsForToday(eventVm.events);
              final upcomingEvents = _getUpcomingEvents(eventVm.events);

              return eventVm.events.isEmpty
                  ? _buildEmptyState()
                  : FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        // Today's summary
                        SliverToBoxAdapter(
                          child: _buildTodaySummary(
                            todayEvents.length,
                            eventVm.events.length,
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 30)),

                        // Today's Events Section
                        if (todayEvents.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              'Today\'s Events',
                              Icons.today_rounded,
                            ),
                          ),

                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return _buildEventCard(
                                todayEvents[index],
                                index,
                                isToday: true,
                              );
                            }, childCount: todayEvents.length),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 30)),
                        ],

                        // Upcoming Events Section
                        if (upcomingEvents.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              'Upcoming Events',
                              Icons.schedule_rounded,
                            ),
                          ),

                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return _buildEventCard(
                                upcomingEvents[index],
                                index + todayEvents.length,
                              );
                            }, childCount: upcomingEvents.length),
                          ),
                        ],

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 60,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your calendar events will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF007AFF),
                ),
                const SizedBox(width: 8),
                Text(
                  'Grant calendar permissions to see events',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF007AFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(int todayCount, int totalCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007AFF), Color(0xFF4DA6FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM dd').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayCount == 0
                      ? 'No events today'
                      : todayCount == 1
                      ? '1 event today'
                      : '$todayCount events today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalCount total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF007AFF)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    CalendarEvent event,
    int index, {
    bool isToday = false,
  }) {
    final eventColor = _getEventColor(index);

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder:
                    (context) =>
                        EventDetailView(event: event, eventColor: eventColor),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border:
                  isToday
                      ? Border.all(
                        color: const Color(0xFF007AFF).withOpacity(0.3),
                        width: 1.5,
                      )
                      : null,
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: eventColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getEventIcon(event),
                        color: eventColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: const Color(0xFF8E8E93),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getEventTimeString(event),
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
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),

                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1C1C1E),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: eventColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: eventColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getEventDateString(event),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: eventColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFF8E8E93),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showCupertinoModalPopup<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: CupertinoActionSheet(
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getEventTimeString(event),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            message:
                event.description.isNotEmpty
                    ? Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Text(
                          event.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1C1C1E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                    : null,
            actions: <CupertinoActionSheetAction>[
              if (event.location.isNotEmpty)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Open location in maps
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF007AFF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open Location',
                        style: TextStyle(color: const Color(0xFF007AFF)),
                      ),
                    ],
                  ),
                ),

              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Add to calendar or edit
                },
                child: const Text(
                  'Record Event',
                  style: TextStyle(color: Color(0xFF007AFF)),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }
}
