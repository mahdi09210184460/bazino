import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'dart:math';
import 'dart:convert';

class Product {
  dynamic id;
  String title;
  String price;
  String quality;
  String imageUrl;
  String category;

  Product({
    this.id,
    required this.title,
    required this.price,
    required this.quality,
    required this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toJson() => {'title': title, 'price': price, 'quality': quality, 'image_url': imageUrl, 'category': category};
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    title: json['title'], 
    price: json['price'], 
    quality: json['quality'], 
    imageUrl: json['image_url'] ?? '',
    category: json['category'] ?? 'other',
  );
}

class Winner {
  dynamic id;
  String name;
  String prize;
  String date;

  Winner({this.id, required this.name, required this.prize, required this.date});

  Map<String, dynamic> toJson() => {'name': name, 'prize': prize, 'date': date};
  factory Winner.fromJson(Map<String, dynamic> json) => Winner(id: json['id'], name: json['name'], prize: json['prize'], date: json['date']);
}

class PrizeRecord {
  dynamic id;
  String title;
  String amount;
  int iconCode;
  int colorValue;

  PrizeRecord({this.id, required this.title, required this.amount, required this.iconCode, required this.colorValue});

  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'icon_code': iconCode, 'color_value': colorValue};
  factory PrizeRecord.fromJson(Map<String, dynamic> json) => PrizeRecord(
    id: json['id'],
    title: json['title'], 
    amount: json['amount'], 
    iconCode: json['icon_code'], 
    colorValue: json['color_value']
  );
}

class LotteryParticipant {
  dynamic id;
  final String name;
  final String phone;
  final String telegram;
  final String date;

  LotteryParticipant({this.id, required this.name, required this.phone, required this.telegram, required this.date});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'telegram': telegram, 'date': date};
  factory LotteryParticipant.fromJson(Map<String, dynamic> json) => LotteryParticipant(id: json['id'], name: json['name'], phone: json['phone'], telegram: json['telegram'], date: json['date']);
}

class OrderRecord {
  dynamic id;
  final String userName;
  final String userPhone;
  final String productTitle;
  final String pageID;
  final String quantity;
  final String requestDetails;
  String status;
  final String date;

  OrderRecord({
    this.id,
    required this.userName,
    required this.userPhone,
    required this.productTitle,
    required this.pageID,
    required this.quantity,
    required this.requestDetails,
    this.status = "در انتظار بررسی",
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'user_name': userName, 
    'user_phone': userPhone, 
    'product_title': productTitle, 
    'page_id': pageID, 
    'quantity': quantity, 
    'request_details': requestDetails, 
    'status': status, 
    'date': date
  };
  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(
    id: json['id'],
    userName: json['user_name'], 
    userPhone: json['user_phone'], 
    productTitle: json['product_title'], 
    pageID: json['page_id'], 
    quantity: json['quantity'], 
    requestDetails: json['request_details'], 
    status: json['status'], 
    date: json['date']
  );
}

class HomePage extends StatefulWidget {
  final String userName;
  final String userPhone;
  final String userEmail;

