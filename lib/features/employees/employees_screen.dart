import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/models/employee.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/premium_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

enum EmployeeSortType { name, designation, salary }

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  EmployeeSortType _sortType = EmployeeSortType.name;
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final allEmployees = provider.employees;
    
    final departments = [
      'All', 
      ...allEmployees
          .map((e) => e.department)
          .where((dept) => dept.isNotEmpty)
          .toSet()
    ];
    
    var filteredEmployees = allEmployees.where((emp) {
      final matchesSearch = emp.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           emp.designation.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDepartment == 'All' || emp.department == _selectedDepartment;
      return matchesSearch && matchesDept;
    }).toList();

    filteredEmployees.sort((a, b) {
      int comparison = 0;
      switch (_sortType) {
        case EmployeeSortType.name:
          comparison = a.name.compareTo(b.name);
          break;
        case EmployeeSortType.designation:
          comparison = a.designation.compareTo(b.designation);
          break;
        case EmployeeSortType.salary:
          comparison = a.salary.compareTo(b.salary);
          break;
      }
      return _isAscending ? comparison : -comparison;
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(departments),
          Expanded(
            child: provider.isLoading 
              ? _buildShimmerList()
              : RefreshIndicator(
                  onRefresh: () => provider.fetchEmployees(),
                  color: AppTheme.accent,
                  child: filteredEmployees.isEmpty
                      ? const Center(
                          child: EmptyStateWidget(
                            title: 'No Employees Found',
                            message: 'Try a different search term or add a new employee.',
                            icon: Icons.people_outline_rounded,
                          ),
                        )
                      : ResponsiveWrapper(
                          child: AnimationLimiter(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredEmployees.length,
                              itemBuilder: (context, index) {
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 500),
                                  child: SlideAnimation(
                                    verticalOffset: 20.0,
                                    child: FadeInAnimation(
                                      child: _buildEmployeeCard(context, filteredEmployees[index]),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employees/add'),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Add Employee'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(List<String> departments) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      color: Colors.white,
      child: ResponsiveWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Employees', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Manage your team and their roles', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                IconButton(
                  onPressed: _showSortDialog,
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort Employees',
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, role or department...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: departments.map((dept) {
                        final isSelected = _selectedDepartment == dept;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(dept),
                            selected: isSelected,
                            onSelected: (v) => setState(() => _selectedDepartment = dept),
                            selectedColor: AppTheme.accent,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textMid,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Employee emp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(emp.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) => _showDeleteDialog(context, emp),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              icon: Icons.delete_outline_rounded,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: BentoCard(
          onTap: () => context.push('/employees/detail', extra: emp.id),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'emp_${emp.id}',
                child: PremiumImage(
                  imageUrl: ApiConfig.getFullImageUrl(emp.photoUrl),
                  size: 64,
                  isCircle: false,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text(emp.designation, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              StatusBadge(label: emp.department, color: AppTheme.accent),
              const SizedBox(width: 20),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: BentoCard(
          child: Row(
            children: [
              const ShimmerLoading(width: 64, height: 64, borderRadius: 16),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(width: 150, height: 18),
                    const SizedBox(height: 8),
                    ShimmerLoading(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildSortOption('Name', EmployeeSortType.name),
            _buildSortOption('Designation', EmployeeSortType.designation),
            _buildSortOption('Salary', EmployeeSortType.salary),
            const Divider(height: 40),
            SwitchListTile(
              title: const Text('Ascending Order'),
              value: _isAscending,
              onChanged: (v) {
                setState(() => _isAscending = v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, EmployeeSortType type) {
    final isSelected = _sortType == type;
    return ListTile(
      onTap: () {
        setState(() => _sortType = type);
        Navigator.pop(context);
      },
      leading: Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? AppTheme.accent : AppTheme.textLight),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
    );
  }

  void _showDeleteDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to remove ${employee.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await context.read<EmployeeProvider>().deleteEmployee(employee.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

