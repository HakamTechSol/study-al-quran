// import 'package:flutter/material.dart';
// import 'package:studyalquran/utils/app_text_styles.dart';
// import 'package:studyalquran/utils/color_constants.dart';
// // import 'package:edulink/utils/color_constants.dart';
// // import 'package:edulink/utils/text_styles.dart';

// class ChatScreen extends StatefulWidget {
//   final String studentName;
//   final String studentId;

//   const ChatScreen({
//     super.key,
//     required this.studentName,
//     required this.studentId,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isSending = false;

//   // Dummy messages - Replace with Firebase Firestore
//   final List<ChatMessage> _messages = [
//     ChatMessage(
//       id: '1',
//       text: 'Hello! Ready for today\'s session?',
//       isTeacher: true,
//       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//       messageType: MessageType.text,
//     ),
//     ChatMessage(
//       id: '2',
//       text: 'Yes sir! I\'m ready.',
//       isTeacher: false,
//       timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
//       messageType: MessageType.text,
//     ),
//     ChatMessage(
//       id: '3',
//       text: '🔔 Your session starts now!\n\nZoom Link: https://zoom.us/j/123456789\nMeeting ID: 123 456 789\nPassword: abc123',
//       isTeacher: true,
//       timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
//       messageType: MessageType.system,
//     ),
//     ChatMessage(
//       id: '4',
//       text: 'Great session today! Any questions?',
//       isTeacher: true,
//       timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
//       messageType: MessageType.text,
//     ),
//     ChatMessage(
//       id: '5',
//       text: '📋 Session Report:\n\n✅ Unit 3 - Complete\n✅ Practice exercises done\n📚 Homework: Pages 45-50\n⏳ Sessions remaining: 4\n\nKeep up the good work!',
//       isTeacher: true,
//       timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
//       messageType: MessageType.report,
//     ),
//     ChatMessage(
//       id: '6',
//       text: 'Thank you sir! I will complete the homework.',
//       isTeacher: false,
//       timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
//       messageType: MessageType.text,
//     ),
//   ];

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     setState(() => _isSending = true);

//     final newMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       text: _messageController.text.trim(),
//       isTeacher: true,
//       timestamp: DateTime.now(),
//       messageType: MessageType.text,
//     );

//     // Simulate sending to Firebase
//     await Future.delayed(const Duration(milliseconds: 500));

//     setState(() {
//       _messages.add(newMessage);
//       _messageController.clear();
//       _isSending = false;
//     });

//     // Scroll to bottom
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     });
//   }

