import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan.dart';
import '../models/task.dart';
import '../models/completion_log.dart';

/// 跨平台 JSON 存储服务（Web + Android + iOS 通用）
/// 使用 shared_preferences 存储序列化 JSON，替代 SQLite
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _keyPlans = 'storage_plans';
  static const _keyTasks = 'storage_tasks';
  static const _keyLogs = 'storage_completion_logs';

  // ==================== 底层读写 ====================

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _prefs;
    final json = prefs.getString(key);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(list));
  }

  // ==================== Plan CRUD ====================

  Future<List<Plan>> getPlans({bool activeOnly = false}) async {
    final maps = await _readList(_keyPlans);
    final plans = maps.map((m) => Plan.fromMap(m)).toList();
    if (activeOnly) {
      return plans.where((p) => p.isActive).toList();
    }
    // 按创建时间倒序
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plans;
  }

  Future<Plan?> getPlan(String id) async {
    final maps = await _readList(_keyPlans);
    final match = maps.cast<Map<String, dynamic>?>().firstWhere(
          (m) => m?['id'] == id,
          orElse: () => null,
        );
    return match != null ? Plan.fromMap(match) : null;
  }

  Future<void> insertPlan(Plan plan) async {
    final maps = await _readList(_keyPlans);
    maps.add(plan.toMap());
    await _writeList(_keyPlans, maps);
  }

  Future<void> updatePlan(Plan plan) async {
    final maps = await _readList(_keyPlans);
    final index = maps.indexWhere((m) => m['id'] == plan.id);
    if (index >= 0) {
      maps[index] = plan.toMap();
      await _writeList(_keyPlans, maps);
    }
  }

  Future<void> deletePlan(String id) async {
    // 删除计划和关联的任务和日志
    var maps = await _readList(_keyPlans);
    maps.removeWhere((m) => m['id'] == id);
    await _writeList(_keyPlans, maps);

    var tasks = await _readList(_keyTasks);
    final taskIds = tasks.where((t) => t['planId'] == id).map((t) => t['id']).toSet();
    tasks.removeWhere((t) => t['planId'] == id);
    await _writeList(_keyTasks, tasks);

    var logs = await _readList(_keyLogs);
    logs.removeWhere((l) => l['planId'] == id || taskIds.contains(l['taskId']));
    await _writeList(_keyLogs, logs);
  }

  Future<List<Plan>> getTodayPlans() async {
    final plans = await getPlans(activeOnly: true);
    final today = DateTime.now();
    return plans.where((p) => p.isActiveOnDate(today)).toList();
  }

  // ==================== Task CRUD ====================

  Future<List<Task>> getTasksByPlan(String planId) async {
    final maps = await _readList(_keyTasks);
    final tasks = maps
        .where((m) => m['planId'] == planId)
        .map((m) => Task.fromMap(m))
        .toList();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tasks;
  }

  Future<Task?> getTask(String id) async {
    final maps = await _readList(_keyTasks);
    final match = maps.cast<Map<String, dynamic>?>().firstWhere(
          (m) => m?['id'] == id,
          orElse: () => null,
        );
    return match != null ? Task.fromMap(match) : null;
  }

  Future<void> insertTask(Task task) async {
    final maps = await _readList(_keyTasks);
    maps.add(task.toMap());
    await _writeList(_keyTasks, maps);
  }

  Future<void> updateTask(Task task) async {
    final maps = await _readList(_keyTasks);
    final index = maps.indexWhere((m) => m['id'] == task.id);
    if (index >= 0) {
      maps[index] = task.toMap();
      await _writeList(_keyTasks, maps);
    }
  }

  Future<void> deleteTask(String id) async {
    var maps = await _readList(_keyTasks);
    maps.removeWhere((m) => m['id'] == id);
    await _writeList(_keyTasks, maps);

    // 同时删除关联日志
    var logs = await _readList(_keyLogs);
    logs.removeWhere((l) => l['taskId'] == id);
    await _writeList(_keyLogs, logs);
  }

  Future<void> resetDailyTasks(String planId) async {
    final maps = await _readList(_keyTasks);
    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['planId'] == planId) {
        maps[i]['isCompletedToday'] = 0;
        maps[i]['completedAt'] = null;
      }
    }
    await _writeList(_keyTasks, maps);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final now = DateTime.now();
    final newStatus = task.isCompletedToday ? 0 : 1;
    final completedAt = newStatus == 1 ? now.toIso8601String() : null;

    // 更新任务
    final taskMaps = await _readList(_keyTasks);
    final taskIndex = taskMaps.indexWhere((m) => m['id'] == task.id);
    if (taskIndex >= 0) {
      taskMaps[taskIndex]['isCompletedToday'] = newStatus;
      taskMaps[taskIndex]['completedAt'] = completedAt;
      await _writeList(_keyTasks, taskMaps);
    }

    // 记录/删除完成日志
    final logMaps = await _readList(_keyLogs);
    final dateStr = DateTime(now.year, now.month, now.day).toIso8601String();
    final logId = '${task.id}_${dateStr.split('T')[0]}';

    if (newStatus == 1) {
      // 添加日志（避免重复）
      if (!logMaps.any((l) => l['id'] == logId)) {
        logMaps.add(CompletionLog(
          id: logId,
          taskId: task.id,
          planId: task.planId,
          completedDate: DateTime(now.year, now.month, now.day),
          completedAt: now,
        ).toMap());
        await _writeList(_keyLogs, logMaps);
      }
    } else {
      logMaps.removeWhere((l) => l['id'] == logId);
      await _writeList(_keyLogs, logMaps);
    }
  }

  // ==================== CompletionLog ====================

  Future<List<CompletionLog>> getCompletionLogsByDate(DateTime date) async {
    final maps = await _readList(_keyLogs);
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    return maps
        .where((m) => m['completedDate'] == dateStr)
        .map((m) => CompletionLog.fromMap(m))
        .toList();
  }

  Future<Map<String, int>> getCompletionCountByDateRange(
      DateTime start, DateTime end) async {
    final maps = await _readList(_keyLogs);
    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day).toIso8601String();

    final result = <String, int>{};
    for (final map in maps) {
      final date = map['completedDate'] as String?;
      if (date != null && date.compareTo(startStr) >= 0 && date.compareTo(endStr) <= 0) {
        result[date] = (result[date] ?? 0) + 1;
      }
    }
    return result;
  }

  Future<double> getDailyCompletionRate(DateTime date) async {
    final todayPlans = await getTodayPlans();
    if (todayPlans.isEmpty) return 1.0;

    int totalTasks = 0;
    int completedTasks = 0;
    final dateStr =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final logs = await _readList(_keyLogs);

    for (final plan in todayPlans) {
      final tasks = await getTasksByPlan(plan.id);
      totalTasks += tasks.length;
      for (final task in tasks) {
        if (logs.any((l) => l['taskId'] == task.id && l['completedDate'] == dateStr)) {
          completedTasks++;
        }
      }
    }

    return totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  }

  Future<Map<String, dynamic>> getStats() async {
    final plans = await _readList(_keyPlans);
    final tasks = await _readList(_keyTasks);
    final logs = await _readList(_keyLogs);

    final activePlanCount = plans.where((p) => p['isActive'] == 1).length;

    // 连续打卡天数
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final hasLog = logs.any((l) => l['completedDate'] == dateStr);
      if (hasLog) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return {
      'planCount': plans.length,
      'activePlanCount': activePlanCount,
      'taskCount': tasks.length,
      'totalCompletions': logs.length,
      'streakDays': streak,
    };
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_keyPlans);
    await prefs.remove(_keyTasks);
    await prefs.remove(_keyLogs);
  }
}
