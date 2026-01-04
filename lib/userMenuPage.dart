import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class UserMenuPage extends StatefulWidget {
  const UserMenuPage({super.key});

  @override
  State<UserMenuPage> createState() => _UserMenuPageState();
}

class _UserMenuPageState extends State<UserMenuPage> {
  List<Map<String, dynamic>> menus = [];
  bool loading = true;

  String sortMode = 'category'; // category / name / price
  final List<String> categories = [
    'Bread',
    'Cookies',
    'Cake & Desserts',
    'Pudding',
    'Pastry',
    'Doughnuts',
  ];

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMenus();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadMenus() async {
    setState(() => loading = true);
    final res = await supabase.from('menu').select().order('id');
    if (res != null) {
      menus = List<Map<String, dynamic>>.from(res);
    }
    setState(() => loading = false);
  }

  void _setSortMode(String mode) {
    setState(() {
      sortMode = mode;
    });
  }

  List<Map<String, dynamic>> _getSortedMenus() {
    List<Map<String, dynamic>> sorted = List.from(menus);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      sorted = sorted
          .where(
            (m) => (m['name'] ?? '').toString().toLowerCase().contains(
              searchQuery,
            ),
          )
          .toList();
    }

    if (sortMode == 'name') {
      sorted.sort(
        (a, b) => (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        ),
      );
    } else if (sortMode == 'price') {
      sorted.sort(
        (a, b) =>
            ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num),
      );
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedMenus = _getSortedMenus();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Luxelle Menu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            fontFamily: 'RobotoSlab',
            color: Color(0xFF3E2723),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8D6E63)),
                filled: true,
                fillColor: const Color(0xFFFDFDFD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // 3 Filter Buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _setSortMode('category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sortMode == 'category'
                        ? const Color(0xFF8D6E63)
                        : Colors.grey[300],
                  ),
                  child: Text(
                    'Sort by Category',
                    style: TextStyle(
                      color: sortMode == 'category'
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _setSortMode('name'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sortMode == 'name'
                        ? const Color(0xFF8D6E63)
                        : Colors.grey[300],
                  ),
                  child: Text(
                    'Name A→Z',
                    style: TextStyle(
                      color: sortMode == 'name' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _setSortMode('price'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sortMode == 'price'
                        ? const Color(0xFF8D6E63)
                        : Colors.grey[300],
                  ),
                  child: Text(
                    'Price Lowest',
                    style: TextStyle(
                      color: sortMode == 'price' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : sortMode == 'category'
                ? _buildCategoryGrid()
                : _buildGrid(sortedMenus),
          ),
        ],
      ),
    );
  }

  // Grid for Name or Price sort
  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 card per row
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          return _buildMenuCard(items[index]);
        },
      ),
    );
  }

  // Category view with headers (2 card per row)
  Widget _buildCategoryGrid() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: categories.map((cat) {
        final items = menus
            .where(
              (m) =>
                  m['category'] == cat &&
                  (m['name'] ?? '').toString().toLowerCase().contains(
                    searchQuery,
                  ),
            )
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cat,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 6),
            items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No items',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 card per row
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (context, index) {
                      return _buildMenuCard(items[index]);
                    },
                  ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  // Card for each menu
  Widget _buildMenuCard(Map<String, dynamic> menu) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE FULL
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: Colors.grey[200],
                  image: menu['img_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(menu['img_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: menu['img_url'] == null
                    ? const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${menu['price'] ?? 0}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (menu['is_best_seller'] == true)
          Positioned(
            top: -4,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                'Best Seller',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}