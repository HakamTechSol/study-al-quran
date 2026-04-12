// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:html' as html;
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:file_saver/file_saver.dart';
// import 'package:permission_handler/permission_handler.dart';

// class ReportsAttendanceScreen extends StatefulWidget {
//   const ReportsAttendanceScreen({super.key});

//   @override
//   State<ReportsAttendanceScreen> createState() =>
//       _ReportsAttendanceScreenState();
// }

// class _ReportsAttendanceScreenState extends State<ReportsAttendanceScreen> {
//   int selectedTab = 0;
//   String selectedStatusFilter = 'All';
//   String selectedDateFilter = 'All Time';
//   String searchQuery = '';

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // 🔥 EXPORT CONFIG
//   bool _isExporting = false;
//   ExportFormat _exportFormat = ExportFormat.csv;
//   DateTimeRange? _exportDateRange;
//   List<String> _exportStatusFilter = ['All'];

//   // 🔥 CHECK IF WEB PLATFORM
//   bool get isWeb {
//     return kIsWeb; // Flutter foundation se check karo
//   }

//   // 🔥 WEB DOWNLOAD METHOD
//   void _downloadFileWeb(String content, String fileName) {
//     try {
//       if (kIsWeb) {
//         // Create Blob
//         final blob = html.Blob([content]);
//         final url = html.Url.createObjectUrlFromBlob(blob);

//         // Create anchor element
//         final anchor = html.AnchorElement(href: url)
//           ..setAttribute('download', fileName)
//           ..style.display = 'none';

//         html.document.body?.append(anchor);
//         anchor.click();
//         html.Url.revokeObjectUrl(url);
//         anchor.remove();
//       }
//     } catch (e) {
//       print('❌ Web download error: $e');
//       // Fallback to alternative method
//       _downloadFileWebAlternative(content, fileName);
//     }
//   }

//   // 🔥 ALTERNATIVE WEB DOWNLOAD (MORE RELIABLE)
//   void _downloadFileWebAlternative(String content, String fileName) {
//     try {
//       // Create data URL
//       final encodedContent = Uri.encodeComponent(content);
//       final dataUrl = 'data:text/plain;charset=utf-8,$encodedContent';

//       // Create hidden link and click
//       final anchor = html.AnchorElement(href: dataUrl)
//         ..setAttribute('download', fileName)
//         ..style.display = 'none';

