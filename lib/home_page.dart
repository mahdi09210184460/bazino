import 'package:flutter/material.dart';
import 'dart:math';

class Product {
  String title;
  String price;
  String quality;
  String imageUrl;

  Product({
    required this.title,
    required this.price,
    required this.quality,
    required this.imageUrl,
  });
}

class Winner {
  String name;
  String prize;
  String date;

  Winner({required this.name, required this.prize, required this.date});
}

class OrderRecord {
  final String userName;
  final String userPhone;
  final String productTitle;
  final String requestDetails;
  final String status;
  final String date;

  OrderRecord({
    required this.userName,
    required this.userPhone,
    required this.productTitle,
    required this.requestDetails,
    this.status = "در انتظار بررسی",
    required this.date,
  });
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

  // Admin Configuration
  final String _adminPhone = "09927891608";

  // Editable Support Info
  String _instaID = "bazino_app";
  String _telegramID = "@bazino_support";
  String _supportEmail = "support@bazino.ir";

  // Data managed by Admin
  List<Product> _instaProducts = [
    Product(title: 'فالور اینستاگرام واقعی', price: '۱۲,۰۰۰ تومان / ۱۰۰۰ عدد', quality: 'بدون ریزش - سرعت بالا', imageUrl: 'https://cdn-icons-png.flaticon.com/512/174/174855.png'),
    Product(title: 'لایک اینستاگرام', price: '۵,۰۰۰ تومان / ۱۰۰۰ عدد', quality: 'سرعت آنی - واقعی', imageUrl: 'https://cdn-icons-png.flaticon.com/512/174/174855.png'),
    Product(title: 'کامنت دلخواه اینستا', price: '۸,۰۰۰ تومان / ۱۰۰ عدد', quality: 'متن انتخابی - ایرانی', imageUrl: 'https://cdn-icons-png.flaticon.com/512/174/174855.png'),
  ];
  
  List<Winner> _lotteryWinners = [
    Winner(name: 'علی مرادی', prize: '۱,۰۰۰,۰۰۰ ت', date: '۱۴۰۲/۰۶/۰۵'),
    Winner(name: 'مریم سعیدی', prize: '۵۰۰,۰۰۰ ت', date: '۱۴۰۲/۰۵/۲۸'),
    Winner(name: 'رضا کاظمی', prize: '۲۰۰,۰۰۰ ت', date: '۱۴۰۲/۰۵/۲۱'),
  ];

  // List of all orders for Admin
  List<OrderRecord> _allOrders = [];
  
  String _lotteryBannerTitle = 'قرعه‌کشی بزرگ هفتگی بازینو';
  String _lotteryBannerPrize = 'جایزه ویژه: ۵ میلیون تومان وجه نقد';

