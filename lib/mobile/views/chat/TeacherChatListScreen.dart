

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studyalquran/mobile/views/chat/TeacherChatScreen.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';

class TeacherChatListScreen extends StatefulWidget {
  const TeacherChatListScreen({super.key});

  @override
  State<TeacherChatListScreen> createState() => _TeacherChatListScreenState();
}

class _TeacherChatListScreenState extends State<TeacherChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? currentTeacherId;
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'unread', 'recent'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        currentTeacherId = user.uid;
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
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
            strokeWidth: 2.5,
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
          Expanded(child: _buildChatsList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      // leading: IconButton(
      //   icon: const Icon(Icons.arrow_back, color: Colors.white),
      //   onPressed: () => Navigator.pop(context),
      // ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chats',
            style: AppTextStyles.appBarTitle.copyWith(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('students')
                .where('assignedTeacherId', isEqualTo: currentTeacherId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  '${snapshot.data!.docs.length} students',
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
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: _showFilterOptions,
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
          decoration: InputDecoration(
            hintText: 'Search students...',
            hintStyle: AppTextStyles.inputHint.copyWith(
              color: AppColors.subtitle,
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.subtitle, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.subtitle, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
          },
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    if (currentTeacherId == null) {
      return _buildErrorWidget('Unable to load teacher data');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('students')
          .where('assignedTeacherId', isEqualTo: currentTeacherId)
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
          return _buildErrorWidget('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var students = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final studentName = (data['name'] ?? '').toLowerCase();
          return studentName.contains(_searchQuery);
        }).toList();

        if (students.isEmpty) {
          return _buildNoSearchResults();
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getStudentsWithChatData(students),
          builder: (context, chatSnapshot) {
            if (!chatSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              );
            }

            var sortedStudents = chatSnapshot.data!;

            // Apply filter
            if (_filterType == 'unread') {
              sortedStudents = sortedStudents.where((s) => s['unreadCount'] > 0).toList();
            } else if (_filterType == 'recent') {
              sortedStudents.sort((a, b) {
                final aTime = a['lastMessageTime'] as DateTime?;
                final bTime = b['lastMessageTime'] as DateTime?;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });
            }

            if (sortedStudents.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedStudents.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
                indent: 88,
              ),
              itemBuilder: (context, index) {
                return _buildChatTile(sortedStudents[index]);
              },
            );
          },
        );
      },
    );
  }

  // Future<List<Map<String, dynamic>>> _getStudentsWithChatData(
  //     List<QueryDocumentSnapshot> students) async {
  //   List<Map<String, dynamic>> result = [];

  //   for (var studentDoc in students) {
  //     final data = studentDoc.data() as Map<String, dynamic>;
  //     final studentId = data['studentId'] ?? studentDoc.id;

  //     final chatDoc = await _firestore
  //         .collection('chats')
  //         .doc(_getChatId(currentTeacherId!, studentId))
  //         .get();

  //     String lastMessage = 'No messages yet';
  //     DateTime? lastMessageTime;
  //     int unreadCount = 0;

  //     if (chatDoc.exists) {
  //       final chatData = chatDoc.data() as Map<String, dynamic>;
  //       lastMessage = chatData['lastMessage'] ?? 'No messages yet';
        
  //       if (chatData['lastMessageTime'] != null) {
  //         lastMessageTime = (chatData['lastMessageTime'] as Timestamp).toDate();
  //       }
        
  //       unreadCount = chatData['unreadCount_teacher'] ?? 0;
  //     }

  //     result.add({
  //       'studentId': studentId,
  //       'studentName': data['name'] ?? 'Unknown Student',
  //       'studentClass': data['class'] ?? '',
  //       'lastMessage': lastMessage,
  //       'lastMessageTime': lastMessageTime,
  //       'unreadCount': unreadCount,
  //     });
  //   }

  //   return result;
  // }


Future<List<Map<String, dynamic>>> _getStudentsWithChatData(
    List<QueryDocumentSnapshot> students) async {
  List<Map<String, dynamic>> result = [];

  for (var studentDoc in students) {
    final data = studentDoc.data() as Map<String, dynamic>;
    final studentId = data['studentId'] ?? studentDoc.id;

    final chatDoc = await _firestore
        .collection('chats')
        .doc(_getChatId(currentTeacherId!, studentId))
        .get();

    String lastMessage = 'No messages yet';
    DateTime? lastMessageTime;
    int unreadCount = 0;

    if (chatDoc.exists) {
      final chatData = chatDoc.data() as Map<String, dynamic>;
      lastMessage = chatData['lastMessage'] ?? 'No messages yet';
      
      if (chatData['lastMessageTime'] != null) {
        lastMessageTime = (chatData['lastMessageTime'] as Timestamp).toDate();
      }
      
      unreadCount = chatData['unreadCount_teacher'] ?? 0;
    }

    result.add({
      'studentId': studentId,
      'studentName': data['name'] ?? 'Unknown Student',
      'studentClass': data['class'] ?? '',
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    });
  }

  // Sort: Unread first, then by most recent message time
  result.sort((a, b) {
    final unreadA = a['unreadCount'] as int;
    final unreadB = b['unreadCount'] as int;
    final timeA = a['lastMessageTime'] as DateTime?;
    final timeB = b['lastMessageTime'] as DateTime?;
    
    // If one has unread and other doesn't, unread comes first
    if (unreadA > 0 && unreadB == 0) return -1;
    if (unreadA == 0 && unreadB > 0) return 1;
    
    // Both have unread or both don't - sort by time
    if (timeA == null && timeB == null) return 0;
    if (timeA == null) return 1;
    if (timeB == null) return -1;
    return timeB.compareTo(timeA);
  });

  return result;
}

// Helper function for chat ID
String _getChatId(String userId1, String userId2) {
  final ids = [userId1, userId2]..sort();
  return '${ids[0]}_${ids[1]}';
}



  Widget _buildChatTile(Map<String, dynamic> studentData) {
    final studentId = studentData['studentId'];
    final studentName = studentData['studentName'];
    final studentClass = studentData['studentClass'];
    final lastMessage = studentData['lastMessage'];
    final lastMessageTime = studentData['lastMessageTime'] as DateTime?;
    final unreadCount = studentData['unreadCount'] as int;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openChat(studentId, studentName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: unreadCount > 0 
              ? AppColors.primaryLight.withOpacity(0.05)
              : Colors.transparent,
          child: Row(
            children: [
              // Avatar with unread badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _getInitials(studentName),
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

              // Message Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            studentName,
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
                        if (lastMessageTime != null)
                          Text(
                            _formatTimestamp(lastMessageTime),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No Chats Yet',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students will appear here once assigned',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
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
            'No students found',
            style: AppTextStyles.heading4.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
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
        ],
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
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Filter Chats',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(
                Icons.chat,
                'All Chats',
                'Show all conversations',
                _filterType == 'all',
                () {
                  setState(() => _filterType = 'all');
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                Icons.mark_chat_unread,
                'Unread Only',
                'Show only unread messages',
                _filterType == 'unread',
                () {
                  setState(() => _filterType = 'unread');
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                Icons.schedule,
                'Recent First',
                'Sort by most recent activity',
                _filterType == 'recent',
                () {
                  setState(() => _filterType = 'recent');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    IconData icon,
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.subtitle,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.text,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.captionText.copyWith(
          color: AppColors.subtitle,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }

  void _openChat(String studentId, String studentName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherChatScreen(
          otherUserId: studentId,
          otherUserName: studentName,
          currentUserId: currentTeacherId!,
          currentUserRole: 'teacher',
        ),
      ),
    );
  }
}