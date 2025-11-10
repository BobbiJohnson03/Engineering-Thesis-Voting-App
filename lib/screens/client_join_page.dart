import 'package:flutter/material.dart';
import '../network/api_network.dart';

class ClientJoinPage extends StatelessWidget {
  final ApiNetwork apiNetwork;

  const ClientJoinPage({super.key, required this.apiNetwork});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Meeting'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Scan QR Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan the QR code provided by the meeting organizer',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/qr');
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // TODO: Manual code entry
              },
              child: const Text('Enter Code Manually'),
            ),
          ],
        ),
      ),
    );
  }
}
