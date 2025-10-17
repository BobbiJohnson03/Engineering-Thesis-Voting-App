import 'package:flutter/material.dart';
import '../main.dart'; // for Routes

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // App scaffold = standard page chrome
      appBar: AppBar(
        title: const Text('Voting – Home'),
        centerTitle: false,
        actions: [
          // "Hamburger" on the right (popup menu)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              switch (value) {
                case 'about':
                  showAboutDialog(
                    context: context,
                    applicationName: 'University Voting',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text('Offline LAN voting app – Engineering Thesis'),
                    ],
                  );
                  break;
                case 'settings':
                  // TODO: navigate to settings when you add it
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ustawienia (wkrótce)')),
                  );
                  break;
                case 'archive':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Archiwum (wkrótce)')),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'about', child: Text('O aplikacji')),
                  PopupMenuItem(value: 'settings', child: Text('Ustawienia')),
                  PopupMenuItem(value: 'archive', child: Text('Archiwum')),
                ],
          ),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'DOŁĄCZ DO GŁOSOWANIA',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtitle
                  Text(
                    'WYBIERZ SPOSÓB ŁĄCZENIA:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // go to QR scanner page
                        Navigator.pushNamed(context, Routes.qrScanner);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                      child: const Text('SKANUJ KOD QR'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // go to manual join page
                        Navigator.pushNamed(context, Routes.clientJoin);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                      child: const Text('WPISZ KOD RĘCZNIE'),
                    ),
                  ),
                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // go to QR scanner page
                        Navigator.pushNamed(context, Routes.qrScanner);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                      child: const Text('ZALOGUJ SIĘ JAKO ADMINISTRATOR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
