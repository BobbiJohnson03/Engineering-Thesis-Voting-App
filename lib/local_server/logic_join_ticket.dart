import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../repositories/meeting_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/meeting_pass_repository.dart';
import '../models/meeting_pass.dart';
import 'broadcast_manager.dart';
import 'logic_helpers.dart';
import '../models/session.dart';

class LogicJoinTicket {
  final MeetingRepository meetings;
  final SessionRepository sessions;
  final TicketRepository tickets;
  final MeetingPassRepository meetingPasses;
  final BroadcastManager broadcast;
  final Uuid _uuid = Uuid();

  LogicJoinTicket({
    required this.meetings,
    required this.sessions,
    required this.tickets,
    required this.meetingPasses,
    required this.broadcast,
  });

  Future<Response> joinMeeting(Request req) async {
    final body = await readJson(req);
    final meetingId = body['meetingId'] as String?;
    final deviceFingerprint = body['deviceFingerprint'] as String?;

    if (meetingId == null) return jsonErr('Missing meetingId');

    final meeting = await meetings.get(meetingId);
    if (meeting == null) return jsonErr('Meeting not found');
    if (!meeting.canJoin) return jsonErr('Meeting not available');

    // Check if device already has a pass
    if (deviceFingerprint != null) {
      final hasPass = await meetingPasses.hasDevicePass(
        meetingId,
        deviceFingerprint,
      );
      if (hasPass) {
        return jsonErr('Device already joined this meeting');
      }
    }

    // Create meeting pass
    final meetingPass = MeetingPass(
      passId: _uuid.v4(),
      meetingId: meetingId,
      deviceFingerprintHash: deviceFingerprint,
    );

    await meetingPasses.put(meetingPass);

    // Get active sessions
    final activeSessions = await sessions.openForMeeting(meetingId);

    return jsonOk({
      'meetingPassId': meetingPass.passId,
      'meeting': {
        'id': meeting.id,
        'title': meeting.title,
        'isActive': meeting.isActive,
      },
      'activeSessions': activeSessions.map((s) => _sessionToJson(s)).toList(),
    });
  }

  Future<Response> requestTicket(Request req) async {
    final body = await readJson(req);
    final meetingPassId = body['meetingPassId'] as String?;
    final sessionId = body['sessionId'] as String?;
    final deviceFingerprint = body['deviceFingerprint'] as String?;

    if (meetingPassId == null || sessionId == null) {
      return jsonErr('Missing required fields');
    }

    final session = await sessions.get(sessionId);
    if (session == null) return jsonErr('Session not found');
    if (!session.canVote) return jsonErr('Session not available for voting');

    final meetingPass = await meetingPasses.get(meetingPassId);
    if (meetingPass == null || meetingPass.revoked) {
      return jsonErr('Invalid meeting pass');
    }

    // Create ticket
    final ticket = await tickets.create(
      sessionId: sessionId,
      meetingPassId: meetingPassId,
      deviceFingerprint: deviceFingerprint ?? '',
    );

    broadcast.send(session.meetingId, {
      'type': 'ticket_issued',
      'sessionId': sessionId,
      'ticketId': ticket.id,
    });

    return jsonOk({
      'ticketId': ticket.id,
      'sessionId': ticket.sessionId,
      'expiresAt': ticket.issuedAt.add(Duration(hours: 2)).toIso8601String(),
    });
  }

  Map<String, dynamic> _sessionToJson(Session session) {
    return {
      'id': session.id,
      'title': session.title,
      'type': session.type.name,
      'status': session.status.name,
      'canVote': session.canVote,
      'endsAt': session.endsAt?.toIso8601String(),
    };
  }
}