  const HomePage({
    super.key,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final String _adminPhone = "09927891608";
  final SupabaseClient _supabase = Supabase.instance.client;

  String _instaID = "bazino_app";
  String _telegramID = "@bazino_support";
  String _supportEmail = "support@bazino.ir";

  List<Product> _instaProducts = [];
  List<Product> _telegramProducts = [];
  List<Product> _otherProducts = [];
  List<Winner> _lotteryWinners = [];
  List<PrizeRecord> _prizes = [];
  List<LotteryParticipant> _lotteryParticipants = [];
  List<OrderRecord> _allOrders = [];
  
  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ هفتگی پیکو مارکت';
  String _lotteryBannerPrize = 'جایزه ویژه: ۵ میلیون تومان وجه نقد';
  String _lotteryBannerDate = 'جمعه ساعت ۲۱:۰۰';

  int _lotteryStep = 0;
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _lPhoneController = TextEditingController();
  final TextEditingController _lTelegramController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSupabaseData();
  }

  Future<void> _fetchSupabaseData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Config
      final configRes = await _supabase.from('app_config').select();
      for (var item in configRes) {
        if (item['key'] == 'lottery_banner_title') _lotteryBannerTitle = item['value'];
        if (item['key'] == 'lottery_banner_prize') _lotteryBannerPrize = item['value'];
        if (item['key'] == 'lottery_banner_date') _lotteryBannerDate = item['value'];
        if (item['key'] == 'insta_id') _instaID = item['value'];
        if (item['key'] == 'telegram_id') _telegramID = item['value'];
        if (item['key'] == 'support_email') _supportEmail = item['value'];
      }

      // Fetch Products
      final productsRes = await _supabase.from('products').select();
      _instaProducts = productsRes.where((p) => p['category'] == 'insta').map((e) => Product.fromJson(e)).toList();
      _telegramProducts = productsRes.where((p) => p['category'] == 'tele').map((e) => Product.fromJson(e)).toList();
      _otherProducts = productsRes.where((p) => p['category'] == 'other').map((e) => Product.fromJson(e)).toList();

      // Fetch Winners
      final winnersRes = await _supabase.from('winners').select().order('created_at', ascending: false);
      _lotteryWinners = winnersRes.map((e) => Winner.fromJson(e)).toList();

      // Fetch Prizes
      final prizesRes = await _supabase.from('prizes').select();
      _prizes = prizesRes.map((e) => PrizeRecord.fromJson(e)).toList();

      // Fetch Participants (Admin only ideally, but fetching here for simplicity)
      final participantsRes = await _supabase.from('participants').select().order('created_at', ascending: false);
      _lotteryParticipants = participantsRes.map((e) => LotteryParticipant.fromJson(e)).toList();

      // Fetch Orders
      final ordersRes = await _supabase.from('orders').select().order('created_at', ascending: false);
      _allOrders = ordersRes.map((e) => OrderRecord.fromJson(e)).toList();

    } catch (e) {
      debugPrint('Supabase Error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    List<Widget> widgetOptions = <Widget>[
      _buildStoreContent(),
      _buildLotteryContent(),
      _buildOrdersContent(),
      _buildProfileContent(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'پیکو مارکت' : (_selectedIndex == 1 ? 'جوایز و قرعه‌کشی' : (_selectedIndex == 2 ? 'سفارشات من' : 'پروفایل کاربری')),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchSupabaseData,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          if (_selectedIndex == 0)
            IconButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              icon: const Icon(Icons.shopping_cart, color: Colors.black),
            ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupportDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.support_agent, color: Colors.black),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'فروشگاه'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'قرعه‌کشی'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'سفارشات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل'),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پشتیبانی پیکو مارکت', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('جهت سوالات، پیشنهادات و انتقادات با ما در ارتباط باشید:', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
            const SizedBox(height: 20),
            _buildSupportTile(Icons.camera_alt, 'اینستاگرام', _instaID),
            _buildSupportTile(Icons.send, 'تلگرام', _telegramID),
            _buildSupportTile(Icons.email, 'ایمیل', _supportEmail),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن', style: TextStyle(color: Colors.orange)))
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSupportTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        dense: true,
      ),
    );
  }

  // --- LOTTERY SECTION ---
  Widget _buildLotteryContent() {
    if (_lotteryStep == 1) return _buildLotteryStep1();
    if (_lotteryStep == 2) return _buildLotteryStep2();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLotteryBanner(),
          const SizedBox(height: 30),
          const Text('🏆 برندگان هفتگی قرعه‌کشی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildWinnersTable(),
          const SizedBox(height: 30),
          const Text('🎁 جوایز این دوره', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _prizes.map((p) => _buildPrizeCard(p.title, p.amount, IconData(p.iconCode, fontFamily: 'MaterialIcons'), Color(p.colorValue))).toList(),
            ),
          ),
          const SizedBox(height: 30),
          _buildLotteryEntryCTA(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLotteryBanner() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.orange], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Icon(Icons.stars, size: 150, color: Colors.white.withOpacity(0.1))),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_lotteryBannerTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(_lotteryBannerPrize, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('موعد قرعه‌کشی: $_lotteryBannerDate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnersTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.orange.withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('نام برنده', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('جایزه', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('تاریخ', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _lotteryWinners.map((w) => DataRow(cells: [
            DataCell(Text(w.name)),
            DataCell(Text(w.prize)),
            DataCell(Text(w.date)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildLotteryEntryCTA() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.orange, width: 2)),
      child: Column(
        children: [
          const Text('ثبت‌نام در قرعه‌کشی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('برای شرکت در این دوره و دریافت کد شانس کلیک کنید.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _lNameController.text = widget.userName;
              _lPhoneController.text = widget.userPhone;
              setState(() => _lotteryStep = 1);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text('ورود و ثبت نام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLotteryStep1() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text('مرحله اول: مشخصات فردی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextField(controller: _lNameController, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _lPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره تماس', border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              if (_lNameController.text.isEmpty || _lPhoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً تمامی فیلدها را پر کنید')));
                return;
              }
              setState(() => _lotteryStep = 2);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
            child: const Text('مرحله بعد'),
          ),
          TextButton(onPressed: () => setState(() => _lotteryStep = 0), child: const Text('بازگشت'))
        ],
      ),
    );
  }

  Widget _buildLotteryStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text('مرحله دوم: پرداخت و تایید', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
            color: Colors.orangeAccent,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  const Text('مبلغ ورودی: ۱۰,۰۰۰ تومان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_lotteryBannerPrize, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('لطفاً مبلغ را به شماره کارت زیر واریز کنید:', textAlign: TextAlign.center),
          const SelectableText('۶۰۳۷ - ۹۹۷۷ - ۰۰۰۰ - ۱۱۱۱', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const Text('بنام: مدیریت پیکو مارکت'),
          const SizedBox(height: 25),
          TextField(controller: _lTelegramController, decoration: const InputDecoration(labelText: 'آیدی تلگرام جهت ارسال رسید', border: OutlineInputBorder(), hintText: '@example')),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue, width: 2)),
            child: const Text('پس از واریزی و تایید ادمین در تلگرام کد قرعه خود را دریافت میکنید', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              if (_lTelegramController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً آیدی تلگرام را وارد کنید')));
                return;
              }
              
              await _supabase.from('participants').insert({
                'name': _lNameController.text,
                'phone': _lPhoneController.text,
                'telegram': _lTelegramController.text,
                'date': DateTime.now().toString().split('.')[0],
              });

              _fetchSupabaseData(); // Refresh local list
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست شما با موفقیت ثبت شد.')));
              setState(() => _lotteryStep = 0);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
            child: const Text('تایید نهایی و بازگشت'),
          ),
          TextButton(onPressed: () => setState(() => _lotteryStep = 1), child: const Text('بازگشت'))
        ],
      ),
    );
  }

  Widget _buildPrizeCard(String rank, String amount, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 10),
          Text(rank, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // --- ORDERS & OTHERS ---
  Widget _buildOrdersContent() { 
    if (_allOrders.isEmpty) return const Center(child: Text('هنوز سفارشی ثبت نکرده‌اید.'));
    return ListView(
      padding: const EdgeInsets.all(15), 
      children: _allOrders.where((o) => o.userPhone == widget.userPhone).map((o) => _buildOrderItem(o.productTitle, 'سفارش در تاریخ ${o.date}', o.status, Colors.blue)).toList(),
    );
  }

  Widget _buildOrderItem(String title, String subtitle, String status, Color statusColor) { return Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)))])); }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(child: Stack(children: [CircleAvatar(radius: 60, backgroundColor: Colors.orange.withOpacity(0.2), child: const Icon(Icons.person, size: 80, color: Colors.orange)), Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.orange, radius: 18, child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.black), onPressed: () {})))])),
          const SizedBox(height: 30),
          _buildInfoTile(Icons.person, 'نام و نام خانوادگی', widget.userName),
          _buildInfoTile(Icons.phone, 'شماره تماس', widget.userPhone),
          _buildInfoTile(Icons.email, 'ایمیل', widget.userEmail),
          const SizedBox(height: 15),
          GestureDetector(
            onDoubleTap: () {
              if (widget.userPhone == _adminPhone) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPanel(
                  instaProducts: _instaProducts,
                  telegramProducts: _telegramProducts,
                  otherProducts: _otherProducts,
                  lotteryWinners: _lotteryWinners,
                  prizes: _prizes,
                  lotteryParticipants: _lotteryParticipants,
                  allOrders: _allOrders,
                  bannerTitle: _lotteryBannerTitle,
                  bannerPrize: _lotteryBannerPrize,
                  bannerDate: _lotteryBannerDate,
                  insta: _instaID,
                  tele: _telegramID,
                  mail: _supportEmail,
                  onUpdate: (insta, tele, other, winners, przs, parts, orders, title, prize, date, inst, tel, eml) async {
                    setState(() => _isLoading = true);
                    // Sync Admin changes to Supabase would be done here...
                    // For performance, we'll let AdminPanel handle Supabase calls
                    _fetchSupabaseData();
                  },
                )));
              }
            },
            child: _buildInfoTile(Icons.info_outline, 'درباره برنامه', 'نسخه ۱.۰.۰ (پیکو مارکت)'),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RegisterPage()), (route) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('خروج از حساب'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) { return Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Row(children: [Icon(icon, color: Colors.orange), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])])); }

  Widget _buildStoreContent() {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildCategorySection('خدمات اینستاگرام', _instaProducts), _buildCategorySection('خدمات تلگرام', _telegramProducts), _buildCategorySection('سایر خدمات (یوتیوب و تیک‌تاک)', _otherProducts), const SizedBox(height: 20)]));
  }

  Widget _buildCategorySection(String title, List<Product> products) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), TextButton(onPressed: () {}, child: const Text('مشاهده همه', style: TextStyle(color: Colors.orange)))])), SizedBox(height: 220, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: products.length, itemBuilder: (context, index) { return _buildProductCard(products[index]); }))]); }
  
  Widget _buildProductCard(Product product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          Image.network(product.imageUrl, height: 60, width: 60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60, color: Colors.grey)),
          const SizedBox(height: 15),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(product.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 5),
          Text(product.quality, style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
          const Spacer(),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(product.price, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () => _handleStorePurchase(product),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('خرید', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStorePurchase(Product product) {
    TextEditingController nameCtrl = TextEditingController(text: widget.userName);
    TextEditingController phoneCtrl = TextEditingController(text: widget.userPhone);
    TextEditingController pageIDCtrl = TextEditingController();
    TextEditingController quantityCtrl = TextEditingController();
    TextEditingController requestCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مشخصات سفارش', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('محصول: ${product.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'شماره تماس'), keyboardType: TextInputType.phone),
              TextField(controller: pageIDCtrl, decoration: const InputDecoration(labelText: 'آیدی پیج / لینک')),
              TextField(controller: quantityCtrl, decoration: const InputDecoration(labelText: 'تعداد مورد نظر'), keyboardType: TextInputType.number),
              TextField(controller: requestCtrl, decoration: const InputDecoration(labelText: 'نوع درخواست و توضیحات'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || pageIDCtrl.text.isEmpty || quantityCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً تمامی فیلدها را پر کنید')));
                return;
              }
              
              await _supabase.from('orders').insert({
                'user_name': nameCtrl.text,
                'user_phone': phoneCtrl.text,
                'product_title': product.title,
                'page_id': pageIDCtrl.text,
                'quantity': quantityCtrl.text,
                'request_details': requestCtrl.text,
                'date': DateTime.now().toString().split('.')[0],
              });

              _fetchSupabaseData(); // Refresh local list
              if (!mounted) return;
              Navigator.pop(context);
              _navigateToPayment(product);
            },
            child: const Text('تایید و پرداخت'),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment(Product product) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentGateway(insta: _instaID, tele: _telegramID, email: _supportEmail, productTitle: product.title, price: product.price)));
  }
}

