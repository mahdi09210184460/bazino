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

      // 2. Cloud Sync (Restore wallet & data if re-installing)
      await _supabase.from('app_users').upsert({
        'name': name,
        'phone': phone,
        'username': username,
        'last_login': DateTime.now().toIso8601String(),
      }, onConflict: 'phone');

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
          _buildField(_referralController, 'کد دعوت (اختیاری)', Icons.card_giftcard),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _isLoading ? null : _registerAndEnter, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 55)), child: _isLoading ? const CircularProgressIndicator() : const Text('ورود امن به برنامه'))
        ])),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String l, IconData i, {TextInputType type = TextInputType.text}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: c, keyboardType: type, textAlign: TextAlign.right, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))), validator: (v) => (v == null || v.isEmpty) ? 'اجباری' : null));
  }
}
