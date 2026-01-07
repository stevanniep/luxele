import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

final supabase = Supabase.instance.client;

class AdminPreOrderPage extends StatefulWidget {
  const AdminPreOrderPage({super.key});

  @override
  State<AdminPreOrderPage> createState() => _AdminPreOrderPageState();
}

class _AdminPreOrderPageState extends State<AdminPreOrderPage> {
  List<dynamic> orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      // Query ini mengambil data PO, Nama dari Profiles, dan List Menu dari po_menu
      final data = await supabase
          .from('po')
          .select('''
            id, 
            created_at, 
            status,
            profiles:user_id ( name ),
            po_menu (
              qty,
              menu ( name, price )
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        orders = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Admin: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat: Pastikan SQL Step 1 sudah dijalankan"),
          ),
        );
      }
    }
  }

  void _downloadCSV() {
    if (orders.isEmpty) return;

    // Header CSV
    String csv = "OrderID;Customer;Item;Qty;Price;Total;Date\n";

    for (var po in orders) {
      final customer = po['profiles']?['name'] ?? "Unknown";
      final date = po['created_at'].toString().substring(0, 10);

      for (var item in po['po_menu']) {
        final menuName = item['menu']['name'];
        final price = item['menu']['price'];
        final qty = item['qty'];
        final total = price * qty;

        csv += "${po['id']};$customer;$menuName;$qty;$price;$total;$date\n";
      }
    }

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "rekap_admin_luxelle.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F3),
      appBar: AppBar(
        title: const Text("Data Pre-Order Admin"),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _downloadCSV,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8D6E63)),
            )
          : orders.isEmpty
          ? const Center(child: Text("Tidak ada pesanan masuk."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final po = orders[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF8D6E63),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      "Order #${po['id']} - ${po['profiles']?['name'] ?? 'Guest'}",
                    ),
                    subtitle: Text(
                      "Status: ${po['status']}\nItems: ${po['po_menu'].length}",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDetail(po),
                  ),
                );
              },
            ),
    );
  }

  void _showDetail(Map<String, dynamic> po) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detail Order #${po['id']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...(po['po_menu'] as List).map(
              (item) => ListTile(
                title: Text(item['menu']['name']),
                subtitle: Text("${item['qty']} x Rp ${item['menu']['price']}"),
              ),
            ),
          ],
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
}
