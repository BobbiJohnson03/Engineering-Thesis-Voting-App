import 'package:flutter/material.dart';
import 'package:vote_app_thesis/network/api_network.dart';
import 'package:uuid/uuid.dart';

class AdminPage extends StatefulWidget {
  final ApiNetwork apiNetwork;

  const AdminPage({super.key, required this.apiNetwork});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _meetingTitleController = TextEditingController();
  final Uuid _uuid = Uuid();
  String? _currentMeetingId;
  bool _serverRunning = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    try {
      await widget.apiNetwork.health();
      setState(() {
        _serverRunning = true;
      });
    } catch (e) {
      setState(() {
        _serverRunning = false;
      });
    }
  }

  Future<void> _createMeeting() async {
    if (_meetingTitleController.text.isEmpty) return;

    final meetingId = _uuid.v4();
    final joinCode = _uuid.v4().substring(0, 8).toUpperCase();

    // In a real app, you'd call your backend to create the meeting
    // For now, we'll just store the ID and show the QR code
    setState(() {
      _currentMeetingId = meetingId;
    });

    // Show QR code dialog
    _showMeetingQr(joinCode);
  }

  void _showMeetingQr(String joinCode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Meeting Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Join Code: $joinCode'),
                const SizedBox(height: 20),
                // In a real app, you'd generate a QR code here
                Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('QR Code Placeholder')),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _serverRunning ? Icons.check_circle : Icons.error,
                      color: _serverRunning ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _serverRunning ? 'Server Running' : 'Server Offline',
                      style: TextStyle(
                        color: _serverRunning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Create Meeting Section
            const Text(
              'Create New Meeting',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _meetingTitleController,
              decoration: const InputDecoration(
                labelText: 'Meeting Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createMeeting,
              child: const Text('Create Meeting & Generate QR'),
            ),

            // Current Meeting Info
            if (_currentMeetingId != null) ...[
              const SizedBox(height: 30),
              const Text(
                'Active Meeting',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Meeting ID: ${_currentMeetingId!.substring(0, 8)}...'),
            ],
          ],
        ),
      ),
    );
  }
}
