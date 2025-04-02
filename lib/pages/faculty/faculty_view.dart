import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http; // Added missing import
import 'package:attendance/pages/faculty/Widgets/drawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceViewPage extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  final String semesterId;
  final String subjectId;
  final String subjectName;
  const AttendanceViewPage({
    required this.facultyId,
    required this.facultyName,
    required this.semesterId,
    required this.subjectId,
    required this.subjectName,
    Key? key, // Added key parameter
  }) : super(key: key);

  @override
  _AttendanceViewPageState createState() => _AttendanceViewPageState();
}

class _AttendanceViewPageState extends State<AttendanceViewPage> {
  // Added missing state variables
 String facultyName = "Loading...";
  String subjectName = "Loading...";
  String facultyId = "";
  String subjectId = "";
  String semesterId = "";
  @override
  void initState() {
    super.initState();
    print("Received params - Faculty: ${widget.facultyName}, Subject: ${widget.subjectName}");
    _loadAdditionalPreferences(); // Only load what's not passed via constructor
  }
  Future<void> _loadAdditionalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Load only additional preferences you need
    // (e.g., user settings that aren't passed via constructor)
  }
  Future<void> _loadSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      facultyId = prefs.getString('faculty_id') ?? "";
      facultyName = prefs.getString('faculty_name') ?? "Unknown Faculty";
      subjectId = prefs.getString('subject_id') ?? "";
      subjectName = prefs.getString('subject_name') ?? "Unknown Subject";
      semesterId = prefs.getString('semester_id') ?? "";
    });
  }
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _filteredData = [];
  int _totalHours = 0;
 // String facultyName = ''; // Should be initialized properly

  // Added sorting functions
  void _sortByName(int columnIndex, bool ascending) {
    setState(() {
      _filteredData.sort((a, b) => ascending
          ? a['name'].compareTo(b['name'])
          : b['name'].compareTo(a['name']));
    });
  }

  void _sortByDate(int columnIndex, bool ascending) {
    setState(() {
      _filteredData.sort((a, b) => ascending
          ? a['date'].compareTo(b['date'])
          : b['date'].compareTo(a['date']));
    });
  }

  Widget _buildDateRangeFilter() {
    return IconButton(
      icon: Icon(Icons.calendar_today),
      onPressed: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
        );
        if (range != null) {
          setState(() {
            _startDate = range.start;
            _endDate = range.end;
            _fetchAttendanceData();
          });
        }
      },
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        PopupMenuItem(value: 'name', child: Text('Sort by Name')),
        PopupMenuItem(value: 'date', child: Text('Sort by Date')),
      ],
      onSelected: (value) {
        if (value == 'name') {
          _sortByName(0, true);
        } else {
          _sortByDate(0, true);
        }
      },
    );
  }

  Widget _buildQuickFilters() {
    return Wrap(
      spacing: 8.0,
      children: [
        FilterChip(
          label: Text('Present'),
          selected: false,
          onSelected: (bool value) {
            // Implement filter by present status
          },
        ),
        FilterChip(
          label: Text('Absent'),
          selected: false,
          onSelected: (bool value) {
            // Implement filter by absent status
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceTable() {
    if (_filteredData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text("Roll No")),
          DataColumn(label: Text("Name"), onSort: _sortByName),
          DataColumn(label: Text("Date"), onSort: _sortByDate),
          DataColumn(label: Text("Hours"), numeric: true),
          DataColumn(label: Text("Status")),
        ],
        rows: _filteredData.map((record) => DataRow(
          cells: [
            DataCell(Text(record['roll_no'].toString())),
            DataCell(Text(record['name'])),
            DataCell(Text(DateFormat('dd-MMM').format(record['date']))),
            DataCell(Text(record['hours'].toString())),
            DataCell(
              Chip(
                label: Text(record['status']),
                backgroundColor: record['status'] == 'Present'
                    ? Colors.green[100]
                    : Colors.red[100],
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }

 Future<void> _fetchAttendanceData() async {
   try {
     final response = await http.post(
       Uri.parse('http://10.0.2.2/localconnect/faculty/fetch_attendance_records.php'),
       headers: {'Content-Type': 'application/json'},
       body: jsonEncode({
         'subject_id': widget.subjectId,
         'faculty_id': widget.facultyId,
         'semester_id': widget.semesterId,
         'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
         'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
       }),
     );

     print('Raw response: ${response.body}');

     final data = jsonDecode(response.body);

     if (response.statusCode == 200 && data['success'] == true) {
       setState(() {
         _filteredData = List<Map<String, dynamic>>.from(data['records'])
             .map((record) => ({
           'number': record['number'],
           'name': record['name'],
           'date': DateTime.parse(record['date']),
           'hours': record['hours'],
           'status': record['status'],
         }))
             .toList();
         _totalHours = data['total_hours'] ?? 0;
       });
     } else {
       throw Exception(data['error'] ?? 'Unknown error');
     }
   } catch (e) {
     print('Error: $e');
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error: ${e.toString()}')),
     );
   }
 }
  Future<void> _exportToPDF() async {
    // Implement PDF export functionality
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: FacultyDrawer(facultyName: widget.facultyName),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName), // Subject name from widget constructor
            Text(
              "Semester: ${widget.semesterId},Total Hours: $_totalHours",

              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          _buildDateRangeFilter(), // Your existing filter button
          _buildSortButton(),      // Your existing sort button
        ],
      ),


      body: Column(

        children: [

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildQuickFilters(),
          ),
          Expanded(child: _buildAttendanceTable()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.picture_as_pdf),
        label: Text("Export"),
        onPressed: _exportToPDF,
      ),
    );
  }
}