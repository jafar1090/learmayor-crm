import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';

import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../app/globals.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'branding_screen.dart';
import 'password_reset_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.userName ?? 'Admin';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      context.read<AuthProvider>().updateProfilePic(pickedFile.path);
    }
  }

  Future<void> _performBackup() async {
    Globals.showSnackBar('Starting backup...');
    try {
      final empProvider = context.read<EmployeeProvider>();
      final intProvider = context.read<InternProvider>();
      final attProvider = context.read<AttendanceProvider>();

      await Future.wait([
        empProvider.fetchEmployees(),
        intProvider.fetchInterns(),
        attProvider.fetchAttendance(),
      ]);

      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'employees': empProvider.employees.map((e) => e.toMap()).toList(),
        'interns': intProvider.interns.map((i) => i.toMap()).toList(),
        'attendance': attProvider.attendanceRecords.map((a) => {
          'id': a.id,
          'personId': a.personId,
          'status': a.status.name,
          'date': a.date.toIso8601String(),
          'notes': a.notes,
        }).toList(),
      };
      debugPrint('BACKUP GENERATED: ${jsonEncode(backupData)}');
      Globals.showSnackBar('Backup Successful! Data exported to system logs.');
    } catch (e) {
      Globals.showSnackBar('Backup failed: $e', isError: true);
    }
  }

  Future<void> _performRestore() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      final content = utf8.decode(file.bytes!);
      jsonDecode(content);

      if (!mounted) return;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore System Data?'),
          content: const Text('This will overwrite all current employees, interns, and attendance records.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
              child: const Text('Restore Now'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      Globals.showSnackBar('Restoring system data...');
      final auth = context.read<AuthProvider>();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/system/restore'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: content,
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        await Future.wait([
          context.read<EmployeeProvider>().fetchEmployees(),
          context.read<InternProvider>().fetchInterns(),
          context.read<AttendanceProvider>().fetchAttendance(),
        ]);
        Globals.showSnackBar('System restored successfully!');
      } else {
        throw Exception('Restore failed (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) Globals.showSnackBar('Restore failed: $e', isError: true);
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool isDialogLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Profile Name'),
            content: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Admin Name'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isDialogLoading ? null : () async {
                  setDialogState(() => isDialogLoading = true);
                  try {
                    await context.read<AuthProvider>().updateProfile(name: _nameController.text.trim());
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    setDialogState(() => isDialogLoading = false);
                  }
                },
                child: isDialogLoading ? const CircularProgressIndicator() : const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(),
            
            ResponsiveWrapper(
              child: AnimationLimiter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // Profile Bento
                        _buildProfileCard(auth),
                        const SizedBox(height: 32),

                        _SectionHeader(title: 'Application'),
                        const SizedBox(height: 12),
                        _buildAppSection(),
                        const SizedBox(height: 32),

                        _SectionHeader(title: 'Security & System'),
                        const SizedBox(height: 12),
                        _buildSecuritySection(auth),
                        const SizedBox(height: 32),

                        _buildSignOut(auth),
                        const SizedBox(height: 48),
                        _buildFooter(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: ResponsiveWrapper(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: -1)),
            SizedBox(height: 4),
            Text('Manage your account and platform preferences', style: TextStyle(color: AppTheme.textMid, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthProvider auth) {
    return BentoCard(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _changePhoto(context),
            child: Stack(
              children: [
                PremiumImage(imageUrl: auth.profilePicUrl ?? '', size: 100, isCircle: true),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.userName ?? 'Admin', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(auth.userEmail ?? 'admin@learnyor.com', style: const TextStyle(color: AppTheme.textMid)),
                const SizedBox(height: 12),
                StatusBadge(label: 'ADMINISTRATOR', color: AppTheme.primary),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEditNameDialog,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection() {
    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.business_rounded,
            title: 'Company Branding',
            subtitle: 'Custom Logo, Name, and Theme',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandingScreen())),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Manage app alerts and reminders',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(AuthProvider auth) {
    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Update your admin credentials',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordResetScreen())),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            subtitle: 'Export CRM data to JSON',
            onTap: _performBackup,
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Restore Data',
            subtitle: 'Import data from a JSON backup',
            onTap: _performRestore,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOut(AuthProvider auth) {
    return BentoCard(
      padding: EdgeInsets.zero,
      child: _SettingsTile(
        icon: Icons.logout_rounded,
        title: 'Sign Out',
        subtitle: 'Safely exit your admin session',
        color: AppTheme.error,
        onTap: () => auth.logout(),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: const [
          Text('Learnyor CRM Premium', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMid)),
          Text('Version 2.0.0 • Build 2026', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMid, letterSpacing: 1.2));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: (color ?? AppTheme.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color ?? AppTheme.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? AppTheme.textDark)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}

