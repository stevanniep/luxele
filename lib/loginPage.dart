import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxele/registerPage.dart';
import 'package:luxele/forgotPasswordPage.dart';
import 'package:luxele/adminDashboardPage.dart';
import 'package:luxele/userDashboardPage.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1️⃣ LOGIN
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;

      if (user != null) {
        debugPrint('Login successful');

        // 2️⃣ UPDATE LAST LOGIN
        try {
          await supabase
              .from('profiles')
              .update({'last_login': DateTime.now().toUtc().toIso8601String()})
              .eq('user_id', user.id);
          debugPrint('last_login updated successfully');
        } catch (e) {
          debugPrint('Failed to update last_login: $e');
        }

        // 3️⃣ FETCH ROLE & NAME
        final profileRes = await supabase
            .from('profiles')
            .select('role, name')
            .eq('user_id', user.id)
            .maybeSingle();

        final role =
            (profileRes?['role'] as String?)?.toLowerCase() ?? 'customer';
        final fullName = profileRes?['name'] as String? ?? 'User';

        if (!mounted) return;

        // 4️⃣ NAVIGATE
        if (role == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardInsidePage(adminName: fullName),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => UserDashboardInsidePage(userName: fullName),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
      debugPrint('Login error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _handleBiometricLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric login is not available yet.')),
    );
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
                    color: Color(0x33000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0x1A8D6E63),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bakery_dining,
                      size: 40,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF3E2723),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to your Luxelle account',
                    style: TextStyle(color: Color(0xFF6D4C41)),
                  ),
                  const SizedBox(height: 30),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  _label('Email'),
                  _inputField(
                    controller: _emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _label('Password'),
                  _inputField(
                    controller: _passwordController,
                    hint: '••••••••',
                    obscure: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _HoverUnderlineButton(
                      text: 'Forgot password?',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8D6E63),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _loading ? 'Signing in...' : 'Sign In',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _handleBiometricLogin,
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFEFEBE9)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Color(0xFF6D4C41)),
                      ),
                      _HoverUnderlineButton(
                        text: 'Sign up',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
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

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(color: Color(0xFF3E2723))),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
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
}

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
