import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vote_app_thesis/main.dart';
import 'package:vote_app_thesis/network/api_network.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      VotingApp(apiNetwork: ApiNetwork('http://localhost:8080')),
    ); // ✅ CHANGED: MyApp to VotingApp

    // Verify that our app starts
    expect(find.text('University Secure Voting'), findsOneWidget);
  });
}
