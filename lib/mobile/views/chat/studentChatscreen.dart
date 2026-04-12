
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:studyalquran/services/fcm_service.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String currentUserId;
  final String currentUserRole;

  const StudentChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSending = false;
  bool _isDisposed = false;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isOnline = false;
  DateTime? _lastSeen;
  late String chatId;
  late String teacherId;
  late String studentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChatIds();
    _initializeChat();
    _markMessagesAsRead();
    _updateOnlineStatus(true);
    _listenToOtherUserStatus();
    _scrollToBottom();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _updateOnlineStatus(false);
    }
  }

  void _initializeChatIds() {
    if (widget.currentUserRole == 'teacher') {
      teacherId = widget.currentUserId;
      studentId = widget.otherUserId;
    } else {
      teacherId = widget.otherUserId;
      studentId = widget.currentUserId;
    }
    chatId = _getChatId(teacherId, studentId);
  }

  // Future<void> _initializeChat() async {
  //   try {
  //     final teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();
  //     final studentDoc = await _firestore.collection('students').doc(studentId).get();

  //     await _firestore.collection('chats').doc(chatId).set({
  //       'chatId': chatId,
  //       'teacherId': teacherId,
  //       'studentId': studentId,
  //       'teacherName': teacherDoc.data()?['name'] ?? 'Teacher',
  //       'studentName': studentDoc.data()?['name'] ?? 'Student',
  //       'participants': [teacherId, studentId],
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'isActive': true,
  //       'unreadCount_teacher': 0,
  //       'unreadCount_student': 0,
  //       'teacher_typing': false,
  //       'student_typing': false,
  //     }, SetOptions(merge: true));
  //   } catch (e) {
  //     debugPrint('Chat init error: $e');
  //   }
  // }

  // void _listenToOtherUserStatus() {
  //   final otherRole = widget.currentUserRole == 'teacher' ? 'students' : 'teachers';
  //   _firestore.collection(otherRole).doc(widget.otherUserId).snapshots().listen((snapshot) {
  //     if (snapshot.exists && mounted) {
  //       final data = snapshot.data();
  //       setState(() {
  //         _isOnline = data?['isOnline'] ?? false;
  //         final lastSeenTimestamp = data?['lastSeen'] as Timestamp?;
  //         _lastSeen = lastSeenTimestamp?.toDate();
  //       });
  //     }
  //   });
  // }

  // Future<void> _updateOnlineStatus(bool isOnline) async {
  //   if (_isDisposed) return;
  //   try {
  //     final collection = widget.currentUserRole == 'teacher' ? 'teachers' : 'students';
  //     await _firestore.collection(collection).doc(widget.currentUserId).set({
  //       'isOnline': isOnline,
  //       'lastSeen': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //   } catch (e) {
  //     debugPrint('Error updating online status: $e');
  //   }
  // }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    _updateTypingStatus(false);
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final unreadField = widget.currentUserRole == 'teacher'
          ? 'unreadCount_teacher'
          : 'unreadCount_student';

      // Mark all unread messages as read
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: widget.currentUserId)
          .where('read', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }

      // Reset unread count
      await _firestore.collection('chats').doc(chatId).set({
        unreadField: 0,
        '${widget.currentUserRole}_lastRead': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (_isDisposed) return;
    try {
      await _firestore.collection('chats').doc(chatId).set({
        '${widget.currentUserRole}_typing': isTyping,
        '${widget.currentUserRole}_typingAt': isTyping
            ? FieldValue.serverTimestamp()
            : null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  void _scrollToBottom() {
    if (_isDisposed || !mounted) return;

    // YE CONDITION ADD KARO - sirf jab naye messages aaye tab scroll karo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isDisposed) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        // Agar user bottom ke paas hai to hi scroll karo
        if (maxScroll - currentScroll < 100) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  // Future<void> _sendMessage({
  //   String? customText,
  //   String messageType = 'text',
  // }) async {
  //   final text = customText ?? _messageController.text.trim();
  //   if (text.isEmpty) return;

  //   setState(() => _isSending = true);
  //   await _updateTypingStatus(false);

  //   try {
  //     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
  //     final timestamp = FieldValue.serverTimestamp();

  //     await _firestore
  //         .collection('chats')
  //         .doc(chatId)
  //         .collection('messages')
  //         .doc(messageId)
  //         .set({
  //       'messageId': messageId,
  //       'text': text,
  //       'senderId': widget.currentUserId,
  //       'senderRole': widget.currentUserRole,
  //       'messageType': messageType,
  //       'timestamp': timestamp,
  //       'read': false,
  //       'chatId': chatId,
  //       'deletedFor': [],
  //     });

  //     String lastMessagePreview;
  //     if (messageType == 'report') {
  //       lastMessagePreview = '📋 Session Report';
  //     } else if (messageType == 'zoom_link') {
  //       lastMessagePreview = '🔔 Session Starting';
  //     } else if (messageType == 'reminder') {
  //       lastMessagePreview = '⏰ Reminder';
  //     } else {
  //       lastMessagePreview = text.length > 50
  //           ? '${text.substring(0, 50)}...'
  //           : text;
  //     }

  //     final unreadField = widget.currentUserRole == 'teacher'
  //         ? 'unreadCount_student'
  //         : 'unreadCount_teacher';

  //     await _firestore.collection('chats').doc(chatId).set({
  //       'lastMessage': lastMessagePreview,
  //       'lastMessageTime': timestamp,
  //       'lastMessageSenderId': widget.currentUserId,
  //       'lastMessageType': messageType,
  //       unreadField: FieldValue.increment(1),
  //       'updatedAt': timestamp,
  //     }, SetOptions(merge: true));

  //     _messageController.clear();

  //     // YE LINE ADD KARO - manual scroll after send
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       if (mounted && _scrollController.hasClients) {
  //         _scrollController.animateTo(
  //           _scrollController.position.maxScrollExtent,
  //           duration: const Duration(milliseconds: 300),
  //           curve: Curves.easeOut,
  //         );
  //       }
  //     });
  //   } catch (e) {
  //     _showSnackBar('Failed to send message', isError: true);
  //     debugPrint('Send message error: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isSending = false);
  //     }
  //   }
  // }
  //   void _showSnackBar(String message, {bool isError = false}) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(message),
  //         backgroundColor: isError ? AppColors.error : AppColors.success,
  //         behavior: SnackBarBehavior.floating,
  //         duration: const Duration(seconds: 2),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //         margin: const EdgeInsets.all(16),
  //       ),
  //     );
  //   }

  // Future<void> _sendMessage({
  //     String? customText,
  //     String messageType = 'text',
  //   }) async {
  //     final text = customText ?? _messageController.text.trim();
  //     if (text.isEmpty) return;

  //     setState(() => _isSending = true);
  //     await _updateTypingStatus(false);

  //     try {
  //       // ... existing message sending code ...

  //       // ADD THIS: Send FCM notification
  //       String notificationTitle;
  //       String notificationBody;
  //       String? zoomLink;

  //       if (messageType == 'report') {
  //         notificationTitle = '📋 New Report';
  //         notificationBody = 'You received a session report';
  //       } else if (messageType == 'zoom_link') {
  //         notificationTitle = '🔔 Session Starting';
  //         notificationBody = 'Your teacher sent a Zoom link';
  //         // Extract zoom link from text
  //         final regex = RegExp(r'https://zoom\.us/j/[^\s]+');
  //         final match = regex.firstMatch(text);
  //         if (match != null) {
  //           zoomLink = match.group(0);
  //         }
  //       } else if (messageType == 'reminder') {
  //         notificationTitle = '⏰ Reminder';
  //         notificationBody = text.length > 50 ? '${text.substring(0, 50)}...' : text;
  //       } else {
  //         notificationTitle = widget.currentUserRole == 'teacher'
  //             ? widget.otherUserName // Teacher's name
  //             : widget.otherUserName;
  //         notificationBody = text.length > 50 ? '${text.substring(0, 50)}...' : text;
  //       }

  //       await FCMService().sendNotification(
  //         recipientId: widget.otherUserId,
  //         recipientRole: widget.currentUserRole == 'teacher' ? 'student' : 'teacher',
  //         title: notificationTitle,
  //         body: notificationBody,
  //         senderId: widget.currentUserId,
  //         senderName: 'You', // This will show receiver's context
  //         currentUserId: widget.otherUserId,
  //         currentUserRole: widget.currentUserRole == 'teacher' ? 'student' : 'teacher',
  //         zoomLink: zoomLink,
  //         type: messageType,
  //       );

  //       _messageController.clear();

  //       Future.delayed(const Duration(milliseconds: 500), () {
  //         if (mounted && _scrollController.hasClients) {
  //           _scrollController.animateTo(
  //             _scrollController.position.maxScrollExtent,
  //             duration: const Duration(milliseconds: 300),
  //             curve: Curves.easeOut,
  //           );
  //         }
  //       });
  //     } catch (e) {
  //       _showSnackBar('Failed to send message', isError: true);
  //       debugPrint('Send message error: $e');
  //     } finally {
  //       if (mounted) {
  //         setState(() => _isSending = false);
  //       }
  //     }
  //   }

  Future<void> _sendMessage({
    String? customText,
    String messageType = 'text',
  }) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    await _updateTypingStatus(false);

    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = FieldValue.serverTimestamp();

      // Save message to Firestore
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
            'timestamp': timestamp,
            'read': false,
            'chatId': chatId,
            'deletedFor': [],
          });

      // Update chat metadata
      String lastMessagePreview;
      if (messageType == 'report') {
        lastMessagePreview = '📋 Session Report';
      } else if (messageType == 'zoom_link') {
        lastMessagePreview = '🔔 Session Starting';
      } else if (messageType == 'reminder') {
        lastMessagePreview = '⏰ Reminder';
      } else {
        lastMessagePreview = text.length > 50
            ? '${text.substring(0, 50)}...'
            : text;
      }

      final unreadField = widget.currentUserRole == 'teacher'
          ? 'unreadCount_student'
          : 'unreadCount_teacher';

      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessagePreview,
        'lastMessageTime': timestamp,
        'lastMessageSenderId': widget.currentUserId,
        'lastMessageType': messageType,
        unreadField: FieldValue.increment(1),
        'updatedAt': timestamp,
      }, SetOptions(merge: true));

      // ✅ FIXED: Send FCM notification (recipientRole removed)
      String notificationTitle;
      String notificationBody;
      String? zoomLink;

      if (messageType == 'report') {
        notificationTitle = '📋 New Report';
        notificationBody = 'You received a session report';
      } else if (messageType == 'zoom_link') {
        notificationTitle = '🔔 Session Starting';
        notificationBody = 'Your teacher sent a Zoom link';

        final regex = RegExp(r'https://zoom\.us/j/[^\s]+');
        final match = regex.firstMatch(text);
        if (match != null) {
          zoomLink = match.group(0);
        }
      } else if (messageType == 'reminder') {
        notificationTitle = '⏰ Reminder';
        notificationBody = text.length > 50
            ? '${text.substring(0, 50)}...'
            : text;
      } else {
        notificationTitle = widget.otherUserName;
        notificationBody = text.length > 50
            ? '${text.substring(0, 50)}...'
            : text;
      }

      // // ✅ CORRECT: No recipientRole parameter
      // // await FCMService().sendNotification(
      //   recipientId: widget.otherUserId,
      //   title: notificationTitle,
      //   body: notificationBody,
      //   senderId: widget.currentUserId,
      //   senderName: widget.otherUserName,
      //   currentUserId: widget.otherUserId,
      //   currentUserRole: widget.currentUserRole == 'teacher'
      //       ? 'student'
      //       : 'teacher',
      //   zoomLink: zoomLink,
      //   type: messageType,
      // );

      _messageController.clear();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _showSnackBar('Failed to send message', isError: true);
      debugPrint('Send message error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // ✅ FIXED: _initializeChat - ab 'users' collection use karega
  Future<void> _initializeChat() async {
    try {
      // ✅ 'teachers'/'students' ki jagah 'users' collection
      final teacherDoc = await _firestore
          .collection('users')
          .doc(teacherId)
          .get();
      final studentDoc = await _firestore
          .collection('users')
          .doc(studentId)
          .get();

      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'teacherId': teacherId,
        'studentId': studentId,
        'teacherName': teacherDoc.data()?['name'] ?? 'Teacher',
        'studentName': studentDoc.data()?['name'] ?? 'Student',
        'participants': [teacherId, studentId],
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'unreadCount_teacher': 0,
        'unreadCount_student': 0,
        'teacher_typing': false,
        'student_typing': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Chat init error: $e');
    }
  }

  // ✅ FIXED: _listenToOtherUserStatus - ab 'users' collection use karega
  void _listenToOtherUserStatus() {
    // ✅ Role-specific collections ki jagah sirf 'users'
    _firestore.collection('users').doc(widget.otherUserId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        setState(() {
          _isOnline = data?['isOnline'] ?? false;
          final lastSeenTimestamp = data?['lastSeen'] as Timestamp?;
          _lastSeen = lastSeenTimestamp?.toDate();
        });
      }
    });
  }

  // ✅ FIXED: _updateOnlineStatus - ab 'users' collection use karega
  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (_isDisposed) return;
    try {
      // ✅ Role-based collection ki jagah sirf 'users'
      await _firestore.collection('users').doc(widget.currentUserId).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getOtherRole() {
    return widget.currentUserRole == 'teacher' ? 'student' : 'teacher';
  }

  String _getOnlineStatus() {
    if (_isOnline) return 'Online';
    if (_lastSeen != null) {
      final diff = DateTime.now().difference(_lastSeen!);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return DateFormat('dd/MM/yy').format(_lastSeen!);
    }
    return 'Offline';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          Expanded(child: _buildMessagesList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          _updateOnlineStatus(false);
          Navigator.pop(context);
        },
      ),
      title: InkWell(
        onTap: _viewProfile,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Text(
                    _getInitials(widget.otherUserName),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .doc(chatId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final isTyping =
                          snapshot.data?.get('${_getOtherRole()}_typing') ??
                          false;
                      return Text(
                        isTyping ? 'Typing...' : _getOnlineStatus(),
                        style: AppTextStyles.captionText.copyWith(
                          color: isTyping
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontStyle: isTyping
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.person, size: 20, color: AppColors.text),
                  const SizedBox(width: 12),
                  Text('View Profile', style: AppTextStyles.bodyMedium),
                ],
              ),
              onTap: () => Future.delayed(Duration.zero, _viewProfile),
            ),
            if (widget.currentUserRole == 'teacher') ...[
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.assignment, size: 20, color: AppColors.success),
                    const SizedBox(width: 12),
                    Text('Send Report', style: AppTextStyles.bodyMedium),
                  ],
                ),
                onTap: () => Future.delayed(Duration.zero, _sendReport),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.videocam, size: 20, color: AppColors.info),
                    const SizedBox(width: 12),
                    Text('Send Zoom Link', style: AppTextStyles.bodyMedium),
                  ],
                ),
                onTap: () => Future.delayed(Duration.zero, _sendZoomLink),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Text('Send Reminder', style: AppTextStyles.bodyMedium),
                  ],
                ),
                onTap: () => Future.delayed(Duration.zero, _sendReminder),
              ),
            ],
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Text('Clear Chat', style: AppTextStyles.bodyMedium),
                ],
              ),
              onTap: () => Future.delayed(Duration.zero, _clearChat),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: AppTextStyles.inputHint,
            prefixIcon: Icon(Icons.search, color: AppColors.subtitle),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.subtitle),
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
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase()),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.background, AppColors.surface],
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
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading messages',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyChat();
          }

          var messages = snapshot.data!.docs;

          // Filter deleted messages
          messages = messages.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final deletedFor = List<String>.from(data['deletedFor'] ?? []);
            return !deletedFor.contains(widget.currentUserId);
          }).toList();

          // Filter by search
          if (_searchQuery.isNotEmpty) {
            messages = messages.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final text = (data['text'] ?? '').toLowerCase();
              return text.contains(_searchQuery);
            }).toList();
          }

          if (messages.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: AppColors.subtitle),
                  const SizedBox(height: 8),
                  Text(
                    'No messages found',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            );
          }

          // WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final messageDoc = messages[index];
              final messageData = messageDoc.data() as Map<String, dynamic>;
              final previousMessage = index > 0
                  ? messages[index - 1].data() as Map<String, dynamic>
                  : null;

              return _buildMessageBubble(
                messageData,
                messageDoc.id,
                previousMessage,
              );
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
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.subtitle.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with ${widget.otherUserName}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> messageData,
    String messageId,
    Map<String, dynamic>? previousMessage,
  ) {
    final text = messageData['text'] ?? '';
    final senderId = messageData['senderId'] ?? '';
    final messageType = messageData['messageType'] ?? 'text';
    final timestamp = messageData['timestamp'] as Timestamp?;
    final isRead = messageData['read'] ?? false;

    final isMe = senderId == widget.currentUserId;
    final showDateDivider = _shouldShowDateDivider(timestamp, previousMessage);

    return Column(
      children: [
        if (showDateDivider && timestamp != null)
          _buildDateDivider(timestamp.toDate()),

        GestureDetector(
          onLongPress: () => _showMessageOptions(messageId, messageData),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (messageType == 'zoom_link')
                  _buildSystemMessage(text, timestamp)
                else if (messageType == 'report')
                  _buildReportMessage(text, timestamp)
                else if (messageType == 'reminder')
                  _buildReminderMessage(text, timestamp)
                else
                  _buildTextMessage(text, timestamp, isMe, isRead, messageId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _shouldShowDateDivider(
    Timestamp? currentTimestamp,
    Map<String, dynamic>? previousMessage,
  ) {
    if (currentTimestamp == null) return false;
    if (previousMessage == null) return true;

    final prevTimestamp = previousMessage['timestamp'] as Timestamp?;
    if (prevTimestamp == null) return true;

    final current = currentTimestamp.toDate();
    final previous = prevTimestamp.toDate();

    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  Widget _buildDateDivider(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      dateText = 'Today';
    } else if (diff.inDays == 1) {
      dateText = 'Yesterday';
    } else if (diff.inDays < 7) {
      dateText = DateFormat('EEEE').format(date);
    } else {
      dateText = DateFormat('dd MMM yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.subtitle.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: AppTextStyles.captionText.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle,
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildSystemMessage(String text, Timestamp? timestamp) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
  //     padding: const EdgeInsets.all(12),
  //     constraints: BoxConstraints(
  //       maxWidth: MediaQuery.of(context).size.width * 0.85,
  //     ),
  //     decoration: BoxDecoration(
  //       color: AppColors.info.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.info.withOpacity(0.3)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.videocam, color: AppColors.info, size: 18),
  //             const SizedBox(width: 8),
  //             Text('Zoom Session',
  //                 style: AppTextStyles.bodyMedium.copyWith(
  //                   color: AppColors.info,
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 13,
  //                 )),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(text,
  //             style: AppTextStyles.bodySmall.copyWith(
  //               color: AppColors.text,
  //               fontSize: 13,
  //             )),
  //         if (timestamp != null) ...[
  //           const SizedBox(height: 6),
  //           Text(_formatTime(timestamp.toDate()),
  //               style: AppTextStyles.captionText.copyWith(
  //                 color: AppColors.subtitle,
  //                 fontSize: 10,
  //               )),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSystemMessage(String text, Timestamp? timestamp) {
    // Extract Zoom link
    final zoomLinkRegex = RegExp(r'https://zoom\.us/j/[^\s]+');
    final match = zoomLinkRegex.firstMatch(text);
    final zoomLink = match?.group(0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Text(
                'Zoom Session',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text,
              fontSize: 13,
            ),
          ),
          if (zoomLink != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _launchZoomUrl(zoomLink),
              icon: const Icon(Icons.videocam, size: 18),
              label: const Text('Join Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
          if (timestamp != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatTime(timestamp.toDate()),
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchZoomUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not open Zoom link', isError: true);
    }
  }

  Widget _buildReportMessage(String text, Timestamp? timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.menu_book,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Session Report',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatTime(timestamp.toDate()),
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderMessage(String text, Timestamp? timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text(
                'Reminder',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatTime(timestamp.toDate()),
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextMessage(
    String text,
    Timestamp? timestamp,
    bool isMe,
    bool isRead,
    String messageId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
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
              color: isMe ? Colors.white : AppColors.text,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timestamp != null ? _formatTime(timestamp.toDate()) : '',
                style: AppTextStyles.captionText.copyWith(
                  color: isMe
                      ? Colors.white.withOpacity(0.7)
                      : AppColors.subtitle,
                  fontSize: 10,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                // YE LINE CHANGE KARO - Single/Double tick ki jagah text
                Text(
                  isRead ? 'Seen' : 'Delivered',
                  style: AppTextStyles.captionText.copyWith(
                    color: isMe
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.subtitle,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppColors.card,
      child: SafeArea(
        child: Row(
          children: [
            // Quick Actions Button
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 28,
              ),
              onPressed: _showQuickActions,
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: AppTextStyles.bodyMedium,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onChanged: (text) {
                    _updateTypingStatus(text.isNotEmpty);
                  },
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: AppTextStyles.inputHint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
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
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  style: AppTextStyles.heading3.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: 20),

                if (widget.currentUserRole == 'teacher') ...[
                  _buildQuickActionTile(
                    icon: Icons.assignment,
                    title: 'Send Session Report',
                    subtitle: 'Share progress and feedback',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      _sendReport();
                    },
                  ),
                  _buildQuickActionTile(
                    icon: Icons.videocam,
                    title: 'Send Zoom Link',
                    subtitle: 'Share meeting details',
                    color: AppColors.info,
                    onTap: () {
                      Navigator.pop(context);
                      _sendZoomLink();
                    },
                  ),
                  _buildQuickActionTile(
                    icon: Icons.notifications,
                    title: 'Send Reminder',
                    subtitle: 'Remind about upcoming session',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      _sendReminder();
                    },
                  ),
                ],

                _buildQuickActionTile(
                  icon: Icons.help_outline,
                  title: 'Ask a Question',
                  subtitle: 'Get help from ${widget.otherUserName}',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text = 'I have a question about ';
                    setState(() {});
                  },
                ),

                if (widget.currentUserRole == 'student') ...[
                  _buildQuickActionTile(
                    icon: Icons.error_outline,
                    title: 'Report Issue',
                    subtitle: 'Report a problem or concern',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      _messageController.text = 'I want to report an issue: ';
                      setState(() {});
                    },
                  ),
                ],
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
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(String messageId, Map<String, dynamic> messageData) {
    final isMe = messageData['senderId'] == widget.currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.warning),
              title: Text('Delete for me', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _deleteMessageForMe(messageId);
              },
            ),
            if (isMe)
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text(
                  'Delete for everyone',
                  style: AppTextStyles.bodyMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessageForEveryone(messageId);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessageForMe(String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayUnion([widget.currentUserId]),
          });
      _showSnackBar('Message deleted');
    } catch (e) {
      _showSnackBar('Failed to delete message', isError: true);
      debugPrint('Error: $e');
    }
  }

  Future<void> _deleteMessageForEveryone(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete message?', style: AppTextStyles.heading4),
        content: Text(
          'This message will be deleted for everyone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .delete();
        _showSnackBar('Message deleted for everyone');
      } catch (e) {
        _showSnackBar('Failed to delete', isError: true);
      }
    }
  }

  void _sendReport() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        onSend: (report) =>
            _sendMessage(customText: report, messageType: 'report'),
      ),
    );
  }

  void _sendZoomLink() {
    showDialog(
      context: context,
      builder: (context) => ZoomLinkDialog(
        onSend: (zoom) =>
            _sendMessage(customText: zoom, messageType: 'zoom_link'),
      ),
    );
  }

  void _sendReminder() {
    showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        onSend: (reminder) =>
            _sendMessage(customText: reminder, messageType: 'reminder'),
      ),
    );
  }

  void _viewProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  _getInitials(widget.otherUserName),
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.otherUserName,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getOnlineStatus(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Chat?', style: AppTextStyles.heading4),
        content: Text(
          'Messages will be removed from your view only.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear'),
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
          batch.update(doc.reference, {
            'deletedFor': FieldValue.arrayUnion([widget.currentUserId]),
          });
        }
        await batch.commit();
        _showSnackBar('Chat cleared');
      } catch (e) {
        _showSnackBar('Failed to clear chat', isError: true);
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(timestamp);
    return DateFormat('HH:mm').format(timestamp);
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
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _unitController.dispose();
    _homeworkController.dispose();
    _sessionsLeftController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.assignment, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 12),
          Text('Session Report', style: AppTextStyles.heading4),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              _unitController,
              'Unit Completed',
              'e.g., Unit 3',
              Icons.book,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _homeworkController,
              'Homework',
              'e.g., Pages 45-50',
              Icons.assignment_turned_in,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _sessionsLeftController,
              'Sessions Left',
              'e.g., 4',
              Icons.schedule,
              TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _notesController,
              'Notes (Optional)',
              'Additional notes...',
              Icons.note,
              TextInputType.text,
              3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_unitController.text.isEmpty ||
                _homeworkController.text.isEmpty ||
                _sessionsLeftController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Fill all required fields'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            String report =
                '''📋 Session Report:

✅ ${_unitController.text} - Complete
✅ Practice exercises done
📚 Homework: ${_homeworkController.text}
⏳ Sessions remaining: ${_sessionsLeftController.text}''';

            if (_notesController.text.trim().isNotEmpty) {
              report += '\n\n📝 Notes: ${_notesController.text}';
            }

            report += '\n\nKeep up the excellent work!';
            widget.onSend(report);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Send Report'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, [
    TextInputType? keyboardType,
    int maxLines = 1,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.subtitle),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
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
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.videocam, color: AppColors.info, size: 24),
          ),
          const SizedBox(width: 12),
          Text('Send Zoom Link', style: AppTextStyles.heading4),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              _linkController,
              'Zoom Link',
              'https://zoom.us/j/...',
              Icons.link,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _meetingIdController,
              'Meeting ID',
              '123 456 789',
              Icons.confirmation_number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _passwordController,
              'Password (Optional)',
              'Meeting password',
              Icons.lock,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_linkController.text.isEmpty ||
                _meetingIdController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Fill required fields'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            String message =
                '''🔔 Your session is starting!

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
            backgroundColor: AppColors.info,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Send Link'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.subtitle),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// Reminder Dialog
class ReminderDialog extends StatefulWidget {
  final Function(String) onSend;
  const ReminderDialog({super.key, required this.onSend});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _reminderController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void dispose() {
    _reminderController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text('Send Reminder', style: AppTextStyles.heading4),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              _reminderController,
              'Reminder Message',
              "e.g., Don\\'t forget your session...",
              Icons.message,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _dateController,
              'Date (Optional)',
              'e.g., Tomorrow, 15th Dec',
              Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _timeController,
              'Time (Optional)',
              'e.g., 10:00 AM',
              Icons.access_time,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reminderController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Enter reminder message'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            String reminder = '⏰ Reminder: ${_reminderController.text}';

            if (_dateController.text.isNotEmpty) {
              reminder += '\n📅 Date: ${_dateController.text}';
            }

            if (_timeController.text.isNotEmpty) {
              reminder += '\n🕒 Time: ${_timeController.text}';
            }

            reminder += '\n\nSee you there!';
            widget.onSend(reminder);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Send Reminder'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.subtitle),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
