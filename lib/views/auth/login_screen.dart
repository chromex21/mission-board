import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'signup_screen.dart';
import '../../utils/notification_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('last_login_email');
    if (savedEmail != null && mounted) {
      _emailController.text = savedEmail;
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login_email', email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      context.showWarning('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String emailOrUsername = _emailController.text.trim();

      // If input doesn't contain @, treat as username and try to find email
      if (!emailOrUsername.contains('@')) {
        // Try to find user by username in Firestore
        final email = await authProvider.getEmailByUsername(emailOrUsername);
        if (email != null) {
          emailOrUsername = email;
        } else {
          // Assume it might be email without domain, add common domains
          if (!emailOrUsername.contains('.')) {
            // Try common email providers
            throw Exception(
              'Username not found. Please enter full email or existing username.',
            );
          }
        }
      }

      await authProvider.signIn(emailOrUsername, _passwordController.text);

      // Save email for next time
      if (_rememberMe && mounted) {
        await _saveEmail(_emailController.text.trim());
      }

      if (mounted) {
        // Navigation handled by main.dart based on auth state
      }
    } catch (e) {
      if (mounted) {
        context.showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double formWidth;

    if (screenWidth > 1200) {
      formWidth = 480;
    } else if (screenWidth > 800) {
      formWidth = 420;
    } else {
      formWidth = screenWidth - 48;
    }

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: BoxConstraints(maxWidth: formWidth),
              child: Card(
                elevation: 8,
                color: AppTheme.grey900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.grey700),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.primaryPurple.withValues(alpha: 0.6),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.stars,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Mission Board',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Welcome back, Agent',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey400,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email/Username field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email or Username',
                            hintText: 'username or email@example.com',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppTheme.darkGrey,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email or username';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppTheme.darkGrey,
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 16),

                        // Remember me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _rememberMe = value ?? true;
                                      });
                                    },
                              fillColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppTheme.primaryPurple;
                                }
                                return null;
                              }),
                            ),
                            Text(
                              'Stay signed in',
                              style: TextStyle(color: AppTheme.grey400),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppTheme.grey700)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(color: AppTheme.grey600),
                              ),
                            ),
                            Expanded(child: Divider(color: AppTheme.grey700)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: AppTheme.grey400),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignupScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                'Create Mission ID',
                                style: TextStyle(
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}
