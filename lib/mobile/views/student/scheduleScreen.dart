import 'package:flutter/material.dart';
import 'package:studyalquran/mobile/views/student/notifications.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Import your chat screen
import 'package:studyalquran/mobile/views/chat/studentChatscreen.dart';

// 📅 Session Model - UPDATED FOR TRIAL WITH APPROVAL STATUS
class Session {
  final String id;
  final String name;
  final String teacherImage;
  final DateTime? dateTime;
  final String duration;
  final String zoomLink;
  final SessionStatus status;
  final String subject;
  final String teacherId;
  final String studentId;
  final String? packageName;
  final bool isTrial;
  final String sessionType;
  final String? trialAssignmentId;
  final String trialStatus;

  Session({
    required this.id,
    required this.name,
    required this.teacherImage,
    this.dateTime,
    required this.duration,
    required this.zoomLink,
    required this.status,
    required this.subject,
    required this.teacherId,
    required this.studentId,
    this.packageName,
    this.isTrial = false,
    this.sessionType = 'regular',
    this.trialAssignmentId,
    this.trialStatus = 'pending',
  });

  factory Session.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? dateTime;

    // 🔥🔥🔥 MAJOR CHANGE STARTS HERE 🔥🔥🔥
    // PEHLE scheduledAt CHECK KARO (NEW UTC SYSTEM)
    if (data['scheduledAt'] != null) {
      try {
        Timestamp ts = data['scheduledAt'] as Timestamp;
        dateTime = ts.toDate().toLocal(); // ✅ UTC se local time automatic
        print('✅ Using UTC timestamp for student: ${dateTime}');
      } catch (e) {
        print('Error parsing scheduledAt: $e');
      }
    }

    // 🔥 AGAR scheduledAt NAHI HAI TOH PURANA SYSTEM USE KARO
    if (dateTime == null && data['date'] != null && data['time'] != null) {
      try {
        String dateStr = data['date'];
        String timeStr = data['time'];

        if (timeStr.toUpperCase().contains('AM') ||
            timeStr.toUpperCase().contains('PM')) {
          dateTime = DateFormat('yyyy-MM-dd h:mm a').parse('$dateStr $timeStr');
        } else {
          dateTime = DateFormat('yyyy-MM-dd HH:mm').parse('$dateStr $timeStr');
        }
        print('⚠️ Using old date/time system for student: ${dateTime}');
      } catch (e) {
        print('Date parsing error: $e');
      }
    }
    // 🔥🔥🔥 MAJOR CHANGE ENDS HERE 🔥🔥🔥

    SessionStatus status = _determineStatus(dateTime, data['status']);
    return Session(
      id: doc.id,
      name: data['name'] ?? 'Unknown Teacher',
      teacherImage: _getTeacherInitial(data['name'] ?? 'T'),
      dateTime: dateTime,
      duration: data['duration'] ?? '60 min',
      zoomLink: data['zoomLink'] ?? '',
      status: status,
      subject: data['subject'] ?? 'Quran',
      teacherId: data['teacherId'] ?? '',
      studentId: data['studentId'] ?? '',
      packageName: data['packageName'],
      isTrial: data['isTrial'] ?? false,
      sessionType: data['isTrial'] == true ? 'trial' : 'regular',
      trialStatus: data['trialStatus'] ?? 'pending',
      trialAssignmentId: doc.id,
    );
  }

  static SessionStatus _determineStatus(DateTime? dateTime, String? status) {
    if (status == 'completed') return SessionStatus.completed;
    if (status == 'cancelled') return SessionStatus.missed;

    if (dateTime == null) return SessionStatus.upcoming;

    DateTime now = DateTime.now();

    // 🔥 NEW: AGAR CLASS KA TIME ABHI 7 BAJAY HAI TO 30 MINUTES TAK 'ONGOING' RAHEGA
    if (dateTime.isBefore(now) &&
        dateTime.add(Duration(minutes: 30)).isAfter(now)) {
      return SessionStatus.ongoing;
    }

    // 🔥 NEW: 30 MINUTES BAAD 'MISSED' HOGA
    if (dateTime.add(Duration(minutes: 30)).isBefore(now)) {
      return SessionStatus.missed;
    }

    if (dateTime.isAfter(now)) return SessionStatus.upcoming;

    return SessionStatus.upcoming;
  }

  static String _getTeacherInitial(String name) {
    if (name.isEmpty) return 'T';
    return name[0].toUpperCase();
  }
}

