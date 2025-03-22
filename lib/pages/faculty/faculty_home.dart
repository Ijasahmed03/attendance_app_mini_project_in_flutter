import 'package:attendance/pages/faculty/Widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  _FacultyDashboardState createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  String facultyName = "Loading..."; // Default value
  String facultyId = "";
  String selectedSubject = "";
  List<Map<String, dynamic>> subjects = [];

  Future<void> fetchFacultyDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedFacultyName = prefs.getString('faculty_name');
    String? storedFacultyId = prefs.getString('faculty_id');

    if (storedFacultyName != null && storedFacultyId != null) {
      setState(() {
        facultyName = storedFacultyName;
        facultyId = storedFacultyId;
      });
      print("Fetched facultyId from SharedPreferences: $facultyId");
      if (facultyId.isNotEmpty) {
        fetchSubjects(); // Fetch subjects only when facultyId is available
      }
    }
  }

  Future<void> fetchSubjects() async {
    try {
      print("Calling subjects endpoint with faculty_id: $facultyId");
      final response = await http.post(
        Uri.parse('http://10.0.2.2/localconnect/faculty_subjects.php'),
        body: {'faculty_id': facultyId},
      );
      print("HTTP status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData is List) {
          setState(() {
            subjects =
                jsonData.map<Map<String, dynamic>>((subject) {
                  return {
                    "code": subject["subject_id"].toString(),
                    "title": subject["subject_name"],
                  };
                }).toList();
          });
        } else {
          print("Error fetching subjects: ${jsonData['message']}");
        }
      } else {
        print("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFacultyDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFD7),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      drawer: FacultyDrawer(facultyName: facultyName),
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
                const SizedBox(height: 10),
                Text(
                  "Your Subjects:",
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
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
                const Spacer(),
                // Buttons at the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () {
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
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.black),
                      onPressed: () {},
                      iconSize: constraints.maxWidth * 0.08,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Subject Card Widget
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
