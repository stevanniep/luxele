import 'package:flutter/material.dart';
import 'package:luxele/userMenuPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxele/userHistoryPage.dart';
import 'package:luxele/userProfilePage.dart';

final supabase = Supabase.instance.client;

class UserDashboardInsidePage extends StatefulWidget {
  final String userName;
  const UserDashboardInsidePage({super.key, required this.userName});

  @override
  State<UserDashboardInsidePage> createState() =>
      _UserDashboardInsidePageState();
}

class _UserDashboardInsidePageState extends State<UserDashboardInsidePage> {
  int _currentIndex = 0;
  String userRole = 'customer';
  bool loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          userRole = (res?['role'] ?? 'customer').toString().toLowerCase();
          loadingRole = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loadingRole = false);
    }
  }

  // FUNGSI NAVIGASI - Memastikan class yang benar dipanggil
  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return UserDashboardHome(userName: widget.userName);
      case 1:
        return UserHistoryPage(key: UniqueKey());
      case 2:
        // INI PERBAIKANNYA: Memanggil class UserMenuPage, bukan sekadar Text
        return UserMenuPage(
          role: userRole,
          userId: supabase.auth.currentUser?.id ?? '',
        );
      case 3:
        return const Center(child: Text("Account Page"));
      case 4:
        return UserProfilePage(key: UniqueKey());
      default:
        return UserDashboardHome(userName: widget.userName);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _getSelectedPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF8D6E63),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.cake), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- HALAMAN HOME ---
class UserDashboardHome extends StatefulWidget {
  final String userName;
  const UserDashboardHome({super.key, required this.userName});

  @override
  State<UserDashboardHome> createState() => _UserDashboardHomeState();
}

class _UserDashboardHomeState extends State<UserDashboardHome> {
  List<dynamic> featuredMenus = [];
  bool loading = true;

  String? avatarUrl;
  bool loadingAvatar = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedMenu();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          avatarUrl = res?['avatar_url'];
          loadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loadingAvatar = false);
      }
    }
  }

  Future<void> _loadFeaturedMenu() async {
    try {
      final res = await supabase
          .from('menu')
          .select()
          .limit(3)
          .order('price', ascending: false);

      if (mounted) {
        setState(() {
          featuredMenus = res;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF8F3), Color(0xFFFFF8DC), Color(0xFFD7CCC8)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // WELCOME CARD
              // =========================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF8D6E63),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back 👋',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =========================
              // QUICK ACTION
              // =========================
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _quickAction(
                    icon: Icons.cake,
                    label: 'Menu',
                    onTap: () {},
                  ),
                  _quickAction(
                    icon: Icons.receipt_long,
                    label: 'Orders',
                    onTap: () {},
                  ),
                  _quickAction(
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =========================
              // BEST SELLER MENU
              // =========================
              const Text(
                'Best Seller Menu 🍰',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              loading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: featuredMenus.map((m) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: SizedBox(
                                    height: 110,
                                    width: double.infinity,
                                    child: m['img_url'] != null
                                        ? Image.network(
                                            m['img_url'],
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.cake, size: 50),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      Text(
                                        m['name'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Rp ${m['price']}',
                                        style: const TextStyle(
                                          color: Color(0xFF8D6E63),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: const Color(0xFF8D6E63)),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
