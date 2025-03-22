import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  _AttendanceViewState createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  DateTimeRange? selectedDateRange;
  String searchQuery = "";
  bool isAscending = true;

  // Sample attendance data
  final List<Map<String, dynamic>> attendanceData = [
    {'rollNo': 1, 'name': 'Adhil', 'status': 'Present'},
    {'rollNo': 2, 'name': 'Afeef', 'status': 'Present'},
    {'rollNo': 3, 'name': 'Bulal', 'status': 'Present'},
    {'rollNo': 4, 'name': 'Chris', 'status': 'Present'},
    {'rollNo': 5, 'name': 'Deva', 'status': 'Present'},
    {'rollNo': 6, 'name': 'Gokul', 'status': 'Present'},
    {'rollNo': 7, 'name': 'Ibrahim', 'status': 'Present'},
    {'rollNo': 8, 'name': 'Joel', 'status': 'Present'},
    {'rollNo': 9, 'name': 'Pranav', 'status': 'Absent'},
  ];

  // Date Range Picker
  Future<void> pickDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  // Filter data based on search query
  List<Map<String, dynamic>> get filteredData =>
      attendanceData
          .where(
            (student) => student['name'].toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
          )
          .toList();

  // Sort the filtered data by name
  void sortByName() {
    setState(() {
      isAscending = !isAscending;
      filteredData.sort(
        (a, b) =>
            isAscending
                ? a['name'].compareTo(b['name'])
                : b['name'].compareTo(a['name']),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine number of columns based on screen width
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 2 : 1;

    return Scaffold(
      backgroundColor: Color(0xFFDFFFD7),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            SizedBox(height: 10),
            // Date Range Picker Button
            Center(
              child: ElevatedButton(
                onPressed: () => pickDateRange(context),
                child: Text(
                  selectedDateRange == null
                      ? "Select Date Range"
                      : "${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}",
                ),
              ),
            ),
            SizedBox(height: 20),
            // Sorting Option
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Sort by Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: sortByName,
                  icon: Icon(
                    isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Floating Tiles Grid View for Attendance with Vertical Overflow
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3, // Adjust tile height as needed
                ),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final student = filteredData[index];
                  bool isPresent = student['status'] == 'Present';
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Roll No displayed in a CircleAvatar
                          CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            child: Text(
                              student['rollNo'].toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          // Student Name
                          Expanded(
                            child: Text(
                              student['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Attendance Status Icon (Green for Present, Red for Absent)
                          Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: isPresent ? Colors.green : Colors.red,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
