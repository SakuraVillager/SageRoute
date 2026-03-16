import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  // 测试连接
  try {
    print('正在尝试连接 Supabase...');
    final data = await supabase.from('Celebrity').select().limit(1);
    print('连接成功！查询结果: $data');
  } catch (e) {
    print('连接失败: $e');
  }

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

final supabase = Supabase.instance.client;

Future<List<dynamic>> getUsers() async {
  final data = await supabase
      .from('Celebrity')
      .select();

  return data;
}