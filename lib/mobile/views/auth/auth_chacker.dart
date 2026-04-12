import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyalquran/mobile/views/auth/splashScreen.dart';
import 'package:studyalquran/mobile/views/auth/AuthScreen.dart';
import 'package:studyalquran/mobile/views/student/Student_bottomNav.dart';
import 'package:studyalquran/mobile/views/teacher/Teacher_bootomNav.dart';
// AuthScreen

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  /// Check SharedPreferences and return target screen
  Future<Widget> _getTargetScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? teacherName = prefs.getString('teacherName');
      final String? teacherPhone = prefs.getString('teacherPhone');

      final String? studentName = prefs.getString('studentName');
      final String? studentPhone = prefs.getString('studentPhone');

      if ((teacherName?.isNotEmpty ?? false) || (teacherPhone?.isNotEmpty ?? false)) {
        // Teacher logged in
        return const TeacherMainScreen();
      } else if ((studentName?.isNotEmpty ?? false) || (studentPhone?.isNotEmpty ?? false)) {
        // Student logged in
        return const StudentMainScreen();
      } else {
        // Not logged in
        return const AuthScreen();
      }
    } catch (e) {
      debugPrint('Error checking auth: $e');
      return const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getTargetScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Splash screen while checking
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasData) {
          // Redirect to the target screen
          return SplashScreenVIP();
        }

        // Default fallback
        return const AuthScreen();
      },
    );
  }
}
