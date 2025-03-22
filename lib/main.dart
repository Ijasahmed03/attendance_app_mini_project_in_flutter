import 'package:attendance/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:attendance/pages/faculty/faculty_home.dart';
import 'package:attendance/pages/faculty/mark_attendance.dart'; // Add this line
import 'package:attendance/pages/faculty/absent.dart'; // Add this line
import 'package:attendance/pages/faculty/successful.dart'; // Add this line

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        '/faculty': (context) => FacultyDashboard(),
        '/login': (context) => LoginPage(),
        '/markAttendance': (context) => AttendancePage(),
        '/absentees':
            (context) => AbsenteesPage(
              absentStudents: [],
              subjectName: 'Algorithm and Analysis',
            ),
        '/successful':
            (context) => AttendanceConfirmation(
              subjectName: 'Algorithm and Analysis',
              presentStudents: [],
              absentStudents: [],
            ),
      },
    );
  }
}
