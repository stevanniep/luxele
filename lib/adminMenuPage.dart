import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

final supabase = Supabase.instance.client;

class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage> {
  List<Map<String, dynamic>> menus = [];
  List<Map<String, dynamic>> filteredMenus = [];
  bool loading = true;
  final TextEditingController searchController = TextEditingController();

  bool showForm = false;
  Map<String, dynamic>? editingMenu;

  late TextEditingController nameController;
  late TextEditingController priceController;
  String? selectedCategory;
  bool isBestSeller = false;
  String? imageUrl;

  final List<String> categories = [
    'Bread',
    'Cookies',
    'Cake & Desserts',
    'Pudding',
    'Pastry',
    'Doughnuts',
  ];

  @override
  void initState() {
    super.initState();
    _loadMenus();
    searchController.addListener(_filterMenus);

    nameController = TextEditingController();
    priceController = TextEditingController();
    selectedCategory = categories.first;
  }

  Future<void> _loadMenus() async {
    setState(() => loading = true);
    final res = await supabase.from('menu').select().order('id');
    if (res != null) {
      menus = List<Map<String, dynamic>>.from(res);
      filteredMenus = List.from(menus);
    }
    setState(() => loading = false);
  }

  void _filterMenus() {
    final query = searchController.text.toLowerCase();
    filteredMenus = menus
        .where((m) => (m['name'] as String).toLowerCase().contains(query))
        .toList();
    setState(() {});
  }

  void _openAddPanel() {
    setState(() {
      showForm = true;
      editingMenu = null;
      nameController.text = '';
      priceController.text = '';
      selectedCategory = categories.first;
      isBestSeller = false;
      imageUrl = null;
    });
  }

  void _openEditPanel(Map<String, dynamic> menu) {
    setState(() {
      showForm = true;
      editingMenu = menu;
      nameController.text = menu['name'] ?? '';
      priceController.text = menu['price']?.toString() ?? '';
      selectedCategory = menu['category'] ?? categories.first;
      isBestSeller = menu['is_best_seller'] == true;
      imageUrl = menu['img_url'] as String?;
    });
  }

  Future<void> _pickImageForPreview() async {
    final tempId = editingMenu?['id'] ?? DateTime.now().millisecondsSinceEpoch;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    Uint8List fileBytes = res.files.single.bytes!;

    img.Image? original = img.decodeImage(fileBytes);
    if (original != null) {
      int targetWidth = original.width;
      int targetHeight = (targetWidth * 0.75).toInt();
      img.Image resized = img.copyResize(
        original,
        width: targetWidth,
        height: targetHeight,
      );
      fileBytes = Uint8List.fromList(img.encodeJpg(resized));
    }

    final ext = res.files.single.extension ?? 'jpg';
    final filename = 'menu_$tempId.$ext';

    await supabase.storage
        .from('menu')
        .uploadBinary(
          filename,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = supabase.storage.from('menu').getPublicUrl(filename);

    if (editingMenu != null) {
      await supabase
          .from('menu')
          .update({'img_url': publicUrl})
          .eq('id', editingMenu!['id']);
    }

    setState(() {
      imageUrl = publicUrl;
    });
  }

  Future<void> _saveMenu() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0;
    final category = selectedCategory ?? categories.first;
    if (name.isEmpty) return;

    if (editingMenu == null) {
      await supabase.from('menu').insert({
        'name': name,
        'price': price,
        'category': category,
        'is_best_seller': isBestSeller,
        'img_url': imageUrl,
      });
    } else {
      await supabase
          .from('menu')
          .update({
            'name': name,
            'price': price,
            'category': category,
            'is_best_seller': isBestSeller,
            'img_url': imageUrl,
          })
          .eq('id', editingMenu!['id']);
    }

    setState(() {
      showForm = false;
      editingMenu = null;
      imageUrl = null;
    });

    await _loadMenus();
  }

  Future<void> _deleteMenu(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Menu?'),
        content: const Text('Are you sure you want to delete this menu item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.from('menu').delete().eq('id', id);
      await _loadMenus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: showForm
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: Text(
                editingMenu == null ? 'Add Menu' : 'Edit Menu',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      showForm = false;
                      editingMenu = null;
                      imageUrl = null;
                    });
                  },
                  icon: const Icon(Icons.close, color: Color(0xFF8D6E63)),
                ),
              ],
            )
          : AppBar(
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
          if (!showForm)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (_) => _filterMenus(),
                    decoration: InputDecoration(
                      hintText: 'Search menu...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8D6E63),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFDFDFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openAddPanel,
                      icon: const Icon(Icons.add, color: Color(0xFF8D6E63)),
                      label: const Text(
                        'Add Menu',
                        style: TextStyle(color: Color(0xFF8D6E63)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF8D6E63),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: showForm ? _buildForm() : _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImageForPreview,
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 0.75,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(16),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _inputField('Name', nameController),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: selectedCategory,
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 12),
            _inputField(
              'Price',
              priceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Best Seller:'),
                Checkbox(
                  value: isBestSeller,
                  onChanged: (val) =>
                      setState(() => isBestSeller = val ?? false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final double itemHeight = 240;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              itemCount: filteredMenus.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final menu = filteredMenus[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: itemHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: itemHeight / 2,
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
                                    child: Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
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
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _openEditPanel(menu),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _deleteMenu(menu['id']),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
              },
            ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFEFEBE9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFEFEBE9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF8D6E63)),
            ),
          ),
        ),
      ],
    );
  }
}
