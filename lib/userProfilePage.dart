import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxele/loginPage.dart';

final supabase = Supabase.instance.client;

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _saving = false;
  bool _changingPassword = false;
  bool _initialized = false;

  // =========================
  // UPLOAD PROFILE PHOTO
  // =========================
  Future<void> _pickAndUploadProfilePhoto(String userId) async {
  try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    if (result == null) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('No image bytes');

    final path = '$userId/avatar.jpg';

    await supabase.storage.from('profiles').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    final url =
        supabase.storage.from('profiles').getPublicUrl(path);

    await supabase
        .from('profiles')
        .update({'avatar_url': url})
        .eq('user_id', userId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload success')),
    );
  } catch (e) {
    debugPrint('UPLOAD ERROR: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  // =========================
  // DELETE PROFILE PHOTO
  // =========================
  Future<void> _deleteProfilePhoto(String userId) async {
    try {
      final filePath = '$userId/avatar.jpg';

      await supabase.storage.from('profiles').remove([filePath]);

      await supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('DELETE PHOTO ERROR: $e');
      _showError('Failed to delete photo');
    }
  }

  // =========================
  // UPDATE NAME
  // =========================
  Future<void> _updateName(String userId) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      await supabase
          .from('profiles')
          .update({'name': name})
          .eq('user_id', userId);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    } finally {
      setState(() => _saving = false);
    }
  }

  // =========================
  // CHANGE PASSWORD
  // =========================
  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _changingPassword = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } finally {
      setState(() => _changingPassword = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('profiles')
              .stream(primaryKey: ['user_id']) // 🔥 FIX UTAMA
              .eq('user_id', user.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = snapshot.data!.first;

            if (!_initialized) {
              _nameController.text =
                  profile['name'] ?? user.email ?? 'User';
              _initialized = true;
            }

            final avatarUrl = profile['avatar_url'];
            final role =
                (profile['role'] ?? 'customer').toString().toLowerCase();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarOptions(
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
                          ? const Icon(Icons.camera_alt,
                              color: Colors.white, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _roleBadge(role),
                  const SizedBox(height: 30),

                  _card(
                    child: Column(
                      children: [
                        _textField(
                          controller: _nameController,
                          label: 'Full Name',
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Email', user.email ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _card(
                    child: Column(
                      children: [
                        _textField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          obscure: true,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          obscure: true,
                        ),
                        const SizedBox(height: 16),
                        _outlinedButton(
                          text: _changingPassword
                              ? 'Changing...'
                              : 'Change Password',
                          onTap:
                              _changingPassword ? null : _changePassword,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _primaryButton(
                    text: _saving ? 'Saving...' : 'Save Changes',
                    onTap: _saving ? null : () => _updateName(user.id),
                  ),

                  const SizedBox(height: 16),
                  _outlinedButton(text: 'Logout', onTap: _logout),
                ],
              ),
            );
          },
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _primaryButton({required String text, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }

  Widget _outlinedButton({required String text, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(onPressed: onTap, child: Text(text)),
    );
  }

  Widget _roleBadge(String role) {
    return Chip(
      label: Text(role.toUpperCase(),
          style: const TextStyle(color: Colors.white)),
      backgroundColor:
          role == 'member' ? Colors.green : const Color(0xFF8D6E63),
    );
  }

  void _showAvatarOptions(String userId, String? avatarUrl) {
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
              _pickAndUploadProfilePhoto(userId);
            },
          ),
          if (avatarUrl != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Photo',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteProfilePhoto(userId);
              },
            ),
        ],
      ),
    );
  }
}
