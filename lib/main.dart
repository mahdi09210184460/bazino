import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://zhrxagzgrohpdivgppxh.supabase.co',
    anonKey: 'sb_publishable_ea6nBoR7swULwyAqYtVyMw_vNyIBNWh', 
  );

  final prefs = await SharedPreferences.getInstance();
  
  final String? name = prefs.getString('userName');
  final String? phone = prefs.getString('userPhone');

  runApp(MyApp(
    isLoggedIn: phone != null && phone.isNotEmpty,
    userName: name ?? '',
    userPhone: phone ?? '',
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final String userPhone;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.userName,
    required this.userPhone,
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
          ? HomePage(userName: userName, userPhone: userPhone, userEmail: '')
          : const RegisterPage(),
    );
  }
}
