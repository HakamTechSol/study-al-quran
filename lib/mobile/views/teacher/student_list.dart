// import 'package:studyalquran/mobile/views/chat/TeacherChatScreen.dart';
// import 'package:studyalquran/utils/app_text_styles.dart';
// import 'package:studyalquran/utils/color_constants.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:rxdart/rxdart.dart';

// // import 'package:studyalquran/mobile/views/chat/teacherdetailsscreen.dart';

// // 🔥 UPDATED STUDENT MODEL WITH TRIAL INFO
// class StudentWithSchedule {
//   final String studentId;
//   final String studentName;
//   final String? packageName;
//   final String? phone;
//   final String? email;
//   final String? region;
//   final int totalScheduledClasses;
//   final int upcomingClasses;
//   final int completedClasses;
//   final int missedClasses;
//   final DateTime? nextClassDate;
//   final String? nextClassTime;
//   final bool isTrial;
//   final String trialStatus;
//   final String? trialAssignmentId; // 🔥 NEW: For trial assignments

//   StudentWithSchedule({
//     required this.studentId,
//     required this.studentName,
//     this.packageName,
//     this.phone,
//     this.email,
//     this.region,
//     required this.totalScheduledClasses,
//     required this.upcomingClasses,
//     required this.completedClasses,
//     required this.missedClasses,
//     this.nextClassDate,
//     this.nextClassTime,
//     this.isTrial = false,
//     this.trialStatus = 'pending',
//     this.trialAssignmentId, // 🔥 NEW
//   });
// }

// class StudentsListScreen extends StatefulWidget {
//   const StudentsListScreen({super.key});

//   @override
//   State<StudentsListScreen> createState() => _StudentsListScreenState();
// }

// class _StudentsListScreenState extends State<StudentsListScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // 🔥 COMBINE REGULAR + TRIAL STUDENTS
//   Stream<List<StudentWithSchedule>> _getAllStudents() {
//     return Rx.combineLatest2(_getStudentsFromSchedules(), _getTrialStudents(), (
//       List<StudentWithSchedule> regularStudents,
//       List<StudentWithSchedule> trialStudents,
//     ) {
//       List<StudentWithSchedule> allStudents = [
//         ...regularStudents,
//         ...trialStudents,
//       ];

//       allStudents.sort((a, b) {
//         if (a.isTrial && !b.isTrial) return -1;
//         if (!a.isTrial && b.isTrial) return 1;
//         return a.studentName.compareTo(b.studentName);
//       });

//       return allStudents;
//     });
//   }

//   // 🔥 GET REGULAR STUDENTS FROM SCHEDULES
//   Stream<List<StudentWithSchedule>> _getStudentsFromSchedules() async* {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) {
//       yield [];
//       return;
//     }

//     await for (var schedulesSnapshot
//         in _firestore
//             .collection('schedules')
//             .where('teacherId', isEqualTo: currentUserId)
//             .snapshots()) {
//       Map<String, List<QueryDocumentSnapshot>> studentSchedulesMap = {};

//       for (var doc in schedulesSnapshot.docs) {
//         String studentId = doc['studentId'] ?? '';
//         if (studentId.isNotEmpty) {
//           if (!studentSchedulesMap.containsKey(studentId)) {
//             studentSchedulesMap[studentId] = [];
//           }
//           studentSchedulesMap[studentId]!.add(doc);
//         }
//       }

//       List<StudentWithSchedule> students = [];

//       for (var entry in studentSchedulesMap.entries) {
//         String studentId = entry.key;
//         List<QueryDocumentSnapshot> schedules = entry.value;

//         // Get student details
//         String studentName = 'Unknown Student';
//         String? phone, email, region, packageName;

//         try {
//           var studentDoc = await _firestore
//               .collection('students')
//               .doc(studentId)
//               .get();
//           if (studentDoc.exists) {
//             var data = studentDoc.data() as Map<String, dynamic>;
//             studentName = data['name'] ?? 'Unknown Student';
//             phone = data['phone'];
//             email = data['email'];
//             region = data['class'];

//             bool isTrial = data['isTrial'] ?? false;
//             if (isTrial) {
//               continue;
//             }
//           }
//         } catch (e) {
//           print('Error fetching student: $e');
//         }

//         if (schedules.isNotEmpty) {
//           packageName = schedules.first['packageName'];
//         }

//         // Calculate statistics
//         int totalClasses = schedules.length;
//         int upcomingClasses = schedules.where((s) {
//           final status = s['status']?.toString().toLowerCase() ?? '';
//           return status == 'upcoming' || status == 'scheduled';
//         }).length;

//         int completedClasses = schedules.where((s) {
//           final status = s['status']?.toString().toLowerCase() ?? '';
//           return status == 'completed' ||
//               status == 'attended' ||
//               status == 'done';
//         }).length;

//         int missedClasses = schedules.where((s) {
//           final status = s['status']?.toString().toLowerCase() ?? '';
//           return status == 'missed' ||
//               status == 'absent' ||
//               status == 'cancelled';
//         }).length;

//         // Find next upcoming class
//         DateTime? nextClassDate;
//         String? nextClassTime;

//         var upcomingSchedules = schedules.where((s) {
//           final status = s['status']?.toString().toLowerCase() ?? '';
//           return status == 'upcoming' || status == 'scheduled';
//         }).toList();

//         if (upcomingSchedules.isNotEmpty) {
//           upcomingSchedules.sort((a, b) {
//             String dateA = a['date'] ?? '';
//             String dateB = b['date'] ?? '';
//             return dateA.compareTo(dateB);
//           });

