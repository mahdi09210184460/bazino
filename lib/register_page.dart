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
  final TextEditingController _codeController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isCodeSent = false;
  bool _isLoading = false;

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Send OTP via Supabase
      await _supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: true,
      );
      
      setState(() => _isCodeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد تایید به ایمیل شما ارسال شد')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_codeController.text.length < 6) return;
    setState(() => _isLoading = true);

    try {
      final AuthResponse res = await _supabase.auth.verifyOTP(
        type: OtpType.magiclink,
        token: _codeController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (res.session != null) {
        // Save user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _nameController.text.isNotEmpty ? _nameController.text : 'کاربر پیکو');
        await prefs.setString('userEmail', _emailController.text.trim());
        await prefs.setString('userPhone', ''); // Phone removed

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userName: prefs.getString('userName') ?? '',
              userPhone: '',
              userEmail: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کد تایید اشتباه است')),
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
        title: const Text('ورود / ثبت نام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              if (!_isCodeSent) ...[
                const Text('لطفاً اطلاعات خود را وارد کنید:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'نام و نام خانوادگی (برای اولین ثبت نام)', Icons.person),
                const SizedBox(height: 15),
                _buildTextField(_emailController, 'آدرس ایمیل', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text('دریافت کد تایید', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                const Text('کد ۶ رقمی ارسال شده به ایمیل را وارد کنید:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildTextField(_codeController, 'کد ۶ رقمی', Icons.lock_clock, keyboardType: TextInputType.number),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('تایید و ورود به برنامه', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => setState(() => _isCodeSent = false),
                  child: const Text('تغییر ایمیل', style: TextStyle(color: Colors.orange)),
                ),
              ],
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
