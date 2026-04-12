// // import 'dart:convert';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:googleapis_auth/auth_io.dart' as auth;
// // import 'package:flutter/services.dart' show rootBundle;
// // import 'package:studyalquran/mobile/views/chat/TeacherChatScreen.dart';
// // import 'package:studyalquran/mobile/views/chat/studentChatscreen.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // // Background message handler
// // @pragma('vm:entry-point')
// // Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //   debugPrint('Background message: ${message.notification?.title}');
// // }

// // class FCMService {
// //   static final FCMService _instance = FCMService._internal();
// //   factory FCMService() => _instance;
// //   FCMService._internal();

// //   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
// //   final FlutterLocalNotificationsPlugin _localNotifications = 
// //       FlutterLocalNotificationsPlugin();
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// //   String? _fcmToken;
// //   BuildContext? _context;

// //   Future<void> initialize(BuildContext context) async {
// //     _context = context;
    
// //     // Request permission
// //     NotificationSettings settings = await _fcm.requestPermission(
// //       alert: true,
// //       badge: true,
// //       sound: true,
// //       provisional: false,
// //     );

// //     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
// //       debugPrint('FCM Permission granted');
// //     }

// //     // Initialize local notifications
// //     const AndroidInitializationSettings androidSettings = 
// //         AndroidInitializationSettings('@mipmap/ic_launcher');
    
// //     const DarwinInitializationSettings iosSettings = 
// //         DarwinInitializationSettings(
// //       requestAlertPermission: true,
// //       requestBadgePermission: true,
// //       requestSoundPermission: true,
// //     );

// //     const InitializationSettings initSettings = InitializationSettings(
// //       android: androidSettings,
// //       iOS: iosSettings,
// //     );

// //     await _localNotifications.initialize(
// //       initSettings,
// //       onDidReceiveNotificationResponse: _onNotificationTapped,
// //     );

// //     // Create notification channel for Android
// //     const AndroidNotificationChannel channel = AndroidNotificationChannel(
// //       'chat_messages',
// //       'Chat Messages',
// //       description: 'Notifications for new chat messages',
// //       importance: Importance.high,
// //       playSound: true,
// //     );

// //     _localNotifications
// //         .resolvePlatformSpecificImplementation;
// //             AndroidFlutterLocalNotificationsPlugin()
// //         .createNotificationChannel(channel);

// //     // Get FCM token
// //     _fcmToken = await _fcm.getToken();
// //     debugPrint('FCM Token: $_fcmToken');

// //     // Background message handler
// //     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

// //     // Foreground messages
// //     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

// //     // When app is opened from notification
// //     FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

// //     // Check if app was opened from terminated state
// //     RemoteMessage? initialMessage = await _fcm.getInitialMessage();
// //     if (initialMessage != null) {
// //       _handleNotificationOpen(initialMessage);
// //     }
// //   }

// //   Future<void> _handleForegroundMessage(RemoteMessage message) async {
// //     debugPrint('Foreground message: ${message.notification?.title}');
    
// //     // Show local notification when app is in foreground
// //     RemoteNotification? notification = message.notification;
// //     AndroidNotification? android = message.notification?.android;

// //     if (notification != null && android != null) {
// //       await _localNotifications.show(
// //         notification.hashCode,
// //         notification.title,
// //         notification.body,
// //         NotificationDetails(
// //           android: AndroidNotificationDetails(
// //             'chat_messages',
// //             'Chat Messages',
// //             channelDescription: 'Notifications for new chat messages',
// //             importance: Importance.high,
// //             priority: Priority.high,
// //             icon: '@mipmap/ic_launcher',
// //           ),
// //           iOS: const DarwinNotificationDetails(
// //             presentAlert: true,
// //             presentBadge: true,
// //             presentSound: true,
// //           ),
// //         ),
// //         payload: jsonEncode(message.data),
// //       );
// //     }
// //   }

// //   void _handleNotificationOpen(RemoteMessage message) {
// //     if (_context == null) return;

// //     final data = message.data;
// //     final type = data['type'];
// //     final senderId = data['senderId'];
// //     final senderName = data['senderName'];
// //     final currentUserId = data['currentUserId'];
// //     final currentUserRole = data['currentUserRole'];
// //     final zoomLink = data['zoomLink'];

// //     if (type == 'zoom_link' && zoomLink != null) {
// //       _openZoomLink(zoomLink);
// //     } else if (senderId != null && senderName != null) {
// //       _openChat(senderId, senderName, currentUserId, currentUserRole);
// //     }
// //   }

// //   void _onNotificationTapped(NotificationResponse response) {
// //     if (response.payload == null || _context == null) return;

