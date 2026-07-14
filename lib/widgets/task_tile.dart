import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete_outline,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // 勾选框
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: task.isCompletedToday
                        ? Colors.green
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: task.isCompletedToday ? Colors.green : Colors.transparent,
                ),
                child: task.isCompletedToday
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // 任务内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: task.isCompletedToday
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompletedToday
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.estimatedMinutes} 分钟',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (task.completedAt != null && task.isCompletedToday) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '已完成',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 拖动指示
              Icon(
                Icons.drag_handle,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
