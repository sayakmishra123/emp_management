import 'dart:math';

import 'package:e_management/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  // NEW controllers for all fields on the form
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _hireDateCtrl = TextEditingController(); // you already had this

  // TODO: wherever you collect password (e.g., separate Register screen),
  // supply it here. For demo, a placeholder:
  String _password = '123456'; // replace with real password source

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    _deptCtrl.dispose();
    _empIdCtrl.dispose();
    _hireDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 40),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        // Fix: use DialogTheme, not DialogThemeData
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _hireDateCtrl.text = "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  final authController = Get.put(AuthController());
  void _onAddEmployee() {
    final email = _emailCtrl.text.trim();
    final role = _roleCtrl.text.trim();

    // Call the updated register function and pass all fields via `extra`
    authController.register(
      email,
      _password, // provide your real password from your registration flow
      role,
      extra: {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'employeeId': _empIdCtrl.text.trim(),
        'hireDate': _hireDateCtrl.text.trim(), // parsed in register()
      },
    );
  }

  String generateEmployeeId() {
    final rand = Random();
    final id = List.generate(6, (index) => rand.nextInt(10)).join();
    return 'EMP$id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () {}),
        title: const Text('Add Employee',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            const _SectionHeader('Personal Information'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _LabeledField(
                        controller: _firstNameCtrl,
                        label: 'First Name',
                        hint: 'Enter first name',
                        textInputAction: TextInputAction.next)),
                const SizedBox(width: 12),
                Expanded(
                    child: _LabeledField(
                        controller: _lastNameCtrl,
                        label: 'Last Name',
                        hint: 'Enter last name',
                        textInputAction: TextInputAction.next)),
              ],
            ),
            const SizedBox(height: 16),
            _LabeledField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'Enter email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: 'Enter phone number',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Employment Details'),
            const SizedBox(height: 12),
            _LabeledField(
              controller: _roleCtrl,
              label: 'Role',
              hint: 'Enter role',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              controller: _deptCtrl,
              label: 'Department',
              hint: 'Enter department',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              controller: _empIdCtrl,
              label: 'Employee ID',
              hint: 'Tap 🔄 to generate',
              suffixIcon: IconButton(
                icon: Icon(Icons.badge),
                onPressed: () {
                  _empIdCtrl.text =
                      generateEmployeeId(); // Generate when tapped
                },
              ),
              onTap: () {}, // Optional
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              controller: _hireDateCtrl,
              label: 'Hire Date',
              hint: 'Select hire date',
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: IconButton(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                tooltip: 'Pick date',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                // Fix: use styleFrom to avoid the broken WidgetState* API usage
                style: FilledButton.styleFrom(
                  shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _onAddEmployee,
                child: const Text('Add Employee',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Section headline (bold, slightly larger)
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }
}

/// Label above a filled TextField, matching the mock spacing/shape/colors.
class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _LabeledField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final labelStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: cs.onBackground, // adapts to light/dark mode
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