// //     final data = jsonDecode(response.payload!);
// //     final type = data['type'];
// //     final senderId = data['senderId'];
// //     final senderName = data['senderName'];
// //     final currentUserId = data['currentUserId'];
// //     final currentUserRole = data['currentUserRole'];
// //     final zoomLink = data['zoomLink'];

// //     if (type == 'zoom_link' && zoomLink != null) {
// //       _openZoomLink(zoomLink);
// //     } else if (senderId != null && senderName != null) {
// //       _openChat(senderId, senderName, currentUserId, currentUserRole);
// //     }
// //   }

// //   void _openChat(String senderId, String senderName, String currentUserId, String currentUserRole) {
// //     if (_context == null) return;

// //     if (currentUserRole == 'teacher') {
// //       Navigator.push(
// //         _context!,
// //         MaterialPageRoute(
// //           builder: (context) => TeacherChatScreen(
// //             otherUserId: senderId,
// //             otherUserName: senderName,
// //             currentUserId: currentUserId,
// //             currentUserRole: currentUserRole,
// //           ),
// //         ),
// //       );
// //     } else {
// //       Navigator.push(
// //         _context!,
// //         MaterialPageRoute(
// //           builder: (context) => StudentChatScreen(
// //             otherUserId: senderId,
// //             otherUserName: senderName,
// //             currentUserId: currentUserId,
// //             currentUserRole: currentUserRole,
// //           ),
// //         ),
// //       );
// //     }
// //   }

// //   Future<void> _openZoomLink(String url) async {
// //     final uri = Uri.parse(url);
// //     if (await canLaunchUrl(uri)) {
// //       await launchUrl(uri, mode: LaunchMode.externalApplication);
// //     }
// //   }

// //   Future<void> saveFCMToken(String userId, String role) async {
// //     if (_fcmToken == null) return;

// //     try {
// //       final collection = role == 'teacher' ? 'teachers' : 'students';
// //       await _firestore.collection(collection).doc(userId).set({
// //         'fcmToken': _fcmToken,
// //         'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
// //       }, SetOptions(merge: true));
      
// //       debugPrint('FCM Token saved for $userId');
// //     } catch (e) {
// //       debugPrint('Error saving FCM token: $e');
// //     }
// //   }

// //   Future<String?> getAccessToken() async {
// //     try {
// //       final serviceAccountJson = await rootBundle.loadString('assets/service_account.json');
// //       final accountCredentials = auth.ServiceAccountCredentials.fromJson(
// //         jsonDecode(serviceAccountJson),
// //       );

// //       final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
// //       final client = http.Client();
      
// //       try {
// //         final accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
// //           accountCredentials,
// //           scopes,
// //           client,
// //         );
// //         return accessCredentials.accessToken.data;
// //       } finally {
// //         client.close();
// //       }
// //     } catch (e) {
// //       debugPrint('Error getting access token: $e');
// //       return null;
// //     }
// //   }

// //   Future<void> sendNotification({
// //     required String recipientId,
// //     required String recipientRole,
// //     required String title,
// //     required String body,
// //     required String senderId,
// //     required String senderName,
// //     required String currentUserId,
// //     required String currentUserRole,
// //     String? zoomLink,
// //     String type = 'message',
// //   }) async {
// //     try {
// //       final collection = recipientRole == 'teacher' ? 'teachers' : 'students';
// //       final doc = await _firestore.collection(collection).doc(recipientId).get();
      
// //       if (!doc.exists) return;
      
// //       final recipientToken = doc.data()?['fcmToken'];
// //       if (recipientToken == null) return;

// //       final accessToken = await getAccessToken();
// //       if (accessToken == null) return;

// //       final projectId = 'studyalquran-4da2f'; // Replace with your Firebase project ID

// //       final response = await http.post(
// //         Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
// //         headers: {
// //           'Content-Type': 'application/json',
// //           'Authorization': 'Bearer $accessToken',
// //         },
// //         body: jsonEncode({
// //           'message': {
// //             'token': recipientToken,
// //             'notification': {
// //               'title': title,
// //               'body': body,
// //             },
// //             'data': {
// //               'type': type,
// //               'senderId': senderId,
// //               'senderName': senderName,
// //               'currentUserId': currentUserId,
// //               'currentUserRole': currentUserRole,
// //               if (zoomLink != null) 'zoomLink': zoomLink,
// //             },
// //             'android': {
// //               'priority': 'high',
// //               'notification': {
// //                 'sound': 'default',
// //                 'channelId': 'chat_messages',
// //               },
// //             },
// //             'apns': {
// //               'payload': {
// //                 'aps': {
// //                   'sound': 'default',
// //                   'badge': 1,
// //                 },
// //               },
// //             },
// //           },
// //         }),
// //       );

