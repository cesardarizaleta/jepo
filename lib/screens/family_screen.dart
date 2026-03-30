import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/emergency_contacts_service.dart';
import '../utils/phone_utils.dart';

class _FamilyMember {
  final int? id;
  final String name;
  final String phone;
  final int priority;

  _FamilyMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.priority,
  });
}

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<_FamilyMember> _familyMembers = [];
  bool _isLoading = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final auth = AuthService(appApi);
    final hasSession = await auth.hasActiveSession();
    _hasSession = hasSession;

    if (!hasSession) {
      setState(() {
        _familyMembers = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final ecService = EmergencyContactsService(appApi);
      final list = await ecService.listContacts();
      final mapped = list.map<_FamilyMember>((e) {
        final map = e as Map<String, dynamic>;
        final rawPhone = map['telefono_contacto']?.toString() ?? '';
        return _FamilyMember(
          id: map['id'] as int?,
          name:
              map['nombre_contacto']?.toString() ??
              map['nombre']?.toString() ??
              'Unknown',
          phone: rawPhone.isEmpty
              ? ''
              : formatToE164(normalizePhoneForApi(rawPhone)),
          priority: map['prioridad'] is int
              ? map['prioridad'] as int
              : int.tryParse(map['prioridad']?.toString() ?? '') ?? 1,
        );
      }).toList();

      setState(() {
        _familyMembers = mapped;
        _isLoading = false;
      });
      return;
    } catch (e) {
      debugPrint('Failed to load contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addContact(String name, String phone, String relation) async {
    if (!_hasSession) {
      return;
    }

    try {
      final ecService = EmergencyContactsService(appApi);
      final normalized = normalizePhoneForApi(phone);
      final payload = {
        'nombre_contacto': name,
        'telefono_contacto': normalized,
        'prioridad': int.tryParse(relation) ?? 1,
      };
      await ecService.createContact(payload);
      await _loadContacts();
      return;
    } catch (e) {
      debugPrint('Failed to add contact: $e');
    }
  }

  Future<void> _deleteContact(int index) async {
    final target = _familyMembers[index];

    try {
      if (target.id != null) {
        final ecService = EmergencyContactsService(appApi);
        await ecService.deleteContact(target.id!);
        await _loadContacts();
        return;
      }
    } catch (e) {
      debugPrint('Failed to delete contact: $e');
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (e.g., +1234567890)',
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Priority (1-5)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relation = relationController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and phone are required')),
                );
                return;
              }

              final normalized = normalizePhoneForApi(phone);
              // Server expects a numeric string; enforce length 7-30 (docs)
              if (normalized.isEmpty ||
                  normalized.length < 7 ||
                  normalized.length > 30) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid phone number')),
                );
                return;
              }

              // Priority validation: should be an integer 1..5
              final priority = int.tryParse(relation) ?? -1;
              if (priority < 1 || priority > 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Priority must be a number between 1 and 5'),
                  ),
                );
                return;
              }

              // If remote mode / active session, enforce uniqueness and max count
              final auth = AuthService(appApi);
              final hasSession = await auth.hasActiveSession();
              if (!hasSession) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to manage emergency contacts'),
                  ),
                );
                return;
              }

              final existing = _familyMembers
                  .where((m) => m.id != null)
                  .toList();
              // Check max 5 contacts
              if (existing.length >= 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum of 5 contacts allowed'),
                  ),
                );
                return;
              }
              // Check duplicates by normalized phone
              final incomingNorm = normalized;
              for (final m in existing) {
                final existingNorm = normalizePhoneForApi(m.phone);
                if (existingNorm == incomingNorm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact with this phone already exists'),
                    ),
                  );
                  return;
                }
              }

              await _addContact(name, phone, relation);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSession
          ? const Center(
              child: Text(
                'Login required to manage emergency contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
            )
          : _familyMembers.isEmpty
          ? const Center(
              child: Text(
                'No emergency contacts added.\nTap + to add contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _familyMembers.length,
              itemBuilder: (context, index) {
                final member = _familyMembers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteContact(index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
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
                            child: const Icon(
                              Icons.person,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                if (member.priority > 0)
                                  Text(
                                    'Priority ${member.priority}',
                                    style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 14,
                                    ),
                                  ),
                                Text(
                                  member.phone,
                                  style: const TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
