import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_management/screens/admin/add_employee.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';

class AdminEmployeesScreen extends StatefulWidget {
  AdminEmployeesScreen({super.key});

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  final TextEditingController searchController = TextEditingController();

  final taskController = Get.put(TaskController());

  final authController = Get.find<AuthController>();

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    const pageX = 16.0;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      taskController.loadTasksFor(uid);
    }
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
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
          onPressed: () {
            Get.to(() => AddEmployeePage());
          },
          icon: const Icon(
            Icons.add_rounded,
            color: Colors.white,
          ),
          label: const Text(
            'Add Employee',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header (centered title, + at right)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: 44), // keep title perfectly centered
                    Expanded(
                      child: Center(
                        child: Text(
                          'Employees',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 22),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(pageX, 8, pageX, 6),
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: searchController,
                  onChanged: (value) =>
                      setState(() => searchQuery = value.trim().toLowerCase()),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search by name',
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

            // List
            Expanded(
              child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'employee')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('No employees found.',
                              style: TextStyle(fontSize: 13)));
                    }

                    final allEmployees = snapshot.data!.docs;
                    final filteredEmployees = allEmployees.where((doc) {
                      final name = doc['firstName'].toString().toLowerCase() +
                          " " +
                          doc['lastName'].toString().toLowerCase();
                      return name.contains(searchQuery);
                    }).toList();

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(pageX, 6, pageX, 16),
                      itemBuilder: (context, i) =>
                          EmployeeRow(emp: filteredEmployees[i]),
                      separatorBuilder: (_, __) => Divider(
                        thickness: 0.4,
                      ),
                      itemCount: filteredEmployees.length,
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeRow extends StatelessWidget {
  final emp;
  const EmployeeRow({super.key, required this.emp});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const avatarSize = 44.0;
    final avatarBg = cs.surfaceVariant; // adapts for dark/light
    final iconColor = cs.secondary; // subtle icon color
    final linkColor = cs.secondary; // email/phone text
    final nameColor = cs.onBackground; // name text

    Widget avatar(String name) {
      final initials =
          name.split(' ').take(2).map((p) => p[0]).join().toUpperCase();
      return CircleAvatar(
        radius: avatarSize / 2,
        backgroundColor: avatarBg,
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: linkColor,
          ),
        ),
      );
    }

    Widget infoText(String text, {bool bold = false, Color? color}) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: bold ? 16 : 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? nameColor,
          height: 1.3,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar(emp['firstName'] + emp['lastName']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                infoText("${emp['firstName']} ${emp['lastName']}", bold: true),
                const SizedBox(height: 2),
                // Role & Department
                infoText(
                  "${emp['role']} · ${emp['department']}",
                  color: linkColor,
                ),
                const SizedBox(height: 2),
                // Email
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: iconColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: infoText(emp['email'] ?? '', color: linkColor),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Phone
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: iconColor),
                    const SizedBox(width: 4),
                    infoText(emp['phone'] ?? '', color: linkColor),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: iconColor),
        ],
      ),
    );
  }
}
