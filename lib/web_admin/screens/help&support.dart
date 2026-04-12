import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:studyalquran/web_admin/screens/package.dart';

// 📦 Package Change Request Model - UPDATED
class HelpAndSupport {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String currentPackageId;
  final String currentPackageName;
  final String? requestedPackageId;
  final String? requestedPackageName;
  final String reason;
  final String status;
  final DateTime requestDate;
  final String? type; // teacher_approval, password_reset, package_change
  final String? teacherName;
  final String? userType; // teacher or student for password reset
  final String? email; // email for password reset requests

  HelpAndSupport({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.currentPackageId,
    required this.currentPackageName,
    this.requestedPackageId,
    this.requestedPackageName,
    required this.reason,
    required this.status,
    required this.requestDate,
    this.type,
    this.teacherName,
    this.userType,
    this.email,
  });
}

class HelpAndSupportsScreen extends StatefulWidget {
  const HelpAndSupportsScreen({super.key});

  @override
  State<HelpAndSupportsScreen> createState() =>
      _HelpAndSupportsScreenState();
}

class _HelpAndSupportsScreenState
    extends State<HelpAndSupportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔥 UPDATED: STREAM FOR PACKAGE CHANGE REQUESTS ONLY
  Stream<List<HelpAndSupport>> getCombinedRequestsStream() {
    return _firestore
        .collection('packageChangeRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((packageSnapshot) async {
          List<HelpAndSupport> allRequests = [];

          // PROCESS ALL REQUESTS FROM PACKAGECHANGEREQUESTS COLLECTION ONLY
          for (var doc in packageSnapshot.docs) {
            try {
              Map<String, dynamic> data = doc.data();

              // Check request type
              final requestType = data['type'] ?? 'package_change';

              if (requestType == 'teacher_approval') {
                // 🔥 TEACHER APPROVAL REQUEST
                allRequests.add(
                  HelpAndSupport(
                    id: doc.id,
                    studentId: data['studentId'] ?? '',
                    studentName: data['studentName'] ?? 'Unknown Student',
                    studentEmail: data['studentEmail'] ?? '',
                    currentPackageId: 'trial_class',
                    currentPackageName: 'Trial Class Feedback',
                    requestedPackageId: null,
                    requestedPackageName: null,
                    reason: data['message'] ?? 'No message',
                    status: data['status'] ?? 'pending',
                    requestDate:
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                    type: 'teacher_approval',
                    teacherName: data['teacherName'],
                  ),
                );
              } else if (requestType == 'password_reset') {
                // 🔥 PASSWORD RESET REQUEST
                allRequests.add(
                  HelpAndSupport(
                    id: doc.id,
                    studentId: '',
                    studentName: data['name'] ?? 'Unknown User',
                    studentEmail: data['email'] ?? '',
                    currentPackageId: 'password_reset',
                    currentPackageName: 'Password Reset Request',
                    requestedPackageId: null,
                    requestedPackageName: null,
                    reason: data['message'] ?? 'Password reset requested',
                    status: data['status'] ?? 'pending',
                    requestDate:
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                    type: 'password_reset',
                    userType: data['userType'],
                    email: data['email'],
                  ),
                );
              } else {
                // 🔥 ORIGINAL PACKAGE CHANGE REQUEST
                String studentName = 'Unknown Student';
                String studentEmail = '';

                if (data['studentId'] != null &&
                    data['studentId'].toString().isNotEmpty) {
                  try {
                    var studentDoc = await _firestore
                        .collection('students')
                        .doc(data['studentId'])
                        .get();

                    if (studentDoc.exists) {
                      var studentData = studentDoc.data();
                      studentName = studentData?['name'] ?? 'Unknown Student';
                      studentEmail = studentData?['email'] ?? '';
                    }
                  } catch (e) {
                    print('❌ Error fetching student: $e');
                  }
                }
    
                String currentPackageName = 'Unknown Package';
                String? requestedPackageName;

                if (data['packageId'] != null &&
                    data['packageId'].toString().isNotEmpty) {
                  try {
                    var packageDoc = await _firestore
                        .collection('packages')
                        .doc(data['packageId'])
                        .get();

                    if (packageDoc.exists) {
                      currentPackageName =
                          packageDoc.data()?['packageName'] ??
                          packageDoc.data()?['name'] ??
                          'Unknown Package';
                    }
                  } catch (e) {
                    print('❌ Error fetching package: $e');
                  }
                }
 
                allRequests.add(
                  HelpAndSupport(
                    id: doc.id,
                    studentId: data['studentId'] ?? '',
                    studentName: studentName,
                    studentEmail: studentEmail,
                    currentPackageId: data['packageId'] ?? '',
                    currentPackageName: currentPackageName,
                    requestedPackageId: data['requestedPackageId'],
                    requestedPackageName: requestedPackageName,
                    reason: data['message'] ?? 'No reason provided',
                    status: data['status'] ?? 'pending',
                    requestDate:
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                    type: 'package_change',
                  ),
                );
              }
            } catch (e) {
              print('❌ Error processing packageChangeRequests ${doc.id}: $e');
            }
          }

          return allRequests;
        });
  }

  // 🔥 DELETE REQUEST FUNCTION
  Future<void> _deleteRequest(HelpAndSupport request) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Request'),
        content: Text('Are you sure you want to delete this request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('packageChangeRequests').doc(request.id).delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Request deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {});
      } catch (e) {
        print('❌ Error deleting request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔥 MARK AS RESOLVED FUNCTION
  Future<void> _markAsResolved(HelpAndSupport request) async {
    try {
      await _firestore.collection('packageChangeRequests').doc(request.id).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Request marked as resolved'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      print('❌ Error marking as resolved: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to mark as resolved'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔥 COUNT ALL REQUESTS
  Stream<int> getTotalRequestsStream() {
    return getCombinedRequestsStream().map((requests) => requests.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 28),

            // Stats Card
            _buildStatsCard(),
            const SizedBox(height: 24),

            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 24),

            // Requests List
            Expanded(child: _buildRequestsList()),
          ],
        ),
      ),
    );
  }

  // 🔹 HEADER
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support & Change Requests',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.text,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage package changes, teacher approvals, and password reset requests',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.subtitle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.text,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 STATS CARD
  Widget _buildStatsCard() {
    return StreamBuilder<int>(
      stream: getTotalRequestsStream(),
      builder: (context, snapshot) {
        final totalRequests = snapshot.data ?? 0;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.support_agent,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Support Requests',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalRequests.toString(),
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Package changes, teacher approvals & password resets',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.subtitle, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, request type...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.subtitle,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: AppColors.subtitle, size: 20),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  // 🔹 REQUESTS LIST
  Widget _buildRequestsList() {
    return StreamBuilder<List<HelpAndSupport>>(
      stream: getCombinedRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        var requests = snapshot.data ?? [];

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          requests = requests.where((req) {
            return req.studentName.toLowerCase().contains(_searchQuery) ||
                (req.email?.toLowerCase().contains(_searchQuery) ?? false) ||
                req.studentEmail.toLowerCase().contains(_searchQuery) ||
                req.currentPackageName.toLowerCase().contains(_searchQuery) ||
                (req.requestedPackageName?.toLowerCase().contains(_searchQuery) ?? false) ||
                (req.teacherName?.toLowerCase().contains(_searchQuery) ?? false) ||
                (req.userType?.toLowerCase().contains(_searchQuery) ?? false) ||
                req.type!.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (requests.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index]);
          },
        );
      },
    );
  }

  // 🔹 REQUEST CARD - UPDATED WITH DELETE BUTTON
  Widget _buildRequestCard(HelpAndSupport request) {
    final isTeacherApproval = request.type == 'teacher_approval';
    final isPasswordReset = request.type == 'password_reset';
    final isPackageChange = request.type == 'package_change';
    
    final isApprovedTeacher = isTeacherApproval && request.status == 'approved';

    // Determine colors based on type
    Color? typeColor;
    IconData typeIcon;
    String typeLabel;

    if (isTeacherApproval) {
      typeColor = request.status == 'approved' ? Colors.green : Colors.orange;
      typeIcon = request.status == 'approved' ? Icons.thumb_up : Icons.thumb_down;
      typeLabel = 'Teacher Approval';
    } else if (isPasswordReset) {
      typeColor = Colors.blue;
      typeIcon = Icons.lock_reset;
      typeLabel = 'Password Reset';
    } else {
      typeColor = AppColors.primary;
      typeIcon = Icons.change_circle;
      typeLabel = 'Package Change';
    }

    return InkWell(
      onTap: () => _showRequestDetails(request),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: typeColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Type Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: typeColor.withOpacity(0.1),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.studentName,
                              style: AppTextStyles.cardTitle.copyWith(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: typeColor),
                            ),
                            child: Text(
                              typeLabel.toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPasswordReset
                            ? (request.email ?? 'No email')
                            : request.studentEmail.isNotEmpty
                                ? request.studentEmail
                                : 'No email',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.subtitle,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isTeacherApproval && request.teacherName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Teacher: ${request.teacherName}',
                          style: AppTextStyles.captionText.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (isPasswordReset && request.userType != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 11, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'User Type: ${request.userType!.toUpperCase()}',
                              style: AppTextStyles.captionText.copyWith(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(request.status),
                    ),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.border),
            const SizedBox(height: 16),

            // Request Details based on type
            if (isTeacherApproval)
              // Teacher Approval Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: request.status == 'approved'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: request.status == 'approved'
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          request.status == 'approved'
                              ? Icons.thumb_up
                              : Icons.thumb_down,
                          size: 16,
                          color: request.status == 'approved'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.status == 'approved'
                                ? '✅ Student Approved Teacher ${request.teacherName ?? "Unknown"}'
                                : '❌ Student Rejected Teacher ${request.teacherName ?? "Unknown"}',
                            style: AppTextStyles.labelText.copyWith(
                              color: request.status == 'approved'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Feedback:',
                      style: AppTextStyles.labelText.copyWith(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.reason,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.text,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            else if (isPasswordReset)
              // Password Reset Request
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_reset, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🔑 Password Reset Request',
                            style: AppTextStyles.labelText.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User requested password reset. Please contact them to provide new credentials.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.text,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            else
              // Package Change Request
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPackageInfo(
                    'Current Package',
                    request.currentPackageName,
                    AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 16,
                          color: AppColors.subtitle,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.reason.length > 80
                                ? '${request.reason.substring(0, 80)}...'
                                : request.reason,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.text,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Footer with Date and Action Buttons
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.subtitle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(request.requestDate),
                    style: AppTextStyles.captionText.copyWith(
                      color: AppColors.subtitle,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // DELETE BUTTON FOR ALL REQUESTS
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () => _deleteRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(0, 30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Delete',
                          style: AppTextStyles.captionText.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // MARK RESOLVED BUTTON (for pending password reset requests)
                if (isPasswordReset && request.status == 'pending')
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () => _markAsResolved(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(
                        'Mark Resolved',
                        style: AppTextStyles.captionText.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Text(
                  'Tap to view details',
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
      case 'resolved':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPackageInfo(String label, String packageName, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.subtitle,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            packageName,
            style: AppTextStyles.labelText.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🔹 EMPTY STATE
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No requests found',
            style: AppTextStyles.heading4.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 8),
          Text(
            'All support requests will appear here',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  // 🔹 ERROR STATE
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading requests',
            style: AppTextStyles.heading4.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              error.length > 200 ? '${error.substring(0, 200)}...' : error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 NAVIGATE TO ASSIGN PACKAGE PAGE
  void _navigateToAssignPackage(HelpAndSupport request) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PackagesManagementScreen()),
    );
  }

  // 🔥 SHOW REQUEST DETAILS DIALOG - UPDATED WITH DELETE BUTTON
  void _showRequestDetails(HelpAndSupport request) {
    final isTeacherApproval = request.type == 'teacher_approval';
    final isPasswordReset = request.type == 'password_reset';
    final isApprovedTeacher = isTeacherApproval && request.status == 'approved';

    Color typeColor = isTeacherApproval
        ? (request.status == 'approved' ? Colors.green : Colors.orange)
        : (isPasswordReset ? Colors.blue : AppColors.primary);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.white.withOpacity(0.2),
                      child: Icon(
                        isTeacherApproval
                            ? (request.status == 'approved'
                                  ? Icons.thumb_up
                                  : Icons.thumb_down)
                            : (isPasswordReset
                                  ? Icons.lock_reset
                                  : Icons.person),
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.studentName,
                            style: AppTextStyles.heading5.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isPasswordReset
                                ? (request.email ?? 'No email')
                                : request.studentEmail.isNotEmpty
                                    ? request.studentEmail
                                    : 'No email',
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          if (isTeacherApproval && request.teacherName != null)
                            Text(
                              'Teacher: ${request.teacherName}',
                              style: AppTextStyles.captionText.copyWith(
                                color: AppColors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                          if (isPasswordReset && request.userType != null)
                            Text(
                              'User Type: ${request.userType!.toUpperCase()}',
                              style: AppTextStyles.captionText.copyWith(
                                color: AppColors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(request.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(request.status),
                          ),
                        ),
                        child: Text(
                          'Status: ${request.status.toUpperCase()}',
                          style: TextStyle(
                            color: _getStatusColor(request.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Request Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: typeColor),
                        ),
                        child: Text(
                          isTeacherApproval
                              ? 'TEACHER APPROVAL REQUEST'
                              : (isPasswordReset
                                  ? 'PASSWORD RESET REQUEST'
                                  : 'PACKAGE CHANGE REQUEST'),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Request Content
                      if (isTeacherApproval) ...[
                        _buildDetailSection(
                          title: 'Teacher Approval Feedback',
                          content: request.reason,
                          icon: request.status == 'approved'
                              ? Icons.thumb_up
                              : Icons.thumb_down,
                          color: request.status == 'approved'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ] else if (isPasswordReset) ...[
                        _buildDetailSection(
                          title: 'Password Reset Request',
                          content: request.reason,
                          icon: Icons.lock_reset,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('User Type:', request.userType ?? 'N/A'),
                        _buildDetailRow('Email:', request.email ?? 'N/A'),
                      ] else ...[
                        _buildDetailSection(
                          title: 'Package Change Request',
                          content: request.reason,
                          icon: Icons.change_circle,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Current Package:', request.currentPackageName),
                        if (request.requestedPackageName != null)
                          _buildDetailRow('Requested Package:', request.requestedPackageName!),
                      ],

                      const SizedBox(height: 24),
                      Divider(color: AppColors.border),
                      const SizedBox(height: 24),

                      // Additional Info
                      _buildDetailRow('Request ID:', request.id),
                      if (request.studentId.isNotEmpty)
                        _buildDetailRow('Student ID:', request.studentId),
                      _buildDetailRow(
                        'Request Date:',
                        DateFormat('dd MMM yyyy, hh:mm a').format(request.requestDate),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    // DELETE BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteRequest(request);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Delete Request', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isApprovedTeacher) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToAssignPackage(request);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Assign Package', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (isPasswordReset && request.status == 'pending') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _markAsResolved(request);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Mark Resolved', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Close', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.heading6.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}