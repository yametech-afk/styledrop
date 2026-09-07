import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/seed_data_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/sync_repository.dart';
import 'providers/wardrobe_provider.dart';
import 'providers/outfit_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_controller.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await StorageService.init();
  await SeedDataService.seedIfNeeded();
  await NotificationService.init();
  runApp(const StyleDropApp());
}

class StyleDropApp extends StatelessWidget {
  const StyleDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WardrobeProvider()..load()),
        ChangeNotifierProvider(create: (_) => OutfitProvider()..load()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..load()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          title: 'StyleDrop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.mode,
          home: const AppRoot(),
        ),
      ),
    );
  }
}

/// Routes between the login screen and the main app based on Firebase auth
/// state. This is the canonical Firebase pattern: a [StreamBuilder] listening
/// to [AuthService.authStateChanges] so login/logout automatically shows the
/// right screen with no manual callbacks.
///
/// It also drives Phase B cloud sync: when the signed-in UID changes to a real
/// (non-guest) account, it pulls that account's library from Firestore into the
/// local cache exactly once, then refreshes the providers.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  String? _syncedUid; // the uid we've already pulled cloud data for
  String? _lastAppliedUid = 'unset'; // last uid we ran identity-sync for
  bool _syncing = false;

  Future<void> _onUserChanged(User? user) async {
    // Only react when the signed-in identity actually changes, otherwise the
    // per-frame post-frame callback would loop (sync -> notify -> rebuild).
    if (user?.uid == _lastAppliedUid) return;
    _lastAppliedUid = user?.uid;

    // Keep the profile identity in sync with the Firebase user.
    if (!mounted) return;
    await context.read<ProfileProvider>().syncWithFirebaseUser(user);

    // Only real (non-anonymous) users sync to the cloud.
    final isRealUser = user != null && !user.isAnonymous;

    if (!isRealUser) {
      _syncedUid = null;
      return;
    }
    if (user.uid == _syncedUid) return; // already pulled for this account

    _syncedUid = user.uid;
    if (mounted) setState(() => _syncing = true);
    try {
      await SyncRepository.instance.pullFromCloud();
      if (!mounted) return;
      // Refresh providers so the UI shows the merged cloud + local library.
      context.read<WardrobeProvider>().load();
      context.read<OutfitProvider>().load();
      context.read<ProfileProvider>().load();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // While Firebase is restoring the persisted session, show a splash.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthSplash();
        }

        final user = snapshot.data;

        // Handle identity sync + cloud pull after the frame is built.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onUserChanged(user);
        });

        if (user == null) {
          return const LoginScreen();
        }
        if (_syncing) {
          return const _AuthSplash(message: 'Syncing your wardrobe…');
        }
        return const MainShell();
      },
    );
  }
}

class _AuthSplash extends StatelessWidget {
  final String? message;
  const _AuthSplash({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!),
            ],
          ],
        ),
      ),
    );
  }
}
