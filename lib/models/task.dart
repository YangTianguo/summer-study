/// 学习任务模型
class Task {
  final String id;
  final String planId;
  final String title;
  final String subject;
  final int estimatedMinutes;
  final bool isCompletedToday;
  final DateTime? completedAt;
  final int sortOrder;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.planId,
    required this.title,
    this.subject = '综合',
    this.estimatedMinutes = 30,
    this.isCompletedToday = false,
    this.completedAt,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'title': title,
      'subject': subject,
      'estimatedMinutes': estimatedMinutes,
      'isCompletedToday': isCompletedToday ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      planId: map['planId'] as String,
      title: map['title'] as String,
      subject: (map['subject'] as String?) ?? '综合',
      estimatedMinutes: (map['estimatedMinutes'] as int?) ?? 30,
      isCompletedToday: (map['isCompletedToday'] as int?) == 1,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      sortOrder: (map['sortOrder'] as int?) ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Task copyWith({
    String? id,
    String? planId,
    String? title,
    String? subject,
    int? estimatedMinutes,
    bool? isCompletedToday,
    DateTime? completedAt,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
