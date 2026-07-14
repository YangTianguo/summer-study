import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/plan_provider.dart';
import '../models/plan.dart';

class AddPlanScreen extends StatefulWidget {
  final Plan? existingPlan; // 编辑模式时传入

  const AddPlanScreen({super.key, this.existingPlan});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedSubject = '数学';
  String _selectedType = 'daily';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // 任务列表（创建时一次性添加）
  final List<_TaskEntry> _taskEntries = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final plan = widget.existingPlan!;
      _titleController.text = plan.title;
      _descriptionController.text = plan.description;
      _selectedSubject = plan.subject;
      _selectedType = plan.type;
      _startDate = plan.startDate;
      _endDate = plan.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final entry in _taskEntries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑计划' : '新建学习计划'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePlan,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 计划名称
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '计划名称 *',
                hintText: '例如：暑假数学冲刺',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入计划名称' : null,
            ),
            const SizedBox(height: 16),

            // 学科选择
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(
                labelText: '学科',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: Plan.subjects.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedSubject = v);
              },
            ),
            const SizedBox(height: 16),

            // 计划类型
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: '计划类型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: Plan.types.map((t) {
                String label;
                switch (t) {
                  case 'daily':
                    label = '每日计划';
                    break;
                  case 'weekly':
                    label = '每周计划';
                    break;
                  case 'custom':
                    label = '自定义';
                    break;
                  default:
                    label = t;
                }
                return DropdownMenuItem(value: t, child: Text(label));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            const SizedBox(height: 16),

            // 日期范围
            Row(
              children: [
                Expanded(
                  child: _DatePickerTile(
                    label: '开始日期',
                    date: _startDate,
                    onChanged: (d) => setState(() {
                      _startDate = d;
                      if (_endDate.isBefore(d)) _endDate = d;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerTile(
                    label: '结束日期',
                    date: _endDate,
                    onChanged: (d) => setState(() {
                      _endDate = d;
                    }),
                    firstDate: _startDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 描述
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '计划描述（可选）',
                hintText: '简单描述一下这个计划的目标...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // 任务列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '任务列表',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addTaskEntry,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加任务'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_taskEntries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      _isEditing
                          ? '编辑模式下请在计划详情页添加任务'
                          : '还没有添加任务，点击上方按钮添加',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

            ..._taskEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final taskEntry = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: taskEntry.controller,
                          decoration: InputDecoration(
                            hintText: '任务 ${index + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixText: '${taskEntry.minutes}分钟',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? '请输入任务名' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            taskEntry.controller.dispose();
                            _taskEntries.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _addTaskEntry() {
    setState(() {
      _taskEntries.add(_TaskEntry(
        controller: TextEditingController(),
        minutes: 30,
      ));
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<PlanProvider>();

      if (_isEditing) {
        // 更新现有计划
        final updated = widget.existingPlan!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          subject: _selectedSubject,
          startDate: _startDate,
          endDate: _endDate,
        );
        await provider.updatePlan(updated);
      } else {
        // 创建新计划
        final tasks = _taskEntries
            .where((e) => e.controller.text.trim().isNotEmpty)
            .map((e) => {
                  'title': e.controller.text.trim(),
                  'estimatedMinutes': e.minutes,
                  'subject': _selectedSubject,
                })
            .toList();

        await provider.createPlan(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          subject: _selectedSubject,
          startDate: _startDate,
          endDate: _endDate,
          tasks: tasks.isNotEmpty ? tasks : null,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _TaskEntry {
  final TextEditingController controller;
  final int minutes;

  _TaskEntry({required this.controller, required this.minutes});
}

/// 日期选择组件
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onChanged,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          DateFormat('yyyy/MM/dd').format(date),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
