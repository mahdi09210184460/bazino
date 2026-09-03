import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'dart:math';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _registerAndEnter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final String phone = _phoneController.text.trim();
      final String name = _nameController.text.trim();
      final String refCode = _referralController.text.trim();

      // 1. Check Security & Ban Status
      final userCheck = await _supabase.from('app_users').select().eq('phone', phone).maybeSingle();
      if (userCheck != null && userCheck['is_banned'] == true) {
        throw 'حساب کاربری شما به دلیل تخلف مسدود شده است.';
      }

      String username = userCheck != null ? userCheck['username'] : "PICO-${Random().nextInt(90000) + 10000}";

      // 2. Referral Logic (Only for new users)
      int initialBonus = 0;
      if (userCheck == null && refCode.isNotEmpty && refCode.startsWith("PICO-")) {
        final referrer = await _supabase.from('app_users').select().eq('username', refCode).maybeSingle();
        if (referrer != null) {
          final config = await _supabase.from('app_config').select('value').eq('key', 'referral_bonus').maybeSingle();
          int bonus = int.tryParse(config?['value'] ?? '5000') ?? 5000;
          initialBonus = bonus;

          // Reward Referrer
          await _supabase.from('app_users').update({'wallet_balance': (referrer['wallet_balance'] ?? 0) + bonus}).eq('username', refCode);
          await _supabase.from('wallet_transactions').insert({
            'user_phone': referrer['phone'],
            'amount': bonus,
            'type': 'هدیه دعوت',
            'description': 'پاداش دعوت از $name',
            'date': DateTime.now().toString().split('.')[0]
          });
        }
      }

      // 3. Cloud Sync & Save
      await _supabase.from('app_users').upsert({
        'name': name,
        'phone': phone,
        'username': username,
        'wallet_balance': userCheck != null ? (userCheck['wallet_balance'] ?? 0) : initialBonus,
        'last_login': DateTime.now().toIso8601String(),
      }, onConflict: 'phone');

      if (initialBonus > 0) {
        await _supabase.from('wallet_transactions').insert({
          'user_phone': phone,
          'amount': initialBonus,
          'type': 'هدیه ورود',
          'description': 'پاداش استفاده از کد دعوت $refCode',
          'date': DateTime.now().toString().split('.')[0]
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('userPhone', phone);
      await prefs.setString('userUsername', username);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => HomePage(userName: name, userPhone: phone, userEmail: '')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        child: Form(key: _formKey, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('پیکو مارکت', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 40),
          _buildField(_nameController, 'نام و نام خانوادگی', Icons.person),
          _buildField(_phoneController, 'شماره تماس ایرانی', Icons.phone, type: TextInputType.phone),
          _buildField(_referralController, 'کد دعوت (اختیاری)', Icons.card_giftcard, isOptional: true),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _isLoading ? null : _registerAndEnter, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 55)), child: _isLoading ? const CircularProgressIndicator() : const Text('ورود امن به برنامه'))
        ])),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String l, IconData i, {TextInputType type = TextInputType.text, bool isOptional = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(
      controller: c, 
      keyboardType: type, 
      textAlign: TextAlign.right, 
      decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))), 
      validator: (v) {
        if (isOptional) return null;
        if (v == null || v.trim().isEmpty) return 'این فیلد الزامی است';
        if (type == TextInputType.phone && !RegExp(r'^09[0-9]{9}$').hasMatch(v.trim())) return 'شماره تماس معتبر نیست';
        return null;
      }
    ));
  }
}
