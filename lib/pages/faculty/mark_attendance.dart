// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:attendance/pages/faculty/Widgets/drawer.dart' show FacultyDrawer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String facultyName = "Loading...";
  String subjectName = "Loading...";
  String facultyId = "";
  String subjectId = "";
  String semesterId = "";
  List<Map<String, dynamic>> students = [];
  bool allAbsent = true;
  TextEditingController hoursController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  String currentTime = "";
  List<Map<String, dynamic>> filteredStudents = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    retrieveAttendanceData();
    updateTime();
    timer = Timer.periodic(Duration(seconds: 60), (timer) => updateTime());
  }

  @override
  void dispose() {
    timer?.cancel();
    hoursController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Retrieve shared data from SharedPreferences
  Future<void> retrieveAttendanceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      facultyId = prefs.getString('faculty_id') ?? "";
      facultyName = prefs.getString('faculty_name') ?? "Unknown Faculty";
      subjectId = prefs.getString('subject_id') ?? "";
      subjectName = prefs.getString('subject_name') ?? "Unknown Subject";
      semesterId = prefs.getString('semester_id') ?? "";
    });

    // Fetch students using the retrieved semester ID
    if (semesterId.isNotEmpty) {
      await fetchStudentList(semesterId);
    }
  }

  // Fetch student list with proper error handling
  Future<void> fetchStudentList(String semester) async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2/localconnect/faculty/fetch_students.php?semester=$semesterId"), // Emulator IP
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            students = data.map((student) => {
              "id": student["id"],
              "name": student["name"],
              "email": student["email"],
              "department": student["department_id"],
              "semester": student["semester"],
              "present": true,  // Default status
            }).toList();
            filteredStudents = List.from(students);
          });
        } else {
          print("No students found.");
        }
      } else {
        print("Failed to fetch students. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching students: $error");
    }
  }

  void updateTime() {
    setState(() {
      currentTime = DateFormat('hh:mm a - dd-MM-yyyy').format(DateTime.now());
    });
  }

  Future<void> saveAttendance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('attendance', jsonEncode(students));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Attendance saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> loadAttendance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('attendance');
    if (savedData != null) {
      setState(() {
        students = List<Map<String, dynamic>>.from(jsonDecode(savedData));
        filteredStudents = List.from(students);
      });
    }
  }

  void filterStudents(String query) {
    query = query.toLowerCase();
    setState(() {
      filteredStudents = students.where((student) {
        String name = student["name"].toLowerCase();
        String id = student["id"].toString();
        return name.contains(query) || id.contains(query);
      }).toList();
    });
  }

  Future<void> toggleAllAttendance() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Attendance Change"),
        content: Text(
          "Are you sure you want to mark all students as ${allAbsent ? 'Present' : 'Absent'}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),  // Cancel
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),   // Confirm
            child: Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        allAbsent = !allAbsent;
        for (var student in students) {
          student["present"] = !allAbsent;
        }
        filteredStudents = List.from(students);
      });

      await saveAttendance();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "All students marked as ${allAbsent ? 'Absent' : 'Present'}.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: FacultyDrawer(facultyName: facultyName),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(facultyName, style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: updateTime,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                // Search Bar for filtering students
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) => filterStudents(value),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: "Hours (1-6)",
                        ),
                        onChanged: (value) {
                          int? enteredValue = int.tryParse(value);
                          if (enteredValue != null &&
                              (enteredValue < 1 || enteredValue > 6)) {
                            hoursController.clear();
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Row(
                      children: [
                        Text(
                          allAbsent ? "All Absent" : "All Present",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: !allAbsent,
                          onChanged: (value) => toggleAllAttendance(),
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    currentTime,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: students.isEmpty
                      ? Center(
                    child: Text(
                      "No students found.",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      var student = filteredStudents[index];
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: student["present"]
                                ? Colors.green
                                : Colors.red,
                            child: Text(
                              "${student["id"]}",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            student["name"],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: student["present"]
                                  ? Colors.black
                                  : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              student["present"]
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: student["present"]
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                student["present"] = !student["present"];
                              });
                              saveAttendance();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Normal Save Button at the bottom (not a floating button)
      floatingActionButton: FloatingActionButton(
        onPressed: saveAttendance,
        backgroundColor: Colors.blue,
        child: Icon(Icons.save, color: Colors.white),
      ),
    );
  }
}
