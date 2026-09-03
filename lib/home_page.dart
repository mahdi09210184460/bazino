import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'register_page.dart';
import 'dart:math';
import 'dart:convert';
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

class SupportTicket {
  dynamic id; String userName, userPhone, username, message, adminReply, status, date, imageUrl;
  SupportTicket({this.id, required this.userName, required this.userPhone, required this.username, required this.message, this.adminReply = '', this.status = 'در انتظار', required this.date, this.imageUrl = ''});
  Map<String, dynamic> toJson() => {'user_name': userName, 'user_phone': userPhone, 'username': username, 'message': message, 'admin_reply': adminReply, 'status': status, 'date': date, 'image_url': imageUrl};
  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(id: json['id'], userName: json['user_name'] ?? '', userPhone: json['user_phone'] ?? '', username: json['username'] ?? '', message: json['message'] ?? '', adminReply: json['admin_reply'] ?? '', status: json['status'] ?? 'در انتظار', date: json['date'] ?? '', imageUrl: json['image_url'] ?? '');
}

class OrderRecord {
  dynamic id; final String userName, userPhone, username, productTitle, trackingCode; String status; final String date;
  OrderRecord({this.id, required this.userName, required this.userPhone, required this.username, required this.productTitle, required this.trackingCode, required this.status, required this.date});
  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(id: json['id'], userName: json['user_name'] ?? '', userPhone: json['user_phone'] ?? '', username: json['username'] ?? '', productTitle: json['product_title'] ?? '', trackingCode: json['tracking_code'] ?? '', status: json['status'] ?? "در انتظار", date: json['date'] ?? '');
}

class WalletTransaction {
  final String title, amount, type, date;
  WalletTransaction({required this.title, required this.amount, required this.type, required this.date});
  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(title: json['title'] ?? 'شارژ/خرید', amount: (json['amount'] ?? 0).toString(), type: json['type'] ?? '', date: json['date'] ?? '');
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

class LotteryParticipant {
  dynamic id; final String name, phone, username, lotteryCode, date;
  LotteryParticipant({this.id, required this.name, required this.phone, required this.username, required this.lotteryCode, required this.date});
  factory LotteryParticipant.fromJson(Map<String, dynamic> json) => LotteryParticipant(id: json['id'], name: json['name'] ?? '', phone: json['phone'] ?? '', username: json['username'] ?? '', lotteryCode: json['lottery_code'] ?? '', date: json['date'] ?? '');
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

