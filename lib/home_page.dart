import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'register_page.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';

// --- Data Models ---

class AppUserRecord {
  final String name, phone, username, lastLogin;
  bool isBanned;
  AppUserRecord({required this.name, required this.phone, required this.username, required this.lastLogin, this.isBanned = false});
  factory AppUserRecord.fromJson(Map<String, dynamic> json) => AppUserRecord(
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    username: json['username'] ?? 'User',
    lastLogin: json['last_login'] ?? '',
    isBanned: json['is_banned'] ?? false,
  );
}

class Product {
  dynamic id;
  String title, price, quality, imageUrl, category, sku;
  int priceInt;
  Product({this.id, required this.title, required this.price, required this.quality, required this.imageUrl, required this.category, this.sku = '', this.priceInt = 0});
  factory Product.fromJson(Map<String, dynamic> json) {
    String pStr = (json['price'] ?? '0').toString().replaceAll(',', '').replaceAll(' تومان', '').split(' /')[0];
    return Product(
      id: json['id'],
      title: json['title'] ?? '',
      price: json['price'] ?? '',
      quality: json['quality'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? 'other',
      sku: json['sku'] ?? '',
      priceInt: int.tryParse(pStr) ?? 0,
    );
  }
  Map<String, dynamic> toJson() => {'title': title, 'price': price, 'quality': quality, 'image_url': imageUrl, 'category': category, 'sku': sku};
}

class OrderRecord {
  dynamic id;
  final String userName, userPhone, username, productTitle, trackingCode, pageId, requestDetails;
  String status;
  final String date;
  OrderRecord({this.id, required this.userName, required this.userPhone, required this.username, required this.productTitle, required this.trackingCode, required this.pageId, required this.requestDetails, required this.status, required this.date});
  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(
    id: json['id'],
    userName: json['user_name'] ?? '',
    userPhone: json['user_phone'] ?? '',
    username: json['username'] ?? '',
    productTitle: json['product_title'] ?? '',
    trackingCode: json['tracking_code'] ?? '',
    pageId: json['page_id'] ?? '',
    requestDetails: json['request_details'] ?? '',
    status: json['status'] ?? "در انتظار",
    date: json['date'] ?? '',
  );
}

class AppNews {
  dynamic id;
  String title, content, date;
  AppNews({this.id, required this.title, required this.content, required this.date});
  Map<String, dynamic> toJson() => {'title': title, 'content': content, 'date': date};
  factory AppNews.fromJson(Map<String, dynamic> json) => AppNews(
    id: json['id'],
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    date: json['date'] ?? '',
  );
}

class Winner {
  dynamic id;
  String name, city, prize, date, lotteryCode, phone;
  Winner({this.id, required this.name, required this.city, required this.prize, required this.date, this.lotteryCode = '', this.phone = ''});
  Map<String, dynamic> toJson() => {'name': name, 'city': city, 'prize': prize, 'date': date, 'lottery_code': lotteryCode, 'phone': phone};
  factory Winner.fromJson(Map<String, dynamic> json) => Winner(
    id: json['id'],
    name: json['name'] ?? '',
    city: json['city'] ?? '',
    prize: json['prize'] ?? '',
    date: json['date'] ?? '',
    lotteryCode: json['lottery_code'] ?? '',
    phone: json['phone'] ?? '',
  );
}

class Participant {
  dynamic id;
  String name, phone, username, lotteryCode, date;
  Participant({this.id, required this.name, required this.phone, required this.username, required this.lotteryCode, required this.date});
  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['id'],
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    username: json['username'] ?? '',
    lotteryCode: json['lottery_code'] ?? '',
    date: json['date'] ?? '',
  );
}

class PrizeRecord {
  dynamic id;
  String title, amount;
  int iconCode, colorValue;
  PrizeRecord({this.id, required this.title, required this.amount, required this.iconCode, required this.colorValue});
  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'icon_code': iconCode, 'color_value': colorValue};
  factory PrizeRecord.fromJson(Map<String, dynamic> json) => PrizeRecord(
    id: json['id'],
    title: json['title'] ?? '',
    amount: json['amount'] ?? '',
    iconCode: json['icon_code'] ?? Icons.card_giftcard.codePoint,
    colorValue: json['color_value'] ?? Colors.orange.value,
  );
}

// --- Utilities ---

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

String maskPhone(String phone) {
  if (phone.length < 7) return phone;
  return "${phone.substring(0, 4)}***${phone.substring(phone.length - 4)}";
}

IconData getIconFromCode(int code) {
  if (code == Icons.card_giftcard.codePoint) return Icons.card_giftcard;
  if (code == Icons.stars.codePoint) return Icons.stars;
  if (code == Icons.emoji_events.codePoint) return Icons.emoji_events;
  if (code == Icons.military_tech.codePoint) return Icons.military_tech;
  if (code == Icons.looks_one.codePoint) return Icons.looks_one;
  if (code == Icons.looks_two.codePoint) return Icons.looks_two;
  if (code == Icons.looks_3.codePoint) return Icons.looks_3;
  if (code == Icons.card_membership.codePoint) return Icons.card_membership;
  return Icons.stars; // Default
}

