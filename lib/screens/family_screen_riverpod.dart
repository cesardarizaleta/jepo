import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../providers/contacts_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/contact_card.dart';
import '../widgets/verify_contact_dialog.dart';

/// Family screen powered entirely by Riverpod — no setState anywhere.
class FamilyScreenRiverpod extends ConsumerStatefulWidget {
  const FamilyScreenRiverpod({super.key});

  @override
  ConsumerState<FamilyScreenRiverpod> createState() =>
      _FamilyScreenRiverpodState();
}

class _FamilyScreenRiverpodState extends ConsumerState<FamilyScreenRiverpod> {
  bool _didInitialBuild = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
      if (isCurrent && _didInitialBuild && mounted) {
        // Force a reload when the route becomes visible so cache updates.
        ref.invalidate(contactsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _didInitialBuild = true;
    });

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
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(contactsProvider),
        color: AppTheme.primary,
        child: contactsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _errorState(context, e),
          data: (contacts) => contacts.isEmpty
              ? _emptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: contacts.length,
                  itemBuilder: (ctx, i) {
                    final c = contacts[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ContactCard(
                        name: c.name,
                        phone: c.phone,
                        priority: c.priority,
                        status: _statusToCard(c.status),
                        onEdit: () {
                          // TODO: open edit bottom sheet.
                        },
                        onDelete: () => _onDelete(context, ref, c),
                        onVerify: c.isPending
                            ? () => _onVerify(context, ref, c)
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_contact',
        backgroundColor: const Color(0xFFEEEEEE),
        elevation: 0,
        onPressed: () {
          // TODO: open add bottom sheet that calls
          //   ref.read(contactsMutationsProvider).add(...)
        },
        child: const Icon(Icons.add, color: Color(0xFF7FCCC4)),
      ),
    );
  }

  // ─── Callbacks ────────────────────────────────────────────────────────

  Future<void> _onVerify(
    BuildContext context,
    WidgetRef ref,
    FamilyContact contact,
  ) async {
    if (contact.id == null) return;
    await showVerifyContactDialog(
      context: context,
      contactId: contact.id!,
      contactName: contact.name,
    );
    // The dialog itself invalidates contactsProvider on success → the
    // Riverpod graph rebuilds the list automatically.
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    FamilyContact contact,
  ) async {
    if (contact.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFEEEEEE),
        title: const Text('Eliminar contacto'),
        content: Text('Se eliminará a ${contact.name} de tus contactos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFFF5151)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(contactsMutationsProvider).remove(contact.id!);
      if (context.mounted) AppToast.success(context, 'Contacto eliminado');
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Error al eliminar: $e');
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  ContactCardStatus _statusToCard(ContactVerificationStatus s) {
    switch (s) {
      case ContactVerificationStatus.verified:
        return ContactCardStatus.verified;
      case ContactVerificationStatus.rejected:
        return ContactCardStatus.rejected;
      case ContactVerificationStatus.pending:
        return ContactCardStatus.pending;
    }
  }

  Widget _emptyState(BuildContext context) => ListView(
    children: [
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(
          child: Text(
            'No se han añadido contactos de emergencia.\n'
            'Toca + para añadir contactos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight),
          ),
        ),
      ),
    ],
  );

  Widget _errorState(BuildContext context, Object error) => ListView(
    children: [
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No se pudieron cargar los contactos.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textLight),
            ),
          ),
        ),
      ),
    ],
  );
}