class PaymentGateway extends StatelessWidget {
  final String insta;
  final String tele;
  final String email;
  final String productTitle;
  final String price;
  const PaymentGateway({super.key, required this.insta, required this.tele, required this.email, required this.productTitle, required this.price});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(children: [
            const SizedBox(height: 30),
            const Text('پیکو مارکت', style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.orange, shadows: [Shadow(blurRadius: 10, color: Colors.black12, offset: Offset(2, 2))])),
            const Text('فروشگاه خدمات مجازی و بازی', style: TextStyle(color: Colors.grey)),
            const Spacer(),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.withOpacity(0.2))), child: Column(children: [
              Text('سفارش شما: $productTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('مبلغ: $price', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              const Text('پشتیبانی درگاه:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              Text('اینستاگرام: $insta', style: const TextStyle(fontSize: 13)),
              Text('تلگرام: $tele', style: const TextStyle(fontSize: 13)),
              Text('ایمیل: $email', style: const TextStyle(fontSize: 13)),
            ])),
            const Spacer(),
            const Text('انتخاب درگاه پرداخت ایمن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildGatewayIcon('زرین پال', Colors.yellow), const SizedBox(width: 20), _buildGatewayIcon('بانک ملت', Colors.red)]),
            const SizedBox(height: 30),
            const Text('جهت گذاشتن لینک درگاه پرداخت مستقیم، اینجا کلیک کنید', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange), child: const Text('بازگشت به برنامه')),
          ]),
        ),
      ),
    );
  }
  Widget _buildGatewayIcon(String label, Color color) { return Column(children: [CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(Icons.payment, color: color)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10))]); }
}

