
// flutter run -d edge --web-port=3000
import 'package:flutter/material.dart';
import 'package:ungdungchatbot/screens/chatscreens/chatscreen.dart';
import 'package:ungdungchatbot/screens/signinscreen.dart';
import 'package:ungdungchatbot/screens/spashscreen.dart';
import 'package:ungdungchatbot/services/authen_service.dart';
import 'package:ungdungchatbot/services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseService = SupabaseService();
  await supabaseService.initialize();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}
