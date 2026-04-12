// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:studyalquran/utils/app_text_styles.dart';
// import 'package:studyalquran/utils/color_constants.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:url_launcher/url_launcher.dart';

// class TeacherScheduleScreen extends StatefulWidget {
//   const TeacherScheduleScreen({super.key});

//   @override
//   State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
// }

// class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
//   int _currentView = 0; // 0: List, 1: Calendar
//   DateTime _selectedDate = DateTime.now();
//   DateTime _focusedDay = DateTime.now();
//   CalendarFormat _calendarFormat = CalendarFormat.month;

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String? get _currentTeacherId => _auth.currentUser?.uid;

//   String _teacherZoomLink = '';
//   bool _isLoadingZoomLink = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadTeacherZoomLink();
//   }

//   Future<void> _loadTeacherZoomLink() async {
//     try {
//       if (_currentTeacherId != null) {
//         final teacherDoc = await _firestore
//             .collection('teachers')
//             .doc(_currentTeacherId)
//             .get();

//         if (teacherDoc.exists) {
//           final data = teacherDoc.data()!;
//           setState(() {
//             _teacherZoomLink = data['zoomLink'] ?? '';
//           });
//         }

//         setState(() => _isLoadingZoomLink = false);
//       }
//     } catch (e) {
//       print('❌ Error loading Zoom link: $e');
//       setState(() => _isLoadingZoomLink = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_currentTeacherId == null) {
//       return Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(
//           child: Text(
//             'Please login to view your schedule',
//             style: AppTextStyles.bodyMedium,
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: _currentView == 0
//                   ? _buildListView()
//                   : _buildCalendarView(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('schedules')
//           .where('teacherId', isEqualTo: _currentTeacherId)
//           .snapshots(),
//       builder: (context, snapshot) {
//         int todayCount = 0;
//         int upcomingCount = 0;
//         int completedCount = 0;

//         if (snapshot.hasData) {
//           final now = DateTime.now();
//           final today = DateTime(now.year, now.month, now.day);

//           for (var doc in snapshot.data!.docs) {
//             final data = doc.data() as Map<String, dynamic>;
//             final dateStr = data['date'] as String?;
//             final status = data['status'] as String?;

//             if (dateStr != null) {
//               final scheduleDate = DateTime.parse(dateStr);
//               final scheduleDateOnly = DateTime(
//                 scheduleDate.year,
//                 scheduleDate.month,
//                 scheduleDate.day,
//               );

//               if (scheduleDateOnly.isAtSameMomentAs(today)) {
//                 todayCount++;
//               } else if (scheduleDateOnly.isAfter(today)) {
//                 upcomingCount++;
//               }

//               if (status == 'completed') {
//                 completedCount++;
//               }
//             }
//           }
//         }

//         return Container(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.primary, AppColors.gradient],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(24),
//               bottomRight: Radius.circular(24),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.primary.withOpacity(0.3),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'My Schedule',
//                     style: AppTextStyles.heading2.copyWith(
//                       color: AppColors.white,
//                       fontSize: 22,
//                     ),
//                   ),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: AppColors.white.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         _buildViewToggle(0, Icons.list, 'List'),
//                         _buildViewToggle(1, Icons.calendar_today, 'Calendar'),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildStatCard(
//                       'Today',
//                       todayCount.toString(),
//                       Icons.today,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: _buildStatCard(
//                       'Upcoming',
//                       upcomingCount.toString(),
//                       Icons.upcoming,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: _buildStatCard(
//                       'Completed',
//                       completedCount.toString(),
//                       Icons.check_circle,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildViewToggle(int index, IconData icon, String label) {
//     final isSelected = _currentView == index;
//     return InkWell(
//       onTap: () => setState(() => _currentView = index),
//       borderRadius: BorderRadius.circular(10),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.white.withOpacity(0.25)
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 16,
//               color: AppColors.white.withOpacity(isSelected ? 1.0 : 0.7),
//             ),
//             const SizedBox(width: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: AppColors.white.withOpacity(isSelected ? 1.0 : 0.7),
//                 fontSize: 12,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: AppColors.white.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.white.withOpacity(0.2)),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: 18, color: AppColors.white),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: AppTextStyles.heading3.copyWith(
//               color: AppColors.white,
//               fontSize: 16,
//             ),
//           ),
//           Text(
//             title,
//             style: TextStyle(
//               color: AppColors.white.withOpacity(0.8),
//               fontSize: 9,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildListView() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('schedules')
//           .where('teacherId', isEqualTo: _currentTeacherId)
//           .orderBy('date')
//           .orderBy('time')
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//             child: CircularProgressIndicator(color: AppColors.primary),
//           );
//         }

//         if (snapshot.hasError) {
//           return Center(
//             child: Text('Error loading schedules: ${snapshot.error}'),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.calendar_today_outlined,
//                   size: 64,
//                   color: AppColors.subtitle,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No schedules found',
//                   style: AppTextStyles.heading3.copyWith(
//                     color: AppColors.subtitle,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Your upcoming sessions will appear here',
//                   style: AppTextStyles.bodySmall.copyWith(
//                     color: AppColors.subtitle,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         final now = DateTime.now();
//         final today = DateTime(now.year, now.month, now.day);
//         final todaySessions = <Map<String, dynamic>>[];
//         final upcomingSessions = <Map<String, dynamic>>[];
//         final pastSessions = <Map<String, dynamic>>[];

//         for (var doc in snapshot.data!.docs) {
//           final data = doc.data() as Map<String, dynamic>;
//           data['docId'] = doc.id;
//           final dateStr = data['date'] as String?;

//           if (dateStr != null) {
//             final scheduleDate = DateTime.parse(dateStr);
//             final scheduleDateOnly = DateTime(
//               scheduleDate.year,
//               scheduleDate.month,
//               scheduleDate.day,
//             );

//             if (scheduleDateOnly.isAtSameMomentAs(today)) {
//               todaySessions.add(data);
//             } else if (scheduleDateOnly.isAfter(today)) {
//               upcomingSessions.add(data);
//             } else {
//               pastSessions.add(data);
//             }
//           }
//         }

