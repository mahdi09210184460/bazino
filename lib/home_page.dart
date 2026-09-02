import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'register_page.dart';
import 'dart:convert';

class Product {
  dynamic id; String title, price, quality, imageUrl, category;
  Product({this.id, required this.title, required this.price, required this.quality, required this.imageUrl, required this.category});
  Map<String, dynamic> toJson() => {'title': title, 'price': price, 'quality': quality, 'image_url': imageUrl, 'category': category};
  factory Product.fromJson(Map<String, dynamic> json) => Product(id: json['id'], title: json['title'] ?? '', price: json['price'] ?? '', quality: json['quality'] ?? '', imageUrl: json['image_url'] ?? '', category: json['category'] ?? 'other');
}

class Winner {
  dynamic id; String name, prize, date;
  Winner({this.id, required this.name, required this.prize, required this.date});
  Map<String, dynamic> toJson() => {'name': name, 'prize': prize, 'date': date};
  factory Winner.fromJson(Map<String, dynamic> json) => Winner(id: json['id'], name: json['name'] ?? '', prize: json['prize'] ?? '', date: json['date'] ?? '');
}

class PrizeRecord {
  dynamic id; String title, amount; int iconCode, colorValue;
  PrizeRecord({this.id, required this.title, required this.amount, required this.iconCode, required this.colorValue});
  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'icon_code': iconCode, 'color_value': colorValue};
  factory PrizeRecord.fromJson(Map<String, dynamic> json) => PrizeRecord(id: json['id'], title: json['title'] ?? '', amount: json['amount'] ?? '', iconCode: json['icon_code'] ?? Icons.card_giftcard.codePoint, colorValue: json['color_value'] ?? Colors.orange.value);
}

class LotteryParticipant {
  dynamic id; final String name, phone, telegram, date;
  LotteryParticipant({this.id, required this.name, required this.phone, required this.telegram, required this.date});
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'telegram': telegram, 'date': date};
  factory LotteryParticipant.fromJson(Map<String, dynamic> json) => LotteryParticipant(id: json['id'], name: json['name'] ?? '', phone: json['phone'] ?? '', telegram: json['telegram'] ?? '', date: json['date'] ?? '');
}

class OrderRecord {
  dynamic id; final String userName, userPhone, productTitle, pageID, quantity, requestDetails; String status; final String date;
  OrderRecord({this.id, required this.userName, required this.userPhone, required this.productTitle, required this.pageID, required this.quantity, required this.requestDetails, this.status = "در انتظار بررسی", required this.date});
  Map<String, dynamic> toJson() => {'user_name': userName, 'user_phone': userPhone, 'product_title': productTitle, 'page_id': pageID, 'quantity': quantity, 'request_details': requestDetails, 'status': status, 'date': date};
  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(id: json['id'], userName: json['user_name'] ?? '', userPhone: json['user_phone'] ?? '', productTitle: json['product_title'] ?? '', pageID: json['page_id'] ?? '', quantity: json['quantity'] ?? '', requestDetails: json['request_details'] ?? '', status: json['status'] ?? "در انتظار بررسی", date: json['date'] ?? '');
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

  String _instaID = "pico_market_app", _telegramID = "@pico_support", _supportEmail = "support@pico.ir", _paymentLink = "https://zarrinpal.com", _lotteryEntryFee = "۱۰,۰۰۰ تومان";
  List<Product> _instaProducts = [], _telegramProducts = [], _otherProducts = [];
  List<Winner> _lotteryWinners = [];
  List<PrizeRecord> _prizes = [];
  List<LotteryParticipant> _lotteryParticipants = [];
  List<OrderRecord> _allOrders = [];
  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ هفتگی', _lotteryBannerPrize = 'جایزه ویژه: ۵ میلیون تومان', _lotteryBannerDate = 'جمعه ساعت ۲۱:۰۰';

