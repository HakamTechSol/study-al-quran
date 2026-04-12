import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 📦 Package Model
class Package {
  final String id;
  final String name;
  final int totalSessions;
  final int completedSessions;
  final int upcomingSessions;
  final int missedSessions;
  final int remainingSessions;
  final DateTime startDate;
  final DateTime expiryDate;
  final double price;
  final PackageStatus status;
  final String assignmentId;

  Package({
    required this.id,
    required this.name,
    required this.totalSessions,
    required this.completedSessions,
    required this.upcomingSessions,
    required this.missedSessions,
    required this.remainingSessions,
    required this.startDate,
    required this.expiryDate,
    required this.price,
    required this.status,
    required this.assignmentId,
  });

  double get progressPercentage => totalSessions > 0
      ? (completedSessions / totalSessions * 100).clamp(0, 100)
      : 0;

  factory Package.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime startDate = DateTime.now();
    DateTime expiryDate = DateTime.now();

    try {
      if (data['startDate'] != null) {
        startDate = (data['startDate'] as Timestamp).toDate();
      }
      if (data['endDate'] != null) {
        expiryDate = (data['endDate'] as Timestamp).toDate();
      }
    } catch (e) {
      print('📅 Date parsing error: $e');
    }

    PackageStatus status = _determinePackageStatus(expiryDate, data['status']);
    int totalSessions = (data['numberOfClasses'] ?? 0).toInt();
    int completedSessions = (data['completedClasses'] ?? 0).toInt();
    
    // Calculate remaining sessions
    int usedSessions = completedSessions;
    int remainingSessions = totalSessions - usedSessions;
    if (remainingSessions < 0) remainingSessions = 0;

    return Package(
      id: data['packageId'] ?? doc.id,
      name: data['packageName'] ?? 'Unknown Package',
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      upcomingSessions: 0, // Will be calculated in getPackagesStream
      missedSessions: 0,   // Will be calculated in getPackagesStream
      remainingSessions: remainingSessions,
      startDate: startDate,
      expiryDate: expiryDate,
      price: (data['price'] ?? 0).toDouble(),
      status: status,
      assignmentId: doc.id,
    );
  }

  static PackageStatus _determinePackageStatus(
    DateTime expiryDate,
    String? status,
  ) {
    if (status == 'expired' || status == 'completed' || status == 'cancelled') {
      return PackageStatus.expired;
    }
    if (status == 'pending') return PackageStatus.pending;

    DateTime now = DateTime.now();
    if (expiryDate.isBefore(now)) return PackageStatus.expired;
    return PackageStatus.active;
  }
}

// 📄 Invoice Model
class Invoice {
  final String id;
  final String packageName;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final InvoiceStatus status;
  final String? packageId;

  Invoice({
    required this.id,
    required this.packageName,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.packageId,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc, String packageName) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime dueDate = DateTime.now();
    DateTime? paidDate;

    try {
      if (data['dueDate'] != null) {
        dueDate = (data['dueDate'] as Timestamp).toDate();
      }
      if (data['paidDate'] != null) {
        paidDate = (data['paidDate'] as Timestamp).toDate();
      }
    } catch (e) {
      print('📅 Invoice date parsing error: $e');
    }

    InvoiceStatus status = _determineInvoiceStatus(dueDate, data['status']);

    return Invoice(
      id: doc.id,
      packageName: packageName,
      amount: (data['amount'] ?? 0).toDouble(),
      dueDate: dueDate,
      paidDate: paidDate,
      status: status,
      packageId: data['packageId']?.toString(),
    );
  }

  static InvoiceStatus _determineInvoiceStatus(
    DateTime dueDate,
    String? status,
  ) {
    if (status == 'paid') return InvoiceStatus.paid;
    if (status == 'overdue') return InvoiceStatus.overdue;

    DateTime now = DateTime.now();
    if (dueDate.isBefore(now) && status != 'paid') return InvoiceStatus.overdue;
    return InvoiceStatus.pending;
  }
}

// 🎯 Status Enums
enum PackageStatus { active, expired, pending }

enum InvoiceStatus { paid, pending, overdue }

class PackagesInvoicesScreen extends StatefulWidget {
  const PackagesInvoicesScreen({super.key});

  @override
  State<PackagesInvoicesScreen> createState() => _PackagesInvoicesScreenState();
}

