import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TaskController extends GetxController {
  final RxList<DocumentSnapshot> tasks = <DocumentSnapshot>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  void loadTasksFor(String employeeId) {
    // Cancel previous subscription if any
    _tasksSubscription?.cancel();

    _tasksSubscription = _firestore
        .collection('tasks')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      tasks.value = snapshot.docs;
    });
  }

  void cancelTasksListener() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
  }

  @override
  void onClose() {
    cancelTasksListener();
    super.onClose();
  }

  Future<bool> assignTask(String employeeId, String description) async {
    try {
      await _firestore.collection('tasks').add({
        'employeeId': employeeId,
        'description': description,
        'status': 'Assigned',
        'assignedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateTaskStatus(
      BuildContext context, String taskId, String status) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated to $status"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteTask(String taskId, String userId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      loadTasksFor(userId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete task');
    }
  }

  Future<void> editTask(BuildContext context, String taskId, String userId,
      String newDescription) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update({'description': newDescription});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update task'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