  int _lotteryStep = 0;
  final TextEditingController _lNameController = TextEditingController(), _lPhoneController = TextEditingController(), _lTelegramController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchSupabaseData(); }

  Future<void> _fetchSupabaseData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final configRes = await _supabase.from('app_config').select();
      for (var item in configRes) {
        if (item['key'] == 'lottery_banner_title') _lotteryBannerTitle = item['value'];
        if (item['key'] == 'lottery_banner_prize') _lotteryBannerPrize = item['value'];
        if (item['key'] == 'lottery_banner_date') _lotteryBannerDate = item['value'];
        if (item['key'] == 'insta_id') _instaID = item['value'];
        if (item['key'] == 'telegram_id') _telegramID = item['value'];
        if (item['key'] == 'support_email') _supportEmail = item['value'];
        if (item['key'] == 'payment_link') _paymentLink = item['value'];
        if (item['key'] == 'lottery_entry_fee') _lotteryEntryFee = item['value'];
      }
      final productsRes = await _supabase.from('products').select();
      _instaProducts = productsRes.where((p) => p['category'] == 'insta').map((e) => Product.fromJson(e)).toList();
      _telegramProducts = productsRes.where((p) => p['category'] == 'tele').map((e) => Product.fromJson(e)).toList();
      _otherProducts = productsRes.where((p) => p['category'] == 'other').map((e) => Product.fromJson(e)).toList();
      final winnersRes = await _supabase.from('winners').select().order('created_at', ascending: false);
      _lotteryWinners = winnersRes.map((e) => Winner.fromJson(e)).toList();
      final prizesRes = await _supabase.from('prizes').select();
      _prizes = prizesRes.map((e) => PrizeRecord.fromJson(e)).toList();
      final participantsRes = await _supabase.from('participants').select().order('created_at', ascending: false);
      _lotteryParticipants = participantsRes.map((e) => LotteryParticipant.fromJson(e)).toList();
      final ordersRes = await _supabase.from('orders').select().order('created_at', ascending: false);
      _allOrders = ordersRes.map((e) => OrderRecord.fromJson(e)).toList();
    } catch (e) { debugPrint('Supabase Error: $e'); }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    List<Widget> widgetOptions = [_buildStoreContent(), _buildPrizesContent(), _buildLotteryContent(), _buildOrdersContent(), _buildProfileContent()];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(['پیکو مارکت', 'جوایز و برندگان', 'شرکت در قرعه‌کشی', 'سفارشات من', 'پروفایل'][_selectedIndex], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.orange, centerTitle: true, elevation: 2,
        actions: [
          IconButton(onPressed: _fetchSupabaseData, icon: const Icon(Icons.refresh, color: Colors.black)),
          if (_selectedIndex == 0) IconButton(onPressed: () => setState(() => _selectedIndex = 3), icon: const Icon(Icons.shopping_cart, color: Colors.black)),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(onPressed: () => _showSupportDialog(), backgroundColor: Colors.orange, child: const Icon(Icons.support_agent, color: Colors.black)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, selectedItemColor: Colors.orange, unselectedItemColor: Colors.grey, currentIndex: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'فروشگاه'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'جوایز'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'قرعه‌کشی'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'سفارشات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل'),
        ],
      ),
    );
  }

  Widget _buildPrizesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎁 لیست جوایز این دوره', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 15),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _prizes.length,
              itemBuilder: (context, index) {
                var p = _prizes[index];
                return Container(
                  width: 140, margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))]),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(radius: 35, backgroundColor: Color(p.colorValue).withOpacity(0.2), child: Icon(_getIcon(p.iconCode), size: 40, color: Color(p.colorValue))),
                    const SizedBox(height: 15),
                    Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(p.amount, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 35),
          const Text('🏆 تالار افتخارات (برندگان قبلی)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 15),
          if (_lotteryWinners.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('هنوز برنده‌ای ثبت نشده است.'))),
          ..._lotteryWinners.map((w) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.purple.withOpacity(0.1))),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.purple.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.purple)),
              title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('برنده ${w.prize}'),
              trailing: Text(w.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLotteryContent() {
    if (_lotteryStep == 1) return _buildLotteryStep1();
    if (_lotteryStep == 2) return _buildLotteryStep2();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(children: [
              const Icon(Icons.stars, color: Colors.white, size: 60),
              const SizedBox(height: 15),
              Text(_lotteryBannerTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const Divider(color: Colors.white24, height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.timer, color: Colors.white70, size: 18), const SizedBox(width: 8), Text('زمان برگزاری: $_lotteryBannerDate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            ]),
          ),
          const SizedBox(height: 40),
          const Text('چگونه شرکت کنیم؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStepInfo(1, 'تکمیل فرم اطلاعات فردی', Icons.edit_note),
          _buildStepInfo(2, 'واریز مبلغ ورودی ($_lotteryEntryFee)', Icons.account_balance_wallet),
          _buildStepInfo(3, 'دریافت کد شانس اختصاصی', Icons.qr_code),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () { _lNameController.text = widget.userName; _lPhoneController.text = widget.userPhone; setState(() => _lotteryStep = 1); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 5),
            child: const Text('شروع ثبت‌نام در قرعه‌کشی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInfo(int step, String text, IconData icon) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: [CircleAvatar(radius: 15, backgroundColor: Colors.orange, child: Text('$step', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))), const SizedBox(width: 15), Icon(icon, color: Colors.grey, size: 20), const SizedBox(width: 10), Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87))]));
  }

  IconData _getIcon(int code) {
    if (code == Icons.looks_one.codePoint) return Icons.looks_one;
    if (code == Icons.looks_two.codePoint) return Icons.looks_two;
    if (code == Icons.looks_3.codePoint) return Icons.looks_3;
    return Icons.card_giftcard;
  }

  Widget _buildLotteryStep1() {
    return Padding(padding: const EdgeInsets.all(25), child: Column(children: [
      const Text('مرحله اول: تایید مشخصات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      TextField(controller: _lNameController, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', border: OutlineInputBorder())),
      const SizedBox(height: 15),
      TextField(controller: _lPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره تماس', border: OutlineInputBorder())),
      const SizedBox(height: 30),
      ElevatedButton(onPressed: () { if (_lNameController.text.trim().isEmpty || _lPhoneController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمامی فیلدها را پر کنید'))); return; } setState(() => _lotteryStep = 2); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('مرحله بعد')),
      TextButton(onPressed: () => setState(() => _lotteryStep = 0), child: const Text('انصراف'))
    ]));
  }

  Widget _buildLotteryStep2() {
    return SingleChildScrollView(padding: const EdgeInsets.all(25), child: Column(children: [
      const Text('مرحله دوم: پرداخت نهایی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange)), child: Column(children: [Text('مبلغ ورودی: $_lotteryEntryFee', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.grey))])),
      const SizedBox(height: 25),
      const Text('شماره کارت جهت واریز:', style: TextStyle(fontSize: 15)),
      const SelectableText('۶۰۳۷ - ۹۹۷۷ - ۰۰۰۰ - ۱۱۱۱', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
      const Text('مدیریت پیکو مارکت'),
      const SizedBox(height: 30),
      TextField(controller: _lTelegramController, decoration: const InputDecoration(labelText: 'آیدی تلگرام شما جهت ارسال رسید', border: OutlineInputBorder(), hintText: '@example')),
      const SizedBox(height: 35),
      ElevatedButton(onPressed: () async {
        if (_lTelegramController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('آیدی تلگرام را وارد کنید'))); return; }
        await _supabase.from('participants').insert({'name': _lNameController.text.trim(), 'phone': _lPhoneController.text.trim(), 'telegram': _lTelegramController.text.trim(), 'date': DateTime.now().toString().split('.')[0]});
        _fetchSupabaseData(); 
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست شما ثبت شد. کد قرعه در تلگرام ارسال می‌شود.')));
        setState(() => _lotteryStep = 0);
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('تایید و ثبت نهایی')),
      TextButton(onPressed: () => setState(() => _lotteryStep = 1), child: const Text('بازگشت'))
    ]));
  }

  void _showSupportDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('پشتیبانی پیکو مارکت', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildSupportTile(Icons.camera_alt, 'اینستاگرام', _instaID),
        _buildSupportTile(Icons.send, 'تلگرام', _telegramID),
        _buildSupportTile(Icons.email, 'ایمیل', _supportEmail),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن', style: TextStyle(color: Colors.orange)))],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ));
  }

  Widget _buildSupportTile(IconData icon, String title, String value) {
    return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: ListTile(leading: Icon(icon, color: Colors.orange), title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), dense: true));
  }

  Widget _buildStoreContent() { return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildCategorySection('خدمات اینستاگرام', _instaProducts), _buildCategorySection('خدمات تلگرام', _telegramProducts), _buildCategorySection('سایر خدمات', _otherProducts), const SizedBox(height: 20)])); }
  Widget _buildCategorySection(String title, List<Product> products) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))), SizedBox(height: 230, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: products.length, itemBuilder: (context, index) { return _buildProductCard(products[index]); }))]); }
  Widget _buildProductCard(Product product) {
    return Container(
      width: 165, margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(children: [
        const SizedBox(height: 15), Image.network(product.imageUrl, height: 65, width: 65, errorBuilder: (c, e, s) => const Icon(Icons.image, size: 60, color: Colors.grey)),
        const SizedBox(height: 15), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(product.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 5), Text(product.quality, style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
        const Spacer(), Text(product.price, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
        Container(width: double.infinity, margin: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () => _handleStorePurchase(product), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('خرید', style: TextStyle(fontSize: 12)))),
      ]),
    );
  }

  void _handleStorePurchase(Product product) {
    TextEditingController n = TextEditingController(text: widget.userName), ph = TextEditingController(text: widget.userPhone), pid = TextEditingController(), q = TextEditingController(), rd = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('مشخصات سفارش'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 15),
      TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: ph, decoration: const InputDecoration(labelText: 'شماره تماس'), keyboardType: TextInputType.phone), TextField(controller: pid, decoration: const InputDecoration(labelText: 'آیدی پیج / لینک')), TextField(controller: q, decoration: const InputDecoration(labelText: 'تعداد'), keyboardType: TextInputType.number), TextField(controller: rd, decoration: const InputDecoration(labelText: 'توضیحات'), maxLines: 2),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')), ElevatedButton(onPressed: () async {
      if (n.text.isEmpty || ph.text.isEmpty || pid.text.isEmpty || q.text.isEmpty) return;
      await _supabase.from('orders').insert({'user_name': n.text.trim(), 'user_phone': ph.text.trim(), 'product_title': product.title, 'page_id': pid.text.trim(), 'quantity': q.text.trim(), 'request_details': rd.text.trim(), 'date': DateTime.now().toString().split('.')[0]});
      _fetchSupabaseData(); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => PaymentGateway(insta: _instaID, tele: _telegramID, email: _supportEmail, paymentLink: _paymentLink, productTitle: product.title, price: product.price)));
    }, child: const Text('تایید و پرداخت'))]));
  }

  Widget _buildOrdersContent() { 
    if (_allOrders.isEmpty) return const Center(child: Text('هنوز سفارشی ثبت نکرده‌اید.'));
    return ListView.builder(padding: const EdgeInsets.all(15), itemCount: _allOrders.length, itemBuilder: (context, i) {
      var o = _allOrders[i]; if (o.userPhone != widget.userPhone && o.userName != widget.userName) return const SizedBox.shrink();
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.productTitle, style: const TextStyle(fontWeight: FontWeight.bold)), Text('تاریخ: ${o.date}', style: const TextStyle(color: Colors.grey, fontSize: 12))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(o.status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)))]));
    });
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(padding: const EdgeInsets.all(25), child: Column(children: [
      const CircleAvatar(radius: 50, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 60, color: Colors.white)),
      const SizedBox(height: 20), Text(widget.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(widget.userPhone, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 30), _buildInfoTile(Icons.info_outline, 'درباره برنامه', 'پیکو مارکت - نسخه ۱.۰.۰', onDoubleTap: () {
        if (widget.userPhone == _adminPhone) Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPanel(instaProducts: _instaProducts, telegramProducts: _telegramProducts, otherProducts: _otherProducts, lotteryWinners: _lotteryWinners, prizes: _prizes, lotteryParticipants: _lotteryParticipants, allOrders: _allOrders, bannerTitle: _lotteryBannerTitle, bannerPrize: _lotteryBannerPrize, bannerDate: _lotteryBannerDate, insta: _instaID, tele: _telegramID, mail: _supportEmail, paymentLink: _paymentLink, lotteryFee: _lotteryEntryFee, onUpdate: (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o) => _fetchSupabaseData())));
      }),
      const SizedBox(height: 40), ElevatedButton.icon(onPressed: () async { (await SharedPreferences.getInstance()).clear(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const RegisterPage()), (r) => false); }, icon: const Icon(Icons.logout), label: const Text('خروج از حساب'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)))
    ]));
  }
  Widget _buildInfoTile(IconData icon, String label, String value, {VoidCallback? onDoubleTap}) { return GestureDetector(onDoubleTap: onDoubleTap, child: Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: Row(children: [Icon(icon, color: Colors.orange), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))])]))); }
}

