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
  bool loading = true;

  bool showForm = false;
  Map<String, dynamic>? editingMenu;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

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
    selectedCategory = categories.first;
    _loadMenus();
  }

  // ================= LOAD MENU =================
  Future<void> _loadMenus() async {
    try {
      setState(() => loading = true);
      final res = await supabase.from('menu').select().order('id');
      menus = List<Map<String, dynamic>>.from(res);
      setState(() => loading = false);
    } catch (e) {
      print('Error loading menus: $e');
      setState(() => loading = false);
    }
  }

  // ================= IMAGE PICK =================
  Future<void> _pickImageForPreview() async {
    try {
      final tempId = editingMenu?['id'] ?? DateTime.now().millisecondsSinceEpoch;

      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (res == null || res.files.single.bytes == null) return;

      Uint8List fileBytes = res.files.single.bytes!;
      img.Image? original = img.decodeImage(fileBytes);
      if (original != null) {
        fileBytes = Uint8List.fromList(img.encodeJpg(original));
      }

      final filename = 'menu_$tempId.jpg';

      await supabase.storage.from('menu').uploadBinary(
            filename,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage.from('menu').getPublicUrl(filename);

      setState(() => imageUrl = publicUrl);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  // ================= SAVE MENU =================
  Future<void> _saveMenu() async {
    try {
      final name = nameController.text.trim();
      final price = double.tryParse(priceController.text) ?? 0;

      if (name.isEmpty || price <= 0) {
        _showSnackBar('Please fill all fields correctly');
        return;
      }

      if (editingMenu == null) {
        await supabase.from('menu').insert({
          'name': name,
          'price': price,
          'category': selectedCategory,
          'is_best_seller': isBestSeller,
          'img_url': imageUrl,
        });
        _showSnackBar('Menu added successfully');
      } else {
        await supabase.from('menu').update({
          'name': name,
          'price': price,
          'category': selectedCategory,
          'is_best_seller': isBestSeller,
          'img_url': imageUrl,
        }).eq('id', editingMenu!['id']);
        _showSnackBar('Menu updated successfully');
      }

      _resetForm();
      await _loadMenus();
    } catch (e) {
      print('Error saving menu: $e');
      _showSnackBar('Error saving menu');
    }
  }

  // ================= SIMPLE DELETE (AFTER CASCADE) =================
  Future<void> _deleteMenu(int id) async {
    try {
      // Konfirmasi sederhana
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Menu'),
          content: const Text('Are you sure you want to delete this menu?'),
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

      if (confirm != true) return;

      // Hapus menu saja, data di po_menu akan terhapus otomatis karena CASCADE
      await supabase.from('menu').delete().eq('id', id);
      
      _showSnackBar('Menu deleted successfully');
      await _loadMenus();
    } catch (e) {
      print('Error deleting menu: $e');
      _showSnackBar('Failed to delete menu');
    }
  }

  // ================= RESET FORM =================
  void _resetForm() {
    setState(() {
      showForm = false;
      editingMenu = null;
      nameController.clear();
      priceController.clear();
      selectedCategory = categories.first;
      isBestSeller = false;
      imageUrl = null;
    });
  }

  // ================= HELPER FUNCTION =================
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        title: const Text("Admin Menu"),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8D6E63),
        child: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            showForm = true;
            editingMenu = null;
            nameController.clear();
            priceController.clear();
            selectedCategory = categories.first;
            isBestSeller = false;
            imageUrl = null;
          });
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : showForm
              ? _menuForm()
              : _menuList(),
    );
  }

  // ================= MENU LIST =================
  Widget _menuList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Card(
          child: ListTile(
            leading: menu['img_url'] != null
                ? Image.network(menu['img_url'], width: 50, height: 50)
                : const Icon(Icons.cake),
            title: Text(menu['name']),
            subtitle: Text("Rp ${menu['price']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      editingMenu = menu;
                      nameController.text = menu['name'];
                      priceController.text = menu['price'].toString();
                      selectedCategory = menu['category'];
                      isBestSeller = menu['is_best_seller'] ?? false;
                      imageUrl = menu['img_url'];
                      showForm = true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteMenu(menu['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= FORM =================
  Widget _menuForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            editingMenu == null ? 'Add Menu' : 'Edit Menu',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Menu Name'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price'),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedCategory,
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => selectedCategory = v),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Best Seller'),
            value: isBestSeller,
            onChanged: (v) => setState(() => isBestSeller = v),
          ),

          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            label: const Text('Upload Image'),
            onPressed: _pickImageForPreview,
          ),

          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Image.network(imageUrl!, height: 120),
            ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveMenu,
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}