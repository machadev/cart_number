import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/collection_provider.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const CarNumberApp());
}

class CarNumberApp extends StatelessWidget {
  const CarNumberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CollectionProvider()..loadData(),
      child: MaterialApp(
        title: 'ナンバー収集',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
