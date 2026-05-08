import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/contact_priority_selector.dart';
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
          msg = e.errors.isNotEmpty ? e.errors.join(', ') : e.message;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddContactBottomSheet(
        onAdd: (name, phone, priority) =>
            _addContact(name, phone, priority.toString()),
        existingContacts: _familyMembers,
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
          : RefreshIndicator(
              onRefresh: _loadContacts,
              color: AppTheme.primary,
              child: _familyMembers.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: const Center(
                            child: Text(
                              'No se han añadido contactos de emergencia.\nToca + para añadir contactos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textLight),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _familyMembers.length,
                      itemBuilder: (context, index) {
                        final member = _familyMembers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Dismissible(
                            key: ValueKey(member.id ?? member.phone),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              final id = member.id;
                              setState(() {
                                _familyMembers.removeAt(index);
                              });
                              if (id != null) {
                                EmergencyContactsService(
                                  appApi,
                                ).deleteContact(id);
                              }
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            child: NeumorphicContainer(
                              useAnimation: false,
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight.withOpacity(
                                        0.3,
                                      ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddContactBottomSheet extends StatefulWidget {
  final Function(String name, String phone, int priority) onAdd;
  final List<_FamilyMember> existingContacts;

  const _AddContactBottomSheet({
    required this.onAdd,
    required this.existingContacts,
  });

  @override
  State<_AddContactBottomSheet> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends State<_AddContactBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedPriority = 3;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: 32 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Añadir Contacto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los contactos de emergencia recibirán alertas cuando se detecte un incidente.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 14),
            ),
            const SizedBox(height: 32),

            _buildLabel('Nombre completo'),
            NeumorphicTextField(
              controller: _nameController,
              hintText: 'Ej. Juan Pérez',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 24),

            _buildLabel('Número de teléfono'),
            NeumorphicTextField(
              controller: _phoneController,
              hintText: '+1234567890',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            _buildLabel('Prioridad de contacto'),
            const SizedBox(height: 8),
            _buildPrioritySelector(),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: NeumorphicButton(
                onPressed: _isLoading ? () {} : _handleSave,
                color: AppTheme.primary,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'AÑADIR FAMILIAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textLight,
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return ContactPrioritySelector(
      selectedPriority: _selectedPriority,
      onChanged: (priority) => setState(() => _selectedPriority = priority),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      AppToast.warning(context, 'Nombre y teléfono son requeridos');
      return;
    }

    final normalized = normalizePhoneForApi(phone);
    if (normalized.isEmpty || normalized.length < 7 || normalized.length > 30) {
      AppToast.warning(context, 'Número de teléfono inválido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = AuthService(appApi);
      final hasSession = await auth.hasActiveSession();
      if (!hasSession) {
        if (mounted) AppToast.error(context, 'Por favor, inicia sesión');
        return;
      }

      final existing = widget.existingContacts
          .where((m) => m.id != null)
          .toList();
      if (existing.length >= 5) {
        if (mounted)
          AppToast.warning(context, 'Máximo de 5 contactos permitidos');
        return;
      }

      for (final m in existing) {
        if (normalizePhoneForApi(m.phone) == normalized) {
          if (mounted) AppToast.warning(context, 'Ya existe este contacto');
          return;
        }
      }

      await widget.onAdd(name, phone, _selectedPriority);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
