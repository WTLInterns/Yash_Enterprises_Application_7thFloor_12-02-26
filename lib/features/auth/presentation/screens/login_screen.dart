import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/fcm_providers.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/network/dio_error_handler.dart';
import '../../../../features/task/presentation/providers/task_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      UiFeedback.snack(context, 'Please fill all fields');
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      UiFeedback.snack(context, 'Please enter a valid work email address');
      return;
    }

    setState(() => _loading = true);
    try {
      print('🔐 LOGIN: Starting authentication...');

      // 1. Call API and get response
      final response = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      print('✅ LOGIN: API success - employeeId=${response.employeeId}');

      if (!mounted) return;

      // 2. IMMEDIATELY update in-memory session state (SYNCHRONOUS)
      ref
          .read(sessionProvider)
          .setSession(
            token: response.token,
            employeeId: response.employeeId,
            name: response.name,
            role: response.role,
            department: response.department, // 🚨 ADD MISSING DEPARTMENT
          );
      print(
        '===== LOGIN SCREEN SESSION UPDATE =====',
      );
      print('isLoggedIn: ${ref.read(sessionProvider).isLoggedIn}');
      print('employeeId: "${ref.read(sessionProvider).employeeId}"');
      print('role: "${ref.read(sessionProvider).role}"');
      print('department: "${ref.read(sessionProvider).department}"'); // 🚨 LOG DEPARTMENT

      // 3. Set employeeId provider for other features
      ref.read(currentEmployeeIdProvider.notifier).state = response.employeeId;

      // 4. Router will automatically redirect to /app via GoRouter redirect logic
      // NO manual navigation needed - state change triggers redirect
      print('✅ LOGIN: Complete - router will handle navigation');

      // 5. Background tasks (non-blocking)
      Future.microtask(() async {
        try {
          await ref.read(fcmTokenSyncProvider).sync();
          print('✅ FCM token synced');
        } catch (e) {
          print('⚠️ FCM sync error (non-critical): $e');
        }
      });
    } on DioException catch (e) {
      print('❌ LOGIN ERROR (DioException): $e');
      if (mounted)
        UiFeedback.snack(context, 'Login failed: ${handleDioError(e)}');
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      if (mounted) {
        UiFeedback.snack(
          context,
          'Login failed: ${e.toString().replaceAll('Exception: ', '').trim()}',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _bg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7F6FF), Color(0xFFF2E9FF), Color(0xFFFFFFFF)],
        ),
      ),
    );
  }

  Widget _logoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2F6BFF), Color(0xFFB14DFF)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F6BFF).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.business, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'YashEnterprises',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2F6BFF)),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _logoRow(),
                        const SizedBox(height: 30),
                        const Text(
                          "Login to account",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 28),

                        /// EMAIL
                        _inputField(
                          controller: _emailController,
                          hint: "Email address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          obscure: false,
                        ),

                        const SizedBox(height: 16),

                        /// PASSWORD
                        _inputField(
                          controller: _passwordController,
                          hint: "Password",
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6BFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        const Text(
                          "v6.57",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
