import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxele/loginPage.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  SupabaseClient get supabase => Supabase.instance.client;

  // =========================
  // UPLOAD ADMIN PHOTO
  // =========================
  Future<void> _uploadPhoto(
    BuildContext context,
    String userId,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      Uint8List bytes = result.files.single.bytes!;
      final image = img.decodeImage(bytes);
      if (image != null) {
        bytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
      }

      final path = '$userId/avatar.jpg';

      await supabase.storage.from('profiles').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final url = supabase.storage.from('profiles').getPublicUrl(path);

      await supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('user_id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin photo updated')),
      );
    } catch (e) {
      debugPrint('UPLOAD ADMIN PHOTO ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // =========================
  // DELETE ADMIN PHOTO
  // =========================
  Future<void> _deletePhoto(
    BuildContext context,
    String userId,
  ) async {
    try {
      final path = '$userId/avatar.jpg';

      await supabase.storage.from('profiles').remove([path]);

      await supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('user_id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin photo deleted')),
      );
    } catch (e) {
      debugPrint('DELETE ADMIN PHOTO ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showAvatarOptions(
    BuildContext context,
    String userId,
    String? avatarUrl,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Change Photo'),
            onTap: () {
              Navigator.pop(context);
              _uploadPhoto(context, userId);
            },
          ),
          if (avatarUrl != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Photo',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(context, userId);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF8F3),
              Color(0xFFFFF8DC),
              Color(0xFFD7CCC8),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('profiles')
                .stream(primaryKey: ['user_id']) // 🔥 FIX STREAM
                .eq('user_id', user.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('Admin profile not found'));
              }

              final profile = snapshot.data!.first;
              final avatarUrl = profile['avatar_url'];

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // =========================
                    // ADMIN AVATAR (UPLOAD + DELETE)
                    // =========================
                    GestureDetector(
                      onTap: () => _showAvatarOptions(
                        context,
                        user.id,
                        avatarUrl,
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF8D6E63),
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(
                                '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                              )
                            : null,
                        child: avatarUrl == null
                            ? const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 40,
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 12),
                    _roleBadge(),
                    const SizedBox(height: 30),

                    // =========================
                    // INFO CARD
                    // =========================
                    _card(
                      child: Column(
                        children: [
                          _infoRow(
                            'Full Name',
                            profile['name'] ?? 'Admin',
                          ),
                          const SizedBox(height: 12),
                          _infoRow('Email', user.email ?? '-'),
                          const SizedBox(height: 12),
                          _infoRow(
                            'Role',
                            (profile['role'] ?? 'admin')
                                .toString()
                                .toUpperCase(),
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            'Last Login',
                            profile['last_login']
                                    ?.toString()
                                    .replaceFirst('T', ' ')
                                    .substring(0, 16) ??
                                '-',
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // =========================
                    // LOGOUT
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await supabase.auth.signOut();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (_) => false,
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================
  // UI HELPERS
  // =========================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _roleBadge() {
    return const Chip(
      label: Text(
        'ADMIN',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.redAccent,
    );
  }
}
