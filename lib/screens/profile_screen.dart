import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image
            NeumorphicContainer(
              borderRadius: 100,
              padding: const EdgeInsets.all(10),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryLight,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Elianis Castillo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const Text(
              'elianis@example.com',
              style: TextStyle(color: AppTheme.textLight, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Options
            _buildProfileOption(context, 'Edit Profile', Icons.edit),
            _buildProfileOption(context, 'Notifications', Icons.notifications),
            _buildProfileOption(context, 'Privacy & Security', Icons.security),
            _buildProfileOption(context, 'Help & Support', Icons.help),
            _buildProfileOption(
              context,
              'Logout',
              Icons.logout,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon, {
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeumorphicButton(
        onPressed: () {},
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : AppTheme.textDark),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive
                  ? Colors.red.withOpacity(0.5)
                  : AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
