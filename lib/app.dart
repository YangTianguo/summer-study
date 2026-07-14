import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/plan_list_screen.dart';
import 'screens/parent_control_screen.dart';

class SummerStudyApp extends StatelessWidget {
  const SummerStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '暑期提分',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

/// 主框架（自适应 Tab：Web端3个，手机端4个）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Web 端没有家长控制能力，只显示 3 个 Tab
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.today_outlined),
        selectedIcon: Icon(Icons.today),
        label: '今日计划',
      ),
      const NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: '学习统计',
      ),
      const NavigationDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: '计划管理',
      ),
    ];

    final pages = <Widget>[
      const HomeScreen(),
      const ProgressScreen(),
      const PlanListScreen(),
    ];

    // 仅在非 Web 平台显示家长控制
    if (!kIsWeb) {
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.shield_outlined),
        selectedIcon: Icon(Icons.shield),
        label: '家长控制',
      ));
      pages.add(const ParentControlScreen());
    }

    // 确保 index 不越界
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        animationDuration: const Duration(milliseconds: 300),
        destinations: destinations,
      ),
    );
  }
}
