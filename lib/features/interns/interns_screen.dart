import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/models/intern.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/premium_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

enum InternSortType { name, date, stipend }

class InternsScreen extends StatefulWidget {
  const InternsScreen({super.key});

  @override
  State<InternsScreen> createState() => _InternsScreenState();
}

class _InternsScreenState extends State<InternsScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  InternSortType _sortType = InternSortType.name;
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InternProvider>();
    final allInterns = provider.interns;

    final departments = [
      'All',
      ...allInterns
          .map((i) => i.department)
          .where((dept) => dept.isNotEmpty)
          .toSet()
    ];

    var filteredInterns = allInterns.where((intern) {
      final matchesSearch =
          intern.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              intern.college.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDepartment == 'All' ||
          intern.department == _selectedDepartment;
      return matchesSearch && matchesDept;
    }).toList();

    filteredInterns.sort((a, b) {
      int comparison = 0;
      switch (_sortType) {
        case InternSortType.name:
          comparison = a.name.compareTo(b.name);
          break;
        case InternSortType.date:
          comparison = a.startDate.compareTo(b.startDate);
          break;
        case InternSortType.stipend:
          comparison = a.stipend.compareTo(b.stipend);
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
                    onRefresh: () => provider.fetchInterns(),
                    color: AppTheme.accent,
                    child: filteredInterns.isEmpty
                        ? const Center(
                            child: EmptyStateWidget(
                              title: 'No Interns Found',
                              message: 'Try a different search term or add a new intern.',
                              icon: Icons.school_outlined,
                            ),
                          )
                        : ResponsiveWrapper(
                            child: AnimationLimiter(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredInterns.length,
                                itemBuilder: (context, index) {
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 500),
                                    child: SlideAnimation(
                                      verticalOffset: 20.0,
                                      child: FadeInAnimation(
                                        child: _InternCard(intern: filteredInterns[index]),
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
        onPressed: () => context.push('/interns/add'),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('New Intern'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(List<String> departments) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 16 : 40, 24, isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.5))),
      ),
      child: ResponsiveWrapper(
        alignment: Alignment.centerLeft,
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
                      Text(
                        'Intern Directory', 
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: isMobile ? 24 : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(height: 4),
                        Text('Track and manage active internships', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showSortDialog,
                  icon: const Icon(Icons.tune_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.background,
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Sort & Filter',
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 32),
            if (isMobile) 
              Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search interns...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: AppTheme.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: departments.map((dept) => _buildDeptChip(dept)).toList(),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name, college or department...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        fillColor: AppTheme.background,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: departments.map((dept) => _buildDeptChip(dept)).toList(),
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

  Widget _buildDeptChip(String dept) {
    final isSelected = _selectedDepartment == dept;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isSelected ? 1.05 : 1.0,
        child: ChoiceChip(
          label: Text(dept),
          selected: isSelected,
          onSelected: (v) => setState(() => _selectedDepartment = dept),
          selectedColor: AppTheme.accent,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMid,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppTheme.accent : AppTheme.border,
              width: 1,
            ),
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
            _buildSortOption('Name', InternSortType.name),
            _buildSortOption('Joining Date', InternSortType.date),
            _buildSortOption('Stipend', InternSortType.stipend),
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

  Widget _buildSortOption(String label, InternSortType type) {
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
}

class _InternCard extends StatelessWidget {
  final Intern intern;

  const _InternCard({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(intern.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) => _showDeleteDialog(context, intern),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              icon: Icons.delete_outline_rounded,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: BentoCard(
          onTap: () => context.push('/interns/detail', extra: intern.id),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'intern_${intern.id}',
                child: PremiumImage(
                  imageUrl: ApiConfig.getFullImageUrl(intern.photoUrl),
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
                    Text(intern.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text(intern.college, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              StatusBadge(label: intern.duration, color: AppTheme.secondary),
              const SizedBox(width: 20),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Intern intern) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Remove Intern?',
        message: 'Are you sure you want to remove ${intern.name} from the internship program?',
        confirmLabel: 'Remove',
        confirmColor: AppTheme.error,
        icon: Icons.person_remove_rounded,
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<InternProvider>().deleteIntern(intern.id);
    }
  }
}

