import 'package:flutter/material.dart';
import 'package:studyalquran/mobile/views/chat/TeacherChatListScreen.dart';
// import 'package:studyalquran/mobile/views/chat/TeacherChatScreen.dart';
// import 'package:studyalquran/mobile/views/chat/TeacherrChatscreen.dart';
import 'package:studyalquran/mobile/views/teacher/ScheduleScreen.dart';
import 'package:studyalquran/mobile/views/teacher/account.dart';
import 'package:studyalquran/mobile/views/teacher/student_list.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
// import 'package:edulink/utils/color_constants.dart';
// import 'package:edulink/utils/text_styles.dart';

// ========================================
// 🧑‍🏫 TEACHER BOTTOM NAVIGATION
// ========================================

class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentsListScreen(),
    const TeacherScheduleScreen(),
    const TeacherChatListScreen(),
    const TeacherAccountScreen(),
    // const ChatScreen2(teacherName: 'student', teacherImage: 't'),
    // const TeacherStudentsScreen(),
    // const TeacherScheduleScreen(),
    // const TeacherAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
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
          unselectedLabelStyle: AppTextStyles.captionText.copyWith(
            fontSize: 11,
          ),
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.chat_bubble_outline),
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
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