//           try {
//             String dateStr = upcomingSchedules.first['date'] ?? '';
//             if (dateStr.isNotEmpty) {
//               nextClassDate = DateTime.parse(dateStr);
//               nextClassTime = upcomingSchedules.first['time'] ?? '';
//             }
//           } catch (e) {
//             print('Error parsing date: $e');
//           }
//         }

//         students.add(
//           StudentWithSchedule(
//             studentId: studentId,
//             studentName: studentName,
//             packageName: packageName,
//             phone: phone,
//             email: email,
//             region: region,
//             totalScheduledClasses: totalClasses,
//             upcomingClasses: upcomingClasses,
//             completedClasses: completedClasses,
//             missedClasses: missedClasses,
//             nextClassDate: nextClassDate,
//             nextClassTime: nextClassTime,
//             isTrial: false,
//             trialStatus: '',
//           ),
//         );
//       }

//       yield students;
//     }
//   }

//   // 🔥 GET TRIAL STUDENTS (WITHOUT SCHEDULES)
//   Stream<List<StudentWithSchedule>> _getTrialStudents() async* {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) {
//       yield [];
//       return;
//     }

//     await for (var studentsSnapshot
//         in _firestore
//             .collection('students')
//             .where('assignedTeacherId', isEqualTo: currentUserId)
//             .where('isTrial', isEqualTo: true)
//             .where(
//               'trialStatus',
//               whereIn: ['pending', 'scheduled', 'completed'],
//             )
//             .snapshots()) {
//       List<StudentWithSchedule> trialStudents = [];

//       for (var doc in studentsSnapshot.docs) {
//         var data = doc.data();

//         // 🔥 GET TRIAL ASSIGNMENT ID
//         String? trialAssignmentId;
//         try {
//           var trialAssignmentSnapshot = await _firestore
//               .collection('trialAssignments')
//               .where('studentId', isEqualTo: doc.id)
//               .where('teacherId', isEqualTo: currentUserId)
//               .limit(1)
//               .get();

//           if (trialAssignmentSnapshot.docs.isNotEmpty) {
//             trialAssignmentId = trialAssignmentSnapshot.docs.first.id;
//           }
//         } catch (e) {
//           print('Error fetching trial assignment: $e');
//         }

//         trialStudents.add(
//           StudentWithSchedule(
//             studentId: doc.id,
//             studentName: data['name'] ?? 'Unknown Student',
//             packageName: data['trialPackage'] ?? 'Trial Package',
//             phone: data['phone'],
//             email: data['email'],
//             region: data['class'],
//             totalScheduledClasses: 0,
//             upcomingClasses: 0,
//             completedClasses: 0,
//             missedClasses: 0,
//             nextClassDate: null,
//             nextClassTime: null,
//             isTrial: true,
//             trialStatus: data['trialStatus'] ?? 'pending',
//             trialAssignmentId: trialAssignmentId, // 🔥 ASSIGN ID
//           ),
//         );
//       }

//       yield trialStudents;
//     }
//   }

//   // 🔥 UPDATE TRIAL STATUS FUNCTION
//   Future<void> _updateTrialStatus(
//     StudentWithSchedule student,
//     String newStatus,
//   ) async {
//     try {
//       // Update student collection
//       await _firestore.collection('students').doc(student.studentId).update({
//         'trialStatus': newStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // Update trialAssignments collection if exists
//       if (student.trialAssignmentId != null) {
//         await _firestore
//             .collection('trialAssignments')
//             .doc(student.trialAssignmentId)
//             .update({
//               'status': newStatus,
//               'updatedAt': FieldValue.serverTimestamp(),
//               if (newStatus == 'completed') 'trialCompleted': true,
//             });
//       }

//       // Show success message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Trial status updated to ${_getTrialStatusText(newStatus)}',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error updating trial status: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error updating status: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // 🔥 SHOW STATUS CHANGE DIALOG
//   void _showTrialStatusDialog(StudentWithSchedule student) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.flag, color: Colors.orange),
//             SizedBox(width: 8),
//             Text('Update Trial Status'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               student.studentName,
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Current: ${_getTrialStatusText(student.trialStatus)}',
//               style: TextStyle(color: Colors.grey),
//             ),
//             SizedBox(height: 16),
//             Text('Select new status:'),
//             SizedBox(height: 8),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           // 🔥 STATUS OPTIONS
//           if (student.trialStatus != 'scheduled')
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _updateTrialStatus(student, 'scheduled');
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//               child: Text('Mark as Scheduled'),
//             ),
//           if (student.trialStatus != 'completed')
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _updateTrialStatus(student, 'completed');
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//               child: Text('Mark as Completed'),
//             ),
//         ],
//       ),
//     );
//   }

//   List<StudentWithSchedule> _filterStudents(
//     List<StudentWithSchedule> students,
//   ) {
//     if (_searchQuery.isEmpty) return students;
//     return students.where((student) {
//       return student.studentName.toLowerCase().contains(
//             _searchQuery.toLowerCase(),
//           ) ||
//           (student.packageName?.toLowerCase().contains(
//                 _searchQuery.toLowerCase(),
//               ) ??
//               false) ||
//           (student.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
//               false);
//     }).toList();
//   }

//   // 🔥 UPDATED: NAVIGATE TO CHAT SCREEN
//   void _navigateToChatScreen(StudentWithSchedule student) {
//     final currentUserId = _auth.currentUser?.uid;