  // Lottery Registration State
  int _lotteryStep = 0;
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _lPhoneController = TextEditingController();
  final TextEditingController _lTelegramController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          _selectedIndex == 0 
              ? 'بازینو' 
              : (_selectedIndex == 1 
                  ? 'جوایز و قرعه‌کشی'
                  : (_selectedIndex == 2
                      ? 'سفارشات من' 
                      : 'پروفایل کاربری')),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              onPressed: () {},
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
        title: const Text('پشتیبانی بازینو', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
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
          Row(
            children: [
              _buildPrizeCard('نفر اول', '۵ میلیون', Icons.looks_one, const Color(0xFFFFD700)),
              _buildPrizeCard('نفر دوم', '۲ میلیون', Icons.looks_two, const Color(0xFFC0C0C0)),
              _buildPrizeCard('نفر سوم', '۱ میلیون', Icons.looks_3, Colors.orangeAccent),
            ],
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
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  child: const Text('موعد قرعه‌کشی: جمعه ساعت ۲۱:۰۰', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            onPressed: () => setState(() => _lotteryStep = 1),
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
            onPressed: () => setState(() => _lotteryStep = 2),
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
          const Card(
            color: Colors.orangeAccent,
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Text('مبلغ ورودی: ۱۰,۰۰۰ تومان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('جوایز: ۵ میلیون نقد برای نفر اول', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('لطفاً مبلغ را به شماره کارت زیر واریز کنید:', textAlign: TextAlign.center),
          const SelectableText('۶۰۳۷ - ۹۹۷۷ - ۰۰۰۰ - ۱۱۱۱', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const Text('بنام: مدیریت بازینو'),
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
            onPressed: () {
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 10),
            Text(rank, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // --- ORDERS & OTHERS ---
  Widget _buildOrdersContent() { 
    if (_allOrders.isEmpty) {
      return const Center(child: Text('هنوز سفارشی ثبت نکرده‌اید.'));
    }
    // Filter orders for current user (simulated)
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
                  lotteryWinners: _lotteryWinners,
                  allOrders: _allOrders,
                  bannerTitle: _lotteryBannerTitle,
                  bannerPrize: _lotteryBannerPrize,
                  insta: _instaID,
                  tele: _telegramID,
                  mail: _supportEmail,
                  onUpdate: (products, winners, orders, title, prize, inst, tel, eml) {
                    setState(() {
                      _instaProducts = products;
                      _lotteryWinners = winners;
                      _allOrders = orders;
                      _lotteryBannerTitle = title;
                      _lotteryBannerPrize = prize;
                      _instaID = inst;
                      _telegramID = tel;
                      _supportEmail = eml;
                    });
                  },
                )));
              }
            },
            child: _buildInfoTile(Icons.info_outline, 'درباره برنامه', 'نسخه ۱.۰.۰ (بازینو)'),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(onPressed: () { Navigator.pop(context); }, icon: const Icon(Icons.logout), label: const Text('خروج از حساب'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) { return Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Row(children: [Icon(icon, color: Colors.orange), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])])); }

  Widget _buildStoreContent() {
    final List<Product> telegramProducts = [ Product(title: 'ممبر واقعی تلگرام', price: '۱۵,۰۰۰ تومان / ۱۰۰۰ عدد', quality: 'فعال - ایرانی', imageUrl: 'https://cdn-icons-png.flaticon.com/512/2111/2111646.png'), Product(title: 'سین پست تلگرام', price: '۲,۰۰۰ تومان / ۱۰۰۰ عدد', quality: 'سرعت بسیار بالا', imageUrl: 'https://cdn-icons-png.flaticon.com/512/2111/2111646.png'), Product(title: 'ممبر فیک کانال', price: '۷,۰۰۰ تومان / ۱۰۰۰ عدد', quality: 'ارزان - ماندگاری بالا', imageUrl: 'https://cdn-icons-png.flaticon.com/512/2111/2111646.png') ];
    final List<Product> otherProducts = [ Product(title: 'سابسکرایب یوتیوب', price: '۴۵,۰۰۰ تومان / ۱۰۰ عدد', quality: 'واقعی - بدون ریزش', imageUrl: 'https://cdn-icons-png.flaticon.com/512/174/174883.png'), Product(title: 'واچ تایم یوتیوب', price: '۹۰,۰۰۰ تومان / ۱۰۰۰ ساعت', quality: 'ایمن برای مانیتایز', imageUrl: 'https://cdn-icons-png.flaticon.com/512/174/174883.png'), Product(title: 'فالور تیک تاک', price: '۲۰,۰۰۰ تومان / ۱۰۰۰ عدد', quality: 'سرعت متوسط', imageUrl: 'https://cdn-icons-png.flaticon.com/512/3046/3046121.png') ];
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildCategorySection('خدمات اینستاگرام', _instaProducts), _buildCategorySection('خدمات تلگرام', telegramProducts), _buildCategorySection('سایر خدمات (یوتیوب و تیک‌تاک)', otherProducts), const SizedBox(height: 20)]));
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
              TextField(controller: requestCtrl, decoration: const InputDecoration(labelText: 'نوع درخواست (توضیحات)'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              if (requestCtrl.text.isEmpty) return;
              
              // Record the order for Admin
              setState(() {
                _allOrders.add(OrderRecord(
                  userName: nameCtrl.text,
                  userPhone: phoneCtrl.text,
                  productTitle: product.title,
                  requestDetails: requestCtrl.text,
                  date: DateTime.now().toString().split('.')[0], // Simple date format
                ));
              });

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGateway(
          insta: _instaID,
          tele: _telegramID,
          email: _supportEmail,
          productTitle: product.title,
          price: product.price,
        ),
      ),
    );
  }
}

// --- PAYMENT GATEWAY WIDGET ---
class PaymentGateway extends StatelessWidget {
  final String insta;
  final String tele;
  final String email;
  final String productTitle;
  final String price;

