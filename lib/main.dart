import 'package:flutter/material.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SageRoute',
      home: Scaffold(
        appBar: AppBar(title: const Text('SageRoute')),
        body: const Center(child: Text('Hello, SageRoute!')),
      ),
    );
  }
}
