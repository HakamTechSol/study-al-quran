import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:studyalquran/web_admin/screens/admin_login.dart';
import 'package:studyalquran/web_admin/screens/help&support.dart';
import 'package:studyalquran/web_admin/screens/invoice.dart';
import 'package:studyalquran/web_admin/screens/package.dart';
import 'package:studyalquran/web_admin/screens/report_attendence.dart';
import 'package:studyalquran/web_admin/screens/schedule.dart';
import 'package:studyalquran/web_admin/screens/setting.dart';
import 'package:studyalquran/web_admin/screens/students.dart';
import 'package:studyalquran/web_admin/screens/teacher.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current Admin User
  User? _currentUser;
  Map<String, dynamic> _adminData = {};

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  // 🔥 GET CURRENT LOGGED IN ADMIN USER
  void _getCurrentUser() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _fetchAdminData();
    }
  }

  // 🔥 FETCH ADMIN DATA FROM FIRESTORE
  void _fetchAdminData() async {
    try {
      if (_currentUser != null) {
        DocumentSnapshot adminSnapshot = await _firestore
            .collection('admins')
            .doc(_currentUser!.uid)
            .get();

        if (adminSnapshot.exists) {
          setState(() {
            _adminData = adminSnapshot.data() as Map<String, dynamic>;
          });
        } else {
          // Agar admin collection mein nahi hai, toh users collection check karo
          DocumentSnapshot userSnapshot = await _firestore
              .collection('users')
              .doc(_currentUser!.uid)
              .get();

          if (userSnapshot.exists) {
            setState(() {
              _adminData = userSnapshot.data() as Map<String, dynamic>;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching admin data: $e');
    }
  }

  // 🔥 LOGOUT FUNCTION - UPDATED
  void _logout() async {
    try {
      await _auth.signOut();
      // Logout ke baad AdminLoginScreen pe navigate karo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminLoginScreen()),
      );
    } catch (e) {
      print('Logout error: $e');
      // Error handling - show dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logout Error'),
          content: Text('Could not logout. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // 🔥 SHOW LOGOUT CONFIRMATION DIALOG
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // 🔥 REAL-TIME DATA STREAMS
  Stream<int> getTotalTeachersStream() {
    return _firestore
        .collection('teachers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalStudentsStream() {
    return _firestore
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getActivePackagesStream() {
    return _firestore
        .collection('packages')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<double> getPendingInvoicesAmountStream() {
    return _firestore
        .collection('invoices')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          double total = 0;
          for (var doc in snapshot.docs) {
            total += (doc.data()['amount'] ?? 0).toDouble();
          }
          return total;
        });
  }

  Stream<int> getPendingInvoicesCountStream() {
    return _firestore
        .collection('invoices')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // 🔥 TODAY'S SCHEDULE STREAM - ORDERBY REMOVED
  Stream<QuerySnapshot> getTodayScheduleStream() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _firestore
        .collection('schedules')
        .where('date', isEqualTo: today)
        .snapshots(); // ORDERBY REMOVED - TIME FORMAT ISSUE
  }

  // 🔥 RECENT ACTIVITIES STREAM
  Stream<QuerySnapshot> getRecentActivitiesStream() {
    return _firestore
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildPageContent()),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const TeachersManagementScreen();
      case 2:
        return const StudentsManagementScreen();
      case 3:
        return const ScheduleManagementScreen();
      case 4:
        return const InvoicesManagementScreen();
      case 5:
        return const PackagesManagementScreen();
      case 6:
        return const ReportsAttendanceScreen();
      case 7:
        return const AdminSettingsScreen();
      case 8:
        return const HelpAndSupportsScreen();
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.gradient],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: AppColors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StudyAlQuran',
                        style: AppTextStyles.heading6.copyWith(
                          color: AppColors.text,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Admin Portal',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.subtitle,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.person_outline, 'Teachers'),
                _buildNavItem(2, Icons.school_outlined, 'Students'),
                _buildNavItem(3, Icons.calendar_today_outlined, 'Schedule'),

                _buildNavItem(4, Icons.receipt_long_outlined, 'Invoices'),
                _buildNavItem(5, Icons.insert_emoticon, 'Packages'),
                _buildNavItem(
                  6,
                  Icons.assessment_outlined,
                  'Reports & Attendance',
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: AppColors.border),
                ),
                const SizedBox(height: 8),
                _buildNavItem(7, Icons.settings_outlined, 'Settings'),
                _buildNavItem(8, Icons.help_outline, 'Help & Support'),
              ],
            ),
          ),

          // 🔥 UPDATED USER PROFILE SECTION WITH REAL DATA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _adminData['name']?.toString() ??
                            _currentUser?.displayName ??
                            'Admin User',
                        style: AppTextStyles.labelText.copyWith(
                          color: AppColors.text,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _currentUser?.email ??
                            _adminData['email']?.toString() ??
                            'admin@studyalquran.com',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.subtitle,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // User ID show karo (debugging ke liye)
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: AppColors.error, size: 20),
                  onPressed: _showLogoutConfirmation,
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.subtitle,
          size: 22,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.text,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        onTap: () {
          setState(() => selectedIndex = index);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDashboardOverview() {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Admin Welcome
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.text,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, ${_adminData['name']?.toString() ?? 'Admin'}!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.subtitle,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Statistics Cards with REAL DATA
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Stats Row with StreamBuilders
                  Row(
                    children: [
                      Expanded(
                        child: _buildRealTimeStatCard(
                          'Total Teachers',
                          getTotalTeachersStream(),
                          Icons.person_outline,
                          AppColors.primary,
                          'All registered teachers',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRealTimeStatCard(
                          'Total Students',
                          getTotalStudentsStream(),
                          Icons.school_outlined,
                          const Color(0xFF8B5CF6),
                          'All enrolled students',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRealTimeStatCard(
                          'Active Packages',
                          getActivePackagesStream(),
                          Icons.inventory_2_outlined,
                          const Color(0xFF14B8A6),
                          'Currently active',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRealTimePendingInvoicesCard()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Today's Classes & Recent Activities
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's Schedule with REAL DATA
                      Expanded(flex: 2, child: _buildRealTimeTodaySchedule()),
                      const SizedBox(width: 16),
                      // Recent Activities with REAL DATA
                      Expanded(
                        flex: 1,
                        child: _buildRealTimeRecentActivities(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 REAL-TIME STAT CARD
  Widget _buildRealTimeStatCard(
    String title,
    Stream<int> stream,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return _buildStatCard(
          title,
          isLoading ? '...' : value.toString(),
          icon,
          color,
          subtitle,
          isLoading: isLoading,
        );
      },
    );
  }

  // 🔥 REAL-TIME PENDING INVOICES CARD
  Widget _buildRealTimePendingInvoicesCard() {
    return StreamBuilder<double>(
      stream: getPendingInvoicesAmountStream(),
      builder: (context, amountSnapshot) {
        return StreamBuilder<int>(
          stream: getPendingInvoicesCountStream(),
          builder: (context, countSnapshot) {
            final amount = amountSnapshot.data ?? 0;
            final count = countSnapshot.data ?? 0;
            final isLoading =
                amountSnapshot.connectionState == ConnectionState.waiting ||
                countSnapshot.connectionState == ConnectionState.waiting;

            return _buildStatCard(
              'Pending Invoices',
              isLoading ? '...' : 'USD ${amount.toStringAsFixed(0)}',
              Icons.receipt_long_outlined,
              const Color(0xFFEF4444),
              '$count invoices due',
              isLoading: isLoading,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle, {
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(Icons.arrow_forward, color: AppColors.subtitle, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.subtitle,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.captionText.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 REAL-TIME TODAY'S SCHEDULE - UPDATED
  Widget _buildRealTimeTodaySchedule() {
    return StreamBuilder<QuerySnapshot>(
      stream: getTodayScheduleStream(),
      builder: (context, snapshot) {
        // 🔥 DEBUG CODE
        if (snapshot.hasData) {
          print(
            '🔥 Schedule Data Found: ${snapshot.data!.docs.length} documents',
          );
          for (var doc in snapshot.data!.docs) {
            print('📅 Schedule: ${doc.data()}');
          }
        }
        if (snapshot.hasError) {
          print('❌ Schedule Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildScheduleLoading();
        }

        if (snapshot.hasError) {
          return _buildScheduleError();
        }

        final schedules = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Scheduled Classes',
                    style: AppTextStyles.heading5.copyWith(
                      color: AppColors.text,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => selectedIndex = 3);
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.buttonSecondary.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (schedules.isEmpty)
                _buildEmptySchedule()
              else
                ...schedules.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildRealTimeScheduleItem(data);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRealTimeScheduleItem(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.access_time, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['subject']?.toString() ?? 'No Subject',
                  style: AppTextStyles.labelText.copyWith(
                    color: AppColors.text,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('teachers')
                      .doc(data['teacherId'])
                      .get(),
                  builder: (context, teacherSnapshot) {
                    final teacherName =
                        teacherSnapshot.data?['name'] ?? 'Unknown Teacher';
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('students')
                          .doc(data['studentId'])
                          .get(),
                      builder: (context, studentSnapshot) {
                        final studentName =
                            studentSnapshot.data?['name'] ?? 'Unknown Student';
                        return Text(
                          '$teacherName → $studentName',
                          style: AppTextStyles.captionText.copyWith(
                            color: AppColors.subtitle,
                            fontSize: 11,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Text(
            data['time']?.toString() ?? '--:--',
            style: AppTextStyles.labelText.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleLoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Scheduled Classes',
            style: AppTextStyles.heading5.copyWith(
              color: AppColors.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildScheduleError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Scheduled Classes',
            style: AppTextStyles.heading5.copyWith(
              color: AppColors.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Error loading schedule',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.calendar_today, color: AppColors.subtitle, size: 48),
          const SizedBox(height: 12),
          Text(
            'No classes scheduled for today',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  // 🔥 REAL-TIME RECENT ACTIVITIES
  Widget _buildRealTimeRecentActivities() {
    return StreamBuilder<QuerySnapshot>(
      stream: getRecentActivitiesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildActivitiesLoading();
        }

        if (snapshot.hasError) {
          return _buildActivitiesError();
        }

        final activities = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Activities',
                style: AppTextStyles.heading5.copyWith(
                  color: AppColors.text,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              if (activities.isEmpty)
                _buildEmptyActivities()
              else
                ...activities.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildRealTimeActivityItem(data);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRealTimeActivityItem(Map<String, dynamic> data) {
    IconData getActivityIcon(String type) {
      switch (type) {
        case 'teacher_registered':
          return Icons.person_add;
        case 'invoice_paid':
          return Icons.payment;
        case 'class_scheduled':
          return Icons.calendar_month;
        case 'student_enrolled':
          return Icons.school;
        default:
          return Icons.notifications;
      }
    }

    String formatTimestamp(Timestamp timestamp) {
      final now = DateTime.now();
      final time = timestamp.toDate();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      return '${difference.inDays} days ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            getActivityIcon(data['type'] ?? ''),
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['message']?.toString() ?? 'Activity',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.text,
                    fontSize: 12,
                  ),
                ),
                Text(
                  formatTimestamp(data['timestamp'] ?? Timestamp.now()),
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.subtitle,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesLoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: AppTextStyles.heading5.copyWith(
              color: AppColors.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildActivitiesError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: AppTextStyles.heading5.copyWith(
              color: AppColors.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Error loading activities',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.notifications_none, color: AppColors.subtitle, size: 48),
          const SizedBox(height: 12),
          Text(
            'No recent activities',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.heading5.copyWith(
              color: AppColors.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedIndex = 1),
                  child: _buildQuickActionButton(
                    'Add Teacher',
                    Icons.person_add,
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedIndex = 2),
                  child: _buildQuickActionButton(
                    'Add Student',
                    Icons.school,
                    const Color(0xFF8B5CF6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedIndex = 4),
                  child: _buildQuickActionButton(
                    'Create Invoice',
                    Icons.receipt,
                    const Color(0xFF14B8A6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedIndex = 3),
                  child: _buildQuickActionButton(
                    'Schedule Class',
                    Icons.calendar_month,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelText.copyWith(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPages(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: AppColors.subtitle),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.heading4.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'This page is under development',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }
}
