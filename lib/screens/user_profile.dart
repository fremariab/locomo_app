import 'package:flutter/material.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';

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
                    onPressed: () {},
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
              child: Container(
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
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: lightGrey, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.asset(
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
                          const SizedBox(height: 16),
                          const Text(
                            'Freda-Marie Beecham',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Registered on 29 April 2022',
                            style: TextStyle(
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
                          onTap: () {},
                        ),
                        _buildSettingsItem(
                          icon: Icons.alt_route_outlined,
                          title: 'Saved Routes',
                          onTap: () {},
                        ),
                        _buildSettingsItem(
                          icon: Icons.language,
                          title: 'Language',
                          value: 'English',
                          showChevron: true,
                          onTap: () {},
                        ),
                        _buildSettingsItem(
                          icon: Icons.public,
                          title: 'Country of Residence',
                          value: 'Ghana',
                          showChevron: true,
                          onTap: () {},
                        ),
                        _buildSettingsItem(
                          icon: Icons.calendar_today,
                          title: 'Default search date',
                          showChevron: true,
                          onTap: () {},
                        ),
                        _buildSettingsItem(
                          icon: Icons.brightness_6_outlined,
                          title: 'Appearance',
                          value: 'Light',
                          showChevron: true,
                          onTap: () {},
                        ),

                        // Sign Out
                        Container(
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
                              Icon(Icons.logout,
                                  color: darkGrey.withOpacity(0.6), size: 20),
                            ],
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
