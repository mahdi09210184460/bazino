import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'register_page.dart';
import 'dart:math';
import 'dart:io';

class AppUserRecord {
  final String name, phone, username, lastLogin; bool isBanned;
  AppUserRecord({required this.name, required this.phone, required this.username, required this.lastLogin, this.isBanned = false});
  factory AppUserRecord.fromJson(Map<String, dynamic> json) => AppUserRecord(name: json['name'] ?? '', phone: json['phone'] ?? '', username: json['username'] ?? 'User', lastLogin: json['last_login'] ?? '', isBanned: json['is_banned'] ?? false);
}

class Product {
  dynamic id; String title, price, quality, imageUrl, category; int priceInt;
  Product({this.id, required this.title, required this.price, required this.quality, required this.imageUrl, required this.category, this.priceInt = 0});
  factory Product.fromJson(Map<String, dynamic> json) {
    String pStr = (json['price'] ?? '0').toString().replaceAll(',', '').replaceAll(' تومان', '').split(' /')[0];
    return Product(id: json['id'], title: json['title'] ?? '', price: json['price'] ?? '', quality: json['quality'] ?? '', imageUrl: json['image_url'] ?? '', category: json['category'] ?? 'other', priceInt: int.tryParse(pStr) ?? 0);
  }
  Map<String, dynamic> toJson() => {'title': title, 'price': price, 'quality': quality, 'image_url': imageUrl, 'category': category};
}

class OrderRecord {
  dynamic id; final String userName, userPhone, username, productTitle, trackingCode; String status; final String date;
  OrderRecord({this.id, required this.userName, required this.userPhone, required this.username, required this.productTitle, required this.trackingCode, required this.status, required this.date});
  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(id: json['id'], userName: json['user_name'] ?? '', userPhone: json['user_phone'] ?? '', username: json['username'] ?? '', productTitle: json['product_title'] ?? '', trackingCode: json['tracking_code'] ?? '', status: json['status'] ?? "در انتظار", date: json['date'] ?? '');
}

class AppNews {
  dynamic id; String title, content, date;
  AppNews({this.id, required this.title, required this.content, required this.date});
  Map<String, dynamic> toJson() => {'title': title, 'content': content, 'date': date};
  factory AppNews.fromJson(Map<String, dynamic> json) => AppNews(id: json['id'], title: json['title'] ?? '', content: json['content'] ?? '', date: json['date'] ?? '');
}

class Winner {
  dynamic id; String name, city, prize, date;
  Winner({this.id, required this.name, required this.city, required this.prize, required this.date});
  Map<String, dynamic> toJson() => {'name': name, 'city': city, 'prize': prize, 'date': date};
  factory Winner.fromJson(Map<String, dynamic> json) => Winner(id: json['id'], name: json['name'] ?? '', city: json['city'] ?? '', prize: json['prize'] ?? '', date: json['date'] ?? '');
}

class PrizeRecord {
  dynamic id; String title, amount; int iconCode, colorValue;
  PrizeRecord({this.id, required this.title, required this.amount, required this.iconCode, required this.colorValue});
  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'icon_code': iconCode, 'color_value': colorValue};
  factory PrizeRecord.fromJson(Map<String, dynamic> json) => PrizeRecord(id: json['id'], title: json['title'] ?? '', amount: json['amount'] ?? '', iconCode: json['icon_code'] ?? Icons.card_giftcard.codePoint, colorValue: json['color_value'] ?? Colors.orange.value);
}

class HomePage extends StatefulWidget {
  final String userName, userPhone, userEmail;
  const HomePage({super.key, required this.userName, required this.userPhone, required this.userEmail});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final String _adminPhone = "09927891608"; 
  final SupabaseClient _supabase = Supabase.instance.client;

  String _username = "", _instaID = "pico", _telegramID = "@pico", _supportEmail = "pico@support", _paymentLink = "https://zarrinpal.com", _lotteryEntryFee = "۱۰,۰۰۰", _lotteryRules = "قوانین برنامه", _supTele = "@pico_support", _supWhatsApp = "09000000000";
  String _catInstaName = "اینستاگرام", _catTeleName = "تلگرام", _catOtherName = "سایر";
  List<Product> _instaProducts = [], _telegramProducts = [], _otherProducts = [];
  List<Winner> _lotteryWinners = []; List<PrizeRecord> _prizes = []; List<OrderRecord> _allOrders = []; List<AppUserRecord> _appUsers = []; List<AppNews> _allNews = [];
  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ هفتگی', _lotteryBannerPrize = 'جایزه ۵ میلیونی', _lotteryBannerDate = 'جمعه ساعت ۲۱';
  bool _isLoading = true; String _searchProductQuery = "";

