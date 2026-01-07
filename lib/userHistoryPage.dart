// lib/userHistoryPage.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key});

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<dynamic> _myOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchMyOrders();
  }

  Future<void> _fetchMyOrders() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Pastikan query ini menarik data po_menu dan menu di dalamnya
      final data = await supabase
          .from('po')
          .select('id, created_at, status, po_menu(qty, menu(name, price))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myOrders = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pre-Order Saya"),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myOrders.isEmpty
          ? const Center(child: Text("Belum ada pre-order"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _myOrders.length,
              itemBuilder: (context, index) {
                final po = _myOrders[index];
                return Card(
                  child: ListTile(
                    title: Text("Order #${po['id']} - ${po['status']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var item in po['po_menu'])
                          Text("• ${item['menu']['name']} (x${item['qty']})"),
                        Text(
                          "Tanggal: ${po['created_at'].toString().substring(0, 10)}",
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