//       html.document.body?.append(anchor);
//       anchor.click();
//       anchor.remove();

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('File downloaded: $fileName'),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       print('❌ Alternative web download error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Download failed: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // 🔥 CONVERT Firebase status to display status
//   String _normalizeStatus(String? status) {
//     if (status == null || status.isEmpty) return 'Unknown';

//     switch (status.toLowerCase()) {
//       case 'present':
//       case 'attended':
//         return 'Attended';
//       case 'absent':
//         return 'Absent without apology';
//       case 'absent with apology':
//       case 'absentwithapology':
//         return 'Absent with apology';
//       case 'absent without apology':
//       case 'absentwithoutapology':
//         return 'Absent without apology';
//       default:
//         return status;
//     }
//   }

//   bool _isWithinDateRange(DateTime date) {
//     final now = DateTime.now();
//     switch (selectedDateFilter) {
//       case 'Today':
//         return date.year == now.year &&
//             date.month == now.month &&
//             date.day == now.day;
//       case 'This Week':
//         final weekStart = now.subtract(Duration(days: now.weekday - 1));
//         return date.isAfter(weekStart.subtract(const Duration(days: 1)));
//       case 'This Month':
//         return date.year == now.year && date.month == now.month;
//       case 'All Time':
//       default:
//         return true;
//     }
//   }

//   Stream<List<AttendanceRecord>> getAttendanceStream() {
//     return _firestore
//         .collection('attendance')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .asyncMap((snapshot) async {
//           List<AttendanceRecord> attendanceRecords = [];

//           for (var doc in snapshot.docs) {
//             try {
//               Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

//               // Get student name
//               String studentName =
//                   data['studentName']?.toString() ?? 'Unknown Student';
//               String studentId = data['studentId']?.toString() ?? '';

//               if (studentName == 'Unknown Student' && studentId.isNotEmpty) {
//                 try {
//                   var studentDoc = await _firestore
//                       .collection('students')
//                       .doc(studentId)
//                       .get();
//                   if (studentDoc.exists) {
//                     studentName =
//                         studentDoc.data()?['name'] ?? 'Unknown Student';
//                   }
//                 } catch (e) {
//                   print('Error fetching student: $e');
//                 }
//               }

//               // Get teacher name
//               String teacherName =
//                   data['teacherName']?.toString() ?? 'Unknown Teacher';
//               String teacherId = data['teacherId']?.toString() ?? '';

//               if (teacherName == 'Unknown Teacher' && teacherId.isNotEmpty) {
//                 try {
//                   var teacherDoc = await _firestore
//                       .collection('teachers')
//                       .doc(teacherId)
//                       .get();
//                   if (teacherDoc.exists) {
//                     teacherName =
//                         teacherDoc.data()?['name'] ?? 'Unknown Teacher';
//                   }
//                 } catch (e) {
//                   print('Error fetching teacher: $e');
//                 }
//               }

//               attendanceRecords.add(
//                 AttendanceRecord.fromFirestore(
//                   data,
//                   doc.id,
//                   studentName,
//                   teacherName,
//                 ),
//               );
//             } catch (e) {
//               print('Error processing attendance record ${doc.id}: $e');
//             }
//           }

//           return attendanceRecords;
//         });
//   }

//   // 🔥 GET SESSION REPORTS STREAM
//   Stream<List<SessionReport>> getSessionReportsStream() {
//     return _firestore
//         .collection('attendance')
//         // .where('reportMessage', isNotEqualTo: '')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .asyncMap((snapshot) async {
//           List<SessionReport> sessionReports = [];

//           for (var doc in snapshot.docs) {
//             try {
//               Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

//               final reportMessage = data['reportMessage']?.toString();
//               if (reportMessage == null || reportMessage.isEmpty) {
//                 continue;
//               }

//               String studentName =
//                   data['studentName']?.toString() ?? 'Unknown Student';
//               String studentId = data['studentId']?.toString() ?? '';

//               if (studentName == 'Unknown Student' && studentId.isNotEmpty) {
//                 try {
//                   var studentDoc = await _firestore
//                       .collection('students')
//                       .doc(studentId)
//                       .get();
//                   if (studentDoc.exists) {
//                     studentName =
//                         studentDoc.data()?['name'] ?? 'Unknown Student';
//                   }
//                 } catch (e) {
//                   print('Error fetching student: $e');
//                 }
//               }

//               String teacherName =
//                   data['teacherName']?.toString() ?? 'Unknown Teacher';
//               String teacherId = data['teacherId']?.toString() ?? '';

//               if (teacherName == 'Unknown Teacher' && teacherId.isNotEmpty) {
//                 try {
//                   var teacherDoc = await _firestore
//                       .collection('teachers')
//                       .doc(teacherId)
//                       .get();
//                   if (teacherDoc.exists) {
//                     teacherName =
//                         teacherDoc.data()?['name'] ?? 'Unknown Teacher';
//                   }
//                 } catch (e) {
//                   print('Error fetching teacher: $e');
//                 }
//               }

//               String topicCompleted =
//                   data['topicCompleted']?.toString() ?? 'No topic completed';
//               String homework =
//                   data['homeworkAssigned']?.toString() ??
//                   'No homework assigned';
//               int sessionNumber = (data['sessionNumber'] ?? 1).toInt();
//               int totalSessions = (data['totalSessions'] ?? 20).toInt();
//               String teacherNotes = data['teacherNotes']?.toString() ?? '';

//               String subject = _extractSubjectFromReport(reportMessage);
//               if (subject.isEmpty) {
//                 subject = data['subject']?.toString() ?? 'Quran';
//               }

//               sessionReports.add(
//                 SessionReport.fromFirestore(
//                   data,
//                   doc.id,
//                   studentName,
//                   teacherName,
//                   reportMessage,
//                   topicCompleted,
//                   homework,
//                   sessionNumber,
//                   totalSessions,
//                   teacherNotes,
//                   subject,
//                 ),
//               );
//             } catch (e) {
//               print('Error processing report ${doc.id}: $e');
//             }
//           }

//           return sessionReports;
//         });
//   }

//   // 🔥 GET ALL ATTENDANCE FOR EXPORT
//   Future<List<AttendanceRecord>> getAllAttendanceForExport() async {
//     try {
//       final snapshot = await _firestore
//           .collection('attendance')
//           .orderBy('timestamp', descending: true)
//           .get();

//       List<AttendanceRecord> attendanceRecords = [];

//       for (var doc in snapshot.docs) {
//         try {
//           Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

//           String studentName =
//               data['studentName']?.toString() ?? 'Unknown Student';
//           String studentId = data['studentId']?.toString() ?? '';

//           if (studentName == 'Unknown Student' && studentId.isNotEmpty) {
//             try {
//               var studentDoc = await _firestore
//                   .collection('students')
//                   .doc(studentId)
//                   .get();
//               if (studentDoc.exists) {
//                 studentName = studentDoc.data()?['name'] ?? 'Unknown Student';
//               }
//             } catch (e) {
//               print('Error fetching student: $e');
//             }
//           }

//           String teacherName =
//               data['teacherName']?.toString() ?? 'Unknown Teacher';
//           String teacherId = data['teacherId']?.toString() ?? '';

//           if (teacherName == 'Unknown Teacher' && teacherId.isNotEmpty) {
//             try {
//               var teacherDoc = await _firestore
//                   .collection('teachers')
//                   .doc(teacherId)
//                   .get();
//               if (teacherDoc.exists) {
//                 teacherName = teacherDoc.data()?['name'] ?? 'Unknown Teacher';
//               }
//             } catch (e) {
//               print('Error fetching teacher: $e');
//             }
//           }

//           attendanceRecords.add(
//             AttendanceRecord.fromFirestore(
//               data,
//               doc.id,
//               studentName,
//               teacherName,
//             ),
//           );
//         } catch (e) {
//           print('Error processing attendance record ${doc.id}: $e');
//         }
//       }

//       return attendanceRecords;
//     } catch (e) {
//       print('❌ Error getting attendance for export: $e');
//       return [];
//     }
//   }

//   // 🔥 GET ALL REPORTS FOR EXPORT
//   Future<List<SessionReport>> getAllReportsForExport() async {
//     try {
//       final snapshot = await _firestore
//           .collection('attendance')
//           .where('reportMessage', isNotEqualTo: '')
//           .orderBy('timestamp', descending: true)
//           .get();

//       List<SessionReport> sessionReports = [];

//       for (var doc in snapshot.docs) {
//         try {
//           Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

//           final reportMessage = data['reportMessage']?.toString();
//           if (reportMessage == null || reportMessage.isEmpty) {
//             continue;
//           }

//           String studentName =
//               data['studentName']?.toString() ?? 'Unknown Student';
//           String studentId = data['studentId']?.toString() ?? '';

//           if (studentName == 'Unknown Student' && studentId.isNotEmpty) {
//             try {
//               var studentDoc = await _firestore
//                   .collection('students')
//                   .doc(studentId)
//                   .get();
//               if (studentDoc.exists) {
//                 studentName = studentDoc.data()?['name'] ?? 'Unknown Student';
//               }
//             } catch (e) {
//               print('Error fetching student: $e');
//             }
//           }

//           String teacherName =
//               data['teacherName']?.toString() ?? 'Unknown Teacher';
//           String teacherId = data['teacherId']?.toString() ?? '';

//           if (teacherName == 'Unknown Teacher' && teacherId.isNotEmpty) {
//             try {
//               var teacherDoc = await _firestore
//                   .collection('teachers')
//                   .doc(teacherId)
//                   .get();
//               if (teacherDoc.exists) {
//                 teacherName = teacherDoc.data()?['name'] ?? 'Unknown Teacher';
//               }
//             } catch (e) {
//               print('Error fetching teacher: $e');
//             }
//           }

//           String topicCompleted =
//               data['topicCompleted']?.toString() ?? 'No topic completed';
//           String homework =
//               data['homeworkAssigned']?.toString() ?? 'No homework assigned';
//           int sessionNumber = (data['sessionNumber'] ?? 1).toInt();
//           int totalSessions = (data['totalSessions'] ?? 20).toInt();
//           String teacherNotes = data['teacherNotes']?.toString() ?? '';

//           String subject = _extractSubjectFromReport(reportMessage);
//           if (subject.isEmpty) {
//             subject = data['subject']?.toString() ?? 'Quran';
//           }

//           sessionReports.add(
//             SessionReport.fromFirestore(
//               data,
//               doc.id,
//               studentName,
//               teacherName,
//               reportMessage,
//               topicCompleted,
//               homework,
//               sessionNumber,
//               totalSessions,
//               teacherNotes,
//               subject,
//             ),
//           );
//         } catch (e) {
//           print('Error processing report ${doc.id}: $e');
//         }
//       }

//       return sessionReports;
//     } catch (e) {
//       print('❌ Error getting reports for export: $e');
//       return [];
//     }
//   }

//   String _extractSubjectFromReport(String reportMessage) {
//     if (reportMessage.toLowerCase().contains('surah') ||
//         reportMessage.toLowerCase().contains('ayat')) {
//       return 'Quran';
//     } else if (reportMessage.toLowerCase().contains('hadith')) {
//       return 'Hadith';
//     } else if (reportMessage.toLowerCase().contains('arabic')) {
//       return 'Arabic';
//     } else if (reportMessage.toLowerCase().contains('fiqh')) {
//       return 'Fiqh';
//     } else if (reportMessage.toLowerCase().contains('tajweed')) {
//       return 'Tajweed';
//     }
//     return 'Quran';
//   }

//   // 🔥 EXPORT ATTENDANCE TO CSV/EXCEL - WEB COMPATIBLE
//   Future<void> _exportAttendance() async {
//     try {
//       setState(() => _isExporting = true);

//       final attendanceRecords = await getAllAttendanceForExport();

//       if (attendanceRecords.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('No attendance data to export'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//         setState(() => _isExporting = false);
//         return;
//       }

//       // Filter records based on export settings
//       List<AttendanceRecord> filteredRecords = attendanceRecords.where((
//         record,
//       ) {
//         // Date range filter
//         if (_exportDateRange != null) {
//           final recordDate = record.timestamp ?? DateTime.now();
//           if (!recordDate.isAfter(_exportDateRange!.start) ||
//               !recordDate.isBefore(_exportDateRange!.end)) {
//             return false;
//           }
//         }

//         // Status filter
//         if (!_exportStatusFilter.contains('All')) {
//           final displayStatus = _normalizeStatus(record.status);
//           if (!_exportStatusFilter.contains(displayStatus)) {
//             return false;
//           }
//         }

//         return true;
//       }).toList();

//       if (filteredRecords.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('No data matches export criteria'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//         setState(() => _isExporting = false);
//         return;
//       }

//       String content = '';
//       String fileName = '';

//       if (_exportFormat == ExportFormat.csv) {
//         content = _convertToCSV(filteredRecords);
//         fileName =
//             'attendance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
//       } else if (_exportFormat == ExportFormat.excel) {
//         content = _convertToExcel(filteredRecords);
//         fileName =
//             'attendance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
//       } else {
//         content = _convertToJSON(filteredRecords);
//         fileName =
//             'attendance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
//       }

//       // 🔥 WEB DOWNLOAD
//       if (isWeb) {
//         _downloadFileWeb(content, fileName);
//       } else {
//         // 🔥 MOBILE PLATFORM (Android/iOS)
//         // Request storage permission
//         final status = await Permission.storage.request();
//         if (!status.isGranted) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Text('Storage permission required for export'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//           setState(() => _isExporting = false);
//           return;
//         }

//         Uint8List bytes = Uint8List.fromList(utf8.encode(content));

//         // Save file
//         await FileSaver.instance.saveFile(name: fileName, bytes: bytes);
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Exported ${filteredRecords.length} records to $fileName',
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       print('❌ Export error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Export failed: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       setState(() => _isExporting = false);
//     }
//   }

//   // 🔥 EXPORT REPORTS TO CSV/EXCEL - WEB COMPATIBLE
//   Future<void> _exportReports() async {
//     try {
//       setState(() => _isExporting = true);

//       final sessionReports = await getAllReportsForExport();

//       if (sessionReports.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('No session reports to export'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//         setState(() => _isExporting = false);
//         return;
//       }

//       // Filter reports
//       List<SessionReport> filteredReports = sessionReports.where((report) {
//         if (_exportDateRange != null) {
//           final recordDate = report.timestamp ?? DateTime.now();
//           if (!recordDate.isAfter(_exportDateRange!.start) ||
//               !recordDate.isBefore(_exportDateRange!.end)) {
//             return false;
//           }
//         }
//         return true;
//       }).toList();

//       if (filteredReports.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('No reports match export criteria'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//         setState(() => _isExporting = false);
//         return;
//       }

//       String content = '';
//       String fileName = '';

//       if (_exportFormat == ExportFormat.csv) {
//         content = _convertReportsToCSV(filteredReports);
//         fileName =
//             'session_reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
//       } else if (_exportFormat == ExportFormat.excel) {
//         content = _convertReportsToExcel(filteredReports);
//         fileName =
//             'session_reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
//       } else {
//         content = _convertReportsToJSON(filteredReports);
//         fileName =
//             'session_reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
//       }

//       // 🔥 WEB DOWNLOAD
//       if (isWeb) {
//         _downloadFileWeb(content, fileName);
//       } else {
//         // 🔥 MOBILE PLATFORM (Android/iOS)
//         final status = await Permission.storage.request();
//         if (!status.isGranted) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Text('Storage permission required for export'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//           setState(() => _isExporting = false);
//           return;
//         }

//         Uint8List bytes = Uint8List.fromList(utf8.encode(content));

//         await FileSaver.instance.saveFile(name: fileName, bytes: bytes);
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Exported ${filteredReports.length} reports to $fileName',
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       print('❌ Export reports error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Export failed: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       setState(() => _isExporting = false);
//     }
//   }

//   // 🔥 CONVERT ATTENDANCE TO CSV
//   String _convertToCSV(List<AttendanceRecord> records) {
//     final columns = [
//       'Student Name',
//       'Teacher Name',
//       'Subject',
//       'Date',
//       'Time',
//       'Status',
//       'Session Fee',
//       'Notes',
//       'Edited By',
//       'Student ID',
//       'Teacher ID',
//       'Timestamp',
//     ];

//     final header = columns.join(',');

//     final rows = records.map((record) {
//       return [
//         _escapeCSV(record.studentName),
//         _escapeCSV(record.teacherName),
//         _escapeCSV(record.subject),
//         _escapeCSV(record.date),
//         _escapeCSV(record.time),
//         _escapeCSV(_normalizeStatus(record.status)),
//         record.sessionFee.toStringAsFixed(2),
//         _escapeCSV(record.notes),
//         _escapeCSV(record.editedBy),
//         _escapeCSV(record.studentId),
//         _escapeCSV(record.teacherId),
//         record.timestamp?.toIso8601String() ?? '',
//       ].join(',');
//     }).toList();

//     return header + '\n' + rows.join('\n');
//   }

//   // 🔥 CONVERT REPORTS TO CSV
//   String _convertReportsToCSV(List<SessionReport> reports) {
//     final columns = [
//       'Student Name',
//       'Teacher Name',
//       'Subject',
//       'Date',
//       'Time',
//       'Session Number',
//       'Total Sessions',
//       'Sessions Remaining',
//       'Topic Completed',
//       'Homework Assigned',
//       'Teacher Notes',
//       'Report Status',
//       'Reviewed By',
//       'Edited By',
//       'Report Preview',
//       'Student ID',
//       'Teacher ID',
//       'Timestamp',
//     ];

//     final header = columns.join(',');

//     final rows = reports.map((report) {
//       String reportPreview = report.reportText.length > 100
//           ? report.reportText.substring(0, 100) + '...'
//           : report.reportText;

//       return [
//         _escapeCSV(report.studentName),
//         _escapeCSV(report.teacherName),
//         _escapeCSV(report.subject),
//         _escapeCSV(report.date),
//         _escapeCSV(report.time),
//         report.sessionsCompleted.toString(),
//         report.packageTotal.toString(),
//         report.sessionsRemaining.toString(),
//         _escapeCSV(report.topicCompleted),
//         _escapeCSV(report.homework),
//         _escapeCSV(report.teacherNotes),
//         _escapeCSV(report.reportStatus),
//         _escapeCSV(report.reviewedBy),
//         _escapeCSV(report.editedBy),
//         _escapeCSV(reportPreview),
//         _escapeCSV(report.studentId),
//         _escapeCSV(report.teacherId),
//         report.timestamp?.toIso8601String() ?? '',
//       ].join(',');
//     }).toList();

//     return header + '\n' + rows.join('\n');
//   }

//   // 🔥 EXCEL FORMAT (Simplified HTML table)
//   String _convertToExcel(List<AttendanceRecord> records) {
//     final columns = [
//       'Student Name',
//       'Teacher Name',
//       'Subject',
//       'Date',
//       'Time',
//       'Status',
//       'Session Fee',
//       'Notes',
//     ];

//     final html =
//         '''
// <html>
// <head>
// <meta charset="UTF-8">
// <style>
// table { border-collapse: collapse; width: 100%; }
// th { background-color: #4F46E5; color: white; padding: 10px; text-align: left; }
// td { padding: 8px; border: 1px solid #ddd; }
// tr:nth-child(even) { background-color: #f2f2f2; }
// </style>
// </head>
// <body>
// <h2>Attendance Report - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</h2>
// <table>
// <tr>${columns.map((col) => '<th>$col</th>').join('')}</tr>
// ${records.map((record) => '''
// <tr>
// <td>${record.studentName}</td>
// <td>${record.teacherName}</td>
// <td>${record.subject}</td>
// <td>${record.date}</td>
// <td>${record.time}</td>
// <td>${_normalizeStatus(record.status)}</td>
// <td>${record.sessionFee.toStringAsFixed(2)}</td>
// <td>${record.notes}</td>
// </tr>
// ''').join('')}
// </table>
// </body>
// </html>
// ''';

//     return html;
//   }

//   String _convertReportsToExcel(List<SessionReport> reports) {
//     final columns = [
//       'Student Name',
//       'Teacher Name',
//       'Subject',
//       'Date',
//       'Time',
//       'Session',
//       'Total Sessions',
//       'Topic Completed',
//       'Homework',
//       'Report Status',
//     ];

//     final html =
//         '''
// <html>
// <head>
// <meta charset="UTF-8">
// <style>
// table { border-collapse: collapse; width: 100%; }
// th { background-color: #10B981; color: white; padding: 10px; text-align: left; }
// td { padding: 8px; border: 1px solid #ddd; }
// tr:nth-child(even) { background-color: #f2f2f2; }
// </style>
// </head>
// <body>
// <h2>Session Reports - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</h2>
// <table>
// <tr>${columns.map((col) => '<th>$col</th>').join('')}</tr>
// ${reports.map((report) => '''
// <tr>
// <td>${report.studentName}</td>
// <td>${report.teacherName}</td>
// <td>${report.subject}</td>
// <td>${report.date}</td>
// <td>${report.time}</td>
// <td>${report.sessionsCompleted}/${report.packageTotal}</td>
// <td>${report.sessionsRemaining}</td>
// <td>${report.topicCompleted}</td>
// <td>${report.homework}</td>
// <td>${report.reportStatus}</td>
// </tr>
// ''').join('')}
// </table>
// </body>
// </html>
// ''';

//     return html;
//   }

//   // 🔥 JSON FORMAT
//   String _convertToJSON(List<AttendanceRecord> records) {
//     final jsonData = records
//         .map(
//           (record) => {
//             'studentName': record.studentName,
//             'teacherName': record.teacherName,
//             'subject': record.subject,
//             'date': record.date,
//             'time': record.time,
//             'status': _normalizeStatus(record.status),
//             'sessionFee': record.sessionFee,
//             'notes': record.notes,
//             'editedBy': record.editedBy,
//             'studentId': record.studentId,
//             'teacherId': record.teacherId,
//             'timestamp': record.timestamp?.toIso8601String(),
//           },
//         )
//         .toList();

//     return jsonEncode({
//       'exportType': 'attendance',
//       'exportDate': DateTime.now().toIso8601String(),
//       'recordCount': records.length,
//       'data': jsonData,
//     });
//   }

//   String _convertReportsToJSON(List<SessionReport> reports) {
//     final jsonData = reports
//         .map(
//           (report) => {
//             'studentName': report.studentName,
//             'teacherName': report.teacherName,
//             'subject': report.subject,
//             'date': report.date,
//             'time': report.time,
//             'sessionNumber': report.sessionsCompleted,
//             'totalSessions': report.packageTotal,
//             'sessionsRemaining': report.sessionsRemaining,
//             'topicCompleted': report.topicCompleted,
//             'homework': report.homework,
//             'teacherNotes': report.teacherNotes,
//             'reportStatus': report.reportStatus,
//             'reviewedBy': report.reviewedBy,
//             'editedBy': report.editedBy,
//             'reportPreview': report.reportText.length > 100
//                 ? report.reportText.substring(0, 100) + '...'
//                 : report.reportText,
//             'studentId': report.studentId,
//             'teacherId': report.teacherId,
//             'timestamp': report.timestamp?.toIso8601String(),
//           },
//         )
//         .toList();

//     return jsonEncode({
//       'exportType': 'session_reports',
//       'exportDate': DateTime.now().toIso8601String(),
//       'recordCount': reports.length,
//       'data': jsonData,
//     });
//   }

//   String _escapeCSV(String value) {
//     if (value.contains(',') || value.contains('"') || value.contains('\n')) {
//       return '"${value.replaceAll('"', '""')}"';
//     }
//     return value;
//   }

//   // 🔥 SHOW EXPORT DIALOG
//   void _showExportDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Row(
//               children: [
//                 const Icon(Icons.download_outlined, color: Colors.blue),
//                 const SizedBox(width: 10),
//                 const Text(
//                   'Export Data',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             content: SizedBox(
//               width: 500,
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Export Type
//                     const Text(
//                       'Export Type',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 10,
//                       children: [
//                         _buildExportTypeOption('Attendance Log', 0, setState),
//                         _buildExportTypeOption('Session Reports', 1, setState),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // Format
//                     const Text(
//                       'Export Format',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 10,
//                       children: [
//                         _buildFormatOption('CSV', ExportFormat.csv, setState),
//                         _buildFormatOption(
//                           'Excel',
//                           ExportFormat.excel,
//                           setState,
//                         ),
//                         _buildFormatOption('PDF', ExportFormat.pdf, setState),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // Date Range
//                     const Text(
//                       'Date Range (Optional)',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: () async {
//                               final DateTimeRange? picked =
//                                   await showDateRangePicker(
//                                     context: context,
//                                     firstDate: DateTime(2023),
//                                     lastDate: DateTime.now(),
//                                     initialDateRange: _exportDateRange,
//                                   );
//                               if (picked != null) {
//                                 setState(() => _exportDateRange = picked);
//                               }
//                             },
//                             icon: const Icon(Icons.calendar_today, size: 16),
//                             label: Text(
//                               _exportDateRange != null
//                                   ? '${DateFormat('dd/MM/yy').format(_exportDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_exportDateRange!.end)}'
//                                   : 'Select Date Range',
//                               style: const TextStyle(fontSize: 12),
//                             ),
//                             style: OutlinedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                             ),
//                           ),
//                         ),
//                         if (_exportDateRange != null) ...[
//                           const SizedBox(width: 8),
//                           IconButton(
//                             icon: const Icon(Icons.clear, size: 18),
//                             onPressed: () =>
//                                 setState(() => _exportDateRange = null),
//                             color: Colors.red,
//                           ),
//                         ],
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // Status Filter
//                     if (selectedTab == 0) ...[
//                       const Text(
//                         'Status Filter',
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: [
//                           FilterChip(
//                             label: const Text('All'),
//                             selected: _exportStatusFilter.contains('All'),
//                             onSelected: (selected) {
//                               setState(() {
//                                 if (selected) {
//                                   _exportStatusFilter = ['All'];
//                                 } else {
//                                   _exportStatusFilter.remove('All');
//                                 }
//                               });
//                             },
//                             selectedColor: Colors.blue.withOpacity(0.1),
//                           ),
//                           FilterChip(
//                             label: const Text('Attended'),
//                             selected: _exportStatusFilter.contains('Attended'),
//                             onSelected: (selected) {
//                               setState(() {
//                                 _exportStatusFilter.remove('All');
//                                 if (selected) {
//                                   _exportStatusFilter.add('Attended');
//                                 } else {
//                                   _exportStatusFilter.remove('Attended');
//                                 }
//                               });
//                             },
//                             selectedColor: const Color(
//                               0xFF10B981,
//                             ).withOpacity(0.1),
//                           ),
//                           FilterChip(
//                             label: const Text('Absent with apology'),
//                             selected: _exportStatusFilter.contains(
//                               'Absent with apology',
//                             ),
//                             onSelected: (selected) {
//                               setState(() {
//                                 _exportStatusFilter.remove('All');
//                                 if (selected) {
//                                   _exportStatusFilter.add(
//                                     'Absent with apology',
//                                   );
//                                 } else {
//                                   _exportStatusFilter.remove(
//                                     'Absent with apology',
//                                   );
//                                 }
//                               });
//                             },
//                             selectedColor: const Color(
//                               0xFFF59E0B,
//                             ).withOpacity(0.1),
//                           ),
//                           FilterChip(
//                             label: const Text('Absent without apology'),
//                             selected: _exportStatusFilter.contains(
//                               'Absent without apology',
//                             ),
//                             onSelected: (selected) {
//                               setState(() {
//                                 _exportStatusFilter.remove('All');
//                                 if (selected) {
//                                   _exportStatusFilter.add(
//                                     'Absent without apology',
//                                   );
//                                 } else {
//                                   _exportStatusFilter.remove(
//                                     'Absent without apology',
//                                   );
//                                 }
//                               });
//                             },
//                             selectedColor: const Color(
//                               0xFFEF4444,
//                             ).withOpacity(0.1),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         'Selected: ${_exportStatusFilter.join(', ')}',
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],

//                     // Export Summary
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.05),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.blue.withOpacity(0.2)),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Export Summary:',
//                             style: TextStyle(
//                               color: Colors.blue,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             selectedTab == 0
//                                 ? '• Exporting Attendance Log\n• Format: ${_exportFormat.toString().split('.').last}\n• Date Range: ${_exportDateRange != null ? '${DateFormat('dd/MM/yy').format(_exportDateRange!.start)} to ${DateFormat('dd/MM/yy').format(_exportDateRange!.end)}' : 'All Time'}\n• Status: ${_exportStatusFilter.join(', ')}'
//                                 : '• Exporting Session Reports\n• Format: ${_exportFormat.toString().split('.').last}\n• Date Range: ${_exportDateRange != null ? '${DateFormat('dd/MM/yy').format(_exportDateRange!.start)} to ${DateFormat('dd/MM/yy').format(_exportDateRange!.end)}' : 'All Time'}',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton.icon(
//                 onPressed: _isExporting
//                     ? null
//                     : () async {
//                         Navigator.of(context).pop();
//                         if (selectedTab == 0) {
//                           await _exportAttendance();
//                         } else {
//                           await _exportReports();
//                         }
//                       },
//                 icon: _isExporting
//                     ? SizedBox(
//                         height: 18,
//                         width: 18,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Icon(Icons.download, size: 18),
//                 label: Text(_isExporting ? 'Exporting...' : 'Export'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildExportTypeOption(
//     String title,
//     int type,
//     void Function(void Function()) setState,
//   ) {
//     return ChoiceChip(
//       label: Text(title),
//       selected: selectedTab == type,
//       onSelected: (selected) => setState(() => selectedTab = type),
//       selectedColor: Colors.blue.withOpacity(0.2),
//       labelStyle: TextStyle(
//         color: selectedTab == type ? Colors.blue : Colors.black,
//       ),
//     );
//   }

//   Widget _buildFormatOption(
//     String title,
//     ExportFormat format,
//     void Function(void Function()) setState,
//   ) {
//     return ChoiceChip(
//       label: Text(title),
//       selected: _exportFormat == format,
//       onSelected: (selected) => setState(() => _exportFormat = format),
//       selectedColor: Colors.blue.withOpacity(0.2),
//       labelStyle: TextStyle(
//         color: _exportFormat == format ? Colors.blue : Colors.black,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeader(),
//             const SizedBox(height: 16),
//             _buildTabs(),
//             const SizedBox(height: 16),
//             Expanded(
//               child: selectedTab == 0
//                   ? _buildAttendanceLog()
//                   : _buildSessionReports(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Reports & Attendance',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               'Track attendance and view session reports',
//               style: TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//           ],
//         ),
//         Row(
//           children: [
//             OutlinedButton.icon(
//               onPressed: _showExportDialog,
//               icon: const Icon(Icons.download, size: 16, color: Colors.blue),
//               label: const Text(
//                 'Export',
//                 style: TextStyle(color: Colors.blue, fontSize: 12),
//               ),
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.blue),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 10,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.calendar_today,
//                     color: Colors.blue,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Today: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
//                     style: const TextStyle(color: Colors.black, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildTabs() {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildTabButton(
//               0,
//               'Attendance Log',
//               Icons.fact_check_outlined,
//             ),
//           ),
//           Expanded(
//             child: _buildTabButton(
//               1,
//               'Session Reports',
//               Icons.description_outlined,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabButton(int index, String label, IconData icon) {
//     final isSelected = selectedTab == index;
//     return InkWell(
//       onTap: () => setState(() => selectedTab = index),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue : Colors.transparent,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? Colors.white : Colors.grey,
//               size: 18,
//             ),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : Colors.black,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceLog() {
//     return Column(
//       children: [
//         _buildCompactAttendanceFilters(),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 100,
//           child: StreamBuilder<List<AttendanceRecord>>(
//             stream: getAttendanceStream(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }

