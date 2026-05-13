import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/emergency_contacts_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../utils/phone_utils.dart';
import '../widgets/contact_card.dart';
import '../widgets/contact_priority_selector.dart';
import '../widgets/jepo_phone_input.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/verification_dialog.dart';

class _FamilyMember {
  final int? id;
  final String name;
  final String phone;
  final int priority;
  final ContactVerificationStatus status;

  _FamilyMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.priority,
    required this.status,
  });

  bool get isPending => status == ContactVerificationStatus.pending;
}

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<_FamilyMember> _familyMembers = <_FamilyMember>[];
  bool _isLoading = true;
  bool _hasSession = false;
  int? _selectedContactIndex;

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
      if (!mounted) return;
      setState(() {
        _familyMembers = <_FamilyMember>[];
        _selectedContactIndex = null;
        _isLoading = false;
      });
      return;
    }

    try {
      final ecService = EmergencyContactsService(appApi);
      final list = await ecService.listContacts();
      final mapped = list
          .map<_FamilyMember>((e) {
            final rawPhone = e.telefonoContacto;
            return _FamilyMember(
              id: e.id,
              name: e.nombreContacto.isEmpty ? 'Desconocido' : e.nombreContacto,
              phone: rawPhone.isEmpty
                  ? ''
                  : formatToE164(normalizePhoneForApi(rawPhone)),
              priority: e.prioridad,
              status: e.estadoVerificacion,
            );
          })
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _familyMembers = mapped;
        if (_selectedContactIndex != null &&
            (_selectedContactIndex! < 0 ||
                _selectedContactIndex! >= mapped.length)) {
          _selectedContactIndex = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load contacts: $e');
      if (!mounted) return;

      String msg = 'Error al cargar los contactos';
      if (e is ApiException) {
        msg = e.errors.isNotEmpty ? e.errors.join(', ') : e.message;
      } else {
        msg = e.toString();
      }
      AppToast.error(context, msg);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Creates the contact. On success, triggers the verification dialog
  /// automatically for the freshly created contact.
  Future<void> _addContact(String name, String phone, int priority) async {
    if (!_hasSession) return;

    try {
      final ecService = EmergencyContactsService(appApi);
      final created = await ecService.createContact(
        CreateEmergencyContactDto(
          nombreContacto: name,
          telefonoContacto: phone,
          prioridad: priority,
        ),
      );

      await _loadContacts();
      if (!mounted) return;
      AppToast.success(context, 'Contacto añadido. Verifica el código.');

      // ── AUTO-OPEN VERIFICATION DIALOG ──────────────────────────────
      if (created?.id != null) {
        // Let the sheet close and the list rebuild before opening the dialog.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        await showVerificationDialog(
          context: context,
          contactId: created!.id!,
          contactName: created.nombreContacto,
        );
        if (!mounted) return;
        await _loadContacts(); // reflect VERIFIED/PENDING after the dialog
      }
    } catch (e) {
      debugPrint('Failed to add contact: $e');
      if (!mounted) return;
      String msg = 'Error al añadir el contacto';
      if (e is ApiException) {
        msg = e.errors.isNotEmpty ? e.errors.join('\n') : e.message;
      }
      AppToast.error(context, msg);
    }
  }

  Future<void> _updateContact(
    _FamilyMember member,
    String name,
    String phone,
    int priority,
  ) async {
    if (member.id == null) return;

    try {
      final ecService = EmergencyContactsService(appApi);
      final payload = UpdateEmergencyContactDto(
        nombreContacto: name,
        telefonoContacto: phone,
        prioridad: priority,
      );
      await ecService.updateContact(member.id!, payload);
      await _loadContacts();
      if (!mounted) return;
      AppToast.success(context, 'Contacto actualizado');
    } catch (e) {
      debugPrint('Failed to update contact: $e');
      if (!mounted) return;
      String msg = 'Error al actualizar el contacto';
      if (e is ApiException) {
        msg = e.errors.isNotEmpty ? e.errors.join('\n') : e.message;
      }
      AppToast.error(context, msg);
    }
  }

  void _showAddContactDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactBottomSheet(
        existingContacts: _familyMembers,
        onSubmit: _addContact,
      ),
    );
  }

  void _showEditForMember(_FamilyMember member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContactBottomSheet(
        initialMember: member,
        existingContacts: _familyMembers,
        onSubmit: (name, phone, priority) =>
            _updateContact(member, name, phone, priority),
      ),
    );
  }

  void _showDeleteForMember(_FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEEEEEE),
          title: const Text('Eliminar contacto'),
          content: Text('Se eliminará a ${member.name} de tus contactos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Color(0xFFFF5151)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || member.id == null) return;

    try {
      await EmergencyContactsService(appApi).deleteContact(member.id!);
      await _loadContacts();
      if (!mounted) return;
      AppToast.success(context, 'Contacto eliminado');
    } catch (e) {
      debugPrint('Failed to delete contact: $e');
      if (!mounted) return;
      AppToast.error(context, 'Error al eliminar el contacto');
    }
  }

  /// Opens the verification dialog for a specific contact. After the dialog
  /// closes (whether the contact was verified or not), the list is reloaded
  /// so the badge updates.
  Future<void> _showVerifyForMember(_FamilyMember member) async {
    if (member.id == null) return;
    await showVerificationDialog(
      context: context,
      contactId: member.id!,
      contactName: member.name,
    );
    if (!mounted) return;
    await _loadContacts();
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
                'Se requiere iniciar sesion para gestionar los contactos de emergencia.',
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
                        final selected = _selectedContactIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ContactCard(
                            name: member.name,
                            phone: member.phone,
                            priority: member.priority,
                            isSelected: selected,
                            status: _mapStatus(member.status),
                            onTap: () {
                              setState(() {
                                _selectedContactIndex = index;
                              });
                            },
                            onEdit: () => _showEditForMember(member),
                            onDelete: () => _showDeleteForMember(member),
                            onVerify: member.isPending
                                ? () => _showVerifyForMember(member)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        child: FloatingActionButton(
          heroTag: 'fab_add_contact',
          backgroundColor: const Color(0xFFEEEEEE),
          elevation: 0,
          onPressed: () {
            if (_familyMembers.length >= 5) {
              AppToast.warning(context, 'Maximo de 5 contactos permitidos');
              return;
            }
            _showAddContactDialog();
          },
          child: const Icon(Icons.add, color: AppTheme.primary),
        ),
      ),
    );
  }

  ContactCardStatus _mapStatus(ContactVerificationStatus s) {
    switch (s) {
      case ContactVerificationStatus.verified:
        return ContactCardStatus.verified;
      case ContactVerificationStatus.rejected:
        return ContactCardStatus.rejected;
      case ContactVerificationStatus.pending:
        return ContactCardStatus.pending;
    }
  }
}