// //       if (response.statusCode == 200) {
// //         debugPrint('Notification sent successfully');
// //       } else {
// //         debugPrint('Failed to send notification: ${response.body}');
// //       }
// //     } catch (e) {
// //       debugPrint('Error sending notification: $e');
// //     }
// //   }
// // }

// // import 'dart:convert';
// // import 'dart:typed_data';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:studyalquran/mobile/views/chat/TeacherChatScreen.dart';
// // import 'package:studyalquran/mobile/views/chat/studentChatscreen.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:shared_preferences/shared_preferences.dart';

// // // ============================================
// // // BACKGROUND MESSAGE HANDLER
// // // ============================================
// // @pragma('vm:entry-point')
// // Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //   await Firebase.initializeApp();
// //   debugPrint('[BACKGROUND] Notification: ${message.notification?.title}');
  
// //   // Show local notification in background
// //   final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
// //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
// //     'chat_messages',
// //     'Chat Messages',
// //     channelDescription: 'Notifications for new chat messages',
// //     importance: Importance.high,
// //     priority: Priority.high,
// //     icon: '@mipmap/ic_launcher',
// //     playSound: true,
// //     sound: RawResourceAndroidNotificationSound('notification'),
// //   );
  
// //   const NotificationDetails platformDetails = NotificationDetails(
// //     android: androidDetails,
// //     iOS: DarwinNotificationDetails(
// //       presentAlert: true,
// //       presentBadge: true,
// //       presentSound: true,
// //     ),
// //   );
  
// //   await flutterLocalNotificationsPlugin.show(
// //     0,
// //     message.notification?.title,
// //     message.notification?.body,
// //     platformDetails,
// //     payload: jsonEncode(message.data),
// //   );
// // }

// // // ============================================
// // // FCM SERVICE CLASS - UPDATED & OPTIMIZED
// // // ============================================
// // class FCMService {
// //   // Singleton pattern
// //   static final FCMService _instance = FCMService._internal();
// //   factory FCMService() => _instance;
// //   FCMService._internal();

// //   // Firebase instances
// //   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
// //   final FlutterLocalNotificationsPlugin _localNotifications = 
// //       FlutterLocalNotificationsPlugin();
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// //   // Variables
// //   String? _fcmToken;
// //   BuildContext? _context;
  
// //   // ✅ FCM Server Key (Get from Firebase Console)
// //   static const String _serverKey = 'AAAAtw-abcdefghijklmnopqrstuvwxyz1234567890'; // Replace with actual key

// //   // ============================================
// //   // 1. INITIALIZE FCM SERVICE
// //   // ============================================
// //   Future<void> initialize(BuildContext context) async {
// //     _context = context;
    
// //     try {
// //       // ✅ Request permissions
// //       final NotificationSettings settings = await _fcm.requestPermission(
// //         alert: true,
// //         announcement: false,
// //         badge: true,
// //         carPlay: false,
// //         criticalAlert: false,
// //         provisional: false,
// //         sound: true,
// //       );

// //       debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

// //       // ✅ Initialize local notifications
// //       await _setupLocalNotifications();

// //       // ✅ Get and save FCM token
// //       await _getAndSaveToken();

// //       // ✅ Setup message handlers
// //       await _setupMessageHandlers();

// //       debugPrint('[FCM] ✅ Service initialized successfully');

// //     } catch (e) {
// //       debugPrint('[FCM] ❌ Initialization error: $e');
// //     }
// //   }

// //   // ============================================
// //   // 2. SAVE FCM TOKEN - BEST PRACTICE
// //   // ============================================
// //   Future<void> saveFCMToken({
// //     required String userId,
// //     required String userRole,
// //   }) async {
// //     try {
// //       // ✅ Ensure we have token
// //       if (_fcmToken == null) {
// //         _fcmToken = await _fcm.getToken();
// //         if (_fcmToken == null) {
// //           debugPrint('[FCM] ❌ No FCM token available');
// //           return;
// //         }
// //       }

// //       debugPrint('[FCM] 💾 Saving token for: $userId ($userRole)');
// //       debugPrint('[FCM] 🔑 Token: ${_fcmToken!.substring(0, 30)}...');

// //       final timestamp = FieldValue.serverTimestamp();
      
