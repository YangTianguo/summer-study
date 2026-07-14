import 'dart:convert';

/// 学习计划文件导入服务
/// 支持格式：JSON、CSV
class PlanImporter {
  /// 解析导入的文件内容，返回 (plans, tasks) 元组
  static ImportResult parse(String content, String fileName) {
    if (fileName.endsWith('.json')) {
      return _parseJson(content);
    } else if (fileName.endsWith('.csv')) {
      return _parseCsv(content);
    } else {
      // 尝试自动检测
      final trimmed = content.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return _parseJson(content);
      }
      return ImportResult.error('不支持的文件格式。请使用 .json 或 .csv 文件。');
    }
  }

  /// JSON 格式解析
  ///
  /// 文件格式示例：
  /// ```json
  /// {
  ///   "plans": [
  ///     {
  ///       "title": "数学强化",
  ///       "subject": "数学",
  ///       "type": "daily",
  ///       "description": "每天做计算题...",
  ///       "startDate": "2026-07-14",
  ///       "endDate": "2026-08-31",
  ///       "tasks": [
  ///         {"title": "上午数学学习", "estimatedMinutes": 90},
  ///         {"title": "20道计算题", "estimatedMinutes": 20}
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  static ImportResult _parseJson(String content) {
    try {
      final data = jsonDecode(content);
      final Map<String, dynamic> root;

      if (data is List) {
        root = {'plans': data};
      } else if (data is Map<String, dynamic>) {
        root = data;
      } else {
        return ImportResult.error('JSON格式不正确');
      }

      final planList = root['plans'] as List<dynamic>?;
      if (planList == null || planList.isEmpty) {
        return ImportResult.error('未找到计划数据，请确保JSON中包含 "plans" 数组');
      }

      final plans = <Map<String, dynamic>>[];
      final tasks = <Map<String, dynamic>>[];

      for (final p in planList) {
        final planData = p as Map<String, dynamic>;
        final planMap = <String, dynamic>{
          'title': planData['title']?.toString() ?? '未命名计划',
          'description': planData['description']?.toString() ?? '',
          'subject': planData['subject']?.toString() ?? '综合',
          'type': planData['type']?.toString() ?? 'daily',
          'startDate': planData['startDate']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
          'endDate': planData['endDate']?.toString() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
        };
        plans.add(planMap);

        final taskList = planData['tasks'] as List<dynamic>?;
        if (taskList != null) {
          for (int i = 0; i < taskList.length; i++) {
            final t = taskList[i] as Map<String, dynamic>;
            tasks.add({
              'title': t['title']?.toString() ?? '未命名任务',
              'estimatedMinutes': int.tryParse(t['estimatedMinutes']?.toString() ?? '30') ?? 30,
              'subject': t['subject']?.toString() ?? planMap['subject'],
              'sortOrder': i,
            });
          }
        }
      }

      return ImportResult.success(plans: plans, tasks: tasks);
    } catch (e) {
      return ImportResult.error('JSON解析失败：$e');
    }
  }

  /// CSV 格式解析
  ///
  /// 文件格式（逗号分隔）：
  /// ```
  /// 计划名称,学科,类型,开始日期,结束日期,描述
  /// 数学强化,数学,daily,2026-07-14,2026-08-31,每天做计算题
  /// ...
  /// ```
  static ImportResult _parseCsv(String content) {
    try {
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) return ImportResult.error('CSV文件为空');

      // 跳过标题行（如果第一行包含"计划"或"名称"等关键词）
      int startRow = 0;
      final firstLine = lines[0].toLowerCase();
      if (firstLine.contains('计划') || firstLine.contains('名称') || firstLine.contains('title')) {
        startRow = 1;
      }

      if (startRow >= lines.length) {
        return ImportResult.error('CSV文件中没有数据行');
      }

      final plans = <Map<String, dynamic>>[];

      for (int i = startRow; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.isEmpty) continue;

        final title = cols.length > 0 ? cols[0].trim() : '未命名计划';
        final subject = cols.length > 1 ? cols[1].trim() : '综合';
        final type = cols.length > 2 ? cols[2].trim() : 'daily';
        final startDate = cols.length > 3 ? cols[3].trim() : DateTime.now().toIso8601String().split('T')[0];
        final endDate = cols.length > 4 ? cols[4].trim() : DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0];
        final description = cols.length > 5 ? cols[5].trim() : '';

        plans.add({
          'title': title,
          'subject': subject,
          'type': type,
          'startDate': startDate,
          'endDate': endDate,
          'description': description,
        });
      }

      return ImportResult.success(plans: plans, tasks: []);
    } catch (e) {
      return ImportResult.error('CSV解析失败：$e');
    }
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if ((char == ',' || char == '	') && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  /// 生成示例 JSON 文件内容
  static String generateSampleJson() {
    final sample = {
      'plans': [
        {
          'title': '📐 数学强化',
          'subject': '数学',
          'type': 'daily',
          'description': '每天上午和晚上各学习90分钟',
          'startDate': DateTime.now().toIso8601String().split('T')[0],
          'endDate': DateTime.now().add(const Duration(days: 56)).toIso8601String().split('T')[0],
          'tasks': [
            {'title': '上午：数学基础学习（看例题+练习）', 'estimatedMinutes': 90},
            {'title': '20道计算题（限时20分钟）', 'estimatedMinutes': 20},
            {'title': '错题整理', 'estimatedMinutes': 15},
          ],
        },
        {
          'title': '🔤 英语突破',
          'subject': '英语',
          'type': 'daily',
          'description': '每天背15个新词，滚动复习',
          'startDate': DateTime.now().toIso8601String().split('T')[0],
          'endDate': DateTime.now().add(const Duration(days: 56)).toIso8601String().split('T')[0],
          'tasks': [
            {'title': '晨读：大声朗读课文20分钟', 'estimatedMinutes': 20},
            {'title': '背15个新单词', 'estimatedMinutes': 30},
            {'title': '语法学习+造句练习', 'estimatedMinutes': 30},
            {'title': '晚间单词滚动复习', 'estimatedMinutes': 30},
          ],
        },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(sample);
  }
}

class ImportResult {
  final bool success;
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> tasks;
  final String? errorMessage;

  ImportResult._({
    required this.success,
    this.plans = const [],
    this.tasks = const [],
    this.errorMessage,
  });

  factory ImportResult.success({
    required List<Map<String, dynamic>> plans,
    required List<Map<String, dynamic>> tasks,
  }) {
    return ImportResult._(success: true, plans: plans, tasks: tasks);
  }

  factory ImportResult.error(String message) {
    return ImportResult._(success: false, errorMessage: message);
  }
}
