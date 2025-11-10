import 'package:flutter/material.dart';
import 'package:vote_app_thesis/network/api_network.dart';
import 'admin_page.dart';
import 'qr_scanner_page.dart';

class LandingPage extends StatelessWidget {
  final ApiNetwork apiNetwork;

  const LandingPage({super.key, required this.apiNetwork});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Voting System')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'University Thesis Voting App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminPage(apiNetwork: apiNetwork),
                  ),
                );
              },
              child: const Text('Admin Mode'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrScannerPage(apiNetwork: apiNetwork),
                  ),
                );
              },
              child: const Text('Join as Voter'),
            ),
          ],
        ),
      ),
    );
  }
}
