import 'package:flutter/material.dart';

class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: cs.onSurface,
          ),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Task Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 28,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () {},
            tooltip: 'More',
          ),
        ],
      ),
      body: const _TaskDetailsBody(),
      bottomNavigationBar: const _CommentInputBar(),
    );
  }
}

class _TaskDetailsBody extends StatelessWidget {
  const _TaskDetailsBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _ElevatedCard(child: _TaskHeaderCard()),
          SizedBox(height: 14),
          _ElevatedCard(child: _CommentsSection()),
        ],
      ),
    );
  }
}

class _ElevatedCard extends StatelessWidget {
  const _ElevatedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _TaskHeaderCard extends StatelessWidget {
  const _TaskHeaderCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finalize project report',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.event_outlined, label: 'March 15, 2024'),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.access_time, label: '10:00 - 11:00 AM'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          children: [
            TagChip(
              label: 'Work',
              fg: cs.primary,
              bg: cs.primary.withOpacity(0.12),
            ),
            TagChip(
              label: 'Urgent',
              fg: cs.error,
              bg: cs.error.withOpacity(0.12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          "Review all sections of the project report, ensure data accuracy, and format it according to the company's guidelines before submitting to management.",
          style: t.bodyMedium,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    required this.fg,
    required this.bg,
  });
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments', style: t.titleMedium),
        const SizedBox(height: 12),
        const _CommentTile(
          name: 'Jane Doe',
          avatarUrl: 'https://i.pravatar.cc/100?img=47',
          message:
              'Please double-check the figures on page 5. I think there might be a typo.',
          ago: '2 hours ago',
        ),
        const SizedBox(height: 10),
        const _CommentTile(
          name: 'John Smith',
          avatarUrl: 'https://i.pravatar.cc/100?img=12',
          message: 'Great work on this. The introduction is very well-written.',
          ago: '1 hour ago',
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.name,
    required this.message,
    required this.ago,
    required this.avatarUrl,
  });

  final String name;
  final String message;
  final String ago;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Light mode fixed colors
    final nameColor = isLight ? const Color(0xFF111827) : cs.onSurface;
    final bubbleColor = isLight ? const Color(0xFFF0F3F7) : cs.surfaceVariant;
    final bubbleTextColor =
        isLight ? const Color(0xFF4B5563) : cs.onSurfaceVariant;
    final agoColor =
        isLight ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: nameColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Text(
                      message,
                      style: t.bodySmall?.copyWith(color: bubbleTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ago,
          style: t.labelSmall?.copyWith(color: agoColor),
        ),
      ],
    );
  }
}

class _CommentInputBar extends StatefulWidget {
  const _CommentInputBar({super.key});

  @override
  State<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<_CommentInputBar> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment sent (demo).')),
    );
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Custom colors for light mode
    final surfaceColor = isLight ? Colors.white : cs.surface;
    final outlineColor = isLight ? const Color(0xFFE5E7EB) : cs.outlineVariant;
    final sendButtonColor = isLight ? const Color(0xFF315BFF) : cs.primary;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: outlineColor),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      fillColor: surfaceColor,
                      filled: true,
                      isDense: true,
                      hintText: 'Add a comment…',
                      hintStyle:
                          TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    minLines: 1,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 52,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sendButtonColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _send,
                  icon: Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
