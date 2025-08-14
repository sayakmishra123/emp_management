import 'package:e_management/screens/employee/employeeprofile.dart';
import 'package:e_management/screens/facedetaction/face_detect.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool lightMode = false;
  bool faceMode = false;

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
              // Header with back arrow and centered title
              Row(
                children: const [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  Spacer(),
                  Text('Settings',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Opacity(
                      opacity: 0,
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
                ],
              ),
              const SizedBox(height: 18),

              const _SettingsSectionTitle('Account'),
              const SizedBox(height: 8),
              _SettingTile(
                ontap: () {
                  Get.to(() => EmployeeProfilePage());
                },
                leading: Icons.person_outline,
                title: 'Personal Information',
                subtitle: 'Update your personal information',
              ),
              const SizedBox(height: 8),
              _SettingTile(
                ontap: () {},
                leading: Icons.lock_outline,
                title: 'Password',
                subtitle: 'Change your password',
              ),

              const SizedBox(height: 18),
              const _SettingsSectionTitle('Preferences'),
              const SizedBox(height: 8),
              _SettingTile(
                ontap: () {},
                leading: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Manage your notification settings',
              ),
              const SizedBox(height: 8),
              _SettingSwitchTile(
                leading: Icons.wb_sunny_outlined,
                title: 'Light Mode',
                value: lightMode,
                onChanged: (v) => setState(() => lightMode = v),
              ),

              const SizedBox(height: 8),
              _SettingSwitchTile(
                leading: Icons.face,
                title: 'Facial Recognition',
                value: faceMode,
                onChanged: (v) {
                  setState(() => faceMode = v);
                  if (faceMode) {
                    Get.to(() => FaceDetectionScreen());
                  }
                },
              ),

              const SizedBox(height: 18),
              const _SettingsSectionTitle('About'),
              const SizedBox(height: 8),
              _SettingTile(
                ontap: () {},
                leading: Icons.info_outline,
                title: 'App Version',
                subtitle: 'View the current app version',
              ),
              const SizedBox(height: 8),
              _SettingTile(
                ontap: () {},
                leading: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
        color: cs.onBackground, // adaptive text color
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final VoidCallback ontap;

  const _SettingTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: ontap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(leading, size: 20, color: cs.onSurfaceVariant),
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
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leading, size: 20, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: cs.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: cs.onPrimary,
            activeTrackColor: cs.primary,
            inactiveThumbColor: cs.onSurfaceVariant,
            inactiveTrackColor: cs.surfaceVariant,
          ),
        ],
      ),
    );
  }
}
