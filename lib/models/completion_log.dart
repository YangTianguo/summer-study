/// 任务完成记录模型
class CompletionLog {
  final String id;
  final String taskId;
  final String planId;
  final DateTime completedDate;
  final DateTime completedAt;

  CompletionLog({
    required this.id,
    required this.taskId,
    required this.planId,
    required this.completedDate,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'planId': planId,
      'completedDate': completedDate.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory CompletionLog.fromMap(Map<String, dynamic> map) {
    return CompletionLog(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      planId: map['planId'] as String,
      completedDate: DateTime.parse(map['completedDate'] as String),
      completedAt: DateTime.parse(map['completedAt'] as String),
    );
  }
}