//         return RefreshIndicator(
//           onRefresh: () async {
//             setState(() {});
//             await _loadTeacherZoomLink();
//           },
//           color: AppColors.primary,
//           child: ListView(
//             padding: const EdgeInsets.all(14),
//             children: [
//               if (todaySessions.isNotEmpty) ...[
//                 _buildSectionHeader(
//                   'Today\'s Sessions',
//                   Icons.today,
//                   Colors.green,
//                 ),
//                 const SizedBox(height: 10),
//                 ...todaySessions.map(
//                   (session) => _buildSessionCard(session, isToday: true),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//               if (upcomingSessions.isNotEmpty) ...[
//                 _buildSectionHeader(
//                   'Upcoming Sessions',
//                   Icons.upcoming,
//                   Colors.blue,
//                 ),
//                 const SizedBox(height: 10),
//                 ...upcomingSessions.map(
//                   (session) => _buildSessionCard(session, isToday: false),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//               if (pastSessions.isNotEmpty) ...[
//                 _buildSectionHeader(
//                   'Past Sessions',
//                   Icons.history,
//                   Colors.grey,
//                 ),
//                 const SizedBox(height: 10),
//                 ...pastSessions
//                     .take(5)
//                     .map((session) => _buildSessionCard(session, isPast: true)),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSectionHeader(String title, IconData icon, Color color) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, size: 16, color: color),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: AppTextStyles.heading3.copyWith(
//             color: AppColors.text,
//             fontSize: 16,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSessionCard(
//     Map<String, dynamic> session, {
//     bool isToday = false,
//     bool isPast = false,
//   }) {
//     final packageName = session['packageName'] ?? 'No Package';
//     final duration = session['duration'] ?? '60 min';
//     final time = session['time'] ?? '00:00';
//     final date = session['date'] ?? '';
//     final studentId = session['studentId'] ?? '';
//     final packageId = session['packageId'] ?? '';
//     final docId = session['docId'] ?? '';
//     final status = session['status'] ?? 'scheduled';
//     final attendanceStatus = session['attendanceStatus'];

//     // 🔥 CHECK: Class ka time guzar gaya hai ya nahi
//     bool isClassFinished = false;
//     try {
//       if (date.isNotEmpty && time.isNotEmpty) {
//         final classDateTime = DateTime.parse(date);
//         final timeParts = time.split(':');
//         final classTime = TimeOfDay(
//           hour: int.parse(timeParts[0]),
//           minute: int.parse(timeParts[1]),
//         );

//         // Class ke time ko DateTime mein convert karo
//         final classFullDateTime = DateTime(
//           classDateTime.year,
//           classDateTime.month,
//           classDateTime.day,
//           classTime.hour,
//           classTime.minute,
//         );

//         // Duration add karo (60 min default)
//         final durationMinutes =
//             int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60;
//         final classEndTime = classFullDateTime.add(
//           Duration(minutes: durationMinutes),
//         );

//         // Check karo ke class khatam ho gayi hai
//         final now = DateTime.now();
//         isClassFinished = now.isAfter(classEndTime);
//       }
//     } catch (e) {
//       print('❌ Error checking class time: $e');
//     }

//     return FutureBuilder<DocumentSnapshot>(
//       future: _firestore.collection('students').doc(studentId).get(),
//       builder: (context, studentSnapshot) {
//         String studentName = 'Student';
//         if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
//           final studentData =
//               studentSnapshot.data!.data() as Map<String, dynamic>?;
//           studentName = studentData?['name'] ?? 'Student';
//         }

//         return Container(
//           margin: const EdgeInsets.only(bottom: 10),
//           decoration: BoxDecoration(
//             color: AppColors.card,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.isDarkMode
//                     ? Colors.black.withOpacity(0.2)
//                     : Colors.grey.withOpacity(0.08),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//             border: isToday
//                 ? Border.all(
//                     color: AppColors.primary.withOpacity(0.3),
//                     width: 1.5,
//                   )
//                 : null,
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               borderRadius: BorderRadius.circular(16),
//               onTap: () => _showClassDetails(session, studentName, packageId),
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 5,
//                           ),
//                           decoration: BoxDecoration(
//                             color: isToday
//                                 ? AppColors.primary.withOpacity(0.1)
//                                 : AppColors.background,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.access_time,
//                                 size: 12,
//                                 color: isToday
//                                     ? AppColors.primary
//                                     : AppColors.subtitle,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 time,
//                                 style: TextStyle(
//                                   color: isToday
//                                       ? AppColors.primary
//                                       : AppColors.subtitle,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         _buildStatusBadge(
//                           status,
//                           attendanceStatus,
//                           isTrialClass: session['isTrialClass'] ?? false,
//                         ),
//                         const Spacer(),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Text(
//                             duration,
//                             style: TextStyle(
//                               color: Colors.blue.shade700,
//                               fontSize: 10,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [AppColors.primary, AppColors.gradient],
//                             ),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Center(
//                             child: Text(
//                               _getInitials(studentName),
//                               style: TextStyle(
//                                 color: AppColors.white,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 studentName,
//                                 style: AppTextStyles.cardTitle.copyWith(
//                                   fontSize: 14,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 packageName,
//                                 style: AppTextStyles.cardSubtitle.copyWith(
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),

//                     // 🔥 ATTENDANCE BUTTONS (Sirf class khatam hone ke baad)
//                     if (isClassFinished) ...[
//                       if (attendanceStatus == null)
//                         _buildAttendanceButtons(docId, studentId, packageId)
//                       else
//                         _buildAttendanceStatus(attendanceStatus),
//                       const SizedBox(height: 8),
//                     ],

