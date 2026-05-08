import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/intern.dart';
import '../repositories/intern_repository.dart';
import '../utils/result.dart';

class InternProvider extends ChangeNotifier {
  InternRepository _repository = InternRepository();
  // List to hold the current interns in memory
  List<Intern> _interns = [];
  // State variables for loading indicators and error messages
  bool _isLoading = false;
  String? _errorMessage;

  // Exposing state to the UI components
  List<Intern> get interns => _interns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update repository with new token
  void updateToken(String? token) {
    _repository = InternRepository(token: token);
    if (token != null) fetchInterns();
  }

  // Method to retrieve all interns from the repository
  Future<void> fetchInterns() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newInterns = await _repository.getInterns();
      _interns = newInterns;
    } catch (e) {
      _errorMessage = 'Failed to fetch interns: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handles the uploading of intern profile pictures
  Future<String?> uploadImage(XFile image) async {
    try {
      return await _repository.uploadImage(image);
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  // Method to add a new intern record
  Future<Result<void, Exception>> addIntern(Intern intern) async {
    try {
      await _repository.addIntern(intern);
      _interns.add(intern); // Update the local list
      notifyListeners();
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // Method to update an existing intern's profile
  Future<Result<void, Exception>> updateIntern(Intern intern) async {
    try {
      await _repository.updateIntern(intern);
      // Find the intern and replace with updated version
      final index = _interns.indexWhere((i) => i.id == intern.id);
      if (index != -1) {
        _interns[index] = intern;
        notifyListeners();
      }
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // Method to delete an intern from the system
  Future<Result<void, Exception>> deleteIntern(String id) async {
    try {
      await _repository.deleteIntern(id);
      // Remove from memory to reflect changes in UI instantly
      _interns.removeWhere((i) => i.id == id);
      notifyListeners();
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
