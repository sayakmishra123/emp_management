import 'package:flutter/material.dart';

class EmployeeProfilePage extends StatelessWidget {
  const EmployeeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with back & centered title
                  Row(
                    children: const [
                      Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      Spacer(),
                      Text('Employee Profile',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Opacity(
                          opacity: 0,
                          child:
                              Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 42,
                      backgroundImage:
                          AssetImage('assets/avatar_placeholder.png'),
                      backgroundColor: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Ethan Carter',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Senior Software Engineer',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F7FA1),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  const Text('Engineering Department',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F7FA1),
                          fontWeight: FontWeight.w600)),

                  const SizedBox(height: 20),
                  // Contact Information Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _SettingsSectionTitle('Contact Information'),
                  ),
                  const SizedBox(height: 8),
                  const _TwoLineTile(
                    leading: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'ethan.carter@example.com',
                  ),
                  const SizedBox(height: 8),
                  const _TwoLineTile(
                    leading: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: '+1 (555) 123-4567',
                  ),
                  const SizedBox(height: 8),
                  const _TwoLineTile(
                    leading: Icons.location_on_outlined,
                    title: 'Address',
                    subtitle: '123 Main St, Anytown, USA',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            const Color.fromARGB(255, 216, 229, 243),
                        foregroundColor: const Color(0xFF111827),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {},
                      child: const Text('Edit Contact Info',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _SettingsSectionTitle('Employment Details'),
                  ),
                  const SizedBox(height: 8),
                  const _TwoLineTile(
                    leading: Icons.apartment_outlined,
                    title: 'Department',
                    subtitle: 'Engineering',
                  ),
                  const SizedBox(height: 8),
                  const _TwoLineTile(
                    leading: Icons.work_outline,
                    title: 'Job Title',
                    subtitle: 'Senior Software Engineer',
                  ),
                  const SizedBox(height: 8),
                  const _TwoLineTile(
                    leading: Icons.calendar_today_outlined,
                    title: 'Start Date',
                    subtitle: 'January 15, 2020',
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoLineTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;

  const _TwoLineTile({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface, // Card background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline), // Border color from theme
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceVariant, // Icon background
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              leading,
              size: 20,
              color: cs.onSurface, // Icon color
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
                    color: cs.onSurface, // Title text
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant, // Subtitle color
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String text;
  const _SettingsSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: cs.onBackground, // Adapts to dark/light
      ),
    );
  }
}