// //       // ✅ OPTION A: Save in users collection (PRIMARY)
// //       await _firestore.collection('users').doc(userId).set({
// //         'fcmToken': _fcmToken,
// //         'fcmTokenUpdatedAt': timestamp,
// //         'lastLogin': timestamp,
// //         'isOnline': true,
// //         'platform': 'mobile',
// //       }, SetOptions(merge: true));

// //       // ✅ OPTION B: Also save in role collection for backward compatibility
// //       if (userRole == 'teacher' || userRole == 'student') {
// //         await _firestore.collection('${userRole}s').doc(userId).set({
// //           'fcmToken': _fcmToken,
// //           'fcmTokenUpdatedAt': timestamp,
// //         }, SetOptions(merge: true));
// //       }

// //       // ✅ Save token locally for quick access
// //       final prefs = await SharedPreferences.getInstance();
// //       await prefs.setString('fcm_token', _fcmToken!);
// //       await prefs.setString('fcm_user_id', userId);

// //       debugPrint('[FCM] ✅ Token saved successfully');

// //       // ✅ Listen for token refresh
// //       _fcm.onTokenRefresh.listen((newToken) async {
// //         debugPrint('[FCM] 🔄 Token refreshed');
// //         _fcmToken = newToken;
        
// //         // Auto-update in Firestore
// //         await _firestore.collection('users').doc(userId).set({
// //           'fcmToken': newToken,
// //           'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
// //         }, SetOptions(merge: true));
// //       });

// //     } catch (e) {
// //       debugPrint('[FCM] ❌ Error saving token: $e');
// //     }
// //   }

// //   // ============================================
// //   // 3. SEND NOTIFICATION - OPTIMIZED VERSION
// //   // ============================================
// //   Future<void> sendNotification({
// //     required String recipientId,
// //     required String senderId,
// //     required String senderName,
// //     required String title,
// //     required String body,
// //     String type = 'chat',
// //     String? zoomLink,
// //     Map<String, dynamic>? customData,
// //   }) async {
// //     try {
// //       debugPrint('[FCM] 🚀 Sending notification to: $recipientId');

// //       // ✅ Get recipient's FCM token from Firestore
// //       final recipientDoc = await _firestore.collection('users').doc(recipientId).get();
      
// //       if (!recipientDoc.exists) {
// //         debugPrint('[FCM] ❌ Recipient not found: $recipientId');
// //         return;
// //       }

// //       final recipientToken = recipientDoc.data()?['fcmToken'];
// //       final recipientName = recipientDoc.data()?['name'] ?? 'User';

// //       if (recipientToken == null || recipientToken.isEmpty) {
// //         debugPrint('[FCM] ❌ No FCM token for: $recipientName');
// //         return;
// //       }

// //       debugPrint('[FCM] 👤 Recipient: $recipientName');
// //       debugPrint('[FCM] 🔑 Token length: ${recipientToken.length}');

// //       // ✅ Get current user data for payload
// //       final senderDoc = await _firestore.collection('users').doc(senderId).get();
// //       final currentUserRole = senderDoc.data()?['role'] ?? '';

// //       // ✅ Prepare notification payload
// //       final Map<String, dynamic> payload = {
// //         'to': recipientToken,
// //         'notification': {
// //           'title': title,
// //           'body': body,
// //           'sound': 'default',
// //           'android_channel_id': 'chat_messages',
// //           'icon': '@mipmap/ic_launcher',
// //         },
// //         'data': {
// //           'type': type,
// //           'senderId': senderId,
// //           'senderName': senderName,
// //           'senderRole': currentUserRole,
// //           'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
// //           if (zoomLink != null) 'zoomLink': zoomLink,
// //           'click_action': 'FLUTTER_NOTIFICATION_CLICK',
// //           ...?customData,
// //         },
// //         'android': {
// //           'priority': 'high',
// //           'notification': {
// //             'channel_id': 'chat_messages',
// //             'sound': 'default',
// //             'icon': '@mipmap/ic_launcher',
// //             'color': '#FF5722', // Your app color
// //           },
// //         },
// //         'apns': {
// //           'payload': {
// //             'aps': {
// //               'alert': {
// //                 'title': title,
// //                 'body': body,
// //               },
// //               'sound': 'default',
// //               'badge': 1,
// //             },
// //           },
// //           'headers': {
// //             'apns-priority': '10',
// //           },
// //         },
// //         'webpush': {
// //           'headers': {
// //             'Urgency': 'high',
// //           },
// //         },
// //       };

// //       // ✅ Send notification via FCM HTTP API
// //       final response = await http.post(
// //         Uri.parse('https://fcm.googleapis.com/fcm/send'),
// //         headers: {
// //           'Content-Type': 'application/json',
// //           'Authorization': 'key=$_serverKey',
// //         },
// //         body: jsonEncode(payload),
// //       );

