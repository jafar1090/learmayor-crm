import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io' as io;
import '../../core/providers/intern_provider.dart';
import '../../core/models/intern.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';

class AddEditInternScreen extends StatefulWidget {
  final Map<String, dynamic>? intern;
  const AddEditInternScreen({super.key, this.intern});

  @override
  State<AddEditInternScreen> createState() => _AddEditInternScreenState();
}

class _AddEditInternScreenState extends State<AddEditInternScreen> {
  // Form key for validation and global access
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to manage the text input for various fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _collegeController;
  late TextEditingController _departmentController;
  late TextEditingController _stipendController;
  late TextEditingController _mentorController;
  
  // State variables for dates, images, and form status
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90)); // Default 3 months internship
  XFile? _imageFile; // To store newly picked image
  String? _existingPhotoUrl; // To store photo URL if editing
  bool _isEdit = false; // Flag to check if we are in edit mode
  bool _certificateIssued = false; // Checkbox state

  @override
  void initState() {
    super.initState();
    // Checking if an intern object was passed to the widget (Edit mode)
    _isEdit = widget.intern != null;
    final intern = _isEdit ? Intern.fromMap(widget.intern!) : null;

    // Initializing controllers with existing data or empty strings
    _nameController = TextEditingController(text: intern?.name);
    _emailController = TextEditingController(text: intern?.email);
    _phoneController = TextEditingController(text: intern?.phone);
    _collegeController = TextEditingController(text: intern?.college);
    _departmentController = TextEditingController(text: intern?.department);
    // If stipend is 0 (new intern), keep the field empty for better UX
    _stipendController = TextEditingController(text: intern?.stipend.toString() == '0' ? '' : intern?.stipend.toString());
    _mentorController = TextEditingController(text: intern?.mentor);
    
    // Setting dates and photo from the existing intern object
    _startDate = intern?.startDate ?? DateTime.now();
    _endDate = intern?.endDate ?? DateTime.now().add(const Duration(days: 90));
    _existingPhotoUrl = intern?.photoUrl;
    _certificateIssued = intern?.certificateIssued ?? false;
  }

  // Function to open gallery and pick an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile); // Update UI to show preview
    }
  }

  // Main function to save or update the intern data
  void _save() async {
    // Validate all form fields first
    if (!_formKey.currentState!.validate()) return;

    // Show a non-dismissible loading dialog while processing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.secondary),
                SizedBox(height: 16),
                Text('Saving Intern Details...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    String? finalPhotoUrl = _existingPhotoUrl;
    // If a new image was picked, upload it and get the new URL
    if (_imageFile != null) {
      finalPhotoUrl = await context.read<InternProvider>().uploadImage(_imageFile!);
    }

    // Creating a new Intern object with the form data
    final intern = Intern(
      id: _isEdit ? widget.intern!['id'] : null, // ID is required only for updates
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      college: _collegeController.text,
      department: _departmentController.text,
      startDate: _startDate,
      endDate: _endDate,
      stipend: double.tryParse(_stipendController.text) ?? 0,
      mentor: _mentorController.text,
      photoUrl: finalPhotoUrl,
      certificateIssued: _certificateIssued,
    );

    // Call either update or add based on the mode
    final result = _isEdit 
        ? await context.read<InternProvider>().updateIntern(intern)
        : await context.read<InternProvider>().addIntern(intern);

    if (mounted) {
      Navigator.pop(context); // Close the loading dialog
      
      // Handle the result using the Result pattern
      result.when(
        onSuccess: (_) {
          // Success feedback to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(_isEdit ? 'Intern Updated!' : 'Intern Added Successfully!'),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context); // Go back to the previous screen
        },
        onFailure: (exception) {
          // Error feedback to the user
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
        title: Text(_isEdit ? 'Edit Intern Profile' : 'Register New Intern', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.secondary,
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
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.secondary.withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageFile != null 
                          ? (kIsWeb ? NetworkImage(_imageFile!.path) : FileImage(io.File(_imageFile!.path)) as ImageProvider)
                          : (_existingPhotoUrl != null && !_existingPhotoUrl!.startsWith('blob:')) 
                              ? NetworkImage(ApiConfig.getFullImageUrl(_existingPhotoUrl)) as ImageProvider 
                              : null,
                        child: (_imageFile == null && (_existingPhotoUrl == null || _existingPhotoUrl!.startsWith('blob:'))) 
                          ? const Icon(Icons.person_rounded, size: 60, color: AppTheme.secondary) 
                          : null,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
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
              _buildTextField(controller: _collegeController, label: 'College / Institution', icon: Icons.school_outlined),
              
              const SizedBox(height: 32),
              const Text('Internship Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              _buildTextField(controller: _departmentController, label: 'Department / Domain', icon: Icons.work_outline_rounded),
              const SizedBox(height: 16),
              _buildTextField(controller: _mentorController, label: 'Assigned Mentor', icon: Icons.person_pin_rounded),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (d != null) {
                          setState(() {
                            _startDate = d;
                            // Optionally recalculate end date if needed
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (d != null) setState(() => _endDate = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Quick Select Duration:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMid)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 6].map((months) {
                  return ChoiceChip(
                    label: Text('$months ${months == 1 ? 'Month' : 'Months'}', style: const TextStyle(fontSize: 12)),
                    selected: false,
                    onSelected: (_) {
                      setState(() {
                        // Calculate end date based on start date + months
                        _endDate = DateTime(_startDate.year, _startDate.month + months, _startDate.day);
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.secondary.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppTheme.secondary.withOpacity(0.3)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _stipendController, label: 'Monthly Stipend (₹)', icon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
              
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                ),
                child: CheckboxListTile(
                  title: const Text('Certificate Issued', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  value: _certificateIssued,
                  onChanged: (v) => setState(() => _certificateIssued = v!),
                  activeColor: AppTheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(_isEdit ? 'UPDATE PROFILE' : 'REGISTER INTERN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.secondary, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border.withOpacity(0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.secondary, width: 2)),
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
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.secondary),
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
