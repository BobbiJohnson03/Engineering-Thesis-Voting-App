import 'package:flutter/material.dart';
import '../main.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voting – Home')),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.adminHost),
              child: const Text('Admin Host'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.clientJoin),
              child: const Text('Client (Join)'),
            ),
          ],
        ),
      ),
    );
  }
}
