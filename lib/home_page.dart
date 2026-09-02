import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'register_page.dart';
import 'dart:math';
import 'dart:convert';

class AppUserRecord {
  final String name, phone, username, lastLogin;
  AppUserRecord({required this.name, required this.phone, required this.username, required this.lastLogin});
  factory AppUserRecord.fromJson(Map<String, dynamic> json) => AppUserRecord(name: json['name'] ?? '', phone: json['phone'] ?? '', username: json['username'] ?? '', lastLogin: json['last_login'] ?? '');
}

class Product {
  dynamic id; String title, price, quality, imageUrl, category; int priceInt;
  Product({this.id, required this.title, required this.price, required this.quality, required this.imageUrl, required this.category, this.priceInt = 0});
  factory Product.fromJson(Map<String, dynamic> json) {
    String pStr = (json['price'] ?? '0').toString().replaceAll(',', '').replaceAll(' تومان', '').split(' /')[0];
    return Product(id: json['id'], title: json['title'] ?? '', price: json['price'] ?? '', quality: json['quality'] ?? '', imageUrl: json['image_url'] ?? '', category: json['category'] ?? 'other', priceInt: int.tryParse(pStr) ?? 0);
  }
}

class SupportTicket {
  dynamic id; String userName, userPhone, username, message, adminReply, status, date;
  SupportTicket({this.id, required this.userName, required this.userPhone, required this.username, required this.message, this.adminReply = '', this.status = 'در انتظار', required this.date});
  Map<String, dynamic> toJson() => {'user_name': userName, 'user_phone': userPhone, 'username': username, 'message': message, 'admin_reply': adminReply, 'status': status, 'date': date};
  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(id: json['id'], userName: json['user_name'] ?? '', userPhone: json['user_phone'] ?? '', username: json['username'] ?? '', message: json['message'] ?? '', adminReply: json['admin_reply'] ?? '', status: json['status'] ?? 'در انتظار', date: json['date'] ?? '');
}

class OrderRecord {
  dynamic id; final String userName, userPhone, username, productTitle, trackingCode; String status; final String date;
  OrderRecord({this.id, required this.userName, required this.userPhone, required this.username, required this.productTitle, required this.trackingCode, required this.status, required this.date});
  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(id: json['id'], userName: json['user_name'] ?? '', userPhone: json['user_phone'] ?? '', username: json['username'] ?? '', productTitle: json['product_title'] ?? '', trackingCode: json['tracking_code'] ?? '', status: json['status'] ?? "در انتظار", date: json['date'] ?? '');
}

class AppMessage {
  dynamic id; String title, content, date; bool isRead;
  AppMessage({this.id, required this.title, required this.content, required this.date, this.isRead = false});
  factory AppMessage.fromJson(Map<String, dynamic> json) => AppMessage(id: json['id'], title: json['title'] ?? '', content: json['content'] ?? '', date: json['date'] ?? '', isRead: json['is_read'] ?? false);
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

  String _username = "", _instaID = "pico", _telegramID = "@pico", _supportEmail = "pico@support", _paymentLink = "https://zarrinpal.com", _lotteryEntryFee = "۱۰,۰۰۰ تومان", _lotteryRules = "۱. پرداخت ورودی الزامی است.", _aiBase = "سلام من دستیار هوشمند هستم.";
  String _catInstaName = "اینستاگرام", _catTeleName = "تلگرام", _catOtherName = "سایر";
  int _walletBalance = 0;
  List<Product> _instaProducts = [], _telegramProducts = [], _otherProducts = [], _cart = [];
  List<Winner> _lotteryWinners = []; List<PrizeRecord> _prizes = []; List<LotteryParticipant> _lotteryParticipants = []; List<OrderRecord> _allOrders = []; List<AppUserRecord> _appUsers = []; List<SupportTicket> _myTickets = [], _allTickets = []; List<AppMessage> _myMessages = [];
  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ', _lotteryBannerPrize = 'جایزه ویژه', _lotteryBannerDate = 'جمعه';