// //       if (response.statusCode == 200) {
// //         debugPrint('[FCM] ✅ Notification sent to $recipientName');
        
// //         // ✅ Log notification in Firestore for analytics
// //         await _logNotification(
// //           senderId: senderId,
// //           recipientId: recipientId,
// //           title: title,
// //           body: body,
// //           type: type,
// //           status: 'sent',
// //         );
        
// //       } else {
// //         debugPrint('[FCM] ❌ Failed: ${response.statusCode}');
// //         debugPrint('[FCM] Response: ${response.body}');
        
// //         await _logNotification(
// //           senderId: senderId,
// //           recipientId: recipientId,
// //           title: title,
// //           body: body,
// //           type: type,
// //           status: 'failed',
// //           error: response.body,
// //         );
// //       }

// //     } catch (e) {
// //       debugPrint('[FCM] ❌ Send error: $e');
      
// //       // Error logging
// //       await _logNotification(
// //         senderId: senderId,
// //         recipientId: recipientId,
// //         title: title,
// //         body: body,
// //         type: type,
// //         status: 'error',
// //         error: e.toString(),
// //       );
// //     }
// //   }

// //   // ============================================
// //   // 4. CLEANUP & LOGOUT HANDLER
// //   // ============================================
// //   Future<void> cleanupOnLogout(String userId) async {
// //     try {
// //       // ✅ Remove online status
// //       await _firestore.collection('users').doc(userId).set({
// //         'isOnline': false,
// //         'lastSeen': FieldValue.serverTimestamp(),
// //       }, SetOptions(merge: true));

// //       // ✅ Clear local token (optional - keep for quick login)
// //       final prefs = await SharedPreferences.getInstance();
// //       await prefs.remove('fcm_token');
// //       await prefs.remove('fcm_user_id');

// //       // ✅ Unsubscribe from all topics
// //       await _fcm.deleteToken();
      
// //       debugPrint('[FCM] ✅ Cleanup completed for user: $userId');

// //     } catch (e) {
// //       debugPrint('[FCM] ❌ Cleanup error: $e');
// //     }
// //   }

// //   // ============================================
// //   // PRIVATE HELPER METHODS
// //   // ============================================
// //   Future<void> _setupLocalNotifications() async {
// //     const AndroidInitializationSettings androidSettings = 
// //         AndroidInitializationSettings('@mipmap/ic_launcher');
    
// //     final DarwinInitializationSettings iosSettings = 
// //         DarwinInitializationSettings(
// //       requestAlertPermission: true,
// //       requestBadgePermission: true,
// //       requestSoundPermission: true,
// //       onDidReceiveLocalNotification: (id, title, body, payload) async {},
// //     );

// //     final InitializationSettings initSettings = InitializationSettings(
// //       android: androidSettings,
// //       iOS: iosSettings,
// //     );

// //     await _localNotifications.initialize(
// //       initSettings,
// //       onDidReceiveNotificationResponse: _onNotificationTapped,
// //       onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
// //     );

// //     // Create Android notification channel
// //     final AndroidNotificationChannel channel = AndroidNotificationChannel(
// //       'chat_messages',
// //       'Chat Messages',
// //       description: 'Notifications for chat messages and alerts',
// //       importance: Importance.max,
// //       playSound: true,
// //       sound: RawResourceAndroidNotificationSound('notification'),
// //       enableVibration: true,
// //       vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
// //     );

// //     await _localNotifications
// //         .resolvePlatformSpecificImplementation<
// //             AndroidFlutterLocalNotificationsPlugin>()
// //         ?.createNotificationChannel(channel);
// //   }

// //   Future<void> _getAndSaveToken() async {
// //     _fcmToken = await _fcm.getToken();
    
// //     if (_fcmToken != null) {
// //       debugPrint('[FCM] 📱 Token: ${_fcmToken!.substring(0, 30)}...');
      
// //       // ✅ Auto-save if user already logged in
// //       final prefs = await SharedPreferences.getInstance();
// //       final savedUserId = prefs.getString('userId');
// //       final savedUserRole = prefs.getString('role');
      
// //       if (savedUserId != null && savedUserRole != null) {
// //         await saveFCMToken(userId: savedUserId, userRole: savedUserRole);
// //       }
// //     } else {
// //       debugPrint('[FCM] ⚠️ No FCM token available');
// //     }
// //   }

// //   Future<void> _setupMessageHandlers() async {
// //     // Foreground messages
// //     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

// //     // When app is opened from notification
// //     FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

// //     // Background message handler
// //     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

