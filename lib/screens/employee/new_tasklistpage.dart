import 'package:e_management/color.dart';
import 'package:e_management/screens/employee/taskDetails.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:table_calendar/table_calendar.dart';

// ===== MODELS =====

enum TaskStatus { pending, inProgress, done }

enum TaskFilter { all, pending, inProgress, done }

class Task {
  final String title;
  final String timeText;
  final DateTime date;
  final List<_ChipData> tags;
  TaskStatus status;
  Task({
    required this.title,
    required this.timeText,
    required this.date,
    required this.tags,
    this.status = TaskStatus.pending,
  });
}

class _ChipData {
  final String label;
  final Color bg;
  final Color fg;
  const _ChipData({required this.label, required this.bg, required this.fg});
}

// ===== HOME SCREEN =====

class TasksHomeScreen extends StatefulWidget {
  const TasksHomeScreen({super.key});
  @override
  State<TasksHomeScreen> createState() => _TasksHomeScreenState();
}

class _TasksHomeScreenState extends State<TasksHomeScreen> {
  DateTime _focusedDay = DateTime(2025, 8, 14);
  DateTime? _selectedDay = DateTime(2025, 8, 14);
  TaskFilter _filter = TaskFilter.all;

  final List<Task> _all = [
    Task(
      title: 'Finalize project report',
      timeText: '10:00 AM - 11:00 AM',
      date: DateTime(2025, 8, 14),
      status: TaskStatus.inProgress,
      tags: const [
        _ChipData(label: 'Work', bg: Color(0xFFE8F0FF), fg: Color(0xFF2F5AF3)),
        _ChipData(
            label: 'Urgent', bg: Color(0xFFFFE8E8), fg: Color(0xFFE84D4D)),
      ],
    ),
    Task(
      title: "Doctor's Appointment",
      timeText: '1:00 PM',
      date: DateTime(2025, 8, 14),
      status: TaskStatus.pending,
      tags: const [
        _ChipData(
            label: 'Personal', bg: Color(0xFFE9F7EE), fg: Color(0xFF1EB980)),
      ],
    ),
    Task(
      title: 'Read chapter 4 of Physics book',
      timeText: '3:00 PM - 4:00 PM',
      date: DateTime(2025, 8, 14),
      status: TaskStatus.done,
      tags: const [
        _ChipData(label: 'Study', bg: Color(0xFFFEF2D7), fg: Color(0xFFD29B2C)),
      ],
    ),
    Task(
      title: 'Team Stand-up meeting',
      timeText: '4:30 PM',
      date: DateTime(2025, 8, 14),
      status: TaskStatus.pending,
      tags: const [
        _ChipData(label: 'Work', bg: Color(0xFFE8F0FF), fg: Color(0xFF2F5AF3)),
      ],
    ),
  ];

  List<Task> get _tasksForSelectedDay {
    final sameDay = (Task t) => isSameDay(t.date, _selectedDay);
    final byFilter = (Task t) {
      switch (_filter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.pending:
          return t.status == TaskStatus.pending ||
              t.status == TaskStatus.inProgress;
        case TaskFilter.inProgress:
          return t.status == TaskStatus.inProgress;
        case TaskFilter.done:
          return t.status == TaskStatus.done;
      }
    };
    return _all.where((t) => sameDay(t) && byFilter(t)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.menu_rounded,
                    onTap: () {},
                  ),
                  const Spacer(),
                  Text("Today's Tasks",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.search_rounded,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calendar (TableCalendar)
              _CalendarTable(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onPrev: () => setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                }),
                onNext: () => setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                }),
                onDaySelected: (day) => setState(() {
                  _selectedDay = day;
                  _focusedDay = day;
                }),
                onPageChanged: (f) => setState(() => _focusedDay = f),
              ),
              const SizedBox(height: 16),

              // Segmented control with filter logic
              _StatusSegmented(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 24),

              // Tasks list for selected day
              Column(
                children: [
                  for (int i = 0; i < _tasksForSelectedDay.length; i++) ...[
                    _TaskCard(
                      title: _tasksForSelectedDay[i].title,
                      timeText: _tasksForSelectedDay[i].timeText,
                      tags: _tasksForSelectedDay[i].tags,
                      done: _tasksForSelectedDay[i].status == TaskStatus.done,
                      onToggle: () => setState(() {
                        final t = _tasksForSelectedDay[i];
                        t.status = t.status == TaskStatus.done
                            ? TaskStatus.pending
                            : TaskStatus.done;
                      }),
                    ),
                    if (i != _tasksForSelectedDay.length - 1)
                      const SizedBox(height: 12),
                  ]
                ],
              ),
              const SizedBox(height: 24),

              // Add Task button
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {},
          icon: const Icon(
            Icons.add_rounded,
            color: Colors.white,
          ),
          label: const Text(
            'Add Task',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ===== WIDGETS =====
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.circleButtonBg,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: AppColors.circleButtonShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.circleButtonIcon),
      ),
    );
  }
}

