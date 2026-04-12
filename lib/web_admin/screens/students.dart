import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:studyalquran/web_admin/screens/invoice.dart';

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() =>
      _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 TRIAL ASSIGNMENT VARIABLES
  bool _isTrialAssignment = false;
  String? _selectedPackageId;
  List<PackageDropdown> _packagesList = [];

  @override
  void initState() {
    super.initState();
    _loadPackages(); // 🔥 Load packages on init
  }

  // 🔥 LOAD PACKAGES FROM PACKAGES COLLECTION
  Future<void> _loadPackages() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('packages')
          .where('status', isEqualTo: 'active')
          .get();
      setState(() {
        _packagesList = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return PackageDropdown(
            id: doc.id,
            name: data['name'] ?? 'Unknown Package',
            sessions: data['numberOfClasses'] ?? 0,
            price: data['price'] ?? 0.0,
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading packages: $e');
    }
  }

  // 🔥 FCM NOTIFICATION FUNCTION
  Future<void> _sendTrialNotification(
    String teacherId,
    String studentId,
    String packageName,
  ) async {
    const String serverKey =
        'YOUR_FCM_SERVER_KEY_HERE'; // Firebase Console se lo

    try {
      // Get teacher and student data
      final teacherDoc = await _firestore
          .collection('teachers')
          .doc(teacherId)
          .get();
      final studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();

      if (!teacherDoc.exists || !studentDoc.exists) return;

      Map<String, dynamic> teacherData = teacherDoc.data()!;
      Map<String, dynamic> studentData = studentDoc.data()!;

      String teacherName = teacherData['name'] ?? 'Teacher';
      String studentName = studentData['name'] ?? 'Student';
      String teacherToken = teacherData['fcmToken'] ?? '';
      String studentToken = studentData['fcmToken'] ?? '';

      // Send to Teacher
      if (teacherToken.isNotEmpty) {
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': teacherToken,
            'notification': {
              'title': '🎯 New Trial Class Assigned',
              'body': 'You have trial class with $studentName for $packageName',
              'sound': 'default',
            },
            'data': {
              'type': 'trial_assignment',
              'studentId': studentId,
              'teacherId': teacherId,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          }),
        );
      }

      // Send to Student
      if (studentToken.isNotEmpty) {
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': studentToken,
            'notification': {
              'title': '🎯 Trial Class Scheduled',
              'body': 'You have trial class with $teacherName for $packageName',
              'sound': 'default',
            },
            'data': {
              'type': 'trial_assignment',
              'studentId': studentId,
              'teacherId': teacherId,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          }),
        );
      }

      print('Trial notifications sent successfully!');
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  // 🔥 STREAM: Real-time students data - UPDATED WITH PACKAGE DISPLAY
  Stream<List<Student>> getStudentsStream() {
    return _firestore.collection('students').snapshots().asyncMap((
      snapshot,
    ) async {
      List<Student> students = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();

        // Get teacher name from teachers collection
        String teacherName = 'Not Assigned';
        if (data['assignedTeacherId'] != null &&
            data['assignedTeacherId'].isNotEmpty) {
          try {
            var teacherDoc = await _firestore
                .collection('teachers')
                .doc(data['assignedTeacherId'])
                .get();
            if (teacherDoc.exists) {
              teacherName = teacherDoc.data()?['name'] ?? 'Unknown';
            }
          } catch (e) {
            print('Error fetching teacher: $e');
          }
        }

        students.add(Student.fromFirestore(data, doc.id, teacherName));
      }

      return students;
    });
  }

  // 🔥 GET TEACHERS LIST FOR DROPDOWN
  Future<List<TeacherDropdown>> getTeachersList() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('teachers').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return TeacherDropdown(id: doc.id, name: data['name'] ?? 'Unknown');
      }).toList();
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  List<Student> filterStudents(List<Student> students) {
    if (_searchQuery.isEmpty) return students;
    return students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.region.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.assignedTeacher.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  void _showAddEditDialog({Student? student}) async {
    List<TeacherDropdown> teachers = await getTeachersList();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AddEditStudentDialog(
        student: student,
        availableTeachers: teachers,
        packagesList: _packagesList,
        onTrialAssignment: (teacherId, studentId, packageId, packageName) {
          // 🔥 Handle trial assignment
          _handleTrialAssignment(teacherId, studentId, packageId, packageName);
        },
      ),
    ).then((_) {
      // Dialog close hone ke baad refresh karo
      if (mounted) {
        setState(() {});
      }
    });
  }

  // 🔥 HANDLE TRIAL ASSIGNMENT
  Future<void> _handleTrialAssignment(
    String teacherId,
    String studentId,
    String packageId,
    String packageName,
  ) async {
    try {
      // Create trial assignment record
      await _firestore.collection('trialAssignments').add({
        'teacherId': teacherId,
        'studentId': studentId,
        'packageId': packageId,
        'packageName': packageName,
        'status': 'pending', // pending, completed, approved, rejected
        'assignedAt': FieldValue.serverTimestamp(),
        'studentApproval': null,
        'trialCompleted': false,
      });

      // Update student record with trial info
      await _firestore.collection('students').doc(studentId).update({
        'assignedTeacherId': teacherId,
        'trialStatus': 'pending',
        'trialPackage': packageName,
        'isTrial': true,
        'studentApprovalStatus': 'pending', // 🔥 NEW FIELD
      });

      // Send FCM notifications
      await _sendTrialNotification(teacherId, studentId, packageName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎯 Trial class assigned successfully!',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAssignTeacherDialog(Student student) async {
    List<TeacherDropdown> teachers = await getTeachersList();
    if (!mounted) return;
    String? selectedTeacherId = student.assignedTeacherId.isNotEmpty
        ? student.assignedTeacherId
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Teacher', style: AppTextStyles.alertTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student: ${student.name}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Text('Select Teacher:', style: AppTextStyles.inputLabel),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedTeacherId,
              style: AppTextStyles.inputValue,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('Not Assigned', style: AppTextStyles.inputValue),
                ),
                ...teachers.map((teacher) {
                  return DropdownMenuItem(
                    value: teacher.id,
                    child: Text(teacher.name),
                  );
                }),
              ],
              onChanged: (value) {
                selectedTeacherId = value;
              },
            ),

            // 🔥 TRIAL ASSIGNMENT OPTION
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isTrialAssignment,
                        onChanged: (val) =>
                            setState(() => _isTrialAssignment = val ?? false),
                      ),
                      Text(
                        'Assign as Trial Class',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  if (_isTrialAssignment) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Select Package for Trial:',
                      style: AppTextStyles.inputLabel,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPackageId,
                      style: AppTextStyles.inputValue,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Select Package',
                            style: AppTextStyles.inputValue,
                          ),
                        ),
                        ..._packagesList.map((package) {
                          return DropdownMenuItem(
                            value: package.id,
                            child: Text(
                              '${package.name} (${package.sessions} classes)',
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedPackageId = value),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (_isTrialAssignment && _selectedPackageId != null) {
                  // 🔥 Trial Assignment
                  String packageName = _packagesList
                      .firstWhere((p) => p.id == _selectedPackageId)
                      .name;
                  await _handleTrialAssignment(
                    selectedTeacherId!,
                    student.id,
                    _selectedPackageId!,
                    packageName,
                  );
                } else {
                  // Regular Assignment
                  await _firestore
                      .collection('students')
                      .doc(student.id)
                      .update({
                        'assignedTeacherId': selectedTeacherId ?? '',
                        'isTrial': false,
                        'trialStatus': null,
                        'studentApprovalStatus':
                            null, // 🔥 CLEAR APPROVAL STATUS
                      });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Teacher assigned successfully',
                        style: AppTextStyles.bodySmall,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e', style: AppTextStyles.bodySmall),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              _isTrialAssignment ? 'Assign Trial' : 'Assign',
              style: AppTextStyles.buttonPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 DELETE STUDENT
  Future<void> _deleteStudent(String studentId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Student', style: AppTextStyles.alertTitle),
        content: Text(
          'Are you sure you want to delete this student?',
          style: AppTextStyles.alertBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('students').doc(studentId).delete();
                await _firestore.collection('users').doc(studentId).delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Student deleted successfully',
                      style: AppTextStyles.bodySmall,
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e', style: AppTextStyles.bodySmall),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }

  // 🔥 CONVERT APPROVED TRIAL STUDENT TO NORMAL STUDENT (CARD CLICK PE)
  Future<void> _convertTrialToNormal(Student student) async {
    // 🔥 CHECK: SIRF APPROVED STUDENTS KO HI CONVERT KARO
    if (!student.isTrial) return;

    bool isApproved = false;
    if (student.studentApprovalStatus.isNotEmpty) {
      isApproved = student.studentApprovalStatus == 'approved';
    } else if (student.trialStatus.isNotEmpty) {
      isApproved = student.trialStatus == 'approved';
    }

    if (!isApproved) return; // Agar approved nahi hai toh return

    // Confirmation Dialog
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Convert Trial to Normal',
              style: AppTextStyles.alertTitle,
            ),
            content: Text(
              'Convert ${student.name} from trial to regular student?',
              style: AppTextStyles.alertBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: AppTextStyles.buttonSecondary),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: Text('Convert', style: AppTextStyles.buttonPrimary),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      // 🔥 UPDATE STUDENT STATUS - Remove trial status and make normal student
      await _firestore.collection('students').doc(student.id).update({
        'isTrial': false,
        'trialStatus': null,
        'studentApprovalStatus': null,
        'trialPackage': null,
        'convertedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Student converted to regular student!',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 🔥 CREATE INVOICE FUNCTION - UPDATE THIS IN STUDENTS MANAGEMENT SCREEN
  Future<void> _createInvoice(Student student) async {
    try {
      // 🔥 UPDATE STUDENT STATUS - Remove trial status and make normal student
      await _firestore.collection('students').doc(student.id).update({
        'isTrial': false,
        'trialStatus': null,
        'studentApprovalStatus': null,
        'trialPackage': null,
        'invoiceCreated': true,
        'invoiceCreatedAt': FieldValue.serverTimestamp(),
      });

      // 🔥 NAVIGATE TO INVOICE PAGE WITH STUDENT ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicesManagementScreen(
            studentId:
                student.id, // 🔥 PASS STUDENT ID INSTEAD OF STUDENT OBJECT
            studentName: student.name, // 🔥 OPTIONAL: PASS STUDENT NAME
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Invoice created! Student converted to regular student',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error creating invoice: $e',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 🔥 GET CARD COLOR BASED ON APPROVAL STATUS - UPDATED VERSION
  Color _getCardColor(Student student) {
    if (student.isTrial) {
      // 🔥 PEHLE studentApprovalStatus CHECK KARO
      if (student.studentApprovalStatus.isNotEmpty) {
        switch (student.studentApprovalStatus) {
          case 'approved':
            return Colors.green.withOpacity(0.1); // 🔥 GREEN FOR APPROVED
          case 'rejected':
            return Colors.red.withOpacity(
              0.1,
            ); // 🔥 RED FOR REJECTED - PERMANENT
          case 'pending':
            return Colors.orange.withOpacity(0.1); // 🔥 ORANGE FOR PENDING
          default:
            return AppColors.warning.withOpacity(0.1);
        }
      }
      // 🔥 PHIR trialStatus CHECK KARO
      else if (student.trialStatus.isNotEmpty) {
        switch (student.trialStatus) {
          case 'approved':
            return Colors.green.withOpacity(0.1);
          case 'rejected':
            return Colors.red.withOpacity(
              0.1,
            ); // 🔥 RED FOR REJECTED - PERMANENT
          case 'pending':
            return Colors.orange.withOpacity(0.1);
          case 'completed':
            return Colors.blue.withOpacity(0.1);
          default:
            return AppColors.warning.withOpacity(0.1);
        }
      }
    }
    return Colors.transparent; // Normal student - no background color
  }

  // 🔥 GET APPROVAL STATUS TEXT - UPDATED VERSION
  String _getApprovalStatusText(Student student) {
    if (student.isTrial) {
      // 🔥 PEHLE studentApprovalStatus CHECK KARO
      if (student.studentApprovalStatus.isNotEmpty) {
        switch (student.studentApprovalStatus) {
          case 'approved':
            return '✅ Teacher approved by student - Create Invoice';
          case 'rejected':
            return '❌ Teacher rejected by student';
          case 'pending':
            return '⏳ Waiting for student approval';
          default:
            return 'Trial - Approval Pending';
        }
      }
      // 🔥 PHIR trialStatus CHECK KARO
      else if (student.trialStatus.isNotEmpty) {
        switch (student.trialStatus) {
          case 'approved':
            return '✅ Trial Completed - Approved - Create Invoice';
          case 'rejected':
            return '❌ Trial Rejected';
          case 'pending':
            return '⏳ Trial Class Pending';
          case 'completed':
            return '✅ Trial Completed - Awaiting Approval';
          default:
            return 'Trial Class Scheduled';
        }
      }
    }
    return '';
  }

  // 🔥 GET APPROVAL STATUS COLOR - UPDATED VERSION
  Color _getApprovalStatusColor(Student student) {
    if (student.isTrial) {
      // 🔥 PEHLE studentApprovalStatus CHECK KARO
      if (student.studentApprovalStatus.isNotEmpty) {
        switch (student.studentApprovalStatus) {
          case 'approved':
            return Colors.green;
          case 'rejected':
            return Colors.red;
          case 'pending':
            return Colors.orange;
          default:
            return AppColors.warning;
        }
      }
      // 🔥 PHIR trialStatus CHECK KARO
      else if (student.trialStatus.isNotEmpty) {
        switch (student.trialStatus) {
          case 'approved':
            return Colors.green;
          case 'rejected':
            return Colors.red;
          case 'pending':
            return Colors.orange;
          case 'completed':
            return Colors.blue;
          default:
            return AppColors.warning;
        }
      }
    }
    return AppColors.text;
  }

  // 🔥 GET STATUS ICON
  IconData _getStatusIcon(Student student) {
    if (student.isTrial) {
      // 🔥 PEHLE studentApprovalStatus CHECK KARO
      if (student.studentApprovalStatus.isNotEmpty) {
        switch (student.studentApprovalStatus) {
          case 'approved':
            return Icons.check_circle;
          case 'rejected':
            return Icons.cancel;
          case 'pending':
            return Icons.access_time;
          default:
            return Icons.info;
        }
      }
      // 🔥 PHIR trialStatus CHECK KARO
      else if (student.trialStatus.isNotEmpty) {
        switch (student.trialStatus) {
          case 'approved':
            return Icons.check_circle;
          case 'rejected':
            return Icons.cancel;
          case 'pending':
            return Icons.access_time;
          case 'completed':
            return Icons.schedule;
          default:
            return Icons.info;
        }
      }
    }
    return Icons.info;
  }

  // 🔥 CHECK IF INVOICE BUTTON SHOULD SHOW
  bool _shouldShowInvoiceButton(Student student) {
    return false;

    if (student.isTrial) {
      // 🔥 SIRF APPROVED STUDENTS KE LIYE INVOICE BUTTON SHOW KARO
      if (student.studentApprovalStatus.isNotEmpty) {
        return student.studentApprovalStatus == 'approved';
      } else if (student.trialStatus.isNotEmpty) {
        return student.trialStatus == 'approved';
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Students Management', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: AppColors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Students List', style: AppTextStyles.heading1),
                    const SizedBox(height: 8),
                    Text(
                      'Manage all students from here',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Student',
                    style: AppTextStyles.buttonPrimary,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: AppTextStyles.inputValue,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, teacher, or region...',
                  hintStyle: AppTextStyles.inputHint,
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.subtitle),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.subtitle),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔥 STUDENTS TABLE WITH STREAM - PACKAGE COLUMN INCLUDED
            Expanded(
              child: StreamBuilder<List<Student>>(
                stream: getStudentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  final students = snapshot.data ?? [];
                  final filteredStudents = filterStudents(students);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header - PACKAGE COLUMN INCLUDED
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Name',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Email',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Region',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Assigned Teacher',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Package',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Sessions Left',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Status',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Actions',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // 🔥 UPDATED TABLE BODY - PACKAGE COLUMN INCLUDED
                        Expanded(
                          child: filteredStudents.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: AppColors.subtitle,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No students found',
                                        style: AppTextStyles.heading4,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        students.isEmpty
                                            ? 'No students in the system'
                                            : 'Try adjusting your search terms',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = filteredStudents[index];
                                    final isTrial = student.isTrial;
                                    final showInvoiceButton =
                                        _shouldShowInvoiceButton(student);

                                    // 🔥 CHECK: Is student approved?
                                    bool isApproved = false;
                                    if (student
                                        .studentApprovalStatus
                                        .isNotEmpty) {
                                      isApproved =
                                          student.studentApprovalStatus ==
                                          'approved';
                                    } else if (student.trialStatus.isNotEmpty) {
                                      isApproved =
                                          student.trialStatus == 'approved';
                                    }

                                    return InkWell(
                                      // 🔥 CARD CLICK - SIRF APPROVED STUDENTS KE LIYE
                                      onTap: isTrial && isApproved
                                          ? () => _convertTrialToNormal(student)
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          color: _getCardColor(
                                            student,
                                          ), // 🔥 DYNAMIC COLOR
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  // Name with Trial Badge
                                                  Expanded(
                                                    flex: 2,
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              _getApprovalStatusColor(
                                                                student,
                                                              ).withOpacity(
                                                                0.2,
                                                              ),
                                                          child: Text(
                                                            student
                                                                    .name
                                                                    .isNotEmpty
                                                                ? student
                                                                      .name[0]
                                                                      .toUpperCase()
                                                                : '?',
                                                            style: AppTextStyles
                                                                .buttonPrimary
                                                                .copyWith(
                                                                  color:
                                                                      _getApprovalStatusColor(
                                                                        student,
                                                                      ),
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                student.name,
                                                                style: AppTextStyles
                                                                    .tableCell,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              if (isTrial) ...[
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        _getApprovalStatusColor(
                                                                          student,
                                                                        ).withOpacity(
                                                                          0.1,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          4,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: _getApprovalStatusColor(
                                                                        student,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    student
                                                                            .studentApprovalStatus
                                                                            .isNotEmpty
                                                                        ? student
                                                                              .studentApprovalStatus
                                                                              .toUpperCase()
                                                                        : student
                                                                              .trialStatus
                                                                              .isNotEmpty
                                                                        ? student
                                                                              .trialStatus
                                                                              .toUpperCase()
                                                                        : 'TRIAL',
                                                                    style: AppTextStyles.captionText.copyWith(
                                                                      color: _getApprovalStatusColor(
                                                                        student,
                                                                      ),
                                                                      fontSize:
                                                                          8,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Email
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      student.email,
                                                      style: AppTextStyles
                                                          .tableCell,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  // Region
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        student.region,
                                                        style: AppTextStyles
                                                            .chipText
                                                            .copyWith(
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),

                                                  // Teacher
                                                  Expanded(
                                                    flex: 2,
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person_outline,
                                                          size: 16,
                                                          color:
                                                              _getApprovalStatusColor(
                                                                student,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            student
                                                                .assignedTeacher,
                                                            style: AppTextStyles
                                                                .tableCell
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      _getApprovalStatusColor(
                                                                        student,
                                                                      ),
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Package
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _getApprovalStatusColor(
                                                              student,
                                                            ).withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        student.packageType,
                                                        style: AppTextStyles
                                                            .chipText
                                                            .copyWith(
                                                              color:
                                                                  _getApprovalStatusColor(
                                                                    student,
                                                                  ),
                                                              fontSize: 11,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),

                                                  // Sessions Left
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            student.sessionsLeft >
                                                                5
                                                            ? AppColors.success
                                                                  .withOpacity(
                                                                    0.1,
                                                                  )
                                                            : student.sessionsLeft >
                                                                  0
                                                            ? AppColors.warning
                                                                  .withOpacity(
                                                                    0.1,
                                                                  )
                                                            : AppColors.error
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${student.sessionsLeft}',
                                                        style: AppTextStyles
                                                            .tableCell
                                                            .copyWith(
                                                              color:
                                                                  student.sessionsLeft >
                                                                      5
                                                                  ? AppColors
                                                                        .success
                                                                  : student.sessionsLeft >
                                                                        0
                                                                  ? AppColors
                                                                        .warning
                                                                  : AppColors
                                                                        .error,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),

                                                  // Status
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: student.isActive
                                                            ? AppColors.success
                                                                  .withOpacity(
                                                                    0.1,
                                                                  )
                                                            : AppColors.error
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        student.isActive
                                                            ? 'Active'
                                                            : 'Inactive',
                                                        style: AppTextStyles
                                                            .badge
                                                            .copyWith(
                                                              color:
                                                                  student
                                                                      .isActive
                                                                  ? AppColors
                                                                        .success
                                                                  : AppColors
                                                                        .error,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),

                                                  // Actions
                                                  Expanded(
                                                    flex: 2,
                                                    child: Row(
                                                      children: [
                                                        // Edit Button
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.edit,
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                          onPressed: () =>
                                                              _showAddEditDialog(
                                                                student:
                                                                    student,
                                                              ),
                                                          tooltip: 'Edit',
                                                        ),

                                                        // Assign Teacher Button
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.person_add,
                                                            color:
                                                                _getApprovalStatusColor(
                                                                  student,
                                                                ),
                                                          ),
                                                          onPressed: () =>
                                                              _showAssignTeacherDialog(
                                                                student,
                                                              ),
                                                          tooltip:
                                                              'Assign Teacher',
                                                        ),

                                                        // Delete Button
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.delete,
                                                            color:
                                                                AppColors.error,
                                                          ),
                                                          onPressed: () =>
                                                              _deleteStudent(
                                                                student.id,
                                                              ),
                                                          tooltip: 'Delete',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // 🔥 APPROVAL STATUS TEXT - WITH CLICK INSTRUCTION
                                              if (isTrial) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getApprovalStatusColor(
                                                          student,
                                                        ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _getStatusIcon(student),
                                                        size: 14,
                                                        color:
                                                            _getApprovalStatusColor(
                                                              student,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        isApproved
                                                            ? '✅ ${_getApprovalStatusText(student)} - Click card to convert'
                                                            : _getApprovalStatusText(
                                                                student,
                                                              ),
                                                        style: AppTextStyles
                                                            .captionText
                                                            .copyWith(
                                                              color:
                                                                  _getApprovalStatusColor(
                                                                    student,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 ADD/EDIT STUDENT DIALOG - FIXED PASSWORD STORAGE ISSUE
class AddEditStudentDialog extends StatefulWidget {
  final Student? student;
  final List<TeacherDropdown> availableTeachers;
  final List<PackageDropdown> packagesList;
  final Function(String, String, String, String)? onTrialAssignment;

  const AddEditStudentDialog({
    super.key,
    this.student,
    required this.availableTeachers,
    required this.packagesList,
    this.onTrialAssignment,
  });

  @override
  State<AddEditStudentDialog> createState() => _AddEditStudentDialogState();
}

class _AddEditStudentDialogState extends State<AddEditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _regionController;
  late TextEditingController _phoneController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _passwordController;
  String? _selectedTeacherId;
  bool _isActive = true;
  bool _isLoading = false;

  // 🔥 PASSWORD VISIBILITY
  bool _isPasswordVisible = false;

  // 🔥 EXISTING PASSWORD
  String? _existingPassword;
  bool _passwordLoaded = false;

  // 🔥 TRIAL FIELDS
  bool _isTrialAssignment = false;
  String? _selectedTrialPackageId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _emailController = TextEditingController(text: widget.student?.email ?? '');
    _regionController = TextEditingController(
      text: widget.student?.region ?? '',
    );
    _phoneController = TextEditingController(text: widget.student?.phone ?? '');
    _parentPhoneController = TextEditingController(
      text: widget.student?.parentPhone ?? '',
    );
    _passwordController = TextEditingController();
    _selectedTeacherId = widget.student?.assignedTeacherId.isNotEmpty == true
        ? widget.student!.assignedTeacherId
        : null;
    _isActive = widget.student?.isActive ?? true;

    // 🔥 LOAD EXISTING PASSWORD IF EDIT MODE
    if (widget.student != null) {
      _loadExistingPassword();
    }
  }

  // 🔥 LOAD EXISTING PASSWORD FROM FIRESTORE (BOTH COLLECTIONS)
  Future<void> _loadExistingPassword() async {
    try {
      print('Loading password for student: ${widget.student!.id}');
      
      // Pehle students collection check karo
      final studentDoc = await _firestore
          .collection('students')
          .doc(widget.student!.id)
          .get();
      
      if (studentDoc.exists && studentDoc.data() != null) {
        final studentData = studentDoc.data()!;
        if (studentData['password'] != null && studentData['password'].toString().isNotEmpty) {
          print('Password found in students collection');
          setState(() {
            _existingPassword = studentData['password'].toString();
            _passwordController.text = _existingPassword!;
            _passwordLoaded = true;
          });
          return;
        }
      }
      
      // Phir users collection check karo
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.student!.id)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        if (userData['password'] != null && userData['password'].toString().isNotEmpty) {
          print('Password found in users collection');
          setState(() {
            _existingPassword = userData['password'].toString();
            _passwordController.text = _existingPassword!;
            _passwordLoaded = true;
          });
          return;
        }
      }
      
      // Agar kahi bhi password nahi mila
      print('No password found in any collection');
      setState(() {
        _existingPassword = null;
        _passwordLoaded = true;
      });
    } catch (e) {
      print('Error loading existing password: $e');
      setState(() {
        _passwordLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      // Better password generation
      final random = DateTime.now().millisecondsSinceEpoch;
      final randomPart = random.toString().substring(random.toString().length - 6);
      _passwordController.text = 'Student@$randomPart';
    });
  }

  // 🔥 STORE PASSWORD IN BOTH COLLECTIONS
  Future<void> _storePasswordInBothCollections(String userId, String password) async {
    try {
      // Store in users collection
      await _firestore.collection('users').doc(userId).update({
        'password': password,
        'passwordStoredAt': FieldValue.serverTimestamp(),
        'passwordStoredBy': 'admin',
      });
      
      // Store in students collection too
      await _firestore.collection('students').doc(userId).update({
        'password': password,
        'passwordStoredAt': FieldValue.serverTimestamp(),
        'passwordStoredBy': 'admin',
      });
      
      print('✅ Password stored in both collections for user: $userId');
    } catch (e) {
      print('❌ Error storing password: $e');
      // Agar update nahi ho pa raha (document doesn't exist), toh create karo
      try {
        // Students collection mein create karo
        final studentDoc = await _firestore.collection('students').doc(userId).get();
        if (studentDoc.exists) {
          await _firestore.collection('students').doc(userId).update({
            'password': password,
            'passwordStoredAt': FieldValue.serverTimestamp(),
            'passwordStoredBy': 'admin',
          });
        }
        
        // Users collection mein create karo
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          await _firestore.collection('users').doc(userId).update({
            'password': password,
            'passwordStoredAt': FieldValue.serverTimestamp(),
            'passwordStoredBy': 'admin',
          });
        }
      } catch (e2) {
        print('❌ Error in fallback password storage: $e2');
      }
    }
  }

  // 🔥 SEND PASSWORD RESET EMAIL
  Future<void> _sendPasswordResetEmail() async {
    try {
      setState(() => _isLoading = true);
      
      await _auth.sendPasswordResetEmail(email: widget.student!.email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📧 Password reset email sent to ${widget.student!.email}',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
      
      setState(() {
        _existingPassword = null;
        _passwordController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error sending reset email: $e',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔥 ADD STUDENT - WITH PROPER PASSWORD STORAGE
  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String password = _passwordController.text.trim();
      
      // Step 1: Create Firebase Auth account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: password,
          );

      String uid = userCredential.user!.uid;

      // Step 2: Store password in BOTH collections
      await _storePasswordInBothCollections(uid, password);

      // Step 3: Add to 'users' collection with ALL data
      await _firestore.collection('users').doc(uid).set({
        'role': 'student',
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': _isActive ? 'active' : 'inactive',
        'password': password, // Store password
        'passwordStoredAt': FieldValue.serverTimestamp(),
        'passwordStoredBy': 'admin',
      });

      // Step 4: Add to 'students' collection with ALL data including password
      Map<String, dynamic> studentData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'class': _regionController.text.trim(),
        'parentPhone': _parentPhoneController.text.trim(),
        'feeStatus': 'paid',
        'assignedTeacherId': _selectedTeacherId ?? '',
        'sessionsLeft': 0,
        'isActive': _isActive,
        'password': password, // Store password here too
        'passwordStoredAt': FieldValue.serverTimestamp(),
        'passwordStoredBy': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 🔥 ADD TRIAL DATA IF TRIAL ASSIGNMENT
      if (_isTrialAssignment &&
          _selectedTeacherId != null &&
          _selectedTrialPackageId != null) {
        String packageName = widget.packagesList
            .firstWhere((p) => p.id == _selectedTrialPackageId)
            .name;
        studentData.addAll({
          'isTrial': true,
          'trialStatus': 'pending',
          'trialPackage': packageName,
          'studentApprovalStatus': 'pending',
        });
      }

      await _firestore.collection('students').doc(uid).set(studentData);

      // 🔥 HANDLE TRIAL ASSIGNMENT
      if (_isTrialAssignment &&
          _selectedTeacherId != null &&
          _selectedTrialPackageId != null) {
        String packageName = widget.packagesList
            .firstWhere((p) => p.id == _selectedTrialPackageId)
            .name;
        widget.onTrialAssignment?.call(
          _selectedTeacherId!,
          uid,
          _selectedTrialPackageId!,
          packageName,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isTrialAssignment
                    ? '🎯 Student added with trial assignment!'
                    : '✅ Student added successfully!',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Password: $password',
                style: AppTextStyles.captionText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Password has been stored in database.',
                style: AppTextStyles.captionText.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔥 UPDATE STUDENT - WITH PASSWORD UPDATE IN BOTH COLLECTIONS
  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String studentId = widget.student!.id;
      String newPassword = _passwordController.text.trim();
      bool passwordChanged = newPassword.isNotEmpty && newPassword != _existingPassword;

      // Update user data
      Map<String, dynamic> userUpdateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'status': _isActive ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update student data
      Map<String, dynamic> studentUpdateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'class': _regionController.text.trim(),
        'parentPhone': _parentPhoneController.text.trim(),
        'assignedTeacherId': _selectedTeacherId ?? '',
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 🔥 UPDATE TRIAL DATA
      if (_isTrialAssignment &&
          _selectedTeacherId != null &&
          _selectedTrialPackageId != null) {
        String packageName = widget.packagesList
            .firstWhere((p) => p.id == _selectedTrialPackageId)
            .name;
        studentUpdateData.addAll({
          'isTrial': true,
          'trialStatus': 'pending',
          'trialPackage': packageName,
          'studentApprovalStatus': 'pending',
        });
      } else {
        studentUpdateData.addAll({
          'isTrial': false,
          'trialStatus': null,
          'studentApprovalStatus': null,
        });
      }

      // 🔥 UPDATE PASSWORD IF CHANGED
      if (passwordChanged) {
        userUpdateData['password'] = newPassword;
        userUpdateData['passwordUpdatedAt'] = FieldValue.serverTimestamp();
        
        studentUpdateData['password'] = newPassword;
        studentUpdateData['passwordUpdatedAt'] = FieldValue.serverTimestamp();
        
        // Store in both collections
        await _storePasswordInBothCollections(studentId, newPassword);
      }

      // Update both collections
      await _firestore.collection('users').doc(studentId).update(userUpdateData);
      await _firestore.collection('students').doc(studentId).update(studentUpdateData);

      // 🔥 HANDLE TRIAL ASSIGNMENT
      if (_isTrialAssignment &&
          _selectedTeacherId != null &&
          _selectedTrialPackageId != null) {
        String packageName = widget.packagesList
            .firstWhere((p) => p.id == _selectedTrialPackageId)
            .name;
        widget.onTrialAssignment?.call(
          _selectedTeacherId!,
          studentId,
          _selectedTrialPackageId!,
          packageName,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTrialAssignment
                ? '🎯 Student updated with trial assignment!'
                : '✅ Student updated successfully!${passwordChanged ? ' Password updated.' : ''}',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔥 SHOW PASSWORD HELP DIALOG
  void _showPasswordHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Password Help', style: AppTextStyles.alertTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For existing students without stored passwords:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpItem('1. Ask the student for their password'),
            _buildHelpItem('2. Send password reset email'),
            _buildHelpItem('3. Set a new password above'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'New students will have passwords automatically stored.',
                style: AppTextStyles.captionText.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendPasswordResetEmail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Send Reset Email', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Student' : 'Add New Student',
                      style: AppTextStyles.heading2,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildTextField('Name', _nameController, 'Enter student name'),
                const SizedBox(height: 20),
                _buildTextField(
                  'Email',
                  _emailController,
                  'Enter email address',
                  enabled: !isEdit,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Phone',
                  _phoneController,
                  'Enter phone number',
                  isNumber: true,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Parent Phone',
                  _parentPhoneController,
                  'Enter parent phone number',
                  isNumber: true,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Region/Class',
                  _regionController,
                  'Enter region (e.g., Karachi)',
                ),
                const SizedBox(height: 20),

                // Assign Teacher Dropdown
                Text('Assign Teacher', style: AppTextStyles.inputLabel),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTeacherId,
                  style: AppTextStyles.inputValue,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Not Assigned',
                        style: AppTextStyles.inputValue,
                      ),
                    ),
                    ...widget.availableTeachers.map((teacher) {
                      return DropdownMenuItem(
                        value: teacher.id,
                        child: Text(teacher.name),
                      );
                    }),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedTeacherId = value),
                ),

                // 🔥 TRIAL ASSIGNMENT SECTION
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _isTrialAssignment,
                            onChanged: (val) => setState(
                              () => _isTrialAssignment = val ?? false,
                            ),
                          ),
                          Text(
                            'Assign as Trial Class',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      if (_isTrialAssignment) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Select Package for Trial:',
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTrialPackageId,
                          style: AppTextStyles.inputValue,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Select Package',
                                style: AppTextStyles.inputValue,
                              ),
                            ),
                            ...widget.packagesList.map((package) {
                              return DropdownMenuItem(
                                value: package.id,
                                child: Text(
                                  '${package.name} (${package.sessions} classes)',
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedTrialPackageId = value),
                          validator: _isTrialAssignment
                              ? (value) {
                                  if (value == null) {
                                    return 'Please select a package for trial';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '📝 Student will need to approve teacher after trial class',
                          style: AppTextStyles.captionText.copyWith(
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔥 PASSWORD FIELD - WITH EYE BUTTON
                Text('Password', style: AppTextStyles.inputLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: AppTextStyles.inputValue,
                        decoration: InputDecoration(
                          hintText: isEdit
                              ? (_existingPassword != null
                                  ? 'Stored password shown'
                                  : 'Enter new password')
                              : 'Enter password for new student',
                          hintStyle: AppTextStyles.inputHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.subtitle,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: isEdit
                            ? null // Edit mode mein password optional hai
                            : (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _generatePassword,
                      icon: Icon(isEdit ? Icons.refresh : Icons.key, size: 18),
                      label: Text(
                        isEdit ? 'New' : 'Auto',
                        style: AppTextStyles.buttonSmall,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEdit
                            ? AppColors.warning
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),

                // 🔥 PASSWORD STATUS FOR EDIT MODE
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_passwordLoaded) ...[
                          Row(
                            children: [
                              Icon(Icons.hourglass_empty, size: 14, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Text(
                                'Loading password information...',
                                style: AppTextStyles.captionText.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ] else if (_existingPassword != null) ...[
                          Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text(
                                '✅ Password found in database',
                                style: AppTextStyles.captionText.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Edit the password above to change it.',
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.subtitle,
                              fontSize: 11,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(Icons.warning, size: 14, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(
                                '⚠️ No password stored for this student',
                                style: AppTextStyles.captionText.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Enter a new password above.',
                                  style: AppTextStyles.captionText.copyWith(
                                    color: AppColors.subtitle,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _showPasswordHelpDialog,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  'Need Help?',
                                  style: AppTextStyles.captionText.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Status Toggle
                Row(
                  children: [
                    Text('Status:', style: AppTextStyles.inputLabel),
                    const SizedBox(width: 16),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      activeThumbColor: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isActive ? 'Active' : 'Inactive',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.buttonSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (isEdit ? _updateStudent : _addStudent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTrialAssignment
                            ? AppColors.warning
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isTrialAssignment
                                  ? (isEdit
                                        ? 'Update with Trial'
                                        : 'Add with Trial')
                                  : (isEdit ? 'Update Student' : 'Add Student'),
                              style: AppTextStyles.buttonPrimary,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          style: AppTextStyles.inputValue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            if (label == 'Email' && !value.contains('@')) {
              return 'Enter a valid email';
            }
            if (isNumber && !RegExp(r'^[0-9+]+$').hasMatch(value)) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }
}

// 🔥 UPDATED STUDENT MODEL - PASSWORD FIELD ADDED
class Student {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String region;
  final String parentPhone;
  final String assignedTeacher;
  final String assignedTeacherId;
  final String packageType;
  final int sessionsLeft;
  final bool isActive;
  final bool isTrial;
  final String trialStatus;
  final String trialPackage;
  final String studentApprovalStatus;
  final bool invoiceCreated;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.region,
    required this.parentPhone,
    required this.assignedTeacher,
    required this.assignedTeacherId,
    required this.packageType,
    required this.sessionsLeft,
    required this.isActive,
    this.isTrial = false,
    this.trialStatus = '',
    this.trialPackage = '',
    this.studentApprovalStatus = '',
    this.invoiceCreated = false,
  });

  factory Student.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String teacherName,
  ) {
    return Student(
      id: id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      region: data['class']?.toString() ?? '',
      parentPhone: data['parentPhone']?.toString() ?? '',
      assignedTeacher: teacherName,
      assignedTeacherId: data['assignedTeacherId']?.toString() ?? '',
      packageType: data['trialPackage']?.toString() ?? '',
      sessionsLeft: (data['sessionsLeft'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      isTrial: data['isTrial'] as bool? ?? false,
      trialStatus: data['trialStatus']?.toString() ?? '',
      trialPackage: data['trialPackage']?.toString() ?? '',
      studentApprovalStatus: data['studentApprovalStatus']?.toString() ?? '',
      invoiceCreated: data['invoiceCreated'] as bool? ?? false,
    );
  }
}

// 🔥 TEACHER DROPDOWN MODEL
class TeacherDropdown {
  final String id;
  final String name;

  TeacherDropdown({required this.id, required this.name});
}

// 🔥 PACKAGE DROPDOWN MODEL
class PackageDropdown {
  final String id;
  final String name;
  final int sessions;
  final double price;

  PackageDropdown({
    required this.id,
    required this.name,
    required this.sessions,
    required this.price,
  });
}