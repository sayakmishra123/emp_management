import 'dart:ui';

import 'package:e_management/screens/employee/new_employee_dashboard.dart';
import 'package:e_management/screens/employee/settingpage.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Widget _buildBody() {
    switch (_index) {
      case 0:
        return const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: NewEmployeeDashboard(),
        );
      case 1:
        return const _SimplePage(
            title: 'Documents', message: 'No documents yet.');

      case 2:
      default:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavBar(
        current: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  final String message;
  const _SimplePage({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Text(message,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== Bottom Navigation (Home / Documents / Departments / Settings) ==================
class BottomNavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;

  const BottomNavBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final selectedColor = cs.onSurface;
    final unselectedColor = cs.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: ClipRRect(
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Strong transparent blur
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent, // fully transparent background
              border: Border(
                top: BorderSide(
                    color: cs.outline.withOpacity(0.2),
                    width: 1), // subtle border
              ),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  label: 'Home',
                  selected: current == 0,
                  filled: Icons.home_rounded,
                  outlined: Icons.home_outlined,
                  onTap: () => onChanged(0),
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                ),
                _NavItem(
                  label: 'Documents',
                  selected: current == 1,
                  filled: Icons.insert_drive_file_rounded,
                  outlined: Icons.insert_drive_file_outlined,
                  onTap: () => onChanged(1),
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                ),
                _NavItem(
                  label: 'Settings',
                  selected: current == 2,
                  filled: Icons.settings_rounded,
                  outlined: Icons.settings_outlined,
                  onTap: () => onChanged(2),
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData filled;
  final IconData outlined;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  const _NavItem({
    required this.label,
    required this.selected,
    required this.filled,
    required this.outlined,
    required this.onTap,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final icon = selected ? filled : outlined;
    final color = selected
        ? (selectedColor ?? cs.onSurface)
        : (unselectedColor ?? cs.onSurfaceVariant);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
