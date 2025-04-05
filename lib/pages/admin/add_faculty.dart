import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:attendance_app/components/custom_drawer.dart';
import 'package:attendance_app/pages/admin/upload_faculty.dart';

class AddFaculty extends StatefulWidget {
  final String adminName;

  const AddFaculty({super.key, required this.adminName});

  @override
  _AddFacultyState createState() => _AddFacultyState();
}

class _AddFacultyState extends State<AddFaculty> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String? selectedDepId;
  List<Map<String, String>> departments = [];

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    String url = "http://10.0.2.2/localconnect/get_departments.php";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          departments =
              data
                  .map(
                    (item) => {
                      "depid": item["depid"].toString(),
                      "name": item["name"].toString(),
                    },
                  )
                  .toList();
          if (departments.isNotEmpty) {
            selectedDepId = departments[0]["depid"];
          }
        });
      }
    } catch (e) {
      print("Error fetching departments: $e");
    }
  }

  Future<void> addFaculty() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDepId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a department")));
      return;
    }
    String apiUrl = "http://10.0.2.2/localconnect/add_faculty.php";
    var response = await http.post(
      Uri.parse(apiUrl),
      body: {
        "name": nameController.text.trim(),
        "username": usernameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
        "department_id": selectedDepId!,
      },
    );

    try {
      var data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Faculty Added Successfully")));
        nameController.clear();
        usernameController.clear();
        emailController.clear();
        passwordController.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${data['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error parsing response")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Add Faculty",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[200],
        //actions: [IconButton(icon: Icon(Icons.logout), onPressed: () {})],
      ),
      drawer: CustomDrawer(adminName: widget.adminName),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Department",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedDepId,
                          onChanged: (value) {
                            setState(() {
                              selectedDepId = value;
                            });
                          },
                          items:
                              departments.map((dept) {
                                return DropdownMenuItem<String>(
                                  value: dept["depid"],
                                  child: Text(dept["name"]!),
                                );
                              }).toList(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "Name",
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? "Enter faculty name" : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? "Enter username" : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator:
                              (value) =>
                                  value!.isEmpty ? "Enter faculty email" : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? "Enter a strong password"
                                      : null,
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: addFaculty,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Add Faculty",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 150),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => UploadFaculty(
                            adminName: widget.adminName,
                          ), // Navigate to the new screen
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(17),
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: const Center(
                    child: Text(
                      "Upload Excel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
