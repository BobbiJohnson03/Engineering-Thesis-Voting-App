import 'package:flutter/material.dart';
import 'package:vote_app_thesis/network/api_network.dart';

class VotingPage extends StatefulWidget {
  final ApiNetwork apiNetwork;
  final String meetingId;
  final String sessionId;

  const VotingPage({
    super.key,
    required this.apiNetwork,
    required this.meetingId,
    required this.sessionId,
  });

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  List<String>? _questions;
  String? _selectedOption;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // Simulate loading questions
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _questions = ['Do you approve the budget?', 'Elect committee chair?'];
    });
  }

  Future<void> _submitVote() async {
    if (_selectedOption == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Show success
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Vote Submitted'),
                content: const Text('Your vote has been securely recorded.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cast Your Vote')),
      body:
          _questions == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_questions!.first),
                    const SizedBox(height: 30),

                    // Voting Options
                    const Text(
                      'Select your vote:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Simple Yes/No options for testing
                    RadioListTile<String>(
                      title: const Text('Yes'),
                      value: 'yes',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('No'),
                      value: 'no',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Abstain'),
                      value: 'abstain',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                        });
                      },
                    ),

                    const Spacer(),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _selectedOption != null && !_isSubmitting
                                ? _submitVote
                                : null,
                        child:
                            _isSubmitting
                                ? const CircularProgressIndicator()
                                : const Text('Submit Secure Vote'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
