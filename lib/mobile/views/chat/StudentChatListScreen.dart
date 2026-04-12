

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studyalquran/mobile/views/chat/studentChatscreen.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';

class StudentChatListScreen extends StatefulWidget {
  const StudentChatListScreen({super.key});

  @override
  State<StudentChatListScreen> createState() => _StudentChatListScreenState();
}

class _StudentChatListScreenState extends State<StudentChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? currentUserId;
  String? currentUserRole;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        currentUserId = user.uid;

        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          currentUserRole = userDoc.data()?['role'];
        } else {
          final studentDoc = await _firestore
              .collection('students')
              .doc(user.uid)
              .get();
          if (studentDoc.exists) {
            currentUserRole = 'student';
          } else {
            final teacherDoc = await _firestore
                .collection('teachers')
                .doc(user.uid)
                .get();
            if (teacherDoc.exists) {
              currentUserRole = 'teacher';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildChatList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chats',
            style: AppTextStyles.appBarTitle.copyWith(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getChatListStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  currentUserRole == 'teacher'
                      ? '${snapshot.data!.docs.length} students'
                      : 'Your teachers',
                  style: AppTextStyles.captionText.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => setState(() => _loadUserData()),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
          },
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: AppTextStyles.inputHint.copyWith(
              color: AppColors.subtitle,
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.subtitle, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.subtitle,
                      size: 20,
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
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getChatListStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading chats: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;

          final data = doc.data() as Map<String, dynamic>;
          if (currentUserRole == 'teacher') {
            final studentName = (data['name'] ?? '').toString().toLowerCase();
            return studentName.contains(_searchQuery);
          } else {
            return true;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildNoResultsWidget();
        }

        // FutureBuilder use karte hue sort karne ke liye
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _sortChatsByPriority(filteredDocs),
          builder: (context, sortSnapshot) {
            if (sortSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              );
            }

            if (sortSnapshot.hasError) {
              return _buildErrorWidget(
                'Error sorting chats: ${sortSnapshot.error}',
              );
            }

            final sortedDocs =
                sortSnapshot.data ?? filteredDocs; // Fallback agar error ho

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedDocs.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
                indent: 88,
              ),
              itemBuilder: (context, index) {
                final chatDoc = sortedDocs[index];
                return _buildChatTile(chatDoc);
              },
            );
          },
        );
      },
    );
  }

  // Sorting function jo Future return karegi
  Future<List<QueryDocumentSnapshot>> _sortChatsByPriority(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final List<Map<String, dynamic>> chatData = [];

    // Har chat ke liye additional data fetch karo
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final otherUserId = currentUserRole == 'teacher'
          ? (data['studentId'] ?? doc.id)
          : (data['assignedTeacherId'] ?? '');

      final chatId = _getChatId(currentUserId!, otherUserId);

      // Firestore se latest message aur unread count fetch karo
      try {
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();

        final messagesQuery = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        final lastMessageTime = messagesQuery.docs.isNotEmpty
            ? messagesQuery.docs.first['timestamp'] as Timestamp
            : Timestamp.now();

        int unreadCount = 0;
        if (chatDoc.exists) {
          final chatDataMap = chatDoc.data() as Map<String, dynamic>;
          final unreadField = currentUserRole == 'teacher'
              ? 'teacherUnreadCount'
              : 'studentUnreadCount';
          unreadCount = chatDataMap[unreadField] as int? ?? 0;
        }

        chatData.add({
          'doc': doc,
          'unreadCount': unreadCount,
          'lastMessageTime': lastMessageTime,
        });
      } catch (e) {
        // Agar error aaye to default values use karo
        chatData.add({
          'doc': doc,
          'unreadCount': 0,
          'lastMessageTime': Timestamp.now(),
        });
      }
    }

    // Sort by: unread count (descending), then by last message time (descending)
    chatData.sort((a, b) {
      // Pehle unread count ke hisaab se (unread pehle)
      if (a['unreadCount'] != b['unreadCount']) {
        return b['unreadCount'].compareTo(a['unreadCount']);
      }

      // Phir last message time ke hisaab se (recent pehle)
      final timeA = a['lastMessageTime'] as Timestamp;
      final timeB = b['lastMessageTime'] as Timestamp;
      return timeB.compareTo(timeA);
    });

    // Sirf documents return karo
    return chatData
        .map((item) => item['doc'] as QueryDocumentSnapshot)
        .toList();
  }

  // Helper function for chat ID
  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Future<List<QueryDocumentSnapshot>> _sortChatsByPriority(
  //   List<QueryDocumentSnapshot> docs,
  // ) async {
  //   List<Map<String, dynamic>> chatsWithData = [];

  //   for (var doc in docs) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     String otherUserId;

  //     if (currentUserRole == 'teacher') {
  //       otherUserId = data['studentId'] ?? doc.id;
  //     } else {
  //       otherUserId = data['assignedTeacherId'] ?? '';
  //     }

  //     if (otherUserId.isEmpty) continue;

  //     final chatId = _getChatId(currentUserId!, otherUserId);
  //     final chatDoc = await _firestore.collection('chats').doc(chatId).get();

  //     int unreadCount = 0;
  //     DateTime? lastMessageTime;

  //     if (chatDoc.exists) {
  //       final chatData = chatDoc.data() as Map<String, dynamic>;
  //       unreadCount = currentUserRole == 'teacher'
  //           ? (chatData['unreadCount_teacher'] ?? 0)
  //           : (chatData['unreadCount_student'] ?? 0);

  //       if (chatData['lastMessageTime'] != null) {
  //         lastMessageTime = (chatData['lastMessageTime'] as Timestamp).toDate();
  //       }
  //     }

  //     chatsWithData.add({
  //       'doc': doc,
  //       'unreadCount': unreadCount,
  //       'lastMessageTime': lastMessageTime,
  //     });
  //   }

  //   // Sort: Unread first, then by most recent
  //   chatsWithData.sort((a, b) {
  //     final unreadA = a['unreadCount'] as int;
  //     final unreadB = b['unreadCount'] as int;
  //     final timeA = a['lastMessageTime'] as DateTime?;
  //     final timeB = b['lastMessageTime'] as DateTime?;

  //     // If one has unread and other doesn't, unread comes first
  //     if (unreadA > 0 && unreadB == 0) return -1;
  //     if (unreadA == 0 && unreadB > 0) return 1;

  //     // Both have unread or both don't - sort by time
  //     if (timeA == null && timeB == null) return 0;
  //     if (timeA == null) return 1;
  //     if (timeB == null) return -1;
  //     return timeB.compareTo(timeA);
  //   });

  //   return chatsWithData
  //       .map((item) => item['doc'] as QueryDocumentSnapshot)
  //       .toList();
  // }



  Stream<QuerySnapshot> _getChatListStream() {
    if (currentUserRole == null || currentUserId == null) {
      return const Stream.empty();
    }

    if (currentUserRole == 'teacher') {
      return _firestore
          .collection('students')
          .where('assignedTeacherId', isEqualTo: currentUserId)
          .snapshots();
    } else {
      return _firestore
          .collection('students')
          .where(FieldPath.documentId, isEqualTo: currentUserId)
          .limit(1)
          .snapshots();
    }
  }

  Widget _buildChatTile(QueryDocumentSnapshot chatDoc) {
    final data = chatDoc.data() as Map<String, dynamic>;

    if (currentUserRole == 'teacher') {
      return _buildTeacherChatTile(chatDoc, data);
    } else {
      return _buildStudentChatTile(data);
    }
  }

  Widget _buildTeacherChatTile(
    QueryDocumentSnapshot chatDoc,
    Map<String, dynamic> data,
  ) {
    final studentId = data['studentId'] ?? chatDoc.id;
    final studentName = data['name'] ?? 'Unknown Student';
    final studentClass = data['class'] ?? '';

    if (studentId.isEmpty) return const SizedBox.shrink();

    final chatId = _getChatId(currentUserId!, studentId);

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('chats').doc(chatId).snapshots(),
      builder: (context, chatSnapshot) {
        String lastMessage = 'Start a conversation';
        String lastMessageTime = '';
        int unreadCount = 0;
        bool hasChat = chatSnapshot.hasData && chatSnapshot.data!.exists;

        if (hasChat) {
          final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
          lastMessage = chatData['lastMessage'] ?? 'Start a conversation';
          unreadCount = chatData['unreadCount_teacher'] ?? 0;

          if (chatData['lastMessageTime'] != null) {
            lastMessageTime = _formatTimestamp(
              (chatData['lastMessageTime'] as Timestamp).toDate(),
            );
          }
        }

        return _buildChatListItem(
          userId: studentId,
          userName: studentName,
          userSubtitle: studentClass.isNotEmpty ? 'Class: $studentClass' : '',
          lastMessage: lastMessage,
          lastMessageTime: lastMessageTime,
          unreadCount: unreadCount,
          onTap: () => _openChat(studentId, studentName),
        );
      },
    );
  }

  Widget _buildStudentChatTile(Map<String, dynamic> data) {
    final teacherId = data['assignedTeacherId'] ?? '';

    if (teacherId.isEmpty) {
      return _buildNoTeacherAssignedTile();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('teachers').doc(teacherId).get(),
      builder: (context, teacherSnapshot) {
        if (teacherSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingTile();
        }

        if (!teacherSnapshot.hasData || !teacherSnapshot.data!.exists) {
          return _buildTeacherNotFoundTile();
        }

        final teacherData =
            teacherSnapshot.data!.data() as Map<String, dynamic>;
        final teacherName = teacherData['name'] ?? 'Unknown Teacher';

        dynamic subjectsRaw = teacherData['subjects'];
        String teacherSubtitle = '';

        if (subjectsRaw is List) {
          teacherSubtitle = subjectsRaw.join(', ');
        } else if (subjectsRaw is String) {
          teacherSubtitle = subjectsRaw;
        }

        if (_searchQuery.isNotEmpty &&
            !teacherName.toLowerCase().contains(_searchQuery)) {
          return const SizedBox.shrink();
        }

        final chatId = _getChatId(teacherId, currentUserId!);

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('chats').doc(chatId).snapshots(),
          builder: (context, chatSnapshot) {
            String lastMessage = 'Start a conversation';
            String lastMessageTime = '';
            int unreadCount = 0;

            if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
              final chatData =
                  chatSnapshot.data!.data() as Map<String, dynamic>;

              if (chatData['lastMessage'] != null &&
                  chatData['lastMessage'].toString().isNotEmpty) {
                lastMessage = chatData['lastMessage'];
              }

              unreadCount = chatData['unreadCount_student'] ?? 0;

              if (chatData['lastMessageTime'] != null) {
                try {
                  final timestamp = chatData['lastMessageTime'] as Timestamp;
                  lastMessageTime = _formatTimestamp(timestamp.toDate());
                } catch (e) {
                  debugPrint('Error formatting timestamp: $e');
                }
              }
            }

            return _buildChatListItem(
              userId: teacherId,
              userName: teacherName,
              userSubtitle: teacherSubtitle,
              lastMessage: lastMessage,
              lastMessageTime: lastMessageTime,
              unreadCount: unreadCount,
              onTap: () => _openChat(teacherId, teacherName),
            );
          },
        );
      },
    );
  }

  Widget _buildChatListItem({
    required String userId,
    required String userName,
    required String userSubtitle,
    required String lastMessage,
    required String lastMessageTime,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: unreadCount > 0
              ? AppColors.primaryLight.withOpacity(0.05)
              : Colors.transparent,
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _getInitials(userName),
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 16,
                              color: AppColors.text,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime.isNotEmpty)
                          Text(
                            lastMessageTime,
                            style: AppTextStyles.captionText.copyWith(
                              fontSize: 12,
                              color: unreadCount > 0
                                  ? AppColors.primary
                                  : AppColors.subtitle,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    if (userSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        userSubtitle,
                        style: AppTextStyles.captionText.copyWith(
                          fontSize: 12,
                          color: AppColors.primary.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 14,
                        color: unreadCount > 0
                            ? AppColors.text
                            : AppColors.subtitle,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildNoTeacherAssignedTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.person_off, color: AppColors.subtitle, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Teacher Assigned',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please wait for admin to assign a teacher',
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherNotFoundTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Not Found',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned teacher data is missing',
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.subtitle.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              currentUserRole == 'teacher'
                  ? 'No Students Yet'
                  : 'No Teacher Assigned',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currentUserRole == 'teacher'
                  ? 'Students will appear here once assigned to you'
                  : 'Please wait for admin to assign a teacher',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.subtitle.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: AppTextStyles.heading4.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _loadUserData()),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // String _getChatId(String userId1, String userId2) {
  //   final ids = [userId1, userId2]..sort();
  //   return '${ids[0]}_${ids[1]}';
  // }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '?';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[timestamp.weekday % 7];
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _openChat(String otherUserId, String otherUserName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          currentUserId: currentUserId!,
          currentUserRole: currentUserRole!,
        ),
      ),
    );
  }
}
