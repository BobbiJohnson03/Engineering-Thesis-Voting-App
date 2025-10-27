import 'package:flutter/material.dart';
import '../network/api_network.dart';

class VotingPage extends StatefulWidget {
  /// Gdy chcesz tylko placeholder (zgodne z `const VotingPage()`),
  /// zostaw wszystko jako null i ekran pokaże prosty komunikat.
  final String? baseUrl;
  final String? sessionId;
  final String? ticketId;
  final String? title;
  final List<Map<String, dynamic>>? questions;

  /// Konstruktor „uniwersalny” – może działać jako placeholder (bez parametrów)
  /// lub pełny (z przekazanymi wszystkimi wartościami).
  const VotingPage({
    Key? key,
    this.baseUrl,
    this.sessionId,
    this.ticketId,
    this.title,
    this.questions,
  }) : super(key: key);

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  ApiNetwork? _api;

  /// qid -> String? (radio) | Set<String> (checkbox)
  final Map<String, dynamic> _answers = {};

  bool _busy = false;
  String? _error;
  bool _sent = false;

  bool get _isFullMode =>
      widget.baseUrl != null &&
      widget.sessionId != null &&
      widget.ticketId != null &&
      widget.title != null &&
      widget.questions != null &&
      widget.questions!.isNotEmpty;

  @override
  void initState() {
    super.initState();

    // Jeżeli mamy pełne dane – inicjalizuj API i odpowiedzi
    if (_isFullMode) {
      _api = ApiNetwork(widget.baseUrl!);

      // przygotuj puste wybory per pytanie
      for (final q in widget.questions!) {
        final qid = q['questionId'] as String;
        final maxSel = q['maxSelectable'] as int?;
        if (maxSel == null || maxSel > 1) {
          _answers[qid] = <String>{}; // multi-select
        } else {
          _answers[qid] = null; // single-select
        }
      }
    }
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isFullMode) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    // zbuduj tablicę answers
    final List<Map<String, dynamic>> payloadAnswers = [];
    for (final q in widget.questions!) {
      final qid = q['questionId'] as String;
      final maxSel = q['maxSelectable'] as int?;
      if (maxSel == null || maxSel > 1) {
        final set = (_answers[qid] as Set<String>);
        payloadAnswers.add({
          'questionId': qid,
          'selectedOptionIds': set.toList(),
        });
      } else {
        final sel = _answers[qid] as String?;
        payloadAnswers.add({
          'questionId': qid,
          'selectedOptionIds': sel == null ? <String>[] : [sel],
        });
      }
    }

    try {
      await _api!.sendVoteBundle(
        ticketId: widget.ticketId!,
        sessionId: widget.sessionId!,
        answers: payloadAnswers,
      );
      setState(() {
        _sent = true;
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Dziękujemy!'),
              content: const Text('Głos został zapisany.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TRYB PLACEHOLDER: brak parametrów → prosty ekran (jak Twoja wersja Stateless)
    if (!_isFullMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Głosowanie')),
        body: Center(
          child: Text(
            'Voting Screen'
            '${widget.baseUrl != null ? '\nAPI: ${widget.baseUrl}' : ''}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // TRYB PEŁNY: formularz głosowania
    final th = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title!)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final q in widget.questions!)
              _QuestionCard(
                question: q,
                value: _answers[q['questionId']],
                onChanged: (newValue) {
                  setState(() {
                    _answers[q['questionId'] as String] = newValue;
                  });
                },
              ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: TextStyle(color: th.colorScheme.error)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _busy || _sent ? null : _submit,
              icon: const Icon(Icons.how_to_vote),
              label:
                  _busy
                      ? const Text('Wysyłanie...')
                      : const Text('Wyślij głos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final dynamic value; // String? (radio) lub Set<String> (checkbox)
  final void Function(dynamic) onChanged;

  const _QuestionCard({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final qid = question['questionId'] as String;
    final text = question['text']?.toString() ?? qid;
    final maxSel = question['maxSelectable'] as int?;
    final options = (question['options'] as List).cast<Map<String, dynamic>>();

    final isMulti = (maxSel == null || maxSel > 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: th.textTheme.titleMedium),
            const SizedBox(height: 6),
            if (!isMulti) ...[
              for (final o in options)
                RadioListTile<String>(
                  title: Text(o['label'] as String),
                  value: o['id'] as String,
                  groupValue: value as String?,
                  onChanged: (v) => onChanged(v),
                  contentPadding: EdgeInsets.zero,
                ),
            ] else ...[
              for (final o in options)
                CheckboxListTile(
                  title: Text(o['label'] as String),
                  value: (value as Set<String>).contains(o['id']),
                  onChanged: (checked) {
                    final set = Set<String>.from(value as Set<String>);
                    if (checked == true) {
                      set.add(o['id'] as String);
                    } else {
                      set.remove(o['id'] as String);
                    }
                    onChanged(set);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              if (maxSel != null)
                Text(
                  'Możesz wybrać maks. $maxSel',
                  style: th.textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