  const PaymentGateway({
    super.key,
    required this.insta,
    required this.tele,
    required this.email,
    required this.productTitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                'بـازینو',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black12, offset: Offset(2, 2))],
                ),
              ),
              const Text('فروشگاه خدمات مجازی و بازی', style: TextStyle(color: Colors.grey)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                child: Column(
                  children: [
                    Text('سفارش شما: $productTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('مبلغ: $price', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    const Divider(height: 30),
                    const Text('پشتیبانی درگاه:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text('اینستاگرام: $insta', style: const TextStyle(fontSize: 13)),
                    Text('تلگرام: $tele', style: const TextStyle(fontSize: 13)),
                    Text('ایمیل: $email', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              const Text('انتخاب درگاه پرداخت ایمن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGatewayIcon('زرین پال', Colors.yellow),
                  const SizedBox(width: 20),
                  _buildGatewayIcon('بانک ملت', Colors.red),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'جهت گذاشتن لینک درگاه پرداخت مستقیم، اینجا کلیک کنید',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange),
                child: const Text('بازگشت به برنامه'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayIcon(String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(Icons.payment, color: color)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

// --- ADMIN PANEL WIDGET ---
class AdminPanel extends StatefulWidget {
  final List<Product> instaProducts;
  final List<Winner> lotteryWinners;
  final List<OrderRecord> allOrders;
  final String bannerTitle;
  final String bannerPrize;
  final String insta;
  final String tele;
  final String mail;
  final Function(List<Product>, List<Winner>, List<OrderRecord>, String, String, String, String, String) onUpdate;

  const AdminPanel({
    super.key,
    required this.instaProducts,
    required this.lotteryWinners,
    required this.allOrders,
    required this.bannerTitle,
    required this.bannerPrize,
    required this.insta,
    required this.tele,
    required this.mail,
    required this.onUpdate,
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late List<Product> _tempProducts;
  late List<Winner> _tempWinners;
  late List<OrderRecord> _tempOrders;
  late TextEditingController _titleController;
  late TextEditingController _prizeController;
  late TextEditingController _instController;
  late TextEditingController _teleController;
  late TextEditingController _mailController;

  @override
  void initState() {
    super.initState();
    _tempProducts = List.from(widget.instaProducts);
    _tempWinners = List.from(widget.lotteryWinners);
    _tempOrders = List.from(widget.allOrders);
    _titleController = TextEditingController(text: widget.bannerTitle);
    _prizeController = TextEditingController(text: widget.bannerPrize);
    _instController = TextEditingController(text: widget.insta);
    _teleController = TextEditingController(text: widget.tele);
    _mailController = TextEditingController(text: widget.mail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیریت بازینو'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onUpdate(_tempProducts, _tempWinners, _tempOrders, _titleController.text, _prizeController.text, _instController.text, _teleController.text, _mailController.text);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📦 لیست تمامی سفارشات کاربران', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            if (_tempOrders.isEmpty) const Text('هیچ سفارشی ثبت نشده است.'),
            ..._tempOrders.reversed.map((order) => Card(
              color: Colors.blue.withOpacity(0.05),
              child: ListTile(
                title: Text('${order.userName} - ${order.productTitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('تماس: ${order.userPhone}\nدرخواست: ${order.requestDetails}\nتاریخ: ${order.date}'),
                isThreeLine: true,
                trailing: const Icon(Icons.pending_actions, color: Colors.orange),
              ),
            )),
            const Divider(height: 40),
            const Text('🛒 محصولات اینستاگرام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._tempProducts.asMap().entries.map((entry) => Card(child: ListTile(title: Text(entry.value.title), subtitle: Text(entry.value.price), trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editProduct(entry.key))))),
            const Divider(height: 40),
            const Text('🎧 مدیریت اطلاعات پشتیبانی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _instController, decoration: const InputDecoration(labelText: 'آیدی اینستاگرام')),
            TextField(controller: _teleController, decoration: const InputDecoration(labelText: 'آیدی تلگرام')),
            TextField(controller: _mailController, decoration: const InputDecoration(labelText: 'ایمیل پشتیبانی')),
            const Divider(height: 40),
            const Text('🏆 مدیریت برندگان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._tempWinners.asMap().entries.map((entry) => Card(child: ListTile(title: Text(entry.value.name), subtitle: Text('${entry.value.prize} - ${entry.value.date}'), trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _editWinner(entry.key))))),
            ElevatedButton.icon(onPressed: _addWinner, icon: const Icon(Icons.add), label: const Text('افزودن برنده جدید'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)),
            const Divider(height: 40),
            const Text('🎫 تنظیمات بنر قرعه‌کشی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان بنر')),
            TextField(controller: _prizeController, decoration: const InputDecoration(labelText: 'متن جایزه')),
          ],
        ),
      ),
    );
  }

  void _editWinner(int index) {
    Winner w = _tempWinners[index];
    TextEditingController nCtrl = TextEditingController(text: w.name);
    TextEditingController pCtrl = TextEditingController(text: w.prize);
    TextEditingController dCtrl = TextEditingController(text: w.date);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('ویرایش برنده'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'نام')),
        TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'جایزه')),
        TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'تاریخ')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
        ElevatedButton(onPressed: () { setState(() { _tempWinners[index] = Winner(name: nCtrl.text, prize: pCtrl.text, date: dCtrl.text); }); Navigator.pop(context); }, child: const Text('ثبت')),
      ],
    ));
  }

  void _addWinner() {
    TextEditingController nCtrl = TextEditingController();
    TextEditingController pCtrl = TextEditingController();
    TextEditingController dCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('افزودن برنده'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'نام')),
        TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'جایزه')),
        TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'تاریخ')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
        ElevatedButton(onPressed: () { setState(() { _tempWinners.add(Winner(name: nCtrl.text, prize: pCtrl.text, date: dCtrl.text)); }); Navigator.pop(context); }, child: const Text('افزودن')),
      ],
    ));
  }

  void _editProduct(int index) {
    Product p = _tempProducts[index];
    TextEditingController tCtrl = TextEditingController(text: p.title);
    TextEditingController pCtrl = TextEditingController(text: p.price);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('ویرایش محصول'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'عنوان')),
        TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'قیمت')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
        ElevatedButton(onPressed: () { setState(() { _tempProducts[index].title = tCtrl.text; _tempProducts[index].price = pCtrl.text; }); Navigator.pop(context); }, child: const Text('تایید')),
      ],
    ));
  }
}
