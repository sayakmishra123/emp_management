import 'package:flutter/material.dart';

class NewEmployeeDashboard extends StatelessWidget {
  const NewEmployeeDashboard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const _TopBar(),
            const SizedBox(height: 18),
            Text('Welcome back, Bro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
            const SizedBox(height: 18),

            // Quick Actions
            const _SectionTitle('Quick Actions'),
            const SizedBox(height: 10),
            const QuickActionButton.primary(label: 'Request Leave'),

            const SizedBox(height: 10),
            const QuickActionButton.secondary(label: 'Update Profile'),
            const SizedBox(height: 18),

            // Attendance
            const _SectionTitle('Attendance'),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: InfoCard(title: 'Login Time', big: '9:00 AM')),
                SizedBox(width: 12),
                Expanded(child: InfoCard(title: 'Present Days', big: '15')),
              ],
            ),
            const SizedBox(height: 12),
            const InfoCard(title: 'Total Hours', big: '120', fullWidth: true),
            const SizedBox(height: 18),

            // Tasks
            const _SectionTitle('Today Tasks'),
            const SizedBox(height: 8),
            const TaskTile(
              title: 'Complete project report',
              metaLabel: 'Due:',
              metaValue: 'Aug 15',
              icon: Icons.checklist_rtl,
            ),
            const SizedBox(height: 8),
            const TaskTile(
              title: 'Prepare presentation',
              metaLabel: 'Due:',
              metaValue: 'Aug 20',
              icon: Icons.checklist_rtl,
            ),
            const SizedBox(height: 18),

            // Recent Activity
            const _SectionTitle('Recent Activity'),
            const SizedBox(height: 8),
            const ActivityTile(
              icon: Icons.calendar_month,
              title: 'Timesheet for week of July 10',
              subtitle: 'Submitted 2 days ago',
            ),
            const SizedBox(height: 8),
            const ActivityTile(
              icon: Icons.event_available,
              title: 'Leave request for July 20-22',
              subtitle: 'Approved',
              chipColor: Color(0xFF16A34A),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: const AssetImage('assets/avatar_placeholder.png'),
          backgroundColor: cs.surfaceVariant, // adapts to theme
        ),
        const Spacer(),
        Text(
          'Home',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: cs.onBackground, // adapts to theme
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surfaceVariant, // adapts to theme
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: cs.onSurface, // adapts to theme
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: cs.onBackground, // adapts to theme
        ),
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String label;
  final bool primary;

  const QuickActionButton.primary({super.key, required this.label})
      : primary = true;
  const QuickActionButton.secondary({super.key, required this.label})
      : primary = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = primary ? cs.primary : cs.secondaryContainer;
    final fg = primary ? cs.onPrimary : cs.onSecondaryContainer;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {},
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String big;
  final bool fullWidth;

  const InfoCard({
    super.key,
    required this.title,
    required this.big,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface, // Card background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline), // Border color from theme
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05), // subtle shadow that adapts
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant, // subtle text color
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            big,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface, // primary readable color
            ),
          ),
        ],
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final String title;
  final String metaLabel;
  final String metaValue;
  final IconData icon;

  const TaskTile({
    super.key,
    required this.title,
    required this.metaLabel,
    required this.metaValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface, // card background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline), // border from theme
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceVariant, // icon background
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: cs.onSurface, // icon color
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface, // title text color
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$metaLabel:',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant, // muted label color
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      metaValue,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary, // highlight color
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // const _CheckBoxStub(),
        ],
      ),
    );
  }
}

class _CheckBoxStub extends StatelessWidget {
  const _CheckBoxStub();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outline, // border adapts to theme
          width: 2,
        ),
        color: cs.surface, // background adapts to theme
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle; // can be status
  final Color? chipColor;

  const ActivityTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasChip = chipColor != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface, // card background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline), // border color from theme
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceVariant, // icon background
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: cs.onSurface, // icon color
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface, // title text
                  ),
                ),
                const SizedBox(height: 4),
                if (!hasChip)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant, // muted subtitle text
                    ),
                  )
                else
                  _Chip(
                    text: subtitle,
                    color: chipColor ?? cs.primary, // chip background
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color? color; // optional, falls back to theme color
  const _Chip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = color ?? cs.primary; // fallback to theme primary

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: baseColor.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: baseColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