class AdminPanel extends StatefulWidget {
  final List<Product> instaProducts, telegramProducts, otherProducts;
  final List<Winner> lotteryWinners;
  final List<PrizeRecord> prizes;
  final List<LotteryParticipant> lotteryParticipants;
  final List<OrderRecord> allOrders;
  final String bannerTitle, bannerPrize, bannerDate, insta, tele, mail;
  final Function(List<Product>, List<Product>, List<Product>, List<Winner>, List<PrizeRecord>, List<LotteryParticipant>, List<OrderRecord>, String, String, String, String, String, String) onUpdate;

  const AdminPanel({super.key, required this.instaProducts, required this.telegramProducts, required this.otherProducts, required this.lotteryWinners, required this.prizes, required this.lotteryParticipants, required this.allOrders, required this.bannerTitle, required this.bannerPrize, required this.bannerDate, required this.insta, required this.tele, required this.mail, required this.onUpdate});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late List<Product> _tempInsta, _tempTele, _tempOther;
  late List<Winner> _tempWinners;
  late List<PrizeRecord> _tempPrizes;
  late List<OrderRecord> _tempOrders;
  late TextEditingController _titleController, _prizeController, _dateController, _instController, _teleController, _mailController;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tempInsta = List.from(widget.instaProducts);
    _tempTele = List.from(widget.telegramProducts);
    _tempOther = List.from(widget.otherProducts);
    _tempWinners = List.from(widget.lotteryWinners);
    _tempPrizes = List.from(widget.prizes);
    _tempOrders = List.from(widget.allOrders);
    _titleController = TextEditingController(text: widget.bannerTitle);
    _prizeController = TextEditingController(text: widget.bannerPrize);
    _dateController = TextEditingController(text: widget.bannerDate);
    _instController = TextEditingController(text: widget.insta);
    _teleController = TextEditingController(text: widget.tele);
    _mailController = TextEditingController(text: widget.mail);
  }

  Future<void> _saveToSupabase() async {
    try {
      // 1. App Config
      await _supabase.from('app_config').upsert([
        {'key': 'lottery_banner_title', 'value': _titleController.text},
        {'key': 'lottery_banner_prize', 'value': _prizeController.text},
        {'key': 'lottery_banner_date', 'value': _dateController.text},
        {'key': 'insta_id', 'value': _instController.text},
        {'key': 'telegram_id', 'value': _teleController.text},
        {'key': 'support_email', 'value': _mailController.text},
      ], onConflict: 'key');

      // 2. Products (Clear and Sync)
      await _supabase.from('products').delete().neq('id', -1);
      await _supabase.from('products').insert(_tempInsta.map((e) => e.toJson()).toList());
      await _supabase.from('products').insert(_tempTele.map((e) => e.toJson()).toList());
      await _supabase.from('products').insert(_tempOther.map((e) => e.toJson()).toList());

      // 3. Winners
      await _supabase.from('winners').delete().neq('id', -1);
      await _supabase.from('winners').insert(_tempWinners.map((e) => e.toJson()).toList());

      // 4. Prizes
      await _supabase.from('prizes').delete().neq('id', -1);
      await _supabase.from('prizes').insert(_tempPrizes.map((e) => e.toJson()).toList());

      // 5. Orders (Update statuses only)
      for (var order in _tempOrders) {
        if (order.id != null) {
          await _supabase.from('orders').update({'status': order.status}).eq('id', order.id);
        }
      }

      if (!mounted) return;
      widget.onUpdate(_tempInsta, _tempTele, _tempOther, _tempWinners, _tempPrizes, widget.lotteryParticipants, _tempOrders, _titleController.text, _prizeController.text, _dateController.text, _instController.text, _teleController.text, _mailController.text);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمامی اطلاعات در سوپابیس همگام‌سازی شد.')));
    } catch (e) {
      debugPrint('Save Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیریت پیکو مارکت'),
        backgroundColor: Colors.orange,
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveToSupabase)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🎟 ثبت‌نام‌کنندگان قرعه‌کشی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
          if (widget.lotteryParticipants.isEmpty) const Text('هیچ ثبت‌نامی انجام نشده است.'),
          ...widget.lotteryParticipants.reversed.map((p) => Card(color: Colors.purple.withOpacity(0.05), child: ListTile(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('تماس: ${p.phone}\nتلگرام: ${p.telegram}\nتاریخ: ${p.date}')))),
          const Divider(height: 40),
          const Text('📦 لیست سفارشات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          ..._tempOrders.reversed.map((order) {
            int idx = _tempOrders.indexOf(order);
            return Card(color: Colors.blue.withOpacity(0.05), child: Column(children: [
              ListTile(title: Text('${order.userName} - ${order.productTitle}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('تماس: ${order.userPhone}\nآیدی: ${order.pageID}\nتعداد: ${order.quantity}\nدرخواست: ${order.requestDetails}\nتاریخ: ${order.date}'), isThreeLine: true, trailing: Text(order.status, style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold))),
              Padding(padding: const EdgeInsets.all(10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_statusButton(idx, "در حال انجام", Colors.blue), _statusButton(idx, "انجام شده", Colors.green), _statusButton(idx, "رد شده", Colors.red)]))
            ]));
          }),
          const Divider(height: 40),
          _buildCategoryEditSection('🛒 اینستاگرام', _tempInsta, 'insta'),
          _buildCategoryEditSection('✈️ تلگرام', _tempTele, 'tele'),
          _buildCategoryEditSection('🌐 سایر', _tempOther, 'other'),
          const Divider(height: 40),
          const Text('🎧 پشتیبانی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _instController, decoration: const InputDecoration(labelText: 'اینستاگرام')),
          TextField(controller: _teleController, decoration: const InputDecoration(labelText: 'تلگرام')),
          TextField(controller: _mailController, decoration: const InputDecoration(labelText: 'ایمیل')),
          const Divider(height: 40),
          const Text('🎁 مدیریت جوایز دوره', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._tempPrizes.asMap().entries.map((entry) => Card(child: ListTile(title: Text(entry.value.title), subtitle: Text(entry.value.amount), trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editPrize(entry.key))))),
          ElevatedButton.icon(onPressed: _addPrize, icon: const Icon(Icons.add), label: const Text('افزودن جایزه'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black)),
          const Divider(height: 40),
          const Text('🏆 مدیریت برندگان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._tempWinners.asMap().entries.map((entry) => Card(child: ListTile(title: Text(entry.value.name), subtitle: Text('${entry.value.prize} - ${entry.value.date}'), trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _editWinner(entry.key))))),
          ElevatedButton.icon(onPressed: _addWinner, icon: const Icon(Icons.add), label: const Text('افزودن برنده'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)),
          const Divider(height: 40),
          const Text('🎫 تنظیمات بنر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان بنر')),
          TextField(controller: _prizeController, decoration: const InputDecoration(labelText: 'متن جایزه')),
          TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'تاریخ قرعه‌کشی')),
        ]),
      ),
    );
  }

  Widget _buildCategoryEditSection(String title, List<Product> list, String categoryKey) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...list.asMap().entries.map((entry) => Card(child: ListTile(title: Text(entry.value.title), subtitle: Text(entry.value.price), trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editProduct(entry.key, list))))),
      ElevatedButton.icon(onPressed: () => _addProduct(list, categoryKey), icon: const Icon(Icons.add_shopping_cart), label: const Text('افزودن محصول'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black)),
    ]);
  }

  Widget _statusButton(int index, String status, Color color) { return ElevatedButton(onPressed: () => setState(() => _tempOrders[index].status = status), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 30), textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), child: Text(status)); }
  void _editWinner(int index) {
    Winner w = _tempWinners[index]; TextEditingController nCtrl = TextEditingController(text: w.name), pCtrl = TextEditingController(text: w.prize), dCtrl = TextEditingController(text: w.date);
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('ویرایش برنده'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'جایزه')), TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'تاریخ'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (nCtrl.text.isEmpty || pCtrl.text.isEmpty || dCtrl.text.isEmpty) return; setState(() => _tempWinners[index] = Winner(name: nCtrl.text, prize: pCtrl.text, date: dCtrl.text)); Navigator.pop(context); }, child: const Text('ثبت'))]));
  }
  void _addWinner() {
    TextEditingController nCtrl = TextEditingController(), pCtrl = TextEditingController(), dCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('افزودن برنده'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'جایزه')), TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'تاریخ'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (nCtrl.text.isEmpty || pCtrl.text.isEmpty || dCtrl.text.isEmpty) return; setState(() => _tempWinners.add(Winner(name: nCtrl.text, prize: pCtrl.text, date: dCtrl.text))); Navigator.pop(context); }, child: const Text('افزودن'))]));
  }
  void _editPrize(int index) {
    PrizeRecord p = _tempPrizes[index]; TextEditingController tCtrl = TextEditingController(text: p.title), aCtrl = TextEditingController(text: p.amount);
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('ویرایش جایزه'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'مبلغ'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (tCtrl.text.isEmpty || aCtrl.text.isEmpty) return; setState(() => _tempPrizes[index].title = tCtrl.text; _tempPrizes[index].amount = aCtrl.text;); Navigator.pop(context); }, child: const Text('ثبت'))]));
  }
  void _addPrize() {
    TextEditingController tCtrl = TextEditingController(), aCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('افزودن جایزه'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'مبلغ'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (tCtrl.text.isEmpty || aCtrl.text.isEmpty) return; setState(() => _tempPrizes.add(PrizeRecord(title: tCtrl.text, amount: aCtrl.text, iconCode: Icons.card_giftcard.codePoint, colorValue: Colors.orangeAccent.value))); Navigator.pop(context); }, child: const Text('افزودن'))]));
  }
  void _addProduct(List<Product> list, String category) {
    TextEditingController tCtrl = TextEditingController(), pCtrl = TextEditingController(), qCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('افزودن محصول'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'قیمت')), TextField(controller: qCtrl, decoration: const InputDecoration(labelText: 'کیفیت'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (tCtrl.text.isEmpty || pCtrl.text.isEmpty) return; setState(() => list.add(Product(title: tCtrl.text, price: pCtrl.text, quality: qCtrl.text, imageUrl: category == 'insta' ? 'https://cdn-icons-png.flaticon.com/512/174/174855.png' : (category == 'tele' ? 'https://cdn-icons-png.flaticon.com/512/2111/2111646.png' : 'https://cdn-icons-png.flaticon.com/512/174/174883.png'), category: category))); Navigator.pop(context); }, child: const Text('افزودن'))]));
  }
  void _editProduct(int index, List<Product> list) {
    Product p = list[index]; TextEditingController tCtrl = TextEditingController(text: p.title), pCtrl = TextEditingController(text: p.price);
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('ویرایش محصول'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'عنوان')), TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'قیمت'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), ElevatedButton(onPressed: () { if (tCtrl.text.isEmpty || pCtrl.text.isEmpty) return; setState(() { list[index].title = tCtrl.text; list[index].price = pCtrl.text; }); Navigator.pop(context); }, child: const Text('تایید'))]));
  }
}
