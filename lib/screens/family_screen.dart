import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/emergency_contacts_service.dart';
import '../utils/phone_utils.dart';
import '../utils/app_toast.dart';

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
        final rawPhone = e.telefonoContacto;
        return _FamilyMember(
          id: e.id,
          name: e.nombreContacto.isEmpty ? 'Desconocido' : e.nombreContacto,
          phone: rawPhone.isEmpty
              ? ''
              : formatToE164(normalizePhoneForApi(rawPhone)),
          priority: e.prioridad,
        );
      }).toList();

      setState(() {
        _familyMembers = mapped;
        _isLoading = false;
      });
      return;
    } catch (e) {
      debugPrint('Failed to load contacts: $e');
      if (mounted) {
        String msg = 'Error al cargar los contactos';
        if (e is ApiException) {
          msg = e.errors.isNotEmpty
              ? e.errors.join(', ')
              : e.message;
        } else {
          msg = e.toString();
        }

        AppToast.error(context, msg);
      }

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
      final payload = CreateEmergencyContactDto(
        nombreContacto: name,
        telefonoContacto: phone,
        prioridad: int.tryParse(relation) ?? 1,
      );
      await ecService.createContact(payload);
      await _loadContacts();
      return;
    } catch (e) {
      debugPrint('Failed to add contact: $e');
      if (mounted) {
        String msg = 'Error al añadir el contacto';
        if (e is ApiException) {
          msg = e.errors.isNotEmpty ? e.errors.join('\n') : e.message;
        }
        AppToast.error(context, msg);
      }
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
        title: const Text('Añadir Familiar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (ej., +1234567890)',
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Prioridad (1-5)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relation = relationController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                AppToast.warning(context, 'Nombre y teléfono son requeridos');
                return;
              }

              final normalized = normalizePhoneForApi(phone);
              // Server expects a numeric string; enforce length 7-30 (docs)
              if (normalized.isEmpty ||
                  normalized.length < 7 ||
                  normalized.length > 30) {
                AppToast.warning(context, 'Número de teléfono inválido');
                return;
              }

              // Priority validation: should be an integer 1..5
              final priority = int.tryParse(relation) ?? -1;
              if (priority < 1 || priority > 5) {
                AppToast.warning(context, 'La prioridad debe ser un número entre 1 y 5');
                return;
              }

              // If remote mode / active session, enforce uniqueness and max count
              final auth = AuthService(appApi);
              final hasSession = await auth.hasActiveSession();
              if (!hasSession) {
                AppToast.error(context, 'Por favor, inicia sesión para gestionar los contactos de emergencia');
                return;
              }

              final existing = _familyMembers
                  .where((m) => m.id != null)
                  .toList();
              // Check max 5 contacts
              if (existing.length >= 5) {
                AppToast.warning(context, 'Máximo de 5 contactos permitidos');
                return;
              }
              // Check duplicates by normalized phone
              final incomingNorm = normalized;
              for (final m in existing) {
                final existingNorm = normalizePhoneForApi(m.phone);
                if (existingNorm == incomingNorm) {
                  AppToast.warning(context, 'Ya existe un contacto con este teléfono');
                  return;
                }
              }

              await _addContact(name, phone, relation);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Añadir'),
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
          'Mi Familia',
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
                'Se requiere iniciar sesión para gestionar los contactos de emergencia.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
            )
          : _familyMembers.isEmpty
          ? const Center(
              child: Text(
                'No se han añadido contactos de emergencia.\nToca + para añadir contactos.',
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
                                    'Prioridad ${member.priority}',
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
