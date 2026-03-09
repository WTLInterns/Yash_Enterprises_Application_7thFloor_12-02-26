import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/notifications/fcm_providers.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/ui_feedback.dart';
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
  final _organizationController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _organizationFocused = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final organization = _organizationController.text.trim();

    if (email.isEmpty || password.isEmpty || organization.isEmpty) {
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
      await ref.read(authRepositoryProvider).login(
            organization: organization,
            email: email,
            password: password,
          );
      await ref.read(sessionProvider).refresh();
      await ref.read(fcmTokenSyncProvider).sync();
      
      // Set employee ID for real-time filtering from secure storage
      final storage = ref.read(secureStorageProvider);
      final employeeId = await storage.readEmployeeId();
      if (employeeId != null) {
        ref.read(currentEmployeeIdProvider.notifier).state = employeeId;
      }
      
      if (mounted) context.go(RouteNames.shell);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? "Network error";
      UiFeedback.snack(context, "Login failed: $msg");
    } catch (e) {
      UiFeedback.snack(context, "Login failed: $e");
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
          colors: [
            Color(0xFFE7F6FF),
            Color(0xFFF2E9FF),
            Color(0xFFFFFFFF),
          ],
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
            gradient: const LinearGradient(colors: [Color(0xFF2F6BFF), Color(0xFFB14DFF)]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    _logoRow(),
                    const SizedBox(height: 22),
                    const Text(
                      'Login to account',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 22),
                    
                    // Organization Field
                    Focus(
                      onFocusChange: (hasFocus) => setState(() => _organizationFocused = hasFocus),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _organizationFocused 
                                ? const Color(0xFF2F6BFF)
                                : const Color(0xFFE7EAF3),
                            width: _organizationFocused ? 2 : 1,
                          ),
                          boxShadow: _organizationFocused
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2F6BFF).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: TextField(
                          controller: _organizationController,
                          decoration: const InputDecoration(
                            hintText: 'Organization',
                            prefixIcon: Icon(Icons.business_outlined, color: Color(0xFF2F6BFF)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  
                  // Email Field
                  Focus(
                    onFocusChange: (hasFocus) => setState(() => _emailFocused = hasFocus),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _emailFocused 
                              ? const Color(0xFF2F6BFF)
                              : const Color(0xFFE7EAF3),
                          width: _emailFocused ? 2 : 1,
                        ),
                        boxShadow: _emailFocused
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2F6BFF).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email Address',
                          helperText: 'Enter your work email',
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2F6BFF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Password Field
                  Focus(
                    onFocusChange: (hasFocus) => setState(() => _passwordFocused = hasFocus),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _passwordFocused 
                              ? const Color(0xFF2F6BFF)
                              : const Color(0xFFE7EAF3),
                          width: _passwordFocused ? 2 : 1,
                        ),
                        boxShadow: _passwordFocused
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2F6BFF).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2F6BFF)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          _emailController.text.trim().isEmpty || 
                          _passwordController.text.trim().isEmpty || 
                          _organizationController.text.trim().isEmpty 
                              ? const Color(0xFFE7EAF3) 
                              : const Color(0xFF2F6BFF),
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          _emailController.text.trim().isEmpty || 
                          _passwordController.text.trim().isEmpty || 
                          _organizationController.text.trim().isEmpty 
                              ? const Color(0xFFB5BAC7) 
                              : Colors.white,
                        ),
                        elevation: WidgetStatePropertyAll(
                          _emailController.text.trim().isEmpty || 
                          _passwordController.text.trim().isEmpty || 
                          _organizationController.text.trim().isEmpty 
                              ? 0 
                              : 4,
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      onPressed: (_loading || 
                               _emailController.text.trim().isEmpty || 
                               _passwordController.text.trim().isEmpty || 
                               _organizationController.text.trim().isEmpty) 
                          ? null 
                          : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('v6.57', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}