class _HeaderChevron extends StatelessWidget {
  final bool isLeft;
  final VoidCallback onTap;
  const _HeaderChevron({required this.isLeft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.headerChevronBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.headerChevronShadow,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          isLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.headerChevronIcon,
        ),
      ),
    );
  }
}

class _CalendarTable extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime>? onPageChanged;

  const _CalendarTable({
    required this.focusedDay,
    required this.selectedDay,
    required this.onPrev,
    required this.onNext,
    required this.onDaySelected,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String label =
        _monthName(focusedDay.month) + ' ' + focusedDay.year.toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderChevron(onTap: onPrev, isLeft: true),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              _HeaderChevron(onTap: onNext, isLeft: false),
            ],
          ),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: focusedDay,
            headerVisible: false,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (sel, foc) => onDaySelected(sel),
            onPageChanged: (f) => onPageChanged?.call(f),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              weekendTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              outsideTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.outlineVariant,
              ),
              disabledTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.outlineVariant,
              ),
              selectedDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              selectedTextStyle: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
              ),
              todayDecoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.secondary,
              ),
              cellMargin:
                  const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              rowDecoration: const BoxDecoration(),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[m - 1];
  }
}

class _StatusSegmented extends StatelessWidget {
  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  const _StatusSegmented({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.segmentedBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _SegmentItem(
            label: 'All',
            selected: selected == TaskFilter.all,
            onTap: () => onChanged(TaskFilter.all),
          ),
          _SegmentItem(
            label: 'Pending',
            selected: selected == TaskFilter.pending,
            onTap: () => onChanged(TaskFilter.pending),
          ),
          _SegmentItem(
            label: 'In Progress',
            selected: selected == TaskFilter.inProgress,
            onTap: () => onChanged(TaskFilter.inProgress),
          ),
          _SegmentItem(
            label: 'Done',
            selected: selected == TaskFilter.done,
            onTap: () => onChanged(TaskFilter.done),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.label,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final base = Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );

    if (!selected) return base;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String timeText;
  final List<_ChipData> tags;
  final bool done;
  final VoidCallback? onToggle;

  const _TaskCard({
    required this.title,
    required this.timeText,
    required this.tags,
    required this.done,
    this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Get.to(() => TaskDetailsPage());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CheckBox(checked: done, onTap: onToggle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: done ? cs.onSurfaceVariant : cs.onSurface,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: done
                          ? cs.onSurfaceVariant.withOpacity(0.7)
                          : cs.onSurfaceVariant,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final c in tags) _TaskChip(data: c),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _KebabButton(onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  final _ChipData data;
  const _TaskChip({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.bg ?? cs.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: data.fg ?? cs.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;
  const _CheckBox({required this.checked, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final child = checked
        ? Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.check_rounded, color: cs.onPrimary, size: 16),
          )
        : Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey, width: 2),
              color: cs.surfaceVariant, // softer than surface
            ),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: child,
    );
  }
}

class _KebabButton extends StatelessWidget {
  final VoidCallback onTap;
  const _KebabButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: cs.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