//               final attendanceRecords = snapshot.data ?? [];
//               final filteredRecords = _filterAttendanceRecords(
//                 attendanceRecords,
//               );

//               final totalSessions = filteredRecords.length;
//               final attendedSessions = filteredRecords
//                   .where(
//                     (a) =>
//                         a.status.toLowerCase().contains('attended') ||
//                         a.status.toLowerCase().contains('present'),
//                   )
//                   .length;
//               final absentWithApology = filteredRecords
//                   .where((a) => a.status.toLowerCase().contains('with apology'))
//                   .length;
//               final absentWithoutApology = filteredRecords
//                   .where(
//                     (a) => a.status.toLowerCase().contains('without apology'),
//                   )
//                   .length;

//               return _buildCompactAttendanceStats(
//                 totalSessions,
//                 attendedSessions,
//                 absentWithApology,
//                 absentWithoutApology,
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 12),
//         Expanded(child: _buildCompactAttendanceTable()),
//       ],
//     );
//   }

//   Widget _buildCompactAttendanceFilters() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: TextField(
//               onChanged: (value) => setState(() => searchQuery = value),
//               decoration: InputDecoration(
//                 hintText: 'Search by student or teacher name...',
//                 hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
//                 prefixIcon: Icon(
//                   Icons.search,
//                   color: Colors.grey.shade600,
//                   size: 18,
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey.shade400),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey.shade400),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildCompactFilterDropdown(
//               'Status',
//               selectedStatusFilter,
//               [
//                 'All',
//                 'Attended',
//                 'Absent with apology',
//                 'Absent without apology',
//               ],
//               (value) => setState(() => selectedStatusFilter = value!),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildCompactFilterDropdown(
//               'Date Range',
//               selectedDateFilter,
//               ['All Time', 'Today', 'This Week', 'This Month'],
//               (value) => setState(() => selectedDateFilter = value!),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCompactFilterDropdown(
//     String label,
//     String value,
//     List<String> items,
//     Function(String?) onChanged,
//   ) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade400),
//       ),
//       child: DropdownButtonFormField<String>(
//         value: value,
//         items: items
//             .map(
//               (item) => DropdownMenuItem(
//                 value: item,
//                 child: Text(item, style: const TextStyle(fontSize: 12)),
//               ),
//             )
//             .toList(),
//         onChanged: onChanged,
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 12,
//             vertical: 8,
//           ),
//         ),
//         dropdownColor: Colors.grey.shade100,
//       ),
//     );
//   }

//   Widget _buildCompactAttendanceStats(
//     int totalSessions,
//     int attendedSessions,
//     int absentWithApology,
//     int absentWithoutApology,
//   ) {
//     return Row(
//       children: [
//         _buildCompactStatCard(
//           'Total',
//           '$totalSessions',
//           Icons.event_available,
//           Colors.blue,
//         ),
//         const SizedBox(width: 8),
//         _buildCompactStatCard(
//           'Attended',
//           '$attendedSessions',
//           Icons.check_circle,
//           const Color(0xFF10B981),
//         ),
//         const SizedBox(width: 8),
//         _buildCompactStatCard(
//           'With Apology',
//           '$absentWithApology',
//           Icons.event_busy,
//           const Color(0xFFF59E0B),
//         ),
//         const SizedBox(width: 8),
//         _buildCompactStatCard(
//           'Without Apology',
//           '$absentWithoutApology',
//           Icons.cancel,
//           const Color(0xFFEF4444),
//         ),
//       ],
//     );
//   }

//   Widget _buildCompactStatCard(
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(6),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Icon(icon, color: color, size: 16),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     value,
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     title,
//                     style: const TextStyle(color: Colors.grey, fontSize: 10),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCompactAttendanceTable() {
//     return StreamBuilder<List<AttendanceRecord>>(
//       stream: getAttendanceStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(color: Colors.blue),
//           );
//         }

//         if (snapshot.hasError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, size: 48, color: Colors.red),
//                 const SizedBox(height: 12),
//                 Text(
//                   'Error: ${snapshot.error}',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           );
//         }

//         final attendanceRecords = snapshot.data ?? [];
//         final filteredRecords = _filterAttendanceRecords(attendanceRecords);

//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 height: 50,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   border: Border(
//                     bottom: BorderSide(color: Colors.grey.shade400),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: _buildCompactTableHeader('Student'),
//                     ),
//                     Expanded(
//                       flex: 2,
//                       child: _buildCompactTableHeader('Teacher'),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: _buildCompactTableHeader('Date & Time'),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: _buildCompactTableHeader('Status'),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: _buildCompactTableHeader('Actions'),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: filteredRecords.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.event_busy,
//                               size: 48,
//                               color: Colors.grey,
//                             ),
//                             const SizedBox(height: 12),
//                             const Text(
//                               'No attendance records found',
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           ],
//                         ),
//                       )
//                     : ListView.builder(
//                         itemCount: filteredRecords.length,
//                         itemBuilder: (context, index) {
//                           final attendance = filteredRecords[index];
//                           return Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               border: Border(
//                                 bottom: BorderSide(
//                                   color: Colors.grey.shade300.withOpacity(0.3),
//                                 ),
//                               ),
//                             ),
//                             child: _buildCompactAttendanceRow(attendance),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildCompactTableHeader(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         color: Colors.black,
//         fontSize: 11,
//         fontWeight: FontWeight.w600,
//       ),
//     );
//   }

