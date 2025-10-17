import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'models/enums.dart';
import 'models/question.dart';
import 'models/session.dart';
import 'models/vote.dart';
import 'models/ticket.dart';
import 'models/result.dart';
import 'models/audit_log.dart';
import 'models/signing_key.dart';
import 'models/meeting.dart';
import 'models/meeting_pass.dart';
import 'screens/landing_page.dart';
import 'screens/admin_page.dart';
import 'screens/client_join_page.dart';
import 'screens/voting_page.dart';
import 'screens/results_page.dart';
import 'screens/qr_scanner_page.dart';

/*** Co dalej / dlaczego tak?
Init Hive w osobnej funkcji → łatwiej testować i czytelniej.
Adaptery zarejestrujemy, gdy przeniesiesz modele (następny krok).
Boxy otwieramy leniwie (np. w storage/repositories/... przy pierwszym użyciu), a nie wszystkie na starcie — start apki jest szybszy i nie „zabetonujesz” kolejności inicjalizacji.
Proste Routes jako stałe — zero magii, łatwo nawigować i podmieniać ekrany.*/

Future<void> _initHive() async {
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final dir = await pp.getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }

  // --- REGISTER ALL ADAPTERS HERE (safe version) ---
  if (!Hive.isAdapterRegistered(0))
    Hive.registerAdapter(SessionTypeAdapter()); // enums.dart
  if (!Hive.isAdapterRegistered(1))
    Hive.registerAdapter(AnswersSchemaAdapter()); // enums.dart
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(OptionModelAdapter()); // question.dart
  if (!Hive.isAdapterRegistered(3))
    Hive.registerAdapter(QuestionAdapter()); // question.dart
  if (!Hive.isAdapterRegistered(4))
    Hive.registerAdapter(SessionAdapter()); // session.dart
  if (!Hive.isAdapterRegistered(5))
    Hive.registerAdapter(TicketAdapter()); // ticket.dart
  if (!Hive.isAdapterRegistered(6))
    Hive.registerAdapter(VoteAdapter()); // vote.dart
  if (!Hive.isAdapterRegistered(7))
    Hive.registerAdapter(ResultAdapter()); // result.dart
  if (!Hive.isAdapterRegistered(8))
    Hive.registerAdapter(AuditLogAdapter()); // audit_log.dart
  if (!Hive.isAdapterRegistered(9))
    Hive.registerAdapter(SigningKeyAdapter()); // signing_key.dart
  if (!Hive.isAdapterRegistered(14))
    Hive.registerAdapter(MeetingAdapter()); // meeting.dart
  if (!Hive.isAdapterRegistered(15))
    Hive.registerAdapter(MeetingPassAdapter()); // meeting_pass.dart

  // Boxy będą otwierane leniwie (np. w repozytoriach lub serwisach storage).
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHive();
  runApp(const VotingApp());
}

class VotingApp extends StatelessWidget {
  const VotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Voting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: Routes.home,
      routes: {
        Routes.home: (_) => const LandingPage(),
        Routes.adminHost: (_) => const AdminPage(),
        Routes.clientJoin: (_) => const ClientJoinPage(),
        Routes.voting: (_) => const VotingPage(),
        Routes.results: (_) => const ResultsPage(),
        Routes.qrScanner: (_) => const QrScannerPage(),
      },
      // prosty „safe” onUnknownRoute
      onUnknownRoute:
          (_) => MaterialPageRoute(builder: (_) => const LandingPage()),
    );
  }
}

class Routes {
  static const home = '/';
  static const adminHost = '/admin';
  static const clientJoin = '/client/join';
  static const voting = '/vote';
  static const results = '/results';
  static const qrScanner = '/qr';
}
