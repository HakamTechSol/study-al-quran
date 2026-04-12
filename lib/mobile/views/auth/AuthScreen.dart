import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:studyalquran/mobile/views/teacher/Teacher_bootomNav.dart';
import 'package:studyalquran/mobile/views/student/Student_bottomNav.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:studyalquran/services/fcm_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedRole = _tabController.index == 0 ? 'teacher' : 'student';

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // await FCMService().initialize(context);

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw 'User data not found in database';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String actualRole = userData['role'] ?? '';

      if (actualRole != selectedRole) {
        await _auth.signOut();
        String errorMsg = selectedRole == 'teacher'
            ? 'This account is not registered as a Teacher. Please use the Student tab.'
            : 'This account is not registered as a Student. Please use the Teacher tab.';
        throw errorMsg;
      }

      if (userData['status'] == 'inactive') {
        await _auth.signOut();
        throw 'Your account has been deactivated. Contact admin.';
      }

      final prefs = await SharedPreferences.getInstance();
      await _clearAllPreferences(prefs);

      await prefs.setString('userId', userCredential.user!.uid);
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('role', actualRole);

      await _saveFCMTokenToUserDocument(
        userId: userCredential.user!.uid,
        userData: userData,
        actualRole: actualRole,
      );

      if (actualRole == 'teacher') {
        await prefs.setString('teacherName', userData['name'] ?? '');
        await prefs.setString('teacherPhone', userData['phone'] ?? '');
        await prefs.setString('teacherSubject', userData['subject'] ?? '');
        await prefs.setString(
          'teacherQualification',
          userData['qualification'] ?? '',
        );

        _showSnackBar('Welcome back, Teacher!', isError: false);
        _navigateToTeacherDashboard();
      } else if (actualRole == 'student') {
        await prefs.setString('studentName', userData['name'] ?? '');
        await prefs.setString('studentPhone', userData['phone'] ?? '');
        await prefs.setString('studentClass', userData['class'] ?? '');
        await prefs.setString(
          'studentRollNumber',
          userData['rollNumber'] ?? '',
        );

        _showSnackBar('Welcome back, Student!', isError: false);
        _navigateToStudentDashboard();
      } else {
        await _auth.signOut();
        throw 'Invalid user role';
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Invalid credentials. Please check email and password';
      }
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFCMTokenToUserDocument({
    required String userId,
    required Map<String, dynamic> userData,
    required String actualRole,
  }) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        debugPrint('FCM token not available');
        return;
      }

      debugPrint('🔑 Saving FCM token for user: $userId');
      debugPrint('📱 Token: ${fcmToken.substring(0, 20)}...');

      await _firestore.collection('users').doc(userId).set({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'appVersion': '1.0.0',
        },
      }, SetOptions(merge: true));

      if (actualRole == 'teacher') {
        await _firestore.collection('teachers').doc(userId).set({
          'fcmToken': fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (actualRole == 'student') {
        await _firestore.collection('students').doc(userId).set({
          'fcmToken': fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      debugPrint('✅ FCM Token saved successfully for $userId');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  Future<void> _clearAllPreferences(SharedPreferences prefs) async {
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('role');
    await prefs.remove('teacherName');
    await prefs.remove('teacherPhone');
    await prefs.remove('teacherSubject');
    await prefs.remove('teacherQualification');
    await prefs.remove('studentName');
    await prefs.remove('studentPhone');
    await prefs.remove('studentClass');
    await prefs.remove('studentRollNumber');
  }

  void _navigateToTeacherDashboard() {
    Get.offAll(
      () => const TeacherMainScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _navigateToStudentDashboard() {
    Get.offAll(
      () => const StudentMainScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = screenHeight < 600 ? 0.85 : 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withOpacity(0.1),
              AppColors.background,
              AppColors.gradient.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0 * scaleFactor),
              child: Transform.scale(
                scale: scaleFactor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.gradient],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 32,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Study Al-Quran',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      'Learning Portal',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.subtitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      constraints: const BoxConstraints(maxWidth: 380),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.isDarkMode
                                ? AppColors.black.withOpacity(0.3)
                                : AppColors.grey.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.subtitle,
                              indicatorColor: AppColors.primary,
                              indicatorWeight: 2.5,
                              labelStyle: AppTextStyles.buttonPrimary.copyWith(
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                              unselectedLabelStyle:
                                  AppTextStyles.buttonDisabled.copyWith(
                                color: AppColors.subtitle,
                                fontSize: 14,
                              ),
                              tabs: const [
                                Tab(text: 'Teacher', height: 42),
                                Tab(text: 'Student', height: 42),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: 460,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLoginForm('Teacher'),
                                _buildLoginForm('Student'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(String userType) {
    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Login as $userType with credentials provided by admin',
                    style: AppTextStyles.captionText.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: '${userType.toLowerCase()}@school.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 2),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _showForgotPasswordDialog(userType);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: Text(
                'Forgot Password?',
                style: AppTextStyles.buttonSecondary.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          _buildLoginButton(),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {
                _showContactAdminDialog();
              },
              child: Text(
                'Need help? Contact Admin',
                style: AppTextStyles.captionText.copyWith(
                  color: AppColors.subtitle,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            keyboardType: keyboardType,
            style: AppTextStyles.inputValue.copyWith(
              color: AppColors.text,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.inputHint.copyWith(
                color: AppColors.subtitle,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: AppColors.subtitle, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.subtitle,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.gradient],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Sign In',
                style: AppTextStyles.buttonPrimary.copyWith(fontSize: 14),
              ),
      ),
    );
  }

  void _showForgotPasswordDialog(String userType) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.gradient],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password Request',
                              style: AppTextStyles.heading5.copyWith(
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              'Request admin to reset your password',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enter your details. Admin will reset your password and contact you.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Name',
                        style: AppTextStyles.labelText.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Address',
                        style: AppTextStyles.labelText.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your registered email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Requesting as: $userType',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.buttonSecondary.copyWith(
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.gradient],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (nameController.text.isEmpty) {
                                      _showSnackBar(
                                        'Please enter your name',
                                        isError: true,
                                      );
                                      return;
                                    }

                                    if (emailController.text.isEmpty) {
                                      _showSnackBar(
                                        'Please enter your email',
                                        isError: true,
                                      );
                                      return;
                                    }

                                    if (!_isValidEmail(
                                        emailController.text.trim())) {
                                      _showSnackBar(
                                        'Please enter a valid email',
                                        isError: true,
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    try {
                                      await _firestore
                                          .collection('helpAndSupport')
                                          .add({
                                        'type': 'password_reset_request',
                                        'userType': userType.toLowerCase(),
                                        'name': nameController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'status': 'pending',
                                        'message':
                                            'Password reset requested for $userType account',
                                        'createdAt': FieldValue.serverTimestamp(),
                                        'updatedAt': FieldValue.serverTimestamp(),
                                        'handledBy': null,
                                        'resolvedAt': null,
                                      });

                                      await _firestore
                                          .collection('packageChangeRequests')
                                          .add({
                                        'type': 'password_reset',
                                        'userType': userType.toLowerCase(),
                                        'name': nameController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'status': 'pending',
                                        'message':
                                            '$userType password reset requested',
                                        'createdAt': FieldValue.serverTimestamp(),
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      });

                                      Navigator.pop(context);

                                      _showSnackBar(
                                        '✅ Request submitted! Admin will contact you soon.',
                                        isError: false,
                                      );
                                    } catch (e) {
                                      print('Error submitting request: $e');
                                      _showSnackBar(
                                        'Failed to submit request. Please try again.',
                                        isError: true,
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => isLoading = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.transparent,
                              shadowColor: AppColors.transparent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Submit Request',
                                        style:
                                            AppTextStyles.buttonPrimary.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.send, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showContactAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Admin',
          style: AppTextStyles.heading5.copyWith(color: AppColors.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For account issues, please contact:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(Icons.email, 'admin@studyalquran.com'),
            const SizedBox(height: 8),
            _buildContactItem(Icons.phone, '+92 300 1234567'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}