class PaymentGateway extends StatelessWidget {
  final String insta, tele, email, paymentLink, productTitle, price;
  const PaymentGateway({super.key, required this.insta, required this.tele, required this.email, required this.paymentLink, required this.productTitle, required this.price});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      const Text('پیکو مارکت', style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.orange)),
      const Spacer(), Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.orange.withOpacity(0.2))), child: Column(children: [Text(productTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 10), Text(price, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)), const Divider(height: 40), Text('پشتیبانی: $tele', style: const TextStyle(fontSize: 14))])),
      const Spacer(), InkWell(onTap: () => launchUrl(Uri.parse(paymentLink)), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(15)), child: const Text('پرداخت مستقیم و آنلاین', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
      const SizedBox(height: 20), TextButton(onPressed: () => Navigator.pop(context), child: const Text('بازگشت به برنامه', style: TextStyle(color: Colors.grey)))
    ]))));
  }
}

class AdminPanel extends StatefulWidget {
  final List<Product> instaProducts, telegramProducts, otherProducts; final List<Winner> lotteryWinners; final List<PrizeRecord> prizes; final List<LotteryParticipant> lotteryParticipants; final List<OrderRecord> allOrders; final String bannerTitle, bannerPrize, bannerDate, insta, tele, mail, paymentLink, lotteryFee;
  final Function(List<Product>, List<Product>, List<Product>, List<Winner>, List<PrizeRecord>, List<LotteryParticipant>, List<OrderRecord>, String, String, String, String, String, String, String, String) onUpdate;
  const AdminPanel({super.key, required this.instaProducts, required this.telegramProducts, required this.otherProducts, required this.lotteryWinners, required this.prizes, required this.lotteryParticipants, required this.allOrders, required this.bannerTitle, required this.bannerPrize, required this.bannerDate, required this.insta, required this.tele, required this.mail, required this.paymentLink, required this.lotteryFee, required this.onUpdate});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late List<Product> _tempInsta, _tempTele, _tempOther; late List<Winner> _tempWinners; late List<PrizeRecord> _tempPrizes; late List<LotteryParticipant> _tempParticipants; late List<OrderRecord> _tempOrders;
  late TextEditingController _title, _prize, _date, _inst, _tel, _mail, _pay, _fee;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tempInsta = List.from(widget.instaProducts); _tempTele = List.from(widget.telegramProducts); _tempOther = List.from(widget.otherProducts); _tempWinners = List.from(widget.lotteryWinners); _tempPrizes = List.from(widget.prizes); _tempParticipants = List.from(widget.lotteryParticipants); _tempOrders = List.from(widget.allOrders);
    _title = TextEditingController(text: widget.bannerTitle); _prize = TextEditingController(text: widget.bannerPrize); _date = TextEditingController(text: widget.bannerDate); _inst = TextEditingController(text: widget.insta); _tel = TextEditingController(text: widget.tele); _mail = TextEditingController(text: widget.mail); _pay = TextEditingController(text: widget.paymentLink); _fee = TextEditingController(text: widget.lotteryFee);
  }

  Future<void> _save() async {
    try {
      await _supabase.from('app_config').upsert([{'key': 'lottery_banner_title', 'value': _title.text.trim()}, {'key': 'lottery_banner_prize', 'value': _prize.text.trim()}, {'key': 'lottery_banner_date', 'value': _date.text.trim()}, {'key': 'insta_id', 'value': _inst.text.trim()}, {'key': 'telegram_id', 'value': _tel.text.trim()}, {'key': 'support_email', 'value': _mail.text.trim()}, {'key': 'payment_link', 'value': _pay.text.trim()}, {'key': 'lottery_entry_fee', 'value': _fee.text.trim()}], onConflict: 'key');
      await _supabase.from('products').delete().neq('id', -1);
      if (_tempInsta.isNotEmpty) await _supabase.from('products').insert(_tempInsta.map((e) => e.toJson()).toList());
      if (_tempTele.isNotEmpty) await _supabase.from('products').insert(_tempTele.map((e) => e.toJson()).toList());
      if (_tempOther.isNotEmpty) await _supabase.from('products').insert(_tempOther.map((e) => e.toJson()).toList());
      await _supabase.from('winners').delete().neq('id', -1);
      if (_tempWinners.isNotEmpty) await _supabase.from('winners').insert(_tempWinners.map((e) => e.toJson()).toList());
      await _supabase.from('prizes').delete().neq('id', -1);
      if (_tempPrizes.isNotEmpty) await _supabase.from('prizes').insert(_tempPrizes.map((e) => e.toJson()).toList());
      for (var o in _tempOrders) { if (o.id != null) await _supabase.from('orders').update({'status': o.status}).eq('id', o.id); }
      if (!mounted) return;
      widget.onUpdate(_tempInsta, _tempTele, _tempOther, _tempWinners, _tempPrizes, _tempParticipants, _tempOrders, _title.text.trim(), _prize.text.trim(), _date.text.trim(), _inst.text.trim(), _tel.text.trim(), _mail.text.trim(), _pay.text.trim(), _fee.text.trim());
      Navigator.pop(context);
    } catch (e) { debugPrint('Save Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('پنل مدیریت پیشرفته', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'کاربران و سفارشات'),
              Tab(icon: Icon(Icons.inventory), text: 'محصولات'),
              Tab(icon: Icon(Icons.emoji_events), text: 'جوایز و برندگان'),
              Tab(icon: Icon(Icons.settings), text: 'تنظیمات عمومی'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildProductsTab(),
            _buildLotteryMgmtTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        _adminCardSection('🎟 شرکت‌کنندگان قرعه‌کشی', Colors.purple, _tempParticipants.isEmpty, () async { await _supabase.from('participants').delete().neq('id', -1); setState(() => _tempParticipants.clear()); },
          _tempParticipants.reversed.map((p) => ListTile(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${p.phone} | ${p.telegram}'), trailing: const Icon(Icons.person_outline))).toList(),
        ),
        const SizedBox(height: 20),
        _adminCardSection('📦 سفارشات کاربران', Colors.blue, _tempOrders.isEmpty, () async { await _supabase.from('orders').delete().neq('id', -1); setState(() => _tempOrders.clear()); },
          _tempOrders.reversed.map((o) => ListTile(
            title: Text(o.productTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('وضعیت: ${o.status}\nکاربر: ${o.userName}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => setState(() => o.status = "انجام شده")),
              IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => o.status = "رد شده")),
            ]),
          )).toList(),
        ),
      ]),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        _buildCategoryMgmt('🛒 محصولات اینستاگرام', _tempInsta, 'insta'),
        const SizedBox(height: 15),
        _buildCategoryMgmt('✈️ محصولات تلگرام', _tempTele, 'tele'),
        const SizedBox(height: 15),
        _buildCategoryMgmt('🌐 سایر خدمات', _tempOther, 'other'),
      ]),
    );
  }

  Widget _buildLotteryMgmtTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        _adminCardSection('🎁 مدیریت جوایز این دوره', Colors.orange, _tempPrizes.isEmpty, null,
          _tempPrizes.asMap().entries.map((e) => ListTile(title: Text(e.value.title), subtitle: Text(e.value.amount), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _tempPrizes.removeAt(e.key))))).toList(),
          footer: ElevatedButton.icon(onPressed: _addPrize, icon: const Icon(Icons.add), label: const Text('افزودن جایزه جدید')),
        ),
        const SizedBox(height: 20),
        _adminCardSection('🏆 لیست برندگان قبلی', Colors.green, _tempWinners.isEmpty, null,
          _tempWinners.asMap().entries.map((e) => ListTile(title: Text(e.value.name), subtitle: Text(e.value.prize), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _tempWinners.removeAt(e.key))))).toList(),
          footer: ElevatedButton.icon(onPressed: _addWinner, icon: const Icon(Icons.add), label: const Text('افزودن برنده جدید')),
        ),
      ]),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('🎧 اطلاعات پشتیبانی'),
        _buildStyledField(_inst, 'آیدی اینستاگرام', Icons.camera_alt),
        _buildStyledField(_tel, 'آیدی تلگرام', Icons.send),
        _buildStyledField(_mail, 'ایمیل پشتیبانی', Icons.email),
        const SizedBox(height: 30),
        _sectionTitle('🔗 درگاه و قرعه‌کشی'),
        _buildStyledField(_pay, 'لینک درگاه پرداخت مستقیم', Icons.link),
        _buildStyledField(_fee, 'مبلغ ورودی قرعه‌کشی', Icons.payments),
        const SizedBox(height: 30),
        _sectionTitle('🎫 بنر قرعه‌کشی'),
        _buildStyledField(_title, 'عنوان بنر', Icons.title),
        _buildStyledField(_prize, 'متن جایزه ویژه', Icons.card_giftcard),
        _buildStyledField(_date, 'تاریخ برگزاری', Icons.event),
      ]),
    );
  }

  Widget _adminCardSection(String title, Color color, bool isEmpty, VoidCallback? onClear, List<Widget> children, {Widget? footer}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            if (onClear != null) IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: onClear),
          ]),
        ),
        if (isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('موردی برای نمایش وجود ندارد', style: TextStyle(color: Colors.grey))),
        ...children,
        if (footer != null) Padding(padding: const EdgeInsets.all(10), child: footer),
      ]),
    );
  }

  Widget _buildCategoryMgmt(String title, List<Product> list, String key) {
    return _adminCardSection(title, Colors.orange, list.isEmpty, null,
      list.asMap().entries.map((e) => ListTile(title: Text(e.value.title), subtitle: Text(e.value.price), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => list.removeAt(e.key))))).toList(),
      footer: ElevatedButton.icon(onPressed: () => _addProduct(list, key), icon: const Icon(Icons.add_shopping_cart), label: const Text('افزودن محصول جدید')),
    );
  }

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)));
  Widget _buildStyledField(TextEditingController c, String l, IconData i) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.white)));

  void _addWinner() {
    TextEditingController n = TextEditingController(), p = TextEditingController(), d = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('افزودن برنده'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: p, decoration: const InputDecoration(labelText: 'جایزه')), TextField(controller: d, decoration: const InputDecoration(labelText: 'تاریخ'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (n.text.isEmpty) return; setState(() => _tempWinners.add(Winner(name: n.text, prize: p.text, date: d.text))); Navigator.pop(context); }, child: const Text('افزودن'))]));
  }
  void _addPrize() {
    TextEditingController t = TextEditingController(), a = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('افزودن جایزه'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: a, decoration: const InputDecoration(labelText: 'مبلغ'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (t.text.isEmpty) return; setState(() => _tempPrizes.add(PrizeRecord(title: t.text, amount: a.text, iconCode: Icons.card_giftcard.codePoint, colorValue: Colors.orange.value))); Navigator.pop(context); }, child: const Text('افزودن'))]));
  }
  void _addProduct(List<Product> l, String k) {
    TextEditingController t = TextEditingController(), p = TextEditingController(), q = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('افزودن محصول'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: p, decoration: const InputDecoration(labelText: 'قیمت')), TextField(controller: q, decoration: const InputDecoration(labelText: 'کیفیت'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (t.text.isEmpty) return; setState(() => l.add(Product(title: t.text, price: p.text, quality: q.text, imageUrl: k=='insta'?'https://cdn-icons-png.flaticon.com/512/174/174855.png':(k=='tele'?'https://cdn-icons-png.flaticon.com/512/2111/2111646.png':'https://cdn-icons-png.flaticon.com/512/174/174883.png'), category: k))); Navigator.pop(context); }, child: const Text('افزودن'))]));
  }
}
