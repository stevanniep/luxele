import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// PASTIKAN SEMUA IMPORT INI ADA DAN BENAR
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
        AdminPreOrderPage(key: UniqueKey()),
        const AdminMenuPage(),
        AdminAccountPage(adminName: widget.adminName),
        AdminProfilePage(key: UniqueKey()),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: const Color(0xFF8D6E63),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cake),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  final String adminName;
  const AdminDashboardPage({super.key, required this.adminName});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  late DateTime _selectedDate = DateTime.now();
  int totalOrders = 0;
  int totalMenus = 0;
  int totalUsers = 0;
  double todaysRevenue = 0.0;
  bool loading = true;
  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> bestSellerMenus = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => loading = true);
    try {
      await Future.wait([
        _loadTotalOrders(),
        _loadTotalMenus(),
        _loadTotalUsers(),
        _loadTodaysRevenue(),
        _loadRecentOrders(),
        _loadBestSellers(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadTotalOrders() async {
    final res = await supabase
        .from('purchase_order')
        .select('id')
        .count();
    totalOrders = res.count ?? 0;
  }

  Future<void> _loadTotalMenus() async {
    final res = await supabase
        .from('menu')
        .select('id')
        .count();
    totalMenus = res.count ?? 0;
  }

  Future<void> _loadTotalUsers() async {
    final res = await supabase
        .from('admin')
        .select('id')
        .count();
    totalUsers = res.count ?? 0;
  }

  Future<void> _loadTodaysRevenue() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final res = await supabase
        .from('purchase_order')
        .select('total_price')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());

    todaysRevenue = res.fold(0.0, (sum, item) {
      return sum + (item['total_price'] as num).toDouble();
    });
  }

  Future<void> _loadRecentOrders() async {
    final res = await supabase
        .from('purchase_order')
        .select('''
          *,
          customer:customer_id(name)
        ''')
        .order('created_at', ascending: false)
        .limit(5);

    recentOrders = List<Map<String, dynamic>>.from(res);
  }

  Future<void> _loadBestSellers() async {
    final res = await supabase
        .from('menu')
        .select('*')
        .eq('is_best_seller', true)
        .limit(4);

    bestSellerMenus = List<Map<String, dynamic>>.from(res);
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    DateFormat('d MMM').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8D6E63),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminPreOrderPage(key: UniqueKey()),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Color(0xFF8D6E63)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No recent orders',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: recentOrders.map((order) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF8D6E63).withOpacity(0.1),
                          child: const Icon(
                            Icons.receipt,
                            color: Color(0xFF8D6E63),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Order #${order['id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          order['customer'] != null
                              ? order['customer']['name'] ?? 'Customer'
                              : 'Customer',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${NumberFormat('#,##0').format(order['total_price'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF8D6E63),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d').format(
                                DateTime.parse(order['created_at']),
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Best Sellers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminMenuPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bestSellerMenus.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No best sellers yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200, // Fixed height untuk menghindari overflow
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3, // Adjusted aspect ratio
                  ),
                  itemCount: bestSellerMenus.length,
                  itemBuilder: (context, index) {
                    final menu = bestSellerMenus[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[50],
                        border: Border.all(
                          color: Colors.grey[200] ?? Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Image Container
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF8D6E63).withOpacity(0.1),
                              ),
                              child: menu['img_url'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        menu['img_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.cake,
                                              color: Color(0xFF8D6E63),
                                              size: 24,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.cake,
                                        color: Color(0xFF8D6E63),
                                        size: 24,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            // Menu Name
                            Text(
                              menu['name'] ?? 'Menu',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Price
                            Text(
                              'Rp ${NumberFormat('#,##0').format(menu['price'])}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8D6E63),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Best Seller Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.amber[200]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Best Seller',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${widget.adminName}! 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM y').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            color: const Color(0xFF8D6E63),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8D6E63),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF8D6E63),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF8D6E63).withOpacity(0.9),
                            const Color(0xFFA1887F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Luxelle Bakery',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Welcome to your admin dashboard',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stat Cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                            title: 'Total Orders',
                            value: totalOrders.toString(),
                            subtitle: 'All time orders',
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.cake,
                            color: Colors.green,
                            title: 'Total Menus',
                            value: totalMenus.toString(),
                            subtitle: 'Available items',
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.people,
                            color: Colors.orange,
                            title: 'Total Admins',
                            value: totalUsers.toString(),
                            subtitle: 'Active users',
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.attach_money,
                            color: Colors.purple,
                            title: "Today's Revenue",
                            value: 'Rp ${NumberFormat('#,##0').format(todaysRevenue)}',
                            subtitle: 'Daily income',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Two Column Layout
                    // Gunakan MediaQuery untuk responsive layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          // Desktop/Landscape layout
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildRecentOrdersCard(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildBestSellersCard(),
                              ),
                            ],
                          );
                        } else {
                          // Mobile/Portrait layout
                          return Column(
                            children: [
                              _buildRecentOrdersCard(),
                              const SizedBox(height: 16),
                              _buildBestSellersCard(),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.spaceEvenly,
                              children: [
                                _buildQuickActionButton(
                                  icon: Icons.add_circle_outline,
                                  label: 'Add Menu',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminMenuPage(),
                                      ),
                                    );
                                  },
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.inventory,
                                  label: 'Manage Stock',
                                  onTap: () {
                                    // Add stock management functionality
                                  },
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.bar_chart,
                                  label: 'Reports',
                                  onTap: () {
                                    // Add reports functionality
                                  },
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.settings,
                                  label: 'Settings',
                                  onTap: () {
                                    // Add settings functionality
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8D6E63),
        child: const Icon(Icons.refresh),
        onPressed: _loadDashboardData,
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8D6E63),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}