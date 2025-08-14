import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_management/controllers/task_controller.dart';
import 'package:e_management/controllers/userController.dart';
import 'package:e_management/model/userdetails.dart';
import 'package:e_management/routes/app_pages.dart';
import 'package:e_management/screens/admin/employeelist.dart';
import 'package:e_management/screens/employee/employee_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Show loading dialog
  void _showLoading(String message) {
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  /// Hide any loading/dialog
  void _hideDialog() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

// Keep your existing members: _auth, _firestore, _showLoading, _hideDialog, login...

  /// Register + save employee profile fields to the user's Firestore doc.
  /// Add any extra fields via [extra]. If extra['hireDate'] is a DateTime, it is
  /// stored as a Firestore Timestamp automatically.
  void register(
    String email,
    String password,
    String role, {
    Map<String, dynamic>? extra,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Validation Error', 'Email and password cannot be empty');
      return;
    }

    _showLoading('Creating account...');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // Prepare data for Firestore
      final data = <String, dynamic>{
        'uid': uid,
        'email': email,
        'role': role,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
        ...?extra,
      };

      // Normalize hireDate -> Timestamp if provided as DateTime/String
      final hd = extra?['hireDate'];
      if (hd is DateTime) {
        data['hireDate'] = Timestamp.fromDate(hd);
      } else if (hd is String && hd.trim().isNotEmpty) {
        // expecting "YYYY-MM-DD" from your picker text (safe parse)
        final parts = hd.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            data['hireDate'] = Timestamp.fromDate(DateTime(y, m, d));
          }
        }
      }

      await _firestore.collection('users').doc(uid).set(data);

      _hideDialog();
      // login(email, password); // Automatically logs in (your original behavior)
    } catch (e) {
      _hideDialog();
      Get.snackbar('Registration Failed', e.toString(),
          backgroundColor: Colors.red[100], colorText: Colors.black);
    }
  }

  void login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Validation Error', 'Please enter both email and password');
      return;
    }

    _showLoading('Logging in...');
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user?.uid ?? '';
      if (uid.isEmpty) {
        _hideDialog();
        Get.snackbar('Login Failed', 'Invalid user ID.');
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        _hideDialog();
        Get.snackbar('Login Failed', 'User role data missing in Firestore');
        await _auth.signOut();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Convert to UserModel
      final userModel = UserModel.fromMap(userData);

      final userController = Get.put(UserController());

      // Store globally using UserController
      userController.setUser(userModel);

      _hideDialog();

      if (userModel.role == 'admin') {
        Get.offAll(AdminEmployeesScreen());
      } else if (userModel.role == 'employee') {
        Get.offAll(EmployeeDashboard());
      } else {
        Get.snackbar('Login Failed', 'Unknown user role.');
        await _auth.signOut();
      }
    } catch (e) {
      _hideDialog();
      Get.snackbar('Login Failed', e.toString(),
          backgroundColor: Colors.red[100], colorText: Colors.black);
    }
  }

  void logout() async {
    _showLoading('Logging out...');
    if (Get.isRegistered<TaskController>()) {
      Get.find<TaskController>().cancelTasksListener();
    }
    await _auth.signOut();
    _hideDialog();
    Get.offAllNamed(AppRoutes.login);
  }
}
