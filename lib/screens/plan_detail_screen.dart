import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/plan_provider.dart';
import '../widgets/task_tile.dart';
import 'add_plan_screen.dart';

class PlanDetailScreen extends StatefulWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 确保加载任务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadTasksForPlan(widget.planId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PlanProvider>();
    final plan = provider.plans.firstWhere(
      (p) => p.id == widget.planId,
      orElse: () => throw '计划不存在',
    );
    final tasks = provider.getTasksForPlan(widget.planId);

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // 编辑计划
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddPlanScreen(existingPlan: plan),
                ),
              ).then((_) {
                provider.loadAll();
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 计划信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTag(theme, plan.subject,
                          Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      _buildTag(theme, plan.typeLabel,
                          theme.colorScheme.surfaceContainerHighest),
                      const Spacer(),
                      Icon(
                        plan.isActive
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        color: plan.isActive ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (plan.description.isNotEmpty) ...[
                    Text(
                      plan.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('yyyy/MM/dd').format(plan.startDate)} ~ ${DateFormat('yyyy/MM/dd').format(plan.endDate)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 任务列表标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '任务列表 (${tasks.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddTaskDialog(context, provider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加任务'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '还没有添加任务',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 任务列表
          ...tasks.map((task) => Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TaskTile(
                    task: task,
                    onToggle: () => provider.toggleTask(task),
                    onDelete: () => provider.deleteTask(task.id, widget.planId),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTag(ThemeData theme, String text, Color color) {
    final isSurfaceType = color == theme.colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSurfaceType ? color : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSurfaceType
              ? theme.colorScheme.onSurfaceVariant
              : color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, PlanProvider provider) {
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
                  planId: widget.planId,
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
}