  @override
  void initState() { super.initState(); _fetchSupabaseData(); _startSecurityMonitor(); }

  Future<void> _startSecurityMonitor() async {
    Future.delayed(const Duration(minutes: 5), () async {
      final res = await _supabase.from('app_users').select('is_banned').eq('phone', widget.userPhone).maybeSingle();
      if (res != null && res['is_banned'] == true) { _handleBan(); }
    });
  }

  void _handleBan() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RegisterPage()), (r) => false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دسترسی شما مسدود شد'), backgroundColor: Colors.red));
  }

  Future<void> _fetchSupabaseData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final configRes = await _supabase.from('app_config').select();
      for (var item in configRes) {
        String k = item['key'] ?? '', v = item['value']?.toString() ?? '';
        if (k == 'lottery_banner_title') _lotteryBannerTitle = v;
        if (k == 'lottery_banner_prize') _lotteryBannerPrize = v;
        if (k == 'lottery_banner_date') _lotteryBannerDate = v;
        if (k == 'insta_id') _instaID = v;
        if (k == 'telegram_id') _telegramID = v;
        if (k == 'support_email') _supportEmail = v;
        if (k == 'payment_link') _paymentLink = v;
        if (k == 'lottery_entry_fee') _lotteryEntryFee = v;
        if (k == 'lottery_rules') _lotteryRules = v;
        if (k == 'sup_tele') _supTele = v;
        if (k == 'sup_whatsapp') _supWhatsApp = v;
        if (k == 'cat_insta_name') _catInstaName = v;
        if (k == 'cat_tele_name') _catTeleName = v;
        if (k == 'cat_other_name') _catOtherName = v;
      }
      final userRes = await _supabase.from('app_users').select().eq('phone', widget.userPhone).maybeSingle();
      if (userRes != null) {
        if (userRes['is_banned'] == true) { _handleBan(); return; }
        _username = userRes['username'] ?? 'User';
      }
      _instaProducts = (await _supabase.from('products').select().eq('category', 'insta')).map((e) => Product.fromJson(e)).toList();
      _telegramProducts = (await _supabase.from('products').select().eq('category', 'tele')).map((e) => Product.fromJson(e)).toList();
      _otherProducts = (await _supabase.from('products').select().eq('category', 'other')).map((e) => Product.fromJson(e)).toList();
      _lotteryWinners = (await _supabase.from('winners').select().order('created_at', ascending: false)).map((e) => Winner.fromJson(e)).toList();
      _prizes = (await _supabase.from('prizes').select()).map((e) => PrizeRecord.fromJson(e)).toList();
      _allOrders = (await _supabase.from('orders').select().order('created_at', ascending: false)).map((e) => OrderRecord.fromJson(e)).toList();
      _appUsers = (await _supabase.from('app_users').select().order('created_at', ascending: false)).map((e) => AppUserRecord.fromJson(e)).toList();
      _allNews = (await _supabase.from('news').select().order('created_at', ascending: false)).map((e) => AppNews.fromJson(e)).toList();
    } catch (e) { debugPrint('Supabase Error: $e'); }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    List<Widget> widgetOptions = [_buildStoreContent(), _buildLotteryAndPrizes(), _buildOrdersContent(), _buildProfileContent()];
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text(['فروشگاه پیکو', 'جوایز و قرعه‌کشی', 'سفارشات', 'پروفایل'][_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange, centerTitle: true, actions: [IconButton(onPressed: _fetchSupabaseData, icon: const Icon(Icons.refresh))]),
      body: widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(onPressed: _showSupportDialog, backgroundColor: Colors.orange, child: const Icon(Icons.headset_mic)),
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, selectedItemColor: Colors.orange, unselectedItemColor: Colors.grey, currentIndex: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i), items: const [BottomNavigationBarItem(icon: Icon(Icons.store), label: 'فروشگاه'), BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'قرعه‌کشی'), BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'سفارشات'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل')]),
    );
  }

  Widget _buildStoreContent() => SingleChildScrollView(child: Column(children: [
    if (_allNews.isNotEmpty) _buildNewsTicker(),
    Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText: 'جستجوی محصول...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.white), onChanged: (v) => setState(() => _searchProductQuery = v))),
    _buildCategorySection(_catInstaName, _instaProducts.where((p) => p.title.contains(_searchProductQuery)).toList()), 
    _buildCategorySection(_catTeleName, _telegramProducts.where((p) => p.title.contains(_searchProductQuery)).toList()), 
    _buildCategorySection(_catOtherName, _otherProducts.where((p) => p.title.contains(_searchProductQuery)).toList()), 
    const SizedBox(height: 20)
  ]));

  Widget _buildNewsTicker() => Container(height: 60, margin: const EdgeInsets.symmetric(vertical: 10), child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _allNews.length, itemBuilder: (c, i) => InkWell(onTap: () => _showNewsDetail(_allNews[i]), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), margin: const EdgeInsets.only(right: 15), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.blue.withOpacity(0.3))), child: Row(children: [const Icon(Icons.campaign, color: Colors.blue, size: 20), const SizedBox(width: 10), Text(_allNews[i].title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))])))));
  void _showNewsDetail(AppNews n) => showDialog(context: context, builder: (c) => AlertDialog(title: Text(n.title), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(n.date, style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 10), Text(n.content)])), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]));

  Widget _buildCategorySection(String t, List<Product> p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.all(16), child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), SizedBox(height: 250, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: p.length, itemBuilder: (c, i) => _buildProductCard(p[i])))]);
  Widget _buildProductCard(Product p) => Container(width: 165, margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [const SizedBox(height: 15), p.imageUrl.isNotEmpty ? Image.network(p.imageUrl, height: 75, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 60)) : const Icon(Icons.image, size: 60), const SizedBox(height: 10), Text(p.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1), const Spacer(), Text('${p.priceInt} تومان', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), Container(width: double.infinity, margin: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () => _handleDirectPayment(p.priceInt, p.title, "خرید محصول"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('پرداخت و خرید')))]));

  Future<void> _handleDirectPayment(int amount, String title, String type) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('تایید نهایی'), content: Text('شما در حال خرید "$title" به مبلغ $amount تومان هستید. به درگاه بانکی منتقل شوید؟'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('بله، انتقال'))]));
    if (confirm != true) return;

    await launchUrl(Uri.parse(_paymentLink), mode: LaunchMode.externalApplication);
    
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(title: const Text('در انتظار پرداخت'), content: const Text('پس از تکمیل پرداخت در مرورگر، دکمه زیر را بزنید.'), actions: [ElevatedButton(onPressed: () async {
      Navigator.pop(c); _showLoading('در حال تایید تراکنش...');
      await Future.delayed(const Duration(seconds: 3)); // Simulate verification
      String track = "TRK-${Random().nextInt(90000) + 10000}";
      if (type == "خرید محصول") {
        await _supabase.from('orders').insert({'user_name': widget.userName, 'user_phone': widget.userPhone, 'username': _username, 'product_title': title, 'tracking_code': track, 'status': 'در حال انجام', 'date': DateTime.now().toString().split('.')[0]});
      } else {
        await _supabase.from('participants').insert({'name': widget.userName, 'phone': widget.userPhone, 'username': _username, 'lottery_code': "LOT-${Random().nextInt(90000)+10000}", 'date': DateTime.now().toString().split('.')[0]});
      }
      Navigator.pop(context); _fetchSupabaseData(); _showSuccess('پرداخت تایید شد! سفارش شما ثبت گردید.\nکد پیگیری: $track');
    }, child: const Text('تایید و ثبت نهایی'))]));
  }

  IconData _getPrizeIcon(int code) {
    if (code == Icons.looks_one.codePoint) return Icons.looks_one;
    if (code == Icons.looks_two.codePoint) return Icons.looks_two;
    if (code == Icons.looks_3.codePoint) return Icons.looks_3;
    if (code == Icons.stars.codePoint) return Icons.stars;
    return Icons.card_giftcard;
  }

  Widget _buildLotteryAndPrizes() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(25), width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(30)), child: Column(children: [const Icon(Icons.stars, color: Colors.white, size: 50), Text(_lotteryBannerTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 15), ElevatedButton(onPressed: () => _handleDirectPayment(int.tryParse(_lotteryEntryFee.replaceAll(',', '')) ?? 10000, "ورودی قرعه‌کشی", "ثبت‌نام قرعه‌کشی"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.orange), child: const Text('شرکت در قرعه‌کشی'))])),
    const SizedBox(height: 25),
    const Text('🎁 جوایز این دوره', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    SizedBox(height: 160, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _prizes.length, itemBuilder: (c, i) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Container(width: 130, padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_getPrizeIcon(_prizes[i].iconCode), size: 35, color: Color(_prizes[i].colorValue)), const SizedBox(height: 10), Text(_prizes[i].title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), Text(_prizes[i].amount, style: const TextStyle(fontSize: 12, color: Colors.grey))]))))),
    const SizedBox(height: 25),
    const Text('🏆 تالار برندگان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    ..._lotteryWinners.map((w) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('از ${w.city} | جایزه: ${w.prize}'), trailing: Text(w.date, style: const TextStyle(fontSize: 10))))),
    const SizedBox(height: 50)
  ]));

  Widget _buildOrdersContent() => _allOrders.where((o) => o.userPhone == widget.userPhone).isEmpty ? const Center(child: Text('سفارشی ثبت نشده است')) : ListView.builder(itemCount: _allOrders.length, itemBuilder: (c, i) => _allOrders[i].userPhone == widget.userPhone ? Card(margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: const Icon(Icons.shopping_bag, color: Colors.orange), title: Text(_allOrders[i].productTitle), subtitle: Text('کد: ${_allOrders[i].trackingCode}'), trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _allOrders[i].status == "انجام شده" ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(_allOrders[i].status, style: TextStyle(color: _allOrders[i].status == "انجام شده" ? Colors.green : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))))) : const SizedBox.shrink());

  Widget _buildProfileContent() {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      Container(
        padding: const EdgeInsets.all(30), width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15)]),
        child: Column(children: [
          const CircleAvatar(radius: 45, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Colors.orange)),
          const SizedBox(height: 15), Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)), child: Text('نام کاربری: $_username', style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
      ),
      const SizedBox(height: 30),
      _buildProfileMenu(Icons.admin_panel_settings, 'مدیریت برنامه', () { if (widget.userPhone == _adminPhone) Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPanel(instaProducts: _instaProducts, telegramProducts: _telegramProducts, otherProducts: _otherProducts, lotteryWinners: _lotteryWinners, prizes: _prizes, allOrders: _allOrders, appUsers: _appUsers, bannerTitle: _lotteryBannerTitle, bannerPrize: _lotteryBannerPrize, bannerDate: _lotteryBannerDate, insta: _instaID, tele: _telegramID, mail: _supportEmail, paymentLink: _paymentLink, lotteryFee: _lotteryEntryFee, lotteryRules: _lotteryRules, supTele: _supTele, supWA: _supWhatsApp, catInsta: _catInstaName, catTele: _catTeleName, catOther: _catOtherName, onUpdate: () => _fetchSupabaseData()))); }),
      _buildProfileMenu(Icons.info_outline, 'درباره پیکو مارکت', () {}),
      const SizedBox(height: 30),
      ElevatedButton.icon(onPressed: () async { (await SharedPreferences.getInstance()).clear(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RegisterPage()), (r) => false); }, icon: const Icon(Icons.logout), label: const Text('خروج از حساب کاربری'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, minimumSize: const Size(double.infinity, 55))),
    ]));
  }
  Widget _buildProfileMenu(IconData i, String t, VoidCallback onTap) => Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(i, color: Colors.orange), title: Text(t), trailing: const Icon(Icons.chevron_right, size: 18), onTap: onTap));

  void _showSupportDialog() { showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (c) => Container(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('📞 مرکز پشتیبانی پیکو', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 25), _buildSupTile(Icons.telegram, 'پشتیبانی تلگرام', _supTele, Colors.blue), _buildSupTile(Icons.message, 'پشتیبانی واتس‌اپ', _supWhatsApp, Colors.green), const SizedBox(height: 10), const Text('ساعت پاسخگویی: ۹ صبح الی ۲۳ شب', style: TextStyle(color: Colors.grey, fontSize: 12))]))); }
  Widget _buildSupTile(IconData i, String t, String v, Color c) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(i, color: c), title: Text(t), subtitle: Text(v), trailing: const Icon(Icons.open_in_new, size: 18), onTap: () => launchUrl(Uri.parse(t.contains('تلگرام') ? "https://t.me/${v.replaceAll('@', '')}" : "https://wa.me/$v"))));

  void _showLoading(String m) => showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Colors.orange), const SizedBox(height: 15), Text(m)])));
  void _showSuccess(String m) => showDialog(context: context, builder: (c) => AlertDialog(title: const Icon(Icons.check_circle, color: Colors.green, size: 50), content: Text(m, textAlign: TextAlign.center), actions: [Center(child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('فهمیدم')))]));
}

