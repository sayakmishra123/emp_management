import 'package:e_management/controllers/task_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AssignTaskScreen extends StatefulWidget {
  final String employeeId;
  final String employeeEmail;

  AssignTaskScreen({required this.employeeId, required this.employeeEmail});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final taskController = Get.put(TaskController());
  final taskText = TextEditingController();
  final List<String> filters = [
    'All',
    'Assigned',
    'Panding',
    'In Progress',
    'Done'
  ];
  int selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    taskController.loadTasksFor(widget.employeeId);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        title: Text(
          'Assign task',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 75, 11, 222),
        // actions: [
        //   IconButton(
        //     icon: Icon(
        //       Icons.se,
        //       color: Colors.white,
        //     ),
        //     onPressed: () {
        //       authController.logout();
        //     },
        //   )
        // ],
      ),
      // appBar: AppBar(
      //   title: Text('Tasks for ${widget.employeeEmail}'),
      //   backgroundColor:
      // ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskText,
                    maxLines: 3,
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
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width - 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 75, 11, 222),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () async {
                final description = taskText.text.trim();

                if (description.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task cannot be empty'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                    ),
                  );
                  return;
                }

                final success = await taskController.assignTask(
                    widget.employeeId, description);

                if (!context.mounted) return;

                if (success) {
                  taskText.clear();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task assigned successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to assign task'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                    ),
                  );
                }
              },
              child: const Text(
                'Add Task',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Tabs
          Container(
            margin: const EdgeInsets.only(top: 10, left: 16),
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
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 75, 11, 222)
                          : const Color(0xFFEFE7FF),
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

          Expanded(
            child: Obx(() {
              final allTasks = taskController.tasks;
              final selectedFilter = filters[selectedFilterIndex];
              final filteredTasks = selectedFilter == 'All'
                  ? allTasks
                  : allTasks
                      .where((t) => t['status'] == selectedFilter)
                      .toList();

              if (filteredTasks.isEmpty) {
                return const Center(
                  child: Text("No tasks found for selected filter."),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  final String status = task['status'];
                  final String formattedDate =
                      DateFormat('MMM dd, yyyy • hh:mm a')
                          .format(task['assignedAt'].toDate());

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.black12,
                      //     blurRadius: 6,
                      //     offset: const Offset(0, 4),
                      //   )
                      // ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Task',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task['description'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time,
                                color: Color.fromARGB(255, 75, 11, 222),
                                size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 75, 11, 222),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // 🟡 Status Chip
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: _getStatusColor(status).withOpacity(0.1),
                                border: Border.all(
                                  color:
                                      _getStatusColor(status).withOpacity(0.6),
                                ),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            // 🗑️ Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              onPressed: () =>
                                  _showDeleteDialog(context, task.id),
                              tooltip: "Delete Task",
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Task',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                try {
                  await taskController.deleteTask(taskId, widget.employeeId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task deleted successfully.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to delete task.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Assigned':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }
}
