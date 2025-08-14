import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_management/controllers/auth_controller.dart';
import 'package:e_management/controllers/task_controller.dart';
import 'package:e_management/screens/admin/assign_task_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final taskController = Get.put(TaskController());
  final authController = Get.find<AuthController>();

  final Color primaryColor = const Color.fromARGB(255, 75, 11, 222);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      taskController.loadTasksFor(uid);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, size: 40, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: primaryColor),
              title: const Text('Logout', style: TextStyle(fontSize: 14)),
              onTap: () {
                Get.back(); // close drawer
                authController.logout();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: searchController,
              onChanged: (value) =>
                  setState(() => searchQuery = value.trim().toLowerCase()),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search employee by email',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 20, color: primaryColor),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📄 Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              "All Employees",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryColor),
            ),
          ),

          // 👥 Employee List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  final email = doc['email'].toString().toLowerCase();
                  return email.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    final email = employee['email'];
                    final displayInitial = email[0].toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Get.to(() => AssignTaskScreen(
                              employeeId: employee.id,
                              employeeEmail: email,
                            )),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: primaryColor,
                              child: Text(
                                displayInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "Tap to assign task",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
