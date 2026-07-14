import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/plan_provider.dart';
import 'providers/parent_control_provider.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => ParentControlProvider()..loadAll()),
      ],
      child: const SummerStudyApp(),
    ),
  );
}
