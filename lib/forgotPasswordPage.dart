import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String? _displayedToken; // for testing only

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
  }

  Future<void> _sendOtp() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showError('Email is required');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Invalid email format');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
            'io.supabase.flutterdemo://reset-callback/', // adjust your redirect URL
      );

      // Optional: show token for testing
      _displayedToken = '123456';

      setState(() {
        _otpSent = true;
      });
    } on AuthException catch (e) {
      _showError('Failed to send OTP: ${e.message}');
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError('All fields are required');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('New password and confirmation do not match');
      return;
    }

    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password has been reset successfully!'),
          ),
        );
        Navigator.pop(context); // back to login
      }
    } on AuthException catch (e) {
      _showError('Failed to reset password: ${e.message}');
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !_otpSent
                        ? 'Enter your email to receive a reset OTP'
                        : 'Enter the OTP and your new password',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6D4C41)),
                  ),
                  const SizedBox(height: 24),

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

                  // Email field
                  TextField(
                    controller: emailController,
                    enabled: !_otpSent,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
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
                  const SizedBox(height: 16),

                  // OTP & Password fields
                  if (_otpSent) ...[
                    if (_displayedToken != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8DC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x338D6E63)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'The OTP Code already sent to',
                              style: TextStyle(
                                color: Color(0xFF3E2723),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              emailController.text.trim(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8D6E63),
                                letterSpacing: 4,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'OTP Code',
                        hintText: 'Enter OTP from your email',
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: '••••••••',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: '••••••••',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading
                          ? null
                          : !_otpSent
                          ? _sendOtp
                          : _resetPassword,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8D6E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isLoading
                            ? (!_otpSent ? 'Sending...' : 'Processing...')
                            : (!_otpSent ? 'Send OTP' : 'Reset Password'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      if (_otpSent) {
                        setState(() {
                          _otpSent = false;
                          _displayedToken = null;
                          otpController.clear();
                          newPasswordController.clear();
                          confirmPasswordController.clear();
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      _otpSent ? 'Back' : 'Back to Login',
                      style: const TextStyle(color: Color(0xFF8D6E63)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
