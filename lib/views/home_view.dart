import 'package:ai_note_taker/views/events_view.dart';
import 'package:ai_note_taker/views/record_view.dart';
import 'package:ai_note_taker/views/summary_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  final Color iconColor = Colors.blue;
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final Color iconColor = Colors.blue;
  int _currentIndex = 0;

  final List<Widget> _pages = [EventsView(), RecordView(), SummaryListView()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CupertinoTabBar(
        height: 80,
        onTap: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.calendar,
              color: _currentIndex == 0 ? iconColor : Colors.grey,
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.mic,
              color: _currentIndex == 1 ? iconColor : Colors.grey,
            ),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.folder,
              color: _currentIndex == 2 ? iconColor : Colors.grey,
            ),
            label: 'Summaries',
          ),
        ],
      ),
    );
  }
}
