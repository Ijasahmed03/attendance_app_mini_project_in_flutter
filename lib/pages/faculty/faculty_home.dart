import 'package:attendance/pages/faculty/Widgets/drawer.dart';
import 'package:flutter/material.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  _FacultyDashboardState createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  String facultyName = "Lini Miss."; // Simulated database fetch
  String selectedSubject = "";
  List<Map<String, String>> subjects = []; // List to store fetched subjects

  @override
  void initState() {
    super.initState();
    fetchFacultyDetails();
  }

  void fetchFacultyDetails() {
    // Simulate fetching faculty name and subjects from database
    setState(() {
      facultyName = "Dr. John Doe"; // Replace with actual fetched name
      subjects = [
        {"code": "CST201", "title": "DATA STRUCTURES"},
        {"code": "CST301", "title": "ALGORITHM AND ANALYSIS"},
        {"code": "CST202", "title": "OBJECTIVE ORIENTED PROGRAMMING"},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDFFFD7), // Light green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
      ),
      drawer: CustomDrawer(facultyName: facultyName),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi,",
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  facultyName,
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.07,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "your subjects:",
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                // Subject List dynamically generated
                Column(
                  children:
                      subjects.map((subject) {
                        return SubjectCard(
                          subject["code"]!,
                          subject["title"]!,
                          selectedSubject,
                          (code) => setState(() => selectedSubject = code),
                        );
                      }).toList(),
                ),
                Spacer(),
                // Buttons at the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.black),
                      onPressed: () {
                        // Navigate to mark attendance page with selected subject
                        if (selectedSubject.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            '/markAttendance',
                            arguments: {'subjectCode': selectedSubject},
                          );
                        }
                      },
                      iconSize: constraints.maxWidth * 0.08,
                    ),
                    SizedBox(width: 20),
                    IconButton(
                      icon: Icon(Icons.visibility, color: Colors.black),
                      onPressed: () {},
                      iconSize: constraints.maxWidth * 0.08,
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget for displaying subject details
class SubjectCard extends StatelessWidget {
  final String code;
  final String title;
  final String selectedSubject;
  final Function(String) onSelect;

  const SubjectCard(
    this.code,
    this.title,
    this.selectedSubject,
    this.onSelect, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedSubject == code;
    return GestureDetector(
      onTap: () => onSelect(code),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: isSelected ? Colors.greenAccent : Colors.white,
        child: ListTile(
          title: Text(
            code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            title,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
