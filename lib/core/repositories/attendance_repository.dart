import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance.dart';
import '../config/api_config.dart';

class AttendanceRepository {
  final String? token;
  AttendanceRepository({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<Attendance>> getAttendance() async {
    final response = await http.get(Uri.parse(ApiConfig.attendanceUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((a) => Attendance.fromMap(a)).toList();
    } else {
      throw Exception('Failed to load attendance');
    }
  }

  Future<void> markAttendance(Attendance attendance) async {
    final response = await http.post(
      Uri.parse(ApiConfig.attendanceUrl),
      headers: _headers,
      body: jsonEncode(attendance.toMap()),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to mark attendance');
    }
  }
}
