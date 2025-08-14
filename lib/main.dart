import 'package:e_management/controllers/auth_controller.dart';
import 'package:e_management/routes/app_pages.dart';
import 'package:e_management/screens/admin/add_employee.dart';
import 'package:e_management/screens/admin/employeelist.dart';
import 'package:e_management/screens/auth/login_screen.dart';
import 'package:e_management/screens/employee/employee_dashboard.dart';
import 'package:e_management/screens/employee/employeeprofile.dart';
import 'package:e_management/screens/employee/leave_request.dart';
import 'package:e_management/screens/employee/leave_request_history.dart';
import 'package:e_management/screens/employee/navbar.dart';
import 'package:e_management/screens/employee/new_employee_dashboard.dart';
import 'package:e_management/screens/employee/new_tasklistpage.dart';
import 'package:e_management/screens/employee/settingpage.dart';
import 'package:e_management/screens/facedetaction/face_detect.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // OneSignal.initialize('YOUR-ONESIGNAL-APP-ID');

  // // OneSignal.Notifications.requestPermission(true);
  Get.put(AuthController());

  // // Determine initial route based on login and role
  String initialRoute = AppRoutes.login;

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final role = doc['role'];
      if (role == 'admin') {
        initialRoute = AppRoutes.admin;
      } else if (role == 'employee') {
        initialRoute = AppRoutes.employee;
      }
    }
  }

  runApp(MyApp(initialRoute: initialRoute));
  // runApp(MaterialApp(
  //   home: LeaveHistoryScreen(),
  // ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    Key? key,
    required this.initialRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0D80F2);

    final lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF7FA2C4), // subtle link/icon
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Colors.white,
      onBackground: const Color(0xFF0D141C),
      surface: Colors.white,
      onSurface: const Color(0xFF0D141C),
      surfaceVariant: const Color(0xFFEFF4FA),
      onSurfaceVariant: const Color(0xFF5F7FA1),
      outline: const Color(0xFFE2ECF9),
      shadow: Colors.black.withOpacity(0.1),
      tertiary: const Color(0xFFE9F0FA), // search field bg
      onTertiary: const Color(0xFF7FA2C4), // search placeholder
    );

    final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF7FA2C4),
      onSecondary: Colors.black,
      error: Colors.red[300]!,
      onError: Colors.black,

      // Background colors
      background: const Color(0xFF0F1A24), // deep black-blue tone
      onBackground: Colors.white,

      // Card / surface colors
      surface: const Color(
          0xFF162029), // slightly lighter than background for contrast
      onSurface: Colors.white,

      // For list dividers, chips, secondary surfaces
      surfaceVariant: const Color(0xFF1E2933),
      onSurfaceVariant: const Color(0xFF7FA2C4),

      // Borders and outlines
      outline: const Color(0xFF2A2A2A),

      shadow: Colors.black,

      // Search field background + placeholder
      tertiary: const Color(0xFF1C2A35), // darker, more opaque than before
      onTertiary: const Color(0xFF7FA2C4),
    );

    final inter = GoogleFonts.interTextTheme();

    ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      textTheme: inter.apply(
        bodyColor: lightColorScheme.onBackground,
        displayColor: lightColorScheme.onBackground,
      ),
      scaffoldBackgroundColor: lightColorScheme.background,
      cardColor: lightColorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.tertiary,
        hintStyle: GoogleFonts.inter(
          color: lightColorScheme.onTertiary,
          fontSize: 16,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );

    ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      textTheme: inter.apply(
        bodyColor: darkColorScheme.onBackground,
        displayColor: darkColorScheme.onBackground,
      ),
      scaffoldBackgroundColor: darkColorScheme.background,
      cardColor: darkColorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.tertiary,
        hintStyle: GoogleFonts.inter(
          color: darkColorScheme.onTertiary,
          fontSize: 16,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );

    return GetMaterialApp(
      title: 'Employee Task Manager',
      debugShowCheckedModeBanner: false,
      home: TasksHomeScreen(),
      // initialRoute: initialRoute,
      // getPages: AppPages.routes,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
