// import 'package:flutter/material.dart';
// import 'firebase_service.dart'; // <-- your service file

// class DummyInsertScreen extends StatelessWidget {
//   final firebaseService = FirebaseService();

//   DummyInsertScreen({super.key});

//   Future<void> addDummyData() async {
//     try {
//       // 1️⃣ Create Teacher
//       final teacherUid = await firebaseService.createUser(
//         email: 'teacher@school.com',
//         password: 'password123',
//         role: 'teacher',
//         name: 'Ali Khan',
//         phone: '+923001234567',
//         additionalData: {
//           'subjects': ['Math', 'Science'],
//         },
//       );

//       // 2️⃣ Create Student with teacher UID
//       await firebaseService.createUser(
//         email: 'student@school.com',
//         password: 'password123',
//         role: 'student',
//         name: 'Ahmed Raza',
//         phone: '+923007654321',
//         additionalData: {
//           'class': 'Grade 5',
//           'parentPhone': '+923009876543',
//           'assignedTeacherId': teacherUid, // teacher UID from above
//         },
//       );

//       print("Dummy data inserted successfully!");
//     } catch (e) {
//       print("Error inserting dummy data: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Insert Dummy Data")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             await addDummyData();
//           },
//           child: const Text("Insert Dummy Teacher + Student"),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:studyalquran/services/FirebaseService.dart';

class DummyScreen extends StatefulWidget {
  const DummyScreen({super.key});

  @override
  State<DummyScreen> createState() => _DummyScreenState();
}

class _DummyScreenState extends State<DummyScreen> {
  final FirebaseService firebaseService = FirebaseService();

  bool loading = false;

  Future<void> createDummyData() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Create Dummy Teacher
      final teacherResult = await firebaseService.createUser(
        email: 'teacher@school.com',
        password: 'password123',
        role: 'teacher',
        name: 'Ali Khan',
        phone: '+923001234567',
        additionalData: {
          'subjects': ['Math', 'Science'],
        },
      );

      if (!teacherResult['success']) {
        print("Teacher creation failed: ${teacherResult['message']}");
        return;
      }

      String teacherUid = teacherResult['uid'];

      // 2️⃣ Create Dummy Student with teacher UID
      final studentResult = await firebaseService.createUser(
        email: 'student@school.com',
        password: 'password123',
        role: 'student',
        name: 'Ahmed Raza',
        phone: '+923007654321',
        additionalData: {
          'class': 'Grade 5',
          'parentPhone': '+923009876543',
          'assignedTeacherId': teacherUid,
        },
      );

      if (!studentResult['success']) {
        print("Student creation failed: ${studentResult['message']}");
        return;
      }

      // SUCCESS MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dummy Teacher & Student Created Successfully!"),
        ),
      );

    } catch (e) {
      print("Error: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dummy Data Generator")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: createDummyData,
                child: const Text("Create Dummy Teacher & Student"),
              ),
      ),
    );
  }
}
