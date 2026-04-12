import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyalquran/utils/color_constants.dart';

// 🔥 THEME CONTROLLER - Globally manage dark mode
class ThemeController extends GetxController {
  RxBool isDarkMode = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  // Load theme preference
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('darkMode') ?? false;
    AppColors.toggleDarkMode(isDarkMode.value); // ✅ Apply colors
  }

  // Toggle theme and save preference
  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    isDarkMode.value = value;
    AppColors.toggleDarkMode(value); // ✅ Apply dark mode colors
    
    // 🔥 Force rebuild to apply new colors
    Get.forceAppUpdate();
  }
}