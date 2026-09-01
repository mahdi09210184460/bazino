import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with your project URL
  // NOTE: You still need to provide your 'anonKey' from Supabase settings
  await Supabase.initialize(
    url: 'https://zhrxagzgrohpdivgppxh.supabase.co',
    anonKey: 'sb_publishable_ea6nBoR7swULwyAqYtVyMw_vNyIBNWh', 
  );

  final prefs = await SharedPreferences.getInstance();
  
  final String? name = prefs.getString('userName');
  final String? email = prefs.getString('userEmail');

  runApp(MyApp(
    isLoggedIn: email != null && email.isNotEmpty,
    userName: name ?? '',
    userEmail: email ?? '',
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final String userEmail;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پیکو مارکت',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'), // Farsi
      ],
      locale: const Locale('fa', 'IR'),
      home: isLoggedIn 
          ? HomePage(userName: userName, userPhone: '', userEmail: userEmail)
          : const RegisterPage(),
    );
  }
}
