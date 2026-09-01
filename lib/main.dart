import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  // TODO: Replace with your actual Supabase Project URL and Anon Key
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final prefs = await SharedPreferences.getInstance();
  
  final String? name = prefs.getString('userName');
  final String? phone = prefs.getString('userPhone');
  final String? email = prefs.getString('userEmail');

  runApp(MyApp(
    isLoggedIn: name != null && name.isNotEmpty && 
                phone != null && phone.isNotEmpty && 
                email != null && email.isNotEmpty,
    userName: name ?? '',
    userPhone: phone ?? '',
    userEmail: email ?? '',
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final String userPhone;
  final String userEmail;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.userName,
    required this.userPhone,
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
          ? HomePage(userName: userName, userPhone: userPhone, userEmail: userEmail)
          : const RegisterPage(),
    );
  }
}
