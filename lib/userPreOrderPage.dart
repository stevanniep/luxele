import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxele/userHistoryPage.dart';

final supabase = Supabase.instance.client;

class UserPreOrderPage extends StatefulWidget {
  const UserPreOrderPage({super.key});

  @override
  State<UserPreOrderPage> createState() => _UserPreOrderPageState();
}

class _UserPreOrderPageState extends State<UserPreOrderPage> {
  int? poId;
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDraftPO();
  }

  // ================= LOAD PRE ORDER (FIXED) =================
  Future<void> _loadDraftPO() async {
    setState(() => loading = true);

    final user = supabase.auth.currentUser;

    // ❗ PENTING: CEK LOGIN
    if (user == null) {
      setState(() {
        loading = false;
        poId = null;
        items = [];
      });
      return;
    }

    final po = await supabase
        .from('po')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'draft')
        .maybeSingle();

    if (po != null) {
      poId = po['id'];

      final data = await supabase
          .from('po_menu')
          .select('id, qty, menu(name, price)')
          .eq('po_id', poId!);

      items = data;
    } else {
      poId = null;
      items = [];
    }

    setState(() => loading = false);
  }
  // ==========================================================

  Future<void> _updateQty(int id, int qty) async {
    if (qty <= 0) {
      await supabase.from('po_menu').delete().eq('id', id);
    } else {
      await supabase.from('po_menu').update({'qty': qty}).eq('id', id);
    }
    await _loadDraftPO();
  }

  Future<void> _confirmPO() async {
    if (poId == null) return;

    await supabase.from('po').update({'status': 'confirmed'}).eq('id', poId!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pre Order berhasil dikonfirmasi")),
    );

    poId = null;
    items = [];

    await _loadDraftPO();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (items.isEmpty) {
      return const Scaffold(body: Center(child: Text("Belum ada pre-order")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pre Order"),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(item['menu']['name']),
              subtitle: Text("Rp ${item['menu']['price']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _updateQty(item['id'], item['qty'] - 1),
                  ),
                  Text(item['qty'].toString()),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _updateQty(item['id'], item['qty'] + 1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8D6E63),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: poId == null ? null : _confirmPO,
          child: const Text(
            "Confirm Pre Order",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
