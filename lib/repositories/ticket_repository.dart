import 'package:hive/hive.dart';
import '../models/ticket.dart';
import '../utils/hive_boxes.dart';

class TicketRepository {
  Future<Box<Ticket>> _box() => HiveBoxes.tickets();

  Future<Ticket?> findByPassAndSession(String passId, String sessionId) async =>
      (await _box()).values.firstWhere(
        (t) => t.byPassId == passId && t.sessionId == sessionId && !t.revoked,
        orElse: () => null,
      );

  Future<void> save(Ticket t) async => (await _box()).put(t.ticketId, t);
}
