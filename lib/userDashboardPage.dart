import 'package:flutter/material.dart';
import 'package:luxele/userMenuPage.dart';
import 'package:luxele/userPreOrderPage.dart';
import 'package:luxele/userProfilePage.dart';

class UserDashboardInsidePage extends StatefulWidget {
  final String userName;
  const UserDashboardInsidePage({super.key, required this.userName});

  @override
  State<UserDashboardInsidePage> createState() =>
      _UserDashboardInsidePageState();
}

class _UserDashboardInsidePageState extends State<UserDashboardInsidePage> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    UserDashboardPage(userName: widget.userName),
    UserProfilePage(),
    UserMenuPage(),
    UserProfilePage(),
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
class UserDashboardPage extends StatelessWidget {
  final String userName;

  const UserDashboardPage({super.key, this.userName = 'User'});

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
                'Welcome back, $userName!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
