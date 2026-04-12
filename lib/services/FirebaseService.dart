import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔥 Firebase Service Class
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // 1️⃣ ADMIN FUNCTIONS
  // ============================================

  /// Create a new user (Teacher or Student) - ADMIN ONLY
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String role, // 'teacher' or 'student'
    required String name,
    required String phone,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create Firebase Auth account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Add to 'users' collection
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to role-specific collection
      if (role == 'teacher') {
        await _firestore.collection('teachers').doc(uid).set({
          'teacherId': uid,
          'name': name,
          'email': email,
          'subjects': additionalData?['subjects'] ?? [],
          'walletBalance': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (role == 'student') {
        await _firestore.collection('students').doc(uid).set({
          'studentId': uid,
          'name': name,
          'class': additionalData?['class'] ?? '',
          'parentPhone': additionalData?['parentPhone'] ?? phone,
          'feeStatus': 'pending',
          'assignedTeacherId': additionalData?['assignedTeacherId'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'success': true,
        'uid': uid,
        'message': '$role created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Assign student to teacher - ADMIN ONLY
  Future<bool> assignStudentToTeacher({
    required String studentId,
    required String teacherId,
  }) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'assignedTeacherId': teacherId,
      });
      return true;
    } catch (e) {
      print('Error assigning student: $e');
      return false;
    }
  }

  /// Update teacher wallet - ADMIN ONLY
  Future<bool> updateTeacherWallet({
    required String teacherId,
    required double amount,
    required String type, // 'add' or 'deduct'
    required String description,
  }) async {
    try {
      DocumentSnapshot teacherDoc =
          await _firestore.collection('teachers').doc(teacherId).get();

      if (!teacherDoc.exists) return false;

      double currentBalance =
          (teacherDoc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
      double newBalance =
          type == 'add' ? currentBalance + amount : currentBalance - amount;

      // Update wallet balance
      await _firestore.collection('teachers').doc(teacherId).update({
        'walletBalance': newBalance,
      });

      // Add transaction record
      await _firestore.collection('walletTransactions').add({
        'teacherId': teacherId,
        'amount': amount,
        'type': type,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating wallet: $e');
      return false;
    }
  }

  /// Deactivate user account - ADMIN ONLY
  Future<bool> deactivateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'inactive',
      });
      return true;
    } catch (e) {
      print('Error deactivating user: $e');
      return false;
    }
  }

  /// Activate user account - ADMIN ONLY
  Future<bool> activateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'active',
      });
      return true;
    } catch (e) {
      print('Error activating user: $e');
      return false;
    }
  }

  // ============================================
  // 2️⃣ TEACHER FUNCTIONS
  // ============================================

  /// Get assigned students for a teacher
  Stream<QuerySnapshot> getAssignedStudents(String teacherId) {
    return _firestore
        .collection('students')
        .where('assignedTeacherId', isEqualTo: teacherId)
        .snapshots();
  }

  /// Get teacher's wallet balance
  Future<double> getTeacherWallet(String teacherId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('teachers').doc(teacherId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet: $e');
      return 0.0;
    }
  }

  /// Mark attendance - TEACHER ONLY
  Future<bool> markAttendance({
    required String teacherId,
    required String studentId,
    required String status, // 'present' or 'absent'
  }) async {
    try {
      await _firestore.collection('attendance').add({
        'date': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD
        'teacherId': teacherId,
        'studentId': studentId,
        'status': status,
        'time': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  /// Get wallet transactions for teacher
  Stream<QuerySnapshot> getWalletTransactions(String teacherId) {
    return _firestore
        .collection('walletTransactions')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ============================================
  // 3️⃣ STUDENT FUNCTIONS
  // ============================================

  /// Get student details
  Future<Map<String, dynamic>?> getStudentDetails(String studentId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting student details: $e');
      return null;
    }
  }

  /// Get student's attendance records
  Stream<QuerySnapshot> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('time', descending: true)
        .snapshots();
  }

  // ============================================
  // 4️⃣ COMMON FUNCTIONS
  // ============================================

  /// Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  /// Send notification to user
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  /// Get notifications for user
  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Get all users (for admin)
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all teachers (for admin)
  Stream<QuerySnapshot> getAllTeachers() {
    return _firestore
        .collection('teachers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all students (for admin)
  Stream<QuerySnapshot> getAllStudents() {
    return _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ============================================
  // 6️⃣ CHAT FUNCTIONS
  // ============================================

  /// Send chat message
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String text,
    String messageType = 'text',
  }) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Add message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set({
        'messageId': messageId,
        'text': text,
        'senderId': senderId,
        'senderRole': senderRole,
        'messageType': messageType,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update chat metadata
      final unreadField = senderRole == 'teacher' 
          ? 'unreadCount_student' 
          : 'unreadCount_teacher';

      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'lastMessage': text.length > 50 ? '${text.substring(0, 50)}...' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        unreadField: FieldValue.increment(1),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Get chat messages stream
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Mark messages as read
  Future<bool> markChatAsRead(String chatId, String userRole) async {
    try {
      final unreadField = userRole == 'teacher' 
          ? 'unreadCount_teacher' 
          : 'unreadCount_student';
      
      await _firestore.collection('chats').doc(chatId).update({
        unreadField: 0,
      });
      return true;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  /// Send automated zoom link message (called by admin/system)
  Future<bool> sendZoomLinkMessage({
    required String teacherId,
    required String studentId,
    required String zoomLink,
    required String meetingId,
    required String password,
  }) async {
    try {
      final chatId = _getChatId(teacherId, studentId);
      
      final message = '''🔔 Your session starts now!

Zoom Link: $zoomLink
Meeting ID: $meetingId
Password: $password

Click the link to join the session.''';

      return await sendMessage(
        chatId: chatId,
        senderId: 'system',
        senderRole: 'system',
        text: message,
        messageType: 'zoom_link',
      );
    } catch (e) {
      print('Error sending zoom link: $e');
      return false;
    }
  }

  /// Helper to create consistent chat ID
  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// ============================================
// 5️⃣ HELPER FUNCTIONS & USAGE EXAMPLES
// ============================================

/*
🔥 HOW TO USE THIS SERVICE:

1️⃣ Initialize in your app:
   final firebaseService = FirebaseService();

2️⃣ ADMIN creates a teacher:
   await firebaseService.createUser(
     email: 'teacher@school.com',
     password: 'password123',
     role: 'teacher',
     name: 'Ali Khan',
     phone: '+923001234567',
     additionalData: {
       'subjects': ['Math', 'Science'],
     },
   );

3️⃣ ADMIN creates a student:
   await firebaseService.createUser(
     email: 'student@school.com',
     password: 'password123',
     role: 'student',
     name: 'Ahmed Raza',
     phone: '+923007654321',
     additionalData: {
       'class': 'Grade 5',
       'parentPhone': '+923009876543',
       'assignedTeacherId': 'teacher_uid_here',
     },
   );

4️⃣ Teacher marks attendance:
   await firebaseService.markAttendance(
     teacherId: 'teacher_uid',
     studentId: 'student_uid',
     status: 'present',
   );

5️⃣ Get teacher's students:
   StreamBuilder<QuerySnapshot>(
     stream: firebaseService.getAssignedStudents('teacher_uid'),
     builder: (context, snapshot) {
       if (snapshot.hasData) {
         final students = snapshot.data!.docs;
         return ListView.builder(
           itemCount: students.length,
           itemBuilder: (context, index) {
             final student = students[index].data() as Map<String, dynamic>;
             return ListTile(
               title: Text(student['name']),
               subtitle: Text(student['class']),
             );
           },
         );
       }
       return CircularProgressIndicator();
     },
   );

6️⃣ Admin updates wallet:
   await firebaseService.updateTeacherWallet(
     teacherId: 'teacher_uid',
     amount: 5000,
     type: 'add',
     description: 'Monthly salary',
   );
*/