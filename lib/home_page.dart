import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'register_page.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';

class AppUserRecord {
  final String name, phone, username, lastLogin; bool isBanned;
  AppUserRecord({required this.name, required this.phone, required this.username, required this.lastLogin, this.isBanned = false});
  factory AppUserRecord.fromJson(Map<String, dynamic> json) => AppUserRecord(name: json['name'] ?? '', phone: json['phone'] ?? '', username: json['username'] ?? 'User', lastLogin: json['last_login'] ?? '', isBanned: json['is_banned'] ?? false);
}

class Product {
  dynamic id; String title, price, quality, imageUrl, category, sku; int priceInt;
  Product({this.id, required this.title, required this.price, required this.quality, required this.imageUrl, required this.category, this.sku = '', this.priceInt = 0});
  factory Product.fromJson(Map<String, dynamic> json) {
    String pStr = (json['price'] ?? '0').toString().replaceAll(',', '').replaceAll(' تومان', '').split(' /')[0];
    return Product(id: json['id'], title: json['title'] ?? '', price: json['price'] ?? '', quality: json['quality'] ?? '', imageUrl: json['image_url'] ?? '', category: json['category'] ?? 'other', sku: json['sku'] ?? '', priceInt: int.tryParse(pStr) ?? 0);
  }
  Map<String, dynamic> toJson() => {'title': title, 'price': price, 'quality': quality, 'image_url': imageUrl, 'category': category, 'sku': sku};
}

class OrderRecord {
  dynamic id; final String userName, userPhone, username, productTitle, trackingCode, pageId, requestDetails; String status; final String date;
  OrderRecord({this.id, required this.userName, required this.userPhone, required this.username, required this.productTitle, required this.trackingCode, required this.pageId, required this.requestDetails, required this.status, required this.date});
  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(id: json['id'], userName: json['user_name'] ?? '', userPhone: json['user_phone'] ?? '', username: json['username'] ?? '', productTitle: json['product_title'] ?? '', trackingCode: json['tracking_code'] ?? '', pageId: json['page_id'] ?? '', requestDetails: json['request_details'] ?? '', status: json['status'] ?? "در انتظار", date: json['date'] ?? '');
}

class AppNews {
  dynamic id; String title, content, date;
  AppNews({this.id, required this.title, required this.content, required this.date});
  Map<String, dynamic> toJson() => {'title': title, 'content': content, 'date': date};
  factory AppNews.fromJson(Map<String, dynamic> json) => AppNews(id: json['id'], title: json['title'] ?? '', content: json['content'] ?? '', date: json['date'] ?? '');
}

class Winner {
  dynamic id; String name, city, prize, date, lotteryCode, phone;
  Winner({this.id, required this.name, required this.city, required this.prize, required this.date, this.lotteryCode = '', this.phone = ''});
  Map<String, dynamic> toJson() => {'name': name, 'city': city, 'prize': prize, 'date': date, 'lottery_code': lotteryCode, 'phone': phone};
  factory Winner.fromJson(Map<String, dynamic> json) => Winner(id: json['id'], name: json['name'] ?? '', city: json['city'] ?? '', prize: json['prize'] ?? '', date: json['date'] ?? '', lotteryCode: json['lottery_code'] ?? '', phone: json['phone'] ?? '');
}

class Participant {
  dynamic id; String name, phone, username, lotteryCode, date;
  Participant({this.id, required this.name, required this.phone, required this.username, required this.lotteryCode, required this.date});
  factory Participant.fromJson(Map<String, dynamic> json) => Participant(id: json['id'], name: json['name'] ?? '', phone: json['phone'] ?? '', username: json['username'] ?? '', lotteryCode: json['lottery_code'] ?? '', date: json['date'] ?? '');
}

