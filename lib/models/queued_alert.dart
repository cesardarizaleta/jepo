import 'package:isar/isar.dart';

part 'queued_alert.g.dart';

/// Lifecycle state of a locally persisted alert in the offline queue.
enum QueueStatus {
  /// Waiting to be sent. The syncPending() loop will pick it up.
  pending,

  /// Currently being sent. Used as a soft lock to avoid double submission.
  sending,

  /// Successfully delivered to the backend.
  sent,

  /// Permanently failed (retry budget exhausted or non-retryable error).
  failed,
}

/// A single alert event durably persisted to the device's local Isar
/// database until it can be shipped to the NestJS backend.
///
/// Every write (enqueue / status update) happens inside an Isar transaction,
/// so a crash mid-write cannot corrupt the queue — the change is either
/// fully committed or not visible at all.
@collection
class QueuedAlert {
  Id id = Isar.autoIncrement;

  /// Deduplication key. Unique index means the backend will never see the
  /// same logical impact event twice, even if the app is force-killed and
  /// the alert is re-enqueued after restart.
  @Index(unique: true, replace: true)
  late String clientEventId;

  // ─── Payload ──────────────────────────────────────────────────────────
  late double latitud;
  late double longitud;
  String? urlAudioContexto;

  @Index()
  late DateTime fechaHora;

  late bool esProactiva;

  // ─── Bookkeeping ──────────────────────────────────────────────────────
  @Enumerated(EnumType.name)
  @Index()
  late QueueStatus status;

  late int retryCount;
  DateTime? lastAttemptAt;
  String? lastError;

  @Index()
  late DateTime createdAt;
}
