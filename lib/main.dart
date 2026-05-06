import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/collection_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/font_preload.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.deferFirstFrame();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  await _loadFonts();
  await waitForDocumentFonts();

  WidgetsBinding.instance.allowFirstFrame();
  runApp(const CarNumberApp());
}

Future<void> _loadFonts() async {
  final manifestContent = await rootBundle.loadString('FontManifest.json');
  final List<dynamic> fonts = json.decode(manifestContent);
  final loaders = <Future<void>>[];

  for (final font in fonts) {
    final loader = FontLoader(font['family'] as String);
    for (final fontData in font['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load(fontData['asset'] as String));
    }
    loaders.add(loader.load());
  }

  await Future.wait(loaders);
}

class CarNumberApp extends StatelessWidget {
  const CarNumberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CollectionProvider>(
          create: (_) => CollectionProvider(),
          update: (_, auth, collection) {
            collection!.onAuthChanged(auth.user);
            return collection;
          },
        ),
      ],
      child: MaterialApp(
        title: 'ナンバー収集',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          useMaterial3: true,
        ),
        home: const _AppRouter(),
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE3F2FD),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isLoggedIn) {
      return const MainScreen();
    }

    return const LoginScreen();
  }
}