//     if (currentUserId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please login to start chat'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => TeacherChatScreen(
//           otherUserId: student.studentId,
//           otherUserName: student.studentName,
//           currentUserId: currentUserId,
//           currentUserRole: 'teacher',
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         title: Text('My Students', style: AppTextStyles.appBarTitle),
//         centerTitle: true,
//         // leading: IconButton(
//         //   icon: Icon(Icons.menu, color: AppColors.white, size: 22),
//         //   onPressed: () {},
//         // ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.notifications_none,
//               color: AppColors.white,
//               size: 22,
//             ),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Header Section
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [AppColors.primary, AppColors.gradient],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(24),
//                 bottomRight: Radius.circular(24),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.primary.withOpacity(0.3),
//                   blurRadius: 12,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Stats Cards
//                 StreamBuilder<List<StudentWithSchedule>>(
//                   stream: _getAllStudents(),
//                   builder: (context, snapshot) {
//                     final totalStudents = snapshot.hasData
//                         ? snapshot.data!.length
//                         : 0;
//                     final regularStudents = snapshot.hasData
//                         ? snapshot.data!.where((s) => !s.isTrial).length
//                         : 0;
//                     final trialStudents = snapshot.hasData
//                         ? snapshot.data!.where((s) => s.isTrial).length
//                         : 0;

//                     return Row(
//                       children: [
//                         Expanded(
//                           child: _buildCompactStatCard(
//                             'Total',
//                             totalStudents.toString(),
//                             Icons.people_alt_outlined,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _buildCompactStatCard(
//                             'Regular',
//                             regularStudents.toString(),
//                             Icons.check_circle_outline,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _buildCompactStatCard(
//                             'Trial',
//                             trialStudents.toString(),
//                             Icons.flag,
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 14),

//                 // Search Bar
//                 Container(
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: AppColors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: AppColors.white.withOpacity(0.3),
//                       width: 1,
//                     ),
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     style: AppTextStyles.inputValue.copyWith(
//                       fontSize: 14,
//                       color: AppColors.white,
//                     ),
//                     onChanged: (value) {
//                       setState(() => _searchQuery = value);
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search students...',
//                       hintStyle: AppTextStyles.inputHint.copyWith(
//                         fontSize: 13,
//                         color: AppColors.white.withOpacity(0.7),
//                       ),
//                       prefixIcon: Icon(
//                         Icons.search,
//                         color: AppColors.white.withOpacity(0.7),
//                         size: 20,
//                       ),
//                       suffixIcon: _searchQuery.isNotEmpty
//                           ? IconButton(
//                               icon: Icon(
//                                 Icons.clear,
//                                 color: AppColors.white.withOpacity(0.7),
//                                 size: 18,
//                               ),
//                               onPressed: () {
//                                 _searchController.clear();
//                                 setState(() => _searchQuery = '');
//                               },
//                             )
//                           : null,
//                       border: InputBorder.none,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 12),

//           // Students List Header
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'My Students',
//                   style: AppTextStyles.heading3.copyWith(
//                     color: AppColors.text,
//                     fontSize: 18,
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.sort, color: AppColors.primary, size: 14),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Sort',
//                         style: AppTextStyles.captionText.copyWith(
//                           color: AppColors.primary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 8),

//           // Students List
//           Expanded(
//             child: StreamBuilder<List<StudentWithSchedule>>(
//               stream: _getAllStudents(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return _buildShimmerLoading();
//                 }

//                 if (snapshot.hasError) {
//                   return _buildErrorState('Error loading students');
//                 }

//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return _buildEmptyState('No students assigned yet');
//                 }

//                 final filteredStudents = _filterStudents(snapshot.data!);

//                 if (filteredStudents.isEmpty) {
//                   return _buildEmptyState(
//                     'No students found for "$_searchQuery"',
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   itemCount: filteredStudents.length,
//                   itemBuilder: (context, index) {
//                     final student = filteredStudents[index];
//                     return student.isTrial
//                         ? _buildTrialStudentCard(student)
//                         : _buildRegularStudentCard(student);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔥 REGULAR STUDENT CARD
//   Widget _buildRegularStudentCard(StudentWithSchedule student) {
//     final cardColor = _getColorFromName(student.studentName);
//     final progress = student.totalScheduledClasses > 0
//         ? student.completedClasses / student.totalScheduledClasses
//         : 0.0;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: AppColors.card,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.isDarkMode
//                 ? AppColors.black.withOpacity(0.2)
//                 : AppColors.grey.withOpacity(0.08),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _showStudentDetails(student),
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: const EdgeInsets.all(14),
//             child: Row(
//               children: [
//                 // Avatar
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [cardColor, cardColor.withOpacity(0.7)],
//                     ),
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: cardColor.withOpacity(0.3),
//                         blurRadius: 8,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: Center(
//                     child: Text(
//                       _getInitials(student.studentName),
//                       style: AppTextStyles.heading3.copyWith(
//                         color: AppColors.white,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Student Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               student.studentName,
//                               style: AppTextStyles.cardTitle.copyWith(
//                                 fontSize: 15,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Icon(
//                             Icons.arrow_forward_ios,
//                             size: 12,
//                             color: AppColors.subtitle,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 5),

//                       // Progress Bar
//                       Container(
//                         height: 5,
//                         decoration: BoxDecoration(
//                           color: AppColors.background,
//                           borderRadius: BorderRadius.circular(2.5),
//                         ),
//                         child: FractionallySizedBox(
//                           alignment: Alignment.centerLeft,
//                           widthFactor: progress.clamp(0.0, 1.0),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [cardColor, cardColor.withOpacity(0.7)],
//                               ),
//                               borderRadius: BorderRadius.circular(2.5),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 5),