class _ContactBottomSheet extends StatefulWidget {
  final _FamilyMember? initialMember;
  final List<_FamilyMember> existingContacts;
  final Future<void> Function(String name, String phone, int priority) onSubmit;

  const _ContactBottomSheet({
    required this.existingContacts,
    required this.onSubmit,
    this.initialMember,
  });

  @override
  State<_ContactBottomSheet> createState() => _ContactBottomSheetState();
}

class _ContactBottomSheetState extends State<_ContactBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  int _selectedPriority = 3;
  bool _isLoading = false;
  bool _phoneValid = false;

  bool get _isEdit => widget.initialMember != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMember;
    if (initial != null) {
      _nameController.text = initial.name;
      _phoneController.text = _toLocalPhone(initial.phone);
      _selectedPriority = initial.priority.clamp(1, 3);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + insets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF747877).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEdit ? 'Editar Contacto' : 'Añadir Contacto',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Define prioridad y telefono de contacto para alertas de emergencia.',
                style: TextStyle(color: Color(0xFF747877), fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildLabel('Nombre completo'),
              NeumorphicTextField(
                controller: _nameController,
                hintText: 'Ej. Juan Perez',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 18),
              JepoPhoneInput(
                controller: _phoneController,
                label: 'Numero de telefono',
                onValidityChanged: (isValid) {
                  if (_phoneValid != isValid) {
                    setState(() => _phoneValid = isValid);
                  }
                },
              ),
              const SizedBox(height: 18),
              _buildLabel('Prioridad de contacto'),
              const SizedBox(height: 8),
              ContactPrioritySelector(
                selectedPriority: _selectedPriority,
                onChanged: (priority) {
                  setState(() => _selectedPriority = priority);
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: _isLoading ? () {} : _handleSave,
                  color: const Color(0xFF7FCCC4),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEdit ? 'GUARDAR CAMBIOS' : 'AÑADIR CONTACTO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
            ],
          ),
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
          color: Color(0xFF747877),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      AppToast.warning(context, 'Nombre requerido');
      return;
    }

    if (!_phoneValid || phone.length != 11) {
      AppToast.warning(
        context,
        'Telefono invalido: completa prefijo + 7 digitos',
      );
      return;
    }

    final normalized = normalizePhoneForApi(phone);
    if (normalized.length != 12 || !normalized.startsWith('58')) {
      AppToast.warning(context, 'Telefono invalido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = AuthService(appApi);
      final hasSession = await auth.hasActiveSession();
      if (!hasSession) {
        if (mounted) AppToast.error(context, 'Por favor, inicia sesion');
        return;
      }

      final existing = widget.existingContacts
          .where((m) => m.id != widget.initialMember?.id)
          .toList(growable: false);

      if (!_isEdit && existing.length >= 5) {
        if (mounted) {
          AppToast.warning(context, 'Maximo de 5 contactos permitidos');
        }
        return;
      }

      for (final m in existing) {
        if (normalizePhoneForApi(m.phone) == normalized) {
          if (mounted) AppToast.warning(context, 'Ya existe este contacto');
          return;
        }
      }

      await widget.onSubmit(name, phone, _selectedPriority);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _toLocalPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('0')) return digits;
    if (digits.length == 10) return '0$digits';
    if (digits.length == 12 && digits.startsWith('58')) {
      return '0${digits.substring(2)}';
    }
    return digits;
  }
}
