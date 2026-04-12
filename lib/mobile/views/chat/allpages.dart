import 'package:flutter/material.dart';


class Allpages extends StatelessWidget {
  const Allpages({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> screens = [
      // {'name': 'Student', 'screen': const StudentChatListScreen()},
      // {'name': 'Student', 'screen': const ChatScreen(studentName: 'student', studentId: '12')},
      // {'name': 'Teacher', 'screen': const TeacherChatsScreen()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation Screen"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: screens.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(
                screens[index]['name'],
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => screens[index]['screen'],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
