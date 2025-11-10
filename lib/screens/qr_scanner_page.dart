import 'package:flutter/material.dart';
import 'package:vote_app_thesis/network/api_network.dart';
import 'voting_page.dart';

class QrScannerPage extends StatelessWidget {
  final ApiNetwork apiNetwork;

  const QrScannerPage({super.key, required this.apiNetwork});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Meeting')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scan QR Code to Join Meeting',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),

            // QR Scanner Placeholder
            Container(
              width: 250,
              height: 250,
              color: Colors.grey[300],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64),
                    SizedBox(height: 10),
                    Text('QR Scanner\n(Placeholder)'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Manual Join Option
            const Text('Or join manually:'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to VotingPage with required parameters
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => VotingPage(
                          apiNetwork: apiNetwork,
                          meetingId: 'test-meeting-123',
                          sessionId: 'test-session-456',
                        ),
                  ),
                );
              },
              child: const Text('Test Join Meeting'),
            ),
          ],
        ),
      ),
    );
  }
}
