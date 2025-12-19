import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> familyMembers = [
      {'name': 'Martha Castillo', 'relation': 'Mother', 'status': 'Safe'},
      {'name': 'Carlos Castillo', 'relation': 'Father', 'status': 'At Work'},
      {'name': 'Sofia Castillo', 'relation': 'Sister', 'status': 'School'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'My Family',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: familyMembers.length,
        itemBuilder: (context, index) {
          final member = familyMembers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: NeumorphicContainer(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          member['relation']!,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      member['status']!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
