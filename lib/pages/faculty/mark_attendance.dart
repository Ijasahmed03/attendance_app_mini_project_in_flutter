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
      print("Fetching students for semester: $semester");

      final response = await http.get(
        Uri.parse("http://10.0.2.2/localconnect/faculty/fetch_students.php?semester=$semester"),
      ).timeout(Duration(seconds: 10));

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          // 1. Create base student list with null checks
          var studentList = (data['students'] as List)
              .where((s) => s['name'] != null && s['name'].toString().trim().isNotEmpty)
              .map((s) => Map<String, dynamic>.from(s)) // Create clean copy
              .toList();

          // 2. Sort alphabetically by name
          studentList.sort((a, b) => a['name'].compareTo(b['name']));

          // 3. Add roll numbers while preserving all original data
          setState(() {
            students = studentList.asMap().entries.map((entry) {
              int index = entry.key;
              var student = entry.value;
              return {
                ...student,
                'present': true, // Default attendance status
                'roll_no': index + 1, // 1-based roll number
              };
            }).toList();

            filteredStudents = List.from(students);
          });

          debugPrint('Students loaded: ${students.map((s) => '${s['roll_no']}:${s['name']}').join(', ')}');
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch students');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading students: ${e.toString().replaceAll('Exception: ', '')}"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        students = [];
        filteredStudents = [];
      });
    }
  }
  void updateTime() {
    setState(() {
      currentTime = DateFormat('hh:mm a - dd-MM-yyyy').format(DateTime.now());
    });
  }


  Future<void> saveAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final response = await http.post(
        Uri.parse('http://10.0.2.2/localconnect/faculty/save_attendance.php'),

        body: {
          'faculty_id': facultyId,
          'semester_id': semesterId,
          'subject_id': subjectId,
          'hours': hoursController.text,
          'attendance_date': DateFormat('yyyy-MM-dd').format(now),
          'students': jsonEncode(students.map((s) => {
            'id': s['id'],
            'present': s['present'],
          }).toList()),
        },
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Attendance saved to database!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to save attendance');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving attendance: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> confirmAndSaveAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Save"),
        content: const Text("Are you sure you want to save this attendance record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await saveAttendance();
    }
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

      // Only show the status change message, not the save confirmation
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
                  :ListView.builder(
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
                              "${student["roll_no"]}", // Changed from "id" to "roll_no"
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
                             // saveAttendance();
                            },
                          ),
                        ),
                      );
                    },
                  )
                ),
              ],
            ),
          ),
        ),
      ),
      // Normal Save Button at the bottom (not a floating button)
      floatingActionButton: FloatingActionButton(
        onPressed: confirmAndSaveAttendance,
        backgroundColor: Colors.blue,
        child: Icon(Icons.save, color: Colors.white),
      ),
    );
  }
}
