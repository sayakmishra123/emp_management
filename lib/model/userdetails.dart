import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String department;
  final String employeeId;
  final String role;
  final DateTime? hireDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.department,
    required this.employeeId,
    required this.role,
    this.hireDate,
  });

  factory UserModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      throw ArgumentError('Data map is null');
    }

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      department: data['department'] ?? '',
      employeeId: data['employeeId'] ?? '',
      role: data['role'] ?? '',
      hireDate: (data['hireDate'] is Timestamp)
          ? (data['hireDate'] as Timestamp).toDate()
          : null,
    );
  }
}
