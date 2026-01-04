import 'package:flutter/material.dart';
import 'package:luxele/adminAccountPage.dart';
import 'package:luxele/adminMenuPage.dart';
import 'package:luxele/adminPreOrdersPage.dart';
import 'package:luxele/adminProfilePage.dart';

class AdminDashboardInsidePage extends StatefulWidget {
  final String adminName;
  const AdminDashboardInsidePage({super.key, required this.adminName});

  @override
  State<AdminDashboardInsidePage> createState() =>
      _AdminDashboardInsidePageState();
}

class _AdminDashboardInsidePageState extends State<AdminDashboardInsidePage> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    AdminDashboardPage(adminName: widget.adminName),
    AdminPreOrderPage(),
    AdminMenuPage(),
    AdminAccountPage(adminName: widget.adminName),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF8D6E63),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem(Icons.dashboard, 'Dashboard', 0),
          _buildNavItem(Icons.receipt_long, 'Pre-Orders', 1),
          _buildNavItem(Icons.cake, 'Menu', 2),
          _buildNavItem(Icons.account_circle, 'Account', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: 24,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: _currentIndex == index
                  ? const Color(0xFF8D6E63)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(icon),
        ],
      ),
      label: label,
    );
  }
}

// ==========================
// DASHBOARD TAB PAGE
// ==========================
class AdminDashboardPage extends StatelessWidget {
  final String adminName;

  const AdminDashboardPage({super.key, this.adminName = 'Admin'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF8F3), Color(0xFFFFF8DC), Color(0xFFD7CCC8)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back, $adminName!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Manage all user accounts (customers, members, and admins) from here.',
                style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final state = context
                      .findAncestorStateOfType<
                        _AdminDashboardInsidePageState
                      >();
                  if (state != null) {
                    state.setState(() {
                      state._currentIndex = 3;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Manage Accounts',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
