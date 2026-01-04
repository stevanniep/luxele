import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _agree = false;
  String _selectedRole = 'Customer';
  String? _errorMessage;

  // =========================
  // REGISTER — SEND OTP EMAIL
  // =========================
  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('All fields must be filled.');
      return;
    }

    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    if (!_agree) {
      _showError('You must agree to the terms and conditions.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // SEND OTP (Sign-up)
      await supabase.auth.signInWithOtp(email: email, shouldCreateUser: true);

      _showOtpDialog(email, name, password);
    } catch (e) {
      _showError('Failed to send OTP email.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =========================
  // OTP VERIFICATION
  // =========================
  void _showOtpDialog(String email, String name, String password) {
    final otpController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool submitting = false;

        Future<void> submitOtp() async {
          if (submitting) return;
          submitting = true;

          try {
            // VERIFY OTP
            await supabase.auth.verifyOTP(
              email: email,
              token: otpController.text.trim(),
              type: OtpType.signup,
            );

            final user = supabase.auth.currentUser;
            if (user == null) throw 'User not found';

            // SET PASSWORD
            await supabase.auth.updateUser(UserAttributes(password: password));

            // INSERT PROFILE
            await supabase.from('profiles').insert({
              'user_id': user.id,
              'name': name,
              'email': email,
              'role': _selectedRole,
              'created_at': DateTime.now().toIso8601String(),
            });

            if (mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registration successful. Please log in.'),
                ),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted)
              setState(() => errorMessage = 'Invalid or expired OTP.');
          } finally {
            submitting = false;
          }
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the verification code sent to your email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6D4C41)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter OTP',
                        filled: true,
                        fillColor: const Color(0xFFF3EFEA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0D7D3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0D7D3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF8D6E63),
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8D6E63)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF8D6E63)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await submitOtp();
                              setStateDialog(
                                () {},
                              ); 
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8D6E63),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Verify',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showError(String msg) {
    setState(() => _errorMessage = msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF8F3), Color(0xFFFFF8DC), Color(0xFFD7CCC8)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x338D6E63)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    offset: Offset(0, 10),
                    color: Color(0x33000000),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF3E2723),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join Luxelle Bakery',
                    style: TextStyle(color: Color(0xFF6D4C41)),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) _errorBox(_errorMessage!),

                  _label('Full Name'),
                  _input(_nameController, 'Your name'),

                  const SizedBox(height: 16),
                  _label('Email'),
                  _input(
                    _emailController,
                    'you@example.com',
                    keyboard: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),
                  _label('Password'),
                  _input(_passwordController, '••••••••', obscure: true),

                  const SizedBox(height: 16),
                  _label('Confirm Password'),
                  _input(_confirmPasswordController, '••••••••', obscure: true),

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Register as',
                      style: TextStyle(color: Color(0xFF3E2723)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _roleSelector(),
                  const SizedBox(height: 20),
                  _agreementBox(),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D6E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _loading ? 'Creating account...' : 'Create Account',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Color(0xFF6D4C41)),
                      ),
                      _HoverUnderlineButton(
                        text: 'Sign in',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // COMPONENTS
  // =========================
  Widget _roleSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: ['Customer', 'Admin'].map((role) {
          final selected = _selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  role,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF3E2723)
                        : const Color(0xFF6D4C41),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _agreementBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _agree,
            onChanged: (v) => setState(() => _agree = v!),
            activeColor: const Color(0xFF8D6E63),
          ),
          const Expanded(
            child: Text(
              'I agree to the terms and conditions.',
              style: TextStyle(color: Color(0xFF3E2723)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(color: Color(0xFF3E2723))),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
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
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(msg, style: const TextStyle(color: Colors.red)),
    );
  }
}

// =========================
// HOVER UNDERLINE BUTTON
// =========================
class _HoverUnderlineButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;

  const _HoverUnderlineButton({required this.text, this.onTap});

  @override
  State<_HoverUnderlineButton> createState() => _HoverUnderlineButtonState();
}

class _HoverUnderlineButtonState extends State<_HoverUnderlineButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            color: const Color(0xFF8D6E63),
            fontWeight: FontWeight.w500,
            decoration: _hover ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
