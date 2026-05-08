import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import 'package:provider/provider.dart';
import '../../app/globals.dart';
import '../../core/providers/auth_provider.dart';
import '../../app/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Start waking up the server as soon as the user sees the login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().warmup();
    });
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    
    try {
      if (_isLogin) {
        await auth.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          
          // Show success for 1.2 seconds then enter
          await Future.delayed(const Duration(milliseconds: 1200));
          if (mounted) {
            auth.finishLogin();
          }
        }
      } else {
        // Simple Register Logic
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'name': _nameController.text.trim(),
          }),
        );
        
        if (response.statusCode == 201) {
          await auth.login(
            _emailController.text.trim(),
            _passwordController.text,
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isSuccess = true;
            });
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) auth.finishLogin();
          }
        } else {
          final data = jsonDecode(response.body);
          throw Exception(data['error'] ?? 'Registration failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Globals.showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondary,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _isSuccess ? 0 : 1,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 600),
                  scale: _isSuccess ? 0.8 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Card(
                          elevation: 12,
                          shadowColor: Colors.black.withOpacity(0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Admin Portal',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(height: 32),
                                if (!_isLogin) ...[
                                  TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Admin Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 32),
                                
                                // Animated Button State
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: _buildButtonState(),
                                ),
                                
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _isLoading || _isSuccess ? null : () => setState(() => _isLogin = !_isLogin),
                                  child: Text(_isLogin ? 'New Admin? Register' : 'Already have an account? Login'),
                                ),
                                if (_isLogin)
                                  TextButton(
                                    onPressed: _isLoading || _isSuccess ? null : () {
                                      Globals.showSnackBar('Entering Demo Mode...');
                                      context.read<AuthProvider>().bypassLogin();
                                    },
                                    child: Text('Try Demo Mode', style: TextStyle(color: AppTheme.textMid.withOpacity(0.7), fontSize: 13)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Success Overlay Animation
          if (_isSuccess)
            Positioned.fill(
              child: Container(
                color: AppTheme.primary.withOpacity(0.9),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Colors.white, size: 100),
                            const SizedBox(height: 24),
                            const Text(
                              'Access Granted',
                              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome back, ${context.read<AuthProvider>().userName ?? "Admin"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.business_center, size: 80, color: Colors.white)),
        const SizedBox(height: 16),
        Text(
          'Learnyor',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
        ),
        const Text(
          'HR & Intern Management',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildButtonState() {
    if (_isSuccess) {
      return Container(
        key: const ValueKey('success'),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 32),
      );
    }

    if (_isLoading) {
      return const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        key: const ValueKey('button'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: ElevatedButton(
          onPressed: _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: Text(_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT'),
        ),
      ),
    );
  }
}
