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
  // Colors
  static const Color primaryRed = Color(0xFFC33939);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF616161);
  static const Color textSecondary = Colors.black54;

  // Services
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  // State
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
          
          // Set controllers with current values
          if (profile != null) {
            _fullNameController.text = profile.fullName;
            _emailController.text = profile.email;
            
            // Email can only be changed for email/password accounts (not Google)
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

  Future<void> _saveChanges() async {
    // Basic validation
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
        // Update name in Firestore
        bool success = await _userProfileService.updateUserProfile(
          userId, 
          {'fullName': _fullNameController.text.trim()}
        );

        // Update email if changed and enabled
        if (_isEmailEnabled && 
            _emailController.text.trim() != _userProfile?.email &&
            _emailController.text.contains('@')) {
          try {
            await _authService.getCurrentUser()?.updateEmail(_emailController.text.trim());
            success = await _userProfileService.updateUserProfile(
              userId, 
              {'email': _emailController.text.trim()}
            );
          } catch (e) {
            _showMessage('Failed to update email: ${e.toString()}');
            // Continue with other updates even if email update fails
          }
        }

        if (success) {
          _showMessage('Account details updated successfully');
          // Reload profile
          await _loadUserProfile();
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

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          // Navigate to login screen
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Full Name
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  TextField(
                    controller: _emailController,
                    enabled: _isEmailEnabled,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                      suffixIcon: !_isEmailEnabled
                          ? const Tooltip(
                              message: 'Email cannot be changed for accounts linked with Google',
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
                  
                  // Security section
                  const Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Reset password button
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
                  
                  // Danger zone
                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Delete account button
                  OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('Delete Account'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}