//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             '${student.completedClasses}/${student.totalScheduledClasses} classes',
//                             style: AppTextStyles.captionText.copyWith(
//                               color: AppColors.subtitle,
//                               fontSize: 10,
//                             ),
//                           ),
//                           Text(
//                             '${(progress * 100).round()}%',
//                             style: AppTextStyles.captionText.copyWith(
//                               color: cardColor,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 🔥 UPDATED TRIAL STUDENT CARD WITH STATUS CHANGE
//   Widget _buildTrialStudentCard(StudentWithSchedule student) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.orange.withOpacity(0.3)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.orange.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _showTrialStudentOptions(student),
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: const EdgeInsets.all(14),
//             child: Row(
//               children: [
//                 // Trial Avatar with Chat Icon
//                 Stack(
//                   children: [
//                     Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.orange, Colors.orange.shade400],
//                         ),
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.orange.withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Icon(
//                           Icons.chat,
//                           color: AppColors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: Container(
//                         padding: const EdgeInsets.all(3),
//                         decoration: BoxDecoration(
//                           color: AppColors.white,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(Icons.flag, size: 12, color: Colors.orange),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(width: 12),

//                 // Trial Student Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               student.studentName,
//                               style: AppTextStyles.cardTitle.copyWith(
//                                 fontSize: 15,
//                                 color: Colors.orange.shade800,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           // 🔥 STATUS BADGE
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _getTrialStatusColor(
//                                 student.trialStatus,
//                               ).withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               _getTrialStatusText(student.trialStatus),
//                               style: AppTextStyles.captionText.copyWith(
//                                 color: _getTrialStatusColor(
//                                   student.trialStatus,
//                                 ),
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // Trial Info
//                       Wrap(
//                         spacing: 6,
//                         runSpacing: 4,
//                         children: [
//                           if (student.packageName != null)
//                             _buildInfoChip(
//                               Icons.card_giftcard,
//                               student.packageName!,
//                               Colors.orange,
//                             ),
//                           if (student.email != null)
//                             _buildInfoChip(
//                               Icons.email,
//                               student.email!,
//                               Colors.blue,
//                             ),
//                           _buildInfoChip(
//                             Icons.schedule,
//                             'Coordinate timing',
//                             Colors.purple,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // 🔥 ACTION MESSAGE
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.touch_app,
//                               size: 10,
//                               color: Colors.orange,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               'Tap for options',
//                               style: AppTextStyles.captionText.copyWith(
//                                 color: Colors.orange,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 🔥 SHOW TRIAL STUDENT OPTIONS
//   void _showTrialStudentOptions(StudentWithSchedule student) {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Header
//             Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.orange, Colors.orange.shade400],
//                     ),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(Icons.flag, color: Colors.white, size: 20),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         student.studentName,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 2),
//                       Text(
//                         'Trial Student',
//                         style: TextStyle(color: Colors.orange, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),

//             // Status Info
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Current Status:'),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: _getTrialStatusColor(
//                         student.trialStatus,
//                       ).withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       _getTrialStatusText(student.trialStatus),
//                       style: TextStyle(
//                         color: _getTrialStatusColor(student.trialStatus),
//                         fontWeight: FontWeight.w600,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16),

//             // 🔥 ACTION BUTTONS
//             Column(
//               children: [
//                 // CHAT BUTTON
//                 Container(
//                   width: double.infinity,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.blue, Colors.blue.shade400],
//                     ),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(10),
//                       onTap: () {
//                         Navigator.pop(context);
//                         _navigateToChatScreen(student);
//                       },
//                       child: Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.chat, size: 20, color: Colors.white),
//                             SizedBox(width: 8),
//                             Text(
//                               'Open Chat',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 10),

//                 // STATUS CHANGE BUTTONS
//                 if (student.trialStatus != 'scheduled')
//                   _buildStatusButton(
//                     'Mark as Scheduled',
//                     Icons.schedule,
//                     Colors.blue,
//                     () {
//                       Navigator.pop(context);
//                       _updateTrialStatus(student, 'scheduled');
//                     },
//                   ),

//                 if (student.trialStatus != 'completed')
//                   _buildStatusButton(
//                     'Mark Trial as Completed',
//                     Icons.check_circle,
//                     Colors.green,
//                     () {
//                       Navigator.pop(context);
//                       _updateTrialStatus(student, 'completed');
//                     },
//                   ),

//                 SizedBox(height: 10),

//                 // CANCEL BUTTON
//                 Container(
//                   width: double.infinity,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(10),
//                       onTap: () => Navigator.pop(context),
//                       child: Center(
//                         child: Text(
//                           'Cancel',
//                           style: TextStyle(
//                             color: Colors.grey.shade700,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusButton(
//     String text,
//     IconData icon,
//     Color color,
//     VoidCallback onPressed,
//   ) {
//     return Container(
//       width: double.infinity,
//       height: 50,
//       margin: EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(10),
//           onTap: onPressed,
//           child: Center(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, size: 20, color: color),
//                 SizedBox(width: 8),
//                 Text(
//                   text,
//                   style: TextStyle(
//                     color: color,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 🔥 TRIAL STATUS HELPERS
//   Color _getTrialStatusColor(String status) {
//     switch (status) {
//       case 'scheduled':
//         return Colors.blue;
//       case 'pending':
//         return Colors.orange;
//       case 'completed':
//         return Colors.green;
//       case 'approved':
//         return Colors.green;
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getTrialStatusIcon(String status) {
//     switch (status) {
//       case 'scheduled':
//         return Icons.schedule;
//       case 'pending':
//         return Icons.pending;
//       case 'completed':
//         return Icons.check_circle;
//       case 'approved':
//         return Icons.thumb_up;
//       case 'rejected':
//         return Icons.thumb_down;
//       default:
//         return Icons.help;
//     }
//   }

//   String _getTrialStatusText(String status) {
//     switch (status) {
//       case 'scheduled':
//         return 'Scheduled';
//       case 'pending':
//         return 'Pending';
//       case 'completed':
//         return 'Completed';
//       case 'approved':
//         return 'Approved';
//       case 'rejected':
//         return 'Rejected';
//       default:
//         return 'Trial';
//     }
//   }

//   // ... (Rest of the helper methods remain same as before)
//   Widget _buildCompactStatCard(String title, String value, IconData icon) {
//     Color iconColor = AppColors.white;
//     if (title == 'Trial') iconColor = Colors.orange.shade200;
//     if (title == 'Regular') iconColor = Colors.green.shade200;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: AppColors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.white.withOpacity(0.2), width: 1),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: AppColors.white.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, size: 16, color: iconColor),
//           ),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 value,
//                 style: AppTextStyles.heading3.copyWith(
//                   color: AppColors.white,
//                   fontSize: 18,
//                 ),
//               ),
//               Text(
//                 title,
//                 style: AppTextStyles.captionText.copyWith(
//                   color: AppColors.white.withOpacity(0.8),
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   void _showStudentDetails(StudentWithSchedule student) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: student.isTrial
//                     ? Colors.orange.withOpacity(0.1)
//                     : AppColors.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 student.isTrial ? Icons.flag : Icons.person,
//                 color: student.isTrial ? Colors.orange : AppColors.primary,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(student.studentName, style: AppTextStyles.heading5),
//                   if (student.isTrial)
//                     Text(
//                       'Trial Student',
//                       style: AppTextStyles.captionText.copyWith(
//                         color: Colors.orange,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (student.packageName != null)
//                 _buildDetailRow('Package', student.packageName!),
//               if (student.phone != null)
//                 _buildDetailRow('Phone', student.phone!),
//               if (student.email != null)
//                 _buildDetailRow('Email', student.email!),
//               if (student.region != null)
//                 _buildDetailRow('Region', student.region!),

//               if (!student.isTrial) ...[
//                 _buildDetailRow(
//                   'Total Classes',
//                   '${student.totalScheduledClasses}',
//                 ),
//                 _buildDetailRow(
//                   'Completed',
//                   '${student.completedClasses}',
//                   Colors.green,
//                 ),
//                 _buildDetailRow(
//                   'Upcoming',
//                   '${student.upcomingClasses}',
//                   Colors.orange,
//                 ),
//                 _buildDetailRow(
//                   'Missed',
//                   '${student.missedClasses}',
//                   Colors.red,
//                 ),
//               ],

//               if (student.isTrial) ...[
//                 const Divider(height: 20),
//                 _buildDetailRow(
//                   'Trial Status',
//                   _getTrialStatusText(student.trialStatus),
//                   _getTrialStatusColor(student.trialStatus),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '💬 Coordinate trial timing via chat with the student',
//                   style: AppTextStyles.bodySmall.copyWith(
//                     color: Colors.orange.shade700,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   width: double.infinity,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.orange, Colors.orange.shade400],
//                     ),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(10),
//                       onTap: () {
//                         Navigator.pop(context);
//                         _navigateToChatScreen(student);
//                       },
//                       child: Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.chat, size: 18, color: Colors.white),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Open Chat',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: TextStyle(color: AppColors.primary)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
//           ),
//           Text(
//             value,
//             style: AppTextStyles.labelText.copyWith(
//               color: valueColor ?? AppColors.text,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoChip(IconData icon, String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: color),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: AppTextStyles.captionText.copyWith(
//               fontSize: 10,
//               color: color,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildShimmerLoading() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: 6,
//       itemBuilder: (context, index) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 10),
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color: AppColors.card,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: AppColors.grey.withOpacity(0.3),
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       width: 100,
//                       height: 14,
//                       decoration: BoxDecoration(
//                         color: AppColors.grey.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Container(
//                       width: double.infinity,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: AppColors.grey.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(2.5),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Container(
//                       width: 60,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         color: AppColors.grey.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 100,
//             height: 100,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.people_outline,
//               size: 45,
//               color: AppColors.primary.withOpacity(0.5),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: AppTextStyles.heading3.copyWith(
//               color: AppColors.subtitle,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'Students with scheduled classes will appear here',
//             style: AppTextStyles.bodySmall.copyWith(
//               color: AppColors.subtitle,
//               fontSize: 12,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.error_outline,
//             size: 60,
//             color: Colors.red.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: AppTextStyles.heading3.copyWith(color: AppColors.subtitle),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () => setState(() {}),
//             style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
//             child: Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getInitials(String name) {
//     List<String> names = name.split(' ');
//     if (names.length >= 2) {
//       return '${names[0][0]}${names[1][0]}'.toUpperCase();
//     }
//     return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
//   }

//   Color _getColorFromName(String name) {
//     final colors = [
//       Colors.blue,
//       Colors.purple,
//       Colors.orange,
//       Colors.green,
//       Colors.teal,
//       Colors.pink,
//       Colors.indigo,
//       Colors.cyan,
//     ];
//     return colors[name.length % colors.length];
//   }
// }
import 'package:studyalquran/mobile/views/chat/TeacherChatScreen.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

// import 'package:studyalquran/mobile/views/chat/teacherdetailsscreen.dart';

// 🔥 UPDATED STUDENT MODEL WITH TRIAL INFO
class StudentWithSchedule {
  final String studentId;
  final String studentName;
  final String? packageName;
  final String? phone;
  final String? email;
  final String? region;
  final int totalScheduledClasses;
  final int upcomingClasses;
  final int completedClasses;
  final int missedClasses;
  final DateTime? nextClassDate;
  final String? nextClassTime;
  final bool isTrial;
  final String trialStatus;
  final String? trialAssignmentId; // 🔥 NEW: For trial assignments

  StudentWithSchedule({
    required this.studentId,
    required this.studentName,
    this.packageName,
    this.phone,
    this.email,
    this.region,
    required this.totalScheduledClasses,
    required this.upcomingClasses,
    required this.completedClasses,
    required this.missedClasses,
    this.nextClassDate,
    this.nextClassTime,
    this.isTrial = false,
    this.trialStatus = 'pending',
    this.trialAssignmentId, // 🔥 NEW
  });
}

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 COMBINE REGULAR + TRIAL STUDENTS
  Stream<List<StudentWithSchedule>> _getAllStudents() {
    return Rx.combineLatest2(_getStudentsFromSchedules(), _getTrialStudents(), (
      List<StudentWithSchedule> regularStudents,
      List<StudentWithSchedule> trialStudents,
    ) {
      List<StudentWithSchedule> allStudents = [
        ...regularStudents,
        ...trialStudents,
      ];

      allStudents.sort((a, b) {
        if (a.isTrial && !b.isTrial) return -1;
        if (!a.isTrial && b.isTrial) return 1;
        return a.studentName.compareTo(b.studentName);
      });

      return allStudents;
    });
  }

  // 🔥 GET REGULAR STUDENTS FROM SCHEDULES
  Stream<List<StudentWithSchedule>> _getStudentsFromSchedules() async* {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      yield [];
      return;
    }

    await for (var schedulesSnapshot
        in _firestore
            .collection('schedules')
            .where('teacherId', isEqualTo: currentUserId)
            .snapshots()) {
      Map<String, List<QueryDocumentSnapshot>> studentSchedulesMap = {};

      for (var doc in schedulesSnapshot.docs) {
        String studentId = doc['studentId'] ?? '';
        if (studentId.isNotEmpty) {
          if (!studentSchedulesMap.containsKey(studentId)) {
            studentSchedulesMap[studentId] = [];
          }
          studentSchedulesMap[studentId]!.add(doc);
        }
      }

      List<StudentWithSchedule> students = [];

      for (var entry in studentSchedulesMap.entries) {
        String studentId = entry.key;
        List<QueryDocumentSnapshot> schedules = entry.value;

        // Get student details
        String studentName = 'Unknown Student';
        String? phone, email, region, packageName;

        try {
          var studentDoc = await _firestore
              .collection('students')
              .doc(studentId)
              .get();
          if (studentDoc.exists) {
            var data = studentDoc.data() as Map<String, dynamic>;
            studentName = data['name'] ?? 'Unknown Student';
            // 🔥 FIX #4: HIDE PHONE AND EMAIL FROM TEACHER
            phone = null; // REMOVED: data['phone'];
            email = null; // REMOVED: data['email'];
            region = data['class'];

            bool isTrial = data['isTrial'] ?? false;
            if (isTrial) {
              continue;
            }
          }
        } catch (e) {
          print('Error fetching student: $e');
        }

        if (schedules.isNotEmpty) {
          packageName = schedules.first['packageName'];
        }

        // Calculate statistics
        int totalClasses = schedules.length;
        int upcomingClasses = schedules.where((s) {
          final status = s['status']?.toString().toLowerCase() ?? '';
          return status == 'upcoming' || status == 'scheduled';
        }).length;

        int completedClasses = schedules.where((s) {
          final status = s['status']?.toString().toLowerCase() ?? '';
          return status == 'completed' ||
              status == 'attended' ||
              status == 'done';
        }).length;

        int missedClasses = schedules.where((s) {
          final status = s['status']?.toString().toLowerCase() ?? '';
          return status == 'missed' ||
              status == 'absent' ||
              status == 'cancelled';
        }).length;

        // Find next upcoming class
        DateTime? nextClassDate;
        String? nextClassTime;

        var upcomingSchedules = schedules.where((s) {
          final status = s['status']?.toString().toLowerCase() ?? '';
          return status == 'upcoming' || status == 'scheduled';
        }).toList();

        if (upcomingSchedules.isNotEmpty) {
          upcomingSchedules.sort((a, b) {
            String dateA = a['date'] ?? '';
            String dateB = b['date'] ?? '';
            return dateA.compareTo(dateB);
          });

          try {
            String dateStr = upcomingSchedules.first['date'] ?? '';
            if (dateStr.isNotEmpty) {
              nextClassDate = DateTime.parse(dateStr);
              nextClassTime = upcomingSchedules.first['time'] ?? '';
            }
          } catch (e) {
            print('Error parsing date: $e');
          }
        }

        students.add(
          StudentWithSchedule(
            studentId: studentId,
            studentName: studentName,
            packageName: packageName,
            phone: phone,
            email: email,
            region: region,
            totalScheduledClasses: totalClasses,
            upcomingClasses: upcomingClasses,
            completedClasses: completedClasses,
            missedClasses: missedClasses,
            nextClassDate: nextClassDate,
            nextClassTime: nextClassTime,
            isTrial: false,
            trialStatus: '',
          ),
        );
      }

      yield students;
    }
  }

  // 🔥 GET TRIAL STUDENTS (WITHOUT SCHEDULES)
  Stream<List<StudentWithSchedule>> _getTrialStudents() async* {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      yield [];
      return;
    }

    await for (var studentsSnapshot
        in _firestore
            .collection('students')
            .where('assignedTeacherId', isEqualTo: currentUserId)
            .where('isTrial', isEqualTo: true)
            .where(
              'trialStatus',
              whereIn: ['pending', 'scheduled', 'completed'],
            )
            .snapshots()) {
      List<StudentWithSchedule> trialStudents = [];

      for (var doc in studentsSnapshot.docs) {
        var data = doc.data();

        // 🔥 GET TRIAL ASSIGNMENT ID
        String? trialAssignmentId;
        try {
          var trialAssignmentSnapshot = await _firestore
              .collection('trialAssignments')
              .where('studentId', isEqualTo: doc.id)
              .where('teacherId', isEqualTo: currentUserId)
              .limit(1)
              .get();

          if (trialAssignmentSnapshot.docs.isNotEmpty) {
            trialAssignmentId = trialAssignmentSnapshot.docs.first.id;
          }
        } catch (e) {
          print('Error fetching trial assignment: $e');
        }

        trialStudents.add(
          StudentWithSchedule(
            studentId: doc.id,
            studentName: data['name'] ?? 'Unknown Student',
            packageName: data['trialPackage'] ?? 'Trial Package',
            // 🔥 FIX #4: HIDE PHONE AND EMAIL FROM TEACHER FOR TRIAL STUDENTS AS WELL
            phone: null, // REMOVED: data['phone'],
            email: null, // REMOVED: data['email'],
            region: data['class'],
            totalScheduledClasses: 0,
            upcomingClasses: 0,
            completedClasses: 0,
            missedClasses: 0,
            nextClassDate: null,
            nextClassTime: null,
            isTrial: true,
            trialStatus: data['trialStatus'] ?? 'pending',
            trialAssignmentId: trialAssignmentId, // 🔥 ASSIGN ID
          ),
        );
      }

      yield trialStudents;
    }
  }

  // 🔥 UPDATE TRIAL STATUS FUNCTION
  Future<void> _updateTrialStatus(
    StudentWithSchedule student,
    String newStatus,
  ) async {
    try {
      // Update student collection
      await _firestore.collection('students').doc(student.studentId).update({
        'trialStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update trialAssignments collection if exists
      if (student.trialAssignmentId != null) {
        await _firestore
            .collection('trialAssignments')
            .doc(student.trialAssignmentId)
            .update({
              'status': newStatus,
              'updatedAt': FieldValue.serverTimestamp(),
              if (newStatus == 'completed') 'trialCompleted': true,
            });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trial status updated to ${_getTrialStatusText(newStatus)}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error updating trial status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔥 SHOW STATUS CHANGE DIALOG
  void _showTrialStatusDialog(StudentWithSchedule student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.flag, color: Colors.orange),
            SizedBox(width: 8),
            Text('Update Trial Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.studentName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Current: ${_getTrialStatusText(student.trialStatus)}',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text('Select new status:'),
            SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          // 🔥 STATUS OPTIONS
          if (student.trialStatus != 'scheduled')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateTrialStatus(student, 'scheduled');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Mark as Scheduled'),
            ),
          if (student.trialStatus != 'completed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateTrialStatus(student, 'completed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Mark as Completed'),
            ),
        ],
      ),
    );
  }

  List<StudentWithSchedule> _filterStudents(
    List<StudentWithSchedule> students,
  ) {
    if (_searchQuery.isEmpty) return students;
    return students.where((student) {
      return student.studentName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (student.packageName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
      // 🔥 FIX #4: REMOVED EMAIL FROM SEARCH SINCE TEACHER CAN'T SEE IT
    }).toList();
  }

  // 🔥 UPDATED: NAVIGATE TO CHAT SCREEN
  void _navigateToChatScreen(StudentWithSchedule student) {
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to start chat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherChatScreen(
          otherUserId: student.studentId,
          otherUserName: student.studentName,
          currentUserId: currentUserId,
          currentUserRole: 'teacher',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text('My Students', style: AppTextStyles.appBarTitle),
        centerTitle: true,
        // leading: IconButton(
        //   icon: Icon(Icons.menu, color: AppColors.white, size: 22),
        //   onPressed: () {},
        // ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: AppColors.white,
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.gradient],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Stats Cards
                StreamBuilder<List<StudentWithSchedule>>(
                  stream: _getAllStudents(),
                  builder: (context, snapshot) {
                    final totalStudents = snapshot.hasData
                        ? snapshot.data!.length
                        : 0;
                    final regularStudents = snapshot.hasData
                        ? snapshot.data!.where((s) => !s.isTrial).length
                        : 0;
                    final trialStudents = snapshot.hasData
                        ? snapshot.data!.where((s) => s.isTrial).length
                        : 0;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildCompactStatCard(
                            'Total',
                            totalStudents.toString(),
                            Icons.people_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCompactStatCard(
                            'Regular',
                            regularStudents.toString(),
                            Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCompactStatCard(
                            'Trial',
                            trialStudents.toString(),
                            Icons.flag,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Search Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.inputValue.copyWith(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      hintStyle: AppTextStyles.inputHint.copyWith(
                        fontSize: 13,
                        color: AppColors.white.withOpacity(0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.white.withOpacity(0.7),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Students List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Students',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.text,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Sort',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Students List
          Expanded(
            child: StreamBuilder<List<StudentWithSchedule>>(
              stream: _getAllStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (snapshot.hasError) {
                  return _buildErrorState('Error loading students');
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState('No students assigned yet');
                }

                final filteredStudents = _filterStudents(snapshot.data!);

                if (filteredStudents.isEmpty) {
                  return _buildEmptyState(
                    'No students found for "$_searchQuery"',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return student.isTrial
                        ? _buildTrialStudentCard(student)
                        : _buildRegularStudentCard(student);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 REGULAR STUDENT CARD
  Widget _buildRegularStudentCard(StudentWithSchedule student) {
    final cardColor = _getColorFromName(student.studentName);
    final progress = student.totalScheduledClasses > 0
        ? student.completedClasses / student.totalScheduledClasses
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode
                ? AppColors.black.withOpacity(0.2)
                : AppColors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStudentDetails(student),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardColor, cardColor.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(student.studentName),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              student.studentName,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.subtitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Progress Bar
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cardColor, cardColor.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${student.completedClasses}/${student.totalScheduledClasses} classes',
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.subtitle,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: AppTextStyles.captionText.copyWith(
                              color: cardColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 UPDATED TRIAL STUDENT CARD WITH STATUS CHANGE
  Widget _buildTrialStudentCard(StudentWithSchedule student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrialStudentOptions(student),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Trial Avatar with Chat Icon
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.orange.shade400],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chat,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.flag, size: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Trial Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              student.studentName,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 15,
                                color: Colors.orange.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 🔥 STATUS BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTrialStatusColor(
                                student.trialStatus,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTrialStatusText(student.trialStatus),
                              style: AppTextStyles.captionText.copyWith(
                                color: _getTrialStatusColor(
                                  student.trialStatus,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Trial Info - 🔥 FIX #4: REMOVED EMAIL FROM DISPLAY
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (student.packageName != null)
                            _buildInfoChip(
                              Icons.card_giftcard,
                              student.packageName!,
                              Colors.orange,
                            ),
                          _buildInfoChip(
                            Icons.schedule,
                            'Coordinate timing',
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 🔥 ACTION MESSAGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 10,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap for options',
                              style: AppTextStyles.captionText.copyWith(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 SHOW TRIAL STUDENT OPTIONS
  void _showTrialStudentOptions(StudentWithSchedule student) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.shade400],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Trial Student',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Status Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Status:'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTrialStatusColor(
                        student.trialStatus,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTrialStatusText(student.trialStatus),
                      style: TextStyle(
                        color: _getTrialStatusColor(student.trialStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 🔥 ACTION BUTTONS
            Column(
              children: [
                // CHAT BUTTON
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToChatScreen(student);
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Open Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // STATUS CHANGE BUTTONS
                if (student.trialStatus != 'scheduled')
                  _buildStatusButton(
                    'Mark as Scheduled',
                    Icons.schedule,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      _updateTrialStatus(student, 'scheduled');
                    },
                  ),

                if (student.trialStatus != 'completed')
                  _buildStatusButton(
                    'Mark Trial as Completed',
                    Icons.check_circle,
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      _updateTrialStatus(student, 'completed');
                    },
                  ),

                SizedBox(height: 10),

                // CANCEL BUTTON
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }

  Widget _buildStatusButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 TRIAL STATUS HELPERS
  Color _getTrialStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrialStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'pending':
        return Icons.pending;
      case 'completed':
        return Icons.check_circle;
      case 'approved':
        return Icons.thumb_up;
      case 'rejected':
        return Icons.thumb_down;
      default:
        return Icons.help;
    }
  }

  String _getTrialStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Trial';
    }
  }

  // ... (Rest of the helper methods remain same as before)
  Widget _buildCompactStatCard(String title, String value, IconData icon) {
    Color iconColor = AppColors.white;
    if (title == 'Trial') iconColor = Colors.orange.shade200;
    if (title == 'Regular') iconColor = Colors.green.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                title,
                style: AppTextStyles.captionText.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(StudentWithSchedule student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: student.isTrial
                    ? Colors.orange.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                student.isTrial ? Icons.flag : Icons.person,
                color: student.isTrial ? Colors.orange : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.studentName, style: AppTextStyles.heading5),
                  if (student.isTrial)
                    Text(
                      'Trial Student',
                      style: AppTextStyles.captionText.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (student.packageName != null)
                _buildDetailRow('Package', student.packageName!),
              // 🔥 FIX #4: REMOVED PHONE AND EMAIL FROM DETAILS DIALOG
              // Teacher should NOT see student's phone and email
              if (student.region != null)
                _buildDetailRow('Region', student.region!),

              if (!student.isTrial) ...[
                _buildDetailRow(
                  'Total Classes',
                  '${student.totalScheduledClasses}',
                ),
                _buildDetailRow(
                  'Completed',
                  '${student.completedClasses}',
                  Colors.green,
                ),
                _buildDetailRow(
                  'Upcoming',
                  '${student.upcomingClasses}',
                  Colors.orange,
                ),
                _buildDetailRow(
                  'Missed',
                  '${student.missedClasses}',
                  Colors.red,
                ),
              ],

              if (student.isTrial) ...[
                const Divider(height: 20),
                _buildDetailRow(
                  'Trial Status',
                  _getTrialStatusText(student.trialStatus),
                  _getTrialStatusColor(student.trialStatus),
                ),
                const SizedBox(height: 8),
                Text(
                  '💬 Coordinate trial timing via chat with the student',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToChatScreen(student);
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Open Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
          ),
          Text(
            value,
            style: AppTextStyles.labelText.copyWith(
              color: valueColor ?? AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.captionText.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 45,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.subtitle,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Students with scheduled classes will appear here',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.subtitle,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.heading3.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[name.length % colors.length];
  }
}
