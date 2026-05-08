class ApiConfig {
  // Production Render Backend URL
  static const String baseUrl = 'https://learnyor-backend.onrender.com';


  static const String employeesUrl = '$baseUrl/employees';
  static const String internsUrl = '$baseUrl/interns';
  static const String attendanceUrl = '$baseUrl/attendance';
  static const String uploadUrl = '$baseUrl/upload';

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path; // Already a full URL
    return '$baseUrl$path';
  }
}
