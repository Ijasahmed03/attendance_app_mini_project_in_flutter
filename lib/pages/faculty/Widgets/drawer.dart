// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:attendance/pages/faculty/faculty_home.dart';
import 'package:attendance/pages/login_page.dart';
import 'package:attendance/pages/faculty/mark_attendance.dart'; // Add this line

class FacultyDrawer extends StatelessWidget {
  final String facultyName;

  const FacultyDrawer({super.key, required this.facultyName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.greenAccent),
            child: Text(
              facultyName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Dashboard"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/faculty');
            },
          ),

          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Logged Out")));
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
