import 'package:flutter/material.dart';
import 'package:studyalquran/mobile/views/auth/AuthScreen.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 🔥 PAYMENT HISTORY MODEL
class PaymentHistory {
  final String sessionId;
  final String studentName;
  final String date;
  final String time;
  final String status; // 'paid', 'pending', 'processing'
  final DateTime? paymentDate;

  PaymentHistory({
    required this.sessionId,
    required this.studentName,
    required this.date,
    required this.time,
    required this.status,
    this.paymentDate,
  });
}

class TeacherAccountScreen extends StatefulWidget {
  const TeacherAccountScreen({super.key});

  @override
  State<TeacherAccountScreen> createState() => _TeacherAccountScreenState();
}

class _TeacherAccountScreenState extends State<TeacherAccountScreen> {
  // 🔥 FIREBASE INSTANCES
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📊 Teacher Data
  String teacherName = "Loading...";
  String region = "Loading...";
  String zoomLink = "Loading...";
  double walletBalance = 0.0;
  int totalSessionsCompleted = 0;
  int thisMonthSessions = 0;
  String teacherEmail = "Loading...";
  String phoneNumber = "Loading...";
  String teacherId = "Loading...";

  // 🔥 PAYMENT HISTORY
  List<PaymentHistory> paymentHistory = [];
  bool _isLoading = true;
  bool _showPaymentHistory = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherDataFromFirebase();
    _setupRealtimeListeners();
    _loadPaymentHistory();
  }

  // 🔥 LOAD PAYMENT HISTORY
  Future<void> _loadPaymentHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 🔥 ATTENDANCE se sessions load karein
        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('teacherId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(50) // Recent 50 records
            .get();

        List<PaymentHistory> history = [];

        for (var attendanceDoc in attendanceSnapshot.docs) {
          final attendanceData = attendanceDoc.data();
          final studentName = attendanceData['studentName']?.toString() ?? 'Unknown Student';
          final date = attendanceData['date'];
          final status = attendanceData['status']?.toString() ?? 'absent';
          final paymentAmount = (attendanceData['paymentAmount'] ?? 0.0).toDouble();
          
          // 🔥 Only show sessions with payment (present status)
          if (status == 'present' && paymentAmount > 0) {
            String formattedDate = 'Date not available';
            String formattedTime = 'Time not available';
            
            // Format date
            if (date is Timestamp) {
              final dateTime = date.toDate();
              formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
              formattedTime = DateFormat('hh:mm a').format(dateTime);
            } else if (date is DateTime) {
              formattedDate = DateFormat('dd MMM yyyy').format(date);
              formattedTime = DateFormat('hh:mm a').format(date);
            }
            
            // Determine payment status
            final walletProcessed = attendanceData['walletProcessed'] ?? false;
            final paymentStatus = walletProcessed ? 'paid' : 'pending';
            
            history.add(
              PaymentHistory(
                sessionId: attendanceDoc.id,
                studentName: studentName,
                date: formattedDate,
                time: formattedTime,
                status: paymentStatus,
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            paymentHistory = history;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading payment history: $e');
    }
  }

  // 🔥 REAL-TIME LISTENERS SETUP
  void _setupRealtimeListeners() {
    final user = _auth.currentUser;
    if (user != null) {
      // Teacher data real-time listener
      _firestore.collection('teachers').doc(user.uid).snapshots().listen((
        snapshot,
      ) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data()!;
          setState(() {
            walletBalance = (data['walletBalance'] ?? 0.0).toDouble();
            totalSessionsCompleted = (data['classesCompleted'] ?? 0).toInt();
          });
        }
      });

      // This month sessions calculation - real-time
      _calculateThisMonthSessions();
    }
  }

  // 🔥 CALCULATE THIS MONTH SESSIONS - ATTENDANCE SE
  Future<void> _calculateThisMonthSessions() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

        // 🔥 ATTENDANCE collection se calculate karein
        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('teacherId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'present')
            .get();

        int monthSessions = 0;

        for (var doc in attendanceSnapshot.docs) {
          final data = doc.data();
          final date = data['date'];
          
          if (date != null) {
            DateTime? sessionDate;
            
            if (date is Timestamp) {
              sessionDate = date.toDate();
            } else if (date is DateTime) {
              sessionDate = date;
            }
            
            if (sessionDate != null) {
              // Check if session is in current month
              if (sessionDate.year == now.year && sessionDate.month == now.month) {
                monthSessions++;
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            thisMonthSessions = monthSessions;
          });
        }
      }
    } catch (e) {
      print('❌ Error calculating this month sessions: $e');
    }
  }

  // 🔥 FIREBASE: Load teacher data
  Future<void> _loadTeacherDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('👤 Loading teacher data for: ${user.uid}');

        // Load from 'teachers' collection
        final teacherDoc = await _firestore
            .collection('teachers')
            .doc(user.uid)
            .get();

        if (teacherDoc.exists) {
          final data = teacherDoc.data()!;
          setState(() {
            teacherName = data['name']?.toString() ?? 'Teacher Name';
            teacherEmail = data['email']?.toString() ?? user.email ?? 'teacher@studyalquran.com';
            phoneNumber = data['phone']?.toString() ?? 'Not provided';
            region = data['region']?.toString() ?? 'Not specified';
            zoomLink = data['zoomLink']?.toString() ?? 'Not provided';
            walletBalance = (data['walletBalance'] ?? 0.0).toDouble();
            
            // 🔥 CORRECT FIELDS FOR SESSIONS COUNT
            totalSessionsCompleted = (data['classesCompleted'] ?? data['sessionsCompleted'] ?? 0).toInt();
            
            teacherId = data['teacherId']?.toString() ?? 'T-${user.uid.substring(0, 8)}';
          });
        } else {
          // 🔥 IF TEACHER NOT FOUND, CHECK USERS COLLECTION
          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            setState(() {
              teacherName = userData['name']?.toString() ?? 'Teacher User';
              teacherEmail = userData['email']?.toString() ?? user.email ?? 'teacher@studyalquran.com';
              phoneNumber = userData['phone']?.toString() ?? 'Not provided';
              region = userData['region']?.toString() ?? 'Not specified';
              zoomLink = 'Not provided';
              walletBalance = 0.0;
              totalSessionsCompleted = 0;
              teacherId = 'T-${user.uid.substring(0, 8)}';
            });
          } else {
            // 🔥 IF NO DATA FOUND, USE AUTH DATA
            setState(() {
              teacherName = 'Teacher User';
              teacherEmail = user.email ?? 'teacher@studyalquran.com';
              phoneNumber = 'Not provided';
              region = 'Not specified';
              zoomLink = 'Not provided';
              walletBalance = 0.0;
              totalSessionsCompleted = 0;
              teacherId = 'T-${user.uid.substring(0, 8)}';
            });
          }
        }

        // 🔥 RECALCULATE TOTAL SESSIONS FROM ATTENDANCE
        await _recalculateTotalSessions();
      }

      setState(() => _isLoading = false);
      print('✅ Teacher data loaded successfully!');
      print('💰 Wallet Balance: $walletBalance');
      print('📊 Total Sessions: $totalSessionsCompleted');
      print('📅 This Month Sessions: $thisMonthSessions');
    } catch (e) {
      print('❌ Error loading teacher data: $e');
      setState(() => _isLoading = false);
      _showSnackBar(context, 'Error loading profile data');
    }
  }

  // 🔥 RECALCULATE TOTAL SESSIONS FROM ATTENDANCE
  Future<void> _recalculateTotalSessions() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 🔥 ATTENDANCE se completed sessions count karein
        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('teacherId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'present')
            .get();

        int totalSessions = attendanceSnapshot.docs.length;

        // 🔥 Update teacher document with correct count
        await _firestore.collection('teachers').doc(user.uid).set({
          'classesCompleted': totalSessions,
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            totalSessionsCompleted = totalSessions;
          });
        }

        print('🔄 Recalculated total sessions: $totalSessions');
      }
    } catch (e) {
      print('❌ Error recalculating sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('My Account', style: AppTextStyles.appBarTitle),
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
                'Loading teacher profile...',
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
        title: Text('My Account', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 TOP PROFILE SECTION
            _buildProfileSection(),

            const SizedBox(height: 20),

            // 🔹 WALLET SUMMARY SECTION
            _buildWalletSection(),

            const SizedBox(height: 20),

            // 🔹 STATISTICS CARDS
            _buildStatisticsSection(),

            const SizedBox(height: 20),

            // 🔹 PAYMENT HISTORY SECTION
            _buildPaymentHistorySection(),

            const SizedBox(height: 20),

            // 🔹 ZOOM LINK SECTION
            _buildZoomLinkSection(),

            const SizedBox(height: 20),

            // 🔹 TEACHER ID SECTION
            _buildTeacherIdSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 PAYMENT HISTORY SECTION
  // ========================================
  Widget _buildPaymentHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payment, color: AppColors.primary, size: 24),
              ),
              title: Text(
                'Payment History',
                style: AppTextStyles.cardTitle.copyWith(color: AppColors.text),
              ),
              trailing: IconButton(
                icon: Icon(
                  _showPaymentHistory ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _showPaymentHistory = !_showPaymentHistory;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _showPaymentHistory = !_showPaymentHistory;
                });
              },
            ),

            // Payment History List
            if (_showPaymentHistory) ...[
              const Divider(height: 1),
              if (paymentHistory.isEmpty) _buildEmptyPaymentState(),
              if (paymentHistory.isNotEmpty) _buildPaymentHistoryList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryList() {
    return Container(
      constraints: BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: paymentHistory.length,
        itemBuilder: (context, index) {
          final payment = paymentHistory[index];
          return _buildPaymentHistoryItem(payment);
        },
      ),
    );
  }

  Widget _buildPaymentHistoryItem(PaymentHistory payment) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pending;

    switch (payment.status) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),

          // Payment Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.studentName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.subtitle,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${payment.date} • ${payment.time}',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.subtitle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              payment.status.toUpperCase(),
              style: AppTextStyles.captionText.copyWith(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPaymentState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.payment,
            size: 50,
            color: AppColors.subtitle.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No Payment History',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 6),
          Text(
            'Completed sessions will appear here',
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 PROFILE SECTION
  // ========================================
  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.gradient],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.white,
            child: Icon(Icons.person, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 15),

          // Teacher Name
          Text(
            teacherName,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),

          // Region
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.white.withOpacity(0.9),
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                region,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Contact Info
          _buildContactChip(Icons.email, teacherEmail),
          const SizedBox(height: 8),
          _buildContactChip(Icons.phone, phoneNumber),
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 WALLET SECTION
  // ========================================
  Widget _buildWalletSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Earnings',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'USD ${walletBalance.toStringAsFixed(2)}',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on $totalSessionsCompleted completed sessions',
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
            const SizedBox(height: 20),

            // Request Payout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: walletBalance > 0
                    ? () {
                        _showRequestPayoutDialog(context);
                      }
                    : null,
                icon: const Icon(Icons.payment),
                label: Text(
                  walletBalance > 0 ? 'Request Payout' : 'No Balance Available',
                  style: AppTextStyles.buttonPrimary,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: walletBalance > 0
                      ? AppColors.primary
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 STATISTICS SECTION
  // ========================================
  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.access_time,
              title: 'Total Sessions',
              value: totalSessionsCompleted.toString(),
              color: AppColors.primary,
              subtitle: 'All completed classes',
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              title: 'This Month',
              value: thisMonthSessions.toString(),
              color: AppColors.opposite,
              subtitle: DateFormat('MMM yyyy').format(DateTime.now()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.subtitle,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 ZOOM LINK SECTION
  // ========================================
  Widget _buildZoomLinkSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.video_call, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'My Zoom Link',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.text,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primary, size: 20),
                  onPressed: () => _showEditZoomLinkDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      zoomLink,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: AppColors.primary, size: 20),
                    onPressed: () {
                      // Copy to clipboard
                      _showSnackBar(context, 'Zoom link copied!');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 TEACHER ID SECTION
  // ========================================
  Widget _buildTeacherIdSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.badge, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher ID',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacherId,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 DIALOGS
  // ========================================
  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: teacherName);
    final phoneController = TextEditingController(text: phoneNumber);
    final regionController = TextEditingController(text: region);

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
              _updateTeacherProfile({
                'name': nameController.text,
                'phone': phoneController.text,
                'region': regionController.text,
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showEditZoomLinkDialog(BuildContext context) {
    final zoomController = TextEditingController(text: zoomLink);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Zoom Link', style: AppTextStyles.heading4),
        content: TextField(
          controller: zoomController,
          decoration: InputDecoration(
            labelText: 'Zoom Meeting Link',
            hintText: 'https://zoom.us/j/...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateTeacherProfile({'zoomLink': zoomController.text});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Update Link'),
          ),
        ],
      ),
    );
  }

  void _showRequestPayoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Payout', style: AppTextStyles.heading4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 60,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Available Balance: USD ${walletBalance.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Based on $totalSessionsCompleted completed sessions',
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your payout request will be processed within 3-5 business days.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, 'Payout request submitted successfully!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Request Payout'),
          ),
        ],
      ),
    );
  }

  // 🔥 FIREBASE: Update teacher profile
  Future<void> _updateTeacherProfile(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('teachers').doc(user.uid).set({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showSnackBar(context, 'Profile updated successfully!');
        _loadTeacherDataFromFirebase(); // Reload data
      }
    } catch (e) {
      _showSnackBar(context, 'Error updating profile: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
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