//                     // JOIN BUTTON (Sirf future aur ongoing classes ke liye)
//                     if (!isClassFinished)
//                       Container(
//                         width: double.infinity,
//                         height: 38,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: isToday
//                                 ? [Colors.green, Colors.green.shade400]
//                                 : [AppColors.primary, AppColors.gradient],
//                           ),
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color:
//                                   (isToday ? Colors.green : AppColors.primary)
//                                       .withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(10),
//                             onTap: () => _launchZoom(_teacherZoomLink),
//                             child: Center(
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Icon(
//                                     Icons.video_camera_front,
//                                     size: 16,
//                                     color: Colors.white,
//                                   ),
//                                   const SizedBox(width: 6),
//                                   Text(
//                                     isToday ? 'Join Now' : 'Join Session',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),

//                     if (_teacherZoomLink.isEmpty &&
//                         !_isLoadingZoomLink &&
//                         !isClassFinished)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8),
//                         child: Row(
//                           children: [
//                             Icon(Icons.warning, size: 12, color: Colors.orange),
//                             SizedBox(width: 4),
//                             Text(
//                               'No Zoom link configured',
//                               style: TextStyle(
//                                 color: Colors.orange,
//                                 fontSize: 10,
//                               ),
//                             ),
//                             Spacer(),
//                             GestureDetector(
//                               onTap: _showAddZoomLinkDialog,
//                               child: Text(
//                                 'Add Zoom Link',
//                                 style: TextStyle(
//                                   color: AppColors.primary,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildStatusBadge(
//     String status,
//     String? attendanceStatus, {
//     bool isTrialClass = false,
//   }) {
//     Color bgColor;
//     Color textColor;
//     String label;
//     IconData icon;

//     // 🔥 ATTENDANCE STATUS (Priority 1)
//     if (attendanceStatus != null) {
//       switch (attendanceStatus) {
//         case 'attended':
//           bgColor = Colors.green.shade50;
//           textColor = Colors.green.shade700;
//           label = 'Attended';
//           icon = Icons.check_circle;
//           break;
//         case 'absent_with_apology':
//           bgColor = Colors.orange.shade50;
//           textColor = Colors.orange.shade700;
//           label = 'Absent (Apology)';
//           icon = Icons.event_busy;
//           break;
//         case 'absent_without_apology':
//           bgColor = Colors.red.shade50;
//           textColor = Colors.red.shade700;
//           label = 'Absent (No Apology)';
//           icon = Icons.cancel;
//           break;
//         default:
//           bgColor = Colors.grey.shade100;
//           textColor = Colors.grey.shade700;
//           label = 'Pending';
//           icon = Icons.schedule;
//       }
//     }
//     // 🔥 TRIAL CLASS CHECK (Priority 2)
//     else if (isTrialClass && status == 'scheduled') {
//       bgColor = Colors.orange.shade50;
//       textColor = Colors.orange.shade700;
//       label = 'Schedule Pending';
//       icon = Icons.pending_actions;
//     }
//     // 🔥 REGULAR CLASS STATUS (Priority 3)
//     else {
//       switch (status) {
//         case 'completed':
//           bgColor = Colors.blue.shade50;
//           textColor = Colors.blue.shade700;
//           label = 'Completed';
//           icon = Icons.check;
//           break;
//         case 'cancelled':
//           bgColor = Colors.red.shade50;
//           textColor = Colors.red.shade700;
//           label = 'Cancelled';
//           icon = Icons.cancel;
//           break;
//         case 'scheduled':
//           bgColor = Colors.blue.shade50;
//           textColor = Colors.blue.shade700;
//           label = 'Confirmed';
//           icon = Icons.verified;
//           break;
//         default:
//           bgColor = Colors.grey.shade100;
//           textColor = Colors.grey.shade700;
//           label = 'Unknown';
//           icon = Icons.help_outline;
//       }
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: textColor),
//           const SizedBox(width: 3),
//           Text(
//             label,
//             style: TextStyle(
//               color: textColor,
//               fontSize: 9,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔥 ATTENDANCE BUTTONS
//   Widget _buildAttendanceButtons(
//     String scheduleId,
//     String studentId,
//     String packageId,
//   ) {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildAttendanceButton(
//             'Attended',
//             Icons.check_circle,
//             Colors.green,
//             () => _markAttendance(scheduleId, studentId, packageId, 'attended'),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Expanded(
//           child: _buildAttendanceButton(
//             'Absent (Apology)',
//             Icons.event_busy,
//             Colors.orange,
//             () => _markAttendance(
//               scheduleId,
//               studentId,
//               packageId,
//               'absent_with_apology',
//             ),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Expanded(
//           child: _buildAttendanceButton(
//             'Absent (No Apology)',
//             Icons.cancel,
//             Colors.red,
//             () => _markAttendance(
//               scheduleId,
//               studentId,
//               packageId,
//               'absent_without_apology',
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAttendanceButton(
//     String label,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, size: 16, color: color),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 9,
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceStatus(String attendanceStatus) {
//     Color color;
//     IconData icon;
//     String label;

//     switch (attendanceStatus) {
//       case 'attended':
//         color = Colors.green;
//         icon = Icons.check_circle;
//         label = 'Marked as Attended';
//         break;
//       case 'absent_with_apology':
//         color = Colors.orange;
//         icon = Icons.event_busy;
//         label = 'Marked as Absent (With Apology)';
//         break;
//       case 'absent_without_apology':
//         color = Colors.red;
//         icon = Icons.cancel;
//         label = 'Marked as Absent (No Apology)';
//         break;
//       default:
//         color = Colors.grey;
//         icon = Icons.help;
//         label = 'Unknown Status';
//     }

//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔥 UPDATED MARK ATTENDANCE FUNCTION - Complete Business Logic
//   Future<void> _markAttendance(
//     String scheduleId,
//     String studentId,
//     String packageId,
//     String attendanceStatus,
//   ) async {
//     try {
//       // Schedule document fetch karo
//       final scheduleDoc = await _firestore
//           .collection('schedules')
//           .doc(scheduleId)
//           .get();

//       if (!scheduleDoc.exists) {
//         throw Exception('Schedule not found');
//       }

//       final scheduleData = scheduleDoc.data()!;
//       final batch = _firestore.batch();

//       // 1. Schedule document update karo
//       final scheduleRef = _firestore.collection('schedules').doc(scheduleId);
//       batch.update(scheduleRef, {
//         'attendanceStatus': attendanceStatus,
//         'status': 'completed',
//         'attendanceMarkedAt': FieldValue.serverTimestamp(),
//         'attendanceMarkedBy': _currentTeacherId,
//       });

//       // 2. 🔥 ATTENDED CASE: Package deduction + Wallet update
//       if (attendanceStatus == 'attended') {
//         // 2.1 Package classes deduct karo
//         if (packageId.isNotEmpty) {
//           final packageRef = _firestore
//               .collection('packageAssignments')
//               .doc(packageId);
//           batch.update(packageRef, {
//             'remainingClasses': FieldValue.increment(-1),
//             'completedClasses': FieldValue.increment(1),
//             'lastUpdated': FieldValue.serverTimestamp(),
//           });
//         }

//         // 2.2 Teacher wallet update karo
//         final teacherRef = _firestore
//             .collection('teachers')
//             .doc(_currentTeacherId!);
//         final teacherDoc = await teacherRef.get();

//         if (teacherDoc.exists) {
//           final teacherData = teacherDoc.data()!;
//           final perClassRate = (teacherData['rate'] ?? 0).toDouble();
//           final currentWallet = (teacherData['walletBalance'] ?? 0).toDouble();

//           batch.update(teacherRef, {
//             'walletBalance': currentWallet + perClassRate,
//             'sessionsCompleted': FieldValue.increment(1),
//             'lastPayoutUpdate': FieldValue.serverTimestamp(),
//           });
//         }
//       }

//       // 3. 🔥 ADMIN PANEL KE LIYE ATTENDANCE COLLECTION MEIN SAVE KARO
//       final attendanceRef = _firestore.collection('attendance').doc();

//       // Status ko Admin format mein convert karo
//       String adminStatus;
//       switch (attendanceStatus) {
//         case 'attended':
//           adminStatus = 'Attended';
//           break;
//         case 'absent_with_apology':
//           adminStatus = 'Absent with apology';
//           break;
//         case 'absent_without_apology':
//           adminStatus = 'Absent without apology';
//           break;
//         default:
//           adminStatus = 'Attended';
//       }

//       batch.set(attendanceRef, {
//         'scheduleId': scheduleId,
//         'studentId': studentId,
//         'teacherId': _currentTeacherId,
//         'date': scheduleData['date'] ?? '',
//         'time': scheduleData['time'] ?? '',
//         'subject': scheduleData['packageName'] ?? 'General',
//         'status': adminStatus,
//         'markedBy': 'Teacher',
//         'notes': 'Marked by teacher during session',
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       await batch.commit();

//       if (mounted) {
//         String message = 'Attendance marked successfully!';
//         if (attendanceStatus == 'attended') {
//           message += '\n1 class deducted from package & wallet updated';
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       print('❌ Error marking attendance: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error marking attendance: $e'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   void _showClassDetails(
//     Map<String, dynamic> session,
//     String studentName,
//     String packageId,
//   ) async {
//     int totalClasses = 0;
//     int remainingClasses = 0;
//     String packageName = session['packageName'] ?? 'No Package';

//     if (packageId.isNotEmpty) {
//       try {
//         final packageDoc = await _firestore
//             .collection('packageAssignments')
//             .doc(packageId)
//             .get();
//         if (packageDoc.exists) {
//           final packageData = packageDoc.data() as Map<String, dynamic>;
//           totalClasses = (packageData['numberOfClasses'] ?? 0).toInt();
//           remainingClasses = (packageData['remainingClasses'] ?? 0).toInt();
//         }
//       } catch (e) {
//         print('Error fetching package: $e');
//       }
//     }

//     if (!mounted) return;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(Icons.event_note, color: AppColors.primary, size: 24),
//             ),
//             const SizedBox(width: 12),
//             Text('Class Details', style: AppTextStyles.heading5),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDetailRow('Student', studentName),
//             _buildDetailRow('Package', packageName),
//             _buildDetailRow('Date', session['date'] ?? 'N/A'),
//             _buildDetailRow('Time', session['time'] ?? 'N/A'),
//             _buildDetailRow('Duration', session['duration'] ?? 'N/A'),
//             _buildDetailRow('Timezone', session['timezone'] ?? 'PKT (UTC+5)'),

//             const SizedBox(height: 12),
//             Divider(color: AppColors.border),
//             const SizedBox(height: 8),

//             if (packageId.isNotEmpty) ...[
//               Text(
//                 'Package Progress',
//                 style: AppTextStyles.labelText.copyWith(
//                   color: AppColors.text,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildProgressItem(
//                     'Total Classes',
//                     totalClasses.toString(),
//                     Icons.book,
//                     Colors.blue,
//                   ),
//                   _buildProgressItem(
//                     'Completed',
//                     (totalClasses - remainingClasses).toString(),
//                     Icons.check_circle,
//                     Colors.green,
//                   ),
//                   _buildProgressItem(
//                     'Remaining',
//                     remainingClasses.toString(),
//                     Icons.schedule,
//                     Colors.orange,
//                   ),
//                 ],
//               ),
//             ] else ...[
//               Text(
//                 'No package assigned',
//                 style: AppTextStyles.bodySmall.copyWith(
//                   color: AppColors.subtitle,
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ],
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close', style: TextStyle(color: AppColors.primary)),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//               _launchZoom(_teacherZoomLink);
//             },
//             icon: const Icon(Icons.video_camera_front, size: 18),
//             label: const Text('Join Class'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '$label: ',
//             style: AppTextStyles.labelText.copyWith(
//               color: AppColors.text,
//               fontSize: 13,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: AppColors.subtitle,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProgressItem(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: AppTextStyles.heading4.copyWith(color: color, fontSize: 16),
//         ),
//         Text(
//           label,
//           style: AppTextStyles.captionText.copyWith(
//             color: AppColors.subtitle,
//             fontSize: 10,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCalendarView() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('schedules')
//           .where('teacherId', isEqualTo: _currentTeacherId)
//           .snapshots(),
//       builder: (context, snapshot) {
//         Map<DateTime, List<Map<String, dynamic>>> events = {};

//         if (snapshot.hasData) {
//           for (var doc in snapshot.data!.docs) {
//             final data = doc.data() as Map<String, dynamic>;
//             data['docId'] = doc.id;
//             final dateStr = data['date'] as String?;
//             if (dateStr != null) {
//               final date = DateTime.parse(dateStr);
//               final dateKey = DateTime(date.year, date.month, date.day);
//               if (events[dateKey] == null) {
//                 events[dateKey] = [];
//               }
//               events[dateKey]!.add(data);
//             }
//           }
//         }

//         return Column(
//           children: [
//             Container(
//               margin: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: AppColors.card,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TableCalendar(
//                 firstDay: DateTime.utc(2020, 1, 1),
//                 lastDay: DateTime.utc(2030, 12, 31),
//                 focusedDay: _focusedDay,
//                 calendarFormat: _calendarFormat,
//                 selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
//                 eventLoader: (day) {
//                   final dateKey = DateTime(day.year, day.month, day.day);
//                   return events[dateKey] ?? [];
//                 },
//                 onDaySelected: (selectedDay, focusedDay) {
//                   setState(() {
//                     _selectedDate = selectedDay;
//                     _focusedDay = focusedDay;
//                   });
//                 },
//                 onFormatChanged: (format) {
//                   setState(() => _calendarFormat = format);
//                 },
//                 calendarStyle: CalendarStyle(
//                   todayDecoration: BoxDecoration(
//                     color: AppColors.primary.withOpacity(0.3),
//                     shape: BoxShape.circle,
//                   ),
//                   selectedDecoration: BoxDecoration(
//                     color: AppColors.primary,
//                     shape: BoxShape.circle,
//                   ),
//                   markerDecoration: BoxDecoration(
//                     color: AppColors.gradient,
//                     shape: BoxShape.circle,
//                   ),
//                   markersMaxCount: 3,
//                 ),
//                 headerStyle: HeaderStyle(
//                   formatButtonVisible: false,
//                   titleCentered: true,
//                   titleTextStyle: AppTextStyles.heading3.copyWith(fontSize: 16),
//                 ),
//               ),
//             ),
//             Expanded(child: _buildSelectedDaySessions(events)),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildSelectedDaySessions(
//     Map<DateTime, List<Map<String, dynamic>>> events,
//   ) {
//     final dateKey = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//     );
//     final sessions = events[dateKey] ?? [];

//     if (sessions.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.event_busy, size: 48, color: AppColors.subtitle),
//             const SizedBox(height: 12),
//             Text(
//               'No sessions on this day',
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: AppColors.subtitle,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       children: [
//         Text(
//           DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
//           style: AppTextStyles.heading3.copyWith(fontSize: 15),
//         ),
//         const SizedBox(height: 10),
//         ...sessions.map((session) => _buildCalendarSessionCard(session)),
//       ],
//     );
//   }

//   Widget _buildCalendarSessionCard(Map<String, dynamic> session) {
//     final packageName = session['packageName'] ?? 'No Package';
//     final time = session['time'] ?? '00:00';
//     final duration = session['duration'] ?? '60 min';
//     final studentId = session['studentId'] ?? '';
//     final attendanceStatus = session['attendanceStatus'];

//     return FutureBuilder<DocumentSnapshot>(
//       future: _firestore.collection('students').doc(studentId).get(),
//       builder: (context, snapshot) {
//         String studentName = 'Student';
//         if (snapshot.hasData && snapshot.data!.exists) {
//           final data = snapshot.data!.data() as Map<String, dynamic>?;
//           studentName = data?['name'] ?? 'Student';
//         }

//         return Container(
//           margin: const EdgeInsets.only(bottom: 8),
//           decoration: BoxDecoration(
//             color: AppColors.card,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppColors.primary.withOpacity(0.2)),
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               borderRadius: BorderRadius.circular(12),
//               onTap: () => _showClassDetails(
//                 session,
//                 studentName,
//                 session['packageId'] ?? '',
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(10),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 4,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [AppColors.primary, AppColors.gradient],
//                         ),
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             studentName,
//                             style: AppTextStyles.cardTitle.copyWith(
//                               fontSize: 13,
//                             ),
//                           ),
//                           const SizedBox(height: 3),
//                           Text(
//                             '$time • $packageName • $duration',
//                             style: AppTextStyles.captionText.copyWith(
//                               color: AppColors.subtitle,
//                               fontSize: 11,
//                             ),
//                           ),
//                           if (attendanceStatus != null) ...[
//                             const SizedBox(height: 4),
//                             _buildStatusBadge(
//                               session['status'] ?? 'scheduled',
//                               attendanceStatus,
//                               isTrialClass: session['isTrialClass'] ?? false,
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(
//                         Icons.video_camera_front,
//                         color: AppColors.primary,
//                       ),
//                       onPressed: () => _launchZoom(_teacherZoomLink),
//                       iconSize: 20,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _launchZoom(String url) async {
//     if (url.isEmpty) {
//       _showAddZoomLinkDialog();
//       return;
//     }

//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Could not launch Zoom'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   void _showAddZoomLinkDialog() {
//     final zoomController = TextEditingController(text: _teacherZoomLink);
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Add Zoom Link', style: AppTextStyles.heading4),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Add your personal Zoom meeting link to join sessions',
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: AppColors.subtitle,
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: zoomController,
//               decoration: InputDecoration(
//                 labelText: 'Zoom Meeting Link',
//                 hintText: 'https://zoom.us/j/your-meeting-id',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 prefixIcon: Icon(Icons.video_camera_front),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (zoomController.text.trim().isNotEmpty) {
//                 await _updateTeacherZoomLink(zoomController.text.trim());
//                 Navigator.pop(context);
//               }
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
//             child: Text('Save Zoom Link'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _updateTeacherZoomLink(String zoomLink) async {
//     try {
//       if (_currentTeacherId != null) {
//         await _firestore.collection('teachers').doc(_currentTeacherId).set({
//           'zoomLink': zoomLink,
//           'updatedAt': FieldValue.serverTimestamp(),
//         }, SetOptions(merge: true));

//         setState(() {
//           _teacherZoomLink = zoomLink;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Zoom link updated successfully!'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating Zoom link: $e'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   String _getInitials(String name) {
//     final names = name.split(' ');
//     if (names.length >= 2) {
//       return '${names[0][0]}${names[1][0]}'.toUpperCase();
//     }
//     return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  int _currentView = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _currentTeacherId => _auth.currentUser?.uid;

  String _teacherZoomLink = '';
  bool _isLoadingZoomLink = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherZoomLink();
  }

  Future<void> _loadTeacherZoomLink() async {
    try {
      if (_currentTeacherId != null) {
        final teacherDoc = await _firestore
            .collection('teachers')
            .doc(_currentTeacherId)
            .get();
        if (teacherDoc.exists) {
          final data = teacherDoc.data()!;
          setState(() => _teacherZoomLink = data['zoomLink'] ?? '');
        }
        setState(() => _isLoadingZoomLink = false);
      }
    } catch (e) {
      print('❌ Error loading Zoom link: $e');
      setState(() => _isLoadingZoomLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTeacherId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Please login to view your schedule',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _currentView == 0
                  ? _buildListView()
                  : _buildCalendarView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('schedules')
          .where('teacherId', isEqualTo: _currentTeacherId)
          .snapshots(),
      builder: (context, snapshot) {
        int todayCount = 0;
        int upcomingCount = 0;
        int completedCount = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] as String?;
            final status = data['status'] as String?;
            if (dateStr != null) {
              final scheduleDate = DateTime.parse(dateStr);
              final scheduleDateOnly = DateTime(
                scheduleDate.year,
                scheduleDate.month,
                scheduleDate.day,
              );
              if (scheduleDateOnly.isAtSameMomentAs(today))
                todayCount++;
              else if (scheduleDateOnly.isAfter(today))
                upcomingCount++;
              if (status == 'completed') completedCount++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Schedule',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.white,
                      fontSize: 22,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildViewToggle(0, Icons.list, 'List'),
                        _buildViewToggle(1, Icons.calendar_today, 'Calendar'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today',
                      todayCount.toString(),
                      Icons.today,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Upcoming',
                      upcomingCount.toString(),
                      Icons.upcoming,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      completedCount.toString(),
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggle(int index, IconData icon, String label) {
    final isSelected = _currentView == index;
    return InkWell(
      onTap: () => setState(() => _currentView = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.white.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.white.withOpacity(isSelected ? 1.0 : 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.white.withOpacity(isSelected ? 1.0 : 0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.white),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.white,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('schedules')
          .where('teacherId', isEqualTo: _currentTeacherId)
          .orderBy('date')
          .orderBy('time')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading schedules: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: AppColors.subtitle,
                ),
                const SizedBox(height: 16),
                Text(
                  'No schedules found',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your upcoming sessions will appear here',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todaySessions = <Map<String, dynamic>>[];
        final upcomingSessions = <Map<String, dynamic>>[];
        final pastSessions = <Map<String, dynamic>>[];

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          final dateStr = data['date'] as String?;
          if (dateStr != null) {
            final scheduleDate = DateTime.parse(dateStr);
            final scheduleDateOnly = DateTime(
              scheduleDate.year,
              scheduleDate.month,
              scheduleDate.day,
            );
            if (scheduleDateOnly.isAtSameMomentAs(today))
              todaySessions.add(data);
            else if (scheduleDateOnly.isAfter(today))
              upcomingSessions.add(data);
            else
              pastSessions.add(data);
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _loadTeacherZoomLink();
          },
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              if (todaySessions.isNotEmpty) ...[
                _buildSectionHeader(
                  'Today\'s Sessions',
                  Icons.today,
                  Colors.green,
                ),
                const SizedBox(height: 10),
                ...todaySessions.map(
                  (s) => _buildSessionCard(s, isToday: true),
                ),
                const SizedBox(height: 16),
              ],
              if (upcomingSessions.isNotEmpty) ...[
                _buildSectionHeader(
                  'Upcoming Sessions',
                  Icons.upcoming,
                  Colors.blue,
                ),
                const SizedBox(height: 10),
                ...upcomingSessions.map(
                  (s) => _buildSessionCard(s, isToday: false),
                ),
                const SizedBox(height: 16),
              ],
              if (pastSessions.isNotEmpty) ...[
                _buildSectionHeader(
                  'Past Sessions',
                  Icons.history,
                  Colors.grey,
                ),
                const SizedBox(height: 10),
                ...pastSessions
                    .take(5)
                    .map((s) => _buildSessionCard(s, isPast: true)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.text,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    Map<String, dynamic> session, {
    bool isToday = false,
    bool isPast = false,
  }) {
    final packageName = session['packageName'] ?? 'No Package';
    final duration = session['duration'] ?? '60 min';
    final time = session['time'] ?? '00:00';
    final date = session['date'] ?? '';
    final studentId = session['studentId'] ?? '';
    final packageId = session['packageId'] ?? '';
    final docId = session['docId'] ?? '';
    final status = session['status'] ?? 'scheduled';
    final attendanceStatus = session['attendanceStatus'];

    // ✅ Already cancelled check
    final isCancelled = status == 'cancelled';

    bool isClassFinished = false;
    try {
      if (date.isNotEmpty && time.isNotEmpty) {
        final classDateTime = DateTime.parse(date);
        final timeParts = time.split(':');
        final classFullDateTime = DateTime(
          classDateTime.year,
          classDateTime.month,
          classDateTime.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        final durationMinutes =
            int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60;
        final classEndTime = classFullDateTime.add(
          Duration(minutes: durationMinutes),
        );
        isClassFinished = DateTime.now().isAfter(classEndTime);
      }
    } catch (e) {
      print('❌ Error checking class time: $e');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('students').doc(studentId).get(),
      builder: (context, studentSnapshot) {
        String studentName = 'Student';
        String studentPhone = '';
        if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
          final studentData =
              studentSnapshot.data!.data() as Map<String, dynamic>?;
          studentName = studentData?['name'] ?? 'Student';
          studentPhone = studentData?['phone']?.toString() ?? '';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isCancelled
                ? AppColors.card.withOpacity(0.6)
                : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: isCancelled
                ? Border.all(color: Colors.red.withOpacity(0.3), width: 1.5)
                : isToday
                ? Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showClassDetails(session, studentName, packageId),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: time, status badge, duration
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: isToday
                                    ? AppColors.primary
                                    : AppColors.subtitle,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.subtitle,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusBadge(
                          status,
                          attendanceStatus,
                          isTrialClass: session['isTrialClass'] ?? false,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            duration,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Student info row
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.gradient],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(studentName),
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                packageName,
                                style: AppTextStyles.cardSubtitle.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ Attendance buttons (after class ends, not cancelled)
                    if (isClassFinished && !isCancelled) ...[
                      if (attendanceStatus == null)
                        _buildAttendanceButtons(docId, studentId, packageId)
                      else
                        _buildAttendanceStatus(attendanceStatus),
                      const SizedBox(height: 8),
                    ],

                    // ✅ CANCELLED BANNER
                    if (isCancelled)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel,
                              size: 16,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'This class has been cancelled',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ✅ Join + Cancel buttons (only for non-cancelled, non-past classes)
                    if (!isClassFinished && !isCancelled) ...[
                      Row(
                        children: [
                          // Join button
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isToday
                                      ? [Colors.green, Colors.green.shade400]
                                      : [AppColors.primary, AppColors.gradient],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isToday
                                                ? Colors.green
                                                : AppColors.primary)
                                            .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _launchZoom(_teacherZoomLink),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.video_camera_front,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isToday ? 'Join Now' : 'Join Session',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // ✅ NEW: Cancel Class Button
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton.icon(
                                onPressed: () => _showCancelClassDialog(
                                  scheduleId: docId,
                                  studentId: studentId,
                                  studentName: studentName,
                                  studentPhone: studentPhone,
                                  packageId: packageId,
                                  packageName: packageName,
                                  date: date,
                                  time: time,
                                  attendanceStatus: attendanceStatus,
                                ),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_teacherZoomLink.isEmpty && !_isLoadingZoomLink)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'No Zoom link configured',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _showAddZoomLinkDialog,
                                child: Text(
                                  'Add Zoom Link',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ✅ NEW: CANCEL CLASS DIALOG
  // ============================================================
  void _showCancelClassDialog({
    required String scheduleId,
    required String studentId,
    required String studentName,
    required String studentPhone,
    required String packageId,
    required String packageName,
    required String date,
    required String time,
    required String? attendanceStatus,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cancel Class',
              style: AppTextStyles.heading5.copyWith(color: AppColors.text),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildCancelDetailRow(Icons.person, 'Student', studentName),
                  const SizedBox(height: 6),
                  _buildCancelDetailRow(
                    Icons.inventory_2,
                    'Package',
                    packageName,
                  ),
                  const SizedBox(height: 6),
                  _buildCancelDetailRow(Icons.calendar_today, 'Date', date),
                  const SizedBox(height: 6),
                  _buildCancelDetailRow(Icons.access_time, 'Time', time),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // What will happen info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What will happen:',
                    style: AppTextStyles.captionText.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWhatHappensRow(
                    '✅',
                    '1 session refunded to student\'s package',
                  ),
                  const SizedBox(height: 4),
                  _buildWhatHappensRow(
                    '📱',
                    'WhatsApp notification sent to student',
                  ),
                  const SizedBox(height: 4),
                  _buildWhatHappensRow(
                    '📋',
                    'Class marked as cancelled in records',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason input
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                labelStyle: AppTextStyles.captionText.copyWith(
                  color: AppColors.subtitle,
                ),
                hintText: 'e.g. Teacher unwell, Emergency, etc.',
                hintStyle: AppTextStyles.captionText.copyWith(
                  color: AppColors.subtitle,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Class',
              style: TextStyle(color: AppColors.subtitle),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _cancelClass(
                scheduleId: scheduleId,
                studentId: studentId,
                studentName: studentName,
                studentPhone: studentPhone,
                packageId: packageId,
                packageName: packageName,
                date: date,
                time: time,
                reason: reasonController.text.trim(),
                attendanceStatus: attendanceStatus,
              );
            },
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Yes, Cancel Class'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.subtitle),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWhatHappensRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.captionText.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ NEW: CANCEL CLASS LOGIC
  // ============================================================
  Future<void> _cancelClass({
    required String scheduleId,
    required String studentId,
    required String studentName,
    required String studentPhone,
    required String packageId,
    required String packageName,
    required String date,
    required String time,
    required String reason,
    required String? attendanceStatus,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. ✅ Schedule status → cancelled
      final scheduleRef = _firestore.collection('schedules').doc(scheduleId);
      batch.update(scheduleRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': _currentTeacherId,
        'cancellationReason': reason.isNotEmpty
            ? reason
            : 'Cancelled by teacher',
      });

      // 2. ✅ Session refund — package mein 1 class wapas
      if (packageId.isNotEmpty) {
        final packageRef = _firestore
            .collection('packageAssignments')
            .doc(packageId);
        batch.update(packageRef, {
          'remainingClasses': FieldValue.increment(1), // +1 wapas
          'completedClasses': FieldValue.increment(
            -1,
          ), // -1 agar already counted tha
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // 3. ✅ Agar attendance already 'attended' mark tha toh teacher wallet se bhi deduct karo
      if (attendanceStatus == 'attended' && _currentTeacherId != null) {
        final teacherRef = _firestore
            .collection('teachers')
            .doc(_currentTeacherId!);
        final teacherDoc = await teacherRef.get();
        if (teacherDoc.exists) {
          final teacherData = teacherDoc.data()!;
          final perClassRate = (teacherData['rate'] ?? 0).toDouble();
          final currentWallet = (teacherData['walletBalance'] ?? 0).toDouble();
          final newWallet = (currentWallet - perClassRate).clamp(
            0.0,
            double.infinity,
          );
          batch.update(teacherRef, {
            'walletBalance': newWallet,
            'sessionsCompleted': FieldValue.increment(-1),
            'lastPayoutUpdate': FieldValue.serverTimestamp(),
          });
        }
      }

      // 4. ✅ Activity log
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'type': 'class_cancelled',
        'message': 'Class cancelled for $studentName — 1 session refunded',
        'teacherId': _currentTeacherId,
        'studentId': studentId,
        'scheduleId': scheduleId,
        'packageId': packageId,
        'reason': reason.isNotEmpty ? reason : 'Cancelled by teacher',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 5. ✅ WhatsApp message student ko
      if (studentPhone.isNotEmpty) {
        await _sendCancellationWhatsApp(
          studentName: studentName,
          phone: studentPhone,
          packageName: packageName,
          date: date,
          time: time,
          reason: reason,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Class cancelled & 1 session refunded to student!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error cancelling class: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling class: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============================================================
  // ✅ NEW: SEND WHATSAPP CANCELLATION MESSAGE
  // ============================================================
  Future<void> _sendCancellationWhatsApp({
    required String studentName,
    required String phone,
    required String packageName,
    required String date,
    required String time,
    required String reason,
  }) async {
    // Clean phone number
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!cleanPhone.startsWith('+') && !cleanPhone.startsWith('92')) {
      cleanPhone = '92$cleanPhone';
    }
    cleanPhone = cleanPhone.replaceAll('+', '');

    final reasonText = reason.isNotEmpty
        ? reason
        : 'an unforeseen circumstance';

    final message =
        '''Assalam o Alaikum $studentName! 🌙

We regret to inform you that your class scheduled for *$date* at *$time* has been *cancelled* due to $reasonText.

📋 *Class Details:*
• Package: $packageName
• Date: $date
• Time: $time

✅ *Good news:* 1 session has been refunded back to your package automatically.

We apologize for the inconvenience. Your class will be rescheduled soon. JazakAllah Khair! 🤲

*StudyAlQuran Team*''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('❌ WhatsApp error: $e');
      }
    } catch (e) {
      print('❌ WhatsApp error: $e');
    }
  }

  // ============================================================
  // ATTENDANCE SECTION (unchanged)
  // ============================================================
  Widget _buildStatusBadge(
    String status,
    String? attendanceStatus, {
    bool isTrialClass = false,
  }) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (attendanceStatus != null) {
      switch (attendanceStatus) {
        case 'attended':
          bgColor = Colors.green.shade50;
          textColor = Colors.green.shade700;
          label = 'Attended';
          icon = Icons.check_circle;
          break;
        case 'absent_with_apology':
          bgColor = Colors.orange.shade50;
          textColor = Colors.orange.shade700;
          label = 'Absent (Apology)';
          icon = Icons.event_busy;
          break;
        case 'absent_without_apology':
          bgColor = Colors.red.shade50;
          textColor = Colors.red.shade700;
          label = 'Absent (No Apology)';
          icon = Icons.cancel;
          break;
        default:
          bgColor = Colors.grey.shade100;
          textColor = Colors.grey.shade700;
          label = 'Pending';
          icon = Icons.schedule;
      }
    } else if (isTrialClass && status == 'scheduled') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      label = 'Schedule Pending';
      icon = Icons.pending_actions;
    } else {
      switch (status) {
        case 'completed':
          bgColor = Colors.blue.shade50;
          textColor = Colors.blue.shade700;
          label = 'Completed';
          icon = Icons.check;
          break;
        case 'cancelled':
          bgColor = Colors.red.shade50;
          textColor = Colors.red.shade700;
          label = 'Cancelled';
          icon = Icons.cancel;
          break;
        case 'scheduled':
          bgColor = Colors.blue.shade50;
          textColor = Colors.blue.shade700;
          label = 'Confirmed';
          icon = Icons.verified;
          break;
        default:
          bgColor = Colors.grey.shade100;
          textColor = Colors.grey.shade700;
          label = 'Unknown';
          icon = Icons.help_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButtons(
    String scheduleId,
    String studentId,
    String packageId,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildAttendanceButton(
            'Attended',
            Icons.check_circle,
            Colors.green,
            () => _markAttendance(scheduleId, studentId, packageId, 'attended'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildAttendanceButton(
            'Absent (Apology)',
            Icons.event_busy,
            Colors.orange,
            () => _markAttendance(
              scheduleId,
              studentId,
              packageId,
              'absent_with_apology',
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildAttendanceButton(
            'Absent (No Apology)',
            Icons.cancel,
            Colors.red,
            () => _markAttendance(
              scheduleId,
              studentId,
              packageId,
              'absent_without_apology',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus(String attendanceStatus) {
    Color color;
    IconData icon;
    String label;
    switch (attendanceStatus) {
      case 'attended':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Marked as Attended';
        break;
      case 'absent_with_apology':
        color = Colors.orange;
        icon = Icons.event_busy;
        label = 'Marked as Absent (With Apology)';
        break;
      case 'absent_without_apology':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Marked as Absent (No Apology)';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Unknown Status';
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendance(
    String scheduleId,
    String studentId,
    String packageId,
    String attendanceStatus,
  ) async {
    try {
      final scheduleDoc = await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .get();
      if (!scheduleDoc.exists) throw Exception('Schedule not found');
      final scheduleData = scheduleDoc.data()!;
      final batch = _firestore.batch();

      final scheduleRef = _firestore.collection('schedules').doc(scheduleId);
      batch.update(scheduleRef, {
        'attendanceStatus': attendanceStatus,
        'status': 'completed',
        'attendanceMarkedAt': FieldValue.serverTimestamp(),
        'attendanceMarkedBy': _currentTeacherId,
      });

      if (attendanceStatus == 'attended') {
        if (packageId.isNotEmpty) {
          final packageRef = _firestore
              .collection('packageAssignments')
              .doc(packageId);
          batch.update(packageRef, {
            'remainingClasses': FieldValue.increment(-1),
            'completedClasses': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        final teacherRef = _firestore
            .collection('teachers')
            .doc(_currentTeacherId!);
        final teacherDoc = await teacherRef.get();
        if (teacherDoc.exists) {
          final teacherData = teacherDoc.data()!;
          final perClassRate = (teacherData['rate'] ?? 0).toDouble();
          final currentWallet = (teacherData['walletBalance'] ?? 0).toDouble();
          batch.update(teacherRef, {
            'walletBalance': currentWallet + perClassRate,
            'sessionsCompleted': FieldValue.increment(1),
            'lastPayoutUpdate': FieldValue.serverTimestamp(),
          });
        }
      }

      String adminStatus;
      switch (attendanceStatus) {
        case 'attended':
          adminStatus = 'Attended';
          break;
        case 'absent_with_apology':
          adminStatus = 'Absent with apology';
          break;
        case 'absent_without_apology':
          adminStatus = 'Absent without apology';
          break;
        default:
          adminStatus = 'Attended';
      }

      final attendanceRef = _firestore.collection('attendance').doc();
      batch.set(attendanceRef, {
        'scheduleId': scheduleId,
        'studentId': studentId,
        'teacherId': _currentTeacherId,
        'date': scheduleData['date'] ?? '',
        'time': scheduleData['time'] ?? '',
        'subject': scheduleData['packageName'] ?? 'General',
        'status': adminStatus,
        'markedBy': 'Teacher',
        'notes': 'Marked by teacher during session',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        String message = 'Attendance marked successfully!';
        if (attendanceStatus == 'attended')
          message += '\n1 class deducted from package & wallet updated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error marking attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showClassDetails(
    Map<String, dynamic> session,
    String studentName,
    String packageId,
  ) async {
    int totalClasses = 0;
    int remainingClasses = 0;
    String packageName = session['packageName'] ?? 'No Package';
    if (packageId.isNotEmpty) {
      try {
        final packageDoc = await _firestore
            .collection('packageAssignments')
            .doc(packageId)
            .get();
        if (packageDoc.exists) {
          final packageData = packageDoc.data() as Map<String, dynamic>;
          totalClasses = (packageData['numberOfClasses'] ?? 0).toInt();
          remainingClasses = (packageData['remainingClasses'] ?? 0).toInt();
        }
      } catch (e) {
        print('Error fetching package: $e');
      }
    }
    if (!mounted) return;
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
              child: Icon(Icons.event_note, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Class Details', style: AppTextStyles.heading5),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Student', studentName),
            _buildDetailRow('Package', packageName),
            _buildDetailRow('Date', session['date'] ?? 'N/A'),
            _buildDetailRow('Time', session['time'] ?? 'N/A'),
            _buildDetailRow('Duration', session['duration'] ?? 'N/A'),
            _buildDetailRow('Timezone', session['timezone'] ?? 'PKT (UTC+5)'),
            const SizedBox(height: 12),
            Divider(color: AppColors.border),
            const SizedBox(height: 8),
            if (packageId.isNotEmpty) ...[
              Text(
                'Package Progress',
                style: AppTextStyles.labelText.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProgressItem(
                    'Total Classes',
                    totalClasses.toString(),
                    Icons.book,
                    Colors.blue,
                  ),
                  _buildProgressItem(
                    'Completed',
                    (totalClasses - remainingClasses).toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildProgressItem(
                    'Remaining',
                    remainingClasses.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _launchZoom(_teacherZoomLink);
            },
            icon: const Icon(Icons.video_camera_front, size: 18),
            label: const Text('Join Class'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.labelText.copyWith(
              color: AppColors.text,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.heading4.copyWith(color: color, fontSize: 16),
        ),
        Text(
          label,
          style: AppTextStyles.captionText.copyWith(
            color: AppColors.subtitle,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('schedules')
          .where('teacherId', isEqualTo: _currentTeacherId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<DateTime, List<Map<String, dynamic>>> events = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            final dateStr = data['date'] as String?;
            if (dateStr != null) {
              final date = DateTime.parse(dateStr);
              final dateKey = DateTime(date.year, date.month, date.day);
              if (events[dateKey] == null) events[dateKey] = [];
              events[dateKey]!.add(data);
            }
          }
        }
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                eventLoader: (day) {
                  final dateKey = DateTime(day.year, day.month, day.day);
                  return events[dateKey] ?? [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppColors.gradient,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppTextStyles.heading3.copyWith(fontSize: 16),
                ),
              ),
            ),
            Expanded(child: _buildSelectedDaySessions(events)),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDaySessions(
    Map<DateTime, List<Map<String, dynamic>>> events,
  ) {
    final dateKey = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final sessions = events[dateKey] ?? [];
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: AppColors.subtitle),
            const SizedBox(height: 12),
            Text(
              'No sessions on this day',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
          style: AppTextStyles.heading3.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...sessions.map((session) => _buildCalendarSessionCard(session)),
      ],
    );
  }

  Widget _buildCalendarSessionCard(Map<String, dynamic> session) {
    final packageName = session['packageName'] ?? 'No Package';
    final time = session['time'] ?? '00:00';
    final duration = session['duration'] ?? '60 min';
    final studentId = session['studentId'] ?? '';
    final attendanceStatus = session['attendanceStatus'];
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('students').doc(studentId).get(),
      builder: (context, snapshot) {
        String studentName = 'Student';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          studentName = data?['name'] ?? 'Student';
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showClassDetails(
                session,
                studentName,
                session['packageId'] ?? '',
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.gradient],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$time • $packageName • $duration',
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.subtitle,
                              fontSize: 11,
                            ),
                          ),
                          if (attendanceStatus != null) ...[
                            const SizedBox(height: 4),
                            _buildStatusBadge(
                              session['status'] ?? 'scheduled',
                              attendanceStatus,
                              isTrialClass: session['isTrialClass'] ?? false,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.video_camera_front,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _launchZoom(_teacherZoomLink),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchZoom(String url) async {
    if (url.isEmpty) {
      _showAddZoomLinkDialog();
      return;
    }
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch Zoom'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _showAddZoomLinkDialog() {
    final zoomController = TextEditingController(text: _teacherZoomLink);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Zoom Link', style: AppTextStyles.heading4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add your personal Zoom meeting link to join sessions',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: zoomController,
              decoration: InputDecoration(
                labelText: 'Zoom Meeting Link',
                hintText: 'https://zoom.us/j/your-meeting-id',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.video_camera_front),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (zoomController.text.trim().isNotEmpty) {
                await _updateTeacherZoomLink(zoomController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Zoom Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeacherZoomLink(String zoomLink) async {
    try {
      if (_currentTeacherId != null) {
        await _firestore.collection('teachers').doc(_currentTeacherId).set({
          'zoomLink': zoomLink,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        setState(() => _teacherZoomLink = zoomLink);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zoom link updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating Zoom link: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) return '${names[0][0]}${names[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
