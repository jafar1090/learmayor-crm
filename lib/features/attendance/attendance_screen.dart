import 'package:flutter/material.dart';
import 'package:learnyor_hrm/core/widgets/premium_widgets.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/empty_state_widget.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    final attendanceList = attendanceProvider.getAttendanceForDate(_selectedDate);
    // Create a map for O(1) lookup performance
    final attendanceMap = {for (var r in attendanceList) r.personId: r};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Professional Header with Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
            color: Colors.white,
            child: ResponsiveWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mark Attendance', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: AppTheme.textMid, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Change Date'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48), // Override global infinite width
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 4,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textLight,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: const [
                      Tab(text: 'EMPLOYEES'),
                      Tab(text: 'INTERNS'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceList(
                  context, 
                  employeeProvider.employees.map((e) => _AttendanceItem(id: e.id, name: e.name, designation: e.designation, photoUrl: e.photoUrl)).toList(),
                  attendanceMap,
                  attendanceProvider,
                ),
                _buildAttendanceList(
                  context, 
                  internProvider.interns.map((i) => _AttendanceItem(id: i.id, name: i.name, designation: i.college, photoUrl: i.photoUrl)).toList(),
                  attendanceMap,
                  attendanceProvider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    BuildContext context, 
    List<_AttendanceItem> items, 
    Map<String, Attendance> recordsMap,
    AttendanceProvider provider,
  ) {
    if (items.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Staff Found',
        message: 'There are no members registered in this category.',
        icon: Icons.people_outline_rounded,
      );
    }

    return ResponsiveWrapper(
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final record = recordsMap[item.id] ?? Attendance(personId: item.id, date: _selectedDate, status: AttendanceStatus.absent);
          final isPresent = record.status == AttendanceStatus.present;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BentoCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  PremiumImage(
                    imageUrl: ApiConfig.getFullImageUrl(item.photoUrl),
                    size: 48,
                    isCircle: true,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 16)),
                        Text(item.designation, style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      _StatusChip(
                        label: 'P', 
                        isSelected: record.status == AttendanceStatus.present,
                        color: AppTheme.success,
                        onTap: () => provider.markAttendance(Attendance(personId: item.id, date: _selectedDate, status: AttendanceStatus.present)),
                      ),
                      _StatusChip(
                        label: 'H', 
                        isSelected: record.status == AttendanceStatus.halfDay,
                        color: Colors.orange,
                        onTap: () => provider.markAttendance(Attendance(personId: item.id, date: _selectedDate, status: AttendanceStatus.halfDay)),
                      ),
                      _StatusChip(
                        label: 'A', 
                        isSelected: record.status == AttendanceStatus.absent,
                        color: AppTheme.error,
                        onTap: () => provider.markAttendance(Attendance(personId: item.id, date: _selectedDate, status: AttendanceStatus.absent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : AppTheme.border, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMid,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _AttendanceItem {
  final String id;
  final String name;
  final String designation;
  final String? photoUrl;
  _AttendanceItem({required this.id, required this.name, required this.designation, this.photoUrl});
}
