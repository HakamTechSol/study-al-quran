// import 'package:studyalquran/mobile/views/auth/splashScreen.dart';
// import 'package:studyalquran/utils/color_constants.dart';
// import 'package:studyalquran/controllers/theme_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   Get.put(ThemeController());

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ThemeController themeController = Get.find();

//     return Obx(
//       () => GetMaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Study Al Quran',
//         theme: AppColors.lightTheme,
//         darkTheme: AppColors.darkTheme,
//         themeMode: themeController.isDarkMode.value
//             ? ThemeMode.dark
//             : ThemeMode.light,
//         home: SplashScreenVIP(),
//       ),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'main_mobile.dart';
import 'main_web.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    runApp(const MyWebApp());
  } else {
    runApp(const MyMobileApp());
  }
}