class _PackagesInvoicesScreenState extends State<PackagesInvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _canRequestPackageChange = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPackageChangePermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🔒 Check if student can request package changes
  Future<void> _checkPackageChangePermission() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final studentDoc = await _firestore
            .collection('students')
            .doc(user.uid)
            .get();
        if (studentDoc.exists) {
          setState(() {
            _canRequestPackageChange =
                studentDoc.data()?['canRequestPackageChange'] ?? true;
          });
        }
      }
    } catch (e) {
      print('❌ Error checking permission: $e');
    }
  }

 // 📦 Get Packages Stream (Real-time) - UPDATED
Stream<List<Package>> getPackagesStream() {
  final user = _auth.currentUser;
  if (user == null) return Stream.value([]);

  return _firestore
      .collection('packageAssignments')
      .where('studentId', isEqualTo: user.uid)
      .snapshots()
      .asyncMap((snapshot) async {
        List<Package> packages = [];

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data();

          DateTime startDate = DateTime.now();
          DateTime expiryDate = DateTime.now();

          try {
            if (data['startDate'] != null) {
              startDate = (data['startDate'] as Timestamp).toDate();
            }
            if (data['endDate'] != null) {
              expiryDate = (data['endDate'] as Timestamp).toDate();
            }
          } catch (e) {
            print('📅 Date parsing error: $e');
          }

          // 🔥 GET ALL CLASSES COUNT FROM SCHEDULES - PROPERLY
          final classCounts = await _getClassCountsFromSchedules(doc.id, user.uid);
          
          int totalSessions = (data['numberOfClasses'] ?? 0).toInt();
          int completedSessions = classCounts['completed'] ?? 0;
          int upcomingSessions = classCounts['upcoming'] ?? 0;
          int missedSessions = classCounts['missed'] ?? 0;
          
          // 🔥 PROPER CALCULATION: Total used = completed + upcoming + missed
          int usedSessions = completedSessions + upcomingSessions + missedSessions;
          int remainingSessions = totalSessions - usedSessions;
          
          // For expired packages, force remaining to 0
          PackageStatus status = _determinePackageStatus(expiryDate, data['status']);
          if (status == PackageStatus.expired) {
            remainingSessions = 0;
          }
          
          // Ensure remaining doesn't go negative
          if (remainingSessions < 0) {
            remainingSessions = 0;
          }

          packages.add(
            Package(
              id: data['packageId'] ?? doc.id,
              name: data['packageName'] ?? 'Unknown Package',
              totalSessions: totalSessions,
              completedSessions: completedSessions,
              upcomingSessions: upcomingSessions,
              missedSessions: missedSessions,
              remainingSessions: remainingSessions,
              startDate: startDate,
              expiryDate: expiryDate,
              price: (data['price'] ?? 0).toDouble(),
              status: status,
              assignmentId: doc.id,
            ),
          );
        }

        packages.sort((a, b) => b.startDate.compareTo(a.startDate));
        return packages;
      });
}
  // 🔥 GET CLASS COUNTS FROM SCHEDULES (completed, upcoming, missed)
  Future<Map<String, int>> _getClassCountsFromSchedules(String assignmentId, String studentId) async {
    try {
      print('🔄 Fetching class counts for assignment: $assignmentId');
      
      // Get all schedules for this package assignment
      var schedulesQuery = await _firestore
          .collection('schedules')
          .where('studentId', isEqualTo: studentId)
          .where('packageId', isEqualTo: assignmentId)
          .get();
      
      int completedCount = 0;
      int upcomingCount = 0;
      int missedCount = 0;
      DateTime now = DateTime.now();
      
      for (var doc in schedulesQuery.docs) {
        var data = doc.data();
        String status = data['status']?.toString().toLowerCase() ?? '';
        DateTime? scheduleTime = _parseScheduleTime(data['date'], data['time']);
        
        if (status == 'completed') {
          completedCount++;
        } else if (status == 'cancelled' || status == 'missed') {
          missedCount++;
        } else if (scheduleTime != null) {
          // Determine if upcoming or missed based on time
          if (scheduleTime.isAfter(now)) {
            upcomingCount++;
          } else {
            missedCount++;
          }
        } else {
          // If no time, count as upcoming
          upcomingCount++;
        }
      }
      
      print('✅ Class counts - Completed: $completedCount, Upcoming: $upcomingCount, Missed: $missedCount');
      
      return {
        'completed': completedCount,
        'upcoming': upcomingCount,
        'missed': missedCount,
      };
    } catch (e) {
      print('❌ Error getting class counts: $e');
      return {'completed': 0, 'upcoming': 0, 'missed': 0};
    }
  }

  // 🔥 PARSE SCHEDULE TIME FROM DATE AND TIME STRINGS
  DateTime? _parseScheduleTime(String? dateStr, String? timeStr) {
    try {
      if (dateStr == null || timeStr == null) return null;
      
      if (timeStr.toUpperCase().contains('AM') || timeStr.toUpperCase().contains('PM')) {
        return DateFormat('yyyy-MM-dd h:mm a').parse('$dateStr $timeStr');
      } else {
        return DateFormat('yyyy-MM-dd HH:mm').parse('$dateStr $timeStr');
      }
    } catch (e) {
      print('❌ Error parsing schedule time: $e');
      return null;
    }
  }

  // 🔥 DETERMINE PACKAGE STATUS
  PackageStatus _determinePackageStatus(DateTime expiryDate, String? status) {
    if (status == 'expired' || status == 'completed' || status == 'cancelled') {
      return PackageStatus.expired;
    }
    if (status == 'pending') return PackageStatus.pending;

    DateTime now = DateTime.now();
    if (expiryDate.isBefore(now)) return PackageStatus.expired;
    return PackageStatus.active;
  }

  // 💰 Get Invoices Stream (Real-time)
  Stream<List<Invoice>> getInvoicesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('invoices')
        .where('studentId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Invoice> invoices = [];

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data();

            // 🔥 PACKAGE NAME FETCH KARNE KA PROPER METHOD
            String packageName = await _getPackageNameForInvoice(data);

            DateTime dueDate = DateTime.now();
            DateTime? paidDate;

            try {
              if (data['dueDate'] != null) {
                dueDate = (data['dueDate'] as Timestamp).toDate();
              }
              if (data['paidDate'] != null) {
                paidDate = (data['paidDate'] as Timestamp).toDate();
              }
            } catch (e) {
              print('📅 Invoice date parsing error: $e');
            }

            InvoiceStatus status = _determineInvoiceStatus(
              dueDate,
              data['status'],
            );

            invoices.add(
              Invoice(
                id: doc.id,
                packageName: packageName,
                amount: (data['amount'] ?? 0).toDouble(),
                dueDate: dueDate,
                paidDate: paidDate,
                status: status,
                packageId: data['packageId']?.toString(),
              ),
            );
          }

          invoices.sort((a, b) => b.dueDate.compareTo(a.dueDate));
          return invoices;
        });
  }

  // 🔥 PACKAGE NAME FETCH KARNE KA MAIN METHOD
  Future<String> _getPackageNameForInvoice(
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      // Pehle direct fields check karein
      if (invoiceData['packageName'] != null &&
          invoiceData['packageName'].toString().isNotEmpty) {
        return invoiceData['packageName'].toString();
      }

      if (invoiceData['package'] != null &&
          invoiceData['package'].toString().isNotEmpty) {
        return invoiceData['package'].toString();
      }

      // Agar packageId hai toh packages collection se fetch karein
      if (invoiceData['packageId'] != null &&
          invoiceData['packageId'].toString().isNotEmpty) {
        final packageId = invoiceData['packageId'].toString();
        final packageDoc = await _firestore
            .collection('packages')
            .doc(packageId)
            .get();

        if (packageDoc.exists) {
          final packageData = packageDoc.data();
          return packageData?['name'] ?? 'Package #$packageId';
        }
      }

      // Agar packageAssignmentId hai toh packageAssignments se fetch karein
      if (invoiceData['packageAssignmentId'] != null &&
          invoiceData['packageAssignmentId'].toString().isNotEmpty) {
        final assignmentId = invoiceData['packageAssignmentId'].toString();
        final assignmentDoc = await _firestore
            .collection('packageAssignments')
            .doc(assignmentId)
            .get();

        if (assignmentDoc.exists) {
          final assignmentData = assignmentDoc.data();
          return assignmentData?['packageName'] ?? 'Assigned Package';
        }
      }

      // Last option: student ke current package se
      final user = _auth.currentUser;
      if (user != null) {
        final studentDoc = await _firestore
            .collection('students')
            .doc(user.uid)
            .get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data();
          return studentData?['currentPackage'] ?? 'General Package';
        }
      }

      return 'Package';
    } catch (e) {
      print('❌ Error fetching package name: $e');
      return 'Package';
    }
  }

  // 🔥 INVOICE STATUS DETERMINE METHOD
  InvoiceStatus _determineInvoiceStatus(DateTime dueDate, String? status) {
    if (status == 'paid') return InvoiceStatus.paid;
    if (status == 'overdue') return InvoiceStatus.overdue;

    DateTime now = DateTime.now();
    if (dueDate.isBefore(now) && status != 'paid') return InvoiceStatus.overdue;
    return InvoiceStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Packages & Invoices', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.tabLabel.copyWith(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: AppTextStyles.tabLabel.copyWith(
            color: AppColors.white.withOpacity(0.7),
            fontSize: 15,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.card_giftcard), text: 'My Packages'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Invoices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPackagesTab(), _buildInvoicesTab()],
      ),
      floatingActionButton: _canRequestPackageChange
          ? FloatingActionButton.extended(
              onPressed: _showPackageChangeRequest,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.swap_horiz),
              label: Text('Request Change', style: AppTextStyles.buttonPrimary),
            )
          : null,
    );
  }

  // ========================================
  // 📦 PACKAGES TAB
  // ========================================
  Widget _buildPackagesTab() {
    return StreamBuilder<List<Package>>(
      stream: getPackagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState('Loading packages...');
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Error loading packages',
            snapshot.error.toString(),
          );
        }

        final packages = snapshot.data ?? [];

        if (packages.isEmpty) {
          return _buildEmptyPackagesState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSummaryCard(packages),
              );
            }
            return _buildPackageCard(packages[index - 1]);
          },
        );
      },
    );
  }

  // 📊 Summary Card
  Widget _buildSummaryCard(List<Package> packages) {
    int totalActive = packages
        .where((p) => p.status == PackageStatus.active)
        .length;
    int totalCompleted = packages.fold(
      0,
      (sum, p) => sum + p.completedSessions,
    );
    int totalRemaining = packages.fold(
      0,
      (sum, p) => sum + p.remainingSessions,
    );
    int totalUpcoming = packages.fold(
      0,
      (sum, p) => sum + p.upcomingSessions,
    );
    int totalMissed = packages.fold(
      0,
      (sum, p) => sum + p.missedSessions,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.opposite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Package Summary',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.check_circle,
                label: 'Completed',
                value: '$totalCompleted',
              ),
              _buildSummaryItem(
                icon: Icons.schedule,
                label: 'Upcoming',
                value: '$totalUpcoming',
              ),
              _buildSummaryItem(
                icon: Icons.pending_actions,
                label: 'Remaining',
                value: '$totalRemaining',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.cancel,
                label: 'Missed',
                value: '$totalMissed',
              ),
              _buildSummaryItem(
                icon: Icons.card_giftcard,
                label: 'Active',
                value: '$totalActive',
              ),
              Container(width: 80), // Spacer
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.captionText.copyWith(
            color: AppColors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // 📦 Package Card
  Widget _buildPackageCard(Package package) {
    Color statusColor = _getPackageStatusColor(package.status);
    IconData statusIcon = _getPackageStatusIcon(package.status);
    bool isActive = package.status == PackageStatus.active;
    bool isExpired = package.status == PackageStatus.expired;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? AppColors.redPrimary.withOpacity(0.5)
              : statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _getPackageStatusText(package.status),
                            style: AppTextStyles.captionText.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'USD',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.subtitle,
                      ),
                    ),
                    Text(
                      package.price.toStringAsFixed(0),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Classes Info - FIRST ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildClassInfoItem(
                        icon: Icons.dashboard,
                        label: 'Total Classes',
                        value: '${package.totalSessions}',
                        color: AppColors.primary,
                      ),
                    ),
                    Container(width: 1, height: 50, color: AppColors.border),
                    Expanded(
                      child: _buildClassInfoItem(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: '${package.completedSessions}',
                        color: Colors.green,
                      ),
                    ),
                    Container(width: 1, height: 50, color: AppColors.border),
                    Expanded(
                      child: _buildClassInfoItem(
                        icon: Icons.schedule,
                        label: 'Upcoming',
                        value: '${package.upcomingSessions}',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Classes Info - SECOND ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildClassInfoItem(
                        icon: Icons.cancel,
                        label: 'Missed',
                        value: '${package.missedSessions}',
                        color: AppColors.redPrimary,
                      ),
                    ),
                    Container(width: 1, height: 50, color: AppColors.border),
                    // FIX: Only show Remaining field for non-expired packages
                    if (!isExpired) ...[
                      Expanded(
                        child: _buildClassInfoItem(
                          icon: Icons.pending,
                          label: 'Remaining',
                          value: '${package.remainingSessions}',
                          color: AppColors.opposite,
                        ),
                      ),
                      Container(width: 1, height: 50, color: AppColors.border),
                    ],
                    Expanded(
                      child: _buildClassInfoItem(
                        icon: Icons.assignment_turned_in,
                        label: 'Used',
                        value: '${package.completedSessions + package.upcomingSessions + package.missedSessions}',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),

                if (isActive && package.totalSessions > 0) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${package.progressPercentage.toStringAsFixed(0)}%',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: package.progressPercentage / 100,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 10,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _buildDateItem(
                        icon: Icons.event,
                        label: 'Start Date',
                        date: _formatDate(package.startDate),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateItem(
                        icon: isExpired
                            ? Icons.event_busy
                            : Icons.event_available,
                        label: isExpired ? 'Expired On' : 'Valid Until',
                        date: _formatDate(package.expiryDate),
                        color: isExpired ? AppColors.redPrimary : Colors.green,
                      ),
                    ),
                  ],
                ),

                // FIX: Remaining Sessions Info - Only show for active/pending packages
                if (!isExpired && package.remainingSessions > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${package.remainingSessions} classes remaining in this package',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // FIX: Only show "All classes have been scheduled" for active packages
                if (!isExpired && package.remainingSessions == 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All classes have been scheduled',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Expired Warning
                if (isExpired) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.redPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.redPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: AppColors.redPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This package has expired',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.redPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _renewPackage(package),
                          child: Text(
                            'Renew',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.redPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.captionText.copyWith(
            color: AppColors.subtitle,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDateItem({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.subtitle,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 💰 INVOICES TAB
  // ========================================
  Widget _buildInvoicesTab() {
    return StreamBuilder<List<Invoice>>(
      stream: getInvoicesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState('Loading invoices...');
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Error loading invoices',
            snapshot.error.toString(),
          );
        }

        final invoices = snapshot.data ?? [];

        if (invoices.isEmpty) {
          return _buildEmptyInvoicesState();
        }

        // Group by status
        final overdue = invoices
            .where((i) => i.status == InvoiceStatus.overdue)
            .toList();
        final pending = invoices
            .where((i) => i.status == InvoiceStatus.pending)
            .toList();
        final paid = invoices
            .where((i) => i.status == InvoiceStatus.paid)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (overdue.isNotEmpty) ...[
              _buildInvoiceSectionHeader(
                'Overdue',
                overdue.length,
                AppColors.redPrimary,
              ),
              ...overdue.map((invoice) => _buildInvoiceCard(invoice)),
              const SizedBox(height: 16),
            ],
            if (pending.isNotEmpty) ...[
              _buildInvoiceSectionHeader(
                'Pending',
                pending.length,
                AppColors.opposite,
              ),
              ...pending.map((invoice) => _buildInvoiceCard(invoice)),
              const SizedBox(height: 16),
            ],
            if (paid.isNotEmpty) ...[
              _buildInvoiceSectionHeader('Paid', paid.length, Colors.green),
              ...paid.map((invoice) => _buildInvoiceCard(invoice)),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildInvoiceSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.captionText.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    Color statusColor = _getInvoiceStatusColor(invoice.status);
    IconData statusIcon = _getInvoiceStatusIcon(invoice.status);
    bool isPaid = invoice.status == InvoiceStatus.paid;
    bool isOverdue = invoice.status == InvoiceStatus.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.packageName,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'INV-${invoice.id.substring(0, 8).toUpperCase()}',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getInvoiceStatusText(invoice.status),
                        style: AppTextStyles.captionText.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount Due',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.subtitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'USD ${invoice.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.heading3.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _buildInvoiceDateItem(
                        icon: Icons.calendar_today,
                        label: 'Due Date',
                        date: _formatDate(invoice.dueDate),
                        color: isOverdue
                            ? AppColors.redPrimary
                            : AppColors.subtitle,
                      ),
                    ),
                    if (isPaid && invoice.paidDate != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInvoiceDateItem(
                          icon: Icons.check_circle,
                          label: 'Paid On',
                          date: _formatDate(invoice.paidDate!),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),

                // Pay Button
                if (!isPaid) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _payInvoice(invoice),
                      icon: const Icon(Icons.payment, size: 20),
                      label: Text(
                        'Pay Now',
                        style: AppTextStyles.buttonPrimary.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDateItem({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.subtitle,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 EMPTY STATES
  // ========================================
  Widget _buildEmptyPackagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Packages Yet',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any assigned packages',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showSnackBar(
                'Please contact admin for package assignment',
                AppColors.primary,
              );
            },
            icon: const Icon(Icons.contact_support),
            label: Text('Contact Admin', style: AppTextStyles.buttonPrimary),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInvoicesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long, size: 64, color: Colors.green),
          ),
          const SizedBox(height: 24),
          Text(
            'No Invoices Found',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 LOADING & ERROR STATES
  // ========================================
  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: AppTextStyles.buttonPrimary),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 HELPER FUNCTIONS
  // ========================================
  Color _getPackageStatusColor(PackageStatus status) {
    switch (status) {
      case PackageStatus.active:
        return Colors.green;
      case PackageStatus.expired:
        return AppColors.redPrimary;
      case PackageStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getPackageStatusIcon(PackageStatus status) {
    switch (status) {
      case PackageStatus.active:
        return Icons.check_circle;
      case PackageStatus.expired:
        return Icons.cancel;
      case PackageStatus.pending:
        return Icons.pending;
    }
  }

  String _getPackageStatusText(PackageStatus status) {
    switch (status) {
      case PackageStatus.active:
        return 'Active';
      case PackageStatus.expired:
        return 'Expired';
      case PackageStatus.pending:
        return 'Pending';
    }
  }

  Color _getInvoiceStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.overdue:
        return AppColors.redPrimary;
    }
  }

  IconData _getInvoiceStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.pending:
        return Icons.schedule;
      case InvoiceStatus.overdue:
        return Icons.warning;
    }
  }

  String _getInvoiceStatusText(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.pending:
        return 'PENDING';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // ========================================
  // 🔹 ACTION FUNCTIONS
  // ========================================
  void _showPackageChangeRequest() {
    final TextEditingController messageController = TextEditingController();
    String? selectedPackageId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.swap_horiz, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Package Change',
              style: AppTextStyles.heading4.copyWith(color: AppColors.text),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a request to admin for package modifications',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<Package>>(
                stream: getPackagesStream(),
                builder: (context, snapshot) {
                  final packages = snapshot.data ?? [];
                  if (packages.isEmpty) return const SizedBox();

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Package',
                      labelStyle: AppTextStyles.inputLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    items: packages.map((pkg) {
                      return DropdownMenuItem(
                        value: pkg.id,
                        child: Text(pkg.name, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedPackageId = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Describe what changes you need...',
                  hintStyle: AppTextStyles.inputHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
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
          ElevatedButton.icon(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) {
                _showSnackBar('Please enter your request', AppColors.error);
                return;
              }

              try {
                // Save request to Firestore
                await _firestore.collection('packageChangeRequests').add({
                  'studentId': _auth.currentUser!.uid,
                  'packageId': selectedPackageId,
                  'message': messageController.text.trim(),
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                _showSnackBar('Request sent successfully!', Colors.green);
              } catch (e) {
                _showSnackBar('Failed to send request', AppColors.error);
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: Text('Send Request', style: AppTextStyles.buttonPrimary),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _renewPackage(Package package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.autorenew, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'Renew Package',
              style: AppTextStyles.heading4.copyWith(color: AppColors.text),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package Details',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRenewDetailRow('Package:', package.name),
            _buildRenewDetailRow(
              'Price:',
              'USD ${package.price.toStringAsFixed(0)}',
            ),
            _buildRenewDetailRow(
              'Classes:',
              '${package.totalSessions} sessions',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin will review your renewal request',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              try {
                await _firestore.collection('renewalRequests').add({
                  'studentId': _auth.currentUser!.uid,
                  'packageId': package.id,
                  'packageName': package.name,
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                _showSnackBar('Renewal request sent!', Colors.green);
              } catch (e) {
                _showSnackBar('Failed to send request', AppColors.error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Confirm Renewal', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _payInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'Payment',
              style: AppTextStyles.heading4.copyWith(color: AppColors.text),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payment gateway integration will be added here',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount to Pay',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'USD ${invoice.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Opening payment gateway...', AppColors.primary);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Proceed to Pay', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.info,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}