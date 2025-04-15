import 'package:flutter/material.dart';
import 'package:locomo_app/services/auth_service.dart';
import 'package:locomo_app/services/user_service.dart';
import 'package:locomo_app/models/user_profile.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({Key? key}) : super(key: key);

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  // Colors used in the UI
  static const Color primaryRed = Color(0xFFC32E31);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFD9D9D9);
  static const Color darkGrey = Color(0xFF656565);
  static const Color textSecondary = Colors.black54;

  // Auth and user profile services
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();

  // For controlling text input fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _userProfile;
  bool _isEmailEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Helper to show small messages on the screen
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Load user profile from Firebase
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final profile = await _userProfileService.getUserProfile(user.uid);
        setState(() {
          _userProfile = profile;

          if (profile != null) {
            _fullNameController.text = profile.fullName;
            _emailController.text = profile.email;

            // Only allow email change if not signed in with Google
            _isEmailEnabled = profile.authProvider != 'google';
          }
        });
      }
    } catch (e) {
      _showMessage('Error loading profile: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save any changes the user made
  Future<void> _saveChanges() async {
    if (_fullNameController.text.trim().isEmpty) {
      _showMessage('Name cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        // Save new name
        bool success = await _userProfileService.updateUserProfile(
          userId,
          {'fullName': _fullNameController.text.trim()},
        );

        // If email changed and editable, try to update
        if (_isEmailEnabled &&
            _emailController.text.trim() != _userProfile?.email &&
            _emailController.text.contains('@')) {
          try {
            await _authService.getCurrentUser()
                ?.updateEmail(_emailController.text.trim());

            success = await _userProfileService.updateUserProfile(
              userId,
              {'email': _emailController.text.trim()},
            );
          } catch (e) {
            _showMessage('Failed to update email: ${e.toString()}');
          }
        }

        if (success) {
          _showMessage('Account details updated successfully');
          await _loadUserProfile(); // Reload data to reflect changes
        } else {
          _showMessage('Failed to update account details');
        }
      }
    } catch (e) {
      _showMessage('Error saving changes: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Ask Firebase to send a password reset email
  Future<void> _resetPassword() async {
    try {
      final email = _userProfile?.email;
      if (email != null && email.isNotEmpty) {
        final result = await _authService.resetPassword(email);
        if (result) {
          _showMessage('Password reset email sent to $email');
        } else {
          _showMessage('Failed to send password reset email');
        }
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  // Show confirmation and delete user account if confirmed
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('Are you sure you want to delete your account? This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Color(0xFFC32E31)),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _authService.deleteAccount();
        if (success) {
          _showMessage('Account deleted successfully');
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          _showMessage('Failed to delete account');
        }
      } catch (e) {
        _showMessage('Error deleting account: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryRed,
        title: const Text('Account Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Full name field
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  TextField(
                    controller: _emailController,
                    enabled: _isEmailEnabled,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                      suffixIcon: !_isEmailEnabled
                          ? const Tooltip(
                              message: 'Can’t edit email for Google accounts',
                              child: Icon(Icons.info_outline, color: textSecondary),
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: white,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: white)
                          : const Text('SAVE CHANGES'),
                    ),
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    'Security',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Reset password button (only for email/password users)
                  _userProfile?.authProvider != 'google'
                      ? OutlinedButton.icon(
                          onPressed: _resetPassword,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Reset Password'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 48),

                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC32E31),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delete account button
                  OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Color(0xFFC32E31)),
                    label: const Text('Delete Account'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Color(0xFFC32E31),
                      side: const BorderSide(color: Color(0xFFC32E31)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