  int _lotteryStep = 0;
  final TextEditingController _lNameController = TextEditingController(), _lPhoneController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchSupabaseData(); }

  Future<void> _fetchSupabaseData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final configRes = await _supabase.from('app_config').select();
      for (var item in configRes) {
        String k = item['key'], v = item['value'];
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
      if (userRes != null) { _walletBalance = userRes['wallet_balance'] ?? 0; _username = userRes['username'] ?? 'بدون نام کاربری'; }

      _instaProducts = (await _supabase.from('products').select().eq('category', 'insta')).map((e) => Product.fromJson(e)).toList();
      _telegramProducts = (await _supabase.from('products').select().eq('category', 'tele')).map((e) => Product.fromJson(e)).toList();
      _otherProducts = (await _supabase.from('products').select().eq('category', 'other')).map((e) => Product.fromJson(e)).toList();
      _lotteryWinners = (await _supabase.from('winners').select().order('created_at', ascending: false)).map((e) => Winner.fromJson(e)).toList();
      _prizes = (await _supabase.from('prizes').select()).map((e) => PrizeRecord.fromJson(e)).toList();
      _lotteryParticipants = (await _supabase.from('participants').select().order('created_at', ascending: false)).map((e) => LotteryParticipant.fromJson(e)).toList();
      _allOrders = (await _supabase.from('orders').select().order('created_at', ascending: false)).map((e) => OrderRecord.fromJson(e)).toList();
      _appUsers = (await _supabase.from('app_users').select().order('created_at', ascending: false)).map((e) => AppUserRecord.fromJson(e)).toList();
      _allTickets = (await _supabase.from('tickets').select().order('created_at', ascending: false)).map((e) => SupportTicket.fromJson(e)).toList();
      _myTickets = _allTickets.where((t) => t.userPhone == widget.userPhone).toList();
      _myMessages = (await _supabase.from('messages').select().eq('user_phone', widget.userPhone).order('created_at', ascending: false)).map((e) => AppMessage.fromJson(e)).toList();
      
      _assistantAutoScan(); // AI monitors orders
    } catch (e) { debugPrint('Supabase Error: $e'); }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _assistantAutoScan() async {
    final prefs = await SharedPreferences.getInstance();
    for (var order in _allOrders.where((o) => o.userPhone == widget.userPhone)) {
      String key = 'order_status_${order.id}';
      String? lastStatus = prefs.getString(key);
      if (lastStatus != null && lastStatus != order.status) {
        String msg = "سفارش شما برای '${order.productTitle}' به وضعیت '${order.status}' تغییر یافت.";
        await _supabase.from('messages').insert({'user_phone': widget.userPhone, 'title': 'بروزرسانی سفارش', 'content': msg, 'date': DateTime.now().toString().split('.')[0]});
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
      floatingActionButton: FloatingActionButton(onPressed: _showAssistantDialog, backgroundColor: Colors.purple, child: const Icon(Icons.psychology, color: Colors.white)),
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, selectedItemColor: Colors.orange, currentIndex: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i), items: const [BottomNavigationBarItem(icon: Icon(Icons.store), label: 'فروشگاه'), BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'جوایز'), BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'قرعه‌کشی'), BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'سفارشات'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل')]),
    );
  }

  // --- ASSISTANT & MESSAGES ---
  void _showAssistantDialog() {
    TextEditingController query = TextEditingController();
    List<Map<String, String>> chatHistory = [{"role": "bot", "msg": _aiBase}];
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (c) => StatefulBuilder(builder: (c, setS) => Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20), height: MediaQuery.of(c).size.height * 0.8,
      child: Column(children: [
        Row(children: [const Icon(Icons.psychology, color: Colors.purple), const SizedBox(width: 10), const Text('دستیار هوشمند پیکو', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))]),
        Expanded(child: ListView.builder(itemCount: chatHistory.length, itemBuilder: (c, i) => _buildChatBubble(chatHistory[i]))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
          Expanded(child: TextField(controller: query, decoration: const InputDecoration(hintText: 'سوال بپرسید...', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)))))),
          const SizedBox(width: 10),
          IconButton(onPressed: () {
            if (query.text.trim().isEmpty) return;
            setS(() {
              chatHistory.add({"role": "user", "msg": query.text.trim()});
              String response = _getAIResponse(query.text.trim());
              chatHistory.add({"role": "bot", "msg": response});
              query.clear();
            });
          }, icon: const Icon(Icons.send, color: Colors.purple))
        ])),
        if (chatHistory.length > 2) TextButton(onPressed: _createNewTicket, child: const Text('ارسال گفتگو به مدیر', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)))
      ]),
    )));
  }

  String _getAIResponse(String q) {
    q = q.toLowerCase();
    if (q.contains('سفارش') || q.contains('وضعیت')) {
      var active = _allOrders.where((o) => o.userPhone == widget.userPhone).toList();
      if (active.isEmpty) return 'شما هنوز سفارشی ثبت نکرده‌اید.';
      return 'شما ${active.length} سفارش دارید. آخرین وضعیت: ${active.first.status}';
    }
    if (q.contains('موجودی') || q.contains('پول')) return 'موجودی فعلی شما $_walletBalance تومان است.';
    return 'در حال حاضر می‌توانم در مورد سفارشات و کیف پول به شما کمک کنم. اگر سوال خاصی دارید بپرسید یا گفتگو را برای مدیر بفرستید.';
  }

  Widget _buildChatBubble(Map<String, String> chat) {
    bool isBot = chat['role'] == 'bot';
    return Align(alignment: isBot ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: isBot ? Colors.grey[200] : Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Text(chat['msg']!, style: TextStyle(color: isBot ? Colors.black : Colors.purple[900]))));
  }

  void _showMessages() {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('📩 پیام‌های سیستم (پیامک داخلی)'), content: SizedBox(width: double.maxFinite, height: 400, child: _myMessages.isEmpty ? const Center(child: Text('پیامی ندارید')) : ListView.builder(itemCount: _myMessages.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(_myMessages[i].title), subtitle: Text(_myMessages[i].content), trailing: Text(_myMessages[i].date, style: const TextStyle(fontSize: 9)))))), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]));
  }

  // --- UI COMPONENTS ---
  Widget _buildStoreContent() => SingleChildScrollView(child: Column(children: [_buildCategorySection(_catInstaName, _instaProducts), _buildCategorySection(_catTeleName, _telegramProducts), _buildCategorySection(_catOtherName, _otherProducts), const SizedBox(height: 20)]));
  Widget _buildCategorySection(String t, List<Product> p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.all(16), child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), SizedBox(height: 240, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: p.length, itemBuilder: (c, i) => _buildProductCard(p[i])))]);
  Widget _buildProductCard(Product p) => Container(width: 165, margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [const SizedBox(height: 15), Image.network(p.imageUrl, height: 65, errorBuilder: (c, e, s) => const Icon(Icons.image, size: 60)), const SizedBox(height: 15), Text(p.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1), const Spacer(), Text(p.price, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), Container(width: double.infinity, margin: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () { setState(() => _cart.add(p)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('به سبد اضافه شد'), duration: Duration(seconds: 1))); }, child: const Text('افزودن')))]));
  void _showCartDialog() {
    int total = _cart.fold(0, (sum, item) => sum + item.priceInt);
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (c) => StatefulBuilder(builder: (c, setS) => Container(padding: const EdgeInsets.all(25), height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [const Text('🛒 سبد خرید', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Expanded(child: _cart.isEmpty ? const Center(child: Text('خالی')) : ListView.builder(itemCount: _cart.length, itemBuilder: (c, i) => ListTile(title: Text(_cart[i].title), subtitle: Text(_cart[i].price), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => _cart.removeAt(i)); setS(() {}); } )))), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('مجموع:'), Text('$total تومان', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('موجودی کیف پول:'), Text('$_walletBalance تومان')]), const SizedBox(height: 20), ElevatedButton(onPressed: _cart.isEmpty ? null : () => _processOrder(total), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 55)), child: const Text('پرداخت و ثبت سفارش'))]))));
  }
  Future<void> _processOrder(int total) async {
    if (_walletBalance >= total) {
      String track = "TRK-${Random().nextInt(90000) + 10000}";
      _walletBalance -= total; await _supabase.from('app_users').update({'wallet_balance': _walletBalance}).eq('phone', widget.userPhone);
      for (var p in _cart) { await _supabase.from('orders').insert({'user_name': widget.userName, 'user_phone': widget.userPhone, 'username': _username, 'product_title': p.title, 'tracking_code': track, 'status': 'در حال انجام', 'date': DateTime.now().toString().split('.')[0]}); }
      Navigator.pop(context); _cart.clear(); _fetchSupabaseData(); _showSuccess('سفارش ثبت شد.\nنام کاربری: $_username\nکد پیگیری: $track');
    } else { Navigator.pop(context); _showRecharge(); }
  }
  Widget _buildLotteryContent() {
    if (_lotteryStep == 1) return _buildLotteryStep1();
    if (_lotteryStep == 2) return _buildLotteryStep2();
    if (_lotteryStep == 3) return _buildLotterySuccess();
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(30)), child: Column(children: [const Icon(Icons.stars, color: Colors.white, size: 60), Text(_lotteryBannerTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.white70)), const Divider(color: Colors.white24, height: 30), Text('موعد: $_lotteryBannerDate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 20), ExpansionTile(title: const Text('📜 قوانین و مقررات قرعه‌کشی', style: TextStyle(fontWeight: FontWeight.bold)), children: [Padding(padding: const EdgeInsets.all(15), child: Text(_lotteryRules, style: const TextStyle(height: 1.6)))]),
      const SizedBox(height: 20), ElevatedButton(onPressed: () => setState(() => _lotteryStep = 1), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('شروع ثبت‌نام'))
    ]));
  }
  String _genLotCode = "";
  Widget _buildLotteryStep1() => Padding(padding: const EdgeInsets.all(25), child: Column(children: [const Text('مرحله اول: تایید مشخصات'), const SizedBox(height: 30), TextField(controller: _lNameController, decoration: const InputDecoration(labelText: 'نام و خانوادگی')), TextField(controller: _lPhoneController, decoration: const InputDecoration(labelText: 'شماره تماس')), const SizedBox(height: 30), ElevatedButton(onPressed: () => setState(() => _lotteryStep = 2), child: const Text('بعدی'))]));
  Widget _buildLotteryStep2() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('مبلغ ورودی: $_lotteryEntryFee'), const SizedBox(height: 40), ElevatedButton(onPressed: _handleLotteryPay, child: const Text('پرداخت آنلاین'))]));
  Widget _buildLotterySuccess() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, color: Colors.green, size: 100), Text('نام کاربری: $_username'), const Text('کد شانس:'), Text(_genLotCode, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange)), ElevatedButton(onPressed: () => setState(() => _lotteryStep = 0), child: const Text('بازگشت'))]));
  Future<void> _handleLotteryPay() async { launchUrl(Uri.parse(_paymentLink)); _showLoading('در حال استعلام...'); await Future.delayed(const Duration(seconds: 3)); Navigator.pop(context); _genLotCode = "LOT-${Random().nextInt(90000)+10000}"; await _supabase.from('participants').insert({'name': _lNameController.text, 'phone': _lPhoneController.text, 'username': _username, 'lottery_code': _genLotCode, 'date': DateTime.now().toString().split('.')[0]}); setState(() => _lotteryStep = 3); }
  Widget _buildPrizesContent() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('🎁 جوایز دوره'), SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _prizes.length, itemBuilder: (c, i) => Card(child: Column(children: [Icon(_getIcon(_prizes[i].iconCode), size: 40, color: Color(_prizes[i].colorValue)), Text(_prizes[i].title), Text(_prizes[i].amount)])))), const Text('🏆 تالار برندگان'), ..._lotteryWinners.map((w) => Card(child: ListTile(title: Text(w.name), subtitle: Text('از ${w.city} | جایزه: ${w.prize}'))))]));
  Widget _buildOrdersContent() => ListView.builder(itemCount: _allOrders.length, itemBuilder: (c, i) => _allOrders[i].userPhone == widget.userPhone ? Card(child: ListTile(title: Text(_allOrders[i].productTitle), subtitle: Text('کد: ${_allOrders[i].trackingCode}'), trailing: Text(_allOrders[i].status))) : const SizedBox.shrink());
  Widget _buildProfileContent() => SingleChildScrollView(padding: const EdgeInsets.all(25), child: Column(children: [const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)), const SizedBox(height: 15), Text(widget.userName), Text('نام کاربری: $_username', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), Text('موجودی: $_walletBalance تومان'), const SizedBox(height: 10), ElevatedButton.icon(onPressed: _showMessages, icon: const Icon(Icons.message), label: const Text('پیام‌های من')), ElevatedButton(onPressed: _showRecharge, child: const Text('شارژ کیف پول')), _buildInfoTile(Icons.info_outline, 'مدیریت', 'ورود به پنل', onDoubleTap: () { if (widget.userPhone == _adminPhone) Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPanel(instaProducts: _instaProducts, telegramProducts: _telegramProducts, otherProducts: _otherProducts, lotteryWinners: _lotteryWinners, prizes: _prizes, lotteryParticipants: _lotteryParticipants, allOrders: _allOrders, appUsers: _appUsers, allTickets: _allTickets, bannerTitle: _lotteryBannerTitle, bannerPrize: _lotteryBannerPrize, bannerDate: _lotteryBannerDate, insta: _instaID, tele: _telegramID, mail: _supportEmail, paymentLink: _paymentLink, lotteryFee: _lotteryEntryFee, lotteryRules: _lotteryRules, aiBase: _aiBase, catInsta: _catInstaName, catTele: _catTeleName, catOther: _catOtherName, onUpdate: (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r) => _fetchSupabaseData()))); }), ElevatedButton(onPressed: () async { (await SharedPreferences.getInstance()).clear(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RegisterPage()), (r) => false); }, child: const Text('خروج'))]));
  void _showSupportDialog() { showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => Container(padding: const EdgeInsets.all(25), height: MediaQuery.of(context).size.height * 0.8, child: Column(children: [const Text('🎫 پشتیبانی'), Expanded(child: ListView.builder(itemCount: _myTickets.length, itemBuilder: (c, i) => ListTile(title: Text(_myTickets[i].message), subtitle: Text('وضعیت: ${_myTickets[i].status}'), onTap: () => _showTicketDetail(_myTickets[i])))), ElevatedButton(onPressed: _createNewTicket, child: const Text('ثبت تیکت جدید'))]))); }
  void _createNewTicket() { TextEditingController m = TextEditingController(); showDialog(context: context, builder: (c) => AlertDialog(title: const Text('تیکت جدید'), content: Column(mainAxisSize: MyAxisSize.min, children: [Text('نام کاربری: $_username'), TextField(controller: m, decoration: const InputDecoration(labelText: 'متن پیام'), maxLines: 3)]), actions: [ElevatedButton(onPressed: () async { await _supabase.from('tickets').insert({'user_name': widget.userName, 'user_phone': widget.userPhone, 'username': _username, 'message': m.text.trim(), 'date': DateTime.now().toString().split('.')[0]}); Navigator.pop(c); _fetchSupabaseData(); }, child: const Text('ارسال'))])); }
  void _showTicketDetail(SupportTicket t) { showDialog(context: context, builder: (c) => AlertDialog(title: const Text('جزئیات'), content: Text('پیام: ${t.message}\n\nپاسخ مدیر: ${t.adminReply.isEmpty ? "خالی" : t.adminReply}'))); }
  void _showRecharge() { showDialog(context: context, builder: (c) => AlertDialog(title: const Text('شارژ کیف پول'), content: Column(mainAxisSize: MyAxisSize.min, children: [for (var a in [200000, 400000, 600000, 800000, 1000000]) ListTile(title: Text('$a تومان'), onTap: () => _handleRecharge(a))]))); }
  Future<void> _handleRecharge(int a) async { Navigator.pop(context); launchUrl(Uri.parse(_paymentLink)); _showLoading('در حال استعلام...'); await Future.delayed(const Duration(seconds: 4)); Navigator.pop(context); _walletBalance += a; await _supabase.from('app_users').update({'wallet_balance': _walletBalance}).eq('phone', widget.userPhone); _fetchSupabaseData(); }
  void _showLoading(String m) => showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MyAxisSize.min, children: [const CircularProgressIndicator(), Text(m)])));
  void _showSuccess(String m) => showDialog(context: context, builder: (c) => AlertDialog(title: const Icon(Icons.check_circle, color: Colors.green), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]));
  IconData _getIcon(int c) => IconData(c, fontFamily: 'MaterialIcons');
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
  String _searchQuery = "";
  final SupabaseClient _supabase = Supabase.instance.client;

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
      if (!mounted) return;
      widget.onUpdate(_tempInsta, _tempTele, _tempOther, _tempWinners, _tempPrizes, _tempParticipants, _tempOrders, _title.text.trim(), _prize.text.trim(), _date.text.trim(), _inst.text.trim(), _tel.text.trim(), _mail.text.trim(), _pay.text.trim(), _fee.text.trim(), _cInsta.text.trim(), _cTele.text.trim(), _cOther.text.trim());
      Navigator.pop(context);
    } catch (e) { debugPrint('Save Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 5, child: Scaffold(backgroundColor: Colors.grey[100], appBar: AppBar(title: const Text('پنل مدیریت'), backgroundColor: Colors.orange, actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)], bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'کاربران'), Tab(text: 'تیکت‌ها'), Tab(text: 'محصولات'), Tab(text: 'جوایز'), Tab(text: 'تنظیمات')])), body: Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: TextField(decoration: const InputDecoration(labelText: 'جستجو...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => _searchQuery = v))),
      Expanded(child: TabBarView(children: [_buildUsersTab(), _buildTicketsTab(), _buildProductsTab(), _buildLotteryMgmtTab(), _buildSettingsTab()])),
    ])));
  }

  Widget _buildUsersTab() {
    var filteredUsers = widget.appUsers.where((u) => u.username.contains(_searchQuery) || u.name.contains(_searchQuery)).toList();
    var filteredParts = _tempParticipants.where((p) => p.username.contains(_searchQuery) || p.name.contains(_searchQuery)).toList();
    var filteredOrders = _tempOrders.where((o) => o.username.contains(_searchQuery) || o.userName.contains(_searchQuery)).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(15), child: Column(children: [
      _adminCardSection('👤 کاربران', Colors.blueGrey, filteredUsers.isEmpty, null, filteredUsers.map((u) => ListTile(title: Text(u.name), subtitle: Text(u.username))).toList()),
      const SizedBox(height: 20),
      _adminCardSection('📦 سفارشات', Colors.blue, filteredOrders.isEmpty, null, filteredOrders.map((o) => ListTile(title: Text(o.productTitle), subtitle: Text('${o.username} | ${o.status}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => setState(() => o.status = "انجام شده")), IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => o.status = "تاخیر در ارسال"))]))).toList())
    ]));
  }
  Widget _buildTicketsTab() {
    var filteredTickets = _tempTickets.where((t) => t.username.contains(_searchQuery) || t.userName.contains(_searchQuery)).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(15), child: _adminCardSection('🎫 تیکت‌ها', Colors.red, filteredTickets.isEmpty, null, filteredTickets.map((t) => ListTile(title: Text(t.userName), subtitle: Text(t.message), trailing: Text(t.status), onTap: () => _replyTicket(t))).toList()));
  }
  void _replyTicket(SupportTicket t) {
    TextEditingController r = TextEditingController(text: t.adminReply);
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('پاسخ'), content: TextField(controller: r, maxLines: 3), actions: [ElevatedButton(onPressed: () { setState(() { t.adminReply = r.text.trim(); t.status = "پاسخ داده شده"; }); Navigator.pop(c); }, child: const Text('ثبت'))]));
  }
  Widget _buildProductsTab() => SingleChildScrollView(padding: const EdgeInsets.all(15), child: Column(children: [_buildCategoryMgmt(_cInsta.text, _tempInsta, 'insta'), _buildCategoryMgmt(_cTele.text, _tempTele, 'tele'), _buildCategoryMgmt(_cOther.text, _tempOther, 'other')]));
  Widget _buildLotteryMgmtTab() => SingleChildScrollView(padding: const EdgeInsets.all(15), child: Column(children: [_adminCardSection('🎁 جوایز', Colors.orange, _tempPrizes.isEmpty, null, _tempPrizes.asMap().entries.map((e) => ListTile(title: Text(e.value.title), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _tempPrizes.removeAt(e.key))))).toList(), footer: ElevatedButton(onPressed: _addPrize, child: const Text('افزودن جایزه'))), const SizedBox(height: 20), _adminCardSection('🏆 برندگان', Colors.green, _tempWinners.isEmpty, null, _tempWinners.asMap().entries.map((e) => ListTile(title: Text(e.value.name), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _tempWinners.removeAt(e.key))))).toList(), footer: ElevatedButton(onPressed: _addWinner, child: const Text('افزودن برنده'))) ]));
  Widget _buildSettingsTab() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [ _buildStyledField(_ai, 'جمله شروع دستیار هوشمند', Icons.psychology, maxLines: 2), _buildStyledField(_rules, 'قوانین قرعه‌کشی', Icons.gavel, maxLines: 3), _buildStyledField(_cInsta, 'طبقه ۱', Icons.label), _buildStyledField(_cTele, 'طبقه ۲', Icons.label), _buildStyledField(_cOther, 'طبقه ۳', Icons.label), _buildStyledField(_pay, 'لینک پرداخت', Icons.link), _buildStyledField(_fee, 'ورودی', Icons.payments), _buildStyledField(_title, 'عنوان', Icons.title), _buildStyledField(_prize, 'جایزه', Icons.card_giftcard), _buildStyledField(_date, 'تاریخ', Icons.event) ]));
  Widget _adminCardSection(String t, Color c, bool e, VoidCallback? cl, List<Widget> ch, {Widget? footer}) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Column(children: [ Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c)), if (cl != null) IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: cl)])), if (e) const Padding(padding: EdgeInsets.all(20), child: Text('خالی')), ...ch, if (footer != null) Padding(padding: const EdgeInsets.all(10), child: footer) ]));
  Widget _buildCategoryMgmt(String t, List<Product> l, String k) => _adminCardSection(t, Colors.orange, l.isEmpty, null, l.asMap().entries.map((e) => ListTile(title: Text(e.value.title), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => l.removeAt(e.key))))).toList(), footer: ElevatedButton(onPressed: () => _addProduct(l, k), child: const Text('افزودن محصول')));
  Widget _buildStyledField(TextEditingController c, String l, IconData i, {int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, maxLines: maxLines, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))));
  void _addWinner() { TextEditingController n = TextEditingController(), c = TextEditingController(), p = TextEditingController(), d = TextEditingController(); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('افزودن برنده'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: c, decoration: const InputDecoration(labelText: 'شهر')), TextField(controller: p, decoration: const InputDecoration(labelText: 'جایزه')), TextField(controller: d, decoration: const InputDecoration(labelText: 'تاریخ'))]), actions: [ElevatedButton(onPressed: () { setState(() => _tempWinners.add(Winner(name: n.text, city: c.text, prize: p.text, date: d.text))); Navigator.pop(ctx); }, child: const Text('افزودن'))])); }
  void _addPrize() { TextEditingController t = TextEditingController(), a = TextEditingController(); showDialog(context: context, builder: (c) => AlertDialog(title: const Text('افزودن جایزه'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: a, decoration: const InputDecoration(labelText: 'مبلغ'))]), actions: [ElevatedButton(onPressed: () { setState(() => _tempPrizes.add(PrizeRecord(title: t.text, amount: a.text, iconCode: Icons.card_giftcard.codePoint, colorValue: Colors.orange.value))); Navigator.pop(c); }, child: const Text('افزودن'))])); }
  void _addProduct(List<Product> l, String k) { TextEditingController t = TextEditingController(), p = TextEditingController(), q = TextEditingController(); showDialog(context: context, builder: (c) => AlertDialog(title: const Text('افزودن محصول'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: p, decoration: const InputDecoration(labelText: 'قیمت')), TextField(controller: q, decoration: const InputDecoration(labelText: 'کیفیت'))]), actions: [ElevatedButton(onPressed: () { setState(() => l.add(Product(title: t.text, price: '${t.text} تومان', quality: q.text, imageUrl: k=='insta'?'https://cdn-icons-png.flaticon.com/512/174/174855.png':(k=='tele'?'https://cdn-icons-png.flaticon.com/512/2111/2111646.png':'https://cdn-icons-png.flaticon.com/512/174/174883.png'), category: k, priceInt: int.tryParse(p.text) ?? 0))); Navigator.pop(c); }, child: const Text('افزودن'))])); }
}
