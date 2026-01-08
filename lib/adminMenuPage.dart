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

  String search = '';

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
    nameController = TextEditingController();
    priceController = TextEditingController();
    selectedCategory = categories.first;
  }

  Future<void> _loadMenus() async {
    setState(() => loading = true);
    final res = await supabase.from('menu').select().order('id');
    menus = List<Map<String, dynamic>>.from(res);
    _applyFilter();
    setState(() => loading = false);
  }

  void _applyFilter() {
    List<Map<String, dynamic>> result = [...menus];

    if (search.isNotEmpty) {
      result = result
          .where(
            (m) => (m['name'] ?? '').toString().toLowerCase().contains(
              search.toLowerCase(),
            ),
          )
          .toList();
    }

    setState(() => filteredMenus = result);
  }

  void _openAddPanel() {
    setState(() {
      showForm = true;
      editingMenu = null;
      nameController.clear();
      priceController.clear();
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
      imageUrl = menu['img_url'];
    });
  }

  Future<void> _pickImageForPreview() async {
    final tempId = editingMenu?['id'] ?? DateTime.now().millisecondsSinceEpoch;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    Uint8List bytes = res.files.single.bytes!;
    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      image = img.copyResize(
        image,
        width: image.width,
        height: (image.width * 0.75).toInt(), // 4:3
      );
      bytes = Uint8List.fromList(img.encodeJpg(image));
    }

    final filename = 'menu_$tempId.jpg';

    await supabase.storage
        .from('menu')
        .uploadBinary(
          filename,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = supabase.storage.from('menu').getPublicUrl(filename);

    if (editingMenu != null) {
      await supabase
          .from('menu')
          .update({'img_url': url})
          .eq('id', editingMenu!['id']);
    }

    setState(() => imageUrl = url);
  }

  Future<void> _saveMenu() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0;

    if (name.isEmpty) return;

    final data = {
      'name': name,
      'price': price,
      'category': selectedCategory,
      'is_best_seller': isBestSeller,
      'img_url': imageUrl,
    };

    if (editingMenu == null) {
      await supabase.from('menu').insert(data);
    } else {
      await supabase.from('menu').update(data).eq('id', editingMenu!['id']);
    }

    setState(() {
      showForm = false;
      editingMenu = null;
      imageUrl = null;
    });

    _loadMenus();
  }

  Future<void> _deleteMenu(int id) async {
    await supabase.from('menu').delete().eq('id', id);
    _loadMenus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8D6E63),
        title: Text(showForm ? 'Manage Menu' : 'Luxelle Menu'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!showForm)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search menu...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8D6E63),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) {
                      search = v;
                      _applyFilter();
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openAddPanel,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Menu',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D6E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImageForPreview,
              child: Container(
                width: double.infinity,
                height: 260, // ✅ diperbesar
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Center(child: Icon(Icons.add_a_photo, size: 48))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _inputField('Name', nameController),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _inputField(
              'Price',
              priceController,
              keyboardType: TextInputType.number,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: isBestSeller,
              onChanged: (v) => setState(() => isBestSeller = v ?? false),
              title: const Text('Best Seller'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
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
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredMenus.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final m = filteredMenus[i];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // ✅ rata kiri
            children: [
              Expanded(
                child: m['img_url'] != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          m['img_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Center(child: Icon(Icons.image, size: 40)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // ✅ rata kiri
                  children: [
                    Text(
                      m['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text('Rp ${m['price']}'),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.amber.withOpacity(0.8),
                          ),
                          onPressed: () => _openEditPanel(m),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red.withOpacity(0.8),
                          ),
                          onPressed: () => _deleteMenu(m['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputField(
    String label,
    TextEditingController c, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
