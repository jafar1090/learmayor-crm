import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learnyor_hrm/core/widgets/premium_widgets.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../core/providers/auth_provider.dart';

class ShellLayout extends StatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumConfirmationDialog(
        title: 'Sign Out?',
        message: 'Are you sure you want to exit your professional session? You will need to sign in again to access the CRM.',
        confirmLabel: 'Sign Out',
        confirmColor: AppTheme.error,
        icon: Icons.logout_rounded,
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Row(
            children: [
              if (isDesktop)
                _NavigationSidebar(
                  isExpanded: _isExpanded,
                  onToggle: () => setState(() => _isExpanded = !_isExpanded),
                  onLogout: () => _handleLogout(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!isDesktop)
                      AppBar(
                        title: const Text('Learnyor CRM'),
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: isDesktop ? null : _MobileDrawer(onLogout: () => _handleLogout(context)),
    );
  }
}

class _NavigationSidebar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  const _NavigationSidebar({
    required this.isExpanded,
    required this.onToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 260 : 80,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _SidebarHeader(isExpanded: isExpanded),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/dashboard',
                  isExpanded: isExpanded,
                  onTap: () => context.go('/dashboard'),
                ),
                _SidebarItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Employees',
                  isSelected: location.startsWith('/employees'),
                  isExpanded: isExpanded,
                  onTap: () => context.go('/employees'),
                ),
                _SidebarItem(
                  icon: Icons.school_rounded,
                  label: 'Interns',
                  isSelected: location.startsWith('/interns'),
                  isExpanded: isExpanded,
                  onTap: () => context.go('/interns'),
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Attendance',
                  isSelected: location == '/attendance',
                  isExpanded: isExpanded,
                  onTap: () => context.go('/attendance'),
                ),
                _SidebarItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  isSelected: location == '/reports',
                  isExpanded: isExpanded,
                  onTap: () => context.go('/reports'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                _SidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: location == '/settings',
                  isExpanded: isExpanded,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          _SidebarFooter(isExpanded: isExpanded, onToggle: onToggle, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final Color? color;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Icon(
                    icon,
                    color: color ?? (isSelected ? Colors.white : Colors.white60),
                    size: 22,
                  ),
                ),
                if (isExpanded)
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color ?? (isSelected ? Colors.white : Colors.white60),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool isExpanded;

  const _SidebarHeader({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'LEARNYOR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  const _SidebarFooter({
    required this.isExpanded,
    required this.onToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isSelected: false,
            isExpanded: isExpanded,
            onTap: onLogout,
            color: Colors.redAccent.shade100,
          ),
          const SizedBox(height: 8),
          IconButton(
            icon: Icon(
              isExpanded ? Icons.keyboard_double_arrow_left_rounded : Icons.keyboard_double_arrow_right_rounded,
              color: Colors.white30,
            ),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  const _MobileDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primary),
            child: Center(
              child: Text(
                'LEARNYOR CRM',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            onTap: () => context.go('/dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: const Text('Employees'),
            onTap: () => context.go('/employees'),
          ),
          ListTile(
            leading: const Icon(Icons.school_rounded),
            title: const Text('Interns'),
            onTap: () => context.go('/interns'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Attendance'),
            onTap: () => context.go('/attendance'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Reports'),
            onTap: () => context.go('/reports'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Settings'),
            onTap: () => context.go('/settings'),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
            title: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              onLogout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
