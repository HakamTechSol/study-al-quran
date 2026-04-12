import 'package:flutter/material.dart';
import 'package:studyalquran/mobile/views/auth/AuthScreen.dart';
import 'dart:io';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:studyalquran/controllers/theme_controller.dart'; 

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  // 🔥 GET THEME CONTROLLER
  final ThemeController themeController = Get.find();
  
  // 🔥 FIREBASE INSTANCES
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📊 User Data (Will be loaded from Firebase)
  String userName = "Loading...";
  String userEmail = "Loading...";
  String userPhone = "Loading...";
  String userAddress = "Loading...";
  String userRegion = "Loading...";
  String studentId = "Loading...";
  DateTime registrationDate = DateTime.now();

  String? profileImagePath;
  bool _isLoading = true;

  // Settings toggles
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadStudentDataFromFirebase();
    // Sync with global theme state
    setState(() {
      darkModeEnabled = themeController.isDarkMode.value;
    });
  }

  // 🔥 FIREBASE: Load student data
  Future<void> _loadStudentDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('👤 Loading student data for: ${user.uid}');

        // Load from 'users' collection
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            userName = userData['name'] ?? 'Student Name';
            userEmail =
                userData['email'] ?? user.email ?? 'student@studyalquran.com';
            userPhone = userData['phone'] ?? '+92 300 1234567';
            userAddress = userData['address'] ?? 'Address not provided';
            userRegion = userData['region'] ?? 'Karachi, Sindh';
            studentId =
                userData['studentId'] ?? 'S-${user.uid.substring(0, 8)}';

            // Handle registration date
            if (userData['createdAt'] != null) {
              registrationDate = (userData['createdAt'] as Timestamp).toDate();
            }
          });
        } else {
          // 🔥 IF USER NOT FOUND, USE AUTH DATA
          setState(() {
            userName = 'Student User';
            userEmail = user.email ?? 'student@studyalquran.com';
            userPhone = '+92 300 1234567';
            userAddress = 'Address not provided';
            userRegion = 'Karachi, Sindh';
            studentId = 'S-${user.uid.substring(0, 8)}';
          });
        }
      }

      setState(() => _isLoading = false);
      print('✅ Student data loaded successfully!');
    } catch (e) {
      print('❌ Error loading student data: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error loading profile data');
    }
  }

  // 🔥 FIREBASE: Update student profile
  Future<void> _updateStudentProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': userName,
          'phone': userPhone,
          'address': userAddress,
          'region': userRegion,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      _showSnackBar('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Profile & Settings', style: AppTextStyles.appBarTitle),
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading student profile...',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Student Profile', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // 🔹 PERSONAL INFORMATION SECTION
            _buildSection(
              title: 'Personal Information',
              children: [
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: userName,
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: userEmail,
                ),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: userPhone,
                ),
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Student ID',
                  value: studentId,
                ),
                _buildInfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Region',
                  value: userRegion,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 ADDRESS SECTION
            _buildSection(
              title: 'Address',
              children: [
                _buildInfoTile(
                  icon: Icons.home_outlined,
                  label: 'Home Address',
                  value: userAddress,
                  isMultiline: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 ACCOUNT INFORMATION
            _buildSection(
              title: 'Account Information',
              children: [
                _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Member Since',
                  value: _formatDate(registrationDate),
                ),
                _buildInfoTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Account Status',
                  value: 'Active',
                  valueColor: Colors.green,
                ),
                _buildInfoTile(
                  icon: Icons.school_outlined,
                  label: 'Role',
                  value: 'Student',
                  valueColor: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 NOTIFICATION SETTINGS
            _buildSection(
              title: 'Notification Settings',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  label: 'Push Notifications',
                  subtitle: 'Receive app notifications',
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      notificationsEnabled = val;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 APP SETTINGS (DARK MODE)
            _buildSection(
              title: 'App Settings',
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  subtitle: 'Switch to dark theme',
                  value: darkModeEnabled,
                  onChanged: (val) async {
                    await themeController.toggleTheme(val);
                    setState(() {
                      darkModeEnabled = val;
                    });
                    _showSnackBar('Dark mode ${val ? 'enabled' : 'disabled'}');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 SUPPORT & ABOUT
            _buildSection(
              title: 'Support & About',
              children: [
                _buildActionTile(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {
                    _showSnackBar('Opening help center...');
                  },
                ),
                _buildActionTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () {
                    _showSnackBar('Opening privacy policy...');
                  },
                ),
                _buildActionTile(
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  onTap: () {
                    _showSnackBar('Opening terms & conditions...');
                  },
                ),
                _buildActionTile(
                  icon: Icons.info_outline,
                  label: 'About StudyAlQuran',
                  value: 'Version 1.0.0',
                  onTap: _showAboutDialog,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const SizedBox(height: 40),
            _buildFooter(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 PROFILE HEADER
  // ========================================
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.lightGrey,
                backgroundImage: profileImagePath != null
                    ? FileImage(File(profileImagePath!))
                    : null,
                child: profileImagePath == null
                    ? Icon(Icons.person, size: 60, color: AppColors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changeProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              studentId,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickStat(Icons.school, 'Student'),
              Container(
                width: 1,
                height: 30,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildQuickStat(Icons.location_on, userRegion),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 EDIT PROFILE DIALOG
  // ========================================
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userName);
    final phoneController = TextEditingController(text: userPhone);
    final addressController = TextEditingController(text: userAddress);
    final regionController = TextEditingController(text: userRegion);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: AppTextStyles.heading4),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: regionController,
                decoration: InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userName = nameController.text;
                userPhone = phoneController.text;
                userAddress = addressController.text;
                userRegion = regionController.text;
              });
              _updateStudentProfile();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔥 LOGOUT DIALOG & FUNCTION
  // ========================================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.redPrimary),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: AppTextStyles.heading4.copyWith(color: AppColors.text),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonSecondary.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redPrimary,
            ),
            child: Text('Logout', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      await _auth.signOut();
      if (mounted) Navigator.pop(context);
      _showSnackBar('Logged out successfully!');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Logout error: $e');
      _showSnackBar('Error logging out: $e');
    }
  }

  // ========================================
  // 🔹 UI HELPER METHODS
  // ========================================
  Widget _buildQuickStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.subtitle),
        SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.subtitle, size: 22),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.subtitle,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.subtitle, size: 22),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.subtitle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    String? value,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.subtitle, size: 22),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
              SizedBox(width: 8),
            ],
            Icon(Icons.arrow_forward_ios, color: AppColors.subtitle, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'StudyAlQuran',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Empowering Islamic Education',
          style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _changeProfileImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Profile Picture',
                  style: AppTextStyles.heading4.copyWith(color: AppColors.text),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Take Photo', style: AppTextStyles.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Camera feature coming soon!');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text(
                    'Choose from Gallery',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Gallery feature coming soon!');
                  },
                ),
                if (profileImagePath != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: AppColors.redPrimary),
                    title: Text(
                      'Remove Photo',
                      style: AppTextStyles.bodyMedium,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => profileImagePath = null);
                      _showSnackBar('Profile picture removed');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About StudyAlQuran',
          style: AppTextStyles.heading4.copyWith(color: AppColors.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 60, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Empowering Islamic Education',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTextStyles.buttonSecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}