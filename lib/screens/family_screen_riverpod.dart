import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/contacts_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/contact_card.dart';

/// Family screen rewritten with Riverpod.
///
/// - Zero `setState()` calls: the entire async lifecycle is handled by
///   `FutureProvider.autoDispose` + `AsyncValue.when(...)`.
/// - Edits / deletes mutate through [contactsMutationsProvider] which
///   invalidates the provider, triggering a clean rebuild with fresh data.
/// - No more "setState during build" crashes — callbacks simply push routes
///   or invoke mutations; rebuilds are driven by Riverpod, not by the
///   widget's own gesture handlers.
class FamilyScreenRiverpod extends ConsumerWidget {
  const FamilyScreenRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

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
          // ─── LOADING ─────────────────────────────────────────────────
          loading: () => const Center(child: CircularProgressIndicator()),

          // ─── ERROR ───────────────────────────────────────────────────
          error: (error, stack) => ListView(
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
          ),

          // ─── DATA ────────────────────────────────────────────────────
          data: (contacts) {
            if (contacts.isEmpty) {
              return ListView(
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
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ContactCard(
                    name: contact.name,
                    phone: contact.phone,
                    priority: contact.priority,
                    onEdit: () => _onEdit(context, ref, contact),
                    onDelete: () => _onDelete(context, ref, contact),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_contact',
        backgroundColor: const Color(0xFFEEEEEE),
        elevation: 0,
        onPressed: () => _onAdd(context, ref),
        child: const Icon(Icons.add, color: Color(0xFF7FCCC4)),
      ),
    );
  }

  // ─── Callbacks: pure intent handlers, no setState anywhere ─────────────

  void _onAdd(BuildContext context, WidgetRef ref) {
    // Open your add-contact bottom sheet here. On success, the sheet should
    // call: ref.read(contactsMutationsProvider).add(...)
    // which internally invalidates contactsProvider → UI refreshes.
  }

  Future<void> _onEdit(
    BuildContext context,
    WidgetRef ref,
    FamilyContact contact,
  ) async {
    // Open your edit bottom sheet. On save:
    // await ref.read(contactsMutationsProvider).update(
    //   id: contact.id!,
    //   name: newName,
    //   phone: newPhone,
    //   priority: newPriority,
    // );
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
        AppToast.error(context, 'Error al eliminar el contacto: $e');
      }
    }
  }
}