// //     // Check if app was opened from terminated state
// //     RemoteMessage? initialMessage = await _fcm.getInitialMessage();
// //     if (initialMessage != null) {
// //       await _handleNotificationOpen(initialMessage);
// //     }
// //   }

// //   Future<void> _handleForegroundMessage(RemoteMessage message) async {
// //     debugPrint('[FCM] 📱 Foreground message received');
    
// //     final notification = message.notification;
// //     final data = message.data;

// //     // Show local notification
// //     if (notification != null) {
// //       final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
// //         'chat_messages',
// //         'Chat Messages',
// //         channelDescription: 'Notifications for chat messages',
// //         importance: Importance.high,
// //         priority: Priority.high,
// //         icon: '@mipmap/ic_launcher',
// //         playSound: true,
// //         styleInformation: BigTextStyleInformation(
// //           notification.body ?? '',
// //           htmlFormatBigText: true,
// //           contentTitle: notification.title,
// //           htmlFormatContentTitle: true,
// //         ),
// //       );

// //       final NotificationDetails platformDetails = NotificationDetails(
// //         android: androidDetails,
// //         iOS: DarwinNotificationDetails(
// //           presentAlert: true,
// //           presentBadge: true,
// //           presentSound: true,
// //         ),
// //       );

// //       await _localNotifications.show(
// //         DateTime.now().millisecondsSinceEpoch ~/ 1000,
// //         notification.title,
// //         notification.body,
// //         platformDetails,
// //         payload: jsonEncode(data),
// //       );
// //     }
// //   }

// //   Future<void> _handleNotificationOpen(RemoteMessage message) async {
// //     if (_context == null) return;

// //     final data = message.data;
// //     final type = data['type'] ?? 'chat';
// //     final senderId = data['senderId'];
// //     final senderName = data['senderName'];
// //     final zoomLink = data['zoomLink'];

// //     debugPrint('[FCM] 👆 Notification tapped: $type');

// //     // Handle different notification types
// //     switch (type) {
// //       case 'zoom_link':
// //         if (zoomLink != null) {
// //           await _launchZoom(zoomLink);
// //         }
// //         break;
        
// //       case 'chat':
// //       case 'message':
// //         if (senderId != null && senderName != null) {
// //           await _openChatScreen(senderId, senderName);
// //         }
// //         break;
        
// //       default:
// //         debugPrint('[FCM] 📌 Unknown notification type: $type');
// //     }
// //   }

// //   void _onNotificationTapped(NotificationResponse response) {
// //     if (_context == null || response.payload == null) return;

// //     try {
// //       final data = jsonDecode(response.payload!);
// //       final type = data['type'] ?? 'chat';
// //       final senderId = data['senderId'];
// //       final senderName = data['senderName'];
// //       final zoomLink = data['zoomLink'];

// //       if (type == 'zoom_link' && zoomLink != null) {
// //         _launchZoom(zoomLink);
// //       } else if (senderId != null && senderName != null) {
// //         _openChatScreen(senderId, senderName);
// //       }
// //     } catch (e) {
// //       debugPrint('[FCM] ❌ Error parsing notification payload: $e');
// //     }
// //   }

// //   Future<void> _openChatScreen(String otherUserId, String otherUserName) async {
// //     if (_context == null) return;

// //     final prefs = await SharedPreferences.getInstance();
// //     final currentUserId = prefs.getString('userId');
// //     final currentUserRole = prefs.getString('role');

// //     if (currentUserId == null || currentUserRole == null) {
// //       debugPrint('[FCM] ❌ User not logged in');
// //       return;
// //     }

// //     // Navigate to appropriate chat screen
// //     if (currentUserRole == 'teacher') {
// //       Navigator.of(_context!).push(
// //         MaterialPageRoute(
// //           builder: (context) => TeacherChatScreen(
// //             otherUserId: otherUserId,
// //             otherUserName: otherUserName,
// //             currentUserId: currentUserId,
// //             currentUserRole: currentUserRole,
// //           ),
// //         ),
// //       );
// //     } else {
// //       Navigator.of(_context!).push(
// //         MaterialPageRoute(
// //           builder: (context) => StudentChatScreen(
// //             otherUserId: otherUserId,
// //             otherUserName: otherUserName,
// //             currentUserId: currentUserId,
// //             currentUserRole: currentUserRole,
// //           ),
// //         ),
// //       );
// //     }
// //   }

// //   Future<void> _launchZoom(String url) async {
// //     try {
// //       final uri = Uri.parse(url);
// //       if (await canLaunchUrl(uri)) {
// //         await launchUrl(uri, mode: LaunchMode.externalApplication);
// //       }
// //     } catch (e) {
// //       debugPrint('[FCM] ❌ Error launching Zoom: $e');
// //     }
// //   }

