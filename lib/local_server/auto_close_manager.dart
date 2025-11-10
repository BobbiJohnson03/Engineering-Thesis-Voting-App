import 'dart:async';
import '../repositories/meeting_repository.dart';
import '../repositories/session_repository.dart';
import 'broadcast_manager.dart';

class AutoCloseManager {
  final MeetingRepository meetings;
  final SessionRepository sessions;
  final BroadcastManager broadcast;

  Timer? _timer;

  AutoCloseManager(this.meetings, this.sessions, this.broadcast);

  void start() {
    stop();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final all = await meetings.getAll(); // ✅ CHANGED: .all() to .getAll()
      for (final m in all) {
        for (final sid in m.sessionIds) {
          final s = await sessions.get(sid);
          if (s != null &&
              s.canVote &&
              s.endsAt != null &&
              DateTime.now().isAfter(s.endsAt!)) {
            s.close();
            broadcast.send(m.id, {'type': 'session_closed', 'sessionId': sid});
          }
        }
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
