import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:studyalquran/web_admin/screens/admin_login.dart';

class MyWebApp extends StatelessWidget {
  const MyWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Al Quran - Admin Panel',
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: ThemeMode.light,
      home: const AdminLoginScreen(),
    );
  }
}
