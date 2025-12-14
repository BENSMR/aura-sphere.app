import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/role_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/access_control_service.dart';
import '../tasks/tasks_list_screen.dart';
import '../expenses/expense_scanner_screen.dart';

/// Employee Mobile Dashboard
/// 
/// Shows 6 features available to employees:
/// - Assigned Tasks
/// - Log Expense (Camera)
/// - View Clients (Read-Only)
/// - Mark Job Complete (+ Photo)
/// - Profile (Name, Role, Logout)
/// - Sync Status (Offline indicator)

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${user.firstName} ${user.lastName}'),
            elevation: 0,
          ),
          body: _buildEmployeePage(_selectedIndex, user),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt),
                label: 'Expense',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Clients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployeePage(int index, dynamic user) {
    switch (index) {
      case 0:
        // Assigned Tasks
        return const TasksListScreen();

      case 1:
        // Log Expense (Camera-first)
        return const ExpenseScannerScreen();

      case 2:
        // View Clients (Read-Only)
        return _buildClientsView();

      case 3:
        // Mark Job Complete + Photo
        return _buildJobsCompletionView();

      case 4:
        // Profile
        return _buildProfileView(user);

      default:
        return const SizedBox();
    }
  }

  Widget _buildClientsView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Clients'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'View Clients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Client list will appear here (read-only)',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to clients view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to clients...')),
                );
              },
              child: const Text('Browse Clients'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsCompletionView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Jobs'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Mark Job Complete',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'View assigned jobs and mark as complete with photo',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening jobs list...')),
                );
              },
              child: const Text('View Jobs'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(dynamic user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: user.avatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Chip(
                        label: const Text('Employee'),
                        backgroundColor: Colors.blue[100],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info Section
              Text(
                'Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildInfoTile('Email', user.email),
              _buildInfoTile('Role', 'Employee'),
              _buildInfoTile('Status', 'Active'),

              const SizedBox(height: 24),

              // Permissions Section
              Text(
                'Permissions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._buildPermissionsList(),

              const SizedBox(height: 24),

              // Sync Status
              Text(
                'Sync Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done, color: Colors.green),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Online'),
                          Text(
                            'Last synced: just now',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              ElevatedButton(
                onPressed: () => _showLogoutDialog(context, userProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  List<Widget> _buildPermissionsList() {
    final features = Features.employeeMobileFeatures;
    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Text(feature.featureName),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await userProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}
