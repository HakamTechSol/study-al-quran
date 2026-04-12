import 'package:flutter/material.dart';
// import 'package:studyalquran/mobile/views/chat/ChatScreen.dart';
import 'package:studyalquran/mobile/views/chat/StudentChatListScreen.dart';
import 'package:studyalquran/mobile/views/student/scheduleScreen.dart';
import 'package:studyalquran/mobile/views/student/studentpakage.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:studyalquran/mobile/views/student/studentProfile.dart';


// ========================================
// 🎓 STUDENT BOTTOM NAVIGATION
// ========================================


class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentScheduleScreen(),
    const StudentChatListScreen(),
    const PackagesInvoicesScreen(),
    const StudentProfile(),
    // const StudentScheduleScreen(),
    // const StudentChatScreen(),
    // const StudentPackagesScreen(),
    // const StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey,
          selectedLabelStyle: AppTextStyles.captionText.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: AppTextStyles.captionText.copyWith(fontSize: 11),
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.chat_outlined),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              activeIcon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Packages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}


