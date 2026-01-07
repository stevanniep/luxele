import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminAccountPage extends StatefulWidget {
  final String adminName;
  const AdminAccountPage({super.key, this.adminName = 'Admin'});

  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final data = await supabase.from('profiles').select().order('name');
      setState(() {
        _users = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleRole(String userId, String currentRole) async {
    String newRole = (currentRole.toLowerCase() == 'member')
        ? 'Customer'
        : 'Member';
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('user_id', userId);
      _fetchUsers();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User diubah menjadi $newRole')));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Role User"),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final String role = user['role'] ?? 'Customer';
                final bool isMember = role.toLowerCase() == 'member';
                final bool isAdmin = role.toLowerCase() == 'admin';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(user['name'] ?? 'No Name'),
                    subtitle: Text("Status: $role"),
                    trailing: isAdmin
                        ? null
                        : ElevatedButton(
                            onPressed: () => _toggleRole(user['user_id'], role),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMember
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            child: Text(
                              isMember ? "Set Basic" : "Set Premium",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
