import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import '../../core/providers/employee_provider.dart';
import '../../core/models/employee.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import 'package:intl/intl.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic>? employee;
  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  // Key to identify and validate the form
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to track and manage text input for employee fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _designationController;
  late TextEditingController _departmentController;
  late TextEditingController _salaryController;
  late TextEditingController _addressController;
  
  // State variables for joining date and profile photo
  DateTime _joiningDate = DateTime.now();
  XFile? _imageFile; // Newly selected image file
  String? _existingPhotoUrl; // Path to the current photo if editing
  bool _isEdit = false; // Flag to switch between 'Add' and 'Edit' modes

  @override
  void initState() {
    super.initState();
    // Determine if we are editing an existing employee or hiring a new one
    _isEdit = widget.employee != null;
    final emp = _isEdit ? Employee.fromMap(widget.employee!) : null;

    // Prefill controllers with existing data or leave them empty
    _nameController = TextEditingController(text: emp?.name);
    _emailController = TextEditingController(text: emp?.email);
    _phoneController = TextEditingController(text: emp?.phone);
    _designationController = TextEditingController(text: emp?.designation);
    _departmentController = TextEditingController(text: emp?.department);
    // Salary field is empty if 0, for better user experience
    _salaryController = TextEditingController(text: emp?.salary.toString() == '0' ? '' : emp?.salary.toString());
    _addressController = TextEditingController(text: emp?.address);
    _joiningDate = emp?.joiningDate ?? DateTime.now();
    _existingPhotoUrl = emp?.photoUrl;
  }

  // Opens the gallery to pick a profile picture
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile); // Trigger UI update for preview
    }
  }

  // Main save function to send data to the backend/provider
  void _save() async {
    // Check if all required fields are filled correctly
    if (!_formKey.currentState!.validate()) return;

    // Show a loading dialog so the user knows the app is working
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text('Saving Employee Details...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    String? finalPhotoUrl = _existingPhotoUrl;
    // If a new photo was picked, upload it first to get a URL
    if (_imageFile != null) {
      finalPhotoUrl = await context.read<EmployeeProvider>().uploadImage(_imageFile!);
    }

    // Creating a data model from form input
    final employee = Employee(
      id: _isEdit ? widget.employee!['id'] : null, // ID only needed for updates
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      designation: _designationController.text,
      department: _departmentController.text,
      joiningDate: _joiningDate,
      salary: double.tryParse(_salaryController.text) ?? 0,
      address: _addressController.text,
      photoUrl: finalPhotoUrl, 
    );

    // Call the appropriate provider method
    final result = _isEdit 
        ? await context.read<EmployeeProvider>().updateEmployee(employee)
        : await context.read<EmployeeProvider>().addEmployee(employee);

    if (mounted) {
      Navigator.pop(context); // Remove the loading dialog
      
      // Handle the success or failure of the operation
      result.when(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(_isEdit ? 'Employee Updated!' : 'Employee Added Successfully!'),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context); // Return to the list screen
        },
        onFailure: (exception) {
          // Notify user about the error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${exception.toString()}'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Employee Profile' : 'Hire New Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white,
                            backgroundImage: _imageFile != null 
                              ? (kIsWeb ? NetworkImage(_imageFile!.path) : FileImage(io.File(_imageFile!.path)) as ImageProvider)
                              : (_existingPhotoUrl != null && !_existingPhotoUrl!.startsWith('blob:')) 
                                  ? NetworkImage(ApiConfig.getFullImageUrl(_existingPhotoUrl)) as ImageProvider 
                                  : null,
                            child: (_imageFile == null && (_existingPhotoUrl == null || _existingPhotoUrl!.startsWith('blob:'))) 
                              ? const Icon(Icons.person_rounded, size: 70, color: AppTheme.primary) 
                              : null,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit_rounded, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(controller: _addressController, label: 'Permanent Address', icon: Icons.home_outlined, maxLines: 2),
              
              const SizedBox(height: 32),
              const Text('Employment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              _buildTextField(controller: _designationController, label: 'Designation', icon: Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildTextField(controller: _departmentController, label: 'Department', icon: Icons.work_outline_rounded),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Joining Date',
                date: _joiningDate,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, 
                    initialDate: _joiningDate, 
                    firstDate: DateTime(2010), 
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.primary,
                            onPrimary: Colors.white,
                            onSurface: AppTheme.textDark,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (d != null) setState(() => _joiningDate = d);
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _salaryController, label: 'Monthly Salary (₹)', icon: Icons.payments_outlined, keyboardType: TextInputType.number),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(_isEdit ? 'Update Profile' : 'Save Employee', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border.withOpacity(0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
