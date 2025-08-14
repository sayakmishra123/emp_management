import 'package:e_management/screens/admin/admin_dashboard.dart';
import 'package:e_management/screens/admin/employeelist.dart';
import 'package:e_management/screens/auth/login_screen.dart';
import 'package:e_management/screens/auth/register_screen.dart';
import 'package:e_management/screens/employee/employee_dashboard.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const admin = '/admin';
  static const employee = '/employee';
}

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => RegisterScreen()),
    GetPage(name: AppRoutes.admin, page: () => AdminEmployeesScreen()),
    GetPage(name: AppRoutes.employee, page: () => EmployeeDashboard()),
  ];
}