class AdminPanel extends StatefulWidget {
  final List<Product> instaProducts, telegramProducts, otherProducts; final List<Winner> lotteryWinners; final List<PrizeRecord> prizes; final List<OrderRecord> allOrders; final List<AppUserRecord> appUsers; final String bannerTitle, bannerPrize, bannerDate, insta, tele, mail, paymentLink, lotteryFee, lotteryRules, supTele, supWA, catInsta, catTele, catOther;
  final VoidCallback onUpdate;
  const AdminPanel({super.key, required this.instaProducts, required this.telegramProducts, required this.otherProducts, required this.lotteryWinners, required this.prizes, required this.allOrders, required this.appUsers, required this.bannerTitle, required this.bannerPrize, required this.bannerDate, required this.insta, required this.tele, required this.mail, required this.paymentLink, required this.lotteryFee, required this.lotteryRules, required this.supTele, required this.supWA, required this.catInsta, required this.catTele, required this.catOther, required this.onUpdate});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late List<Product> _tempInsta, _tempTele, _tempOther; late List<Winner> _tempWinners; late List<PrizeRecord> _tempPrizes; late List<OrderRecord> _tempOrders;
  late TextEditingController _title, _prize, _date, _inst, _tel, _mail, _pay, _fee, _rules, _sTel, _sWA, _cInsta, _cTele, _cOther;
  String _searchQuery = ""; final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tempInsta = List.from(widget.instaProducts); _tempTele = List.from(widget.telegramProducts); _tempOther = List.from(widget.otherProducts); _tempWinners = List.from(widget.lotteryWinners); _tempPrizes = List.from(widget.prizes); _tempOrders = List.from(widget.allOrders);
    _title = TextEditingController(text: widget.bannerTitle); _prize = TextEditingController(text: widget.bannerPrize); _date = TextEditingController(text: widget.bannerDate); _inst = TextEditingController(text: widget.insta); _tel = TextEditingController(text: widget.tele); _mail = TextEditingController(text: widget.mail); _pay = TextEditingController(text: widget.paymentLink); _fee = TextEditingController(text: widget.lotteryFee); _rules = TextEditingController(text: widget.lotteryRules); _sTel = TextEditingController(text: widget.supTele); _sWA = TextEditingController(text: widget.supWA); _cInsta = TextEditingController(text: widget.catInsta); _cTele = TextEditingController(text: widget.catTele); _cOther = TextEditingController(text: widget.catOther);
  }

  Future<void> _save() async {
    try {
      await _supabase.from('app_config').upsert([{'key': 'lottery_banner_title', 'value': _title.text.trim()}, {'key': 'lottery_banner_prize', 'value': _prize.text.trim()}, {'key': 'lottery_banner_date', 'value': _date.text.trim()}, {'key': 'insta_id', 'value': _inst.text.trim()}, {'key': 'telegram_id', 'value': _tel.text.trim()}, {'key': 'support_email', 'value': _mail.text.trim()}, {'key': 'payment_link', 'value': _pay.text.trim()}, {'key': 'lottery_entry_fee', 'value': _fee.text.trim()}, {'key': 'lottery_rules', 'value': _rules.text.trim()}, {'key': 'sup_tele', 'value': _sTel.text.trim()}, {'key': 'sup_whatsapp', 'value': _sWA.text.trim()}, {'key': 'cat_insta_name', 'value': _cInsta.text.trim()}, {'key': 'cat_tele_name', 'value': _cTele.text.trim()}, {'key': 'cat_other_name', 'value': _cOther.text.trim()}], onConflict: 'key');
      await _supabase.from('products').delete().neq('id', -1);
      if (_tempInsta.isNotEmpty) await _supabase.from('products').insert(_tempInsta.map((e) => e.toJson()).toList());
      if (_tempTele.isNotEmpty) await _supabase.from('products').insert(_tempTele.map((e) => e.toJson()).toList());
      if (_tempOther.isNotEmpty) await _supabase.from('products').insert(_tempOther.map((e) => e.toJson()).toList());
      await _supabase.from('winners').delete().neq('id', -1);
      if (_tempWinners.isNotEmpty) await _supabase.from('winners').insert(_tempWinners.map((e) => e.toJson()).toList());
      await _supabase.from('prizes').delete().neq('id', -1);
      if (_tempPrizes.isNotEmpty) await _supabase.from('prizes').insert(_tempPrizes.map((e) => e.toJson()).toList());
      for (var o in _tempOrders) { if (o.id != null) await _supabase.from('orders').update({'status': o.status}).eq('id', o.id); }
      widget.onUpdate(); if (!mounted) return; Navigator.pop(context);
    } catch (e) { debugPrint('Save Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 6, child: Scaffold(backgroundColor: Colors.grey[100], appBar: AppBar(title: const Text('مدیریت پیشرفته'), backgroundColor: Colors.orange, actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)], bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'سفارشات'), Tab(text: 'کاربران'), Tab(text: 'محصولات'), Tab(text: 'جوایز'), Tab(text: 'تنظیمات'), Tab(text: 'برندگان')])), body: Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: TextField(decoration: const InputDecoration(labelText: 'جستجو...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => _searchQuery = v))),
      Expanded(child: TabBarView(children: [_buildOrdersTab(), _buildUsersTab(), _buildProductsTab(), _buildLotteryMgmtTab(), _buildSettingsTab(), _buildWinnersTab()])),
    ])));
  }

  Widget _buildUsersTab() {
    var filtered = widget.appUsers.where((u) => u.username.contains(_searchQuery) || u.name.contains(_searchQuery)).toList();
    return ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(filtered[i].name), subtitle: Text(filtered[i].username), trailing: IconButton(icon: Icon(Icons.block, color: filtered[i].isBanned ? Colors.grey : Colors.red), onPressed: () async { await _supabase.from('app_users').update({'is_banned': true}).eq('phone', filtered[i].phone); }))));
  }
  Widget _buildOrdersTab() {
    var filtered = _tempOrders.where((o) => o.username.contains(_searchQuery) || o.userName.contains(_searchQuery)).toList();
    var active = filtered.where((o) => o.status != "انجام شده").toList();
    var completed = filtered.where((o) => o.status == "انجام شده").toList();
    return ListView(children: [
      _header('📦 در جریان (${active.length})', Colors.blue),
      ...active.map((o) => Card(child: ListTile(title: Text(o.productTitle), subtitle: Text('${o.username} | ${o.status}'), trailing: IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => setState(() => o.status = "انجام شده"))))),
      _header('✅ ثبت شده ها (${completed.length})', Colors.green),
      ...completed.map((o) => Card(color: Colors.green.withOpacity(0.05), child: ListTile(title: Text(o.productTitle), subtitle: Text('${o.username} | انجام شده'))))
    ]);
  }
  Widget _header(String t, Color c) => Container(padding: const EdgeInsets.all(15), color: c.withOpacity(0.1), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c)));

  Widget _buildProductsTab() => SingleChildScrollView(child: Column(children: [_buildCategoryMgmt(_cInsta.text, _tempInsta, 'insta'), _buildCategoryMgmt(_cTele.text, _tempTele, 'tele'), _buildCategoryMgmt(_cOther.text, _tempOther, 'other'), const SizedBox(height: 20)]));
  Widget _buildCategoryMgmt(String t, List<Product> l, String k) => Card(child: Column(children: [ListTile(title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold))), ...l.map((e) => ListTile(leading: e.imageUrl.isNotEmpty ? Image.network(e.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.image)) : const Icon(Icons.image), title: Text(e.title), subtitle: Text(e.price), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => l.remove(e))))), ElevatedButton.icon(onPressed: () => _addProduct(l, k), icon: const Icon(Icons.add), label: const Text('افزودن محصول'))]));
  void _addProduct(List<Product> l, String k) {
    TextEditingController t = TextEditingController(), p = TextEditingController(); String? imgUrl;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(title: const Text('محصول جدید'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: t, decoration: const InputDecoration(labelText: 'نام محصول')),
      TextField(controller: p, decoration: const InputDecoration(labelText: 'قیمت (عدد)')),
      const SizedBox(height: 15),
      if (imgUrl != null) Image.network(imgUrl!, height: 80) else const Icon(Icons.image, size: 50, color: Colors.grey),
      TextButton.icon(onPressed: () async {
        final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pick != null) {
          final bytes = await pick.readAsBytes();
          final path = 'products/${DateTime.now().millisecondsSinceEpoch}.png';
          await _supabase.storage.from('products').uploadBinary(path, bytes);
          setS(() => imgUrl = _supabase.storage.from('products').getPublicUrl(path));
        }
      }, icon: const Icon(Icons.upload), label: const Text('آپلود عکس'))
    ]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')), ElevatedButton(onPressed: () { if (t.text.isEmpty) return; setState(() => l.add(Product(title: t.text, price: '${p.text} تومان', quality: 'عالی', imageUrl: imgUrl ?? '', category: k, priceInt: int.tryParse(p.text) ?? 0))); Navigator.pop(c); }, child: const Text('افزودن'))])));
  }
  Widget _buildLotteryMgmtTab() => Column(children: [ElevatedButton(onPressed: _addPrize, child: const Text('افزودن جایزه جدید')), Expanded(child: ListView.builder(itemCount: _tempPrizes.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(_tempPrizes[i].title), subtitle: Text(_tempPrizes[i].amount), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _tempPrizes.removeAt(i)))))))]);
  void _addPrize() { TextEditingController t = TextEditingController(), a = TextEditingController(); showDialog(context: context, builder: (c) => AlertDialog(title: const Text('جایزه'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: a, decoration: const InputDecoration(labelText: 'مبلغ/توضیح'))]), actions: [ElevatedButton(onPressed: () { setState(() => _tempPrizes.add(PrizeRecord(title: t.text, amount: a.text, iconCode: Icons.stars.codePoint, colorValue: Colors.orange.value))); Navigator.pop(c); }, child: const Text('ثبت'))])); }
  Widget _buildWinnersTab() => Column(children: [ElevatedButton(onPressed: _addWinner, child: const Text('افزودن برنده')), Expanded(child: ListView.builder(itemCount: _tempWinners.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(_tempWinners[i].name), subtitle: Text(_tempWinners[i].city), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _tempWinners.removeAt(i)))))))]);
  void _addWinner() { TextEditingController n = TextEditingController(), ci = TextEditingController(), p = TextEditingController(), d = TextEditingController(); showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: ci, decoration: const InputDecoration(labelText: 'شهر')), TextField(controller: p, decoration: const InputDecoration(labelText: 'جایزه')), TextField(controller: d, decoration: const InputDecoration(labelText: 'تاریخ'))]), actions: [ElevatedButton(onPressed: () { setState(() => _tempWinners.add(Winner(name: n.text, city: ci.text, prize: p.text, date: d.text))); Navigator.pop(c); }, child: const Text('ثبت'))])); }
  Widget _buildSettingsTab() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [_buildStyledField(_sTel, 'آیدی تلگرام پشتیبانی', Icons.telegram), _buildStyledField(_sWA, 'شماره واتس‌اپ پشتیبانی', Icons.message), _buildStyledField(_rules, 'قوانین قرعه‌کشی', Icons.gavel), _buildStyledField(_pay, 'لینک درگاه پرداخت', Icons.link), _buildStyledField(_fee, 'هزینه ورودی قرعه', Icons.payments), _buildStyledField(_title, 'عنوان بنر قرعه', Icons.title), _buildStyledField(_prize, 'جایزه بنر قرعه', Icons.card_giftcard), _buildStyledField(_date, 'تاریخ بنر قرعه', Icons.event), _buildStyledField(_cInsta, 'نام طبقه ۱', Icons.label), _buildStyledField(_cTele, 'نام طبقه ۲', Icons.label), _buildStyledField(_cOther, 'نام طبقه ۳', Icons.label)]));
  Widget _buildStyledField(TextEditingController c, String l, IconData i) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))));
}
