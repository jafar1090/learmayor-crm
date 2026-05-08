import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/attendance.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/company_provider.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final company = context.watch<CompanyProvider>();

    final employeeCount = employeeProvider.employees.length;
    final internCount = internProvider.interns.length;
    final totalStaff = employeeCount + internCount;

    final todayAttendance = attendanceProvider.getAttendanceForDate(DateTime.now())
        .where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.halfDay)
        .length;

    final attendancePercent = totalStaff > 0 ? todayAttendance / totalStaff : 0.0;

    final recentActivity = [
      ...employeeProvider.employees.map((e) => {'name': e.name, 'role': e.designation, 'type': 'Employee', 'date': e.joiningDate}),
      ...internProvider.interns.map((i) => {'name': i.name, 'role': 'Intern - ${i.college}', 'type': 'Intern', 'date': i.joiningDate}),
    ];
    recentActivity.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final displayActivity = recentActivity.take(8).toList();
    final isLoading = employeeProvider.isLoading || internProvider.isLoading || attendanceProvider.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: ResponsiveWrapper(
              maxWidth: 1400,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20),
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 20.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildHeader(context, company, isDesktop),
                        const SizedBox(height: 40),
                        
                        // Summary Cards Row
                        _buildSummarySection(attendancePercent, todayAttendance, totalStaff, employeeCount, internCount, isDesktop),
                        const SizedBox(height: 32),
                        
                        // Recent Joinings
                        _RecentActivityCard(displayActivity: displayActivity, isLoading: isLoading),
                        
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CompanyProvider company, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()},',
              style: const TextStyle(color: AppTheme.textMid, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              company.name ?? 'Learnyor CRM',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: -1),
            ),
          ],
        ),
        if (isDesktop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummarySection(double percent, int present, int total, int emps, int interns, bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _ProgressCard(label: "Today's Presence", percent: percent, count: "$present / $total")),
          const SizedBox(width: 24),
          Expanded(child: _DashboardStatCard(title: 'Total Employees', value: emps.toString(), icon: Icons.people_alt_rounded, color: AppTheme.primary, onTap: () {})),
          const SizedBox(width: 24),
          Expanded(child: _DashboardStatCard(title: 'Active Interns', value: interns.toString(), icon: Icons.school_rounded, color: Colors.indigo, onTap: () {})),
        ],
      );
    }
    return Column(
      children: [
        _ProgressCard(label: "Today's Presence", percent: percent, count: "$present / $total"),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _DashboardStatCard(title: 'Employees', value: emps.toString(), icon: Icons.people_alt_rounded, color: AppTheme.primary, onTap: () {})),
            const SizedBox(width: 16),
            Expanded(child: _DashboardStatCard(title: 'Interns', value: interns.toString(), icon: Icons.school_rounded, color: Colors.indigo, onTap: () {})),
          ],
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardStatCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const Icon(Icons.trending_up_rounded, color: Colors.teal, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: -1)),
          Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textMid, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final double percent;
  final String count;

  const _ProgressCard({required this.label, required this.percent, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      ),
                      FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 10)],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(value * 100).toInt()}% marked for today',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> displayActivity;
  final bool isLoading;

  const _RecentActivityCard({required this.displayActivity, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Text('Recent Joinings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
          if (isLoading)
            _buildActivityShimmer()
          else if (displayActivity.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('No activity yet', style: TextStyle(color: AppTheme.textLight))))
          else
            ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayActivity.length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.divider, height: 1, indent: 92),
              itemBuilder: (context, index) {
                final activity = displayActivity[index];
                return _ActivityTile(name: activity['name'] as String, sub: activity['role'] as String, type: activity['type'] as String);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemBuilder: (context, index) => const ListTile(
        leading: ShimmerLoading(width: 48, height: 48, borderRadius: 24),
        title: ShimmerLoading(width: 150, height: 16),
        subtitle: Padding(padding: EdgeInsets.only(top: 8), child: ShimmerLoading(width: 100, height: 12)),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String name;
  final String sub;
  final String type;

  const _ActivityTile({required this.name, required this.sub, required this.type});

  @override
  Widget build(BuildContext context) {
    final isIntern = type == 'Intern';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (isIntern ? Colors.indigo : AppTheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(isIntern ? Icons.school_rounded : Icons.person_rounded, size: 24, color: isIntern ? Colors.indigo : AppTheme.primary),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.border),
    );
  }
}

