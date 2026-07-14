import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/plan_provider.dart';
import '../providers/parent_control_provider.dart';
import '../services/plan_importer.dart';
import '../services/seed_data.dart';
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
          // 导入按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导入计划',
            onSelected: (value) {
              if (value == 'paste') {
                _showImportDialog(context);
              } else if (value == 'demo') {
                _importDemoData(context);
              } else if (value == 'sample') {
                _downloadSample(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'paste',
                child: ListTile(
                  leading: Icon(Icons.paste),
                  title: Text('粘贴 JSON 导入'),
                  subtitle: Text('从剪贴板粘贴计划数据', style: TextStyle(fontSize: 12)),
                  dense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'demo',
                child: ListTile(
                  leading: Icon(Icons.rocket_launch),
                  title: Text('加载杨田安暑期计划'),
                  subtitle: Text('一键导入完整的暑期提升计划', style: TextStyle(fontSize: 12)),
                  dense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sample',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('下载示例 JSON 文件'),
                  subtitle: Text('下载模板，修改后导入', style: TextStyle(fontSize: 12)),
                  dense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              '还没有学习计划',
              style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '创建计划或导入已有计划文件',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            // 一键导入按钮
            FilledButton.icon(
              onPressed: () => _importDemoData(context),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('📋 加载杨田安暑期计划'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(280, 48),
              ),
            ),
            const SizedBox(height: 12),
            // 手动创建
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPlanScreen()),
                ).then((_) {
                  context.read<PlanProvider>().loadAll();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('手动创建计划'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(280, 48),
              ),
            ),
            const SizedBox(height: 12),
            // 粘贴导入
            OutlinedButton.icon(
              onPressed: () => _showImportDialog(context),
              icon: const Icon(Icons.paste),
              label: const Text('粘贴 JSON 导入'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(280, 44),
              ),
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

  // ==================== 导入功能 ====================

  /// 一键导入杨田安暑期计划
  static void _importDemoData(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        title: Text('正在导入...'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('正在加载杨田安暑期提升计划...'),
          ],
        ),
      ),
    );

    SeedDataService.importSeedData().then((_) {
      if (context.mounted) {
        Navigator.pop(context); // 关闭 loading
        context.read<PlanProvider>().loadAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 杨田安暑期计划已导入！\n6个计划、23个任务'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }).catchError((e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    });
  }

  /// 粘贴 JSON 导入
  static void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.paste, size: 20),
            SizedBox(width: 8),
            Text('粘贴 JSON 导入'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '将 JSON 格式的计划内容粘贴到下方：',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: '{\n  "plans": [...]\n}',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '请粘贴JSON内容' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final result = PlanImporter.parse(
                controller.text.trim(),
                'import.json',
              );
              if (!result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.errorMessage ?? '格式错误')),
                );
                return;
              }
              _executeImport(context, result.plans, result.tasks);
              Navigator.pop(ctx);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 下载示例 JSON
  static void _downloadSample(BuildContext context) {
    final json = PlanImporter.generateSampleJson();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💡 示例已生成。请复制下方内容保存为 .json 文件后导入。'),
        duration: Duration(seconds: 4),
      ),
    );
    // 显示示例内容
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📄 示例 JSON（可复制保存）'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 执行导入
  static void _executeImport(
    BuildContext context,
    List<Map<String, dynamic>> plans,
    List<Map<String, dynamic>> tasks,
  ) {
    final provider = context.read<PlanProvider>();
    final planCount = plans.length;

    provider.batchImportPlans(plans, tasks).then((_) {
      provider.loadAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 成功导入 $planCount 个计划！'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    });
  }
}
