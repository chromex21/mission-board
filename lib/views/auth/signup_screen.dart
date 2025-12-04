import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../widgets/profile/mission_id_card.dart';
import '../../utils/notification_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Account credentials
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 2: Profile information
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedCountry;
  String? _selectedCountryCode;
  UserRole _selectedRole = UserRole.worker;

  bool _isLoading = false;
  AppUser? _previewUser;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (_currentStep == 2) {
      _generatePreview();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateStep1() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('Please enter a valid email');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_displayNameController.text.isEmpty) {
      _showError('Please enter your name');
      return false;
    }
    return true;
  }

  void _generatePreview() {
    // Generate temporary user for preview
    final tempUid = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _previewUser = AppUser(
        uid: tempUid,
        email: _emailController.text.trim(),
        role: _selectedRole,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        country: _selectedCountry,
        countryCode: _selectedCountryCode,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        createdAt: DateTime.now(),
      );
    });
  }

  Future<void> _completeSignup() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create account
      await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        role: _selectedRole,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        country: _selectedCountry,
        countryCode: _selectedCountryCode,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      if (mounted) {
        // Show success message
        context.showSuccess('Mission ID created successfully! 🎉');

        // Navigation will be handled by main.dart auth state
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    context.showError(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      appBar: AppBar(
        title: const Text('Create Mission ID'),
        backgroundColor: AppTheme.grey900,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.grey900,
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? AppTheme.primaryPurple
                    : AppTheme.grey700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    final screenWidth = MediaQuery.of(context).size.width;
    double formWidth;

    if (screenWidth > 1200) {
      formWidth = 500;
    } else if (screenWidth > 800) {
      formWidth = 420;
    } else {
      formWidth = double.infinity;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: BoxConstraints(maxWidth: formWidth),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Credentials',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your secure login',
                  style: TextStyle(color: AppTheme.grey400),
                ),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.grey900,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.grey900,
                  ),
                  obscureText: _obscurePassword,
                ),

                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.grey900,
                  ),
                  obscureText: _obscureConfirmPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final screenWidth = MediaQuery.of(context).size.width;
    double formWidth;

    if (screenWidth > 1200) {
      formWidth = 500;
    } else if (screenWidth > 800) {
      formWidth = 420;
    } else {
      formWidth = double.infinity;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: BoxConstraints(maxWidth: formWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about yourself',
                style: TextStyle(color: AppTheme.grey400),
              ),
              const SizedBox(height: 32),

              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey900,
                ),
              ),

              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (optional)',
                  prefixIcon: const Icon(Icons.alternate_email),
                  hintText: 'agentsmith',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey900,
                ),
              ),

              const SizedBox(height: 16),

              // Country Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCountryCode,
                decoration: InputDecoration(
                  labelText: 'Country',
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey900,
                ),
                items: _getCountries().map((country) {
                  return DropdownMenuItem(
                    value: country['code'],
                    child: Row(
                      children: [
                        Text(country['flag']!),
                        const SizedBox(width: 8),
                        Text(country['name']!),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountryCode = value;
                    _selectedCountry = _getCountries().firstWhere(
                      (c) => c['code'] == value,
                    )['name'];
                  });
                },
              ),

              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hintText: '+1 234 567 8900',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey900,
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio (optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                  hintText: 'A few words about you...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.grey900,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Role Selection
              Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey400,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.worker,
                      icon: Icons.military_tech,
                      title: 'Agent',
                      description: 'Complete missions',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.admin,
                      icon: Icons.admin_panel_settings,
                      title: 'Admin',
                      description: 'Create missions',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withValues(alpha: 0.2)
              : AppTheme.grey900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppTheme.grey700,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryPurple : AppTheme.grey600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryPurple : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: AppTheme.grey400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth;

    if (screenWidth > 1200) {
      cardWidth = 500;
    } else if (screenWidth > 800) {
      cardWidth = 420;
    } else {
      cardWidth = double.infinity;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: BoxConstraints(maxWidth: cardWidth),
          child: Column(
            children: [
              Text(
                'Your Mission ID',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preview your digital identity',
                style: TextStyle(color: AppTheme.grey400),
              ),
              const SizedBox(height: 32),

              if (_previewUser != null)
                MissionIdCard(user: _previewUser!, isFlippable: true),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.grey900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.grey700),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.infoBlue,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the card to flip and see more details',
                      style: TextStyle(color: AppTheme.grey400, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        border: Border(top: BorderSide(color: AppTheme.grey700)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.grey700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _currentStep < 2
                  ? _nextStep
                  : _completeSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(0, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep < 2 ? 'Continue' : 'Create Mission ID'),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getCountries() {
    return [
      {'code': 'VC', 'name': 'St. Vincent and the Grenadines', 'flag': '🇻🇨'},
      {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
      {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
      {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
      {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
      {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
      {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
      {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
      {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
      {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
      {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷'},
      {'code': 'MX', 'name': 'Mexico', 'flag': '🇲🇽'},
      {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
      {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
      {'code': 'NL', 'name': 'Netherlands', 'flag': '🇳🇱'},
      {'code': 'SE', 'name': 'Sweden', 'flag': '🇸🇪'},
      {'code': 'KR', 'name': 'South Korea', 'flag': '🇰🇷'},
      {'code': 'SG', 'name': 'Singapore', 'flag': '🇸🇬'},
      {'code': 'AE', 'name': 'UAE', 'flag': '🇦🇪'},
      {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦'},
      {'code': 'AR', 'name': 'Argentina', 'flag': '🇦🇷'},
      {'code': 'JM', 'name': 'Jamaica', 'flag': '🇯🇲'},
      {'code': 'TT', 'name': 'Trinidad and Tobago', 'flag': '🇹🇹'},
      {'code': 'BB', 'name': 'Barbados', 'flag': '🇧🇧'},
      {'code': 'GD', 'name': 'Grenada', 'flag': '🇬🇩'},
      {'code': 'LC', 'name': 'Saint Lucia', 'flag': '🇱🇨'},
    ];
  }
}