//   Widget _buildCompactAttendanceRow(AttendanceRecord attendance) {
//     Color statusColor;
//     IconData statusIcon;
//     String displayStatus = _normalizeStatus(attendance.status);

//     switch (displayStatus) {
//       case 'Attended':
//         statusColor = const Color(0xFF10B981);
//         statusIcon = Icons.check_circle;
//         break;
//       case 'Absent with apology':
//         statusColor = const Color(0xFFF59E0B);
//         statusIcon = Icons.event_busy;
//         break;
//       case 'Absent without apology':
//         statusColor = const Color(0xFFEF4444);
//         statusIcon = Icons.cancel;
//         break;
//       default:
//         statusColor = Colors.grey;
//         statusIcon = Icons.help_outline;
//         displayStatus = attendance.status;
//     }

//     return Row(
//       children: [
//         Expanded(
//           flex: 2,
//           child: Text(
//             attendance.studentName,
//             style: const TextStyle(color: Colors.black, fontSize: 11),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         Expanded(
//           flex: 2,
//           child: Text(
//             attendance.teacherName,
//             style: const TextStyle(color: Colors.black, fontSize: 11),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         Expanded(
//           flex: 1,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 attendance.date,
//                 style: const TextStyle(color: Colors.black, fontSize: 10),
//               ),
//               Text(
//                 attendance.time,
//                 style: const TextStyle(color: Colors.grey, fontSize: 9),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           flex: 1,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: statusColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(statusIcon, size: 12, color: statusColor),
//                 const SizedBox(width: 4),
//                 Flexible(
//                   child: Text(
//                     _getStatusAbbreviation(displayStatus),
//                     style: TextStyle(
//                       color: statusColor,
//                       fontSize: 9,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Expanded(
//           flex: 1,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.visibility_outlined, size: 16),
//                 onPressed: () => _showAttendanceDetails(attendance),
//                 color: Colors.blue,
//                 tooltip: 'View Details',
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//               const SizedBox(width: 4),
//               IconButton(
//                 icon: const Icon(Icons.edit_outlined, size: 16),
//                 onPressed: () => _showEditAttendanceDialog(attendance),
//                 color: Colors.grey,
//                 tooltip: 'Edit Status',
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   String _getStatusAbbreviation(String status) {
//     switch (status) {
//       case 'Attended':
//         return 'Attended';
//       case 'Absent with apology':
//         return 'With Apology';
//       case 'Absent without apology':
//         return 'No Apology';
//       case 'present':
//         return 'Present';
//       case 'absent':
//         return 'Absent';
//       default:
//         return status.length > 10 ? '${status.substring(0, 10)}...' : status;
//     }
//   }

//   Widget _buildSessionReports() {
//     return Column(
//       children: [
//         _buildCompactReportsFilters(),
//         const SizedBox(height: 12),
//         Expanded(child: _buildReportsList()),
//       ],
//     );
//   }

//   Widget _buildCompactReportsFilters() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: TextField(
//               onChanged: (value) => setState(() => searchQuery = value),
//               decoration: InputDecoration(
//                 hintText: 'Search reports by student, teacher or topic...',
//                 hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
//                 prefixIcon: Icon(
//                   Icons.search,
//                   color: Colors.grey.shade600,
//                   size: 18,
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey.shade400),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey.shade400),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildCompactFilterDropdown(
//               'Date Range',
//               selectedDateFilter,
//               ['All Time', 'Today', 'This Week', 'This Month'],
//               (value) => setState(() => selectedDateFilter = value!),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   List<AttendanceRecord> _filterAttendanceRecords(
//     List<AttendanceRecord> records,
//   ) {
//     return records.where((record) {
//       final matchesSearch =
//           searchQuery.isEmpty ||
//           record.studentName.toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           ) ||
//           record.teacherName.toLowerCase().contains(searchQuery.toLowerCase());

//       final displayStatus = _normalizeStatus(record.status);
//       final matchesFilter =
//           selectedStatusFilter == 'All' ||
//           displayStatus == selectedStatusFilter;

//       final matchesDate = _isWithinDateRange(
//         record.timestamp ?? DateTime.now(),
//       );

//       return matchesSearch && matchesFilter && matchesDate;
//     }).toList();
//   }

//   Widget _buildReportsList() {
//     return StreamBuilder<List<SessionReport>>(
//       stream: getSessionReportsStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(color: Colors.blue),
//           );
//         }

//         if (snapshot.hasError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, size: 48, color: Colors.red),
//                 const SizedBox(height: 12),
//                 Text(
//                   'Error: ${snapshot.error}',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           );
//         }

//         final sessionReports = snapshot.data ?? [];
//         final filteredReports = _filterSessionReports(sessionReports);

//         if (filteredReports.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.description_outlined, size: 48, color: Colors.grey),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'No session reports found',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Reports will appear when teachers submit session reports',
//                   style: TextStyle(color: Colors.grey, fontSize: 11),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           );
//         }

//         return ListView.builder(
//           itemCount: filteredReports.length,
//           itemBuilder: (context, index) {
//             final report = filteredReports[index];
//             return _buildReportCard(report);
//           },
//         );
//       },
//     );
//   }

//   List<SessionReport> _filterSessionReports(List<SessionReport> reports) {
//     return reports.where((report) {
//       final matchesSearch =
//           searchQuery.isEmpty ||
//           report.studentName.toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           ) ||
//           report.teacherName.toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           ) ||
//           report.topicCompleted.toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           ) ||
//           report.homework.toLowerCase().contains(searchQuery.toLowerCase()) ||
//           report.reportText.toLowerCase().contains(searchQuery.toLowerCase());

//       final matchesDate = _isWithinDateRange(
//         report.timestamp ?? DateTime.now(),
//       );

//       return matchesSearch && matchesDate;
//     }).toList();
//   }

//   Widget _buildReportCard(SessionReport report) {
//     final progress = report.packageTotal > 0
//         ? report.sessionsCompleted / report.packageTotal
//         : 0.0;

//     Color statusColor;
//     IconData statusIcon;
//     String statusText = report.reportStatus;

//     if (report.editedBy.isNotEmpty) {
//       statusColor = const Color(0xFFF59E0B);
//       statusIcon = Icons.edit;
//       statusText = 'Edited';
//     } else if (report.reviewedBy.isNotEmpty) {
//       statusColor = const Color(0xFF10B981);
//       statusIcon = Icons.check_circle;
//       statusText = 'Reviewed';
//     } else {
//       statusColor = const Color(0xFF6B7280);
//       statusIcon = Icons.pending;
//       statusText = 'Pending';
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(Icons.description, color: Colors.blue, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       report.studentName,
//                       style: const TextStyle(
//                         color: Colors.black,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.person_outline,
//                           size: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           report.teacherName,
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 10,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Icon(
//                           Icons.book_outlined,
//                           size: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           report.subject,
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 10,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: statusColor.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(statusIcon, size: 12, color: statusColor),
//                     const SizedBox(width: 4),
//                     Text(
//                       statusText,
//                       style: TextStyle(
//                         color: statusColor,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     report.date,
//                     style: const TextStyle(color: Colors.black, fontSize: 11),
//                   ),
//                   Text(
//                     report.time,
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Report Summary
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey.shade400),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.bookmark_outline,
//                             size: 12,
//                             color: Colors.blue,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'Topic: ${report.topicCompleted}',
//                             style: TextStyle(
//                               color: Colors.blue,
//                               fontSize: 10,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF10B981).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.assignment_outlined,
//                             size: 12,
//                             color: const Color(0xFF10B981),
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'Homework: ${report.homework}',
//                             style: TextStyle(
//                               color: const Color(0xFF10B981),
//                               fontSize: 10,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   report.reportText,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 12,
//                     height: 1.4,
//                   ),
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Progress Section
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'Package Progress',
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontSize: 11,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         Text(
//                           'Session ${report.sessionsCompleted} of ${report.packageTotal}',
//                           style: const TextStyle(
//                             color: Colors.blue,
//                             fontSize: 11,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: LinearProgressIndicator(
//                         value: progress,
//                         backgroundColor: Colors.grey.shade300,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                         minHeight: 6,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '${report.sessionsRemaining}',
//                       style: const TextStyle(
//                         color: Colors.blue,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const Text(
//                       'Remaining',
//                       style: TextStyle(color: Colors.blue, fontSize: 9),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Teacher Notes
//           if (report.teacherNotes.isNotEmpty) ...[
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFEF3C7).withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: const Color(0xFFF59E0B).withOpacity(0.3),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.note_outlined,
//                         size: 14,
//                         color: const Color(0xFFF59E0B),
//                       ),
//                       const SizedBox(width: 6),
//                       const Text(
//                         'Teacher Notes:',
//                         style: TextStyle(
//                           color: Color(0xFF92400E),
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     report.teacherNotes,
//                     style: const TextStyle(
//                       color: Color(0xFF92400E),
//                       fontSize: 11,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//           ],

//           // Action Buttons
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.event, size: 12, color: Colors.grey.shade600),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Session #${report.sessionsCompleted}',
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   // Edit Button
//                   OutlinedButton.icon(
//                     onPressed: () => _showEditReportDialog(report),
//                     icon: const Icon(Icons.edit_outlined, size: 14),
//                     label: const Text('Edit', style: TextStyle(fontSize: 11)),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.blue,
//                       side: const BorderSide(color: Colors.blue),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 6,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   // View Button
//                   OutlinedButton.icon(
//                     onPressed: () => _showReportDetails(report),
//                     icon: const Icon(Icons.visibility_outlined, size: 14),
//                     label: const Text('View', style: TextStyle(fontSize: 11)),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.blue,
//                       side: const BorderSide(color: Colors.blue),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 6,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   void _showAttendanceDetails(AttendanceRecord attendance) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//           'Attendance Details',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         content: SizedBox(
//           width: 500,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('Student:', attendance.studentName),
//                 _buildDetailRow('Teacher:', attendance.teacherName),
//                 _buildDetailRow('Date:', attendance.date),
//                 _buildDetailRow('Time:', attendance.time),
//                 _buildDetailRow('Status:', _normalizeStatus(attendance.status)),
//                 if (attendance.editedBy.isNotEmpty)
//                   _buildDetailRow('Last Edited By:', attendance.editedBy),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Notes:',
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.shade400),
//                   ),
//                   child: Text(
//                     attendance.notes.isEmpty
//                         ? 'No notes available'
//                         : attendance.notes,
//                     style: const TextStyle(color: Colors.black, fontSize: 13),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _showEditAttendanceDialog(attendance);
//             },
//             child: const Text('Edit Status'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.grey,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(color: Colors.black, fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showEditAttendanceDialog(AttendanceRecord attendance) {
//     String selectedStatus = _normalizeStatus(attendance.status);
//     TextEditingController notesController = TextEditingController(
//       text: attendance.notes,
//     );

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//           'Edit Attendance Status',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         content: SizedBox(
//           width: 400,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildDetailRow('Student:', attendance.studentName),
//               _buildDetailRow('Teacher:', attendance.teacherName),
//               _buildDetailRow('Date:', '${attendance.date} ${attendance.time}'),
//               const SizedBox(height: 16),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Status',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.grey.shade400),
//                     ),
//                     child: DropdownButtonFormField<String>(
//                       value: selectedStatus,
//                       items: [
//                         DropdownMenuItem(
//                           value: 'Attended',
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.check_circle,
//                                 color: const Color(0xFF10B981),
//                                 size: 18,
//                               ),
//                               const SizedBox(width: 8),
//                               const Text('Attended'),
//                             ],
//                           ),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Absent with apology',
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.event_busy,
//                                 color: const Color(0xFFF59E0B),
//                                 size: 18,
//                               ),
//                               const SizedBox(width: 8),
//                               const Text('Absent with apology'),
//                             ],
//                           ),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Absent without apology',
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.cancel,
//                                 color: const Color(0xFFEF4444),
//                                 size: 18,
//                               ),
//                               const SizedBox(width: 8),
//                               const Text('Absent without apology'),
//                             ],
//                           ),
//                         ),
//                       ],
//                       onChanged: (value) => selectedStatus = value!,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 12,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFEF3C7),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: const Color(0xFFF59E0B)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.warning_amber,
//                       color: Color(0xFFF59E0B),
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Changing status will recalculate teacher wallet balance',
//                         style: const TextStyle(
//                           color: Color(0xFF92400E),
//                           fontSize: 11,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Admin Notes',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: notesController,
//                     maxLines: 3,
//                     decoration: InputDecoration(
//                       hintText: 'Add reason for correction...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.grey.shade400),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.grey.shade400),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _updateAttendanceStatus(
//                 attendance.id,
//                 selectedStatus,
//                 notesController.text,
//                 attendance.studentId,
//                 attendance.teacherId,
//                 attendance.sessionFee,
//               );
//               Navigator.of(context).pop();
//             },
//             child: const Text('Save Changes'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showEditReportDialog(SessionReport report) {
//     TextEditingController reportController = TextEditingController(
//       text: report.reportText,
//     );
//     TextEditingController topicController = TextEditingController(
//       text: report.topicCompleted,
//     );
//     TextEditingController homeworkController = TextEditingController(
//       text: report.homework,
//     );
//     TextEditingController teacherNotesController = TextEditingController(
//       text: report.teacherNotes,
//     );

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//           'Edit Session Report',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         content: SizedBox(
//           width: 600,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('Student:', report.studentName),
//                 _buildDetailRow('Teacher:', report.teacherName),
//                 _buildDetailRow('Date:', '${report.date} ${report.time}'),
//                 _buildDetailRow(
//                   'Session:',
//                   '${report.sessionsCompleted}/${report.packageTotal}',
//                 ),
//                 const SizedBox(height: 16),

