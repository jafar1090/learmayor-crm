import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../../app/globals.dart';

class AuthProvider extends ChangeNotifier {
  // Secure storage for sensitive JWT token
  final _storage = const FlutterSecureStorage();
  
  // Current user data
  String? _userName;
  String? _userEmail;
  String? _token;
  
  // Admin's profile photo stored locally
  String? _profilePicUrl;
  
  // Flag for demo/offline access
  bool _isDemoUser = false;
  bool _isLoading = false;

  AuthProvider() {
    _loadSession();
  }

  // Getters
  String? get profilePicUrl => _profilePicUrl;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null || _isDemoUser;

  // Loads session from storage
  Future<void> _loadSession() async {
    _token = await _storage.read(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    _userEmail = prefs.getString('user_email');
    _profilePicUrl = prefs.getString('admin_photo');
    _isDemoUser = prefs.getBool('is_demo') ?? false;
    
    if (_token != null) {
      _verifyToken();
    }
    notifyListeners();
  }

  // Verify token with backend
  Future<void> _verifyToken() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode != 200) {
        logout();
      }
    } catch (e) {
      // Offline or server down - keep local session for now
    }
  }

  // Custom Login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // First attempt with a longer timeout to handle Render cold starts
      http.Response response;
      try {
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        // If it fails (likely a timeout), try one more time as the server should be waking up
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ).timeout(const Duration(seconds: 30));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _userName = data['name'];
        _userEmail = data['email'];
        
        await _storage.write(key: 'jwt_token', value: _token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _userName!);
        await prefs.setString('user_email', _userEmail!);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Server is taking too long to wake up. Please try again in a few seconds.');
      }
      rethrow;
    } finally {
      _isLoading = false;
      // We don't notify here on success to allow for Login animations
    }
  }

  void finishLogin() {
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email, String? oldPassword, String? newPassword}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (oldPassword != null) 'oldPassword': oldPassword,
          if (newPassword != null) 'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userName = data['name'];
        _userEmail = data['email'];
        _token = data['token'];
        
        await _storage.write(key: 'jwt_token', value: _token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _userName!);
        await prefs.setString('user_email', _userEmail!);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Update failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/upload'));
      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['imageUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> updateProfilePic(String url) async {
    _profilePicUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_photo', url);
    notifyListeners();
  }

  void bypassLogin() {
    _isDemoUser = true;
    notifyListeners();
  }

  // Wake up the server early to handle cold starts
  Future<void> warmup() async {
    try {
      // Just a simple GET to wake up the Render instance
      await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/verify')).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore errors, we just want to trigger the server boot
    }
  }

  Future<void> logout() async {
    _token = null;
    _userName = null;
    _userEmail = null;
    _isDemoUser = false;
    
    await _storage.delete(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('is_demo');
    
    Globals.showSnackBar('Logout Successful. See you soon!');
    notifyListeners();
  }
}