  String _username = "", _instaID = "pico", _telegramID = "@pico", _supportEmail = "pico@support", _paymentLink = "https://zarrinpal.com", _lotteryEntryFee = "۱۰,۰۰۰ تومان", _lotteryRules = "قوانین برنامه", _aiBase = "دستیار هوشمند";
  String _catInstaName = "اینستاگرام", _catTeleName = "تلگرام", _catOtherName = "سایر";
  int _walletBalance = 0;
  List<Product> _instaProducts = [], _telegramProducts = [], _otherProducts = [], _cart = [];
  List<Winner> _lotteryWinners = []; List<PrizeRecord> _prizes = []; List<LotteryParticipant> _lotteryParticipants = []; List<OrderRecord> _allOrders = []; List<AppUserRecord> _appUsers = []; List<SupportTicket> _myTickets = [], _allTickets = []; List<AppNews> _allNews = []; List<WalletTransaction> _myTransactions = [];
  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ هفتگی', _lotteryBannerPrize = 'جایزه ۵ میلیونی', _lotteryBannerDate = 'جمعه ساعت ۲۱';
  bool _isLoading = true; String _searchProductQuery = "";
  int _lotteryStep = 0;
  final TextEditingController _lNameController = TextEditingController(), _lPhoneController = TextEditingController();

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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دسترسی شما به دلیل تخلف مسدود شد'), backgroundColor: Colors.red));
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
        if (k == 'ai_base') _aiBase = v;
        if (k == 'cat_insta_name') _catInstaName = v;
        if (k == 'cat_tele_name') _catTeleName = v;
        if (k == 'cat_other_name') _catOtherName = v;
      }
      final userRes = await _supabase.from('app_users').select().eq('phone', widget.userPhone).maybeSingle();
      if (userRes != null) {
        if (userRes['is_banned'] == true) { _handleBan(); return; }
        _walletBalance = userRes['wallet_balance'] ?? 0;
        _username = userRes['username'] ?? 'User';
      }
      _instaProducts = (await _supabase.from('products').select().eq('category', 'insta')).map((e) => Product.fromJson(e)).toList();
      _telegramProducts = (await _supabase.from('products').select().eq('category', 'tele')).map((e) => Product.fromJson(e)).toList();
      _otherProducts = (await _supabase.from('products').select().eq('category', 'other')).map((e) => Product.fromJson(e)).toList();
      _lotteryWinners = (await _supabase.from('winners').select().order('created_at', ascending: false)).map((e) => Winner.fromJson(e)).toList();
      _prizes = (await _supabase.from('prizes').select()).map((e) => PrizeRecord.fromJson(e)).toList();
      _lotteryParticipants = (await _supabase.from('participants').select().order('created_at', ascending: false)).map((e) => LotteryParticipant.fromJson(e)).toList();
      _allOrders = (await _supabase.from('orders').select().order('created_at', ascending: false)).map((e) => OrderRecord.fromJson(e)).toList();
      _appUsers = (await _supabase.from('app_users').select().order('created_at', ascending: false)).map((e) => AppUserRecord.fromJson(e)).toList();
      _allTickets = (await _supabase.from('tickets').select().order('created_at', ascending: false)).map((e) => SupportTicket.fromJson(e)).toList();
      _allNews = (await _supabase.from('news').select().order('created_at', ascending: false)).map((e) => AppNews.fromJson(e)).toList();
      _myTickets = _allTickets.where((t) => t.userPhone == widget.userPhone).toList();
      _myTransactions = (await _supabase.from('wallet_transactions').select().eq('user_phone', widget.userPhone).order('created_at', ascending: false)).map((e) => WalletTransaction.fromJson(e)).toList();
      _assistantAutoScan();
    } catch (e) { debugPrint('Supabase Error: $e'); }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _assistantAutoScan() async {
    final prefs = await SharedPreferences.getInstance();
    for (var order in _allOrders.where((o) => o.userPhone == widget.userPhone)) {
      String key = 'order_status_${order.id}';
      String? lastStatus = prefs.getString(key);
      if (lastStatus != null && lastStatus != order.status) {
        await _supabase.from('messages').insert({'user_phone': widget.userPhone, 'title': 'بروزرسانی سفارش', 'content': "سفارش '${order.productTitle}' به وضعیت '${order.status}' تغییر یافت.", 'date': DateTime.now().toString().split('.')[0]});
      }
      await prefs.setString(key, order.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    List<Widget> widgetOptions = [_buildStoreContent(), _buildPrizesContent(), _buildLotteryContent(), _buildOrdersContent(), _buildProfileContent()];
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text(['فروشگاه پیکو', 'جوایز', 'قرعه‌کشی', 'سفارشات', 'پروفایل'][_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange, centerTitle: true, actions: [IconButton(onPressed: _fetchSupabaseData, icon: const Icon(Icons.refresh)), Stack(children: [IconButton(onPressed: _showCartDialog, icon: const Icon(Icons.shopping_cart)), if (_cart.isNotEmpty) Positioned(right: 5, top: 5, child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text('${_cart.length}', style: const TextStyle(fontSize: 10, color: Colors.white))))])]),
      body: widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(onPressed: _showSupportDialog, backgroundColor: Colors.orange, child: const Icon(Icons.support_agent)),
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, selectedItemColor: Colors.orange, unselectedItemColor: Colors.grey, currentIndex: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i), items: const [BottomNavigationBarItem(icon: Icon(Icons.store), label: 'فروشگاه'), BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'جوایز'), BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'قرعه‌کشی'), BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'سفارشات'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل')]),
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

  Widget _buildCategorySection(String t, List<Product> p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.all(16), child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), SizedBox(height: 240, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: p.length, itemBuilder: (c, i) => _buildProductCard(p[i])))]);
  Widget _buildProductCard(Product p) => Container(width: 165, margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [const SizedBox(height: 15), Image.network(p.imageUrl, height: 65, errorBuilder: (c, e, s) => const Icon(Icons.image, size: 60)), const SizedBox(height: 15), Text(p.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1), const Spacer(), Text(p.price, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), Container(width: double.infinity, margin: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () { setState(() => _cart.add(p)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اضافه شد'))); }, child: const Text('افزودن')))]));
  void _showCartDialog() {
    int total = _cart.fold(0, (sum, item) => sum + item.priceInt);
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (c) => StatefulBuilder(builder: (c, setS) => Container(padding: const EdgeInsets.all(25), height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [const Text('🛒 سبد خرید', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Expanded(child: ListView.builder(itemCount: _cart.length, itemBuilder: (c, i) => ListTile(title: Text(_cart[i].title), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => _cart.removeAt(i)); setS(() {}); } )))), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('مجموع:'), Text('$total تومان')]), ElevatedButton(onPressed: _cart.isEmpty ? null : () => _processOrder(total), child: const Text('پرداخت'))]))));
  }
  Future<void> _processOrder(int total) async {
    if (_walletBalance >= total) {
      String track = "TRK-${Random().nextInt(90000) + 10000}";
      _walletBalance -= total; await _supabase.from('app_users').update({'wallet_balance': _walletBalance}).eq('phone', widget.userPhone);
      for (var p in _cart) { await _supabase.from('orders').insert({'user_name': widget.userName, 'user_phone': widget.userPhone, 'username': _username, 'product_title': p.title, 'tracking_code': track, 'status': 'در حال انجام', 'date': DateTime.now().toString().split('.')[0]}); }
      Navigator.pop(context); _cart.clear(); _fetchSupabaseData(); _showSuccess('ثبت شد. کد: $track');
    } else { Navigator.pop(context); _showRecharge(); }
  }

  Widget _buildLotteryContent() {
    if (_lotteryStep == 1) return _buildLotteryStep1();
    if (_lotteryStep == 2) return _buildLotteryStep2();
    if (_lotteryStep == 3) return _buildLotterySuccess();
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(30)), child: Column(children: [const Icon(Icons.stars, color: Colors.white, size: 60), Text(_lotteryBannerTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.white70))])), const SizedBox(height: 20), ExpansionTile(title: const Text('📜 قوانین قرعه‌کشی'), children: [Padding(padding: const EdgeInsets.all(15), child: Text(_lotteryRules))]), const SizedBox(height: 20), ElevatedButton(onPressed: () => setState(() => _lotteryStep = 1), child: const Text('شروع ثبت‌نام'))]));
  }
  Widget _buildLotteryStep1() => Padding(padding: const EdgeInsets.all(25), child: Column(children: [const Text('تایید مشخصات'), TextField(controller: _lNameController, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: _lPhoneController, decoration: const InputDecoration(labelText: 'شماره')), ElevatedButton(onPressed: () => setState(() => _lotteryStep = 2), child: const Text('بعدی'))]));
  Widget _buildLotteryStep2() => Center(child: Column(children: [Text('ورودی: $_lotteryEntryFee'), ElevatedButton(onPressed: _handleLotteryPay, child: const Text('پرداخت'))]));
  Widget _buildLotterySuccess() => Center(child: Column(children: [const Icon(Icons.check_circle, color: Colors.green, size: 80), Text('کد شانس: $_generatedCode'), ElevatedButton(onPressed: () => setState(() => _lotteryStep = 0), child: const Text('بازگشت'))]));
  String _generatedCode = "";
  Future<void> _handleLotteryPay() async { launchUrl(Uri.parse(_paymentLink)); _showLoading('استعلام...'); await Future.delayed(const Duration(seconds: 3)); Navigator.pop(context); _generatedCode = "LOT-${Random().nextInt(90000)+10000}"; await _supabase.from('participants').insert({'name': _lNameController.text, 'phone': _lPhoneController.text, 'username': _username, 'lottery_code': _generatedCode, 'date': DateTime.now().toString().split('.')[0]}); setState(() => _lotteryStep = 3); }

  IconData _getIcon(int code) {
    if (code == Icons.looks_one.codePoint) return Icons.looks_one;
    if (code == Icons.looks_two.codePoint) return Icons.looks_two;
    if (code == Icons.looks_3.codePoint) return Icons.looks_3;
    return Icons.card_giftcard;
  }

  Widget _buildPrizesContent() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('🎁 جوایز دوره'), SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _prizes.length, itemBuilder: (c, i) => Card(child: Column(children: [Icon(_getIcon(_prizes[i].iconCode), size: 40, color: Color(_prizes[i].colorValue)), Text(_prizes[i].title), Text(_prizes[i].amount)])))), const Text('🏆 تالار برندگان'), ..._lotteryWinners.map((w) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('از ${w.city} | جایزه: ${w.prize}'), trailing: Text(w.date, style: const TextStyle(fontSize: 10)))))]));
  Widget _buildOrdersContent() => ListView.builder(itemCount: _allOrders.length, itemBuilder: (c, i) => _allOrders[i].userPhone == widget.userPhone ? Card(child: ListTile(title: Text(_allOrders[i].productTitle), subtitle: Text('کد: ${_allOrders[i].trackingCode}'), trailing: Text(_allOrders[i].status))) : const SizedBox.shrink());
  Widget _buildProfileContent() {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      Container(
        padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15)]),
        child: Column(children: [
          const CircleAvatar(radius: 45, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Colors.orange)),
          const SizedBox(height: 15), Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)), child: Text('نام کاربری: $_username', style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
      ),
      const SizedBox(height: 25),
      Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('موجودی کیف پول', style: TextStyle(color: Colors.grey)), Text('$_walletBalance تومان', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))]),
        ElevatedButton(onPressed: _showRecharge, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('شارژ آنی'))
      ]))),
      const SizedBox(height: 15),
      _buildProfileMenu(Icons.history, 'تاریخچه تراکنش‌ها', _showTransactions),
      _buildProfileMenu(Icons.info_outline, 'درباره پیکو مارکت', () { if (widget.userPhone == _adminPhone) Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPanel(instaProducts: _instaProducts, telegramProducts: _telegramProducts, otherProducts: _otherProducts, lotteryWinners: _lotteryWinners, prizes: _prizes, lotteryParticipants: _lotteryParticipants, allOrders: _allOrders, appUsers: _appUsers, allTickets: _allTickets, bannerTitle: _lotteryBannerTitle, bannerPrize: _lotteryBannerPrize, bannerDate: _lotteryBannerDate, insta: _instaID, tele: _telegramID, mail: _supportEmail, paymentLink: _paymentLink, lotteryFee: _lotteryEntryFee, lotteryRules: _lotteryRules, aiBase: _aiBase, catInsta: _catInstaName, catTele: _catTeleName, catOther: _catOtherName, onUpdate: (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r) => _fetchSupabaseData()))); }),
      const SizedBox(height: 30),
      ElevatedButton.icon(onPressed: () async { (await SharedPreferences.getInstance()).clear(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RegisterPage()), (r) => false); }, icon: const Icon(Icons.logout), label: const Text('خروج از حساب کاربری'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, minimumSize: const Size(double.infinity, 55))),
    ]));
  }
  Widget _buildProfileMenu(IconData i, String t, VoidCallback onTap) => Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(i, color: Colors.orange), title: Text(t), trailing: const Icon(Icons.chevron_right, size: 18), onTap: onTap));

  void _showSupportDialog() { showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (c) => Container(padding: const EdgeInsets.all(25), height: MediaQuery.of(context).size.height * 0.8, child: Column(children: [const Text('🎫 تیکت‌های پشتیبانی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Expanded(child: ListView.builder(itemCount: _myTickets.length, itemBuilder: (c, i) => ListTile(title: Text(_myTickets[i].message), subtitle: Text('وضعیت: ${_myTickets[i].status}'), onTap: () => _showTicketDetail(_myTickets[i])))), ElevatedButton(onPressed: _createNewTicket, child: const Text('ثبت تیکت جدید'))]))); }
  void _createNewTicket() {
    TextEditingController m = TextEditingController(); String? imgUrl;
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('تیکت جدید'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('نام کاربری: $_username'), const SizedBox(height: 10),
      TextField(controller: m, decoration: const InputDecoration(labelText: 'متن پیام'), maxLines: 3), const SizedBox(height: 10),
      ElevatedButton.icon(onPressed: () async {
        final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pick != null) {
          _showLoading('آپلود تصویر...');
          final bytes = await pick.readAsBytes();
          final path = 'tickets/${DateTime.now().millisecondsSinceEpoch}.png';
          await _supabase.storage.from('tickets').uploadBinary(path, bytes);
          imgUrl = _supabase.storage.from('tickets').getPublicUrl(path);
          Navigator.pop(context);
        }
      }, icon: const Icon(Icons.image), label: const Text('پیوست عکس (رسید)'))
    ]), actions: [ElevatedButton(onPressed: () async {
      await _supabase.from('tickets').insert({'user_name': widget.userName, 'user_phone': widget.userPhone, 'username': _username, 'message': m.text.trim(), 'image_url': imgUrl ?? '', 'date': DateTime.now().toString().split('.')[0]});
      Navigator.pop(c); _fetchSupabaseData();
    }, child: const Text('ارسال'))]));
  }
  void _showTicketDetail(SupportTicket t) { showDialog(context: context, builder: (c) => AlertDialog(title: const Text('جزئیات'), content: Column(mainAxisSize: MainAxisSize.min, children: [
    Text('پیام: ${t.message}'), const SizedBox(height: 10),
    if (t.imageUrl.isNotEmpty) InkWell(onTap: () => launchUrl(Uri.parse(t.imageUrl)), child: const Text('🖼 مشاهده تصویر پیوست', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
    const SizedBox(height: 10), Text('پاسخ: ${t.adminReply.isEmpty ? "خالی" : t.adminReply}')
  ]))); }

  void _showTransactions() => showDialog(context: context, builder: (c) => AlertDialog(title: const Text('تاریخچه'), content: SizedBox(width: double.maxFinite, height: 400, child: _myTransactions.isEmpty ? const Center(child: Text('خالی')) : ListView.builder(itemCount: _myTransactions.length, itemBuilder: (c, i) => ListTile(title: Text(_myTransactions[i].type), subtitle: Text(_myTransactions[i].date), trailing: Text('${_myTransactions[i].amount}'))))));
  void _showRecharge() { showDialog(context: context, builder: (c) => AlertDialog(title: const Text('شارژ'), content: Column(mainAxisSize: MainAxisSize.min, children: [for (var a in [200000, 400000, 600000, 800000, 1000000]) ListTile(title: Text('$a تومان'), onTap: () => _handleRecharge(a))]))); }
  Future<void> _handleRecharge(int a) async { Navigator.pop(context); launchUrl(Uri.parse(_paymentLink)); _showLoading('استعلام...'); await Future.delayed(const Duration(seconds: 4)); Navigator.pop(context); _walletBalance += a; await _supabase.from('app_users').update({'wallet_balance': _walletBalance}).eq('phone', widget.userPhone); _fetchSupabaseData(); }
  void _showLoading(String m) => showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), Text(m)])));
  void _showSuccess(String m) => showDialog(context: context, builder: (c) => AlertDialog(title: const Icon(Icons.check_circle, color: Colors.green), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]));
  Widget _buildInfoTile(IconData i, String l, String v, {VoidCallback? onDoubleTap}) => GestureDetector(onDoubleTap: onDoubleTap, child: ListTile(leading: Icon(i, color: Colors.orange), title: Text(l), subtitle: Text(v)));
}

