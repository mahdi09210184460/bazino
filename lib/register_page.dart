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
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;

  Future<void> _registerAndEnter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String phone = _phoneController.text.trim();
      final String name = _nameController.text.trim();

      // Check if user exists or generate new username
      final existingUser = await _supabase.from('app_users').select('username').eq('phone', phone).maybeSingle();
      
      String username;
      if (existingUser != null) {
        username = existingUser['username'];
      } else {
        username = "PICO-${Random().nextInt(90000) + 10000}";
      }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ورود با موفقیت انجام شد')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            userName: name,
            userPhone: phone,
            userEmail: '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در اتصال: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('ورود / ثبت نام', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Text('پیکو مارکت', textAlign: TextAlign.center, style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.orange)),
              const SizedBox(height: 40),
              _buildTextField(_nameController, 'نام و نام خانوادگی', Icons.person),
              const SizedBox(height: 15),
              _buildTextField(_phoneController, 'شماره تماس (مثال: ۰۹۱۲۳۴۵۶۷۸۹)', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerAndEnter,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('ورود به برنامه', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.orange), filled: true, fillColor: Colors.orange.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'این فیلد الزامی است';
        if (keyboardType == TextInputType.phone && !RegExp(r'^09[0-9]{9}$').hasMatch(value.trim())) return 'شماره تماس معتبر نیست';
        return null;
      },
    );
  }
}
