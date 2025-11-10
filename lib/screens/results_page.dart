import 'package:flutter/material.dart';
import 'package:vote_app_thesis/network/api_network.dart';

class ResultsPage extends StatelessWidget {
  final ApiNetwork apiNetwork;

  const ResultsPage({super.key, required this.apiNetwork});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voting Results')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64),
            SizedBox(height: 20),
            Text(
              'Live Results',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Real-time vote tallies will appear here'),
          ],
        ),
      ),
    );
  }
}
