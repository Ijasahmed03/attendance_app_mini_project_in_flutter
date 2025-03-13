import 'package:attendance/pages/faculty/Widgets/drawer.dart' show CustomDrawer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String facultyName = "Lini Miss.";
  String subjectName = "";
  List<Map<String, dynamic>> students = [];
  bool allAbsent = true;
  TextEditingController hoursController = TextEditingController();
  String currentTime = "";

  @override
  void initState() {
    super.initState();
    fetchSubjectName();
    fetchStudentList();
    updateTime();
  }

  void fetchSubjectName() {
    setState(() {
      subjectName = "CST301 - Algorithm and Analysis";
    });
  }

  void fetchStudentList() {
    setState(() {
      students = List.generate(
        10,
        (index) => {
          "rollNumber": index + 1,
          "name": "Student ${index + 1}",
          "present": true,
        },
      );
    });
  }

  void toggleAllAttendance() {
    setState(() {
      allAbsent = !allAbsent;
      for (var student in students) {
        student["present"] = !allAbsent;
      }
    });
  }

  void updateTime() {
    setState(() {
      currentTime = DateFormat('hh:mm a - dd-MM-yyyy').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDFFFD7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
      ),
      drawer: CustomDrawer(facultyName: facultyName),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subjectName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      hintText: "Hours",
                    ),
                    onChanged: (value) {
                      int? enteredValue = int.tryParse(value);
                      if (enteredValue != null &&
                          (enteredValue < 1 || enteredValue > 6)) {
                        hoursController.text = "";
                      }
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: toggleAllAttendance,
                  child: Text(allAbsent ? "All Present" : "All Absent"),
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
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Text("${students[index]["rollNumber"]}"),
                      title: Text(students[index]["name"]),
                      trailing: Checkbox(
                        value: students[index]["present"],
                        onChanged: (value) {
                          setState(() {
                            students[index]["present"] = value!;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    Navigator.pushNamed(context, '/absentees');
                  },
                  child: Icon(Icons.arrow_forward, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
