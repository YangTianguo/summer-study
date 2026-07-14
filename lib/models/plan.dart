/// 学习计划模型
class Plan {
  final String id;
  final String title;
  final String description;
  final String type; // daily, weekly, custom
  final String subject; // 数学, 英语, 语文, 综合, 自定义
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final bool isActive;

  Plan({
    required this.id,
    required this.title,
    this.description = '',
    this.type = 'daily',
    this.subject = '综合',
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'subject': subject,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'daily',
      subject: (map['subject'] as String?) ?? '综合',
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: (map['isActive'] as int?) == 1,
    );
  }

  Plan copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? subject,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 判断计划是否在今天的时间范围内
  bool isActiveOnDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return isActive && (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  static const List<String> subjects = ['数学', '英语', '语文', '综合', '自定义'];
  static const List<String> types = ['daily', 'weekly', 'custom'];

  String get typeLabel {
    switch (type) {
      case 'daily':
        return '每日计划';
      case 'weekly':
        return '每周计划';
      case 'custom':
        return '自定义';
      default:
        return type;
    }
  }
}
