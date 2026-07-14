import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:summer_study/providers/plan_provider.dart';
import 'package:summer_study/app.dart';

void main() {
  testWidgets('App renders main shell with bottom navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlanProvider(),
        child: const SummerStudyApp(),
      ),
    );

    // 验证底部导航栏存在
    expect(find.text('今日计划'), findsOneWidget);
    expect(find.text('学习统计'), findsOneWidget);
    expect(find.text('计划管理'), findsOneWidget);

    // 验证标题存在
    expect(find.text('📚 暑期提分'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches pages', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlanProvider(),
        child: const SummerStudyApp(),
      ),
    );

    // 点击统计页
    await tester.tap(find.text('学习统计'));
    await tester.pumpAndSettle();
    expect(find.text('📊 学习统计'), findsOneWidget);

    // 点击计划管理页
    await tester.tap(find.text('计划管理'));
    await tester.pumpAndSettle();
    expect(find.text('📋 计划管理'), findsOneWidget);

    // 回到今日计划
    await tester.tap(find.text('今日计划'));
    await tester.pumpAndSettle();
    expect(find.text('📚 暑期提分'), findsOneWidget);
  });
}
