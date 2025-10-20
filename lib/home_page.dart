import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth.dart';
import 'product_page.dart';
import 'addproduct.dart';
import 'add_borrowable_product.dart';
import 'borrow_form_page.dart';
import 'return_form_page.dart';
import 'borrow_history_page.dart';
import 'return_history_page.dart';
import 'signin_page.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/homepage';
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  late DatabaseReference _userRef;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _userRef = FirebaseDatabase.instance.ref().child(
        'projectpeem/${user.uid}',
      );
      _fetchUserData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final snapshot = await _userRef.get();
      if (snapshot.exists) {
        if (!mounted) return;
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
        });
      } else {
        _userData = null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _userData = null;
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final DatabaseReference borrowableRef = FirebaseDatabase.instance
        .ref()
        .child("borrowable_products");

    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _userData?['prefix'] != null
                    ? '${_userData!['prefix']} ${_userData!['firstName']} ${_userData!['lastName']}'
                    : 'ผู้ใช้: User',
              ),
              accountEmail: Text(_auth.currentUser?.email ?? 'อีเมล: Email'),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    _userData?['profileImage'] != null
                        ? NetworkImage(_userData!['profileImage'])
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                child:
                    _userData?['profileImage'] == null
                        ? const Icon(Icons.person)
                        : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('เพิ่มสินค้าใหม่'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('เพิ่มสินค้าสำหรับยืม'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddBorrowableProductPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('ดูรายการสินค้า'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('ประวัติการยืม'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BorrowHistoryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('ประวัติการคืน'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReturnHistoryPage(),
                  ),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ออกจากระบบ: Logout'),
              onTap: () async {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginPage.routeName,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'สินค้าสำหรับยืม',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: borrowableRef.onValue,
              builder: (context, snapshot) {
                Map<String, dynamic> products = {};

                if (snapshot.hasData && snapshot.data is DatabaseEvent) {
                  final event = snapshot.data as DatabaseEvent;
                  if (event.snapshot.value != null) {
                    products = Map<String, dynamic>.from(
                      event.snapshot.value as Map,
                    );
                  }
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล"),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (products.isEmpty) {
                  return const Center(child: Text("ไม่มีสินค้าสำหรับยืม"));
                }

                final items = products.entries.toList();

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final Map<String, dynamic> product =
                        Map<String, dynamic>.from(item.value as Map);

                    final rawQuantity = product['quantity'];
                    final quantity =
                        rawQuantity is int
                            ? rawQuantity
                            : int.tryParse(rawQuantity?.toString() ?? '0') ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("ประเภท: ${product['type'] ?? '-'}"),
                            Text("ยี่ห้อ: ${product['brand'] ?? '-'}"),
                            Text("รุ่น: ${product['model'] ?? '-'}"),
                            // Serial removed per request
                            Text("จำนวนคงเหลือ: $quantity"),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // ปุ่มยืม → สีเขียว
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed:
                                      quantity > 0
                                          ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => BorrowFormPage(
                                                      productId: item.key,
                                                      productData: product,
                                                    ),
                                              ),
                                            );
                                          }
                                          : null,
                                  child: const Text("ยืม"),
                                ),
                                const SizedBox(width: 8),
                                // ปุ่มคืน → สีแดง
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ReturnFormPage(
                                              productId: item.key,
                                              productData: product,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text("คืน"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