//                 // Topic Completed
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Topic Completed',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: topicController,
//                       decoration: InputDecoration(
//                         hintText: 'Enter topic completed...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.grey.shade400),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.grey.shade400),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 // Homework Assigned
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Homework Assigned',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: homeworkController,
//                       decoration: InputDecoration(
//                         hintText: 'Enter homework assigned...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.grey.shade400),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.grey.shade400),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 // Teacher Notes
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Teacher Notes',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: teacherNotesController,
//                       maxLines: 3,
//                       decoration: InputDecoration(
//                         hintText: 'Enter teacher notes...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.grey.shade400),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.grey.shade400),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 // Report Message
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Session Report',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       height: 200,
//                       child: TextField(
//                         controller: reportController,
//                         maxLines: null,
//                         expands: true,
//                         textAlignVertical: TextAlignVertical.top,
//                         decoration: InputDecoration(
//                           hintText: 'Enter session report...',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide(color: Colors.grey.shade400),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide(color: Colors.grey.shade400),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _updateSessionReport(
//                 report.id,
//                 reportController.text,
//                 teacherNotesController.text,
//                 topicController.text,
//                 homeworkController.text,
//               );
//               Navigator.of(context).pop();
//             },
//             child: const Text('Save Report'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showReportDetails(SessionReport report) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//           'Session Report Details',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         content: SizedBox(
//           width: 600,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('Student:', report.studentName),
//                 _buildDetailRow('Teacher:', report.teacherName),
//                 _buildDetailRow('Date:', report.date),
//                 _buildDetailRow('Time:', report.time),
//                 _buildDetailRow('Subject:', report.subject),
//                 _buildDetailRow(
//                   'Session Number:',
//                   '${report.sessionsCompleted}',
//                 ),
//                 _buildDetailRow('Total Sessions:', '${report.packageTotal}'),
//                 _buildDetailRow(
//                   'Sessions Remaining:',
//                   '${report.sessionsRemaining}',
//                 ),
//                 _buildDetailRow('Topic Completed:', report.topicCompleted),
//                 _buildDetailRow('Homework Assigned:', report.homework),
//                 if (report.teacherNotes.isNotEmpty)
//                   _buildDetailRow('Teacher Notes:', report.teacherNotes),
//                 if (report.reviewedBy.isNotEmpty)
//                   _buildDetailRow('Reviewed By:', report.reviewedBy),
//                 if (report.editedBy.isNotEmpty)
//                   _buildDetailRow('Last Edited By:', report.editedBy),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Full Report:',
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.shade400),
//                   ),
//                   child: Text(
//                     report.reportText,
//                     style: const TextStyle(color: Colors.black, fontSize: 13),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _updateAttendanceStatus(
//     String attendanceId,
//     String status,
//     String notes,
//     String studentId,
//     String teacherId,
//     double sessionFee,
//   ) async {
//     try {
//       final adminUser = _auth.currentUser;
//       final adminName = adminUser?.email ?? 'Admin';

//       String firebaseStatus = status.toLowerCase().contains('attended')
//           ? 'present'
//           : 'absent';

//       await _firestore.collection('attendance').doc(attendanceId).update({
//         'status': firebaseStatus,
//         'notes': notes,
//         'editedBy': adminName,
//         'editedAt': FieldValue.serverTimestamp(),
//         'lastEditReason': 'Admin correction',
//       });

//       if (status == 'Attended' && sessionFee > 0) {
//         await _firestore.collection('teachers').doc(teacherId).update({
//           'walletBalance': FieldValue.increment(sessionFee),
//         });