// --- Main Application Pages ---

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

  // App Configuration Variables
  String _username = "", _instaID = "pico", _telegramID = "@pico", _supportEmail = "pico@support", _paymentLink = "https://zarrinpal.com", _lotteryEntryFee = "۱۰,۰۰۰", _lotteryRules = "قوانین برنامه", _supTele = "@pico_support", _supWhatsApp = "09000000000";
  String _lotteryBazaarSKU = "lottery_entry";
  String _catInstaName = "اینستاگرام", _catTeleName = "تلگرام", _catOtherName = "سایر";
  List<Product> _instaProducts = [], _telegramProducts = [], _otherProducts = [];
  List<Winner> _lotteryWinners = [];
  List<PrizeRecord> _prizes = [];
  List<OrderRecord> _allOrders = [];
  List<AppUserRecord> _appUsers = [];
  List<AppNews> _allNews = [];
  List<Participant> _allParticipants = [];

  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ هفتگی', _lotteryBannerPrize = 'جایزه ۵ میلیونی', _lotteryBannerDate = 'جمعه ساعت ۲۱';
  int _lotteryMaxCapacity = 500, _lotteryManualOffset = 0;
  bool _isStoreEnabled = true, _isLotteryEnabled = true, _isOrdersEnabled = true, _isNewsEnabled = true, _isSupportEnabled = true;
  bool _isLoading = true;
  String _searchProductQuery = "";

  // Payment Temp Variables
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
    }, onDone: () => _subscription.cancel(), onError: (error) => debugPrint('IAP Error: $error'));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _startSecurityMonitor() async {
    Future.delayed(const Duration(minutes: 5), () async {
      if (!mounted) return;
      final res = await _supabase.from('app_users').select('is_banned').eq('phone', widget.userPhone).maybeSingle();
      if (res != null && res['is_banned'] == true) _handleBan();
    });
  }

  void _handleBan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
        if (k == 'lottery_bazaar_sku') _lotteryBazaarSKU = v;
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
    } catch (e) {
      debugPrint('Supabase Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // --- Branding & UI Helpers ---

  Widget _buildPicoLogo({double size = 40}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(size * 0.3)),
      alignment: Alignment.center,
      child: Text('P', style: TextStyle(color: Colors.white, fontSize: size * 0.7, fontWeight: FontWeight.bold)),
    );
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
      titles.add('پیکو مارکت');
    }
    if (_isLotteryEnabled) {
      activeWidgets.add(_buildLotteryAndPrizes());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'قرعه‌کشی'));
      titles.add('جوایز و قرعه‌کشی');
    }
    if (_isOrdersEnabled) {
      activeWidgets.add(_buildOrdersContent());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'سفارشات'));
      titles.add('سفارشات من');
    }
    activeWidgets.add(_buildProfileContent());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل'));
    titles.add('حساب کاربری');

    if (_selectedIndex >= activeWidgets.length) _selectedIndex = 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [_buildPicoLogo(size: 30), const SizedBox(width: 8), Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold))]),
        backgroundColor: Colors.orange, centerTitle: true,
        actions: [IconButton(onPressed: _fetchSupabaseData, icon: const Icon(Icons.refresh))],
      ),
      body: activeWidgets[_selectedIndex],
      floatingActionButton: _isSupportEnabled ? FloatingActionButton(onPressed: _showSupportDialog, backgroundColor: Colors.orange, child: const Icon(Icons.headset_mic)) : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: navItems,
      ),
    );
  }

  // --- Store Section ---

  Widget _buildStoreContent() => SingleChildScrollView(
    child: Column(children: [
      if (_isNewsEnabled && _allNews.isNotEmpty) _buildNewsTicker(),
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'جستجوی محصول در پیکو...',
            prefixIcon: const Icon(Icons.search, color: Colors.orange),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: (v) => setState(() => _searchProductQuery = v),
        ),
      ),
      _buildCategorySection(_catInstaName, _instaProducts.where((p) => p.title.contains(_searchProductQuery)).toList(), Colors.blue),
      _buildCategorySection(_catTeleName, _telegramProducts.where((p) => p.title.contains(_searchProductQuery)).toList(), Colors.teal),
      _buildCategorySection(_catOtherName, _otherProducts.where((p) => p.title.contains(_searchProductQuery)).toList(), Colors.deepPurple),
      const SizedBox(height: 80)
    ]),
  );

  Widget _buildNewsTicker() => Container(
    height: 50, margin: const EdgeInsets.only(top: 10),
    child: ListView.builder(
      scrollDirection: Axis.horizontal, itemCount: _allNews.length,
      itemBuilder: (c, i) => InkWell(
        onTap: () => _showNewsDetail(_allNews[i]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15), margin: const EdgeInsets.only(right: 10, left: 10),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.orange.withOpacity(0.3))),
          child: Row(children: [const Icon(Icons.campaign, color: Colors.orange, size: 20), const SizedBox(width: 8), Text(_allNews[i].title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
        ),
      ),
    ),
  );

  void _showNewsDetail(AppNews n) => showDialog(context: context, builder: (c) => AlertDialog(
    title: Text(n.title),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n.date, style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 10), Text(n.content)]),
    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('فهمیدم'))],
  ));

  Widget _buildCategorySection(String t, List<Product> p, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: Row(children: [Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])),
      SizedBox(height: 260, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: p.length, itemBuilder: (cxt, i) => _buildProductCard(p[i], color))),
    ],
  );

  Widget _buildProductCard(Product p, Color color) => Container(
    width: 170, margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(children: [
      const SizedBox(height: 15),
      ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: p.imageUrl.isNotEmpty
            ? Image.network(p.imageUrl, height: 80, width: 80, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(Icons.shopping_bag, size: 50, color: color.withOpacity(0.5)))
            : Icon(Icons.shopping_bag, size: 50, color: color.withOpacity(0.5)),
      ),
      const SizedBox(height: 12),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(p.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
      const Spacer(),
      Text(p.quality, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      const SizedBox(height: 4),
      Text('${formatPrice(p.priceInt)} تومان', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ElevatedButton(
          onPressed: () => _handleDirectPayment(p.priceInt, p.title, "خرید محصول"),
          style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: const Text('خرید فوری', style: TextStyle(color: Colors.white)),
        ),
      ),
      const SizedBox(height: 10),
    ]),
  );

  // --- Payment & IAP Logic ---

  Future<void> _handleDirectPayment(int amount, String title, String type) async {
    final bool available = await _iap.isAvailable();
    if (!available) { _showError('سرویس پرداخت بازار در دسترس نیست.'); return; }

    if (type == "خرید محصول") {
      TextEditingController pageIdController = TextEditingController();
      TextEditingController detailsController = TextEditingController();
      TextEditingController nameController = TextEditingController(text: widget.userName);
      TextEditingController phoneController = TextEditingController(text: widget.userPhone);

      bool? formFilled = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('تکمیل اطلاعات خریدار'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person))),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'شماره همراه', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              TextField(controller: pageIdController, decoration: const InputDecoration(labelText: 'آیدی پیج / کانال (اجباری)', prefixIcon: Icon(Icons.link))),
              TextField(controller: detailsController, decoration: const InputDecoration(labelText: 'توضیحات اضافی', prefixIcon: Icon(Icons.note)), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
            ElevatedButton(onPressed: () {
              if (pageIdController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وارد کردن آیدی الزامی است')));
                return;
              }
              Navigator.pop(c, true);
            }, child: const Text('تایید و پرداخت')),
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

      String sku = "";
      try {
        sku = [..._instaProducts, ..._telegramProducts, ..._otherProducts].firstWhere((pr) => pr.title == title).sku;
      } catch(e) { sku = ""; }

      if (sku.isEmpty) { _showError('خطا: شناسه محصول یافت نشد.'); return; }
      final ProductDetailsResponse response = await _iap.queryProductDetails({sku});
      if (response.notFoundIDs.isNotEmpty) { _showError('محصول در بازار یافت نشد.'); return; }
      _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: response.productDetails.first));
    } else {
      // Lottery Entry
      String sku = _lotteryBazaarSKU;
      final ProductDetailsResponse response = await _iap.queryProductDetails({sku});
      if (response.notFoundIDs.isNotEmpty) { _showError('آیتم قرعه‌کشی یافت نشد.'); return; }
      _tempTitle = null; // Mark as lottery
      _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: response.productDetails.first));
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> list) {
    for (var p in list) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        _deliverProduct(p);
      }
      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p);
      }
      if (p.status == PurchaseStatus.error) {
        _showError('خطا در پرداخت: ${p.error?.message}');
      }
    }
  }

  void _deliverProduct(PurchaseDetails p) async {
    if (_tempTitle != null) {
      String track = "PICO-${Random().nextInt(90000) + 10000}";
      await _supabase.from('orders').insert({
        'user_name': _tempName, 'user_phone': _tempPhone, 'username': _username,
        'product_title': _tempTitle, 'tracking_code': track, 'page_id': _tempPageId,
        'request_details': _tempDetails, 'status': 'در حال انجام', 'date': DateTime.now().toIso8601String()
      });
      _showSuccess('سفارش شما با موفقیت ثبت شد!\nکد رهگیری: $track');
    } else {
      String code = "LIT-${Random().nextInt(900000) + 100000}";
      await _supabase.from('participants').insert({
        'name': widget.userName, 'phone': widget.userPhone, 'username': _username,
        'lottery_code': code, 'date': DateTime.now().toIso8601String()
      });
      _showSuccess('شما با موفقیت در قرعه‌کشی شرکت کردید!\nکد شانس شما: $code');
    }
    _fetchSupabaseData();
  }

  // --- Lottery Section ---

  Widget _buildLotteryAndPrizes() {
    int displayCount = _allParticipants.length + _lotteryManualOffset;
    double progress = (displayCount / _lotteryMaxCapacity).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(25), width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFB300), Color(0xFFFFD54F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(children: [
            const Icon(Icons.card_membership, color: Colors.white, size: 60),
            const SizedBox(height: 15),
            Text(_lotteryBannerTitle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text('زمان قرعه‌کشی: $_lotteryBannerDate', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => _handleDirectPayment(10000, "بلیط قرعه‌کشی", "قرعه"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              child: Text('شرکت در قرعه‌کشی ($_lotteryEntryFee)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        const SizedBox(height: 30),
        const Text('📊 ظرفیت باقیمانده', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('شرکت‌کنندگان: $displayCount نفر'), Text('ظرفیت کل: $_lotteryMaxCapacity')]),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.red : Colors.orange)),
            ),
          ]),
        ),
        const SizedBox(height: 30),
        const Row(children: [Icon(Icons.emoji_events, color: Colors.amber), SizedBox(width: 8), Text('جوایز این دوره', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 15),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, itemCount: _prizes.length,
            itemBuilder: (c, i) => Container(
              width: 130, margin: const EdgeInsets.only(left: 15),
              decoration: BoxDecoration(color: Color(_prizes[i].colorValue).withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(_prizes[i].colorValue).withOpacity(0.3))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(getIconFromCode(_prizes[i].iconCode), color: Color(_prizes[i].colorValue), size: 40),
                const SizedBox(height: 10),
                Text(_prizes[i].title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                Text(_prizes[i].amount, style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Row(children: [Icon(Icons.stars, color: Colors.orange), SizedBox(width: 8), Text('برندگان دوره‌های قبل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 15),
        ..._lotteryWinners.map((w) => Card(
          margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.military_tech, color: Colors.white)),
            title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('از ${w.city} | ${w.date}'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(w.lotteryCode, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              Text(maskPhone(w.phone), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ),
        )),
        const SizedBox(height: 100),
      ]),
    );
  }

  // --- Orders Section ---

  Widget _buildOrdersContent() {
    final myOrders = _allOrders.where((o) => o.userPhone == widget.userPhone).toList();
    if (myOrders.isEmpty) return const Center(child: Text('هنوز سفارشی ثبت نکردید'));
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: myOrders.length,
      itemBuilder: (c, i) => Card(
        margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(15),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.shopping_bag, color: Colors.orange)),
          title: Text(myOrders[i].productTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 5),
            Text('کد رهگیری: ${myOrders[i].trackingCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            Text('تاریخ: ${myOrders[i].date}', style: const TextStyle(fontSize: 11)),
          ]),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: myOrders[i].status == "تکمیل شده" ? Colors.green : Colors.blue, borderRadius: BorderRadius.circular(10)),
            child: Text(myOrders[i].status, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  // --- Profile Section ---

  Widget _buildProfileContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
        child: Column(children: [
          GestureDetector(onTap: _handleAdminAccess, child: CircleAvatar(radius: 50, backgroundColor: Colors.orange.withOpacity(0.1), child: const Icon(Icons.person, size: 60, color: Colors.orange))),
          const SizedBox(height: 20),
          Text(widget.userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(widget.userPhone, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)), child: Text('نام کاربری: $_username', style: const TextStyle(color: Colors.white, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 30),
      _buildProfileMenu(Icons.help_outline, 'مرکز پشتیبانی', () => _showSupportDialog(), Colors.blue),
      _buildProfileMenu(Icons.rule, 'قوانین و مقررات', () => _showTextDialog('قوانین', _lotteryRules), Colors.orange),
      _buildProfileMenu(Icons.info_outline, 'درباره پیکو مارکت', () => _showTextDialog('درباره ما', 'پیکو مارکت، مرجع خدمات شبکه‌های اجتماعی و قرعه‌کشی‌های بزرگ.'), Colors.teal),
      const SizedBox(height: 30),
      ElevatedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance(); await prefs.clear();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RegisterPage()), (r) => false);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
        child: const Text('خروج از حساب', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 100),
    ]),
  );

  Widget _buildProfileMenu(IconData i, String t, VoidCallback onTap, Color c) => Card(
    margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(leading: Icon(i, color: c), title: Text(t), trailing: const Icon(Icons.chevron_right, size: 20), onTap: onTap),
  );

  void _showTextDialog(String title, String content) => showDialog(context: context, builder: (c) => AlertDialog(title: Text(title), content: Text(content), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]));

  void _showSupportDialog() {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (c) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ارتباط با پشتیبانی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          _buildSupTile(Icons.telegram, 'پشتیبانی تلگرام', _supTele, Colors.blue),
          _buildSupTile(Icons.chat, 'پشتیبانی واتس‌اپ', _supWhatsApp, Colors.green),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildSupTile(IconData i, String t, String v, Color c) => ListTile(
    leading: Icon(i, color: c), title: Text(t), subtitle: Text(v),
    onTap: () async {
      Clipboard.setData(ClipboardData(text: v));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کپی شد'), duration: Duration(seconds: 2)));

      String url = "";
      if (t.contains('تلگرام')) url = "https://t.me/${v.replaceAll('@', '')}";
      else if (t.contains('واتس‌اپ')) url = "https://wa.me/$v";
      else url = "mailto:$v";
      if (await canLaunchUrl(Uri.parse(url))) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    },
  );

  // --- Admin Logic ---

  void _handleAdminAccess() {
    _adminClickCount++;
    if (_adminClickCount >= 7) {
      _adminClickCount = 0;
      TextEditingController pass = TextEditingController();
      showDialog(
        context: context, builder: (c) => AlertDialog(
          title: const Text('دسترسی مدیریت'), content: TextField(controller: pass, decoration: const InputDecoration(labelText: 'رمز عبور'), obscureText: true),
          actions: [ElevatedButton(onPressed: () {
            if (pass.text == "amin1391soltani") {
              Navigator.pop(c);
              Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPanel(
                instaProducts: _instaProducts, telegramProducts: _telegramProducts, otherProducts: _otherProducts,
                lotteryWinners: _lotteryWinners, prizes: _prizes, allOrders: _allOrders, appUsers: _appUsers,
                allParticipants: _allParticipants, allNews: _allNews, bannerTitle: _lotteryBannerTitle, bannerPrize: _lotteryBannerPrize,
                bannerDate: _lotteryBannerDate, insta: _instaID, tele: _telegramID, mail: _supportEmail,
                paymentLink: _paymentLink, lotteryFee: _lotteryEntryFee, lotteryRules: _lotteryRules,
                supTele: _supTele, supWA: _supWhatsApp, catInsta: _catInstaName, catTele: _catTeleName,
                catOther: _catOtherName, lotteryMax: _lotteryMaxCapacity, lotteryOffset: _lotteryManualOffset,
                lotterySKU: _lotteryBazaarSKU,
                storeEn: _isStoreEnabled, lotteryEn: _isLotteryEnabled, ordersEn: _isOrdersEnabled,
                newsEn: _isNewsEnabled, supportEn: _isSupportEnabled, onUpdate: () => _fetchSupabaseData()
              )));
            }
          }, child: const Text('ورود'))],
        ),
      );
    }
  }

  void _showError(String m) => showDialog(context: context, builder: (c) => AlertDialog(title: const Text('خطا'), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]));
  void _showSuccess(String m) => showDialog(context: context, builder: (c) => AlertDialog(title: const Text('موفقیت'), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('تایید'))]));
}

