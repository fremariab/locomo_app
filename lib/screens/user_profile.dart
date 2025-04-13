import 'dart:io';
import 'package:flutter/material.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';
import 'package:locomo_app/services/auth_service.dart';
import 'package:locomo_app/services/user_service.dart';
import 'package:locomo_app/models/user_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'login.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen> {
  // Inline colors
  static const Color primaryRed = Color(0xFFC33939);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF616161);
  static const Color iconGrey = Color(0xFF757575);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;

  // Services
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  
  // State variables
  UserProfile? _userProfile;
  bool _isLoading = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        final profile = await _userProfileService.getUserProfile(userId);
        setState(() {
          _userProfile = profile;
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

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        final userId = _authService.getCurrentUser()?.uid;
        if (userId != null) {
          _showMessage('Uploading image...');
          final imageUrl = await _userProfileService.uploadProfileImage(userId, _selectedImage!);
          if (imageUrl != null) {
            _showMessage('Profile image updated');
            _loadUserProfile();
          } else {
            _showMessage('Failed to upload image');
          }
        }
      }
    } catch (e) {
      _showMessage('Error selecting image: ${e.toString()}');
    }
  }

  Future<void> _updateCountry() async {
    final countries = [
      'Ghana'
    ];

    final selectedCountry = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Country'),
        children: countries.map((country) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, country),
            child: Text(country),
          );
        }).toList(),
      ),
    );

    if (selectedCountry != null) {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        final success = await _userProfileService.updateCountry(userId, selectedCountry);
        if (success) {
          _showMessage('Country updated');
          _loadUserProfile();
        } else {
          _showMessage('Failed to update country');
        }
      }
    }
  }

/*   Future<void> _updateLanguage() async {
    final languages = ['English', 'French', 'Swahili', 'Arabic', 'Portuguese', 'Amharic'];

    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: languages.map((language) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, language),
            child: Text(language),
          );
        }).toList(),
      ),
    );

    if (selectedLanguage != null) {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        final success = await _userProfileService.updateLanguage(userId, selectedLanguage);
        if (success) {
          _showMessage('Language updated');
          _loadUserProfile();
        } else {
          _showMessage('Failed to update language');
        }
      }
    }
  } */

/*   Future<void> _updateAppearance() async {
    final appearances = ['Light', 'Dark', 'System'];

    final selectedAppearance = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Appearance'),
        children: appearances.map((appearance) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, appearance),
            child: Text(appearance),
          );
        }).toList(),
      ),
    );

    if (selectedAppearance != null) {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        final success = await _userProfileService.updateAppearance(userId, selectedAppearance);
        if (success) {
          _showMessage('Appearance updated');
          _loadUserProfile();
        } else {
          _showMessage('Failed to update appearance');
        }
      }
    }
  }
 */
  Future<void> _updateDefaultSearchDate() async {
    final initialDate = _userProfile?.defaultSearchDate ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        final success = await _userProfileService.updateDefaultSearchDate(userId, selectedDate);
        if (success) {
          _showMessage('Default search date updated');
          _loadUserProfile();
        } else {
          _showMessage('Failed to update default search date');
        }
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      _showMessage('Error signing out: ${e.toString()}');
    }
  }

  String _formatRegistrationDate(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar
            Container(
              color: primaryRed,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Profile Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      color: white,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Profile Header
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: lightGrey, width: 2),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(40),
                                          child: _userProfile?.profileImageUrl != null
                                              ? Image.network(
                                                  _userProfile!.profileImageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const CircleAvatar(
                                                      radius: 40,
                                                      backgroundColor: lightGrey,
                                                      child: Icon(Icons.person,
                                                          size: 40, color: darkGrey),
                                                    );
                                                  },
                                                )
                                              : Image.asset(
                                                  'assets/images/profile_placeholder.jpg',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const CircleAvatar(
                                                      radius: 40,
                                                      backgroundColor: lightGrey,
                                                      child: Icon(Icons.person,
                                                          size: 40, color: darkGrey),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: primaryRed,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _userProfile?.fullName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Registered on ${_userProfile != null ? _formatRegistrationDate(_userProfile!.createdAt) : 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Settings Items
                          const Divider(color: lightGrey, height: 1),
                          Column(
                            children: [
                              _buildSettingsItem(
                                icon: Icons.account_circle_outlined,
                                title: 'Account Details',
                                onTap: () {
                                  // Navigate to account details screen
                                  Navigator.pushNamed(context, '/account-details');
                                },
                              ),
                              _buildSettingsItem(
                                icon: Icons.alt_route_outlined,
                                title: 'Saved Routes',
                                onTap: () {
                                  // Navigate to saved routes screen
                                  Navigator.pushNamed(context, '/saved-routes');
                                },
                              ),
/*                               _buildSettingsItem(
                                icon: Icons.language,
                                title: 'Language',
                                value: _userProfile?.language ?? 'English',
                                showChevron: true,
                                onTap: _updateLanguage,
                              ), */
                              _buildSettingsItem(
                                icon: Icons.public,
                                title: 'Country of Residence',
                                value: _userProfile?.country ?? 'Ghana',
                                showChevron: true,
                                onTap: _updateCountry,
                              ),
                              _buildSettingsItem(
                                icon: Icons.calendar_today,
                                title: 'Default search date',
                                value: _userProfile?.defaultSearchDate != null
                                    ? DateFormat('dd MMM yyyy').format(_userProfile!.defaultSearchDate!)
                                    : null,
                                showChevron: true,
                                onTap: _updateDefaultSearchDate,
                              ),
/*                               _buildSettingsItem(
                                icon: Icons.brightness_6_outlined,
                                title: 'Appearance',
                                value: _userProfile?.appearance ?? 'Light',
                                showChevron: true,
                                onTap: _updateAppearance,
                              ), */

                              // Sign Out
                              InkWell(
                                onTap: _signOut,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 24),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout, color: darkGrey),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Sign out',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.chevron_right,
                                          color: darkGrey.withOpacity(0.6), size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? value,
    bool showChevron = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: lightGrey, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: darkGrey),
            const SizedBox(width: 16),
            Text(
              title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: textSecondary),
              ),
            if (showChevron)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.chevron_right, color: darkGrey, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}