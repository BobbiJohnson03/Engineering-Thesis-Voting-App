import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as pp;

// Ekrany (na razie placeholdery – jeśli nie masz jeszcze plików, dodaj proste scaffolde)
import 'screens/landing_page.dart';
import 'screens/admin_page.dart';
import 'screens/client_join_page.dart';
import 'screens/voting_page.dart';
import 'screens/results_page.dart';
import 'screens/qr_scanner_page.dart';

/**
 * Co dalej / dlaczego tak?

Init Hive w osobnej funkcji → łatwiej testować i czytelniej.

Adaptery zarejestrujemy, gdy przeniesiesz modele (następny krok).

Boxy otwieramy leniwie (np. w storage/repositories/... przy pierwszym użyciu), a nie wszystkie na starcie — start apki jest szybszy i nie „zabetonujesz” kolejności inicjalizacji.

Proste Routes jako stałe — zero magii, łatwo nawigować i podmieniać ekrany.
 */

Future<void> _initHive() async {
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final dir = await pp.getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }

  // TODO: Rejestracje adapterów – przeniesiemy po dodaniu modeli:
  // Hive.registerAdapter(SessionModelAdapter());
  // Hive.registerAdapter(QuestionModelAdapter());
  // Hive.registerAdapter(VoteModelAdapter());
  // Hive.registerAdapter(TicketModelAdapter());
  // Hive.registerAdapter(ResultModelAdapter());
  // Hive.registerAdapter(AuditLogModelAdapter());

  // UWAGA: Boxy otwierajmy leniwie w repozytoriach (lub przy pierwszym użyciu),
  // a nie globalnie tutaj – skraca start i ułatwia testy.
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
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const LandingPage()),
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
