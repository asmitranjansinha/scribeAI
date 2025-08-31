import 'package:ai_note_taker/models/calendar_event.dart';
import 'package:ai_note_taker/services/calendar_service.dart';
import 'package:flutter/material.dart';

class EventVm extends ChangeNotifier {
  List<CalendarEvent> _events = [];

  List<CalendarEvent> get events => _events;

  void setEvents(List<CalendarEvent> events) {
    _events = events;
    notifyListeners();
  }

  final _calendarService = CalendarService();

  Future<void> fetchEvents(DateTime start, DateTime end) async {
    final events = await _calendarService.getGoogleCalendarEvents(start, end);
    setEvents(events);
  }
}
