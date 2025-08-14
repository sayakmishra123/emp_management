import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

enum FilterTab { all, approved, pending }

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  final searchCtrl = TextEditingController();
  FilterTab tab = FilterTab.all;

  // Demo data (exactly like the screenshot)
  final past = const [
    _LeaveRowData(
        dates: '05/15/24 - 05/20/24', kind: 'Vacation', status: 'Approved'),
    _LeaveRowData(
        dates: '04/20/24 - 04/21/24', kind: 'Sick Leave', status: 'Approved'),
    _LeaveRowData(dates: '03/10/24', kind: 'Personal Day', status: 'Approved'),
  ];
  final pending = const [
    _LeaveRowData(
        dates: '06/10/24 - 06/15/24', kind: 'Vacation', status: 'Pending'),
  ];

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pageX = 16.0;
    const titleH = 44.0;

    final allRows = switch (tab) {
      FilterTab.all => (past, pending),
      FilterTab.approved => (
          past.where((e) => e.status == 'Approved').toList(),
          <_LeaveRowData>[]
        ),
      FilterTab.pending => (<_LeaveRowData>[], pending),
    };

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: SizedBox(
                height: titleH,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 22),
                      onPressed: () {},
                      splashRadius: 20,
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Leave History',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // keeps title centered
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: pageX),
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: searchCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 10, right: 6),
                              child: Icon(Icons.search,
                                  size: 20, color: Color(0xFF7FA2C4)),
                            ),
                            prefixIconConstraints: BoxConstraints(minWidth: 36),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: pageX),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: tab == FilterTab.all,
                            onTap: () => setState(() => tab = FilterTab.all),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Approved',
                            selected: tab == FilterTab.approved,
                            onTap: () =>
                                setState(() => tab = FilterTab.approved),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Pending',
                            selected: tab == FilterTab.pending,
                            onTap: () =>
                                setState(() => tab = FilterTab.pending),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Past section (shown when it has rows)
                    if (allRows.$1.isNotEmpty) ...[
                      const _SectionHeader('Past'),
                      const SizedBox(height: 8),
                      ...allRows.$1.map((e) => _LeaveRow(data: e)),
                      const SizedBox(height: 16),
                    ],

                    // Pending section (shown when it has rows)
                    if (allRows.$2.isNotEmpty) ...[
                      const _SectionHeader('Pending'),
                      const SizedBox(height: 8),
                      ...allRows.$2.map((e) => _LeaveRow(data: e)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const chipBg = Color(0xFFEFF4FA);
    const chipSel = Color(0xFFE2ECF9);
    const text = Color(0xFF0D141C);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipSel : chipBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: text,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LeaveRowData {
  final String dates;
  final String kind;
  final String status;
  const _LeaveRowData({
    required this.dates,
    required this.kind,
    required this.status,
  });
}

class _LeaveRow extends StatelessWidget {
  final _LeaveRowData data;
  const _LeaveRow({required this.data});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF7FA2C4);
    final statusColor = const Color(0xFF0D141C).withOpacity(0.75);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left (dates + type)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.dates,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.kind,
                  style: GoogleFonts.inter(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Right (status)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              data.status,
              style: GoogleFonts.inter(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
