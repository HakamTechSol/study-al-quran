import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';


// 💬 Message Model
class ChatMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final String? zoomLink; // For system messages with Zoom links
  final String? reportContent; // For session reports

  ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.zoomLink,
    this.reportContent,
  });
}

// 📝 Message Types
enum MessageType {
  student, // Sent by student
  teacher, // Sent by teacher
  system, // Auto-generated system messages
  report, // Session reports from teacher
  apology, // Apology messages (sent to admin)
}

class TeacherChatScreen2 extends StatefulWidget {
  final String teacherName;
  final String teacherImage;

  const TeacherChatScreen2({
    super.key,
    required this.teacherName,
    this.teacherImage = 'T',
  });

  @override
  State<TeacherChatScreen2> createState() => _TeacherChatScreen2State();
}

class _TeacherChatScreen2State extends State<TeacherChatScreen2> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // 📊 Sample Messages (Replace with API data)
  final List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      text: 'Hello! Welcome to DriveWay. I\'m your assigned driving instructor.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: MessageType.teacher,
      isRead: true,
    ),
    ChatMessage(
      id: '2',
      text: 'Thank you! I\'m excited to start learning.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 23)),
      type: MessageType.student,
      isRead: true,
    ),
    ChatMessage(
      id: '3',
      text: '🔔 Reminder: Your session is scheduled for tomorrow at 10:00 AM',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: MessageType.system,
      isRead: true,
      zoomLink: 'https://zoom.us/j/123456789',
    ),
    ChatMessage(
      id: '4',
      text: 'Session Report: Great progress today! You handled parallel parking well. Focus on checking mirrors more frequently.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: MessageType.report,
      isRead: true,
      reportContent: 'Student showed excellent understanding of vehicle controls. Needs improvement in mirror checking and signal usage.',
    ),
    ChatMessage(
      id: '5',
      text: 'Thank you for the feedback! I\'ll work on that.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      type: MessageType.student,
      isRead: true,
    ),
    ChatMessage(
      id: '6',
      text: '⏰ Your session starts in 15 minutes. Join using the link below:',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: MessageType.system,
      isRead: false,
      zoomLink: 'https://zoom.us/j/987654321',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.white,
              child: Text(
                widget.teacherImage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacherName,
                    style: AppTextStyles.appBarTitle.copyWith(fontSize: 16),
                  ),
                  Text(
                    'Your Instructor',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              _startVideoCall();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 💬 Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),

          // ✍️ Input Area
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 MESSAGE BUBBLE
  // ========================================
  Widget _buildMessageBubble(ChatMessage message) {
    bool isStudent = message.type == MessageType.student;
    bool isSystem = message.type == MessageType.system;
    bool isReport = message.type == MessageType.report;
    bool isApology = message.type == MessageType.apology;

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    if (isReport) {
      return _buildReportMessage(message);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isStudent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Teacher Avatar (left side)
          if (!isStudent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.grey.withOpacity(0.3),
              child: Text(
                widget.teacherImage,
                style: AppTextStyles.captionText.copyWith(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isStudent
                    ? AppColors.opposite // Teal for student
                    : AppColors.lightGrey, // Gray for teacher
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isStudent ? const Radius.circular(16) : Radius.zero,
                  bottomRight:
                      isStudent ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Text
                  Text(
                    message.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isStudent ? AppColors.white : AppColors.text,
                      fontSize: 15,
                    ),
                  ),

                  // Timestamp
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.captionText.copyWith(
                      color: isStudent
                          ? AppColors.white.withOpacity(0.8)
                          : AppColors.subtitle,
                      fontSize: 10,
                    ),
                  ),

                  // Apology Badge
                  if (isApology) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sent to Admin',
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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

          // Student spacing (right side)
          if (isStudent) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ========================================
  // 🔹 SYSTEM MESSAGE
  // ========================================
  Widget _buildSystemMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            // Zoom Link Button
            if (message.zoomLink != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _joinZoomMeeting(message.zoomLink!);
                  },
                  icon: const Icon(Icons.videocam, size: 18),
                  label: Text(
                    'Join Zoom Meeting',
                    style: AppTextStyles.buttonPrimary.copyWith(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],

            // Timestamp
            const SizedBox(height: 8),
            Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 REPORT MESSAGE (with book icon 📘)
  // ========================================
  Widget _buildReportMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Book Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.menu_book, // 📘 Book icon
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Report',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'From ${widget.teacherName}',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Report Content
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                height: 1.5,
              ),
            ),

            // Detailed Report (if available)
            if (message.reportContent != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.reportContent!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // Timestamp
            const SizedBox(height: 12),
            Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 MESSAGE INPUT
  // ========================================
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quick Actions Button
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: AppColors.primary,
              ),
              onPressed: () {
                _showQuickActions();
              },
            ),

            // Text Input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: AppTextStyles.inputHint,
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    setState(() {
                      _isTyping = text.isNotEmpty;
                    });
                  },
                  maxLines: null,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            CircleAvatar(
              backgroundColor: _isTyping
                  ? AppColors.primary
                  : AppColors.grey.withOpacity(0.3),
              radius: 24,
              child: IconButton(
                icon: Icon(
                  _isTyping ? Icons.send : Icons.mic,
                  color: AppColors.white,
                  size: 20,
                ),
                onPressed: _isTyping ? _sendMessage : _recordVoice,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 QUICK ACTIONS BOTTOM SHEET
  // ========================================
  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Actions',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 20),
                _buildQuickActionTile(
                  icon: Icons.error_outline,
                  title: 'Send Apology for Absence',
                  subtitle: 'Notify admin about missed session',
                  color: AppColors.redPrimary,
                  onTap: () {
                    Navigator.pop(context);
                    _sendApology();
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.schedule,
                  title: 'Reschedule Session',
                  subtitle: 'Request a new time slot',
                  color: AppColors.opposite,
                  onTap: () {
                    Navigator.pop(context);
                    _requestReschedule();
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.help_outline,
                  title: 'Ask a Question',
                  subtitle: 'Get help from your instructor',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text = 'I have a question about ';
                    setState(() {
                      _isTyping = true;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionText.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔹 HELPER FUNCTIONS
  // ========================================
  String _formatTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      if (hour == 0) hour = 12;
      return '${dateTime.day}/${dateTime.month} $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: _messageController.text.trim(),
          timestamp: DateTime.now(),
          type: MessageType.student,
        ),
      );
      _messageController.clear();
      _isTyping = false;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendApology() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Apology',
          style: AppTextStyles.heading3.copyWith(color: AppColors.text),
        ),
        content: Text(
          'This will notify the admin about your absence. Would you like to add a reason?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
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
              setState(() {
                messages.add(
                  ChatMessage(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    text:
                        'I apologize for missing the session. I had an emergency.',
                    timestamp: DateTime.now(),
                    type: MessageType.apology,
                  ),
                );
              });
              _showSnackBar('Apology sent to admin', AppColors.primary);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redPrimary,
            ),
            child: Text(
              'Send',
              style: AppTextStyles.buttonPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _requestReschedule() {
    _showSnackBar('Opening reschedule options...', AppColors.opposite);
  }

  void _recordVoice() {
    _showSnackBar('Voice recording coming soon!', AppColors.primary);
  }

  void _startVideoCall() {
    _showSnackBar('Starting video call...', AppColors.primary);
  }

  void _joinZoomMeeting(String link) {
    _showSnackBar('Opening Zoom: $link', AppColors.primary);
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.block, color: AppColors.redPrimary),
                title: Text('Mute Notifications',
                    style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.redPrimary),
                title: Text('Clear Chat', style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.report, color: AppColors.redPrimary),
                title:
                    Text('Report Issue', style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}