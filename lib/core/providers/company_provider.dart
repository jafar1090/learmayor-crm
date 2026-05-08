import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CompanyProvider extends ChangeNotifier {
  String? _name;
  String? _logoUrl;
  String? _primaryColor;
  bool _isLoading = false;

  String? get name => _name;
  String? get logoUrl => _logoUrl;
  bool get isLoading => _isLoading;

  CompanyProvider() {
    fetchCompanyInfo();
  }

  Future<void> fetchCompanyInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/company'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _name = data['name'];
        _logoUrl = data['logoUrl'];
        _primaryColor = data['primaryColor'];
      }
    } catch (e) {
      debugPrint('Error fetching company info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCompany({String? name, String? logoUrl, String? token}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/company'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (logoUrl != null) 'logoUrl': logoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _name = data['name'];
        _logoUrl = data['logoUrl'];
      } else {
        throw Exception('Failed to update company info');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