// //   Future<void> _logNotification({
// //     required String senderId,
// //     required String recipientId,
// //     required String title,
// //     required String body,
// //     required String type,
// //     required String status,
// //     String? error,
// //   }) async {
// //     try {
// //       await _firestore.collection('notification_logs').add({
// //         'senderId': senderId,
// //         'recipientId': recipientId,
// //         'title': title,
// //         'body': body,
// //         'type': type,
// //         'status': status,
// //         'error': error,
// //         'timestamp': FieldValue.serverTimestamp(),
// //         'platform': 'mobile',
// //       });
// //     } catch (e) {
// //       debugPrint('[FCM] ❌ Error logging notification: $e');
// //     }
// //   }
// // }













// import 'dart:convert';
// import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'package:googleapis_auth/auth_io.dart' as auth;
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:studyalquran/mobile/views/chat/TeacherChatScreen.dart';
// import 'package:studyalquran/mobile/views/chat/studentChatscreen.dart';
// import 'package:url_launcher/url_launcher.dart';

// // Background message handler
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint('Background message: ${message.notification?.title}');
// }

// class FCMService {
//   static final FCMService _instance = FCMService._internal();
//   factory FCMService() => _instance;
//   FCMService._internal();

//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications = 
//       FlutterLocalNotificationsPlugin();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String? _fcmToken;
//   BuildContext? _context;

//   Future<void> initialize(BuildContext context) async {
//     _context = context;
    
//     // Request permission
//     NotificationSettings settings = await _fcm.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       provisional: false,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       debugPrint('FCM Permission granted');
//     }

//     // Initialize local notifications
//     const AndroidInitializationSettings androidSettings = 
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     const DarwinInitializationSettings iosSettings = 
//         DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _localNotifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );

//     // Create notification channel for Android
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'chat_messages',
//       'Chat Messages',
//       description: 'Notifications for new chat messages',
//       importance: Importance.high,
//       playSound: true,
//     );

//     await _localNotifications
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     // Get FCM token
//     _fcmToken = await _fcm.getToken();
//     debugPrint('FCM Token: $_fcmToken');

//     // Background message handler
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     // Foreground messages
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//     // When app is opened from notification
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

//     // Check if app was opened from terminated state
//     RemoteMessage? initialMessage = await _fcm.getInitialMessage();
//     if (initialMessage != null) {
//       _handleNotificationOpen(initialMessage);
//     }
//   }

//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     debugPrint('Foreground message: ${message.notification?.title}');
    
//     // Show local notification when app is in foreground
//     RemoteNotification? notification = message.notification;
//     AndroidNotification? android = message.notification?.android;

//     if (notification != null) {
//       await _localNotifications.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'chat_messages',
//             'Chat Messages',
//             channelDescription: 'Notifications for new chat messages',
//             importance: Importance.high,
//             priority: Priority.high,
//             icon: '@mipmap/ic_launcher',
//           ),
//           iOS: const DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//           ),
//         ),
//         payload: jsonEncode(message.data),
//       );
//     }
//   }

//   void _handleNotificationOpen(RemoteMessage message) {
//     if (_context == null) return;

//     final data = message.data;
//     final type = data['type'];
//     final senderId = data['senderId'];
//     final senderName = data['senderName'];
//     final currentUserId = data['currentUserId'];
//     final currentUserRole = data['currentUserRole'];
//     final zoomLink = data['zoomLink'];

//     if (type == 'zoom_link' && zoomLink != null) {
//       _openZoomLink(zoomLink);
//     } else if (senderId != null && senderName != null) {
//       _openChat(senderId, senderName, currentUserId, currentUserRole);
//     }
//   }

//   void _onNotificationTapped(NotificationResponse response) {
//     if (response.payload == null || _context == null) return;

//     final data = jsonDecode(response.payload!);
//     final type = data['type'];
//     final senderId = data['senderId'];
//     final senderName = data['senderName'];
//     final currentUserId = data['currentUserId'];
//     final currentUserRole = data['currentUserRole'];
//     final zoomLink = data['zoomLink'];

//     if (type == 'zoom_link' && zoomLink != null) {
//       _openZoomLink(zoomLink);
//     } else if (senderId != null && senderName != null) {
//       _openChat(senderId, senderName, currentUserId, currentUserRole);
//     }
//   }

//   void _openChat(String senderId, String senderName, String currentUserId, String currentUserRole) {
//     if (_context == null) return;