//         await _firestore.collection('wallet_transactions').add({
//           'teacherId': teacherId,
//           'type': 'earning',
//           'amount': sessionFee,
//           'reason': 'Class attended - Admin corrected',
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       } else if (sessionFee > 0) {
//         await _firestore.collection('teachers').doc(teacherId).update({
//           'walletBalance': FieldValue.increment(-sessionFee),
//         });

//         await _firestore.collection('wallet_transactions').add({
//           'teacherId': teacherId,
//           'type': 'deduction',
//           'amount': sessionFee,
//           'reason': 'Attendance corrected to $status',
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Attendance updated & wallet recalculated',
//               style: TextStyle(fontSize: 12),
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e', style: const TextStyle(fontSize: 12)),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _updateSessionReport(
//     String reportId,
//     String reportText,
//     String teacherNotes,
//     String topicCompleted,
//     String homeworkAssigned,
//   ) async {
//     try {
//       final adminUser = _auth.currentUser;
//       final adminName = adminUser?.email ?? 'Admin';

//       await _firestore.collection('attendance').doc(reportId).update({
//         'reportMessage': reportText,
//         'teacherNotes': teacherNotes,
//         'topicCompleted': topicCompleted,
//         'homeworkAssigned': homeworkAssigned,
//         'editedBy': adminName,
//         'editedAt': FieldValue.serverTimestamp(),
//         'reportStatus': 'Edited',
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Report updated successfully',
//               style: TextStyle(fontSize: 12),
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e', style: const TextStyle(fontSize: 12)),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
// }

// // 🔥 DATA MODELS
// class AttendanceRecord {
//   final String id;
//   final String studentId;
//   final String teacherId;
//   final String studentName;
//   final String teacherName;
//   final String subject;
//   final DateTime? timestamp;
//   final String date;
//   final String time;
//   final String status;
//   final String notes;
//   final double sessionFee;
//   final String editedBy;

//   AttendanceRecord({
//     required this.id,
//     required this.studentId,
//     required this.teacherId,
//     required this.studentName,
//     required this.teacherName,
//     required this.subject,
//     required this.timestamp,
//     required this.date,
//     required this.time,
//     required this.status,
//     required this.notes,
//     required this.sessionFee,
//     required this.editedBy,
//   });

//   factory AttendanceRecord.fromFirestore(
//     Map<String, dynamic> data,
//     String id,
//     String studentName,
//     String teacherName,
//   ) {
//     final timestamp = data['timestamp'] != null
//         ? (data['timestamp'] as Timestamp).toDate()
//         : null;

//     final date = timestamp != null
//         ? DateFormat('dd MMM yyyy').format(timestamp)
//         : 'N/A';

//     final time = timestamp != null
//         ? DateFormat('hh:mm a').format(timestamp)
//         : 'N/A';

//     return AttendanceRecord(
//       id: id,
//       studentId: data['studentId']?.toString() ?? '',
//       teacherId: data['teacherId']?.toString() ?? '',
//       studentName: studentName,
//       teacherName: teacherName,
//       subject: data['subject']?.toString() ?? 'Quran',
//       timestamp: timestamp,
//       date: date,
//       time: time,
//       status: data['status']?.toString() ?? 'present',
//       notes: data['notes']?.toString() ?? '',
//       sessionFee: (data['sessionFee'] ?? 0).toDouble(),
//       editedBy: data['editedBy']?.toString() ?? '',
//     );
//   }
// }

// class SessionReport {
//   final String id;
//   final String studentId;
//   final String teacherId;
//   final String studentName;
//   final String teacherName;
//   final String subject;
//   final DateTime? timestamp;
//   final String date;
//   final String time;
//   final String reportText;
//   final String reportStatus;
//   final int sessionsCompleted;
//   final int packageTotal;
//   final int sessionsRemaining;
//   final String topicCompleted;
//   final String homework;
//   final String teacherNotes;
//   final String reviewedBy;
//   final String editedBy;

//   SessionReport({
//     required this.id,
//     required this.studentId,
//     required this.teacherId,
//     required this.studentName,
//     required this.teacherName,
//     required this.subject,
//     required this.timestamp,
//     required this.date,
//     required this.time,
//     required this.reportText,
//     required this.reportStatus,
//     required this.sessionsCompleted,
//     required this.packageTotal,
//     required this.sessionsRemaining,
//     required this.topicCompleted,
//     required this.homework,
//     required this.teacherNotes,
//     required this.reviewedBy,
//     required this.editedBy,
//   });

//   factory SessionReport.fromFirestore(
//     Map<String, dynamic> data,
//     String id,
//     String studentName,
//     String teacherName,
//     String reportText,
//     String topicCompleted,
//     String homework,
//     int sessionNumber,
//     int totalSessions,
//     String teacherNotes,
//     String subject,
//   ) {
//     final timestamp = data['timestamp'] != null
//         ? (data['timestamp'] as Timestamp).toDate()
//         : null;

//     final date = timestamp != null
//         ? DateFormat('dd MMM yyyy').format(timestamp)
//         : 'N/A';

//     final time = timestamp != null
//         ? DateFormat('hh:mm a').format(timestamp)
//         : 'N/A';

//     final sessionsCompleted = sessionNumber;
//     final packageTotal = totalSessions;
//     final sessionsRemaining = packageTotal - sessionsCompleted;

//     return SessionReport(
//       id: id,
//       studentId: data['studentId']?.toString() ?? '',
//       teacherId: data['teacherId']?.toString() ?? '',
//       studentName: studentName,
//       teacherName: teacherName,
//       subject: subject,
//       timestamp: timestamp,
//       date: date,
//       time: time,
//       reportText: reportText,
//       reportStatus: data['reportStatus']?.toString() ?? 'Pending',
//       sessionsCompleted: sessionsCompleted,
//       packageTotal: packageTotal,
//       sessionsRemaining: sessionsRemaining,
//       topicCompleted: topicCompleted,
//       homework: homework,
//       teacherNotes: teacherNotes,
//       reviewedBy: data['reviewedBy']?.toString() ?? '',
//       editedBy: data['editedBy']?.toString() ?? '',
//     );
//   }
// }

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportsAttendanceScreen extends StatefulWidget {
  const ReportsAttendanceScreen({super.key});

  @override
  State<ReportsAttendanceScreen> createState() =>
      _ReportsAttendanceScreenState();
}

class _ReportsAttendanceScreenState extends State<ReportsAttendanceScreen> {
  int selectedTab = 0;
  String selectedStatusFilter = 'All';
  String selectedDateFilter = 'All Time';
  String searchQuery = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isExporting = false;
  ExportFormat _exportFormat = ExportFormat.csv;
  DateTimeRange? _exportDateRange;
  List<String> _exportStatusFilter = ['All'];

  bool get isWeb => kIsWeb;

  void _downloadFileWeb(String content, String fileName) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File ready: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _downloadFileWebAlternative(String content, String fileName) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ─── STATUS NORMALIZE ────────────────────────────────────────────────────────
  String _normalizeStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    switch (status.toLowerCase()) {
      case 'present':
      case 'attended':
        return 'Attended';
      case 'absent':
        return 'Absent without apology';
      case 'absent with apology':
      case 'absentwithapology':
        return 'Absent with apology';
      case 'absent without apology':
      case 'absentwithoutapology':
        return 'Absent without apology';
      default:
        return status;
    }
  }

  bool _isWithinDateRange(DateTime date) {
    final now = DateTime.now();
    switch (selectedDateFilter) {
      case 'Today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(weekStart.subtract(const Duration(days: 1)));
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  // ─── MAIN STREAM: ATTENDANCE WITH TEACHER & STUDENT DETAILS ─────────────────
  Stream<List<AttendanceRecord>> getAttendanceStream() {
    return _firestore
        .collection('attendance')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<AttendanceRecord> records = [];

          // Cache teacher & student data to avoid repeated fetches
          Map<String, Map<String, dynamic>> teacherCache = {};
          Map<String, Map<String, dynamic>> studentCache = {};

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;

              // ── STUDENT ──
              String studentId = data['studentId']?.toString() ?? '';
              String studentName =
                  data['studentName']?.toString() ?? 'Unknown Student';
              String packageType = '';
              int sessionsCompleted = 0;
              int sessionsLeft = 0;
              int sessionsRemaining = 0;

              if (studentId.isNotEmpty) {
                if (!studentCache.containsKey(studentId)) {
                  try {
                    final sDoc = await _firestore
                        .collection('students')
                        .doc(studentId)
                        .get();
                    studentCache[studentId] = sDoc.data() ?? {};
                  } catch (_) {
                    studentCache[studentId] = {};
                  }
                }
                final sData = studentCache[studentId]!;
                if (studentName == 'Unknown Student') {
                  studentName = sData['name']?.toString() ?? 'Unknown Student';
                }
                packageType = sData['packageType']?.toString() ?? '';
                sessionsCompleted = (sData['sessionsCompleted'] ?? 0) as int;
                sessionsLeft = (sData['sessionsLeft'] ?? 0) as int;
                sessionsRemaining = (sData['sessionsRemaining'] ?? 0) as int;
              }

              // ── TEACHER ──
              String teacherId = data['teacherId']?.toString() ?? '';
              String teacherName =
                  data['teacherName']?.toString() ?? 'Unknown Teacher';
              double walletBalance = 0;
              double totalEarnings = 0;
              double rate = 0;
              int teacherClassesCompleted = 0;

              if (teacherId.isNotEmpty) {
                if (!teacherCache.containsKey(teacherId)) {
                  try {
                    final tDoc = await _firestore
                        .collection('teachers')
                        .doc(teacherId)
                        .get();
                    teacherCache[teacherId] = tDoc.data() ?? {};
                  } catch (_) {
                    teacherCache[teacherId] = {};
                  }
                }
                final tData = teacherCache[teacherId]!;
                if (teacherName == 'Unknown Teacher') {
                  teacherName = tData['name']?.toString() ?? 'Unknown Teacher';
                }
                walletBalance = (tData['walletBalance'] ?? 0).toDouble();
                totalEarnings = (tData['totalEarnings'] ?? 0).toDouble();
                rate = (tData['rate'] ?? 0).toDouble();
                teacherClassesCompleted =
                    (tData['classesCompleted'] ?? 0) as int;
              }

              records.add(
                AttendanceRecord.fromFirestore(
                  data,
                  doc.id,
                  studentName,
                  teacherName,
                  packageType,
                  sessionsCompleted,
                  sessionsLeft,
                  sessionsRemaining,
                  walletBalance,
                  totalEarnings,
                  rate,
                  teacherClassesCompleted,
                ),
              );
            } catch (e) {
              debugPrint('Error processing record ${doc.id}: $e');
            }
          }
          return records;
        });
  }

  // ─── SESSION REPORTS STREAM ───────────────────────────────────────────────────
  Stream<List<SessionReport>> getSessionReportsStream() {
    return _firestore
        .collection('attendance')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<SessionReport> sessionReports = [];

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final reportMessage = data['reportMessage']?.toString();
              if (reportMessage == null || reportMessage.isEmpty) continue;

              String studentName =
                  data['studentName']?.toString() ?? 'Unknown Student';
              String studentId = data['studentId']?.toString() ?? '';
              if (studentName == 'Unknown Student' && studentId.isNotEmpty) {
                try {
                  final sDoc = await _firestore
                      .collection('students')
                      .doc(studentId)
                      .get();
                  studentName = sDoc.data()?['name'] ?? 'Unknown Student';
                } catch (_) {}
              }

              String teacherName =
                  data['teacherName']?.toString() ?? 'Unknown Teacher';
              String teacherId = data['teacherId']?.toString() ?? '';
              if (teacherName == 'Unknown Teacher' && teacherId.isNotEmpty) {
                try {
                  final tDoc = await _firestore
                      .collection('teachers')
                      .doc(teacherId)
                      .get();
                  teacherName = tDoc.data()?['name'] ?? 'Unknown Teacher';
                } catch (_) {}
              }

              sessionReports.add(
                SessionReport.fromFirestore(
                  data,
                  doc.id,
                  studentName,
                  teacherName,
                  reportMessage,
                  data['topicCompleted']?.toString() ?? 'No topic',
                  data['homeworkAssigned']?.toString() ?? 'No homework',
                  (data['sessionNumber'] ?? 1) as int,
                  (data['totalSessions'] ?? 20) as int,
                  data['teacherNotes']?.toString() ?? '',
                  _extractSubjectFromReport(reportMessage),
                ),
              );
            } catch (e) {
              debugPrint('Error processing report ${doc.id}: $e');
            }
          }
          return sessionReports;
        });
  }

  String _extractSubjectFromReport(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('surah') || lower.contains('ayat')) return 'Quran';
    if (lower.contains('hadith')) return 'Hadith';
    if (lower.contains('arabic')) return 'Arabic';
    if (lower.contains('fiqh')) return 'Fiqh';
    if (lower.contains('tajweed')) return 'Tajweed';
    return 'Quran';
  }

  // ─── EXPORT ───────────────────────────────────────────────────────────────────
  Future<List<AttendanceRecord>> getAllAttendanceForExport() async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .orderBy('timestamp', descending: true)
          .get();
      List<AttendanceRecord> records = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          String studentId = data['studentId']?.toString() ?? '';
          String studentName =
              data['studentName']?.toString() ?? 'Unknown Student';
          String packageType = '';
          int sessionsCompleted = 0, sessionsLeft = 0, sessionsRemaining = 0;
          if (studentId.isNotEmpty) {
            try {
              final sDoc = await _firestore
                  .collection('students')
                  .doc(studentId)
                  .get();
              final sData = sDoc.data() ?? {};
              if (studentName == 'Unknown Student')
                studentName = sData['name'] ?? 'Unknown Student';
              packageType = sData['packageType']?.toString() ?? '';
              sessionsCompleted = (sData['sessionsCompleted'] ?? 0) as int;
              sessionsLeft = (sData['sessionsLeft'] ?? 0) as int;
              sessionsRemaining = (sData['sessionsRemaining'] ?? 0) as int;
            } catch (_) {}
          }
          String teacherId = data['teacherId']?.toString() ?? '';
          String teacherName =
              data['teacherName']?.toString() ?? 'Unknown Teacher';
          double walletBalance = 0, totalEarnings = 0, rate = 0;
          int teacherClassesCompleted = 0;
          if (teacherId.isNotEmpty) {
            try {
              final tDoc = await _firestore
                  .collection('teachers')
                  .doc(teacherId)
                  .get();
              final tData = tDoc.data() ?? {};
              if (teacherName == 'Unknown Teacher')
                teacherName = tData['name'] ?? 'Unknown Teacher';
              walletBalance = (tData['walletBalance'] ?? 0).toDouble();
              totalEarnings = (tData['totalEarnings'] ?? 0).toDouble();
              rate = (tData['rate'] ?? 0).toDouble();
              teacherClassesCompleted = (tData['classesCompleted'] ?? 0) as int;
            } catch (_) {}
          }
          records.add(
            AttendanceRecord.fromFirestore(
              data,
              doc.id,
              studentName,
              teacherName,
              packageType,
              sessionsCompleted,
              sessionsLeft,
              sessionsRemaining,
              walletBalance,
              totalEarnings,
              rate,
              teacherClassesCompleted,
            ),
          );
        } catch (_) {}
      }
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<List<SessionReport>> getAllReportsForExport() async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('reportMessage', isNotEqualTo: '')
          .orderBy('timestamp', descending: true)
          .get();
      List<SessionReport> reports = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final reportMessage = data['reportMessage']?.toString();
          if (reportMessage == null || reportMessage.isEmpty) continue;
          String studentName =
              data['studentName']?.toString() ?? 'Unknown Student';
          String teacherName =
              data['teacherName']?.toString() ?? 'Unknown Teacher';
          reports.add(
            SessionReport.fromFirestore(
              data,
              doc.id,
              studentName,
              teacherName,
              reportMessage,
              data['topicCompleted']?.toString() ?? '',
              data['homeworkAssigned']?.toString() ?? '',
              (data['sessionNumber'] ?? 1) as int,
              (data['totalSessions'] ?? 20) as int,
              data['teacherNotes']?.toString() ?? '',
              _extractSubjectFromReport(reportMessage),
            ),
          );
        } catch (_) {}
      }
      return reports;
    } catch (_) {
      return [];
    }
  }

  Future<void> _exportAttendance() async {
    try {
      setState(() => _isExporting = true);
      final records = await getAllAttendanceForExport();
      if (records.isEmpty) {
        _showSnack('No attendance data to export', Colors.orange);
        setState(() => _isExporting = false);
        return;
      }
      List<AttendanceRecord> filtered = records.where((r) {
        if (_exportDateRange != null) {
          final d = r.timestamp ?? DateTime.now();
          if (!d.isAfter(_exportDateRange!.start) ||
              !d.isBefore(_exportDateRange!.end))
            return false;
        }
        if (!_exportStatusFilter.contains('All')) {
          if (!_exportStatusFilter.contains(_normalizeStatus(r.status)))
            return false;
        }
        return true;
      }).toList();
      if (filtered.isEmpty) {
        _showSnack('No data matches criteria', Colors.orange);
        setState(() => _isExporting = false);
        return;
      }
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String content = _exportFormat == ExportFormat.csv
          ? _convertToCSV(filtered)
          : _exportFormat == ExportFormat.excel
          ? _convertToExcel(filtered)
          : _convertToJSON(filtered);
      String fileName =
          'attendance_$stamp.${_exportFormat == ExportFormat.csv
              ? 'csv'
              : _exportFormat == ExportFormat.excel
              ? 'xlsx'
              : 'json'}';
      if (isWeb) {
        _downloadFileWeb(content, fileName);
      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnack('Storage permission required', Colors.red);
          setState(() => _isExporting = false);
          return;
        }
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(utf8.encode(content)),
        );
      }
      _showSnack('Exported ${filtered.length} records', Colors.green);
    } catch (e) {
      _showSnack('Export failed: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportReports() async {
    try {
      setState(() => _isExporting = true);
      final reports = await getAllReportsForExport();
      if (reports.isEmpty) {
        _showSnack('No reports to export', Colors.orange);
        setState(() => _isExporting = false);
        return;
      }
      List<SessionReport> filtered = reports.where((r) {
        if (_exportDateRange != null) {
          final d = r.timestamp ?? DateTime.now();
          if (!d.isAfter(_exportDateRange!.start) ||
              !d.isBefore(_exportDateRange!.end))
            return false;
        }
        return true;
      }).toList();
      if (filtered.isEmpty) {
        _showSnack('No data matches criteria', Colors.orange);
        setState(() => _isExporting = false);
        return;
      }
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String content = _exportFormat == ExportFormat.csv
          ? _convertReportsToCSV(filtered)
          : _exportFormat == ExportFormat.excel
          ? _convertReportsToExcel(filtered)
          : _convertReportsToJSON(filtered);
      String fileName =
          'session_reports_$stamp.${_exportFormat == ExportFormat.csv
              ? 'csv'
              : _exportFormat == ExportFormat.excel
              ? 'xlsx'
              : 'json'}';
      if (isWeb) {
        _downloadFileWeb(content, fileName);
      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnack('Storage permission required', Colors.red);
          setState(() => _isExporting = false);
          return;
        }
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(utf8.encode(content)),
        );
      }
      _showSnack('Exported ${filtered.length} reports', Colors.green);
    } catch (e) {
      _showSnack('Export failed: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _convertToCSV(List<AttendanceRecord> records) {
    final header =
        'Student Name,Teacher Name,Package,Session No,Sessions Completed,Sessions Left,Sessions Remaining,Date,Time,Status,Session Fee (USD),Teacher Wallet (USD),Teacher Total Earnings (USD),Teacher Rate (USD),Teacher Classes Done,Notes,Student ID,Teacher ID';
    final rows = records
        .map(
          (r) => [
            _escapeCSV(r.studentName),
            _escapeCSV(r.teacherName),
            _escapeCSV(r.packageType),
            r.sessionNumber.toString(),
            r.studentSessionsCompleted.toString(),
            r.sessionsLeft.toString(),
            r.sessionsRemaining.toString(),
            _escapeCSV(r.date),
            _escapeCSV(r.time),
            _escapeCSV(_normalizeStatus(r.status)),
            r.sessionFee.toStringAsFixed(2),
            r.teacherWalletBalance.toStringAsFixed(2),
            r.teacherTotalEarnings.toStringAsFixed(2),
            r.teacherRate.toStringAsFixed(2),
            r.teacherClassesCompleted.toString(),
            _escapeCSV(r.notes),
            _escapeCSV(r.studentId),
            _escapeCSV(r.teacherId),
          ].join(','),
        )
        .toList();
    return '$header\n${rows.join('\n')}';
  }

  String _convertReportsToCSV(List<SessionReport> reports) {
    final header =
        'Student Name,Teacher Name,Subject,Date,Time,Session Number,Total Sessions,Sessions Remaining,Topic Completed,Homework Assigned,Teacher Notes,Report Status,Student ID,Teacher ID';
    final rows = reports
        .map(
          (r) => [
            _escapeCSV(r.studentName),
            _escapeCSV(r.teacherName),
            _escapeCSV(r.subject),
            _escapeCSV(r.date),
            _escapeCSV(r.time),
            r.sessionsCompleted.toString(),
            r.packageTotal.toString(),
            r.sessionsRemaining.toString(),
            _escapeCSV(r.topicCompleted),
            _escapeCSV(r.homework),
            _escapeCSV(r.teacherNotes),
            _escapeCSV(r.reportStatus),
            _escapeCSV(r.studentId),
            _escapeCSV(r.teacherId),
          ].join(','),
        )
        .toList();
    return '$header\n${rows.join('\n')}';
  }

  String _convertToExcel(List<AttendanceRecord> records) {
    return '''<html><head><meta charset="UTF-8"><style>table{border-collapse:collapse;width:100%}th{background:#4F46E5;color:white;padding:10px}td{padding:8px;border:1px solid #ddd}tr:nth-child(even){background:#f2f2f2}</style></head><body>
<h2>Attendance Report - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</h2>
<table><tr><th>Student</th><th>Teacher</th><th>Package</th><th>Class No</th><th>Done</th><th>Left</th><th>Remaining</th><th>Date</th><th>Status</th><th>Fee (USD)</th><th>Teacher Wallet (USD)</th><th>Total Earnings (USD)</th></tr>
${records.map((r) => '<tr><td>${r.studentName}</td><td>${r.teacherName}</td><td>${r.packageType}</td><td>${r.sessionNumber}</td><td>${r.studentSessionsCompleted}</td><td>${r.sessionsLeft}</td><td>${r.sessionsRemaining}</td><td>${r.date}</td><td>${_normalizeStatus(r.status)}</td><td>\$${r.sessionFee.toStringAsFixed(2)}</td><td>\$${r.teacherWalletBalance.toStringAsFixed(2)}</td><td>\$${r.teacherTotalEarnings.toStringAsFixed(2)}</td></tr>').join('')}
</table></body></html>''';
  }

  String _convertReportsToExcel(List<SessionReport> reports) {
    return '''<html><head><meta charset="UTF-8"><style>table{border-collapse:collapse;width:100%}th{background:#10B981;color:white;padding:10px}td{padding:8px;border:1px solid #ddd}tr:nth-child(even){background:#f2f2f2}</style></head><body>
<h2>Session Reports - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</h2>
<table><tr><th>Student</th><th>Teacher</th><th>Subject</th><th>Date</th><th>Session</th><th>Topic</th><th>Homework</th><th>Status</th></tr>
${reports.map((r) => '<tr><td>${r.studentName}</td><td>${r.teacherName}</td><td>${r.subject}</td><td>${r.date}</td><td>${r.sessionsCompleted}/${r.packageTotal}</td><td>${r.topicCompleted}</td><td>${r.homework}</td><td>${r.reportStatus}</td></tr>').join('')}
</table></body></html>''';
  }

  String _convertToJSON(List<AttendanceRecord> records) {
    return jsonEncode({
      'exportType': 'attendance',
      'exportDate': DateTime.now().toIso8601String(),
      'recordCount': records.length,
      'data': records
          .map(
            (r) => {
              'studentName': r.studentName,
              'teacherName': r.teacherName,
              'packageType': r.packageType,
              'classNumber': r.sessionNumber,
              'sessionsCompleted': r.studentSessionsCompleted,
              'sessionsLeft': r.sessionsLeft,
              'sessionsRemaining': r.sessionsRemaining,
              'date': r.date,
              'time': r.time,
              'status': _normalizeStatus(r.status),
              'sessionFeeUSD': r.sessionFee,
              'teacherWalletUSD': r.teacherWalletBalance,
              'teacherTotalEarningsUSD': r.teacherTotalEarnings,
              'teacherRateUSD': r.teacherRate,
              'teacherClassesCompleted': r.teacherClassesCompleted,
            },
          )
          .toList(),
    });
  }

  String _convertReportsToJSON(List<SessionReport> reports) {
    return jsonEncode({
      'exportType': 'session_reports',
      'exportDate': DateTime.now().toIso8601String(),
      'recordCount': reports.length,
      'data': reports
          .map(
            (r) => {
              'studentName': r.studentName,
              'teacherName': r.teacherName,
              'subject': r.subject,
              'date': r.date,
              'sessionNumber': r.sessionsCompleted,
              'totalSessions': r.packageTotal,
              'sessionsRemaining': r.sessionsRemaining,
              'topicCompleted': r.topicCompleted,
              'homework': r.homework,
              'teacherNotes': r.teacherNotes,
              'reportStatus': r.reportStatus,
            },
          )
          .toList(),
    });
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: selectedTab == 0
                  ? _buildAttendanceLog()
                  : _buildSessionReports(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports & Attendance',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Track attendance, income & session progress',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _showExportDialog,
              icon: const Icon(Icons.download, size: 16, color: Colors.blue),
              label: const Text(
                'Export',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Today: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              0,
              'Attendance Log',
              Icons.fact_check_outlined,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              1,
              'Session Reports',
              Icons.description_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = selectedTab == index;
    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ATTENDANCE LOG ───────────────────────────────────────────────────────────
  Widget _buildAttendanceLog() {
    return Column(
      children: [
        _buildAttendanceFilters(),
        const SizedBox(height: 12),
        // Stats cards
        SizedBox(
          height: 100,
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: getAttendanceStream(),
            builder: (context, snapshot) {
              final records = _filterAttendanceRecords(snapshot.data ?? []);
              final total = records.length;
              final attended = records
                  .where((r) => _normalizeStatus(r.status) == 'Attended')
                  .length;
              final withApology = records
                  .where(
                    (r) => _normalizeStatus(r.status) == 'Absent with apology',
                  )
                  .length;
              final withoutApology = records
                  .where(
                    (r) =>
                        _normalizeStatus(r.status) == 'Absent without apology',
                  )
                  .length;
              return _buildStatCards(
                total,
                attended,
                withApology,
                withoutApology,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildAttendanceTable()),
      ],
    );
  }

  Widget _buildAttendanceFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by student, teacher, or package...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown(
              'Status',
              selectedStatusFilter,
              [
                'All',
                'Attended',
                'Absent with apology',
                'Absent without apology',
              ],
              (v) => setState(() => selectedStatusFilter = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown(
              'Date Range',
              selectedDateFilter,
              ['All Time', 'Today', 'This Week', 'This Month'],
              (v) => setState(() => selectedDateFilter = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        dropdownColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildStatCards(
    int total,
    int attended,
    int withApology,
    int withoutApology,
  ) {
    return Row(
      children: [
        _buildStatCard('Total', '$total', Icons.event_available, Colors.blue),
        const SizedBox(width: 8),
        _buildStatCard(
          'Attended',
          '$attended',
          Icons.check_circle,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'With Apology',
          '$withApology',
          Icons.event_busy,
          const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'No Apology',
          '$withoutApology',
          Icons.cancel,
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ATTENDANCE TABLE ─────────────────────────────────────────────────────────
  Widget _buildAttendanceTable() {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: getAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }

        final records = _filterAttendanceRecords(snapshot.data ?? []);

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _tableHeader('Student')),
                    Expanded(flex: 2, child: _tableHeader('Teacher')),
                    // ── NEW: Package & Session Info ──
                    Expanded(
                      flex: 2,
                      child: _tableHeader('Package & Progress'),
                    ),
                    Expanded(flex: 2, child: _tableHeader('Teacher Income')),
                    Expanded(flex: 1, child: _tableHeader('Date')),
                    Expanded(flex: 1, child: _tableHeader('Status')),
                    Expanded(flex: 1, child: _tableHeader('Actions')),
                  ],
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No attendance records found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: _buildAttendanceRow(records[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildAttendanceRow(AttendanceRecord r) {
    final displayStatus = _normalizeStatus(r.status);
    Color statusColor;
    IconData statusIcon;
    switch (displayStatus) {
      case 'Attended':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'Absent with apology':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.event_busy;
        break;
      case 'Absent without apology':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    // Package progress percent
    final totalSessions = (r.studentSessionsCompleted + r.sessionsRemaining);
    final progress = totalSessions > 0
        ? r.studentSessionsCompleted / totalSessions
        : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Student ──
        Expanded(
          flex: 2,
          child: Text(
            r.studentName,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // ── Teacher ──
        Expanded(
          flex: 2,
          child: Text(
            r.teacherName,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // ── Package & Session Progress ──
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Package name (packageType)
              if (r.packageType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.packageType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 4),
              // Class number info
              Text(
                'Class ${r.sessionNumber} | Done: ${r.studentSessionsCompleted} | Left: ${r.sessionsRemaining}',
                style: const TextStyle(fontSize: 9, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        // ── Teacher Income ──
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 11,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Wallet: \$${r.teacherWalletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 11, color: Colors.blue),
                  const SizedBox(width: 3),
                  Text(
                    'Total: \$${r.teacherTotalEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 11, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(
                    'Rate: \$${r.teacherRate.toStringAsFixed(0)}/class | ${r.teacherClassesCompleted} done',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── Date ──
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(r.date, style: const TextStyle(fontSize: 10)),
              Text(
                r.time,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
        ),
        // ── Status Badge ──
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    _shortStatus(displayStatus),
                    style: TextStyle(
                      fontSize: 9,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Actions ──
        Expanded(
          flex: 1,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 15),
                onPressed: () => _showAttendanceDetails(r),
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 15),
                onPressed: () => _showEditAttendanceDialog(r),
                color: Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _shortStatus(String status) {
    switch (status) {
      case 'Attended':
        return 'Attended';
      case 'Absent with apology':
        return 'W/ Apology';
      case 'Absent without apology':
        return 'No Apology';
      default:
        return status.length > 10 ? '${status.substring(0, 10)}...' : status;
    }
  }

  List<AttendanceRecord> _filterAttendanceRecords(
    List<AttendanceRecord> records,
  ) {
    return records.where((r) {
      final matchSearch =
          searchQuery.isEmpty ||
          r.studentName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          r.teacherName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          r.packageType.toLowerCase().contains(searchQuery.toLowerCase());
      final matchStatus =
          selectedStatusFilter == 'All' ||
          _normalizeStatus(r.status) == selectedStatusFilter;
      final matchDate = _isWithinDateRange(r.timestamp ?? DateTime.now());
      return matchSearch && matchStatus && matchDate;
    }).toList();
  }

  // ─── SESSION REPORTS ──────────────────────────────────────────────────────────
  Widget _buildSessionReports() {
    return Column(
      children: [
        _buildReportsFilters(),
        const SizedBox(height: 12),
        Expanded(child: _buildReportsList()),
      ],
    );
  }

  Widget _buildReportsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search reports by student, teacher or topic...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown(
              'Date Range',
              selectedDateFilter,
              ['All Time', 'Today', 'This Week', 'This Month'],
              (v) => setState(() => selectedDateFilter = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return StreamBuilder<List<SessionReport>>(
      stream: getSessionReportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }
        final reports = _filterSessionReports(snapshot.data ?? []);
        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No session reports found',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) => _buildReportCard(reports[index]),
        );
      },
    );
  }

  List<SessionReport> _filterSessionReports(List<SessionReport> reports) {
    return reports.where((r) {
      final matchSearch =
          searchQuery.isEmpty ||
          r.studentName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          r.teacherName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          r.topicCompleted.toLowerCase().contains(searchQuery.toLowerCase());
      final matchDate = _isWithinDateRange(r.timestamp ?? DateTime.now());
      return matchSearch && matchDate;
    }).toList();
  }

  Widget _buildReportCard(SessionReport report) {
    final progress = report.packageTotal > 0
        ? report.sessionsCompleted / report.packageTotal
        : 0.0;
    Color statusColor;
    IconData statusIcon;
    String statusText;
    if (report.editedBy.isNotEmpty) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.edit;
      statusText = 'Edited';
    } else if (report.reviewedBy.isNotEmpty) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
      statusText = 'Reviewed';
    } else {
      statusColor = const Color(0xFF6B7280);
      statusIcon = Icons.pending;
      statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.studentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.teacherName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.book_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.subject,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(report.date, style: const TextStyle(fontSize: 11)),
                  Text(
                    report.time,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Topic & homework
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bookmark_outline,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Topic: ${report.topicCompleted}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 12,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'HW: ${report.homework}',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.reportText,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Package Progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Session ${report.sessionsCompleted} of ${report.packageTotal}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${report.sessionsRemaining}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Remaining',
                      style: TextStyle(color: Colors.blue, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report.teacherNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.note_outlined,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Teacher Notes:',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.teacherNotes,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Session #${report.sessionsCompleted}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditReportDialog(report),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () => _showReportDetails(report),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────────
  void _showAttendanceDetails(AttendanceRecord r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Attendance Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student info
                _sectionTitle('Student Information'),
                _detailRow('Name:', r.studentName),
                _detailRow(
                  'Package:',
                  r.packageType.isEmpty ? 'N/A' : r.packageType.toUpperCase(),
                ),
                _detailRow('Class Number:', '#${r.sessionNumber}'),
                _detailRow('Sessions Done:', '${r.studentSessionsCompleted}'),
                _detailRow('Sessions Left:', '${r.sessionsLeft}'),
                _detailRow('Sessions Remaining:', '${r.sessionsRemaining}'),
                const Divider(height: 24),
                // Teacher info
                _sectionTitle('Teacher Information'),
                _detailRow('Name:', r.teacherName),
                _detailRow(
                  'Rate per Class:',
                  '\$${r.teacherRate.toStringAsFixed(0)} USD',
                ),
                _detailRow(
                  'Classes Completed:',
                  '${r.teacherClassesCompleted}',
                ),
                _detailRow(
                  'Total Earnings:',
                  '\$${r.teacherTotalEarnings.toStringAsFixed(2)} USD',
                ),
                _detailRow(
                  'Wallet Balance:',
                  '\$${r.teacherWalletBalance.toStringAsFixed(2)} USD',
                ),
                const Divider(height: 24),
                // Class info
                _sectionTitle('Class Information'),
                _detailRow('Date:', r.date),
                _detailRow('Time:', r.time),
                _detailRow('Status:', _normalizeStatus(r.status)),
                _detailRow(
                  'Session Fee:',
                  '\$${r.sessionFee.toStringAsFixed(2)} USD',
                ),
                if (r.editedBy.isNotEmpty) _detailRow('Edited By:', r.editedBy),
                const SizedBox(height: 12),
                if (r.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(r.notes, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditAttendanceDialog(r);
            },
            child: const Text('Edit Status'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _showEditAttendanceDialog(AttendanceRecord r) {
    String selectedStatus = _normalizeStatus(r.status);
    final notesController = TextEditingController(text: r.notes);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Edit Attendance Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Student:', r.studentName),
              _detailRow('Teacher:', r.teacherName),
              _detailRow('Date:', '${r.date} ${r.time}'),
              _detailRow(
                'Package:',
                r.packageType.isEmpty ? 'N/A' : r.packageType,
              ),
              _detailRow('Session #:', '${r.sessionNumber}'),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: [
                        DropdownMenuItem(
                          value: 'Attended',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text('Attended'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Absent with apology',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_busy,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text('Absent with apology'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Absent without apology',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cancel,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text('Absent without apology'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) => selectedStatus = v!,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changing status will recalculate teacher wallet balance',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Notes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Reason for correction...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateAttendanceStatus(
                r.id,
                selectedStatus,
                notesController.text,
                r.studentId,
                r.teacherId,
                r.sessionFee,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showEditReportDialog(SessionReport report) {
    final reportCtrl = TextEditingController(text: report.reportText);
    final topicCtrl = TextEditingController(text: report.topicCompleted);
    final homeworkCtrl = TextEditingController(text: report.homework);
    final notesCtrl = TextEditingController(text: report.teacherNotes);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Edit Session Report',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Student:', report.studentName),
                _detailRow('Teacher:', report.teacherName),
                _detailRow(
                  'Session:',
                  '${report.sessionsCompleted}/${report.packageTotal}',
                ),
                const SizedBox(height: 12),
                _editField('Topic Completed', topicCtrl, 'Enter topic...'),
                const SizedBox(height: 12),
                _editField(
                  'Homework Assigned',
                  homeworkCtrl,
                  'Enter homework...',
                ),
                const SizedBox(height: 12),
                _editField(
                  'Teacher Notes',
                  notesCtrl,
                  'Enter notes...',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _editField(
                  'Session Report',
                  reportCtrl,
                  'Enter report...',
                  maxLines: 6,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateSessionReport(
                report.id,
                reportCtrl.text,
                notesCtrl.text,
                topicCtrl.text,
                homeworkCtrl.text,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save Report'),
          ),
        ],
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  void _showReportDetails(SessionReport report) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Session Report Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Student:', report.studentName),
                _detailRow('Teacher:', report.teacherName),
                _detailRow('Subject:', report.subject),
                _detailRow('Date:', report.date),
                _detailRow('Time:', report.time),
                _detailRow('Session Number:', '${report.sessionsCompleted}'),
                _detailRow('Total Sessions:', '${report.packageTotal}'),
                _detailRow(
                  'Sessions Remaining:',
                  '${report.sessionsRemaining}',
                ),
                _detailRow('Topic Completed:', report.topicCompleted),
                _detailRow('Homework Assigned:', report.homework),
                if (report.teacherNotes.isNotEmpty)
                  _detailRow('Teacher Notes:', report.teacherNotes),
                if (report.reviewedBy.isNotEmpty)
                  _detailRow('Reviewed By:', report.reviewedBy),
                if (report.editedBy.isNotEmpty)
                  _detailRow('Last Edited By:', report.editedBy),
                const SizedBox(height: 12),
                const Text(
                  'Full Report:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    report.reportText,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── FIRESTORE UPDATES ────────────────────────────────────────────────────────
  Future<void> _updateAttendanceStatus(
    String attendanceId,
    String status,
    String notes,
    String studentId,
    String teacherId,
    double sessionFee,
  ) async {
    try {
      final adminEmail = _auth.currentUser?.email ?? 'Admin';
      final isAttended = status == 'Attended';

      await _firestore.collection('attendance').doc(attendanceId).update({
        'status': isAttended ? 'present' : 'absent',
        'notes': notes,
        'editedBy': adminEmail,
        'editedAt': FieldValue.serverTimestamp(),
        'lastEditReason': 'Admin correction',
      });

      if (sessionFee > 0) {
        final double increment = isAttended ? sessionFee : -sessionFee;
        await _firestore.collection('teachers').doc(teacherId).update({
          'walletBalance': FieldValue.increment(increment),
        });
        await _firestore.collection('wallet_transactions').add({
          'teacherId': teacherId,
          'type': isAttended ? 'earning' : 'deduction',
          'amount': sessionFee,
          'reason': isAttended
              ? 'Class attended - Admin corrected'
              : 'Attendance corrected to $status',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _showSnack('Attendance updated & wallet recalculated', Colors.green);
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    }
  }

  Future<void> _updateSessionReport(
    String reportId,
    String reportText,
    String teacherNotes,
    String topicCompleted,
    String homeworkAssigned,
  ) async {
    try {
      final adminEmail = _auth.currentUser?.email ?? 'Admin';
      await _firestore.collection('attendance').doc(reportId).update({
        'reportMessage': reportText,
        'teacherNotes': teacherNotes,
        'topicCompleted': topicCompleted,
        'homeworkAssigned': homeworkAssigned,
        'editedBy': adminEmail,
        'editedAt': FieldValue.serverTimestamp(),
        'reportStatus': 'Edited',
      });
      _showSnack('Report updated successfully', Colors.green);
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    }
  }

  // ─── EXPORT DIALOG ────────────────────────────────────────────────────────────
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.download_outlined, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Export Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Format',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      _formatOption('CSV', ExportFormat.csv, setState),
                      _formatOption('Excel', ExportFormat.excel, setState),
                      _formatOption('JSON', ExportFormat.pdf, setState),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Date Range (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now(),
                              initialDateRange: _exportDateRange,
                            );
                            if (picked != null)
                              setState(() => _exportDateRange = picked);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _exportDateRange != null
                                ? '${DateFormat('dd/MM/yy').format(_exportDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_exportDateRange!.end)}'
                                : 'Select Date Range',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (_exportDateRange != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _exportDateRange = null),
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isExporting
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      if (selectedTab == 0)
                        await _exportAttendance();
                      else
                        await _exportReports();
                    },
              icon: _isExporting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_isExporting ? 'Exporting...' : 'Export'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatOption(
    String title,
    ExportFormat format,
    void Function(void Function()) setState,
  ) {
    return ChoiceChip(
      label: Text(title),
      selected: _exportFormat == format,
      onSelected: (_) => setState(() => _exportFormat = format),
      selectedColor: Colors.blue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _exportFormat == format ? Colors.blue : Colors.black,
      ),
    );
  }
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class AttendanceRecord {
  final String id;
  final String studentId;
  final String teacherId;
  final String studentName;
  final String teacherName;
  final String subject;
  final DateTime? timestamp;
  final String date;
  final String time;
  final String status;
  final String notes;
  final double sessionFee;
  final String editedBy;

  // ── NEW: Student package fields ──
  final String packageType;
  final int studentSessionsCompleted;
  final int sessionsLeft;
  final int sessionsRemaining;
  final int sessionNumber; // current class number (sessionsCompleted + 1)

  // ── NEW: Teacher income fields ──
  final double teacherWalletBalance;
  final double teacherTotalEarnings;
  final double teacherRate;
  final int teacherClassesCompleted;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.studentName,
    required this.teacherName,
    required this.subject,
    required this.timestamp,
    required this.date,
    required this.time,
    required this.status,
    required this.notes,
    required this.sessionFee,
    required this.editedBy,
    required this.packageType,
    required this.studentSessionsCompleted,
    required this.sessionsLeft,
    required this.sessionsRemaining,
    required this.sessionNumber,
    required this.teacherWalletBalance,
    required this.teacherTotalEarnings,
    required this.teacherRate,
    required this.teacherClassesCompleted,
  });

  factory AttendanceRecord.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String studentName,
    String teacherName,
    String packageType,
    int studentSessionsCompleted,
    int sessionsLeft,
    int sessionsRemaining,
    double teacherWalletBalance,
    double teacherTotalEarnings,
    double teacherRate,
    int teacherClassesCompleted,
  ) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : null;
    final date = timestamp != null
        ? DateFormat('dd MMM yyyy').format(timestamp)
        : 'N/A';
    final time = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp)
        : 'N/A';

    return AttendanceRecord(
      id: id,
      studentId: data['studentId']?.toString() ?? '',
      teacherId: data['teacherId']?.toString() ?? '',
      studentName: studentName,
      teacherName: teacherName,
      subject: data['subject']?.toString() ?? 'Quran',
      timestamp: timestamp,
      date: date,
      time: time,
      status: data['status']?.toString() ?? 'present',
      notes: data['notes']?.toString() ?? '',
      sessionFee: (data['sessionFee'] ?? 0).toDouble(),
      editedBy: data['editedBy']?.toString() ?? '',
      packageType: packageType,
      studentSessionsCompleted: studentSessionsCompleted,
      sessionsLeft: sessionsLeft,
      sessionsRemaining: sessionsRemaining,
      sessionNumber: studentSessionsCompleted > 0
          ? studentSessionsCompleted
          : 1,
      teacherWalletBalance: teacherWalletBalance,
      teacherTotalEarnings: teacherTotalEarnings,
      teacherRate: teacherRate,
      teacherClassesCompleted: teacherClassesCompleted,
    );
  }
}

class SessionReport {
  final String id;
  final String studentId;
  final String teacherId;
  final String studentName;
  final String teacherName;
  final String subject;
  final DateTime? timestamp;
  final String date;
  final String time;
  final String reportText;
  final String reportStatus;
  final int sessionsCompleted;
  final int packageTotal;
  final int sessionsRemaining;
  final String topicCompleted;
  final String homework;
  final String teacherNotes;
  final String reviewedBy;
  final String editedBy;

  SessionReport({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.studentName,
    required this.teacherName,
    required this.subject,
    required this.timestamp,
    required this.date,
    required this.time,
    required this.reportText,
    required this.reportStatus,
    required this.sessionsCompleted,
    required this.packageTotal,
    required this.sessionsRemaining,
    required this.topicCompleted,
    required this.homework,
    required this.teacherNotes,
    required this.reviewedBy,
    required this.editedBy,
  });

  factory SessionReport.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String studentName,
    String teacherName,
    String reportText,
    String topicCompleted,
    String homework,
    int sessionNumber,
    int totalSessions,
    String teacherNotes,
    String subject,
  ) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : null;
    final date = timestamp != null
        ? DateFormat('dd MMM yyyy').format(timestamp)
        : 'N/A';
    final time = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp)
        : 'N/A';

    return SessionReport(
      id: id,
      studentId: data['studentId']?.toString() ?? '',
      teacherId: data['teacherId']?.toString() ?? '',
      studentName: studentName,
      teacherName: teacherName,
      subject: subject,
      timestamp: timestamp,
      date: date,
      time: time,
      reportText: reportText,
      reportStatus: data['reportStatus']?.toString() ?? 'Pending',
      sessionsCompleted: sessionNumber,
      packageTotal: totalSessions,
      sessionsRemaining: totalSessions - sessionNumber,
      topicCompleted: topicCompleted,
      homework: homework,
      teacherNotes: teacherNotes,
      reviewedBy: data['reviewedBy']?.toString() ?? '',
      editedBy: data['editedBy']?.toString() ?? '',
    );
  }
}

enum ExportFormat { csv, excel, pdf }