//   void _sendReport() {
//     showDialog(
//       context: context,
//       builder: (context) => ReportDialog(
//         onSend: (report) {
//           setState(() {
//             _messages.add(ChatMessage(
//               id: DateTime.now().millisecondsSinceEpoch.toString(),
//               text: report,
//               isTeacher: true,
//               timestamp: DateTime.now(),
//               messageType: MessageType.report,
//             ));
//           });
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final scaleFactor = screenHeight < 600 ? 0.9 : 1.0;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         elevation: 2,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppColors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundColor: AppColors.white,
//               radius: 18,
//               child: Text(
//                 _getInitials(widget.studentName),
//                 style: AppTextStyles.bodySmall.copyWith(
//                   color: AppColors.primary,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.studentName,
//                     style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
//                   ),
//                   Text(
//                     'Online',
//                     style: AppTextStyles.captionText.copyWith(
//                       color: AppColors.white.withOpacity(0.8),
//                       fontSize: 11,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.videocam, color: AppColors.white),
//             onPressed: () {
//               // Start video call
//             },
//           ),
//           PopupMenuButton(
//             icon: Icon(Icons.more_vert, color: AppColors.white),
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 child: Text('View Profile', style: AppTextStyles.bodySmall),
//                 onTap: () {},
//               ),
//               PopupMenuItem(
//                 child: Text('Clear Chat', style: AppTextStyles.bodySmall),
//                 onTap: () {},
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: Transform.scale(
//         scale: scaleFactor,
//         child: Column(
//           children: [
//             // Messages List
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.isDarkMode
//                       ? AppColors.darkBackground
//                       : const Color(0xFFF5F5F5),
//                 ),
//                 child: ListView.builder(
//                   controller: _scrollController,
//                   padding: const EdgeInsets.all(12),
//                   itemCount: _messages.length,
//                   itemBuilder: (context, index) {
//                     return _buildMessageBubble(_messages[index]);
//                   },
//                 ),
//               ),
//             ),

//             // Input Area
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//               decoration: BoxDecoration(
//                 color: AppColors.card,
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.grey.withOpacity(0.1),
//                     blurRadius: 5,
//                     offset: const Offset(0, -2),
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 child: Row(
//                   children: [
//                     // Report Button
//                     IconButton(
//                       icon: Icon(Icons.assignment, color: AppColors.primary),
//                       onPressed: _sendReport,
//                       tooltip: 'Send Report',
//                     ),

//                     // Text Input
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         decoration: BoxDecoration(
//                           color: AppColors.background,
//                           borderRadius: BorderRadius.circular(24),
//                           border: Border.all(color: AppColors.border),
//                         ),
//                         child: TextField(
//                           controller: _messageController,
//                           style: AppTextStyles.inputValue.copyWith(fontSize: 14),
//                           maxLines: null,
//                           textInputAction: TextInputAction.newline,
//                           decoration: InputDecoration(
//                             hintText: 'Type a message...',
//                             hintStyle: AppTextStyles.inputHint.copyWith(fontSize: 13),
//                             border: InputBorder.none,
//                             contentPadding: const EdgeInsets.symmetric(vertical: 10),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(width: 6),

//                     // Send Button
//                     Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [AppColors.primary, AppColors.gradient],
//                         ),
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.primary.withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: IconButton(
//                         icon: _isSending
//                             ? SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   color: AppColors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : Icon(Icons.send, color: AppColors.white, size: 22),
//                         onPressed: _isSending ? null : _sendMessage,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageBubble(ChatMessage message) {
//     // System Message (Yellow Box)
//     if (message.messageType == MessageType.system) {
//       return Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFF9C4),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFFFEB3B), width: 1.5),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(Icons.info_outline, color: Colors.orange.shade800, size: 22),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message.text,
//                 style: AppTextStyles.bodySmall.copyWith(
//                   color: Colors.orange.shade900,
//                   fontSize: 13,
//                   height: 1.4,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // Report Message (Green Box)
//     if (message.messageType == MessageType.report) {
//       return Align(
//         alignment: message.isTeacher ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//           padding: const EdgeInsets.all(14),
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.8,
//           ),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 AppColors.primary.withOpacity(0.1),
//                 AppColors.gradient.withOpacity(0.1),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.assignment_turned_in,
//                       color: AppColors.primary, size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Session Report',
//                     style: AppTextStyles.heading4.copyWith(
//                       color: AppColors.primary,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 message.text,
//                 style: AppTextStyles.bodySmall.copyWith(
//                   color: AppColors.text,
//                   fontSize: 13,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 _formatTime(message.timestamp),
//                 style: AppTextStyles.captionText.copyWith(
//                   color: AppColors.subtitle,
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     // Regular Text Messages
//     final isTeacher = message.isTeacher;
//     return Align(
//       alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.75,
//         ),
//         decoration: BoxDecoration(
//           color: isTeacher
//               ? AppColors.primary.withOpacity(0.15)
//               : AppColors.isDarkMode
//                   ? AppColors.darkCard
//                   : AppColors.grey.withOpacity(0.15),
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: Radius.circular(isTeacher ? 16 : 4),
//             bottomRight: Radius.circular(isTeacher ? 4 : 16),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               message.text,
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: AppColors.text,
//                 fontSize: 14,
//                 height: 1.4,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               _formatTime(message.timestamp),
//               style: AppTextStyles.captionText.copyWith(
//                 color: AppColors.subtitle,
//                 fontSize: 10,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getInitials(String name) {
//     List<String> names = name.split(' ');
//     if (names.length >= 2) {
//       return '${names[0][0]}${names[1][0]}'.toUpperCase();
//     }
//     return name.substring(0, 2).toUpperCase();
//   }

//   String _formatTime(DateTime timestamp) {
//     final now = DateTime.now();
//     final diff = now.difference(timestamp);

//     if (diff.inDays > 0) {
//       return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
//     } else if (diff.inHours > 0) {
//       return '${diff.inHours}h ago';
//     } else if (diff.inMinutes > 0) {
//       return '${diff.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }

// // Chat Message Model
// class ChatMessage {
//   final String id;
//   final String text;
//   final bool isTeacher;
//   final DateTime timestamp;
//   final MessageType messageType;

//   ChatMessage({
//     required this.id,
//     required this.text,
//     required this.isTeacher,
//     required this.timestamp,
//     required this.messageType,
//   });
// }

// enum MessageType { text, system, report }

// // Report Dialog
// class ReportDialog extends StatefulWidget {
//   final Function(String) onSend;

//   const ReportDialog({super.key, required this.onSend});

//   @override
//   State<ReportDialog> createState() => _ReportDialogState();
// }

// class _ReportDialogState extends State<ReportDialog> {
//   final _unitController = TextEditingController();
//   final _homeworkController = TextEditingController();
//   final _sessionsLeftController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       backgroundColor: AppColors.card,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Row(
//         children: [
//           Icon(Icons.assignment, color: AppColors.primary, size: 28),
//           const SizedBox(width: 10),
//           Text('Send Report', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildTextField(
//               controller: _unitController,
//               label: 'Unit Completed',
//               hint: 'e.g., Unit 3',
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _homeworkController,
//               label: 'Homework',
//               hint: 'e.g., Pages 45-50',
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _sessionsLeftController,
//               label: 'Sessions Left',
//               hint: 'e.g., 4',
//               keyboardType: TextInputType.number,
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text('Cancel', style: AppTextStyles.buttonSecondary),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             final report = '''📋 Session Report:

// ✅ ${_unitController.text} - Complete
// ✅ Practice exercises done
// 📚 Homework: ${_homeworkController.text}
// ⏳ Sessions remaining: ${_sessionsLeftController.text}

// Keep up the good work!''';

//             widget.onSend(report);
//             Navigator.pop(context);
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: Text('Send Report', style: AppTextStyles.buttonPrimary.copyWith(fontSize: 14)),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     TextInputType? keyboardType,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: AppTextStyles.labelText.copyWith(fontSize: 13)),
//         const SizedBox(height: 6),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           style: AppTextStyles.inputValue.copyWith(fontSize: 14),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: AppTextStyles.inputHint.copyWith(fontSize: 13),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: AppColors.border),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: AppColors.primary, width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           ),
//         ),
//       ],
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:studyalquran/utils/app_text_styles.dart';

class TeacherChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String currentUserId;
  final String currentUserRole;

  const TeacherChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<TeacherChatDetailScreen> createState() => _TeacherChatDetailScreenState();
}

class _TeacherChatDetailScreenState extends State<TeacherChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isSending = false;
  late String chatId;

  // VIP Teacher Theme - Light Cream/Yellow Luxury
  final Color _vipBg = const Color(0xFFFFFDF7);
  final Color _vipGold = const Color(0xFFFFD700);
  final Color _vipCream = const Color(0xFFFFF8DC);
  final Color _vipAccent = const Color(0xFFFFE57F);
  final Color _vipDark = const Color(0xFF8B7355);
  final Color _vipLight = const Color(0xFFFFFAF0);
  final Color _vipMessageBg = const Color(0xFFFFF9C4);
  final Color _vipCardBg = const Color(0xFFFFF8E1);

  @override
  void initState() {
    super.initState();
    chatId = _getChatId(widget.currentUserId, widget.otherUserId);
    _markMessagesAsRead();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'unreadCount_teacher': 0,
        'lastReadTime_teacher': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({
    String? customText,
    String messageType = 'text',
  }) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set({
        'messageId': messageId,
        'text': text,
        'senderId': widget.currentUserId,
        'senderRole': widget.currentUserRole,
        'messageType': messageType,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      String displayMessage = text;
      if (messageType == 'report') {
        displayMessage = '📋 Session Report';
      } else if (messageType == 'zoom_link') {
        displayMessage = '🔔 Session Starting';
      } else if (text.length > 50) {
        displayMessage = '${text.substring(0, 50)}...';
      }

      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'teacherId': widget.currentUserId,
        'studentId': widget.otherUserId,
        'lastMessage': displayMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': widget.currentUserId,
        'unreadCount_student': FieldValue.increment(1),
        'unreadCount_teacher': 0,
      }, SetOptions(merge: true));

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Failed to send message', isError: true);
      debugPrint('Error sending message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _vipGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _vipBg,
      appBar: _buildVIPAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildVIPInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildVIPAppBar() {
    return AppBar(
      backgroundColor: _vipGold,
      elevation: 8,
      shadowColor: _vipGold.withOpacity(0.5),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _vipDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_vipGold, _vipAccent],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(widget.otherUserName),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: AppTextStyles.appBarTitle.copyWith(
                    fontSize: 16,
                    color: _vipDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.workspace_premium, size: 12, color: _vipDark),
                    const SizedBox(width: 4),
                    Text(
                      'VIP Student',
                      style: AppTextStyles.captionText.copyWith(
                        color: _vipDark.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: _vipDark),
          onPressed: _showStudentInfo,
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: _vipDark),
          color: _vipCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.person, size: 20, color: _vipDark),
                  const SizedBox(width: 10),
                  Text('View Profile', style: AppTextStyles.bodySmall),
                ],
              ),
              onTap: () => _viewStudentProfile(),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red.shade600),
                  const SizedBox(width: 10),
                  Text('Clear Chat', style: AppTextStyles.bodySmall),
                ],
              ),
              onTap: () => Future.delayed(Duration.zero, _clearChat),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_vipLight, _vipBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_vipGold),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading messages',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyChat();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final messageDoc = snapshot.data!.docs[index];
              final messageData = messageDoc.data() as Map<String, dynamic>;
              return _buildMessageBubble(messageData);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _vipCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: _vipGold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start the conversation',
            style: AppTextStyles.heading4.copyWith(
              color: _vipDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.otherUserName}',
            style: AppTextStyles.bodySmall.copyWith(
              color: _vipDark.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData) {
    final text = messageData['text'] ?? '';
    final senderId = messageData['senderId'] ?? '';
    final messageType = messageData['messageType'] ?? 'text';
    final timestamp = messageData['timestamp'] as Timestamp?;
    
    final isMe = senderId == widget.currentUserId;

    // System Message (Zoom Link)
    if (messageType == 'zoom_link') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.videocam, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.blue.shade900,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(timestamp.toDate()),
                      style: AppTextStyles.captionText.copyWith(
                        color: Colors.blue.shade700,
                        fontSize: 10,
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

    // Report Message
    if (messageType == 'report') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 8,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_turned_in, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Session Report',
                  style: AppTextStyles.heading4.copyWith(
                    color: Colors.green.shade900,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.green.shade900,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTime(timestamp.toDate()),
                style: AppTextStyles.captionText.copyWith(
                  color: Colors.green.shade700,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Regular Text Message
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(colors: [_vipGold, _vipAccent])
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: Border.all(
            color: isMe ? _vipGold : _vipCream,
            width: isMe ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isMe 
                  ? _vipGold.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : _vipDark,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatTime(timestamp.toDate()),
                style: AppTextStyles.captionText.copyWith(
                  color: isMe ? Colors.white.withOpacity(0.8) : _vipDark.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVIPInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _vipCardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Quick Actions
            Row(
              children: [
                _buildQuickActionButton(
                  Icons.assignment,
                  'Report',
                  Colors.green,
                  _sendReport,
                ),
                const SizedBox(width: 8),
                _buildQuickActionButton(
                  Icons.videocam,
                  'Zoom',
                  Colors.blue,
                  _sendZoomLink,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Input Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _vipLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _vipCream, width: 2),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.inputValue.copyWith(
                        fontSize: 14,
                        color: _vipDark,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: AppTextStyles.inputHint.copyWith(
                          fontSize: 13,
                          color: _vipDark.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_vipGold, _vipAccent]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _vipGold.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: _isSending ? null : () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendReport() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(onSend: (report) {
        _sendMessage(customText: report, messageType: 'report');
      }),
    );
  }

  void _sendZoomLink() {
    showDialog(
      context: context,
      builder: (context) => ZoomLinkDialog(onSend: (zoomMessage) {
        _sendMessage(customText: zoomMessage, messageType: 'zoom_link');
      }),
    );
  }

  void _showStudentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _vipCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person, color: _vipGold),
            const SizedBox(width: 8),
            Text('Student Info', style: AppTextStyles.heading4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.otherUserName}', 
              style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Status: VIP Student', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Chat ID: $chatId', style: AppTextStyles.captionText),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTextStyles.buttonSecondary),
          ),
        ],
      ),
    );
  }

  void _viewStudentProfile() {
    _showSnackBar('Student profile feature coming soon');
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _vipCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Chat', 
          style: AppTextStyles.heading4.copyWith(color: _vipDark)),
        content: Text(
          'Are you sure you want to delete all messages? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: _vipDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _vipDark)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final messages = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();

        final batch = _firestore.batch();
        for (var doc in messages.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Update chat document
        await _firestore.collection('chats').doc(chatId).set({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showSnackBar('Chat cleared successfully');
      } catch (e) {
        _showSnackBar('Failed to clear chat', isError: true);
        debugPrint('Error clearing chat: $e');
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }
}

// Report Dialog
class ReportDialog extends StatefulWidget {
  final Function(String) onSend;

  const ReportDialog({super.key, required this.onSend});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _unitController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _sessionsLeftController = TextEditingController();

  @override
  void dispose() {
    _unitController.dispose();
    _homeworkController.dispose();
    _sessionsLeftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment, color: Colors.green.shade700, size: 28),
          ),
          const SizedBox(width: 12),
          Text('Session Report',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18,
                color: Colors.brown.shade900,
              )),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _unitController,
              label: 'Unit Completed',
              hint: 'e.g., Unit 3',
              icon: Icons.book,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _homeworkController,
              label: 'Homework',
              hint: 'e.g., Pages 45-50',
              icon: Icons.assignment_turned_in,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _sessionsLeftController,
              label: 'Sessions Left',
              hint: 'e.g., 4',
              icon: Icons.schedule,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', 
            style: AppTextStyles.buttonSecondary.copyWith(
              color: Colors.brown.shade600,
            )),
        ),
        ElevatedButton(
          onPressed: () {
            if (_unitController.text.isEmpty ||
                _homeworkController.text.isEmpty ||
                _sessionsLeftController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please fill all fields'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
              return;
            }

            final report = '''📋 Session Report:

✅ ${_unitController.text} - Complete
✅ Practice exercises done
📚 Homework: ${_homeworkController.text}
⏳ Sessions remaining: ${_sessionsLeftController.text}

Keep up the excellent work!''';

            widget.onSend(report);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Send Report', style: AppTextStyles.buttonPrimary),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, 
          style: AppTextStyles.labelText.copyWith(
            fontSize: 13,
            color: Colors.brown.shade900,
          )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.inputValue.copyWith(
            fontSize: 14,
            color: Colors.brown.shade900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint.copyWith(
              fontSize: 13,
              color: Colors.brown.shade400,
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.brown.shade600),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.amber.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// Zoom Link Dialog
class ZoomLinkDialog extends StatefulWidget {
  final Function(String) onSend;

  const ZoomLinkDialog({super.key, required this.onSend});

  @override
  State<ZoomLinkDialog> createState() => _ZoomLinkDialogState();
}

class _ZoomLinkDialogState extends State<ZoomLinkDialog> {
  final _linkController = TextEditingController();
  final _meetingIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _linkController.dispose();
    _meetingIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.videocam, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(width: 12),
          Text('Send Zoom Link',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18,
                color: Colors.brown.shade900,
              )),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _linkController,
              label: 'Zoom Link',
              hint: 'https://zoom.us/j/...',
              icon: Icons.link,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _meetingIdController,
              label: 'Meeting ID',
              hint: 'e.g., 123 456 789',
              icon: Icons.confirmation_number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Password (Optional)',
              hint: 'Enter meeting password',
              icon: Icons.lock,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
            style: AppTextStyles.buttonSecondary.copyWith(
              color: Colors.brown.shade600,
            )),
        ),
        ElevatedButton(
          onPressed: () {
            if (_linkController.text.isEmpty || _meetingIdController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please fill required fields'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
              return;
            }

            String message = '''🔔 Your session is starting!

🔗 Zoom Link: ${_linkController.text}
🆔 Meeting ID: ${_meetingIdController.text}''';

            if (_passwordController.text.isNotEmpty) {
              message += '\n🔒 Password: ${_passwordController.text}';
            }

            message += '\n\nJoin the session now!';

            widget.onSend(message);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Send Link', style: AppTextStyles.buttonPrimary),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: AppTextStyles.labelText.copyWith(
            fontSize: 13,
            color: Colors.brown.shade900,
          )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTextStyles.inputValue.copyWith(
            fontSize: 14,
            color: Colors.brown.shade900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint.copyWith(
              fontSize: 13,
              color: Colors.brown.shade400,
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.brown.shade600),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.amber.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:studyalquran/utils/app_text_styles.dart';
// import 'package:studyalquran/utils/color_constants.dart';

// class StudentChatScreen extends StatefulWidget {
//   final String otherUserId;
//   final String otherUserName;
//   final String currentUserId;
//   final String currentUserRole;

//   const StudentChatScreen({
//     super.key,
//     required this.otherUserId,
//     required this.otherUserName,
//     required this.currentUserId,
//     required this.currentUserRole,
//   });

//   @override
//   State<StudentChatScreen> createState() => _StudentChatScreenState();
// }

// class _StudentChatScreenState extends State<StudentChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isSending = false;
//   late String chatId;

//   @override
//   void initState() {
//     super.initState();
//     chatId = _getChatId(widget.currentUserId, widget.otherUserId);
//     _markMessagesAsRead();
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   String _getChatId(String userId1, String userId2) {
//     final ids = [userId1, userId2]..sort();
//     return '${ids[0]}_${ids[1]}';
//   }

//   Future<void> _markMessagesAsRead() async {
//     try {
//       final unreadField = widget.currentUserRole == 'teacher'
//           ? 'unreadCount_teacher'
//           : 'unreadCount_student';

//       await _firestore.collection('chats').doc(chatId).update({
//         unreadField: 0,
//       });
//     } catch (e) {
//       // Chat document might not exist yet
//     }
//   }

//   Future<void> _sendMessage({
//     String? customText,
//     String messageType = 'text',
//   }) async {
//     final text = customText ?? _messageController.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isSending = true);

//     try {
//       final messageId = DateTime.now().millisecondsSinceEpoch.toString();

//       // Add message to messages subcollection
//       await _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .doc(messageId)
//           .set({
//         'messageId': messageId,
//         'text': text,
//         'senderId': widget.currentUserId,
//         'senderRole': widget.currentUserRole,
//         'messageType': messageType,
//         'timestamp': FieldValue.serverTimestamp(),
//         'read': false,
//       });

//       // Update chat document with last message
//       final unreadField = widget.currentUserRole == 'teacher'
//           ? 'unreadCount_student'
//           : 'unreadCount_teacher';

//       await _firestore.collection('chats').doc(chatId).set({
//         'chatId': chatId,
//         'teacherId': widget.currentUserRole == 'teacher'
//             ? widget.currentUserId
//             : widget.otherUserId,
//         'studentId': widget.currentUserRole == 'student'
//             ? widget.currentUserId
//             : widget.otherUserId,
//         'lastMessage': messageType == 'report'
//             ? '📋 Session Report'
//             : messageType == 'zoom_link'
//             ? '🔔 Session Starting'
//             : text.length > 50
//             ? '${text.substring(0, 50)}...'
//             : text,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//         unreadField: FieldValue.increment(1),
//       }, SetOptions(merge: true));

//       _messageController.clear();

//       // Scroll to bottom
//       Future.delayed(const Duration(milliseconds: 100), () {
//         if (_scrollController.hasClients) {
//           _scrollController.animateTo(
//             _scrollController.position.maxScrollExtent,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         }
//       });
//     } catch (e) {
//       _showSnackBar('Failed to send message: $e', isError: true);
//     } finally {
//       setState(() => _isSending = false);
//     }
//   }

//   void _sendReport() {
//     showDialog(
//       context: context,
//       builder: (context) => ReportDialog(
//         onSend: (report) {
//           _sendMessage(customText: report, messageType: 'report');
//         },
//       ),
//     );
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? AppColors.error : AppColors.success,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final scaleFactor = screenHeight < 600 ? 0.9 : 1.0;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         elevation: 2,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppColors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: AppColors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Center(
//                 child: Text(
//                   _getInitials(widget.otherUserName),
//                   style: AppTextStyles.bodySmall.copyWith(
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.otherUserName,
//                     style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
//                   ),
//                   Text(
//                     'Online',
//                     style: AppTextStyles.captionText.copyWith(
//                       color: AppColors.white.withOpacity(0.8),
//                       fontSize: 11,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           PopupMenuButton(
//             icon: Icon(Icons.more_vert, color: AppColors.white),
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 child: Row(
//                   children: [
//                     Icon(Icons.person, size: 20, color: AppColors.text),
//                     const SizedBox(width: 10),
//                     Text('View Profile', style: AppTextStyles.bodySmall),
//                   ],
//                 ),
//                 onTap: () {},
//               ),
//               PopupMenuItem(
//                 child: Row(
//                   children: [
//                     Icon(Icons.delete_outline, size: 20, color: AppColors.error),
//                     const SizedBox(width: 10),
//                     Text('Clear Chat',
//                         style: AppTextStyles.bodySmall.copyWith(
//                           color: AppColors.error,
//                         )),
//                   ],
//                 ),
//                 onTap: () => _clearChat(),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: Transform.scale(
//         scale: scaleFactor,
//         child: Column(
//           children: [
//             // Messages List
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.isDarkMode
//                       ? AppColors.darkBackground
//                       : const Color(0xFFF5F7FA),
//                 ),
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: _firestore
//                       .collection('chats')
//                       .doc(chatId)
//                       .collection('messages')
//                       .orderBy('timestamp', descending: false)
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Center(
//                         child: CircularProgressIndicator(
//                           color: AppColors.primary,
//                         ),
//                       );
//                     }

//                     if (snapshot.hasError) {
//                       return Center(
//                         child: Text(
//                           'Error loading messages',
//                           style: AppTextStyles.bodyMedium.copyWith(
//                             color: AppColors.error,
//                           ),
//                         ),
//                       );
//                     }

//                     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                       return Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.chat_bubble_outline,
//                               size: 80,
//                               color: AppColors.subtitle.withOpacity(0.3),
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               'No messages yet',
//                               style: AppTextStyles.heading4.copyWith(
//                                 color: AppColors.subtitle,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Start a conversation',
//                               style: AppTextStyles.bodySmall.copyWith(
//                                 color: AppColors.subtitle,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }

//                     return ListView.builder(
//                       controller: _scrollController,
//                       padding: const EdgeInsets.all(12),
//                       itemCount: snapshot.data!.docs.length,
//                       itemBuilder: (context, index) {
//                         final messageDoc = snapshot.data!.docs[index];
//                         final messageData = messageDoc.data() as Map<String, dynamic>;
//                         return _buildMessageBubble(messageData);
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),

//             // Input Area
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//               decoration: BoxDecoration(
//                 color: AppColors.card,
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.grey.withOpacity(0.1),
//                     blurRadius: 5,
//                     offset: const Offset(0, -2),
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 child: Row(
//                   children: [
//                     // Report Button (Only for teachers)
//                     if (widget.currentUserRole == 'teacher')
//                       IconButton(
//                         icon: Icon(Icons.assignment, color: AppColors.primary),
//                         onPressed: _sendReport,
//                         tooltip: 'Send Report',
//                       ),

//                     // Text Input
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         decoration: BoxDecoration(
//                           color: AppColors.background,
//                           borderRadius: BorderRadius.circular(24),
//                           border: Border.all(color: AppColors.border),
//                         ),
//                         child: TextField(
//                           controller: _messageController,
//                           style: AppTextStyles.inputValue.copyWith(fontSize: 14),
//                           maxLines: null,
//                           textInputAction: TextInputAction.newline,
//                           decoration: InputDecoration(
//                             hintText: 'Type a message...',
//                             hintStyle: AppTextStyles.inputHint.copyWith(fontSize: 13),
//                             border: InputBorder.none,
//                             contentPadding: const EdgeInsets.symmetric(vertical: 10),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(width: 6),

//                     // Send Button
//                     Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [AppColors.primary, AppColors.gradient],
//                         ),
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.primary.withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: IconButton(
//                         icon: _isSending
//                             ? SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   color: AppColors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : Icon(Icons.send, color: AppColors.white, size: 22),
//                         onPressed: _isSending ? null : () => _sendMessage(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageBubble(Map<String, dynamic> messageData) {
//     final text = messageData['text'] ?? '';
//     final senderId = messageData['senderId'] ?? '';
//     final messageType = messageData['messageType'] ?? 'text';
//     final timestamp = messageData['timestamp'] as Timestamp?;

//     final isMe = senderId == widget.currentUserId;

//     // System Message (Zoom Link)
//     if (messageType == 'zoom_link') {
//       return Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFF9C4),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFFFEB3B), width: 1.5),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(Icons.info_outline, color: Colors.orange.shade800, size: 22),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     text,
//                     style: AppTextStyles.bodySmall.copyWith(
//                       color: Colors.orange.shade900,
//                       fontSize: 13,
//                       height: 1.4,
//                     ),
//                   ),
//                   if (timestamp != null) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       _formatTime(timestamp.toDate()),
//                       style: AppTextStyles.captionText.copyWith(
//                         color: Colors.orange.shade700,
//                         fontSize: 10,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // Report Message
//     if (messageType == 'report') {
//       return Align(
//         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//           padding: const EdgeInsets.all(14),
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.8,
//           ),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 AppColors.primary.withOpacity(0.1),
//                 AppColors.gradient.withOpacity(0.1),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: AppColors.primary.withOpacity(0.3),
//               width: 1.5,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.assignment_turned_in,
//                       color: AppColors.primary, size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Session Report',
//                     style: AppTextStyles.heading4.copyWith(
//                       color: AppColors.primary,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 text,
//                 style: AppTextStyles.bodySmall.copyWith(
//                   color: AppColors.text,
//                   fontSize: 13,
//                   height: 1.5,
//                 ),
//               ),
//               if (timestamp != null) ...[
//                 const SizedBox(height: 6),
//                 Text(
//                   _formatTime(timestamp.toDate()),
//                   style: AppTextStyles.captionText.copyWith(
//                     color: AppColors.subtitle,
//                     fontSize: 10,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       );
//     }

//     // Regular Text Message
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.75,
//         ),
//         decoration: BoxDecoration(
//           color: isMe
//               ? AppColors.primary.withOpacity(0.15)
//               : AppColors.isDarkMode
//                   ? AppColors.darkCard
//                   : AppColors.grey.withOpacity(0.15),
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: Radius.circular(isMe ? 16 : 4),
//             bottomRight: Radius.circular(isMe ? 4 : 16),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               text,
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: AppColors.text,
//                 fontSize: 14,
//                 height: 1.4,
//               ),
//             ),
//             if (timestamp != null) ...[
//               const SizedBox(height: 4),
//               Text(
//                 _formatTime(timestamp.toDate()),
//                 style: AppTextStyles.captionText.copyWith(
//                   color: AppColors.subtitle,
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   String _getInitials(String name) {
//     final parts = name.split(' ');
//     if (parts.length >= 2) {
//       return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
//     }
//     return name.substring(0, 2).toUpperCase();
//   }

//   String _formatTime(DateTime timestamp) {
//     final now = DateTime.now();
//     final diff = now.difference(timestamp);

//     if (diff.inDays > 0) {
//       return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
//     } else if (diff.inHours > 0) {
//       return '${diff.inHours}h ago';
//     } else if (diff.inMinutes > 0) {
//       return '${diff.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }

//   Future<void> _clearChat() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Clear Chat', style: AppTextStyles.heading4),
//         content: Text(
//           'Are you sure you want to delete all messages?',
//           style: AppTextStyles.bodyMedium,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
//             child: Text('Delete', style: TextStyle(color: AppColors.white)),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       try {
//         final messages = await _firestore
//             .collection('chats')
//             .doc(chatId)
//             .collection('messages')
//             .get();

//         for (var doc in messages.docs) {
//           await doc.reference.delete();
//         }

//         _showSnackBar('Chat cleared successfully', isError: false);
//       } catch (e) {
//         _showSnackBar('Failed to clear chat', isError: true);
//       }
//     }
//   }
// }

// // Report Dialog
// class ReportDialog extends StatefulWidget {
//   final Function(String) onSend;

//   const ReportDialog({super.key, required this.onSend});

//   @override
//   State<ReportDialog> createState() => _ReportDialogState();
// }

// class _ReportDialogState extends State<ReportDialog> {
//   final _unitController = TextEditingController();
//   final _homeworkController = TextEditingController();
//   final _sessionsLeftController = TextEditingController();

//   @override
//   void dispose() {
//     _unitController.dispose();
//     _homeworkController.dispose();
//     _sessionsLeftController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       backgroundColor: AppColors.card,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Row(
//         children: [
//           Icon(Icons.assignment, color: AppColors.primary, size: 28),
//           const SizedBox(width: 10),
//           Text('Send Report',
//               style: AppTextStyles.heading3.copyWith(fontSize: 18)),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildTextField(
//               controller: _unitController,
//               label: 'Unit Completed',
//               hint: 'e.g., Unit 3',
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _homeworkController,
//               label: 'Homework',
//               hint: 'e.g., Pages 45-50',
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _sessionsLeftController,
//               label: 'Sessions Left',
//               hint: 'e.g., 4',
//               keyboardType: TextInputType.number,
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text('Cancel', style: AppTextStyles.buttonSecondary),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             if (_unitController.text.isEmpty ||
//                 _homeworkController.text.isEmpty ||
//                 _sessionsLeftController.text.isEmpty) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Please fill all fields'),
//                   backgroundColor: AppColors.error,
//                 ),
//               );
//               return;
//             }

//             final report = '''📋 Session Report:

// ✅ ${_unitController.text} - Complete
// ✅ Practice exercises done
// 📚 Homework: ${_homeworkController.text}
// ⏳ Sessions remaining: ${_sessionsLeftController.text}

// Keep up the good work!''';

//             widget.onSend(report);
//             Navigator.pop(context);
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: Text('Send Report',
//               style: AppTextStyles.buttonPrimary.copyWith(fontSize: 14)),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     TextInputType? keyboardType,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: AppTextStyles.labelText.copyWith(fontSize: 13)),
//         const SizedBox(height: 6),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           style: AppTextStyles.inputValue.copyWith(fontSize: 14),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: AppTextStyles.inputHint.copyWith(fontSize: 13),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: AppColors.border),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: AppColors.primary, width: 2),
//             ),
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           ),
//         ),
//       ],
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:studyalquran/mobile/views/chat/studentChatscreen.dart';
// import 'package:studyalquran/utils/app_text_styles.dart';

// class StudentChatListScreen extends StatefulWidget {
//   const StudentChatListScreen({super.key});

//   @override
//   State<StudentChatListScreen> createState() => _StudentChatListScreenState();
// }

// class _StudentChatListScreenState extends State<StudentChatListScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String? currentUserId;
//   String? currentUserRole;
//   bool _isLoading = true;
//   String _searchQuery = '';
//   final TextEditingController _searchController = TextEditingController();

//   // VIP Theme Colors
//   final Color _vipBg = const Color(0xFFFFFDF7);
//   final Color _vipGold = const Color(0xFFFFD700);
//   final Color _vipCream = const Color(0xFFFFF8DC);
//   final Color _vipAccent = const Color(0xFFFFE57F);
//   final Color _vipDark = const Color(0xFF8B7355);
//   final Color _vipCardBg = const Color(0xFFFFF8E1);

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadUserData() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         currentUserId = user.uid;

//         // First try to get role from users collection
//         final userDoc = await _firestore
//             .collection('users')
//             .doc(user.uid)
//             .get();
//         if (userDoc.exists) {
//           currentUserRole = userDoc.data()?['role'];
//         } else {
//           // Check students collection by document ID
//           final studentDoc = await _firestore
//               .collection('students')
//               .doc(user.uid)
//               .get();
//           if (studentDoc.exists) {
//             currentUserRole = 'student';
//           } else {
//             // Check teachers collection
//             final teacherDoc = await _firestore
//                 .collection('teachers')
//                 .doc(user.uid)
//                 .get();
//             if (teacherDoc.exists) {
//               currentUserRole = 'teacher';
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error loading user data: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: _vipBg,
//         body: Center(child: CircularProgressIndicator(color: _vipGold)),
//       );
//     }

//     return Scaffold(
//       backgroundColor: _vipBg,
//       appBar: _buildVIPAppBar(),
//       body: Column(
//         children: [
//           _buildSearchBar(),
//           Expanded(child: _buildChatList()),
//         ],
//       ),
//     );
//   }

//   PreferredSizeWidget _buildVIPAppBar() {
//     return AppBar(
//       backgroundColor: _vipGold,
//       elevation: 8,
//       shadowColor: _vipGold.withOpacity(0.5),
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'VIP Messages',
//             style: AppTextStyles.appBarTitle.copyWith(
//               fontSize: 20,
//               color: _vipDark,
//             ),
//           ),
//           Text(
//             currentUserRole == 'teacher'
//                 ? 'Your VIP Students'
//                 : 'Your VIP Teachers',
//             style: AppTextStyles.captionText.copyWith(
//               color: _vipDark.withOpacity(0.85),
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(Icons.refresh, color: _vipDark),
//           onPressed: () => setState(() => _loadUserData()),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _vipCardBg,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: _vipCream, width: 2),
//         ),
//         child: TextField(
//           controller: _searchController,
//           style: AppTextStyles.bodyMedium.copyWith(color: _vipDark),
//           onChanged: (value) {
//             setState(() => _searchQuery = value.toLowerCase());
//           },
//           decoration: InputDecoration(
//             hintText: 'Search conversations...',
//             hintStyle: AppTextStyles.inputHint.copyWith(
//               color: _vipDark.withOpacity(0.5),
//             ),
//             prefixIcon: Icon(Icons.search, color: _vipDark),
//             suffixIcon: _searchQuery.isNotEmpty
//                 ? IconButton(
//                     icon: Icon(Icons.clear, color: _vipDark),
//                     onPressed: () {
//                       _searchController.clear();
//                       setState(() => _searchQuery = '');
//                     },
//                   )
//                 : null,
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChatList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _getChatListStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator(color: _vipGold));
//         }

//         if (snapshot.hasError) {
//           return _buildErrorWidget('Error loading chats: ${snapshot.error}');
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return _buildEmptyState();
//         }

//         final filteredDocs = snapshot.data!.docs.where((doc) {
//           if (_searchQuery.isEmpty) return true;

//           final data = doc.data() as Map<String, dynamic>;
//           if (currentUserRole == 'teacher') {
//             final studentName = (data['name'] ?? '').toString().toLowerCase();
//             return studentName.contains(_searchQuery);
//           } else {
//             // For students, we'll filter in the FutureBuilder
//             return true;
//           }
//         }).toList();

//         if (filteredDocs.isEmpty) {
//           return _buildNoResultsWidget();
//         }

//         return ListView.separated(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           itemCount: filteredDocs.length,
//           separatorBuilder: (context, index) =>
//               Divider(height: 1, color: _vipDark.withOpacity(0.1), indent: 80),
//           itemBuilder: (context, index) {
//             final chatDoc = filteredDocs[index];
//             return _buildChatTile(chatDoc);
//           },
//         );
//       },
//     );
//   }

//   // Replace _getChatListStream method:
//   Stream<QuerySnapshot> _getChatListStream() {
//     if (currentUserRole == null || currentUserId == null) {
//       return const Stream.empty();
//     }

//     if (currentUserRole == 'teacher') {
//       // For teachers: Get all students assigned to this teacher
//       return _firestore
//           .collection('students')
//           .where('assignedTeacherId', isEqualTo: currentUserId)
//           .snapshots();
//     } else {
//       // For students: Get student document by DOCUMENT ID (not field)
//       return _firestore
//           .collection('students')
//           .where(FieldPath.documentId, isEqualTo: currentUserId)
//           .limit(1)
//           .snapshots();
//     }
//   }

//   Widget _buildChatTile(QueryDocumentSnapshot chatDoc) {
//     final data = chatDoc.data() as Map<String, dynamic>;

//     if (currentUserRole == 'teacher') {
//       return _buildTeacherChatTile(chatDoc, data);
//     } else {
//       return _buildStudentChatTile(data);
//     }
//   }

//   Widget _buildTeacherChatTile(
//     QueryDocumentSnapshot chatDoc,
//     Map<String, dynamic> data,
//   ) {
//     final studentId = data['studentId'] ?? chatDoc.id;
//     final studentName = data['name'] ?? 'Unknown Student';
//     final studentClass = data['class'] ?? '';

//     if (studentId.isEmpty) return const SizedBox.shrink();

//     final chatId = _getChatId(currentUserId!, studentId);

//     return StreamBuilder<DocumentSnapshot>(
//       stream: _firestore.collection('chats').doc(chatId).snapshots(),
//       builder: (context, chatSnapshot) {
//         String lastMessage = 'Start a conversation';
//         String lastMessageTime = '';
//         int unreadCount = 0;
//         bool hasChat = chatSnapshot.hasData && chatSnapshot.data!.exists;

//         if (hasChat) {
//           final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
//           lastMessage = chatData['lastMessage'] ?? 'Start a conversation';
//           unreadCount = chatData['unreadCount_teacher'] ?? 0;

//           if (chatData['lastMessageTime'] != null) {
//             lastMessageTime = _formatTimestamp(
//               (chatData['lastMessageTime'] as Timestamp).toDate(),
//             );
//           }
//         }

//         return _buildChatListItem(
//           userId: studentId,
//           userName: studentName,
//           userSubtitle: studentClass.isNotEmpty
//               ? 'Class: $studentClass'
//               : 'VIP Student',
//           lastMessage: lastMessage,
//           lastMessageTime: lastMessageTime,
//           unreadCount: unreadCount,
//           isOnline: false,
//           onTap: () => _openChat(studentId, studentName),
//         );
//       },
//     );
//   }

//   // Replace the entire _buildStudentChatTile method with this:
//   Widget _buildStudentChatTile(Map<String, dynamic> data) {
//     final teacherId = data['assignedTeacherId'] ?? '';

//     if (teacherId.isEmpty) {
//       return _buildNoTeacherAssignedTile();
//     }

//     return FutureBuilder<DocumentSnapshot>(
//       future: _firestore.collection('teachers').doc(teacherId).get(),
//       builder: (context, teacherSnapshot) {
//         if (teacherSnapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingTile();
//         }

//         if (!teacherSnapshot.hasData || !teacherSnapshot.data!.exists) {
//           return _buildTeacherNotFoundTile();
//         }
//         final teacherData =
//             teacherSnapshot.data!.data() as Map<String, dynamic>;
//         final teacherName = teacherData['name'] ?? 'Unknown Teacher';

//         // FIXED — handle both List & String
//         dynamic subjectsRaw = teacherData['subjects'];
//         String teacherSubtitle = 'VIP Teacher';

//         if (subjectsRaw is List) {
//           teacherSubtitle = subjectsRaw.join(', ');
//         } else if (subjectsRaw is String) {
//           teacherSubtitle = subjectsRaw;
//         }

//         // Filter by search query
//         if (_searchQuery.isNotEmpty &&
//             !teacherName.toLowerCase().contains(_searchQuery)) {
//           return const SizedBox.shrink();
//         }

//         // Create proper chatId - teacher comes first, then student
//         final chatId = _getChatId(teacherId, currentUserId!);

//         return StreamBuilder<DocumentSnapshot>(
//           stream: _firestore.collection('chats').doc(chatId).snapshots(),
//           builder: (context, chatSnapshot) {
//             String lastMessage = 'Start a conversation';
//             String lastMessageTime = '';
//             int unreadCount = 0;

//             if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
//               final chatData =
//                   chatSnapshot.data!.data() as Map<String, dynamic>;

//               // Get last message
//               if (chatData['lastMessage'] != null &&
//                   chatData['lastMessage'].toString().isNotEmpty) {
//                 lastMessage = chatData['lastMessage'];
//               }

//               // Get unread count for STUDENT
//               unreadCount = chatData['unreadCount_student'] ?? 0;

//               // Format timestamp
//               if (chatData['lastMessageTime'] != null) {
//                 try {
//                   final timestamp = chatData['lastMessageTime'] as Timestamp;
//                   lastMessageTime = _formatTimestamp(timestamp.toDate());
//                 } catch (e) {
//                   debugPrint('Error formatting timestamp: $e');
//                 }
//               }
//             }

//             return _buildChatListItem(
//               userId: teacherId,
//               userName: teacherName,
//               userSubtitle: teacherSubtitle,
//               lastMessage: lastMessage,
//               lastMessageTime: lastMessageTime,
//               unreadCount: unreadCount,
//               isOnline: false,
//               onTap: () => _openChat(teacherId, teacherName),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildChatListItem({
//     required String userId,
//     required String userName,
//     required String userSubtitle,
//     required String lastMessage,
//     required String lastMessageTime,
//     required int unreadCount,
//     required bool isOnline,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: unreadCount > 0
//               ? _vipGold.withOpacity(0.05)
//               : Colors.transparent,
//         ),
//         child: Row(
//           children: [
//             // VIP Avatar
//             Stack(
//               children: [
//                 Container(
//                   width: 56,
//                   height: 56,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(colors: [_vipGold, _vipAccent]),
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: _vipGold.withOpacity(0.3),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Center(
//                     child: Text(
//                       _getInitials(userName),
//                       style: AppTextStyles.heading5.copyWith(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // VIP Badge
//                 Positioned(
//                   right: 0,
//                   bottom: 0,
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: _vipGold,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: _vipCardBg, width: 2),
//                     ),
//                     child: Icon(
//                       Icons.workspace_premium,
//                       color: Colors.white,
//                       size: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(width: 14),

//             // Message Info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           userName,
//                           style: AppTextStyles.cardTitle.copyWith(
//                             fontSize: 16,
//                             color: _vipDark,
//                             fontWeight: unreadCount > 0
//                                 ? FontWeight.w700
//                                 : FontWeight.w600,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       if (lastMessageTime.isNotEmpty)
//                         Text(
//                           lastMessageTime,
//                           style: AppTextStyles.captionText.copyWith(
//                             fontSize: 11,
//                             color: unreadCount > 0
//                                 ? _vipGold
//                                 : _vipDark.withOpacity(0.5),
//                             fontWeight: unreadCount > 0
//                                 ? FontWeight.w600
//                                 : FontWeight.w400,
//                           ),
//                         ),
//                     ],
//                   ),
//                   if (userSubtitle.isNotEmpty) ...[
//                     const SizedBox(height: 2),
//                     Text(
//                       userSubtitle,
//                       style: AppTextStyles.captionText.copyWith(
//                         fontSize: 12,
//                         color: _vipGold,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           lastMessage,
//                           style: AppTextStyles.bodySmall.copyWith(
//                             fontSize: 13,
//                             color: unreadCount > 0
//                                 ? _vipDark
//                                 : _vipDark.withOpacity(0.6),
//                             fontWeight: unreadCount > 0
//                                 ? FontWeight.w500
//                                 : FontWeight.w400,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       if (unreadCount > 0) ...[
//                         const SizedBox(width: 8),
//                         Container(
//                           constraints: const BoxConstraints(minWidth: 20),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 7,
//                             vertical: 3,
//                           ),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [_vipGold, _vipAccent],
//                             ),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Text(
//                             unreadCount > 99 ? '99+' : '$unreadCount',
//                             textAlign: TextAlign.center,
//                             style: AppTextStyles.captionText.copyWith(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 4),

//             // Arrow icon
//             Icon(
//               Icons.chevron_right,
//               color: _vipDark.withOpacity(0.3),
//               size: 24,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNoTeacherAssignedTile() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: _vipCream,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _vipGold, width: 1),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.person_off, color: _vipGold, size: 32),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'No Teacher Assigned',
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     color: _vipDark,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Please wait for admin to assign a teacher',
//                   style: AppTextStyles.captionText.copyWith(
//                     color: _vipDark.withOpacity(0.6),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTeacherNotFoundTile() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: _vipCream,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.red.shade300, width: 1),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red, size: 32),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Teacher Not Found',
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     color: Colors.red.shade700,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Assigned teacher data is missing',
//                   style: AppTextStyles.captionText.copyWith(
//                     color: Colors.red.shade600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingTile() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       child: Row(
//         children: [
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(color: _vipCream, shape: BoxShape.circle),
//             child: Center(
//               child: CircularProgressIndicator(strokeWidth: 2, color: _vipGold),
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 120,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     color: _vipCream,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   width: 80,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: _vipCream,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: _vipCream,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.chat_bubble_outline_rounded,
//                 size: 64,
//                 color: _vipGold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               currentUserRole == 'teacher'
//                   ? 'No VIP Students Yet'
//                   : 'No Teacher Assigned',
//               style: AppTextStyles.heading4.copyWith(color: _vipDark),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               currentUserRole == 'teacher'
//                   ? 'Students will appear here once assigned to you'
//                   : 'Please wait for admin to assign a teacher',
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: _vipDark.withOpacity(0.6),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNoResultsWidget() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.search_off_rounded,
//               size: 64,
//               color: _vipDark.withOpacity(0.3),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No results found',
//               style: AppTextStyles.heading4.copyWith(color: _vipDark),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Try searching with different keywords',
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: _vipDark.withOpacity(0.6),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget(String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () => setState(() => _loadUserData()),
//               icon: Icon(Icons.refresh, color: Colors.white),
//               label: Text('Retry', style: TextStyle(color: Colors.white)),
//               style: ElevatedButton.styleFrom(backgroundColor: _vipGold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getChatId(String userId1, String userId2) {
//     final ids = [userId1, userId2]..sort();
//     return '${ids[0]}_${ids[1]}';
//   }

//   String _getInitials(String name) {
//     final parts = name.trim().split(' ');
//     if (parts.length >= 2) {
//       return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
//     }
//     return name.isNotEmpty
//         ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
//         : '?';
//   }

//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final diff = now.difference(timestamp);

//     if (diff.inDays == 0) {
//       final hour = timestamp.hour;
//       final minute = timestamp.minute.toString().padLeft(2, '0');
//       final period = hour >= 12 ? 'PM' : 'AM';
//       final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
//       return '$displayHour:$minute $period';
//     } else if (diff.inDays == 1) {
//       return 'Yesterday';
//     } else if (diff.inDays < 7) {
//       const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
//       return days[timestamp.weekday % 7];
//     } else {
//       return '${timestamp.day}/${timestamp.month}';
//     }
//   }

//   void _openChat(String otherUserId, String otherUserName) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => StudentChatScreen(
//           otherUserId: otherUserId,
//           otherUserName: otherUserName,
//           currentUserId: currentUserId!,
//           currentUserRole: currentUserRole!,
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:studyalquran/mobile/views/chat/studentChatscreen.dart';
// import 'package:studyalquran/utils/app_text_styles.dart';
// import 'package:studyalquran/utils/color_constants.dart';

// class StudentChatListScreen extends StatefulWidget {
//   const StudentChatListScreen({super.key});

//   @override
//   State<StudentChatListScreen> createState() => _StudentChatListScreenState();
// }

// class _StudentChatListScreenState extends State<StudentChatListScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String? currentUserId;
//   String? currentUserRole;
//   bool _isLoading = true;
//   String _searchQuery = '';
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadUserData() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         currentUserId = user.uid;

//         final userDoc = await _firestore
//             .collection('users')
//             .doc(user.uid)
//             .get();
//         if (userDoc.exists) {
//           currentUserRole = userDoc.data()?['role'];
//         } else {
//           final studentDoc = await _firestore
//               .collection('students')
//               .doc(user.uid)
//               .get();
//           if (studentDoc.exists) {
//             currentUserRole = 'student';
//           } else {
//             final teacherDoc = await _firestore
//                 .collection('teachers')
//                 .doc(user.uid)
//                 .get();
//             if (teacherDoc.exists) {
//               currentUserRole = 'teacher';
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error loading user data: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation(AppColors.primary),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           _buildSearchBar(),
//           Expanded(child: _buildChatList()),
//         ],
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: AppColors.primary,
//       elevation: 0,
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Chats',
//             style: AppTextStyles.appBarTitle.copyWith(
//               fontSize: 20,
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           StreamBuilder<QuerySnapshot>(
//             stream: _getChatListStream(),
//             builder: (context, snapshot) {
//               if (snapshot.hasData) {
//                 return Text(
//                   currentUserRole == 'teacher'
//                       ? '${snapshot.data!.docs.length} students'
//                       : 'Your teachers',
//                   style: AppTextStyles.captionText.copyWith(
//                     color: Colors.white.withOpacity(0.8),
//                     fontSize: 12,
//                   ),
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.refresh, color: Colors.white),
//           onPressed: () => setState(() => _loadUserData()),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       color: AppColors.primary,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: TextField(
//           controller: _searchController,
//           style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
//           onChanged: (value) {
//             setState(() => _searchQuery = value.toLowerCase());
//           },
//           decoration: InputDecoration(
//             hintText: 'Search conversations...',
//             hintStyle: AppTextStyles.inputHint.copyWith(
//               color: AppColors.subtitle,
//             ),
//             prefixIcon: Icon(Icons.search, color: AppColors.subtitle, size: 22),
//             suffixIcon: _searchQuery.isNotEmpty
//                 ? IconButton(
//                     icon: Icon(Icons.clear, color: AppColors.subtitle, size: 20),
//                     onPressed: () {
//                       _searchController.clear();
//                       setState(() => _searchQuery = '');
//                     },
//                   )
//                 : null,
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 12,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChatList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _getChatListStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation(AppColors.primary),
//             ),
//           );
//         }

//         if (snapshot.hasError) {
//           return _buildErrorWidget('Error loading chats: ${snapshot.error}');
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return _buildEmptyState();
//         }

//         final filteredDocs = snapshot.data!.docs.where((doc) {
//           if (_searchQuery.isEmpty) return true;

//           final data = doc.data() as Map<String, dynamic>;
//           if (currentUserRole == 'teacher') {
//             final studentName = (data['name'] ?? '').toString().toLowerCase();
//             return studentName.contains(_searchQuery);
//           } else {
//             return true;
//           }
//         }).toList();

//         if (filteredDocs.isEmpty) {
//           return _buildNoResultsWidget();
//         }

//         return ListView.separated(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           itemCount: filteredDocs.length,
//           separatorBuilder: (context, index) => Divider(
//             height: 1,
//             thickness: 1,
//             color: AppColors.border,
//             indent: 88,
//           ),
//           itemBuilder: (context, index) {
//             final chatDoc = filteredDocs[index];
//             return _buildChatTile(chatDoc);
//           },
//         );
//       },
//     );
//   }

//   Stream<QuerySnapshot> _getChatListStream() {
//     if (currentUserRole == null || currentUserId == null) {
//       return const Stream.empty();
//     }

//     if (currentUserRole == 'teacher') {
//       return _firestore
//           .collection('students')
//           .where('assignedTeacherId', isEqualTo: currentUserId)
//           .snapshots();
//     } else {
//       return _firestore
//           .collection('students')
//           .where(FieldPath.documentId, isEqualTo: currentUserId)
//           .limit(1)
//           .snapshots();
//     }
//   }

//   Widget _buildChatTile(QueryDocumentSnapshot chatDoc) {
//     final data = chatDoc.data() as Map<String, dynamic>;

//     if (currentUserRole == 'teacher') {
//       return _buildTeacherChatTile(chatDoc, data);
//     } else {
//       return _buildStudentChatTile(data);
//     }
//   }

//   Widget _buildTeacherChatTile(
//     QueryDocumentSnapshot chatDoc,
//     Map<String, dynamic> data,
//   ) {
//     final studentId = data['studentId'] ?? chatDoc.id;
//     final studentName = data['name'] ?? 'Unknown Student';
//     final studentClass = data['class'] ?? '';

//     if (studentId.isEmpty) return const SizedBox.shrink();

//     final chatId = _getChatId(currentUserId!, studentId);

//     return StreamBuilder<DocumentSnapshot>(
//       stream: _firestore.collection('chats').doc(chatId).snapshots(),
//       builder: (context, chatSnapshot) {
//         String lastMessage = 'Start a conversation';
//         String lastMessageTime = '';
//         int unreadCount = 0;
//         bool hasChat = chatSnapshot.hasData && chatSnapshot.data!.exists;

//         if (hasChat) {
//           final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
//           lastMessage = chatData['lastMessage'] ?? 'Start a conversation';
//           unreadCount = chatData['unreadCount_teacher'] ?? 0;

//           if (chatData['lastMessageTime'] != null) {
//             lastMessageTime = _formatTimestamp(
//               (chatData['lastMessageTime'] as Timestamp).toDate(),
//             );
//           }
//         }

//         return _buildChatListItem(
//           userId: studentId,
//           userName: studentName,
//           userSubtitle: studentClass.isNotEmpty ? 'Class: $studentClass' : '',
//           lastMessage: lastMessage,
//           lastMessageTime: lastMessageTime,
//           unreadCount: unreadCount,
//           onTap: () => _openChat(studentId, studentName),
//         );
//       },
//     );
//   }

//   Widget _buildStudentChatTile(Map<String, dynamic> data) {
//     final teacherId = data['assignedTeacherId'] ?? '';

//     if (teacherId.isEmpty) {
//       return _buildNoTeacherAssignedTile();
//     }

//     return FutureBuilder<DocumentSnapshot>(
//       future: _firestore.collection('teachers').doc(teacherId).get(),
//       builder: (context, teacherSnapshot) {
//         if (teacherSnapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingTile();
//         }

//         if (!teacherSnapshot.hasData || !teacherSnapshot.data!.exists) {
//           return _buildTeacherNotFoundTile();
//         }

//         final teacherData =
//             teacherSnapshot.data!.data() as Map<String, dynamic>;
//         final teacherName = teacherData['name'] ?? 'Unknown Teacher';

//         dynamic subjectsRaw = teacherData['subjects'];
//         String teacherSubtitle = '';

//         if (subjectsRaw is List) {
//           teacherSubtitle = subjectsRaw.join(', ');
//         } else if (subjectsRaw is String) {
//           teacherSubtitle = subjectsRaw;
//         }

//         if (_searchQuery.isNotEmpty &&
//             !teacherName.toLowerCase().contains(_searchQuery)) {
//           return const SizedBox.shrink();
//         }

//         final chatId = _getChatId(teacherId, currentUserId!);

//         return StreamBuilder<DocumentSnapshot>(
//           stream: _firestore.collection('chats').doc(chatId).snapshots(),
//           builder: (context, chatSnapshot) {
//             String lastMessage = 'Start a conversation';
//             String lastMessageTime = '';
//             int unreadCount = 0;

//             if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
//               final chatData =
//                   chatSnapshot.data!.data() as Map<String, dynamic>;

//               if (chatData['lastMessage'] != null &&
//                   chatData['lastMessage'].toString().isNotEmpty) {
//                 lastMessage = chatData['lastMessage'];
//               }

//               unreadCount = chatData['unreadCount_student'] ?? 0;

//               if (chatData['lastMessageTime'] != null) {
//                 try {
//                   final timestamp = chatData['lastMessageTime'] as Timestamp;
//                   lastMessageTime = _formatTimestamp(timestamp.toDate());
//                 } catch (e) {
//                   debugPrint('Error formatting timestamp: $e');
//                 }
//               }
//             }

//             return _buildChatListItem(
//               userId: teacherId,
//               userName: teacherName,
//               userSubtitle: teacherSubtitle,
//               lastMessage: lastMessage,
//               lastMessageTime: lastMessageTime,
//               unreadCount: unreadCount,
//               onTap: () => _openChat(teacherId, teacherName),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildChatListItem({
//     required String userId,
//     required String userName,
//     required String userSubtitle,
//     required String lastMessage,
//     required String lastMessageTime,
//     required int unreadCount,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           color: unreadCount > 0
//               ? AppColors.primaryLight.withOpacity(0.05)
//               : Colors.transparent,
//           child: Row(
//             children: [
//               Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   CircleAvatar(
//                     radius: 28,
//                     backgroundColor: AppColors.primary,
//                     child: Text(
//                       _getInitials(userName),
//                       style: AppTextStyles.heading4.copyWith(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   if (unreadCount > 0)
//                     Positioned(
//                       right: -2,
//                       top: -2,
//                       child: Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: AppColors.primary,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 2),
//                         ),
//                         constraints: const BoxConstraints(
//                           minWidth: 20,
//                           minHeight: 20,
//                         ),
//                         child: Center(
//                           child: Text(
//                             unreadCount > 99 ? '99+' : '$unreadCount',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                               height: 1,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),

//               const SizedBox(width: 12),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             userName,
//                             style: AppTextStyles.cardTitle.copyWith(
//                               fontSize: 16,
//                               color: AppColors.text,
//                               fontWeight: unreadCount > 0
//                                   ? FontWeight.w600
//                                   : FontWeight.w500,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         if (lastMessageTime.isNotEmpty)
//                           Text(
//                             lastMessageTime,
//                             style: AppTextStyles.captionText.copyWith(
//                               fontSize: 12,
//                               color: unreadCount > 0
//                                   ? AppColors.primary
//                                   : AppColors.subtitle,
//                               fontWeight: unreadCount > 0
//                                   ? FontWeight.w600
//                                   : FontWeight.w400,
//                             ),
//                           ),
//                       ],
//                     ),
//                     if (userSubtitle.isNotEmpty) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         userSubtitle,
//                         style: AppTextStyles.captionText.copyWith(
//                           fontSize: 12,
//                           color: AppColors.primary.withOpacity(0.7),
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                     const SizedBox(height: 4),
//                     Text(
//                       lastMessage,
//                       style: AppTextStyles.bodySmall.copyWith(
//                         fontSize: 14,
//                         color: unreadCount > 0
//                             ? AppColors.text
//                             : AppColors.subtitle,
//                         fontWeight: unreadCount > 0
//                             ? FontWeight.w500
//                             : FontWeight.w400,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoTeacherAssignedTile() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.border, width: 1),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.person_off, color: AppColors.subtitle, size: 32),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'No Teacher Assigned',
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     color: AppColors.text,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Please wait for admin to assign a teacher',
//                   style: AppTextStyles.captionText.copyWith(
//                     color: AppColors.subtitle,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTeacherNotFoundTile() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppColors.error.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: AppColors.error, size: 32),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Teacher Not Found',
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     color: AppColors.error,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Assigned teacher data is missing',
//                   style: AppTextStyles.captionText.copyWith(
//                     color: AppColors.error,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingTile() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       child: Row(
//         children: [
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation(AppColors.primary),
//               ),
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 120,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   width: 80,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.chat_bubble_outline,
//               size: 80,
//               color: AppColors.subtitle.withOpacity(0.3),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               currentUserRole == 'teacher'
//                   ? 'No Students Yet'
//                   : 'No Teacher Assigned',
//               style: AppTextStyles.heading3.copyWith(
//                 color: AppColors.text,
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               currentUserRole == 'teacher'
//                   ? 'Students will appear here once assigned to you'
//                   : 'Please wait for admin to assign a teacher',
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: AppColors.subtitle,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNoResultsWidget() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.search_off,
//               size: 64,
//               color: AppColors.subtitle.withOpacity(0.3),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No results found',
//               style: AppTextStyles.heading4.copyWith(color: AppColors.text),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Try searching with different keywords',
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: AppColors.subtitle,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget(String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: AppColors.error),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () => setState(() => _loadUserData()),
//               icon: const Icon(Icons.refresh, color: Colors.white),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getChatId(String userId1, String userId2) {
//     final ids = [userId1, userId2]..sort();
//     return '${ids[0]}_${ids[1]}';
//   }

//   String _getInitials(String name) {
//     final parts = name.trim().split(' ');
//     if (parts.length >= 2) {
//       return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
//     }
//     return name.isNotEmpty
//         ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
//         : '?';
//   }

//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final diff = now.difference(timestamp);

//     if (diff.inDays == 0) {
//       final hour = timestamp.hour;
//       final minute = timestamp.minute.toString().padLeft(2, '0');
//       final period = hour >= 12 ? 'PM' : 'AM';
//       final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
//       return '$displayHour:$minute $period';
//     } else if (diff.inDays == 1) {
//       return 'Yesterday';
//     } else if (diff.inDays < 7) {
//       const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
//       return days[timestamp.weekday % 7];
//     } else {
//       return '${timestamp.day}/${timestamp.month}';
//     }
//   }

//   void _openChat(String otherUserId, String otherUserName) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => StudentChatScreen(
//           otherUserId: otherUserId,
//           otherUserName: otherUserName,
//           currentUserId: currentUserId!,
//           currentUserRole: currentUserRole!,
//         ),
//       ),
//     );
//   }
// }