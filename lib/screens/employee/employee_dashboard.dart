import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_management/controllers/auth_controller.dart';
import 'package:e_management/controllers/task_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class EmployeeDashboard extends StatefulWidget {
  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final taskController = Get.put(TaskController());
  final authController = Get.find<AuthController>();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  DateTime selectedDate = DateTime.now();
  DateTime focusedDay = DateTime.now();
  int selectedFilterIndex = 0;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool showSearchBar = false;

  final List<String> filters = ['All', 'Panding', 'In Progress', 'Done'];
  final List<String> statusOptions = [
    'Panding',
    'Assigned',
    'In Progress',
    'Done'
  ];

  @override
  void initState() {
    super.initState();
    taskController.loadTasksFor(uid);
  }

  void _showEditTaskDialog(
      BuildContext context, String taskId, String currentDescription) {
    final TextEditingController descriptionController =
        TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.edit_note, color: Colors.deepPurple, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Update task description...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 75, 11, 222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final newDescription =
                            descriptionController.text.trim();
                        if (newDescription.isEmpty) return;

                        await taskController.editTask(
                            context, taskId, uid, newDescription);
                        Get.back();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 8,
          insetPadding: EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note,
                        color: const Color.fromARGB(255, 75, 11, 222),
                        size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Add New Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  maxLines: 10,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter task description...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.deepPurple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final description = descriptionController.text.trim();
                        if (description.isEmpty) return;

                        final success =
                            await taskController.assignTask(uid, description);

                        if (!context.mounted) return; // Ensure context is valid

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? "Task assigned successfully"
                                : "Failed to assign task"),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );

                        if (success) {
                          taskController.loadTasksFor(uid);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 75, 11, 222),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Add Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTaskDialog(context),
          backgroundColor: const Color.fromARGB(255, 75, 11, 222),
          label: Text(
            'Add Task',
            style: TextStyle(color: Colors.white),
          )),
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 75, 11, 222),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Get.back();
                authController.logout();
              },
            ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(showSearchBar ? 130 : 70),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 75, 11, 222),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.menu, color: Colors.white),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Today's Tasks",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          setState(() => showSearchBar = !showSearchBar);
                        },
                      )
                    ],
                  ),
                  if (showSearchBar) ...[
                    SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(
                            () => searchQuery = value.trim().toLowerCase());
                      },
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        hintText: "Search assigned task...",
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color.fromARGB(255, 75, 11, 222),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: const Color.fromARGB(255, 75, 11, 222),
                          ),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              searchQuery = '';
                              showSearchBar = false;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),

      // ... (other unchanged code remains)
      body: Obx(() {
        final tasks = taskController.tasks.where((task) {
          final taskDate = (task['assignedAt'] as Timestamp).toDate();
          final sameDay = isSameDay(taskDate, selectedDate);

          final selectedFilter = filters[selectedFilterIndex];
          final matchesFilter = selectedFilter == 'All'
              ? true
              : task['status'].toString().toLowerCase() ==
                  selectedFilter.toLowerCase();

          final description =
              (task['description'] ?? '').toString().toLowerCase();
          final matchesSearch =
              searchQuery.isEmpty || description.contains(searchQuery);

          return sameDay && matchesFilter && matchesSearch;
        }).toList();
        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDate = selected;
                      focusedDay = focused;
                    });
                  },
                  rowHeight: 40,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: const Color.fromARGB(255, 75, 11, 222),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.redAccent),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekendStyle: TextStyle(color: Colors.redAccent),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, left: 16),
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final isSelected = selectedFilterIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedFilterIndex = index);
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 10),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color.fromARGB(255, 75, 11, 222)
                                  : Color(0xFFEFE7FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                filters[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color.fromARGB(255, 75, 11, 222),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // ... (calendar and filters UI remains)
              tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(child: Text("No tasks found.")),
                    )
                  : ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final taskDate =
                            (task['assignedAt'] as Timestamp).toDate();
                        final time = DateFormat('hh:mm a').format(taskDate);
                        final currentStatus = task['status'];
                        final isValidStatus =
                            statusOptions.contains(currentStatus);

                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned Task',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600),
                              ),
                              SizedBox(height: 6),
                              Text(
                                task['description'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      color: const Color.fromARGB(
                                          255, 75, 11, 222),
                                      size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 75, 11, 222),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(currentStatus)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: getStatusColor(currentStatus)
                                              .withOpacity(0.5)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: isValidStatus
                                            ? currentStatus
                                            : 'Panding',
                                        icon: Icon(Icons.arrow_drop_down,
                                            size: 16,
                                            color:
                                                getStatusColor(currentStatus)),
                                        dropdownColor: Colors.white,
                                        style: TextStyle(
                                          color: getStatusColor(currentStatus),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        isDense: true,
                                        alignment: Alignment.center,
                                        items:
                                            statusOptions.map((String status) {
                                          return DropdownMenuItem<String>(
                                            value: status,
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                  color:
                                                      getStatusColor(status)),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (newStatus) async {
                                          if (newStatus != null &&
                                              newStatus != currentStatus) {
                                            taskController.updateTaskStatus(
                                                context, task.id, newStatus);
                                            taskController.loadTasksFor(uid);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: Colors.deepPurple, size: 20),
                                    onPressed: () => _showEditTaskDialog(
                                        context,
                                        task.id,
                                        task['description'] ?? ''),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      }),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Assigned':
        return Colors.blue;
      case 'Panding':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