// 🎯 Session Status Enum
enum SessionStatus { upcoming, ongoing, completed, missed }

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 Store deleted trial IDs locally
  Set<String> _deletedTrialIds = {};

  // 🔥 Calendar View State
  bool _showCalendarView = false;
  List<Session> _allSessions = [];
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _calendarController = CalendarController();
    _loadDeletedTrials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  // 🔥 Load deleted trials from local storage
  Future<void> _loadDeletedTrials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? deletedTrialsJson = prefs.getString(
        'deleted_trials_${_auth.currentUser?.uid}',
      );

      if (deletedTrialsJson != null && deletedTrialsJson.isNotEmpty) {
        List<String> deletedList = deletedTrialsJson.split(',');
        setState(() {
          _deletedTrialIds = deletedList.toSet();
        });
        print('Loaded deleted trials: $_deletedTrialIds');
      }
    } catch (e) {
      print('Error loading deleted trials: $e');
    }
  }

  // 🔥 Save deleted trial to local storage
  Future<void> _saveDeletedTrial(String trialId) async {
    try {
      _deletedTrialIds.add(trialId);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String deletedTrialsString = _deletedTrialIds.join(',');
      await prefs.setString(
        'deleted_trials_${_auth.currentUser?.uid}',
        deletedTrialsString,
      );

      print('Saved deleted trial: $trialId');
    } catch (e) {
      print('Error saving deleted trial: $e');
    }
  }

  // 🔥 UPDATED: Trial classes with approval status
  Stream<List<Session>> getCombinedSessionsStream() {
    String? studentId = _auth.currentUser?.uid;

    if (studentId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('schedules')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date')
        .orderBy('time')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Session> allSessions = [];

          // 🔥 1. REGULAR SCHEDULES (With time)
          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data();

            // Skip if it's a trial class in schedules
            if (data['isTrial'] == true) continue;

            // Get teacher name from teachers collection
            String teacherName = 'Unknown Teacher';
            String teacherZoomLink = '';

            if (data['teacherId'] != null && data['teacherId'].isNotEmpty) {
              try {
                var teacherDoc = await _firestore
                    .collection('teachers')
                    .doc(data['teacherId'])
                    .get();
                if (teacherDoc.exists) {
                  teacherName = teacherDoc.data()?['name'] ?? 'Unknown Teacher';
                  teacherZoomLink = teacherDoc.data()?['zoomLink'] ?? '';
                }
              } catch (e) {
                print('Error fetching teacher: $e');
              }
            }

            String? packageName = data['packageName'];
            if (data['packageId'] != null &&
                data['packageId'].isNotEmpty &&
                packageName == null) {
              try {
                var packageDoc = await _firestore
                    .collection('packageAssignments')
                    .doc(data['packageId'])
                    .get();
                if (packageDoc.exists) {
                  packageName = packageDoc.data()?['packageName'];
                }
              } catch (e) {
                print('Error fetching package: $e');
              }
            }

            // 🔥🔥🔥 MAJOR CHANGE HERE TOO - Same logic as in Session.fromFirestore
            DateTime? dateTime;

            // PEHLE scheduledAt CHECK KARO (NEW UTC SYSTEM)
            if (data['scheduledAt'] != null) {
              try {
                Timestamp ts = data['scheduledAt'] as Timestamp;
                dateTime = ts
                    .toDate()
                    .toLocal(); // ✅ UTC se local time automatic
                print('✅ Using UTC timestamp in stream: ${dateTime}');
              } catch (e) {
                print('Error parsing scheduledAt in stream: $e');
              }
            }

            // AGAR scheduledAt NAHI HAI TOH PURANA SYSTEM USE KARO
            if (dateTime == null &&
                data['date'] != null &&
                data['time'] != null) {
              try {
                String dateStr = data['date'];
                String timeStr = data['time'];

                if (timeStr.toUpperCase().contains('AM') ||
                    timeStr.toUpperCase().contains('PM')) {
                  dateTime = DateFormat(
                    'yyyy-MM-dd h:mm a',
                  ).parse('$dateStr $timeStr');
                } else {
                  dateTime = DateFormat(
                    'yyyy-MM-dd HH:mm',
                  ).parse('$dateStr $timeStr');
                }
                print('⚠️ Using old date/time system in stream: ${dateTime}');
              } catch (e) {
                print('Date parsing error in stream: $e');
              }
            }

            // Status determine karo
            SessionStatus status = _determineStatus(dateTime, data['status']);

            // Zoom link
            String finalZoomLink = teacherZoomLink.isNotEmpty
                ? teacherZoomLink
                : (data['zoomLink'] ?? 'https://zoom.us/j/meeting');

            allSessions.add(
              Session(
                id: doc.id,
                name: teacherName,
                teacherImage: _getTeacherInitial(teacherName),
                dateTime: dateTime,
                duration: data['duration'] ?? '60 min',
                zoomLink: finalZoomLink,
                status: status,
                subject: data['subject'] ?? 'Quran',
                teacherId: data['teacherId'] ?? '',
                studentId: data['studentId'] ?? '',
                packageName: packageName,
                isTrial: false,
                sessionType: 'regular',
              ),
            );
          }

          // 🔥 2. TRIAL ASSIGNMENTS (Without time - With approval status)
          try {
            var trialSnapshot = await _firestore
                .collection('trialAssignments')
                .where('studentId', isEqualTo: studentId)
                .where(
                  'status',
                  whereIn: [
                    'pending',
                    'scheduled',
                    'completed',
                    'approved',
                    'rejected',
                  ],
                )
                .get();

            for (var trialDoc in trialSnapshot.docs) {
              Map<String, dynamic> trialData = trialDoc.data();
              String trialId = trialDoc.id;
              String fullTrialId = 'trial_$trialId';

              // 🔥 CHECK IF THIS TRIAL IS DELETED
              if (_deletedTrialIds.contains(fullTrialId)) {
                print('Skipping deleted trial: $fullTrialId');
                continue; // Skip this trial card
              }

              // Get teacher details
              String teacherName = 'Unknown Teacher';
              String teacherZoomLink = '';
              String teacherId = trialData['teacherId'] ?? '';

              if (teacherId.isNotEmpty) {
                try {
                  var teacherDoc = await _firestore
                      .collection('teachers')
                      .doc(teacherId)
                      .get();
                  if (teacherDoc.exists) {
                    teacherName =
                        teacherDoc.data()?['name'] ?? 'Unknown Teacher';
                    teacherZoomLink = teacherDoc.data()?['zoomLink'] ?? '';
                  }
                } catch (e) {
                  print('Error fetching teacher for trial: $e');
                }
              }

              // 🔥 TRIAL CLASSES: No specific date/time
              allSessions.add(
                Session(
                  id: fullTrialId,
                  name: teacherName,
                  teacherImage: _getTeacherInitial(teacherName),
                  dateTime: null,
                  duration: 'To be scheduled',
                  zoomLink: teacherZoomLink.isNotEmpty
                      ? teacherZoomLink
                      : 'https://zoom.us/j/meeting',
                  status: SessionStatus.upcoming,
                  subject:
                      'Trial Class - ${trialData['packageName'] ?? 'Quran'}',
                  teacherId: teacherId,
                  studentId: trialData['studentId'] ?? '',
                  packageName: trialData['packageName'] ?? 'Trial Package',
                  isTrial: true,
                  sessionType: 'trial',
                  trialAssignmentId: trialDoc.id,
                  trialStatus: trialData['status'] ?? 'pending',
                ),
              );
            }
          } catch (e) {
            print('Error fetching trial assignments: $e');
          }

          // Sort: Regular classes with time first, then trial classes
          allSessions.sort((a, b) {
            if (a.dateTime != null && b.dateTime != null) {
              return a.dateTime!.compareTo(b.dateTime!);
            } else if (a.dateTime != null) {
              return -1;
            } else if (b.dateTime != null) {
              return 1;
            } else {
              return a.name.compareTo(b.name);
            }
          });

          // 🔥 Update all sessions for calendar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _allSessions = allSessions;
              });
            }
          });

          return allSessions;
        });
  }

  // 🔥 DELETE TRIAL CARD FUNCTION
  Future<void> _deleteTrialCard(Session session) async {
    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Remove Trial Class'),
              ],
            ),
            content: Text(
              'Are you sure you want to remove this trial class from your schedule?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      // Save to deleted list
      await _saveDeletedTrial(session.id);

      // Refresh the list
      setState(() {});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Trial class removed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔥 UPDATED: MARK SESSION AS COMPLETED WHEN JOINING ZOOM
  Future<void> _markSessionAsCompleted(Session session) async {
    try {
      await _firestore.collection('schedules').doc(session.id).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Session marked as completed: ${session.id}');
    } catch (e) {
      print('❌ Error marking session as completed: $e');
    }
  }

  Future<void> _updateTrialApproval(Session session, String newStatus) async {
    try {
      String studentId = _auth.currentUser?.uid ?? '';

      if (studentId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();

      Map<String, dynamic> studentData =
          studentDoc.data() as Map<String, dynamic>;
      String studentName = studentData['name'] ?? 'Unknown Student';

      if (session.trialAssignmentId != null) {
        await _firestore
            .collection('trialAssignments')
            .doc(session.trialAssignmentId)
            .update({
              'status': newStatus,
              'studentApproval': newStatus,
              'approvedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      await _firestore.collection('students').doc(studentId).update({
        'trialStatus': newStatus,
        'studentApprovalStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      String feedbackMessage = newStatus == 'approved'
          ? 'Student was satisfied with the trial class. Ready to proceed with regular classes.'
          : 'Student was not satisfied with the teaching style. Requesting new teacher assignment.';

      await _firestore.collection('packageChangeRequests').add({
        'type': 'teacher_approval',
        'studentId': studentId,
        'studentName': studentName,
        'teacherName': session.name,
        'teacherId': session.teacherId,
        'packageName': session.packageName ?? 'Trial Package',
        'status': newStatus,
        'message': feedbackMessage,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'trialAssignmentId': session.trialAssignmentId,
      });

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'approved'
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    newStatus == 'approved'
                        ? '🎉 Teacher approved successfully! Admin will contact you soon.'
                        : '✅ Feedback submitted. Admin will assign another teacher.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: newStatus == 'approved'
                ? Colors.green
                : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      setState(() {});
    } catch (e) {
      print('❌ Error updating trial approval: $e');

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showApprovalDialog(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.thumb_up, color: Colors.green),
            SizedBox(width: 8),
            Text('Approve Teacher'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your trial class with ${session.name}?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Your feedback will help us improve the teaching experience.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRejectConfirmation(session);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red),
            ),
            child: Text('Not Satisfied', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showApproveConfirmation(session);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              'Approve Teacher',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirm Approval'),
          ],
        ),
        content: Text(
          'Are you sure you want to approve ${session.name} as your teacher?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTrialApproval(session, 'approved');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Yes, Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Provide Feedback'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please share why you are not satisfied:'),
            SizedBox(height: 12),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g., Teaching style, communication, timing issues...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {},
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
              _updateTrialApproval(session, 'rejected');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }

  SessionStatus _determineStatus(DateTime? dateTime, String? status) {
    if (status == 'completed') return SessionStatus.completed;
    if (status == 'cancelled') return SessionStatus.missed;

    if (dateTime == null) return SessionStatus.upcoming;

    DateTime now = DateTime.now();

    // 🔥 NEW: AGAR CLASS KA TIME ABHI 7 BAJAY HAI TO 30 MINUTES TAK 'ONGOING' RAHEGA
    if (dateTime.isBefore(now) &&
        dateTime.add(Duration(minutes: 30)).isAfter(now)) {
      return SessionStatus.ongoing;
    }

    // 🔥 NEW: 30 MINUTES BAAD 'MISSED' HOGA
    if (dateTime.add(Duration(minutes: 30)).isBefore(now)) {
      return SessionStatus.missed;
    }

    if (dateTime.isAfter(now)) return SessionStatus.upcoming;

    return SessionStatus.upcoming;
  }

  String _getTeacherInitial(String name) {
    if (name.isEmpty) return 'T';
    return name[0].toUpperCase();
  }

  // 🔥 CALENDAR VIEW WIDGET
  Widget _buildCalendarView() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 🔥 Calendar Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedule Calendar',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.list, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _showCalendarView = false;
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 🔥 SfCalendar Widget
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SfCalendar(
                controller: _calendarController,
                view: CalendarView.week,
                dataSource: _getCalendarDataSource(),
                monthViewSettings: MonthViewSettings(
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                  showAgenda: true,
                ),
                onTap: (CalendarTapDetails details) {
                  if (details.targetElement == CalendarElement.appointment) {
                    final Appointment tappedAppointment =
                        details.appointments![0];
                    final Session session = tappedAppointment.id as Session;
                    _showSessionDetails(session);
                  }
                },
                headerHeight: 50,
                appointmentTextStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                todayHighlightColor: AppColors.primary,
                selectionDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // 🔥 Legend
          SizedBox(height: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  // 🔥 Calendar Data Source
  _AppointmentDataSource _getCalendarDataSource() {
    List<Appointment> appointments = [];

    for (var session in _allSessions) {
      if (session.dateTime != null) {
        Color appointmentColor = _getSessionColor(session);
        DateTime endTime = session.dateTime!.add(
          Duration(minutes: int.tryParse(session.duration.split(' ')[0]) ?? 60),
        );

        appointments.add(
          Appointment(
            startTime: session.dateTime!,
            endTime: endTime,
            subject: '${session.subject}\n${session.name}',
            color: appointmentColor,
            id: session,
            notes: session.packageName ?? '',
          ),
        );
      }
    }

    return _AppointmentDataSource(appointments);
  }

  Color _getSessionColor(Session session) {
    if (session.isTrial) {
      return AppColors.warning;
    }

    switch (session.status) {
      case SessionStatus.upcoming:
        return AppColors.primary;
      case SessionStatus.ongoing:
        return Colors.orange;
      case SessionStatus.completed:
        return Colors.green;
      case SessionStatus.missed:
        return AppColors.redPrimary;
    }
  }

  // 🔥 Calendar Legend
  Widget _buildCalendarLegend() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem(AppColors.primary, 'Upcoming'),
              _buildLegendItem(Colors.orange, 'Ongoing'),
              _buildLegendItem(Colors.green, 'Completed'),
              _buildLegendItem(AppColors.redPrimary, 'Missed'),
              _buildLegendItem(AppColors.warning, 'Trial'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 6),
        Text(text, style: AppTextStyles.captionText.copyWith(fontSize: 11)),
      ],
    );
  }

  // 🔥 Show Session Details when tapped on calendar
  void _showSessionDetails(Session session) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildSessionCard(session, forCalendar: true),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _joinZoomMeeting(session);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Join Class',
                        style: AppTextStyles.buttonPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openTeacherChat(session);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Chat with Teacher',
                        style: AppTextStyles.buttonSecondary.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Schedule', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showCalendarView ? Icons.list : Icons.calendar_month_outlined,
              color: AppColors.white,
            ),
            onPressed: () {
              setState(() {
                _showCalendarView = !_showCalendarView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showNotificationSettings();
            },
          ),
        ],
        bottom: _showCalendarView
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: AppColors.white,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.tabLabel.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                ),
                unselectedLabelStyle: AppTextStyles.tabLabel.copyWith(
                  color: AppColors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Missed'),
                ],
              ),
      ),
      body: StreamBuilder<List<Session>>(
        stream: getCombinedSessionsStream(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return _buildLoadingState();
          // }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final sessions = snapshot.data ?? [];

          return _showCalendarView
              ? _buildCalendarView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSessionList(sessions),
                    _buildSessionList(
                      _filterSessions(sessions, SessionStatus.upcoming),
                    ),
                    _buildSessionList(
                      _filterSessions(sessions, SessionStatus.completed),
                    ),
                    _buildSessionList(
                      _filterSessions(sessions, SessionStatus.missed),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildSessionCard(Session session, {bool forCalendar = false}) {
    Color statusColor = _getStatusColor(session.status);
    bool isUpcoming = session.status == SessionStatus.upcoming;
    bool isOngoing = session.status == SessionStatus.ongoing;
    bool isMissed = session.status == SessionStatus.missed;
    bool isCompleted = session.status == SessionStatus.completed;
    bool hasPackage =
        session.packageName != null && session.packageName!.isNotEmpty;
    bool isTrial = session.isTrial;
    bool hasTime = session.dateTime != null;

    bool showApprovalButtons = isTrial && session.trialStatus == 'completed';
    bool isApproved = isTrial && session.trialStatus == 'approved';
    bool isRejected = isTrial && session.trialStatus == 'rejected';

    return GestureDetector(
      onTap: () {
        if (!showApprovalButtons && !isApproved && !isRejected) {
          _openTeacherChat(session);
        }
      },
      child: Container(
        margin: forCalendar ? EdgeInsets.zero : EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTrial
                ? (isApproved
                      ? Colors.green
                      : (isRejected ? Colors.red : AppColors.warning))
                : (isMissed ? AppColors.redPrimary : AppColors.border),
            width: isTrial ? 2 : (isMissed ? 2 : 1),
          ),
          boxShadow: forCalendar
              ? []
              : [
                  BoxShadow(
                    color: (isTrial ? AppColors.warning : statusColor)
                        .withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // 🔥 DELETE BUTTON - ONLY FOR TRIAL CARDS
            if (isTrial && !forCalendar)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deleteTrialCard(session),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ),
              ),

            // Main Content
            IntrinsicHeight(
              child: Row(
                children: [
                  // Left Status Indicator
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: isTrial
                          ? (isApproved
                                ? Colors.green
                                : (isRejected ? Colors.red : AppColors.warning))
                          : statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    (isTrial
                                            ? (isApproved
                                                  ? Colors.green
                                                  : (isRejected
                                                        ? Colors.red
                                                        : AppColors.warning))
                                            : statusColor)
                                        .withOpacity(0.2),
                                child: Text(
                                  session.teacherImage,
                                  style: AppTextStyles.heading3.copyWith(
                                    color: isTrial
                                        ? (isApproved
                                              ? Colors.green
                                              : (isRejected
                                                    ? Colors.red
                                                    : AppColors.warning))
                                        : statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                            session.name,
                                            style: AppTextStyles.cardTitle
                                                .copyWith(
                                                  color: AppColors.text,
                                                ),
                                          ),
                                        ),
                                        if (isTrial) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getTrialStatusColor(
                                                session.trialStatus,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _getTrialStatusColor(
                                                  session.trialStatus,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              _getTrialStatusText(
                                                session.trialStatus,
                                              ),
                                              style: AppTextStyles.captionText
                                                  .copyWith(
                                                    color: _getTrialStatusColor(
                                                      session.trialStatus,
                                                    ),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (isTrial) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            _getTrialStatusIcon(
                                              session.trialStatus,
                                            ),
                                            size: 14,
                                            color: _getTrialStatusColor(
                                              session.trialStatus,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getTrialStatusDisplayText(
                                              session.trialStatus,
                                            ),
                                            style: AppTextStyles.captionText
                                                .copyWith(
                                                  color: _getTrialStatusColor(
                                                    session.trialStatus,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Row(
                                        children: [
                                          Icon(
                                            _getStatusIcon(session.status),
                                            size: 14,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getStatusText(session.status),
                                            style: AppTextStyles.captionText
                                                .copyWith(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            session.subject,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isTrial
                                  ? _getTrialStatusColor(session.trialStatus)
                                  : statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          if (hasPackage) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isTrial
                                    ? _getTrialStatusColor(
                                        session.trialStatus,
                                      ).withOpacity(0.1)
                                    : statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isTrial
                                      ? _getTrialStatusColor(
                                          session.trialStatus,
                                        ).withOpacity(0.3)
                                      : statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    size: 12,
                                    color: isTrial
                                        ? _getTrialStatusColor(
                                            session.trialStatus,
                                          )
                                        : statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    session.packageName!,
                                    style: AppTextStyles.captionText.copyWith(
                                      color: isTrial
                                          ? _getTrialStatusColor(
                                              session.trialStatus,
                                            )
                                          : statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (showApprovalButtons && !forCalendar) ...[
                            const SizedBox(height: 16),
                            Text(
                              '🎉 Trial class completed! Please share your feedback:',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showApprovalDialog(session);
                                    },
                                    icon: Icon(
                                      Icons.thumb_down,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    label: Text(
                                      'Not Satisfied',
                                      style: AppTextStyles.buttonSecondary
                                          .copyWith(
                                            fontSize: 14,
                                            color: Colors.red,
                                          ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showApprovalDialog(session);
                                    },
                                    icon: Icon(
                                      Icons.thumb_up,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Approve Teacher',
                                      style: AppTextStyles.buttonPrimary
                                          .copyWith(fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (isApproved && !forCalendar) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '🎉 You approved this teacher! Admin will contact you for regular classes.',
                                      style: AppTextStyles.captionText.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (isRejected && !forCalendar) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Thank you for your feedback. Admin will assign another teacher.',
                                      style: AppTextStyles.captionText.copyWith(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (isTrial &&
                              !showApprovalButtons &&
                              !isApproved &&
                              !isRejected &&
                              !forCalendar) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_outlined,
                                    color: AppColors.warning,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tap to chat with teacher and schedule trial class timing',
                                      style: AppTextStyles.captionText.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (hasTime) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.subtitle,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(session.dateTime!),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: AppColors.subtitle,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  session.duration,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // 🔥 UPDATED: ACTION BUTTONS FOR REGULAR CLASSES
                          if ((isUpcoming || isOngoing) &&
                              hasTime &&
                              !isTrial &&
                              !forCalendar) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _joinZoomMeeting(session);
                                    },
                                    icon: const Icon(Icons.videocam, size: 18),
                                    label: Text(
                                      isOngoing ? 'Join Now' : 'Join Zoom',
                                      style: AppTextStyles.buttonPrimary
                                          .copyWith(fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isOngoing
                                          ? Colors.orange
                                          : AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // 🔥 ONGOING CLASS MESSAGE
                            if (isOngoing) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Class is ongoing. Join within 30 minutes.',
                                        style: AppTextStyles.captionText
                                            .copyWith(
                                              color: Colors.orange,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          // MISSED SESSION ACTIONS - ONLY AFTER 30 MINUTES
                          if (isMissed && !isTrial && !forCalendar) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.redPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.redPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You missed this session (30 minutes passed)',
                                      style: AppTextStyles.captionText.copyWith(
                                        color: AppColors.redPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // TextButton(
                                  //   onPressed: () {
                                  //     _bookMakeupSession(session);
                                  //   },
                                  //   // child: Text(
                                  //   //   'Book Makeup',
                                  //   //   style: AppTextStyles.captionText.copyWith(
                                  //   //     color: AppColors.redPrimary,
                                  //   //     fontWeight: FontWeight.bold,
                                  //   //   ),
                                  //   // ),
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Color _getTrialStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.purple;
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
        return Icons.flag;
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
        return 'SCHEDULED';
      case 'pending':
        return 'PENDING';
      case 'completed':
        return 'COMPLETED';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'TRIAL';
    }
  }

  String _getTrialStatusDisplayText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Trial Scheduled';
      case 'pending':
        return 'Schedule Pending';
      case 'completed':
        return 'Awaiting Your Feedback';
      case 'approved':
        return 'Teacher Approved';
      case 'rejected':
        return 'Feedback Submitted';
      default:
        return 'Trial Class';
    }
  }

  void _openTeacherChat(Session session) {
    String currentUserId = _auth.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not logged in', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentChatScreen(
          otherUserId: session.teacherId,
          otherUserName: session.name,
          currentUserId: currentUserId,
          currentUserRole: 'student',
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading your schedule...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          SizedBox(height: 16),
          Text(
            'Error loading schedule',
            style: AppTextStyles.heading3.copyWith(color: AppColors.error),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(List<Session> sessionList) {
    if (sessionList.isEmpty) {
      return _buildEmptyState();
    }

    Map<String, List<Session>> groupedSessions = {};
    List<Session> noDateSessions = [];

    for (var session in sessionList) {
      if (session.dateTime != null) {
        String dateKey = _formatDateHeader(session.dateTime!);
        if (!groupedSessions.containsKey(dateKey)) {
          groupedSessions[dateKey] = [];
        }
        groupedSessions[dateKey]!.add(session);
      } else {
        noDateSessions.add(session);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      children: [
        if (noDateSessions.isNotEmpty) ...[
          _buildDateHeader('Trial Classes'),
          const SizedBox(height: 12),
          ...noDateSessions.map((session) => _buildSessionCard(session)),
          const SizedBox(height: 20),
        ],

        ...groupedSessions.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(entry.key),
              const SizedBox(height: 12),
              ...entry.value.map((session) => _buildSessionCard(session)),
              const SizedBox(height: 20),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        date,
        style: AppTextStyles.heading4.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No Sessions Found',
            style: AppTextStyles.heading3.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 10),
          Text(
            'Book your first Quran session',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  List<Session> _filterSessions(List<Session> sessions, SessionStatus status) {
    return sessions.where((s) => s.status == status).toList();
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.upcoming:
        return AppColors.primary;
      case SessionStatus.ongoing:
        return Colors.orange;
      case SessionStatus.completed:
        return Colors.green;
      case SessionStatus.missed:
        return AppColors.redPrimary;
    }
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.upcoming:
        return Icons.schedule;
      case SessionStatus.ongoing:
        return Icons.play_circle_filled;
      case SessionStatus.completed:
        return Icons.check_circle;
      case SessionStatus.missed:
        return Icons.cancel;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.upcoming:
        return 'Upcoming';
      case SessionStatus.ongoing:
        return 'Ongoing';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.missed:
        return 'Missed';
    }
  }

  String _formatDateHeader(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  void _joinZoomMeeting(Session session) async {
    if (session.zoomLink.isEmpty ||
        session.zoomLink == 'https://zoom.us/j/meeting') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Zoom link not available. Please contact your teacher.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(session.zoomLink);
      await _markSessionAsCompleted(session);

      // canLaunchUrl hatao, directly launch karo
      await launchUrl(url, mode: LaunchMode.externalApplication);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening Zoom meeting...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error opening Zoom: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Zoom link. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _bookMakeupSession(Session session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking makeup session...',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentNotificationsScreen(),
      ),
    );
  }
}

// 🔥 Calendar Data Source Class
class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