String formatPrice(dynamic amount) {
  int val = 0;
  if (amount is int) val = amount;
  else if (amount is String) val = int.tryParse(amount.replaceAll(',', '').replaceAll(' تومان', '')) ?? 0;
  
  String price = val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return price.split('').map((char) {
    int? d = int.tryParse(char);
    return d != null ? persianDigits[d] : char;
  }).join('');
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
  int _adminClickCount = 0;
  
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  String _username = "", _instaID = "pico", _telegramID = "@pico", _supportEmail = "pico@support", _paymentLink = "https://zarrinpal.com", _lotteryEntryFee = "۱۰,۰۰۰", _lotteryRules = "قوانین برنامه", _supTele = "@pico_support", _supWhatsApp = "09000000000";
  String _catInstaName = "اینستاگرام", _catTeleName = "تلگرام", _catOtherName = "سایر";
  List<Product> _instaProducts = [], _telegramProducts = [], _otherProducts = [];
  List<Winner> _lotteryWinners = []; List<PrizeRecord> _prizes = []; List<OrderRecord> _allOrders = []; List<AppUserRecord> _appUsers = []; List<AppNews> _allNews = [];
  List<Participant> _allParticipants = [];
  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ هفتگی', _lotteryBannerPrize = 'جایزه ۵ میلیونی', _lotteryBannerDate = 'جمعه ساعت ۲۱';
  int _lotteryMaxCapacity = 500, _lotteryManualOffset = 0;
  bool _isStoreEnabled = true, _isLotteryEnabled = true, _isOrdersEnabled = true, _isNewsEnabled = true, _isSupportEnabled = true;
  bool _isLoading = true; String _searchProductQuery = "";
  
  String? _tempPageId, _tempDetails, _tempName, _tempPhone, _tempTitle;
  int? _tempAmount;

  @override
  void initState() { 
    super.initState(); 
    _fetchSupabaseData(); 
    _startSecurityMonitor();
    
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint('IAP Subscription Error: $error');
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

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
        if (k == 'lottery_max_capacity') _lotteryMaxCapacity = int.tryParse(v) ?? 500;
        if (k == 'lottery_manual_offset') _lotteryManualOffset = int.tryParse(v) ?? 0;
        if (k == 'is_store_enabled') _isStoreEnabled = v == 'true';
        if (k == 'is_lottery_enabled') _isLotteryEnabled = v == 'true';
        if (k == 'is_orders_enabled') _isOrdersEnabled = v == 'true';
        if (k == 'is_news_enabled') _isNewsEnabled = v == 'true';
        if (k == 'is_support_enabled') _isSupportEnabled = v == 'true';
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
      _allParticipants = (await _supabase.from('participants').select().order('created_at', ascending: false)).map((e) => Participant.fromJson(e)).toList();
      _allNews = (await _supabase.from('news').select().order('created_at', ascending: false)).map((e) => AppNews.fromJson(e)).toList();
    } catch (e) { debugPrint('Supabase Error: $e'); }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    
    List<Widget> activeWidgets = [];
    List<BottomNavigationBarItem> navItems = [];
    List<String> titles = [];

    if (_isStoreEnabled) {
      activeWidgets.add(_buildStoreContent());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'فروشگاه'));
      titles.add('فروشگاه پیکو');
    }
    if (_isLotteryEnabled) {
      activeWidgets.add(_buildLotteryAndPrizes());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'قرعه‌کشی'));
      titles.add('جوایز و قرعه‌کشی');
    }
    if (_isOrdersEnabled) {
      activeWidgets.add(_buildOrdersContent());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'سفارشات'));
      titles.add('سفارشات');
    }
    
    activeWidgets.add(_buildProfileContent());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل'));
    titles.add('پروفایل');

    if (_selectedIndex >= activeWidgets.length) _selectedIndex = 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange, centerTitle: true, actions: [IconButton(onPressed: _fetchSupabaseData, icon: const Icon(Icons.refresh))]),
      body: activeWidgets[_selectedIndex],
      floatingActionButton: _isSupportEnabled ? FloatingActionButton(onPressed: _showSupportDialog, backgroundColor: Colors.orange, child: const Icon(Icons.headset_mic)) : null,
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, selectedItemColor: Colors.orange, unselectedItemColor: Colors.grey, currentIndex: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i), items: navItems),
    );
  }

  Widget _buildStoreContent() => SingleChildScrollView(child: Column(children: [
    if (_isNewsEnabled && _allNews.isNotEmpty) _buildNewsTicker(),
    Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText: 'جستجوی محصول...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.white), onChanged: (v) => setState(() => _searchProductQuery = v))),
    _buildCategorySection(_catInstaName, _instaProducts.where((p) => p.title.contains(_searchProductQuery)).toList(), Colors.blue), 
    _buildCategorySection(_catTeleName, _telegramProducts.where((p) => p.title.contains(_searchProductQuery)).toList(), Colors.teal), 
    _buildCategorySection(_catOtherName, _otherProducts.where((p) => p.title.contains(_searchProductQuery)).toList(), Colors.deepPurple), 
    const SizedBox(height: 20)
  ]));

  Widget _buildNewsTicker() => Container(height: 60, margin: const EdgeInsets.symmetric(vertical: 10), child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _allNews.length, itemBuilder: (c, i) => InkWell(onTap: () => _showNewsDetail(_allNews[i]), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), margin: const EdgeInsets.only(right: 15), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.blue.withOpacity(0.3))), child: Row(children: [const Icon(Icons.campaign, color: Colors.blue, size: 20), const SizedBox(width: 10), Text(_allNews[i].title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))])))));
  void _showNewsDetail(AppNews n) => showDialog(context: context, builder: (c) => AlertDialog(title: Text(n.title), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(n.date, style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 10), Text(n.content)])), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]));

  Widget _buildCategorySection(String t, List<Product> p, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 5, height: 25, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 10), Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])), SizedBox(height: 250, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: p.length, itemBuilder: (cxt, i) => _buildProductCard(p[i], c)))]);
  Widget _buildProductCard(Product p, Color c) => Container(width: 165, margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.1), width: 2), boxShadow: [BoxShadow(color: c.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(children: [const SizedBox(height: 15), p.imageUrl.isNotEmpty ? Image.network(p.imageUrl, height: 75, fit: BoxFit.contain, errorBuilder: (_,e,s) => Icon(Icons.image, size: 60, color: c)) : Icon(Icons.image, size: 60, color: c), const SizedBox(height: 10), Text(p.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1), const Spacer(), Text('${formatPrice(p.priceInt)} تومان', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)), Container(width: double.infinity, margin: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () => _handleDirectPayment(p.priceInt, p.title, "خرید محصول"), style: ElevatedButton.styleFrom(backgroundColor: c, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('پرداخت و خرید')))]));

  Future<void> _handleDirectPayment(int amount, String title, String type) async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      _showError('سرویس پرداخت بازار در دسترس نیست. لطفا از نصب بودن کافه بازار اطمینان حاصل کنید.');
      return;
    }

    if (type == "خرید محصول") {
      TextEditingController pageIdController = TextEditingController();
      TextEditingController detailsController = TextEditingController();
      TextEditingController nameController = TextEditingController(text: widget.userName);
      TextEditingController phoneController = TextEditingController(text: widget.userPhone);

      bool? formFilled = await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('مشخصات سفارش', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'شماره تماس', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                TextField(controller: pageIdController, decoration: const InputDecoration(labelText: 'آیدی پیج یا لینک (اجباری)', border: OutlineInputBorder(), hintText: '@example')),
                const SizedBox(height: 10),
                TextField(controller: detailsController, decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)', border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (pageIdController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا آیدی پیج را وارد کنید')));
                  return;
                }
                Navigator.pop(c, true);
              },
              child: const Text('مرحله بعد'),
            )
          ],
        ),
      );
      if (formFilled != true) return;

      _tempName = nameController.text.trim();
      _tempPhone = phoneController.text.trim();
      _tempPageId = pageIdController.text.trim();
      _tempDetails = detailsController.text.trim();
      _tempTitle = title;
      _tempAmount = amount;

      String sku = type == "خرید محصول" ? (instaProducts_flat().firstWhere((pr) => pr.title == title)).sku : "lottery_entry";
      
      if (sku.isEmpty) {
        _showError('شناسه محصول (SKU) در پنل مدیریت تنظیم نشده است.');
        return;
      }
      
      final ProductDetailsResponse response = await _iap.queryProductDetails({sku});
      if (response.notFoundIDs.isNotEmpty) {
        _showError('شناسه کالا در بازار یافت نشد (SKU: $sku)');
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
      _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      String sku = "lottery_entry";
      final ProductDetailsResponse response = await _iap.queryProductDetails({sku});
      if (response.notFoundIDs.isNotEmpty) {
        _showError('شناسه قرعه‌کشی در بازار یافت نشد (SKU: $sku)');
        return;
      }
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
      _iap.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  List<Product> instaProducts_flat() => [..._instaProducts, ..._telegramProducts, ..._otherProducts];

  IconData _getPrizeIcon(int code) {
    if (code == Icons.looks_one.codePoint) return Icons.looks_one;
    if (code == Icons.looks_two.codePoint) return Icons.looks_two;
    if (code == Icons.looks_3.codePoint) return Icons.looks_3;
    if (code == Icons.stars.codePoint) return Icons.stars;
    return Icons.card_giftcard;
  }

  Widget _buildLotteryAndPrizes() {
    int displayCount = _allParticipants.length + _lotteryManualOffset;
    double progress = (displayCount / _lotteryMaxCapacity).clamp(0.0, 1.0);

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(25), width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8E24AA), Color(0xFFD81B60), Color(0xFFFFB300)]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10))]), child: Column(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 50)),
        const SizedBox(height: 15),
        Text(_lotteryBannerTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black26, blurRadius: 10)])), 
        Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.white70, fontSize: 16)), 
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => _handleDirectPayment(int.tryParse(_lotteryEntryFee.replaceAll(',', '')) ?? 10000, "ورودی قرعه‌کشی", "ثبت‌نام قرعه‌کشی"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple, elevation: 10, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('همین حالا شرکت کن!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))
      ])),
      const SizedBox(height: 25),
      Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 5, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('وضعیت ظرفیت ثبت‌نام', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('$displayCount / $_lotteryMaxCapacity نفر', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 15),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.red : Colors.orange))),
        const SizedBox(height: 10),
        Text(progress >= 1.0 ? '⚠️ ظرفیت تکمیل شد!' : 'شما هم می‌توانید یکی از برندگان باشید', style: TextStyle(fontSize: 12, color: progress >= 1.0 ? Colors.red : Colors.grey)),
      ]))),
      const SizedBox(height: 25),
      const Row(children: [Icon(Icons.stars, color: Colors.amber), SizedBox(width: 10), Text('🎁 جوایز طلایی این دوره', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
    const SizedBox(height: 15),
    SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _prizes.length, itemBuilder: (c, i) => Container(width: 140, margin: const EdgeInsets.only(right: 15), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.amber.shade400, Colors.amber.shade700]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white30, shape: BoxShape.circle), child: Icon(_getPrizeIcon(_prizes[i].iconCode), size: 40, color: Colors.white)),
      const SizedBox(height: 15),
      Text(_prizes[i].title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15), textAlign: TextAlign.center),
      Text(_prizes[i].amount, style: const TextStyle(fontSize: 13, color: Colors.white70))
    ])))),
    const SizedBox(height: 30),
    const Row(children: [Icon(Icons.emoji_events, color: Colors.orange), SizedBox(width: 10), Text('🏆 تالار مشاهیر برندگان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
    const SizedBox(height: 15),
    ...List.generate(_lotteryWinners.length, (i) {
      final w = _lotteryWinners[i];
      Color medalColor = i == 0 ? Colors.amber : (i == 1 ? Colors.grey.shade400 : (i == 2 ? Colors.orange.shade300 : Colors.blue.shade100));
      String maskedPhone = w.phone.length > 7 ? '${w.phone.substring(0, 4)}***${w.phone.substring(w.phone.length - 2)}' : w.phone;
      
      return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]), child: Column(
        children: [
          ListTile(
            leading: Container(width: 45, height: 45, decoration: BoxDecoration(color: medalColor.withOpacity(0.2), shape: BoxShape.circle), child: Icon(i < 3 ? Icons.emoji_events : Icons.person, color: medalColor)), 
            title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
            subtitle: Text('از ${w.city} | جایزه: ${w.prize}'), 
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (i < 3) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: medalColor, borderRadius: BorderRadius.circular(10)), child: Text(['اول', 'دوم', 'سوم'][i], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(height: 5),
              Text(w.date, style: const TextStyle(fontSize: 10, color: Colors.grey))
            ])
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.confirmation_number, size: 14, color: Colors.blue),
                  const SizedBox(width: 5),
                  Text('کد: ${w.lotteryCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                ]),
                Row(children: [
                  const Icon(Icons.phone_android, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(maskedPhone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ],
            ),
          )
        ],
      ));
    }),
    const SizedBox(height: 50)
  ]));

  Widget _buildOrdersContent() => _allOrders.where((o) => o.userPhone == widget.userPhone).isEmpty ? const Center(child: Text('سفارشی ثبت نشده است')) : ListView.builder(itemCount: _allOrders.length, itemBuilder: (c, i) => _allOrders[i].userPhone == widget.userPhone ? Card(margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: const Icon(Icons.shopping_bag, color: Colors.orange), title: Text(_allOrders[i].productTitle), subtitle: Text('کد پیگیری: ${_allOrders[i].trackingCode}\nآیدی: ${_allOrders[i].pageId}'), isThreeLine: true, trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _allOrders[i].status == "انجام شده" ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(_allOrders[i].status, style: TextStyle(color: _allOrders[i].status == "انجام شده" ? Colors.green : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))))) : const SizedBox.shrink());

  Widget _buildProfileContent() {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      Container(
        padding: const EdgeInsets.all(30), width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)]),
        child: Column(children: [
          GestureDetector(
            onTap: _handleAdminAccess,
            child: const CircleAvatar(radius: 45, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Colors.black)),
          ),
          const SizedBox(height: 15), Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Text('نام کاربری: $_username', style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
      ),
      const SizedBox(height: 30),
      _buildProfileMenu(Icons.info_outline, 'درباره پیکو مارکت', () {}, Colors.black),
      _buildProfileMenu(Icons.share, 'معرفی به دوستان', () {}, Colors.black),
      _buildProfileMenu(Icons.star_outline, 'امتیاز به برنامه', () {}, Colors.black),
      const SizedBox(height: 30),
      ElevatedButton.icon(onPressed: () async { (await SharedPreferences.getInstance()).clear(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RegisterPage()), (r) => false); }, icon: const Icon(Icons.logout), label: const Text('خروج از حساب کاربری'), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 5, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
    ]));
  }
  Widget _buildProfileMenu(IconData i, String t, VoidCallback onTap, Color c) => Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 2, child: ListTile(leading: Icon(i, color: c), title: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w500)), trailing: Icon(Icons.chevron_right, size: 18, color: c), onTap: onTap));

  void _showSupportDialog() { showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (c) => Container(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('📞 مرکز پشتیبانی پیکو', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 25), _buildSupTile(Icons.telegram, 'پشتیبانی تلگرام', _supTele, Colors.blue), _buildSupTile(Icons.message, 'پشتیبانی واتس‌اپ', _supWhatsApp, Colors.green), const SizedBox(height: 10), const Text('ساعت پاسخگویی: ۹ صبح الی ۲۳ شب', style: TextStyle(color: Colors.grey, fontSize: 12))]))); }
  Widget _buildSupTile(IconData i, String t, String v, Color c) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(i, color: c), title: Text(t), subtitle: Text(v), trailing: const Icon(Icons.open_in_new, size: 18), onTap: () => launchUrl(Uri.parse(t.contains('تلگرام') ? "https://t.me/${v.replaceAll('@', '')}" : "https://wa.me/$v"))));

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showLoading('در حال برقراری ارتباط با بازار...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          Navigator.pop(context);
          _showError('خطا در پرداخت: ${purchaseDetails.error?.message}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _deliverProduct(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    return true;
  }

  void _deliverProduct(PurchaseDetails purchase) async {
    Navigator.pop(context); 
    String track = "BAZ-${Random().nextInt(90000) + 10000}";
    
    if (_tempTitle != null) {
      await _supabase.from('orders').insert({
        'user_name': _tempName, 
        'user_phone': _tempPhone, 
        'username': _username, 
        'product_title': _tempTitle, 
        'tracking_code': track, 
        'page_id': _tempPageId,
        'request_details': _tempDetails,
        'status': 'در حال انجام', 
        'quantity': '1',
        'date': DateTime.now().toString().split('.')[0]
      });
      _fetchSupabaseData();
      _showSuccess('پرداخت بازار تایید شد! سفارش شما با موفقیت ثبت گردید.\nکد پیگیری: $track');
    } else {
      String pikoCode = "PIKO-${Random().nextInt(900000) + 100000}";
      await _supabase.from('participants').insert({
        'name': widget.userName, 
        'phone': widget.userPhone, 
        'username': _username, 
        'lottery_code': pikoCode, 
        'date': DateTime.now().toString().split('.')[0], 
        'telegram': _username
      });
      _fetchSupabaseData();
      _showSuccess('پرداخت بازار تایید شد! ثبت‌نام شما در قرعه‌کشی انجام شد.\nکد شما: $pikoCode');
    }
  }

  void _showError(String m) => showDialog(context: context, builder: (c) => AlertDialog(title: const Icon(Icons.error, color: Colors.red, size: 50), content: Text(m, textAlign: TextAlign.center), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('باشه'))]));
  void _showSuccess(String m) => showDialog(context: context, builder: (c) => AlertDialog(title: const Icon(Icons.check_circle, color: Colors.green, size: 50), content: Text(m, textAlign: TextAlign.center), actions: [Center(child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('فهمیدم')))]));
  void _showLoading(String m) => showDialog(context: context, builder: (c) => AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Colors.orange), const SizedBox(height: 15), Text(m)])));

  void _handleAdminAccess() {
    _adminClickCount++;
    if (_adminClickCount >= 5) {
      _adminClickCount = 0;
      TextEditingController pass = TextEditingController();
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('ورود به مدیریت', textAlign: TextAlign.center),
          content: TextField(controller: pass, decoration: const InputDecoration(labelText: 'رمز عبور را وارد کنید'), obscureText: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (pass.text == "amin1391soltani") {
                  Navigator.pop(c);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPanel(instaProducts: _instaProducts, telegramProducts: _telegramProducts, otherProducts: _otherProducts, lotteryWinners: _lotteryWinners, prizes: _prizes, allOrders: _allOrders, appUsers: _appUsers, allParticipants: _allParticipants, bannerTitle: _lotteryBannerTitle, bannerPrize: _lotteryBannerPrize, bannerDate: _lotteryBannerDate, insta: _instaID, tele: _telegramID, mail: _supportEmail, paymentLink: _paymentLink, lotteryFee: _lotteryEntryFee, lotteryRules: _lotteryRules, supTele: _supTele, supWA: _supWhatsApp, catInsta: _catInstaName, catTele: _catTeleName, catOther: _catOtherName, lotteryMax: _lotteryMaxCapacity, lotteryOffset: _lotteryManualOffset, storeEn: _isStoreEnabled, lotteryEn: _isLotteryEnabled, ordersEn: _isOrdersEnabled, newsEn: _isNewsEnabled, supportEn: _isSupportEnabled, onUpdate: () => _fetchSupabaseData())));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز اشتباه است')));
                }
              },
              child: const Text('ورود'),
            )
          ],
        ),
      );
    }
  }
}

