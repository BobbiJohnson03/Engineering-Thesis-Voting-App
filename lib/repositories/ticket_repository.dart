import 'package:hive/hive.dart';
import '../models/ticket.dart';
import '_boxes.dart';

class TicketRepository {
  Box<Ticket>? _box;

  Future<Box<Ticket>> _open() async =>
      _box ??= await Hive.openBox<Ticket>(boxTicket);

  Future<Ticket?> get(String id) async {
    final box = await _open();
    return box.get(id);
  }

  /// Idempotent: returns existing ticket for (passId, sessionId) if present.
  Future<Ticket> issueIfAbsent({
    required String ticketId,
    required String sessionId,
    required String byPassId,
    DateTime? issuedAt,
    String? deviceFingerprintHash,
  }) async {
    final box = await _open();

    Ticket? existing;
    for (final t in box.values) {
      if (t.byPassId == byPassId && t.sessionId == sessionId) {
        existing = t;
        break;
      }
    }

    if (existing != null) return existing;

    final t = Ticket(
      ticketId: ticketId,
      sessionId: sessionId,
      issuedAt: issuedAt ?? DateTime.now(),
      byPassId: byPassId,
      deviceFingerprintHash: deviceFingerprintHash,
    );
    await box.put(t.ticketId, t);
    return t;
  }

  Future<void> markUsed(String ticketId) async {
    final box = await _open();
    final t = box.get(ticketId);
    if (t != null && !t.used) {
      t.used = true;
      await t.save();
    }
  }
}
