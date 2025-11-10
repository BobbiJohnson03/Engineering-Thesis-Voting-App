import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as pp;

// ============ MODELS ============
import 'models/enums.dart';
import 'models/option.dart';
import 'models/question.dart';
import 'models/session.dart';
import 'models/secure_vote.dart';
import 'models/ticket.dart';
import 'models/result.dart';
import 'models/audit_log.dart';
import 'models/signing_key.dart';
import 'models/meeting.dart';
import 'models/meeting_pass.dart';

// ============ SCREENS ============
import 'screens/landing_page.dart';
import 'screens/admin_page.dart';
import 'screens/client_join_page.dart';
import 'screens/voting_page.dart';
import 'screens/results_page.dart';
import 'screens/qr_scanner_page.dart';

// ============ SERVICES ============
import 'network/api_network.dart';

Future<void> _initHive() async {
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final dir = await pp.getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }

  // ============ ENUMS ============
  Hive.registerAdapter(SessionTypeAdapter());
  Hive.registerAdapter(AnswersSchemaAdapter());
  Hive.registerAdapter(SessionStatusAdapter());
  Hive.registerAdapter(AuditActionAdapter());

  // ============ MODELS ============
  Hive.registerAdapter(MeetingAdapter()); // TypeId: 3
  Hive.registerAdapter(OptionAdapter()); // TypeId: 4
  Hive.registerAdapter(QuestionAdapter()); // TypeId: 5
  Hive.registerAdapter(SessionAdapter()); // TypeId: 6
  Hive.registerAdapter(SigningKeyAdapter()); // TypeId: 7
  Hive.registerAdapter(TicketAdapter()); // TypeId: 8
  Hive.registerAdapter(SecureVoteAdapter()); // TypeId: 9
  Hive.registerAdapter(ResultAdapter()); // TypeId: 10
  Hive.registerAdapter(MeetingPassAdapter()); // TypeId: 11
  Hive.registerAdapter(AuditLogAdapter()); // TypeId: 12

  debugPrint('Hive initialization complete - all adapters registered');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHive();

  // Initialize our network service
  final apiNetwork = ApiNetwork(
    'http://localhost:8080', // Default, will be configured per device
  );

  runApp(VotingApp(apiNetwork: apiNetwork));
}

class VotingApp extends StatelessWidget {
  final ApiNetwork apiNetwork;

  const VotingApp({super.key, required this.apiNetwork});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Secure Voting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: Routes.home,
      routes: {
        Routes.home: (_) => LandingPage(apiNetwork: apiNetwork),
        Routes.adminHost: (_) => AdminPage(apiNetwork: apiNetwork),
        Routes.clientJoin: (_) => ClientJoinPage(apiNetwork: apiNetwork),
        Routes.results: (_) => ResultsPage(apiNetwork: apiNetwork),
        Routes.qrScanner: (_) => QrScannerPage(apiNetwork: apiNetwork),
      },
      onUnknownRoute:
          (_) => MaterialPageRoute(
            builder: (_) => LandingPage(apiNetwork: apiNetwork),
          ),
    );
  }
}

class Routes {
  static const home = '/';
  static const adminHost = '/admin';
  static const clientJoin = '/client/join';
  static const results = '/results';
  static const qrScanner = '/qr';
}

// ============ APP STATE MANAGEMENT ============

/// Simple state management for the voting app
class AppState extends InheritedWidget {
  final ApiNetwork apiNetwork;
  final String? currentMeetingId;
  final String? currentSessionId;

  const AppState({
    super.key,
    required this.apiNetwork,
    required super.child,
    this.currentMeetingId,
    this.currentSessionId,
  });

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppState>()!;
  }

  @override
  bool updateShouldNotify(AppState oldWidget) {
    return currentMeetingId != oldWidget.currentMeetingId ||
        currentSessionId != oldWidget.currentSessionId;
  }
}