class AdminPanel extends StatefulWidget {
  final List<Product> instaProducts, telegramProducts, otherProducts; final List<Winner> lotteryWinners; final List<PrizeRecord> prizes; final List<OrderRecord> allOrders; final List<AppUserRecord> appUsers; final List<Participant> allParticipants; final String bannerTitle, bannerPrize, bannerDate, insta, tele, mail, paymentLink, lotteryFee, lotteryRules, supTele, supWA, catInsta, catTele, catOther;
  final int lotteryMax, lotteryOffset;
  final bool storeEn, lotteryEn, ordersEn, newsEn, supportEn;
  final VoidCallback onUpdate;
  const AdminPanel({super.key, required this.instaProducts, required this.telegramProducts, required this.otherProducts, required this.lotteryWinners, required this.prizes, required this.allOrders, required this.appUsers, required this.allParticipants, required this.bannerTitle, required this.bannerPrize, required this.bannerDate, required this.insta, required this.tele, required this.mail, required this.paymentLink, required this.lotteryFee, required this.lotteryRules, required this.supTele, required this.supWA, required this.catInsta, required this.catTele, required this.catOther, required this.lotteryMax, required this.lotteryOffset, required this.storeEn, required this.lotteryEn, required this.ordersEn, required this.newsEn, required this.supportEn, required this.onUpdate});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late List<Product> _tempInsta, _tempTele, _tempOther; late List<Winner> _tempWinners; late List<PrizeRecord> _tempPrizes; late List<OrderRecord> _tempOrders;
  late TextEditingController _title, _prize, _date, _inst, _tel, _mail, _pay, _fee, _rules, _sTel, _sWA, _cInsta, _cTele, _cOther, _lMax, _lOffset;
  late bool _stEn, _ltEn, _orEn, _nwEn, _suEn;
  String _searchQuery = ""; final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tempInsta = List.from(widget.instaProducts); _tempTele = List.from(widget.telegramProducts); _tempOther = List.from(widget.otherProducts); _tempWinners = List.from(widget.lotteryWinners); _tempPrizes = List.from(widget.prizes); _tempOrders = List.from(widget.allOrders);
    _title = TextEditingController(text: widget.bannerTitle); _prize = TextEditingController(text: widget.bannerPrize); _date = TextEditingController(text: widget.bannerDate); _inst = TextEditingController(text: widget.insta); _tel = TextEditingController(text: widget.tele); _mail = TextEditingController(text: widget.mail); _pay = TextEditingController(text: widget.paymentLink); _fee = TextEditingController(text: widget.lotteryFee); _rules = TextEditingController(text: widget.lotteryRules); _sTel = TextEditingController(text: widget.supTele); _sWA = TextEditingController(text: widget.supWA); _cInsta = TextEditingController(text: widget.catInsta); _cTele = TextEditingController(text: widget.catTele); _cOther = TextEditingController(text: widget.catOther);
    _lMax = TextEditingController(text: widget.lotteryMax.toString());
    _lOffset = TextEditingController(text: widget.lotteryOffset.toString());
    _stEn = widget.storeEn; _ltEn = widget.lotteryEn; _orEn = widget.ordersEn; _nwEn = widget.newsEn; _suEn = widget.supportEn;
  }

  Future<void> _updateConfig(String k, String v) async {
    try {
      await _supabase.from('app_config').upsert({'key': k, 'value': v}, onConflict: 'key');
      widget.onUpdate();
    } catch (e) {
      debugPrint('Update Config Error ($k): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalRevenue = widget.allOrders.where((o) => o.status == "انجام شده").fold(0, (sum, item) {
      String p = item.productTitle;
      int price = 0;
      var product = [...widget.instaProducts, ...widget.telegramProducts, ...widget.otherProducts].where((pr) => pr.title == p).firstOrNull;
      price = product?.priceInt ?? 0;
      return sum + price;
    });

    return DefaultTabController(length: 9, child: Scaffold(backgroundColor: Colors.grey[100], appBar: AppBar(title: const Text('مدیریت زنده'), backgroundColor: Colors.orange, bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'داشبورد'), Tab(text: 'دسترسی بخش‌ها'), Tab(text: 'پرداختی‌های موفق'), Tab(text: 'سفارشات'), Tab(text: 'کاربران'), Tab(text: 'محصولات'), Tab(text: 'جوایز'), Tab(text: 'تنظیمات'), Tab(text: 'برندگان')])), body: Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: TextField(decoration: const InputDecoration(labelText: 'جستجو...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => _searchQuery = v))),
      Expanded(child: TabBarView(children: [_buildDashboard(totalRevenue), _buildAccessMgmtTab(), _buildSuccessfulPaymentsTab(), _buildOrdersTab(), _buildUsersTab(), _buildProductsTab(), _buildLotteryMgmtTab(), _buildSettingsTab(), _buildWinnersTab()])),
    ])));
  }

  Widget _buildAccessMgmtTab() {
    return ListView(padding: const EdgeInsets.all(15), children: [
      _header('🔧 فعال/غیرفعال‌سازی بخش‌ها (ذخیره آنی)', Colors.blueGrey),
      _accessTile('بخش فروشگاه', _stEn, (v) { setState(() => _stEn = v); _updateConfig('is_store_enabled', v.toString()); }),
      _accessTile('بخش قرعه‌کشی و جوایز', _ltEn, (v) { setState(() => _ltEn = v); _updateConfig('is_lottery_enabled', v.toString()); }),
      _accessTile('بخش سفارشات کاربر', _orEn, (v) { setState(() => _orEn = v); _updateConfig('is_orders_enabled', v.toString()); }),
      _accessTile('نوار اخبار در فروشگاه', _nwEn, (v) { setState(() => _nwEn = v); _updateConfig('is_news_enabled', v.toString()); }),
      _accessTile('دکمه شناور پشتیبانی', _suEn, (v) { setState(() => _suEn = v); _updateConfig('is_support_enabled', v.toString()); }),
      const Padding(
        padding: EdgeInsets.all(15),
        child: Text('با غیرفعال کردن هر بخش، آن گزینه از منوی کاربران حذف خواهد شد.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      )
    ]);
  }
  Widget _accessTile(String t, bool val, Function(bool) onC) => Card(child: SwitchListTile(title: Text(t), value: val, onChanged: onC, activeColor: Colors.orange));

  Widget _buildSuccessfulPaymentsTab() {
    List<dynamic> combined = [];
    combined.addAll(widget.allOrders.where((o) => o.trackingCode.startsWith('BAZ-') || o.status == "انجام شده"));
    combined.addAll(widget.allParticipants);
    combined.sort((a, b) => b.date.compareTo(a.date));

    var filtered = combined.where((item) {
      String search = _searchQuery.toLowerCase();
      if (item is OrderRecord) return item.userName.toLowerCase().contains(search) || item.productTitle.toLowerCase().contains(search);
      if (item is Participant) return item.name.toLowerCase().contains(search) || item.lotteryCode.toLowerCase().contains(search);
      return false;
    }).toList();

    return ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) {
      var item = filtered[i];
      if (item is OrderRecord) {
        return Card(child: ListTile(
          leading: const Icon(Icons.shopping_bag, color: Colors.green),
          title: Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('خرید از: ${item.userName} | کد: ${item.trackingCode}\nزمان: ${item.date}'),
          trailing: const Text('پرداخت بازار', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ));
      } else {
        return Card(child: ListTile(
          leading: const Icon(Icons.confirmation_number, color: Colors.orange),
          title: const Text('ورودی قرعه‌کشی', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('شرکت‌کننده: ${item.name} | کد: ${item.lotteryCode}\nزمان: ${item.date}'),
          trailing: const Text('پرداخت بازار', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
        ));
      }
    });
  }

  Widget _buildDashboard(int revenue) {
    return SingleChildScrollView(padding: const EdgeInsets.all(15), child: Column(children: [
      Row(children: [
        _statCard('کل کاربران', widget.appUsers.length.toString(), Icons.people, Colors.blue),
        _statCard('سفارشات جدید', _tempOrders.where((o) => o.status != "انجام شده").length.toString(), Icons.shopping_cart, Colors.orange),
      ]),
      Row(children: [
        _statCard('درآمد تخمینی', '${formatPrice(revenue)} تومان', Icons.account_balance_wallet, Colors.green),
        _statCard('برندگان', widget.lotteryWinners.length.toString(), Icons.emoji_events, Colors.purple),
      ]),
      const SizedBox(height: 20),
      const Card(child: ListTile(title: Text('وضعیت سیستم', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('تمامی سرویس‌ها فعال و در دسترس هستند.'), leading: Icon(Icons.check_circle, color: Colors.green))),
    ]));
  }
  Widget _statCard(String t, String v, IconData i, Color c) => Expanded(child: Card(child: Container(padding: const EdgeInsets.all(20), child: Column(children: [Icon(i, color: c, size: 30), const SizedBox(height: 10), Text(t, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c))]))));

  Widget _buildUsersTab() {
    var filtered = widget.appUsers.where((u) => u.username.contains(_searchQuery) || u.name.contains(_searchQuery)).toList();
    return ListView.builder(itemCount: filtered.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(filtered[i].name), subtitle: Text(filtered[i].username), trailing: IconButton(icon: Icon(Icons.block, color: filtered[i].isBanned ? Colors.grey : Colors.red), onPressed: () async { await _supabase.from('app_users').update({'is_banned': true}).eq('phone', filtered[i].phone); }))));
  }
  Widget _buildOrdersTab() {
    var filtered = _tempOrders.where((o) => o.username.contains(_searchQuery) || o.userName.contains(_searchQuery)).toList();
    var active = filtered.where((o) => o.status != "انجام شده").toList();
    var completed = filtered.where((o) => o.status == "انجام شده").toList();
    return ListView(children: [
      _header('📦 سفارشات جدید (${active.length})', Colors.blue),
      ...active.map((o) => Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: ListTile(
        title: Text(o.productTitle, style: const TextStyle(fontWeight: FontWeight.bold)), 
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 5),
          Row(children: [const Icon(Icons.person, size: 14, color: Colors.grey), const SizedBox(width: 5), Text('${o.userName} (${o.userPhone})')]),
          Row(children: [const Icon(Icons.link, size: 14, color: Colors.blue), const SizedBox(width: 5), Text('آیدی: ${o.pageId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),
          if (o.requestDetails.isNotEmpty) Row(children: [const Icon(Icons.notes, size: 14, color: Colors.grey), const SizedBox(width: 5), Expanded(child: Text('توضیحات: ${o.requestDetails}', maxLines: 2, overflow: TextOverflow.ellipsis))]),
          Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 5), Text('زمان ثبت: ${o.date}')]),
        ]), 
        trailing: ElevatedButton(onPressed: () async {
          await _supabase.from('orders').update({'status': 'انجام شده'}).eq('id', o.id);
          setState(() => o.status = "انجام شده");
          widget.onUpdate();
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('تکمیل'))
      ))),
      _header('✅ تکمیل شده (${completed.length})', Colors.green),
      ...completed.map((o) => Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: Colors.green.withOpacity(0.05), child: ListTile(
        title: Text(o.productTitle), 
        subtitle: Text('کاربر: ${o.userName} | تاریخ: ${o.date}'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      )))
    ]);
  }
  Widget _header(String t, Color c) => Container(padding: const EdgeInsets.all(15), color: c.withOpacity(0.1), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c)));

  Widget _buildProductsTab() => SingleChildScrollView(child: Column(children: [_buildCategoryMgmt(_cInsta.text, _tempInsta, 'insta'), _buildCategoryMgmt(_cTele.text, _tempTele, 'tele'), _buildCategoryMgmt(_cOther.text, _tempOther, 'other'), const SizedBox(height: 20)]));
  Widget _buildCategoryMgmt(String t, List<Product> l, String k) => Card(child: Column(children: [
    ListTile(title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold))), 
    ...l.map((e) => ListTile(
      leading: e.imageUrl.isNotEmpty ? Image.network(e.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,o,s) => const Icon(Icons.image)) : const Icon(Icons.image), 
      title: Text(e.title), 
      subtitle: Text('${formatPrice(e.priceInt)} تومان | SKU: ${e.sku}'), 
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editProduct(e, l)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
            await _supabase.from('products').delete().eq('id', e.id);
            setState(() => l.remove(e));
            widget.onUpdate();
          }),
        ],
      )
    )), 
    ElevatedButton.icon(onPressed: () => _addProduct(l, k), icon: const Icon(Icons.add), label: const Text('افزودن محصول'))
  ]));

  void _editProduct(Product p, List<Product> l) {
    TextEditingController t = TextEditingController(text: p.title), pr = TextEditingController(text: p.priceInt.toString()), s = TextEditingController(text: p.sku); 
    String? imgUrl = p.imageUrl;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(title: const Text('ویرایش محصول'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: t, decoration: const InputDecoration(labelText: 'نام محصول')),
      TextField(controller: pr, decoration: const InputDecoration(labelText: 'قیمت (عدد)')),
      TextField(controller: s, decoration: const InputDecoration(labelText: 'شناسه بازار (SKU)')),
      const SizedBox(height: 15),
      if (imgUrl != null && imgUrl!.isNotEmpty) Image.network(imgUrl!, height: 80, errorBuilder: (_,e,s) => const Icon(Icons.broken_image)) else const Icon(Icons.image, size: 50, color: Colors.grey),
      TextButton.icon(onPressed: () async {
        final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pick != null) {
          final bytes = await pick.readAsBytes();
          final path = 'products/${DateTime.now().millisecondsSinceEpoch}.png';
          await _supabase.storage.from('products').uploadBinary(path, bytes);
          setS(() => imgUrl = _supabase.storage.from('products').getPublicUrl(path));
        }
      }, icon: const Icon(Icons.upload), label: const Text('تغییر عکس'))
    ])), actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')), 
      ElevatedButton(onPressed: () async { 
        if (t.text.isEmpty) return; 
        final updatedProduct = {'title': t.text, 'price': '${pr.text} تومان', 'sku': s.text, 'image_url': imgUrl ?? '', 'category': p.category};
        await _supabase.from('products').update(updatedProduct).eq('id', p.id);
        setState(() {
          p.title = t.text;
          p.priceInt = int.tryParse(pr.text) ?? 0;
          p.price = '${pr.text} تومان';
          p.sku = s.text;
          p.imageUrl = imgUrl ?? '';
        }); 
        widget.onUpdate();
        Navigator.pop(c); 
      }, child: const Text('بروزرسانی'))
    ])));
  }

  void _addProduct(List<Product> l, String k) {
    TextEditingController t = TextEditingController(), p = TextEditingController(), s = TextEditingController(); String? imgUrl;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(title: const Text('محصول جدید'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: t, decoration: const InputDecoration(labelText: 'نام محصول')),
      TextField(controller: p, decoration: const InputDecoration(labelText: 'قیمت (عدد)')),
      TextField(controller: s, decoration: const InputDecoration(labelText: 'شناسه بازار (SKU)')),
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
    ]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')), ElevatedButton(onPressed: () async { 
      if (t.text.isEmpty) return; 
      final newProduct = {'title': t.text, 'price': '${p.text} تومان', 'quality': 'عالی', 'image_url': imgUrl ?? '', 'category': k, 'sku': s.text};
      final res = await _supabase.from('products').insert(newProduct).select().single();
      setState(() => l.add(Product.fromJson(res))); 
      widget.onUpdate();
      Navigator.pop(c); 
    }, child: const Text('افزودن'))])));
  }
  Widget _buildLotteryMgmtTab() => Column(children: [
    ElevatedButton(onPressed: _addPrize, child: const Text('افزودن جایزه جدید')), 
    Expanded(child: ListView.builder(itemCount: _tempPrizes.length, itemBuilder: (c, i) => Card(child: ListTile(
      title: Text(_tempPrizes[i].title), 
      subtitle: Text(_tempPrizes[i].amount), 
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () async {
        await _supabase.from('prizes').delete().eq('id', _tempPrizes[i].id);
        setState(() => _tempPrizes.removeAt(i));
        widget.onUpdate();
      })
    ))))
  ]);
  void _addPrize() { 
    TextEditingController t = TextEditingController(), a = TextEditingController(); 
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('جایزه'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: a, decoration: const InputDecoration(labelText: 'مبلغ/توضیح'))]), actions: [ElevatedButton(onPressed: () async { 
      final newPrize = {'title': t.text, 'amount': a.text, 'icon_code': Icons.stars.codePoint, 'color_value': Colors.orange.value};
      final res = await _supabase.from('prizes').insert(newPrize).select().single();
      setState(() => _tempPrizes.add(PrizeRecord.fromJson(res))); 
      widget.onUpdate();
      Navigator.pop(c); 
    }, child: const Text('ثبت'))])); 
  }
  Widget _buildWinnersTab() => Column(children: [
    ElevatedButton(onPressed: _addWinner, child: const Text('افزودن برنده')), 
    Expanded(child: ListView.builder(itemCount: _tempWinners.length, itemBuilder: (c, i) => Card(child: ListTile(
      title: Text(_tempWinners[i].name), 
      subtitle: Text('${_tempWinners[i].city} | کد: ${_tempWinners[i].lotteryCode}\nتلفن: ${_tempWinners[i].phone}'), 
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () async {
        await _supabase.from('winners').delete().eq('id', _tempWinners[i].id);
        setState(() => _tempWinners.removeAt(i));
        widget.onUpdate();
      })
    ))))
  ]);
  void _addWinner() { 
    TextEditingController n = TextEditingController(), ci = TextEditingController(), p = TextEditingController(), d = TextEditingController(), lc = TextEditingController(), ph = TextEditingController(); 
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('ثبت برنده جدید'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')), 
      TextField(controller: lc, decoration: const InputDecoration(labelText: 'کد قرعه‌کشی (PIKO-XXXXXX)')),
      TextField(controller: ci, decoration: const InputDecoration(labelText: 'شهر')), 
      TextField(controller: ph, decoration: const InputDecoration(labelText: 'شماره تماس'), keyboardType: TextInputType.phone),
      TextField(controller: p, decoration: const InputDecoration(labelText: 'جایزه')), 
      TextField(controller: d, decoration: const InputDecoration(labelText: 'تاریخ'))
    ])), actions: [ElevatedButton(onPressed: () async { 
      final newWinner = {'name': n.text, 'city': ci.text, 'prize': p.text, 'date': d.text, 'lottery_code': lc.text, 'phone': ph.text};
      final res = await _supabase.from('winners').insert(newWinner).select().single();
      setState(() => _tempWinners.add(Winner.fromJson(res))); 
      widget.onUpdate();
      Navigator.pop(c); 
    }, child: const Text('ثبت'))])); 
  }
  Widget _buildSettingsTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('📞 ارتباطات و پشتیبانی'),
      _buildStyledField(_sTel, 'آیدی تلگرام پشتیبانی', Icons.telegram, 'sup_tele'),
      _buildStyledField(_sWA, 'شماره واتس‌اپ پشتیبانی', Icons.message, 'sup_whatsapp'),
      _buildStyledField(_mail, 'ایمیل پشتیبانی', Icons.email, 'support_email'),
      
      _sectionHeader('💰 درگاه و پرداخت'),
      _buildStyledField(_pay, 'لینک درگاه زرین‌پال', Icons.link, 'payment_link'),
      _buildStyledField(_fee, 'هزینه ورودی قرعه‌کشی', Icons.payments, 'lottery_entry_fee'),
      
      _sectionHeader('🎟️ بنر قرعه‌کشی'),
      _buildStyledField(_title, 'عنوان بنر', Icons.title, 'lottery_banner_title'),
      _buildStyledField(_prize, 'جایزه بنر', Icons.card_giftcard, 'lottery_banner_prize'),
      _buildStyledField(_date, 'زمان قرعه‌کشی', Icons.event, 'lottery_banner_date'),
      
      _sectionHeader('📊 ظرفیت و آمار قرعه‌کشی'),
      _buildStyledField(_lMax, 'حداکثر ظرفیت ثبت‌نام', Icons.group, 'lottery_max_capacity'),
      _buildStyledField(_lOffset, 'عدد نمایشی اضافی (هیجان)', Icons.add_chart, 'lottery_manual_offset'),
      
      _sectionHeader('🏷️ نام دسته‌بندی‌ها'),
      _buildStyledField(_cInsta, 'دسته ۱ (اینستاگرام)', Icons.label, 'cat_insta_name'),
      _buildStyledField(_cTele, 'دسته ۲ (تلگرام)', Icons.label, 'cat_tele_name'),
      _buildStyledField(_cOther, 'دسته ۳ (سایر)', Icons.label, 'cat_other_name'),
      
      _sectionHeader('⚖️ قوانین و مقررات'),
      _buildStyledField(_rules, 'متن قوانین قرعه‌کشی', Icons.gavel, 'lottery_rules'),
      
      const SizedBox(height: 30),
    ]));
  }
  Widget _sectionHeader(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)));
  Widget _buildStyledField(TextEditingController c, String l, IconData i, String k) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))), onSubmitted: (v) => _updateConfig(k, v.trim())));
}
