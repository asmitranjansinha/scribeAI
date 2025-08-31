import 'package:ai_note_taker/firebase_options.dart';
import 'package:ai_note_taker/models/summary.dart';
import 'package:ai_note_taker/viewmodels/event_vm.dart';
import 'package:ai_note_taker/viewmodels/record_vm.dart';
import 'package:ai_note_taker/viewmodels/summaries_vm.dart';
import 'package:ai_note_taker/viewmodels/summarize_vm.dart';
import 'package:ai_note_taker/viewmodels/transcribe_vm.dart';
import 'package:ai_note_taker/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var path = await getApplicationDocumentsDirectory().then((dir) => dir.path);
  Hive
    ..init(path)
    ..registerAdapter(SummaryAdapter());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecordVm()),
        ChangeNotifierProvider(create: (_) => TranscribeVm()),
        ChangeNotifierProvider(create: (_) => SummarizeVm()),
        ChangeNotifierProvider(create: (_) => SummariesVm()),
        ChangeNotifierProvider(create: (_) => EventVm()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Note Taker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeView(),
    );
  }
}
