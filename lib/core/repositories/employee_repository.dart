import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../config/api_config.dart';

class EmployeeRepository {
  final String? token;
  EmployeeRepository({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<Employee>> getEmployees() async {
    final response = await http.get(Uri.parse(ApiConfig.employeesUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Employee.fromMap(e)).toList();
    }
    throw Exception('Failed to load employees');
  }

  Future<String?> uploadImage(XFile image) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('image', await image.readAsBytes(), filename: image.name));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      return jsonDecode(respStr)['imageUrl'];
    }
    return null;
  }

  Future<void> addEmployee(Employee employee) async {
    await http.post(
      Uri.parse(ApiConfig.employeesUrl),
      headers: _headers,
      body: jsonEncode(employee.toMap()),
    );
  }

  Future<void> updateEmployee(Employee employee) async {
    await http.post(
      Uri.parse(ApiConfig.employeesUrl),
      headers: _headers,
      body: jsonEncode(employee.toMap()),
    );
  }

  Future<void> deleteEmployee(String id) async {
    await http.delete(Uri.parse('${ApiConfig.employeesUrl}/$id'), headers: _headers);
  }
}
