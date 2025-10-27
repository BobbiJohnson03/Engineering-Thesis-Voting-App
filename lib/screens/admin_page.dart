import 'dart:io';
import 'package:flutter/material.dart';
import '../local_server/admin_host_server.dart';
import '../network/api_network.dart';
import '../repositories/meeting_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/vote_repository.dart';
import '../repositories/question_repository.dart';
import '../models/meeting.dart';
import '../models/session.dart';
import '../models/enums.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // --- host/server state ---
  AdminHostServer? _server;
  bool _serverRunning = false;

  // --- simple config ---
  final _port = 8080;
  String _baseUrl = 'http://127.0.0.1:8080'; // po starcie spróbujemy odkryć IP

  // --- data created via seed ---
  String? _meetingId;
  String? _sessionId;
  String? _sessionTitle;

  // --- repos (Hive) ---
  late final MeetingRepository _meetings;
  late final SessionRepository _sessions;
  late final TicketRepository _tickets;
  late final VoteRepository _votes;
  late final QuestionRepository _questions;

  // API client (do wołania /admin/session/seed, /admin/results itd.)
  ApiNetwork? _api;

  @override
  void initState() {
    super.initState();
    _meetings = MeetingRepository();
    _sessions = SessionRepository();
    _tickets = TicketRepository();
    _votes = VoteRepository();
    _questions = QuestionRepository();
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }

  // -------------------- helpers --------------------

  Future<void> _startServer() async {
    if (_serverRunning) return;

    // 1) przygotuj serwer
    final srv = AdminHostServer(
      meetings: _meetings,
      sessions: _sessions,
      tickets: _tickets,
      votes: _votes,
      questions: _questions,
    );

    // 2) start serwera na 0.0.0.0:8080
    await srv.start(address: InternetAddress.anyIPv4, port: _port);

    // 3) spróbuj wykryć IP (prosty heurystyczny wariant)
    final ip = await _tryDetectLocalIPv4() ?? '127.0.0.1';
    final base = 'http://$ip:$_port';

    setState(() {
      _server = srv;
      _serverRunning = true;
      _baseUrl = base;
      _api = ApiNetwork(_baseUrl);
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serwer uruchomiony na $_baseUrl')),
      );
    }
  }

  Future<void> _stopServer() async {
    if (!_serverRunning) return;
    await _server?.stop();
    _api?.close();
    setState(() {
      _server = null;
      _serverRunning = false;
      _api = null;
    });
  }

  Future<String?> _tryDetectLocalIPv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith(RegExp(r'\d'))) {
            return addr.address; // bierz pierwszy sensowny
          }
        }
      }
    } catch (_) {
      /* ignore */
    }
    return null;
  }

  // Tworzy Meeting jeśli nie istnieje i seeduje 1 sesję z pytaniami
  Future<void> _seedDemoSession() async {
    if (!_serverRunning || _api == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Najpierw uruchom serwer.')));
      return;
    }

    // 1) zadbaj o Meeting – jeśli brak, utwórz prosty
    var mid = _meetingId;
    if (mid == null) {
      mid = DateTime.now().microsecondsSinceEpoch.toString();
      final m = Meeting(
        meetingId: mid,
        title: 'Posiedzenie Senatu – Demo',
        sessionIds: const [],
        isOpen: true,
        createdAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(hours: 4)),
        shortCode: 'DEMO',
        jwtKeyId: 'local',
      );
      await _meetings.put(m);
      setState(() => _meetingId = mid);
    }

    // 2) wołamy seed endpoint na serwerze (prosto, jednym strzałem)
    try {
      final payload = {
        'meetingId': mid,
        'title': 'Uchwała X – Głosowanie jawne',
        'shortCode': 'A1B2C3',
        'questions': [
          {
            'questionId': 'q1',
            'text': 'Czy zgadzasz się z uchwałą X?',
            'maxSelectable': 1,
            'displayGroup': 0,
            'options': [
              {'id': 'yes', 'label': 'TAK', 'order': 0},
              {'id': 'no', 'label': 'NIE', 'order': 1},
              {'id': 'abstain', 'label': 'WSTRZYMUJĘ SIĘ', 'order': 2},
            ],
          },
          {
            'questionId': 'q2',
            'text': 'Czy wprowadzić poprawkę Y?',
            'maxSelectable': 1,
            'displayGroup': 0,
            'options': [
              {'id': 'yes', 'label': 'TAK', 'order': 0},
              {'id': 'no', 'label': 'NIE', 'order': 1},
            ],
          },
        ],
      };

      final json = await _api!.adminSeedSession(payload);
      final sid = (json['sessionId'] as String?) ?? '';

      setState(() {
        _sessionId = sid;
        _sessionTitle = payload['title'] as String;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Utworzono sesję: $sid')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Seed nie powiódł się: $e')));
      }
    }
  }

  Future<void> _closeSession() async {
    if (_sessionId == null || _api == null) return;
    try {
      await _api!.adminClose(_sessionId!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesja zamknięta.')));
      setState(() {
        /* UI odśwież */
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd zamykania: $e')));
    }
  }

  Future<void> _showResults() async {
    if (_sessionId == null || _api == null) return;
    try {
      final json = await _api!.getResults(_sessionId!);
      final tallies = json['tallies'];
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Wyniki (surowe)'),
              content: SingleChildScrollView(
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(tallies),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd pobierania wyników: $e')));
    }
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Panel administratora')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sekcja serwera
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serwer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _serverRunning
                          ? 'Działa na: $_baseUrl'
                          : 'Serwer nie jest uruchomiony',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _serverRunning ? null : _startServer,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Uruchom serwer'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _serverRunning ? _stopServer : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Zatrzymaj serwer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sekcja seeda
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nowa sesja (demo)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Meeting ID: ${_meetingId ?? '–'}'),
                    Text('Session ID: ${_sessionId ?? '–'}'),
                    Text('Tytuł: ${_sessionTitle ?? '–'}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _serverRunning ? _seedDemoSession : null,
                      child: const Text('+ Utwórz przykładową sesję'),
                    ),
                    if (_sessionId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Klient: najpierw /joinMeeting z meetingId=$_meetingId, '
                        'potem /ticket dla sessionId=$_sessionId, '
                        'później /manifest?sid=$_sessionId i /voteBundle.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Akcje admins.
            if (_sessionId != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _closeSession,
                        child: const Text('Zamknij sesję'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _showResults,
                        child: const Text('Pokaż wyniki (JSON)'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