class AdminPanel extends StatefulWidget {
  final List<Product> instaProducts, telegramProducts, otherProducts; final List<Winner> lotteryWinners; final List<PrizeRecord> prizes; final List<LotteryParticipant> lotteryParticipants; final List<OrderRecord> allOrders; final List<AppUserRecord> appUsers; final List<SupportTicket> allTickets; final String bannerTitle, bannerPrize, bannerDate, insta, tele, mail, paymentLink, lotteryFee, lotteryRules, aiBase, catInsta, catTele, catOther;
  final Function(List<Product>, List<Product>, List<Product>, List<Winner>, List<PrizeRecord>, List<LotteryParticipant>, List<OrderRecord>, String, String, String, String, String, String, String, String, String, String, String) onUpdate;
  const AdminPanel({super.key, required this.instaProducts, required this.telegramProducts, required this.otherProducts, required this.lotteryWinners, required this.prizes, required this.lotteryParticipants, required this.allOrders, required this.appUsers, required this.allTickets, required this.bannerTitle, required this.bannerPrize, required this.bannerDate, required this.insta, required this.tele, required this.mail, required this.paymentLink, required this.lotteryFee, required this.lotteryRules, required this.aiBase, required this.catInsta, required this.catTele, required this.catOther, required this.onUpdate});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late List<Product> _tempInsta, _tempTele, _tempOther; late List<Winner> _tempWinners; late List<PrizeRecord> _tempPrizes; late List<LotteryParticipant> _tempParticipants; late List<OrderRecord> _tempOrders; late List<SupportTicket> _tempTickets;
  late TextEditingController _title, _prize, _date, _inst, _tel, _mail, _pay, _fee, _rules, _ai, _cInsta, _cTele, _cOther;
  String _searchQuery = ""; final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tempInsta = List.from(widget.instaProducts); _tempTele = List.from(widget.telegramProducts); _tempOther = List.from(widget.otherProducts); _tempWinners = List.from(widget.lotteryWinners); _tempPrizes = List.from(widget.prizes); _tempParticipants = List.from(widget.lotteryParticipants); _tempOrders = List.from(widget.allOrders); _tempTickets = List.from(widget.allTickets);
    _title = TextEditingController(text: widget.bannerTitle); _prize = TextEditingController(text: widget.bannerPrize); _date = TextEditingController(text: widget.bannerDate); _inst = TextEditingController(text: widget.insta); _tel = TextEditingController(text: widget.tele); _mail = TextEditingController(text: widget.mail); _pay = TextEditingController(text: widget.paymentLink); _fee = TextEditingController(text: widget.lotteryFee); _rules = TextEditingController(text: widget.lotteryRules); _ai = TextEditingController(text: widget.aiBase); _cInsta = TextEditingController(text: widget.catInsta); _cTele = TextEditingController(text: widget.catTele); _cOther = TextEditingController(text: widget.catOther);
  }

  Future<void> _save() async {
    try {
      await _supabase.from('app_config').upsert([{'key': 'lottery_banner_title', 'value': _title.text.trim()}, {'key': 'lottery_banner_prize', 'value': _prize.text.trim()}, {'key': 'lottery_banner_date', 'value': _date.text.trim()}, {'key': 'insta_id', 'value': _inst.text.trim()}, {'key': 'telegram_id', 'value': _tel.text.trim()}, {'key': 'support_email', 'value': _mail.text.trim()}, {'key': 'payment_link', 'value': _pay.text.trim()}, {'key': 'lottery_entry_fee', 'value': _fee.text.trim()}, {'key': 'lottery_rules', 'value': _rules.text.trim()}, {'key': 'ai_base', 'value': _ai.text.trim()}, {'key': 'cat_insta_name', 'value': _cInsta.text.trim()}, {'key': 'cat_tele_name', 'value': _cTele.text.trim()}, {'key': 'cat_other_name', 'value': _cOther.text.trim()}], onConflict: 'key');
      await _supabase.from('products').delete().neq('id', -1);
      if (_tempInsta.isNotEmpty) await _supabase.from('products').insert(_tempInsta.map((e) => e.toJson()).toList());
      if (_tempTele.isNotEmpty) await _supabase.from('products').insert(_tempTele.map((e) => e.toJson()).toList());
      if (_tempOther.isNotEmpty) await _supabase.from('products').insert(_tempOther.map((e) => e.toJson()).toList());
      await _supabase.from('winners').delete().neq('id', -1);
      if (_tempWinners.isNotEmpty) await _supabase.from('winners').insert(_tempWinners.map((e) => e.toJson()).toList());
      await _supabase.from('prizes').delete().neq('id', -1);
      if (_tempPrizes.isNotEmpty) await _supabase.from('prizes').insert(_tempPrizes.map((e) => e.toJson()).toList());
      for (var o in _tempOrders) { if (o.id != null) await _supabase.from('orders').update({'status': o.status}).eq('id', o.id); }
      for (var t in _tempTickets) { if (t.id != null) await _supabase.from('tickets').update({'admin_reply': t.adminReply, 'status': t.status}).eq('id', t.id); }
      if (!mounted) return; Navigator.pop(context);
    } catch (e) { debugPrint('Save Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 7, child: Scaffold(backgroundColor: Colors.grey[100], appBar: AppBar(title: const Text('مدیریت پیشرفته'), backgroundColor: Colors.orange, actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)], bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'کاربران'), Tab(text: 'سفارشات'), Tab(text: 'تیکت‌ها'), Tab(text: 'محصولات'), Tab(text: 'جوایز'), Tab(text: 'تنظیمات')])), body: Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: TextField(decoration: const InputDecoration(labelText: 'جستجو نام/یوزرنیم...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => _searchQuery = v))),
      Expanded(child: TabBarView(children: [_buildUsersTab(), _buildOrdersTab(), _buildTicketsTab(), _buildProductsTab(), _buildLotteryMgmtTab(), _buildSettingsTab()])),
    ])));
  }

  Widget _buildUsersTab() {
    var filtered = widget.appUsers.where((u) => u.username.contains(_searchQuery) || u.name.contains(_searchQuery)).toList();
    return ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(filtered[i].name), subtitle: Text(filtered[i].username), trailing: IconButton(icon: const Icon(Icons.block, color: Colors.red), onPressed: () async { await _supabase.from('app_users').update({'is_banned': true}).eq('phone', filtered[i].phone); }))));
  }
  Widget _buildOrdersTab() {
    var filtered = _tempOrders.where((o) => o.username.contains(_searchQuery) || o.userName.contains(_searchQuery)).toList();
    var active = filtered.where((o) => o.status != "انجام شده").toList();
    var completed = filtered.where((o) => o.status == "انجام شده").toList();
    return ListView(children: [
      _adminSectionHeader('📦 در جریان (${active.length})', Colors.blue),
      ...active.map((o) => Card(child: ListTile(title: Text(o.productTitle), subtitle: Text('${o.username} | ${o.status}'), trailing: IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => setState(() => o.status = "انجام شده"))))),
      _adminSectionHeader('✅ ثبت شده ها (${completed.length})', Colors.green),
      ...completed.map((o) => Card(color: Colors.green.withOpacity(0.05), child: ListTile(title: Text(o.productTitle), subtitle: Text('${o.username} | انجام شده'), trailing: const Icon(Icons.done_all, color: Colors.green))))
    ]);
  }
  Widget _adminSectionHeader(String t, Color c) => Container(padding: const EdgeInsets.all(15), color: c.withOpacity(0.1), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c)));

  Widget _buildTicketsTab() {
    var filtered = _tempTickets.where((t) => t.username.contains(_searchQuery) || t.userName.contains(_searchQuery)).toList();
    return ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(filtered[i].userName), subtitle: Text(filtered[i].message), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (filtered[i].imageUrl.isNotEmpty) IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => launchUrl(Uri.parse(filtered[i].imageUrl))), Text(filtered[i].status)]), onTap: () => _replyTicket(filtered[i]))));
  }
  void _replyTicket(SupportTicket t) { TextEditingController r = TextEditingController(text: t.adminReply); showDialog(context: context, builder: (c) => AlertDialog(title: const Text('پاسخ'), content: TextField(controller: r, maxLines: 3), actions: [ElevatedButton(onPressed: () { setState(() { t.adminReply = r.text; t.status = "پاسخ داده شده"; }); Navigator.pop(c); }, child: const Text('ثبت'))])); }
  Widget _buildProductsTab() => Column(children: [_buildCategoryMgmt(_cInsta.text, _tempInsta, 'insta'), _buildCategoryMgmt(_cTele.text, _tempTele, 'tele'), _buildCategoryMgmt(_cOther.text, _tempOther, 'other')]);
  Widget _buildCategoryMgmt(String t, List<Product> l, String k) => Card(child: Column(children: [ListTile(title: Text(t)), ...l.map((e) => ListTile(title: Text(e.title), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => l.remove(e))))), ElevatedButton(onPressed: () => _addProduct(l, k), child: const Text('افزودن'))]));
  void _addProduct(List<Product> l, String k) { TextEditingController t = TextEditingController(), p = TextEditingController(); showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: p, decoration: const InputDecoration(labelText: 'قیمت'))]), actions: [ElevatedButton(onPressed: () { setState(() => l.add(Product(title: t.text, price: '${t.text} تومان', quality: 'عالی', imageUrl: '', category: k, priceInt: int.tryParse(p.text) ?? 0))); Navigator.pop(c); }, child: const Text('افزودن'))])); }
  Widget _buildLotteryMgmtTab() => Column(children: [ElevatedButton(onPressed: _addWinner, child: const Text('افزودن برنده')), Expanded(child: ListView.builder(itemCount: _tempWinners.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(_tempWinners[i].name), subtitle: Text(_tempWinners[i].city), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _tempWinners.removeAt(i)))))))]);
  void _addWinner() { TextEditingController n = TextEditingController(), ci = TextEditingController(), p = TextEditingController(), d = TextEditingController(); showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: ci, decoration: const InputDecoration(labelText: 'شهر')), TextField(controller: p, decoration: const InputDecoration(labelText: 'جایزه')), TextField(controller: d, decoration: const InputDecoration(labelText: 'تاریخ'))]), actions: [ElevatedButton(onPressed: () { setState(() => _tempWinners.add(Winner(name: n.text, city: ci.text, prize: p.text, date: d.text))); Navigator.pop(c); }, child: const Text('ثبت'))])); }
  Widget _buildSettingsTab() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [_buildStyledField(_ai, 'جمله AI', Icons.psychology), _buildStyledField(_rules, 'قوانین', Icons.gavel), _buildStyledField(_cInsta, 'طبقه ۱', Icons.label), _buildStyledField(_cTele, 'طبقه ۲', Icons.label), _buildStyledField(_cOther, 'طبقه ۳', Icons.label), _buildStyledField(_pay, 'لینک پرداخت', Icons.link), _buildStyledField(_fee, 'ورودی', Icons.payments), _buildStyledField(_title, 'عنوان بنر', Icons.title), _buildStyledField(_prize, 'جایزه بنر', Icons.card_giftcard), _buildStyledField(_date, 'تاریخ بنر', Icons.event)]));
  Widget _buildStyledField(TextEditingController c, String l, IconData i) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))));
}