//     if (currentUserRole == 'teacher') {
//       Navigator.push(
//         _context!,
//         MaterialPageRoute(
//           builder: (context) => TeacherChatScreen(
//             otherUserId: senderId,
//             otherUserName: senderName,
//             currentUserId: currentUserId,
//             currentUserRole: currentUserRole,
//           ),
//         ),
//       );
//     } else {
//       Navigator.push(
//         _context!,
//         MaterialPageRoute(
//           builder: (context) => StudentChatScreen(
//             otherUserId: senderId,
//             otherUserName: senderName,
//             currentUserId: currentUserId,
//             currentUserRole: currentUserRole,
//           ),
//         ),
//       );
//     }
//   }

//   Future<void> _openZoomLink(String url) async {
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }

//   // ✅ FIXED: Ab sirf 'users' collection se token save karta hai
//   Future<void> saveFCMToken(String userId) async {
//     if (_fcmToken == null) {
//       debugPrint('FCM Token is null, cannot save');
//       return;
//     }

//     try {
//       // ✅ Sirf 'users' collection mein save karo
//       await _firestore.collection('users').doc(userId).set({
//         'fcmToken': _fcmToken,
//         'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
      
//       debugPrint('✅ FCM Token saved successfully for user: $userId');
//     } catch (e) {
//       debugPrint('❌ Error saving FCM token: $e');
//     }
//   }

//   // ✅ Access token generation (OAuth2 se)
//   Future<String?> getAccessToken() async {
//     try {
//       final serviceAccountJson = await rootBundle.loadString('assets/service_account.json');
//       final accountCredentials = auth.ServiceAccountCredentials.fromJson(
//         jsonDecode(serviceAccountJson),
//       );

//       final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
//       final client = http.Client();
      
//       try {
//         final accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
//           accountCredentials,
//           scopes,
//           client,
//         );
//         debugPrint('✅ Access token obtained successfully');
//         return accessCredentials.accessToken.data;
//       } finally {
//         client.close();
//       }
//     } catch (e) {
//       debugPrint('❌ Error getting access token: $e');
//       return null;
//     }
//   }

//   // ✅ FIXED: Ab 'users' collection se FCM token lega
//   Future<void> sendNotification({
//     required String recipientId,
//     required String title,
//     required String body,
//     required String senderId,
//     required String senderName,
//     required String currentUserId,
//     required String currentUserRole,
//     String? zoomLink,
//     String type = 'message',
//   }) async {
//     try {
//       // ✅ 'users' collection se recipient ka FCM token lo
//       final doc = await _firestore.collection('users').doc(recipientId).get();
      
//       if (!doc.exists) {
//         debugPrint('❌ User document not found for recipientId: $recipientId');
//         return;
//       }
      
//       final recipientToken = doc.data()?['fcmToken'];
//               print('fcmtoken1  $recipientToken   ');
//       if (recipientToken == null || recipientToken.toString().isEmpty) {
//         debugPrint('❌ FCM Token not found for user: $recipientId');
//         return;
//       }
//               print('fcmtoken2  $recipientToken');

//       debugPrint('✅ Recipient FCM Token found: ${recipientToken.toString().substring(0, 20)}...');

//       // Get access token
//       final accessToken = await getAccessToken();
//               print('access token ye he   $accessToken');

//       if (accessToken == null) {
//         print('❌ Failed to get access token');
//         return;
//       }

//       // ✅ Replace with your actual Firebase project ID
//       final projectId = 'studyalquran-4da2f';

//       final response = await http.post(
//         Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $accessToken',
//         },
//         body: jsonEncode({
//           'message': {
//             'token': recipientToken,
//             'notification': {
//               'title': title,
//               'body': body,
//             },
//             'data': {
//               'type': type,
//               // 'senderId': senderId,
//               'senderName': senderName,
//               // 'currentUserId': currentUserId,
//               'currentUserRole': currentUserRole,
//               if (zoomLink != null) 'zoomLink': zoomLink,
//             },
//             'android': {
//               'priority': 'high',
//               'notification': {
//                 'sound': 'default',
//                 'channelId': 'chat_messages',
//               },
//             },
//             'apns': {
//               'payload': {
//                 'aps': {
//                   'sound': 'default',
//                   'badge': 1,
//                 },
//               },
//             },
//           },
//         }),
//       );

//       if (response.statusCode == 200) {
//         print('✅ Notification sent successfully to $recipientId');
//       } else {
//         print('❌ Failed to send notification: ${response.statusCode}');
//     print('Response body: ${response.body}');
//       }
//     } catch (e) {
//       debugPrint('❌ Error sending notification: $e');
//     }
//   }
// }