import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/plan_provider.dart';
import '../providers/parent_control_provider.dart';
import '../widgets/task_tile.dart';
import 'add_plan_screen.dart';

/// 同步家长控制状态（根据学习完成情况自动开关拦截）
void _syncParentControl(BuildContext context) {
  try {
    final planProvider = context.read<PlanProvider>();
    final controlProvider = context.read<ParentControlProvider>();
    final allDone = planProvider.todayTotalTasks > 0 &&
        planProvider.todayCompletedTasks >= planProvider.todayTotalTasks;
    controlProvider.updateBlockingByCompletion(allDone);
  } catch (_) {
    // 家长控制未初始化时忽略
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('📚 暑期提分', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () {
              context.read<PlanProvider>().loadAll();
            },
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.todayPlans.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              children: [
                // 今日进度概览卡片
                _buildTodayProgressCard(context, provider),
                const SizedBox(height: 8),
                // 各计划及其任务
                ...provider.todayPlans.map(
                  (plan) => _buildPlanSection(context, provider, plan.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPlanScreen()),
          ).then((_) {
            context.read<PlanProvider>().loadAll();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('新建计划'),
      ),
    );
  }

  Widget _buildTodayProgressCard(BuildContext context, PlanProvider provider) {
    final total = provider.todayTotalTasks;
    final completed = provider.todayCompletedTasks;
    final rate = total > 0 ? completed / total : 0.0;
    final isAllDone = total > 0 && completed >= total;

    return Card(
      color: isAllDone
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // 进度环
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 6,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          isAllDone
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${(rate * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAllDone ? '🎉 全部完成！' : '今日进度',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '已完成 $completed / $total 项任务',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (isAllDone)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '可以放松一下啦~',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.green),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isAllDone && total > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: rate,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSection(
      BuildContext context, PlanProvider provider, String planId) {
    final plan = provider.todayPlans.firstWhere((p) => p.id == planId);
    final tasks = provider.getTasksForPlan(planId);
    final completedCount = tasks.where((t) => t.isCompletedToday).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 计划标题行
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSubjectColor(plan.subject).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    plan.subject,
                    style: TextStyle(
                      color: _getSubjectColor(plan.subject),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plan.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '$completedCount/${tasks.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: completedCount >= tasks.length && tasks.isNotEmpty
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                plan.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            // 任务列表
            ...tasks.map((task) => TaskTile(
                  task: task,
                  onToggle: () async {
                    await provider.toggleTask(task);
                    // 同步家长控制拦截状态
                    _syncParentControl(context);
                  },
                  onDelete: () => provider.deleteTask(task.id, planId),
                )),
            // 添加任务按钮
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    '还没有任务，点击下方按钮添加',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () => _showAddTaskDialog(context, provider, planId),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加任务'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(
      BuildContext context, PlanProvider provider, String planId) {
    final titleController = TextEditingController();
    final minutesController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加任务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '任务名称',
                hintText: '例如：做一套数学卷子',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesController,
              decoration: const InputDecoration(
                labelText: '预计时长（分钟）',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                provider.addTaskToPlan(
                  planId: planId,
                  title: title,
                  estimatedMinutes:
                      int.tryParse(minutesController.text) ?? 30,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              '还没有学习计划',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮创建你的第一个学习计划\n设定每日任务，开始暑期提分之旅！',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPlanScreen()),
                ).then((_) {
                  context.read<PlanProvider>().loadAll();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('创建学习计划'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case '数学':
        return const Color(0xFF4A90D9);
      case '英语':
        return const Color(0xFFE8734A);
      case '语文':
        return const Color(0xFF5B9A5B);
      case '综合':
        return const Color(0xFF7B61D9);
      default:
        return const Color(0xFF607D8B);
    }
  }
}
