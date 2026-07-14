import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/plan_provider.dart';
import '../models/plan.dart';
import 'add_plan_screen.dart';
import 'plan_detail_screen.dart';

class PlanListScreen extends StatelessWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 计划管理',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<PlanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = provider.plans;

          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    '还没有学习计划',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                return _PlanListTile(plan: plans[index]);
              },
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
}

class _PlanListTile extends StatelessWidget {
  final Plan plan;

  const _PlanListTile({required this.plan});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectColor = _getSubjectColor(plan.subject);
    final dateFormat = DateFormat('yyyy/MM/dd');
    final now = DateTime.now();
    final isActive = plan.isActiveOnDate(now);
    final isExpired = now.isAfter(plan.endDate);

    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editPlan(context),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => _deletePlan(context),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanDetailScreen(planId: plan.id),
              ),
            ).then((_) {
              context.read<PlanProvider>().loadAll();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 学科标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.subject,
                        style: TextStyle(
                          color: subjectColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 类型标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.typeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 状态标记
                    if (!plan.isActive)
                      Icon(Icons.pause_circle,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant),
                    if (isExpired)
                      Icon(Icons.event_busy,
                          size: 20, color: Colors.orange),
                    if (isActive && !isExpired && plan.isActive)
                      Icon(Icons.check_circle,
                          size: 20, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  plan.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.date_range,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(plan.startDate)} ~ ${dateFormat.format(plan.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

  void _editPlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlanScreen(existingPlan: plan),
      ),
    ).then((_) {
      context.read<PlanProvider>().loadAll();
    });
  }

  void _deletePlan(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${plan.title}」及其所有任务吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<PlanProvider>().deletePlan(plan.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
