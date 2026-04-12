import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studyalquran/mobile/views/auth/splashScreen.dart';
import 'package:studyalquran/utils/color_constants.dart';

class MyMobileApp extends StatelessWidget {
  const MyMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Al Quran - Mobile',
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: AppColors.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreenVIP(),
    );
  }
}
