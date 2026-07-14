import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/plan_provider.dart';
import '../database/storage_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, int> _weeklyData = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    final store = StorageService();
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final data = await store.getCompletionCountByDateRange(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );

    setState(() {
      _weeklyData = data;
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 学习统计',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PlanProvider>().loadAll();
              _loadStats();
            },
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || _isLoadingStats) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.stats;

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadAll();
              await _loadStats();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 概览卡片
                _buildStatsOverview(context, stats),
                const SizedBox(height: 16),

                // 本周完成趋势图
                _buildWeeklyChart(context),
                const SizedBox(height: 16),

                // 连续打卡
                _buildStreakCard(context, stats),
                const SizedBox(height: 16),

                // 今日完成率
                _buildTodayCard(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book,
            label: '学习计划',
            value: '${stats['activePlanCount'] ?? 0}',
            sublabel: '进行中',
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.task_alt,
            label: '完成任务',
            value: '${stats['totalCompletions'] ?? 0}',
            sublabel: '总次数',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            label: '连续打卡',
            value: '${stats['streakDays'] ?? 0}',
            sublabel: '天',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weekDayNames = ['一', '二', '三', '四', '五', '六', '日'];

    final spots = List.generate(7, (i) {
      final date =
          startOfWeek.add(Duration(days: i));
      final dateStr =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final count = _weeklyData[dateStr] ?? 0;
      return FlSpot(i.toDouble(), count.toDouble());
    });

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周完成趋势',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY < 4 ? 4 : maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 7) return const SizedBox();
                          final isToday = startOfWeek
                              .add(Duration(days: idx))
                              .day == today.day;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weekDayNames[idx],
                              style: TextStyle(
                                color: isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight:
                                    isToday ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: spots.map((spot) {
                    final idx = spot.x.toInt();
                    final date =
                        startOfWeek.add(Duration(days: idx));
                    final isToday = date.day == today.day &&
                        date.month == today.month;

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: spot.y,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(alpha: 0.5),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final streak = (stats['streakDays'] as int?) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连续打卡',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$streak',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' 天',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // 火焰进度
            if (streak > 0)
              Column(
                children: [
                  Text(
                    streak >= 7
                        ? '🔥'
                        : streak >= 3
                            ? '🌟'
                            : '💪',
                    style: const TextStyle(fontSize: 40),
                  ),
                  Text(
                    streak >= 7
                        ? '太棒了！'
                        : streak >= 3
                            ? '继续加油'
                            : '好的开始',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context, PlanProvider provider) {
    final theme = Theme.of(context);
    final total = provider.todayTotalTasks;
    final completed = provider.todayCompletedTasks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日数据',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTodayStat(
                    context, '总任务', '$total', Icons.assignment),
                _buildTodayStat(
                    context, '已完成', '$completed', Icons.check_circle_outline),
                _buildTodayStat(
                  context,
                  '完成率',
                  total > 0 ? '${(completed / total * 100).toInt()}%' : '-',
                  Icons.pie_chart_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStat(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              sublabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
