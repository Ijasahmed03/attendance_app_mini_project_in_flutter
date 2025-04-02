import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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
    Key? key,
  }) : super(key: key);

  @override
  _AttendanceViewPageState createState() => _AttendanceViewPageState();
}

class _AttendanceViewPageState extends State<AttendanceViewPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  int _subjectTotalHours = 0;
  int _filteredHours = 0;
  int _totalStudents = 0;
  int _totalDays = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _showDetailedView = false; // Toggle between views
  final Map<int, bool> _expandedStudents = {}; // Track expanded state

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _expandedStudents.clear();
    });

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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          setState(() {
            _students = (data['students'] as List).map((student) {
              // Initialize expanded state
              _expandedStudents[student['id']] = false;
              return {
                'id': student['id'],
                'number': student['number'],
                'name': student['name'],
                'attendance': (student['attendance'] as List).map((att) {
                  return {
                    'date': DateTime.parse(att['date']),
                    'hours': att['hours'],
                    'status': att['status'],
                  };
                }).toList(),
                'total_hours': student['total_hours'],
                'present_hours': student['present_hours'],
                'absent_hours': student['absent_hours'],
                'attendance_dates': student['attendance_dates'] ?? [],
              };
            }).toList();

            _subjectTotalHours = data['subject_total_hours'] ?? 0;
            _filteredHours = data['filtered_hours'] ?? 0;
            _totalStudents = data['total_students'] ?? 0;
            _totalDays = data['total_days'] ?? 0;
            _isLoading = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $_errorMessage')),
      );
    }
  }

  Widget _buildMasterView() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final attendanceRate = _totalDays > 0
            ? (student['present_hours'] / student['total_hours'] * 100).toStringAsFixed(1)
            : '0.0';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedStudents[student['id']] =
                !(_expandedStudents[student['id']] ?? false);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${student['number']}. ${student['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${student['total_hours']}h (${attendanceRate}%)',
                        style: TextStyle(
                          color: double.parse(attendanceRate) >= 75
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _totalDays > 0
                        ? student['present_hours'] / _totalDays
                        : 0,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                  ),
                  if (_expandedStudents[student['id']] ?? false) ...[
                    const SizedBox(height: 8),
                    ...student['attendance'].map<Widget>((record) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(DateFormat('dd-MMM').format(record['date'])),
                            const Spacer(),
                            Text('${record['hours']}h'),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: record['status'] == 'present'
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                record['status'].toString().toUpperCase(),
                                style: TextStyle(
                                  color: record['status'] == 'present'
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("No")),
          DataColumn(label: Text("Name")),
          DataColumn(label: Text("Total Hours"), numeric: true),
          DataColumn(label: Text("Present"), numeric: true),
          DataColumn(label: Text("Absent"), numeric: true),
          DataColumn(label: Text("Attendance %"), numeric: true),
        ],
        rows: _students.map((student) {
          final attendanceRate = _totalDays > 0
              ? (student['present_hours'] / _totalDays * 100).toStringAsFixed(1)
              : '0.0';

          return DataRow(
            cells: [
              DataCell(Text(student['number'].toString())),
              DataCell(Text(student['name'])),
              DataCell(Text(student['total_hours'].toString())),
              DataCell(Text(student['present_hours'].toString())),
              DataCell(Text(student['absent_hours'].toString())),
              DataCell(Text('$attendanceRate%')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text('Error: $_errorMessage'));
    }

    if (_students.isEmpty) {
      return const Center(child: Text('No attendance records found'));
    }

    return _showDetailedView ? _buildMasterView() : _buildTableView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Sem: ${widget.semesterId} , Total Hours: $_subjectTotalHours",
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
           
          ],
        ),
      
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAttendanceData,
          ),
          IconButton(
            icon: Icon(
              _showDetailedView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showDetailedView = !_showDetailedView;
              });
            },
            tooltip: _showDetailedView ? 'Show table view' : 'Show detailed view',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
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
                });
                _fetchAttendanceData();
              }
            },
          ),
        ],
      ),
      drawer: FacultyDrawer(facultyName: widget.facultyName),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Export"),
        onPressed: () {}, // Implement export functionality
      ),
    );
  }
}