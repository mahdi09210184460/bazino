import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;

  Future<void> _registerAndEnter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim();
      final String name = _nameController.text.trim();

      // 1. Save to Supabase (Custom users table for Admin to see)
      await _supabase.from('app_users').upsert({
        'name': name,
        'email': email,
        'last_login': DateTime.now().toIso8601String(),
      }, onConflict: 'email');

      // 2. Save locally for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);

      if (!mounted) return;
      
      // 3. Show welcome and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خوش آمدید! ورود با موفقیت انجام شد')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            userName: name,
            userPhone: '',
            userEmail: email,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در اتصال: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ورود / ثبت نام سریع', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Text(
                'پیکو مارکت',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.orange),
              ),
              const SizedBox(height: 40),
              const Text('اطلاعات خود را وارد کنید:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTextField(_nameController, 'نام و نام خانوادگی', Icons.person),
              const SizedBox(height: 15),
              _buildTextField(_emailController, 'آدرس ایمیل', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerAndEnter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text('ثبت‌نام و ورود به برنامه', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text(
                'نیاز به تایید ایمیل نیست؛ مستقیماً وارد شوید.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: Colors.orange.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'این فیلد الزامی است';
        if (keyboardType == TextInputType.emailAddress && !value.contains('@')) return 'ایمیل نامعتبر است';
        return null;
      },
    );
  }
}
