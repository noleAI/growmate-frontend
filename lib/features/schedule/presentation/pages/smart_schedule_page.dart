import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/models/feature_availability.dart';
import '../../../../shared/widgets/feature_availability_banner.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/models/study_schedule_item.dart';
import '../../data/repositories/study_schedule_repository.dart';
import '../../services/google_calendar_service.dart';

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
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.t(vi: 'Lịch thông minh', en: 'Smart Schedule'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GrowMateLayout.space8),
                Text(
                  context.t(
                    vi: 'Theo dõi lịch thi và hạn nộp để AI ưu tiên chủ đề cần ôn gấp.',
                    en: 'Track exams and deadlines so AI can prioritize urgent topics.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                FeatureAvailabilityBanner(
                  availability: FeatureAvailability.beta,
                  message: context.t(
                    vi: 'Smart Schedule hien dang la local beta va deep-link Google Calendar, chua co backend scheduling service.',
                    en: 'Smart Schedule is currently a local beta with Google Calendar deep-links, not a backend scheduling service yet.',
                  ),
                ),
                const SizedBox(height: GrowMateLayout.sectionGap),
                ZenButton(
                  label: context.t(
                    vi: 'Thêm mốc học tập',
                    en: 'Add study milestone',
                  ),
                  onPressed: _showCreateDialog,
                  trailing: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.contentGap),
                if (items.isEmpty)
                  Column(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: GrowMateLayout.space12),
                      ZenCard(
                        child: Text(
                          context.t(
                            vi: 'Chưa có mốc nào. Thêm lịch thi hoặc hạn nộp để GrowMate sắp xếp kế hoạch học thông minh hơn.',
                            en: 'No milestones yet. Add an exam or deadline so GrowMate can build a smarter study plan.',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
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
        radius: GrowMateLayout.cardRadius,
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
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.type == 'exam'
                    ? Icons.school_rounded
                    : Icons.assignment_rounded,
                size: 18,
                color: theme.colorScheme.primary,
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
                    '${item.subject} • ${_formatDate(dueLocal)} • ${_priorityLabel(context, item.priority)}',
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
                  tooltip: context.t(
                    vi: 'Thêm vào Google Calendar',
                    en: 'Add to Google Calendar',
                  ),
                  onPressed: () {
                    _openGoogleCalendarDraft(context, item);
                  },
                  icon: Icon(
                    Icons.event_available_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, item),
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

  Future<void> _confirmDelete(
    BuildContext context,
    StudyScheduleItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.t(vi: 'Xóa mốc?', en: 'Delete milestone?')),
        content: Text(
          context.t(
            vi: 'Bạn có chắc muốn xóa "${item.title}"? Hành động này không thể hoàn tác.',
            en: 'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              context.t(vi: 'Hủy', en: 'Cancel'),
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(context.t(vi: 'Xóa', en: 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _repository.deleteItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                vi: 'Đã xóa mốc "${item.title}"',
                en: 'Deleted "${item.title}"',
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final parentContext = context;
    final titleController = TextEditingController();
    final subjectController = TextEditingController(text: 'Toán');

    var selectedDate = DateTime.now().add(const Duration(days: 2));
    var selectedType = 'deadline';
    var selectedPriority = 2;
    var createGoogleEvent = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                context.t(vi: 'Thêm mốc học tập', en: 'Add study milestone'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(vi: 'Tên mốc', en: 'Milestone name'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: context.t(
                          vi: 'VD: Thi thử Đạo hàm chương 2',
                          en: 'e.g. Derivatives mock test - chapter 2',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.t(vi: 'Môn học', en: 'Subject'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        hintText: context.t(vi: 'Toán', en: 'Math'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.t(vi: 'Loại mốc', en: 'Milestone type'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        hintText: context.t(
                          vi: 'Chọn loại mốc',
                          en: 'Choose type',
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'exam',
                          child: Text(context.t(vi: 'Bài thi', en: 'Exam')),
                        ),
                        DropdownMenuItem(
                          value: 'deadline',
                          child: Text(context.t(vi: 'Hạn nộp', en: 'Deadline')),
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
                    Text(
                      context.t(vi: 'Ưu tiên', en: 'Priority'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedPriority,
                      decoration: InputDecoration(
                        hintText: context.t(
                          vi: 'Chọn mức ưu tiên',
                          en: 'Choose priority',
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(context.t(vi: 'Cao', en: 'High')),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            context.t(vi: 'Trung bình', en: 'Medium'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(context.t(vi: 'Thấp', en: 'Low')),
                        ),
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
                      title: Text(
                        context.t(vi: 'Ngày đến hạn', en: 'Due date'),
                      ),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: context.t(
                              vi: 'Chọn ngày',
                              en: 'Pick date',
                            ),
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
                                  selectedDate.hour,
                                  selectedDate.minute,
                                );
                              });
                            },
                            icon: const Icon(Icons.calendar_today_rounded),
                          ),
                          IconButton(
                            tooltip: context.t(vi: 'Chọn giờ', en: 'Pick time'),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(
                                  selectedDate,
                                ),
                              );

                              if (picked == null) {
                                return;
                              }

                              setDialogState(() {
                                selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            },
                            icon: const Icon(Icons.schedule_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      value: createGoogleEvent,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        context.t(
                          vi: 'Tạo sự kiện trên Google Calendar',
                          en: 'Create Google Calendar event',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          createGoogleEvent = value ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: Text(context.t(vi: 'Hủy', en: 'Cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(context.t(vi: 'Lưu', en: 'Save')),
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

    if (!mounted || !parentContext.mounted) {
      titleController.dispose();
      subjectController.dispose();
      return;
    }

    if (createGoogleEvent) {
      final eventDetails = parentContext.t(
        vi: 'Môn học: ${subjectController.text.trim()}\nLoại mốc: ${_typeLabel(parentContext, selectedType)}\nƯu tiên: ${_priorityLabel(parentContext, selectedPriority)}',
        en: 'Subject: ${subjectController.text.trim()}\nType: ${_typeLabel(parentContext, selectedType)}\nPriority: ${_priorityLabel(parentContext, selectedPriority)}',
      );
      final opened = await GoogleCalendarService.openCreateEvent(
        title: titleController.text.trim(),
        start: selectedDate,
        end: selectedDate.add(const Duration(hours: 1)),
        details: eventDetails,
      );

      if (!mounted || !parentContext.mounted) {
        titleController.dispose();
        subjectController.dispose();
        return;
      }

      ScaffoldMessenger.of(parentContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              opened
                  ? parentContext.t(
                      vi: 'Đã mở Google Calendar để tạo sự kiện.',
                      en: 'Opened Google Calendar event draft.',
                    )
                  : parentContext.t(
                      vi: 'Không mở được Google Calendar lúc này.',
                      en: 'Could not open Google Calendar right now.',
                    ),
            ),
          ),
        );
    }

    titleController.dispose();
    subjectController.dispose();
  }

  Future<void> _openGoogleCalendarDraft(
    BuildContext context,
    StudyScheduleItem item,
  ) async {
    final details = context.t(
      vi: 'Môn học: ${item.subject}\nLoại mốc: ${_typeLabel(context, item.type)}\nƯu tiên: ${_priorityLabel(context, item.priority)}',
      en: 'Subject: ${item.subject}\nType: ${_typeLabel(context, item.type)}\nPriority: ${_priorityLabel(context, item.priority)}',
    );
    final successMessage = context.t(
      vi: 'Đã mở Google Calendar để tạo sự kiện.',
      en: 'Opened Google Calendar event draft.',
    );
    final failureMessage = context.t(
      vi: 'Không mở được Google Calendar lúc này.',
      en: 'Could not open Google Calendar right now.',
    );

    final opened = await GoogleCalendarService.openCreateEvent(
      title: item.title,
      start: item.dueAt.toLocal(),
      end: item.dueAt.toLocal().add(const Duration(hours: 1)),
      details: details,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(opened ? successMessage : failureMessage)),
      );
  }

  static String _formatDate(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} • $hour:$minute';
  }

  String _priorityLabel(BuildContext context, int priority) {
    switch (priority) {
      case 1:
        return context.t(vi: 'Ưu tiên cao', en: 'High priority');
      case 2:
        return context.t(vi: 'Ưu tiên vừa', en: 'Medium priority');
      default:
        return context.t(vi: 'Ưu tiên thấp', en: 'Low priority');
    }
  }

  String _typeLabel(BuildContext context, String type) {
    if (type == 'exam') {
      return context.t(vi: 'Bài thi', en: 'Exam');
    }
    return context.t(vi: 'Hạn nộp', en: 'Deadline');
  }
}
