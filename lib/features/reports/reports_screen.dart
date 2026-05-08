import 'package:flutter/material.dart';
import 'package:learnyor_hrm/core/widgets/premium_widgets.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../app/theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing providers to get the latest data for employees, interns, and attendance
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    // Storing lists from providers for easier access
    final employees = employeeProvider.employees;
    final interns = internProvider.interns;
    
    // Calculating total staff count by combining both lists
    final totalStaff = employees.length + interns.length;
    
    // Getting the number of people who marked attendance for today's date
    final todayAttendance = attendanceProvider.getAttendanceForDate(DateTime.now()).length;
    
    // Calculating the total salary payout for all employees using fold (initial value 0)
    final totalSalary = employees.fold<double>(0, (sum, e) => sum + e.salary);
    
    // Calculating the total stipend payout for all interns
    final totalStipend = interns.fold<double>(0, (sum, i) => sum + i.stipend);
    
    // Formatting currency in Indian Rupees with compact notation (e.g., 10k instead of 10,000)
    final currencyFormat = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN');

    // Logic to calculate how many staff members are in each department
    final Map<String, int> deptMap = {};
    // Loop through employees and increment the count for their department
    for (var e in employees) {
      deptMap[e.department] = (deptMap[e.department] ?? 0) + 1;
    }
    // Loop through interns and increment the count for their department
    for (var i in interns) {
      deptMap[i.department] = (deptMap[i.department] ?? 0) + 1;
    }
    // Convert the map to a list and sort it by the number of staff (highest first)
    final sortedDepts = deptMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: ResponsiveWrapper(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildMainChart(),
                const SizedBox(height: 32),
                _buildMetricsGrid(currencyFormat, totalSalary, totalStipend, todayAttendance, totalStaff),
                const SizedBox(height: 40),
                _buildDepartmentSection(sortedDepts, totalStaff),
                const SizedBox(height: 40),
                _buildExportCard(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports & Analytics',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: -1),
        ),
        SizedBox(height: 8),
        Text(
          'Comprehensive statistical overview of your staff and financials',
          style: TextStyle(color: AppTheme.textMid, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMainChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withBlue(100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Engagement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Average attendance rates', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.show_chart_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 48),
          const SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(height: 0.45, label: 'Mon'),
                _Bar(height: 0.72, label: 'Tue'),
                _Bar(height: 0.88, label: 'Wed', isHighlight: true),
                _Bar(height: 0.65, label: 'Thu'),
                _Bar(height: 0.82, label: 'Fri'),
                _Bar(height: 0.35, label: 'Sat'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(NumberFormat format, double salary, double stipend, int today, int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.4,
          children: [
            _InfoCard(title: 'Total Salaries', value: format.format(salary), icon: Icons.account_balance_wallet_rounded, color: Colors.indigo),
            _InfoCard(title: 'Total Stipends', value: format.format(stipend), icon: Icons.payments_rounded, color: Colors.blue),
            _InfoCard(title: 'Present Today', value: today.toString(), icon: Icons.check_circle_rounded, color: Colors.teal),
            _InfoCard(title: 'On Leave', value: (total - today).toString(), icon: Icons.wb_sunny_rounded, color: Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildDepartmentSection(List<MapEntry<String, int>> depts, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department Distribution',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: depts.isEmpty
              ? const Center(child: Text('No data available', style: TextStyle(color: AppTheme.textMid)))
              : Column(
                  children: depts.map((entry) => _DeptTile(
                        name: entry.key,
                        count: entry.value,
                        total: total,
                      )).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildExportCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 32),
                ),
                const SizedBox(width: 24),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generate Executive Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                      SizedBox(height: 4),
                      Text('Export a complete PDF analysis of current staff and attendance', style: TextStyle(fontSize: 14, color: AppTheme.textMid)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.border, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeptTile extends StatelessWidget {
  final String name;
  final int count;
  final int total;

  const _DeptTile({required this.name, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 15)),
              Text('$count Members', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: AppTheme.border.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final String label;
  final bool isHighlight;

  const _Bar({required this.height, required this.label, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 120 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHighlight 
                ? [Colors.white, Colors.white.withOpacity(0.8)]
                : [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: isHighlight ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10)] : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: isHighlight ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: -0.5)),
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
