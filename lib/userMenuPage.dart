import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Pastikan file-file berikut sudah ada di folder lib Anda
import 'package:luxele/userPreOrderPage.dart';
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
  late String userRole;
  bool loadingRole = true;

  // Getter halaman agar UniqueKey() dipanggil ulang setiap kali tab diklik (untuk refresh data)
  List<Widget> get _pages => [
    UserDashboardPage(userName: widget.userName), // Index 0
    UserHistoryPage(key: UniqueKey()), // Index 1 (Riwayat Pre-Order)
    UserMenuPage(
      role: userRole,
      userId: supabase.auth.currentUser!.id,
    ), // Index 2
    const Center(child: Text("Account Page")), // Index 3
    const UserProfilePage(), // Index 4
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final user = supabase.auth.currentUser;
      final res = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', user!.id)
          .single();

      if (mounted) {
        setState(() {
          userRole = (res['role'] ?? 'customer').toString().toLowerCase();
          loadingRole = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading role: $e");
      if (mounted) {
        setState(() {
          userRole = 'customer';
          loadingRole = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pre-Orders',
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

// ==========================
// DASHBOARD HOME
// ==========================
class UserDashboardPage extends StatelessWidget {
  final String userName;
  const UserDashboardPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF8F3), Color(0xFFFFF8DC), Color(0xFFD7CCC8)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Cari roti favoritmu hari ini di Luxelle Bakery'),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// USER MENU PAGE (FITUR FILTER & PRE-ORDER)
// ==========================
class UserMenuPage extends StatefulWidget {
  final String role;
  final String userId;

  const UserMenuPage({super.key, required this.role, required this.userId});

  @override
  State<UserMenuPage> createState() => _UserMenuPageState();
}

class _UserMenuPageState extends State<UserMenuPage> {
  List<dynamic> menus = [];
  List<dynamic> filteredMenus = [];
  bool loading = true;

  String search = '';
  String category = 'All';
  String sort = 'A-Z';

  final categories = ['All', 'Bread', 'Pastry', 'Dessert', 'Cake', 'Cookies'];

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    try {
      final res = await supabase.from('menu').select();
      if (mounted) {
        setState(() {
          menus = res;
          _applyFilter();
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching menus: $e");
    }
  }

  void _applyFilter() {
    List<dynamic> result = [...menus];

    // Filter Pencarian
    if (search.isNotEmpty) {
      result = result
          .where(
            (m) => m['name'].toString().toLowerCase().contains(
              search.toLowerCase(),
            ),
          )
          .toList();
    }

    // Filter Kategori
    if (category != 'All') {
      result = result.where((m) => m['category'] == category).toList();
    }

    // Logika Sorting (Abjad & Harga)
    if (sort == 'A-Z') {
      result.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (sort == 'Z-A') {
      result.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
    } else if (sort == 'Harga Termurah') {
      result.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
    } else if (sort == 'Harga Termahal') {
      result.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
    }

    setState(() => filteredMenus = result);
  }

  Future<void> _preOrder(int menuId, String name) async {
    // Validasi Role
    if (widget.role != 'member' && widget.role != 'admin') {
      _showUpgradeDialog();
      return;
    }

    try {
      final po = await supabase
          .from('po')
          .insert({'user_id': widget.userId, 'status': 'confirmed'})
          .select()
          .single();

      await supabase.from('po_menu').insert({
        'po_id': po['id'],
        'menu_id': menuId,
        'qty': 1,
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name berhasil di-pre-order!')));
      }
    } catch (e) {
      debugPrint("Error Pre-order: $e");
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✨ Premium Only"),
        content: const Text(
          "Fitur Pre-Order hanya tersedia untuk Premium Member.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Luxelle Bakery Menu"),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search menu...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) {
                      search = v;
                      _applyFilter();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(
                            labelText: "Category",
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              category = v!;
                              _applyFilter();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sort,
                          decoration: const InputDecoration(
                            labelText: "Sort By",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'A-Z',
                              child: Text(
                                'A-Z (Abjad)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Z-A',
                              child: Text(
                                'Z-A (Abjad)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Harga Termurah',
                              child: Text(
                                'Harga Termurah',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Harga Termahal',
                              child: Text(
                                'Harga Termahal',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              sort = v!;
                              _applyFilter();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredMenus.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, i) {
                      final m = filteredMenus[i];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: m['img_url'] != null
                                  ? Image.network(
                                      m['img_url'],
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 110,
                                      color: Colors.grey,
                                      child: const Icon(Icons.cake),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    m['category'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Rp ${m['price']}",
                                    style: const TextStyle(
                                      color: Color(0xFF8D6E63),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _preOrder(m['id'], m['name']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF8D6E63,
                                        ),
                                      ),
                                      child: const Text(
                                        "Pre Order",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
