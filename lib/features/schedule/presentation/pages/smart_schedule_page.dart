import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/models/study_schedule_item.dart';
import '../../data/repositories/study_schedule_repository.dart';

class SmartSchedulePage extends StatefulWidget {
  const SmartSchedulePage({super.key});

  @override
  State<SmartSchedulePage> createState() => _SmartSchedulePageState();
}

class _SmartSchedulePageState extends State<SmartSchedulePage> {
  final StudyScheduleRepository _repository = StudyScheduleRepository.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: StreamBuilder<List<StudyScheduleItem>>(
          stream: _repository.watchItems(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <StudyScheduleItem>[];

            return ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(AppRoutes.settings);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: GrowMateColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Smart Schedule',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GrowMateLayout.space8),
                Text(
                  'Theo dõi lịch thi và deadline để AI ưu tiên chủ đề cần ôn gấp.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.sectionGap),
                ZenButton(
                  label: 'Thêm mốc học tập',
                  onPressed: _showCreateDialog,
                  trailing: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.contentGap),
                if (items.isEmpty)
                  ZenCard(
                    radius: 18,
                    child: Text(
                      'Chưa có mốc nào. Thêm lịch thi hoặc deadline để GrowMate sắp xếp kế hoạch học thông minh hơn.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  )
                else
                  ...items.map((item) => _buildItemCard(context, item)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, StudyScheduleItem item) {
    final theme = Theme.of(context);
    final dueLocal = item.dueAt.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ZenCard(
        radius: 18,
        color: item.completed
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.65)
            : theme.colorScheme.surfaceContainerLow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.type == 'exam'
                    ? const Color(0xFFFFE8D7)
                    : const Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.type == 'exam'
                    ? Icons.school_rounded
                    : Icons.assignment_rounded,
                size: 18,
                color: GrowMateColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.subject} • ${_formatDate(dueLocal)} • ${_priorityLabel(item.priority)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Checkbox(
                  value: item.completed,
                  onChanged: (value) {
                    _repository.toggleCompleted(
                      id: item.id,
                      value: value ?? false,
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    _repository.deleteItem(item.id);
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController(text: 'Toán');

    var selectedDate = DateTime.now().add(const Duration(days: 2));
    var selectedType = 'deadline';
    var selectedPriority = 2;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm mốc học tập'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên mốc',
                        hintText: 'VD: Thi thử Đạo hàm chương 2',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: 'Môn học'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Loại mốc'),
                      items: const [
                        DropdownMenuItem(value: 'exam', child: Text('Bài thi')),
                        DropdownMenuItem(
                          value: 'deadline',
                          child: Text('Deadline'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Ưu tiên'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Cao')),
                        DropdownMenuItem(value: 2, child: Text('Trung bình')),
                        DropdownMenuItem(value: 3, child: Text('Thấp')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày đến hạn'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: IconButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );

                          if (picked == null) {
                            return;
                          }

                          setDialogState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              8,
                              0,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_today_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) {
      titleController.dispose();
      subjectController.dispose();
      return;
    }

    await _repository.upsertItem(
      title: titleController.text.trim(),
      subject: subjectController.text.trim(),
      dueAt: selectedDate,
      type: selectedType,
      priority: selectedPriority,
    );

    titleController.dispose();
    subjectController.dispose();
  }

  static String _formatDate(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} • $hour:$minute';
  }

  static String _priorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Ưu tiên cao';
      case 2:
        return 'Ưu tiên vừa';
      default:
        return 'Ưu tiên thấp';
    }
  }
}
