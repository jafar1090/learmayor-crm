import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/employee.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/widgets/premium_widgets.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final String employeeId;
  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeProvider>().employees.firstWhere(
      (e) => e.id == employeeId,
      orElse: () => Employee(id: '', name: 'Not Found', email: '', phone: '', designation: '', department: '', joiningDate: DateTime.now(), salary: 0, address: ''),
    );
    
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Employee Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/employees/add', extra: employee.toMap()),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, employee),
            tooltip: 'Delete Employee',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ResponsiveWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Profile Card & Quick Actions
                    SizedBox(
                      width: 350,
                      child: Column(
                        children: [
                          _buildProfileCard(context, employee),
                          const SizedBox(height: 24),
                          _buildQuickActions(employee),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Right Column: Details & Attendance
                    Expanded(
                      child: Column(
                        children: [
                          _buildEmploymentDetails(employee, currencyFormat),
                          const SizedBox(height: 24),
                          _AttendanceSection(personId: employee.id),
                          const SizedBox(height: 24),
                          _buildContactDetails(employee),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile/Tablet Vertical Layout
                return Column(
                  children: [
                    _buildProfileCard(context, employee),
                    const SizedBox(height: 24),
                    _buildQuickActions(employee),
                    const SizedBox(height: 24),
                    _buildEmploymentDetails(employee, currencyFormat),
                    const SizedBox(height: 24),
                    _AttendanceSection(personId: employee.id),
                    const SizedBox(height: 24),
                    _buildContactDetails(employee),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Employee employee) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Hero(
            tag: 'emp_${employee.id}',
            child: PremiumImage(
              imageUrl: ApiConfig.getFullImageUrl(employee.photoUrl),
              size: 140,
              isCircle: false,
              borderRadius: 24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            employee.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            employee.designation,
            style: const TextStyle(fontSize: 16, color: AppTheme.textMid, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          StatusBadge(label: employee.department, color: AppTheme.accent),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Employee employee) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _ActionButton(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: Colors.green,
                onTap: () => _makeCall(employee.phone),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.message_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _openWhatsApp(employee.phone, employee.name),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.email_rounded,
                label: 'Email',
                color: Colors.blue,
                onTap: () => _sendEmail(employee.email),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentDetails(Employee employee, NumberFormat format) {
    return _InfoSection(
      title: 'Employment Information',
      children: [
        Row(
          children: [
            Expanded(child: DetailTile(icon: Icons.business_center_rounded, label: 'Department', value: employee.department)),
            Expanded(child: DetailTile(icon: Icons.calendar_today_rounded, label: 'Joining Date', value: DateFormat('MMM dd, yyyy').format(employee.joiningDate))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: DetailTile(icon: Icons.payments_rounded, label: 'Salary', value: format.format(employee.salary))),
            Expanded(child: DetailTile(icon: Icons.badge_rounded, label: 'Role', value: employee.designation)),
          ],
        ),
      ],
    );
  }

  Widget _buildContactDetails(Employee employee) {
    return _InfoSection(
      title: 'Contact Information',
      children: [
        DetailTile(icon: Icons.email_outlined, label: 'Email Address', value: employee.email),
        const SizedBox(height: 12),
        DetailTile(icon: Icons.phone_android_rounded, label: 'Phone Number', value: employee.phone),
        const SizedBox(height: 12),
        DetailTile(icon: Icons.location_on_outlined, label: 'Current Address', value: employee.address),
      ],
    );
  }

  void _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappUrl = Uri.parse("https://wa.me/91$cleanPhone?text=Hello $name, this is from Learnyor HRM.");
    if (await canLaunchUrl(whatsappUrl)) await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  }

  void _sendEmail(String email) async {
    final Uri url = Uri.parse('mailto:$email?subject=Regarding your Employment');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showDeleteDialog(BuildContext context, Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Delete Employee Profile?',
        message: 'Are you sure you want to remove ${employee.name}? All historical data for this employee will be permanently deleted.',
        confirmLabel: 'Delete Permanently',
        confirmColor: AppTheme.error,
        icon: Icons.delete_sweep_rounded,
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await context.read<EmployeeProvider>().deleteEmployee(employee.id);
      if (context.mounted) {
        context.pop(); // Back to list
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  final String personId;
  const _AttendanceSection({required this.personId});

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final records = attendanceProvider.getAttendanceForPerson(personId);
    
    final presentCount = records.where((r) => r.status == AttendanceStatus.present).length;
    final halfDayCount = records.where((r) => r.status == AttendanceStatus.halfDay).length;
    final absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;

    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attendance Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${records.length} Records', style: const TextStyle(color: AppTheme.textMid)),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Present', value: presentCount.toString(), color: Colors.green),
              _StatItem(label: 'Half Day', value: halfDayCount.toString(), color: Colors.orange),
              _StatItem(label: 'Absent', value: absentCount.toString(), color: Colors.red),
            ],
          ),
          if (records.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            ...records.take(5).map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(DateFormat('MMM dd, yyyy').format(record.date), style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  StatusBadge(
                    label: record.status.name.toUpperCase(),
                    color: _getStatusColor(record.status),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.halfDay: return Colors.orange;
      case AttendanceStatus.leave: return Colors.blue;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

