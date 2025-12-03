import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../utils/countries.dart';
import '../../utils/notification_helper.dart';

class EditProfileDialog extends StatefulWidget {
  final AppUser user;

  const EditProfileDialog({super.key, required this.user});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _photoUrlController;
  CountryData? _selectedCountry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );
    _photoUrlController = TextEditingController(text: widget.user.photoURL);

    // Find matching country or default to St. Vincent
    if (widget.user.countryCode != null) {
      _selectedCountry = countries.firstWhere(
        (c) => c.code == widget.user.countryCode,
        orElse: () => countries.first,
      );
    } else {
      _selectedCountry = countries.first; // St. Vincent by default
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      context.showError('Username is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.updateUserProfile(
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : null,
        country: _selectedCountry?.name,
        countryCode: _selectedCountry?.code,
        photoURL: _photoUrlController.text.trim().isNotEmpty
            ? _photoUrlController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        context.showSuccess('Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.grey900,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.grey400),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    Text(
                      'Username *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grey200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Enter username',
                        hintStyle: TextStyle(color: AppTheme.grey600),
                        filled: true,
                        fillColor: AppTheme.grey800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryPurple),
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                    ),
                    const SizedBox(height: 16),

                    // Display Name
                    Text(
                      'Display Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grey200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter display name',
                        hintStyle: TextStyle(color: AppTheme.grey600),
                        filled: true,
                        fillColor: AppTheme.grey800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryPurple),
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                    ),
                    const SizedBox(height: 16),

                    // Photo URL
                    Text(
                      'Profile Photo URL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grey200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _photoUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/photo.jpg',
                        hintStyle: TextStyle(color: AppTheme.grey600),
                        filled: true,
                        fillColor: AppTheme.grey800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryPurple),
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.white),
                    ),
                    const SizedBox(height: 16),

                    // Country Dropdown
                    Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grey200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CountryData>(
                      initialValue: _selectedCountry,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.grey800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryPurple),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: AppTheme.grey800,
                      style: const TextStyle(color: AppTheme.white),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.grey400,
                      ),
                      items: countries.map((country) {
                        return DropdownMenuItem<CountryData>(
                          value: country,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                country.flag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  country.name,
                                  style: const TextStyle(color: AppTheme.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                country.code,
                                style: TextStyle(
                                  color: AppTheme.grey400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (CountryData? value) {
                        setState(() {
                          _selectedCountry = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.grey400),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
