import 'package:flutter/material.dart';
import '../network/api_network.dart';
import 'voting_page.dart';

class ClientJoinPage extends StatefulWidget {
  const ClientJoinPage({super.key});

  @override
  State<ClientJoinPage> createState() => _ClientJoinPageState();
}

class _ClientJoinPageState extends State<ClientJoinPage> {
  final _formKey = GlobalKey<FormState>();

  final _baseUrlCtrl = TextEditingController(text: 'http://127.0.0.1:8080');
  final _meetingIdCtrl = TextEditingController();
  final _sessionIdCtrl = TextEditingController();

  bool _busy = false;
  String? _error;

  Future<void> _joinAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final baseUrl = _baseUrlCtrl.text.trim();
    final meetingId = _meetingIdCtrl.text.trim();
    final sessionId = _sessionIdCtrl.text.trim();

    setState(() {
      _busy = true;
      _error = null;
    });

    final api = ApiNetwork(baseUrl);

    try {
      // 1) joinMeeting -> passId
      final join = await api.joinMeeting({'mid': meetingId});
      final passId = join['passId'] as String;

      // 2) issue ticket -> ticketId
      final ticket = await api.issueTicket({
        'passId': passId,
        'sessionId': sessionId,
      });
      final ticketId = ticket['ticketId'] as String;

      // 3) manifest -> pytania
      final manifest = await api.getManifest(sessionId);
      final questions =
          (manifest['questions'] as List).cast<Map<String, dynamic>>();
      final title = manifest['title']?.toString() ?? 'Głosowanie';

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => VotingPage(
                baseUrl: baseUrl,
                sessionId: sessionId,
                ticketId: ticketId,
                title: title,
                questions: questions,
              ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      api.close();
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _meetingIdCtrl.dispose();
    _sessionIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dołącz do głosowania')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Połącz ręcznie', style: th.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _baseUrlCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'Base URL serwera (np. http://192.168.0.10:8080)',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Podaj adres'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _meetingIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Meeting ID (od administratora)',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Podaj Meeting ID'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sessionIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Session ID (od administratora)',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Podaj Session ID'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: th.colorScheme.error),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _joinAndProceed,
                        child:
                            _busy
                                ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : const Text('Połącz i przejdź do głosowania'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