// --- Admin Panel Implementation ---

class AdminPanel extends StatefulWidget {
  final List<Product> instaProducts, telegramProducts, otherProducts;
  final List<Winner> lotteryWinners;
  final List<PrizeRecord> prizes;
  final List<OrderRecord> allOrders;
  final List<AppUserRecord> appUsers;
  final List<Participant> allParticipants;
  final List<AppNews> allNews;
  final String bannerTitle, bannerPrize, bannerDate, insta, tele, mail, paymentLink, lotteryFee, lotteryRules, supTele, supWA, catInsta, catTele, catOther, lotterySKU;
  final int lotteryMax, lotteryOffset;
  final bool storeEn, lotteryEn, ordersEn, newsEn, supportEn;
  final VoidCallback onUpdate;

  AdminPanel({Key? key, required this.instaProducts, required this.telegramProducts, required this.otherProducts, required this.lotteryWinners, required this.prizes, required this.allOrders, required this.appUsers, required this.allParticipants, required this.allNews, required this.bannerTitle, required this.bannerPrize, required this.bannerDate, required this.insta, required this.tele, required this.mail, required this.paymentLink, required this.lotteryFee, required this.lotteryRules, required this.supTele, required this.supWA, required this.catInsta, required this.catTele, required this.catOther, required this.lotterySKU, required this.lotteryMax, required this.lotteryOffset, required this.storeEn, required this.lotteryEn, required this.ordersEn, required this.newsEn, required this.supportEn, required this.onUpdate}) : super(key: key);

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late List<Product> _tempInsta, _tempTele, _tempOther;
  late List<OrderRecord> _tempOrders;
  late List<Winner> _tempWinners;
  late List<PrizeRecord> _tempPrizes;
  late List<AppNews> _tempNews;
  late TextEditingController _title, _prize, _date, _inst, _tel, _mail, _pay, _fee, _rules, _sTel, _sWA, _cInsta, _cTele, _cOther, _lMax, _lOffset, _lSKU;
  late bool _stEn, _ltEn, _orEn, _nwEn, _suEn;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tempInsta = List.from(widget.instaProducts);
    _tempTele = List.from(widget.telegramProducts);
    _tempOther = List.from(widget.otherProducts);
    _tempOrders = List.from(widget.allOrders);
    _tempWinners = List.from(widget.lotteryWinners);
    _tempPrizes = List.from(widget.prizes);
    _tempNews = List.from(widget.allNews);
    _title = TextEditingController(text: widget.bannerTitle);
    _prize = TextEditingController(text: widget.bannerPrize);
    _date = TextEditingController(text: widget.bannerDate);
    _inst = TextEditingController(text: widget.insta);
    _tel = TextEditingController(text: widget.tele);
    _mail = TextEditingController(text: widget.mail);
    _pay = TextEditingController(text: widget.paymentLink);
    _fee = TextEditingController(text: widget.lotteryFee);
    _rules = TextEditingController(text: widget.lotteryRules);
    _sTel = TextEditingController(text: widget.supTele);
    _sWA = TextEditingController(text: widget.supWA);
    _cInsta = TextEditingController(text: widget.catInsta);
    _cTele = TextEditingController(text: widget.catTele);
    _cOther = TextEditingController(text: widget.catOther);
    _lMax = TextEditingController(text: widget.lotteryMax.toString());
    _lOffset = TextEditingController(text: widget.lotteryOffset.toString());
    _lSKU = TextEditingController(text: widget.lotterySKU);
    _stEn = widget.storeEn; _ltEn = widget.lotteryEn; _orEn = widget.ordersEn; _nwEn = widget.newsEn; _suEn = widget.supportEn;
  }

  Future<void> _updateConfig(String k, String v) async {
    try {
      await _supabase.from('app_config').upsert({'key': k, 'value': v}, onConflict: 'key');
      widget.onUpdate();
    } catch (e) { debugPrint('Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 10,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل مدیریت هوشمند'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'دسترسی'), Tab(text: 'سفارشات'), Tab(text: 'محصولات'), Tab(text: 'قرعه‌کشی'), Tab(text: 'کاربران'), Tab(text: 'جوایز'), Tab(text: 'برندگان'), Tab(text: 'اخبار'), Tab(text: 'پشتیبانی'), Tab(text: 'عمومی')
          ]),
        ),
        body: TabBarView(children: [
          _buildAccessTab(), _buildOrdersTab(), _buildProductsTab(), _buildLotteryTab(), _buildUsersTab(), _buildPrizesTab(), _buildWinnersTab(), _buildNewsTab(), _buildSupportTab(), _buildGeneralTab()
        ]),
      ),
    );
  }

  Widget _buildAccessTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _buildSwitch('فعال‌سازی فروشگاه', _stEn, (v) { setState(() => _stEn = v); _updateConfig('is_store_enabled', v.toString()); }),
    _buildSwitch('فعال‌سازی قرعه‌کشی', _ltEn, (v) { setState(() => _ltEn = v); _updateConfig('is_lottery_enabled', v.toString()); }),
    _buildSwitch('بخش سفارشات', _orEn, (v) { setState(() => _orEn = v); _updateConfig('is_orders_enabled', v.toString()); }),
    _buildSwitch('بخش اخبار', _nwEn, (v) { setState(() => _nwEn = v); _updateConfig('is_news_enabled', v.toString()); }),
    _buildSwitch('سیستم پشتیبانی', _suEn, (v) { setState(() => _suEn = v); _updateConfig('is_support_enabled', v.toString()); }),
  ]);

  Widget _buildSwitch(String label, bool val, Function(bool) onChanged) => SwitchListTile(title: Text(label), value: val, onChanged: onChanged, activeColor: Colors.orange);

  Widget _buildOrdersTab() => ListView.builder(
    itemCount: _tempOrders.length,
    itemBuilder: (c, i) => Card(
      child: ListTile(
        title: Text(_tempOrders[i].productTitle),
        subtitle: Text('کاربر: ${_tempOrders[i].userName} | آیدی: ${_tempOrders[i].pageId}'),
        trailing: DropdownButton<String>(
          value: _tempOrders[i].status,
          onChanged: (v) async {
            if (v == null) return;
            await _supabase.from('orders').update({'status': v}).eq('id', _tempOrders[i].id);
            setState(() { _tempOrders[i].status = v; });
            widget.onUpdate();
          },
          items: ['در انتظار', 'در حال انجام', 'تکمیل شده', 'لغو شده'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        ),
      ),
    ),
  );

  Widget _buildProductsTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      ElevatedButton.icon(onPressed: () => _showProductDialog(), icon: const Icon(Icons.add), label: const Text('افزودن محصول جدید')),
      const Divider(height: 30),
      ..._tempInsta.map((p) => _buildAdminProdCard(p)),
      ..._tempTele.map((p) => _buildAdminProdCard(p)),
      ..._tempOther.map((p) => _buildAdminProdCard(p)),
    ]),
  );

  Widget _buildAdminProdCard(Product p) => Card(
    child: ListTile(
      leading: const Icon(Icons.shopping_bag, color: Colors.orange),
      title: Text(p.title),
      subtitle: Text('قیمت: ${p.price} | SKU: ${p.sku}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(product: p)),
        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(p)),
      ]),
    ),
  );

  void _showProductDialog({Product? product}) {
    TextEditingController t = TextEditingController(text: product?.title);
    TextEditingController pr = TextEditingController(text: product?.price);
    TextEditingController q = TextEditingController(text: product?.quality);
    TextEditingController img = TextEditingController(text: product?.imageUrl);
    TextEditingController s = TextEditingController(text: product?.sku);
    String cat = product?.category ?? 'insta';

    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setDialogState) => AlertDialog(
      title: Text(product == null ? 'افزودن محصول' : 'ویرایش محصول'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: 'نام محصول')),
        TextField(controller: pr, decoration: const InputDecoration(labelText: 'قیمت (متن)')),
        TextField(controller: q, decoration: const InputDecoration(labelText: 'کیفیت')),
        TextField(controller: img, decoration: const InputDecoration(labelText: 'لینک عکس')),
        TextField(controller: s, decoration: const InputDecoration(labelText: 'SKU بازار')),
        DropdownButton<String>(value: cat, items: ['insta', 'tele', 'other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setDialogState(() => cat = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')),
        ElevatedButton(onPressed: () async {
          final data = {'title': t.text, 'price': pr.text, 'quality': q.text, 'image_url': img.text, 'sku': s.text, 'category': cat};
          if (product == null) {
            final res = await _supabase.from('products').insert(data).select().single();
            Product newP = Product.fromJson(res);
            setState(() {
              if (cat == 'insta') _tempInsta.add(newP);
              else if (cat == 'tele') _tempTele.add(newP);
              else _tempOther.add(newP);
            });
          } else {
            await _supabase.from('products').update(data).eq('id', product.id);
            setState(() {
              if (product.category == cat) {
                if (cat == 'insta') { int idx = _tempInsta.indexWhere((p) => p.id == product.id); if (idx != -1) _tempInsta[idx] = Product.fromJson({...data, 'id': product.id}); }
                else if (cat == 'tele') { int idx = _tempTele.indexWhere((p) => p.id == product.id); if (idx != -1) _tempTele[idx] = Product.fromJson({...data, 'id': product.id}); }
                else { int idx = _tempOther.indexWhere((p) => p.id == product.id); if (idx != -1) _tempOther[idx] = Product.fromJson({...data, 'id': product.id}); }
              } else {
                if (product.category == 'insta') _tempInsta.removeWhere((p) => p.id == product.id);
                else if (product.category == 'tele') _tempTele.removeWhere((p) => p.id == product.id);
                else _tempOther.removeWhere((p) => p.id == product.id);

                Product newP = Product.fromJson({...data, 'id': product.id});
                if (cat == 'insta') _tempInsta.add(newP);
                else if (cat == 'tele') _tempTele.add(newP);
                else _tempOther.add(newP);
              }
            });
          }
          widget.onUpdate(); Navigator.pop(c);
        }, child: Text(product == null ? 'افزودن' : 'بروزرسانی')),
      ],
    )));
  }

  void _deleteProduct(Product p) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('حذف محصول'), content: const Text('آیا از حذف این محصول مطمئن هستید؟'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('نه')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('بله'))]));
    if (confirm == true) {
      await _supabase.from('products').delete().eq('id', p.id);
      setState(() {
        if (p.category == 'insta') _tempInsta.removeWhere((prod) => prod.id == p.id);
        else if (p.category == 'tele') _tempTele.removeWhere((prod) => prod.id == p.id);
        else _tempOther.removeWhere((prod) => prod.id == p.id);
      });
      widget.onUpdate();
    }
  }

  Widget _buildLotteryTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _buildField(_title, 'عنوان بنر قرعه‌کشی', 'lottery_banner_title'),
    _buildField(_prize, 'جایزه اصلی', 'lottery_banner_prize'),
    _buildField(_date, 'تاریخ قرعه‌کشی', 'lottery_banner_date'),
    _buildField(_fee, 'هزینه شرکت (متن)', 'lottery_entry_fee'),
    _buildField(_lSKU, 'SKU بازار قرعه‌کشی', 'lottery_bazaar_sku'),
    _buildField(_lMax, 'حداکثر ظرفیت', 'lottery_max_capacity'),
    _buildField(_lOffset, 'آمار نمایشی (Manual Offset)', 'lottery_manual_offset'),
    const Divider(),
    const Text('شرکت‌کنندگان فعلی:'),
    ...widget.allParticipants.take(10).map((pa) => ListTile(title: Text(pa.name), subtitle: Text(pa.lotteryCode))),
  ]);

  Widget _buildUsersTab() => ListView.builder(
    itemCount: widget.appUsers.length,
    itemBuilder: (c, i) => ListTile(
      title: Text(widget.appUsers[i].name),
      subtitle: Text(widget.appUsers[i].phone),
      trailing: Switch(
        value: !widget.appUsers[i].isBanned,
        onChanged: (v) async {
          await _supabase.from('app_users').update({'is_banned': !v}).eq('phone', widget.appUsers[i].phone);
          setState(() { widget.appUsers[i].isBanned = !v; });
        },
      ),
    ),
  );

  Widget _buildPrizesTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(onPressed: () => _showPrizeDialog(), icon: const Icon(Icons.add), label: const Text('افزودن جایزه')),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _tempPrizes.length,
          itemBuilder: (c, i) => Card(
            child: ListTile(
              leading: Icon(getIconFromCode(_tempPrizes[i].iconCode), color: Color(_tempPrizes[i].colorValue)),
              title: Text(_tempPrizes[i].title),
              subtitle: Text(_tempPrizes[i].amount),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showPrizeDialog(prize: _tempPrizes[i])),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePrize(_tempPrizes[i])),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  void _showPrizeDialog({PrizeRecord? prize}) {
    TextEditingController t = TextEditingController(text: prize?.title);
    TextEditingController am = TextEditingController(text: prize?.amount);
    int icon = prize?.iconCode ?? Icons.card_giftcard.codePoint;
    int color = prize?.colorValue ?? Colors.orange.value;

    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setDialogState) => AlertDialog(
      title: Text(prize == null ? 'افزودن جایزه' : 'ویرایش جایزه'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان جایزه')),
        TextField(controller: am, decoration: const InputDecoration(labelText: 'مقدار/توضیح')),
        const SizedBox(height: 10),
        const Text('انتخاب آیکون:'),
        Wrap(children: [Icons.card_giftcard, Icons.stars, Icons.emoji_events, Icons.military_tech, Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.card_membership].map((ic) => IconButton(icon: Icon(ic, color: icon == ic.codePoint ? Colors.orange : Colors.grey), onPressed: () => setDialogState(() => icon = ic.codePoint))).toList()),
        const SizedBox(height: 10),
        const Text('انتخاب رنگ:'),
        Wrap(children: [Colors.orange, Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.amber].map((cl) => IconButton(icon: Icon(Icons.circle, color: cl), onPressed: () => setDialogState(() => color = cl.value))).toList()),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')),
        ElevatedButton(onPressed: () async {
          final data = {'title': t.text, 'amount': am.text, 'icon_code': icon, 'color_value': color};
          if (prize == null) {
            final res = await _supabase.from('prizes').insert(data).select().single();
            setState(() { _tempPrizes.add(PrizeRecord.fromJson(res)); });
          } else {
            await _supabase.from('prizes').update(data).eq('id', prize.id);
            setState(() { int idx = _tempPrizes.indexWhere((pr) => pr.id == prize.id); if (idx != -1) _tempPrizes[idx] = PrizeRecord.fromJson({...data, 'id': prize.id}); });
          }
          widget.onUpdate(); Navigator.pop(c);
        }, child: Text(prize == null ? 'افزودن' : 'بروزرسانی')),
      ],
    )));
  }

  void _deletePrize(PrizeRecord pr) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('حذف جایزه'), content: const Text('آیا از حذف این جایزه مطمئن هستید؟'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('نه')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('بله'))]));
    if (confirm == true) { await _supabase.from('prizes').delete().eq('id', pr.id); setState(() { _tempPrizes.removeWhere((p) => p.id == pr.id); }); widget.onUpdate(); }
  }

  Widget _buildWinnersTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(onPressed: () => _showWinnerDialog(), icon: const Icon(Icons.add), label: const Text('افزودن برنده جدید')),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _tempWinners.length,
          itemBuilder: (c, i) => Card(
            child: ListTile(
              title: Text(_tempWinners[i].name),
              subtitle: Text('${_tempWinners[i].prize} | ${_tempWinners[i].city}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showWinnerDialog(winner: _tempWinners[i])),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteWinner(_tempWinners[i])),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  void _showWinnerDialog({Winner? winner}) {
    TextEditingController n = TextEditingController(text: winner?.name);
    TextEditingController c = TextEditingController(text: winner?.city);
    TextEditingController p = TextEditingController(text: winner?.prize);
    TextEditingController d = TextEditingController(text: winner?.date);
    TextEditingController lc = TextEditingController(text: winner?.lotteryCode);
    TextEditingController ph = TextEditingController(text: winner?.phone);

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(winner == null ? 'افزودن برنده' : 'ویرایش برنده'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: 'نام برنده')),
        TextField(controller: c, decoration: const InputDecoration(labelText: 'شهر')),
        TextField(controller: p, decoration: const InputDecoration(labelText: 'جایزه')),
        TextField(controller: d, decoration: const InputDecoration(labelText: 'تاریخ')),
        TextField(controller: lc, decoration: const InputDecoration(labelText: 'کد قرعه‌کشی')),
        TextField(controller: ph, decoration: const InputDecoration(labelText: 'تلفن (برای ماسک)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        ElevatedButton(onPressed: () async {
          final data = {'name': n.text, 'city': c.text, 'prize': p.text, 'date': d.text, 'lottery_code': lc.text, 'phone': ph.text};
          if (winner == null) {
            final res = await _supabase.from('winners').insert(data).select().single();
            setState(() { _tempWinners.insert(0, Winner.fromJson(res)); });
          } else {
            await _supabase.from('winners').update(data).eq('id', winner.id);
            setState(() { int idx = _tempWinners.indexWhere((w) => w.id == winner.id); if (idx != -1) _tempWinners[idx] = Winner.fromJson({...data, 'id': winner.id}); });
          }
          widget.onUpdate(); Navigator.pop(ctx);
        }, child: Text(winner == null ? 'افزودن' : 'بروزرسانی')),
      ],
    ));
  }

  void _deleteWinner(Winner w) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('حذف برنده'), content: const Text('آیا از حذف این برنده مطمئن هستید؟'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('نه')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('بله'))]));
    if (confirm == true) { await _supabase.from('winners').delete().eq('id', w.id); setState(() { _tempWinners.removeWhere((win) => win.id == w.id); }); widget.onUpdate(); }
  }

  Widget _buildNewsTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(onPressed: () => _showNewsDialog(), icon: const Icon(Icons.add), label: const Text('افزودن خبر جدید')),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _tempNews.length,
          itemBuilder: (c, i) => Card(
            child: ListTile(
              title: Text(_tempNews[i].title),
              subtitle: Text(_tempNews[i].date),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showNewsDialog(news: _tempNews[i])),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteNews(_tempNews[i])),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  void _showNewsDialog({AppNews? news}) {
    TextEditingController t = TextEditingController(text: news?.title);
    TextEditingController co = TextEditingController(text: news?.content);
    TextEditingController d = TextEditingController(text: news?.date ?? DateTime.now().toString().split(' ')[0]);

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(news == null ? 'افزودن خبر' : 'ویرایش خبر'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان خبر')),
        TextField(controller: co, decoration: const InputDecoration(labelText: 'متن خبر'), maxLines: 3),
        TextField(controller: d, decoration: const InputDecoration(labelText: 'تاریخ')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        ElevatedButton(onPressed: () async {
          final data = {'title': t.text, 'content': co.text, 'date': d.text};
          if (news == null) {
            final res = await _supabase.from('news').insert(data).select().single();
            setState(() { _tempNews.insert(0, AppNews.fromJson(res)); });
          } else {
            await _supabase.from('news').update(data).eq('id', news.id);
            setState(() { int idx = _tempNews.indexWhere((n) => n.id == news.id); if (idx != -1) _tempNews[idx] = AppNews.fromJson({...data, 'id': news.id}); });
          }
          widget.onUpdate(); Navigator.pop(ctx);
        }, child: Text(news == null ? 'افزودن' : 'بروزرسانی')),
      ],
    ));
  }

  void _deleteNews(AppNews n) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('حذف خبر'), content: const Text('آیا از حذف این خبر مطمئن هستید؟'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('نه')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('بله'))]));
    if (confirm == true) { await _supabase.from('news').delete().eq('id', n.id); setState(() { _tempNews.removeWhere((item) => item.id == n.id); }); widget.onUpdate(); }
  }

  Widget _buildSupportTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _buildField(_sTel, 'آیدی تلگرام پشتیبان', 'sup_tele'),
    _buildField(_sWA, 'شماره واتس‌اپ پشتیبان', 'sup_whatsapp'),
    _buildField(_mail, 'ایمیل پشتیبانی', 'support_email'),
  ]);

  Widget _buildGeneralTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _buildField(_inst, 'آیدی اینستاگرام پیج اصلی', 'insta_id'),
    _buildField(_tel, 'آیدی کانال تلگرام', 'telegram_id'),
    _pay == null ? const SizedBox() : _buildField(_pay, 'لینک پرداخت مکمل', 'payment_link'),
    _buildField(_cInsta, 'نام دسته اینستاگرام', 'cat_insta_name'),
    _buildField(_cTele, 'نام دسته تلگرام', 'cat_tele_name'),
    _buildField(_cOther, 'نام دسته سایر', 'cat_other_name'),
    _buildField(_rules, 'متن قوانین و مقررات (بسیار مهم)', 'lottery_rules'),
  ]);

  Widget _buildField(TextEditingController c, String l, String k) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: c, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()),
      onChanged: (v) => _updateConfig(k, v),
    ),
  );
}
