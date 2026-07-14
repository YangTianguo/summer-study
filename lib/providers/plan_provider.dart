import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/storage_service.dart';
import '../models/plan.dart';
import '../models/task.dart';

class PlanProvider extends ChangeNotifier {
  final StorageService _store = StorageService();
  final Uuid _uuid = const Uuid();

  List<Plan> _plans = [];
  List<Plan> _todayPlans = [];
  Map<String, List<Task>> _planTasks = {}; // planId -> tasks
  bool _isLoading = false;
  double _todayCompletionRate = 0.0;
  Map<String, dynamic> _stats = {};

  List<Plan> get plans => _plans;
  List<Plan> get todayPlans => _todayPlans;
  bool get isLoading => _isLoading;
  double get todayCompletionRate => _todayCompletionRate;
  Map<String, dynamic> get stats => _stats;

  int get todayTotalTasks {
    int count = 0;
    for (final tasks in _planTasks.values) {
      count += tasks.length;
    }
    return count;
  }

  int get todayCompletedTasks {
    int count = 0;
    for (final tasks in _planTasks.values) {
      count += tasks.where((t) => t.isCompletedToday).length;
    }
    return count;
  }

  /// 获取指定计划的任务列表
  List<Task> getTasksForPlan(String planId) {
    return _planTasks[planId] ?? [];
  }

  /// 加载所有数据
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _plans = await _store.getPlans();
      _todayPlans = await _store.getTodayPlans();
      _stats = await _store.getStats();

      // 加载每个今日计划的任务
      _planTasks = {};
      for (final plan in _todayPlans) {
        _planTasks[plan.id] = await _store.getTasksByPlan(plan.id);
      }

      // 计算今日完成率
      final today = DateTime.now();
      _todayCompletionRate = await _store.getDailyCompletionRate(today);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建计划
  Future<Plan> createPlan({
    required String title,
    String description = '',
    String type = 'daily',
    String subject = '综合',
    required DateTime startDate,
    required DateTime endDate,
    List<Map<String, dynamic>>? tasks,
  }) async {
    final now = DateTime.now();
    final plan = Plan(
      id: _uuid.v4(),
      title: title,
      description: description,
      type: type,
      subject: subject,
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
    );

    await _store.insertPlan(plan);

    // 创建关联的任务
    if (tasks != null && tasks.isNotEmpty) {
      for (int i = 0; i < tasks.length; i++) {
        final taskData = tasks[i];
        final task = Task(
          id: _uuid.v4(),
          planId: plan.id,
          title: taskData['title'] as String,
          subject: (taskData['subject'] as String?) ?? subject,
          estimatedMinutes: (taskData['estimatedMinutes'] as int?) ?? 30,
          sortOrder: i,
          createdAt: now,
        );
        await _store.insertTask(task);
      }
    }

    await loadAll();
    return plan;
  }

  /// 更新计划
  Future<void> updatePlan(Plan plan) async {
    await _store.updatePlan(plan);
    await loadAll();
  }

  /// 删除计划
  Future<void> deletePlan(String id) async {
    await _store.deletePlan(id);
    await loadAll();
  }

  /// 为计划添加任务
  Future<Task> addTaskToPlan({
    required String planId,
    required String title,
    String subject = '综合',
    int estimatedMinutes = 30,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      planId: planId,
      title: title,
      subject: subject,
      estimatedMinutes: estimatedMinutes,
      sortOrder: (_planTasks[planId]?.length ?? 0),
      createdAt: DateTime.now(),
    );
    await _store.insertTask(task);

    // 更新缓存
    final tasks = _planTasks[planId] ?? [];
    tasks.add(task);
    _planTasks[planId] = tasks;

    notifyListeners();
    return task;
  }

  /// 删除任务
  Future<void> deleteTask(String taskId, String planId) async {
    await _store.deleteTask(taskId);
    _planTasks[planId]?.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  /// 切换任务完成状态
  Future<void> toggleTask(Task task) async {
    await _store.toggleTaskCompletion(task);

    // 更新缓存中的任务状态
    final tasks = _planTasks[task.planId];
    if (tasks != null) {
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        tasks[index] = task.copyWith(
          isCompletedToday: !task.isCompletedToday,
          completedAt: !task.isCompletedToday ? DateTime.now() : null,
        );
        _planTasks[task.planId] = tasks;
      }
    }

    // 更新完成率
    final today = DateTime.now();
    _todayCompletionRate = await _store.getDailyCompletionRate(today);
    _stats = await _store.getStats();

    notifyListeners();
  }

  /// 展开/加载指定计划的任务（用于查看非今日计划的任务）
  Future<void> loadTasksForPlan(String planId) async {
    if (!_planTasks.containsKey(planId)) {
      final tasks = await _store.getTasksByPlan(planId);
      _planTasks[planId] = tasks;
      notifyListeners();
    }
  }
}
