import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'borrow_form_page.dart';
import 'return_form_page.dart';

class BorrowableProductsPage extends StatelessWidget {
  const BorrowableProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DatabaseReference borrowableRef = FirebaseDatabase.instance.ref().child("borrowable_products");

    return Scaffold(
      appBar: AppBar(title: const Text("สินค้าสำหรับยืม")),
      body: StreamBuilder(
        stream: borrowableRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> products = {};
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            products = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          }

          if (products.isEmpty) {
            return const Center(child: Text("ไม่มีสินค้าสำหรับยืม"));
          }

          final items = products.entries.toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
        final Map<String, dynamic> product = Map<String, dynamic>.from(item.value as Map);
        final quantity = product['quantity'] is int
          ? product['quantity'] as int
          : int.tryParse(product['quantity']?.toString() ?? '') ?? 0;
        final total = product['total'] is int
          ? product['total'] as int
          : int.tryParse(product['total']?.toString() ?? '') ?? quantity;
        final borrowedCount = (total - quantity).clamp(0, total);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("ประเภท: ${product['type'] ?? '-'}"),
                      Text("ยี่ห้อ: ${product['brand'] ?? '-'}"),
                      Text("รุ่น: ${product['model'] ?? '-'}"),
                      Text("จำนวนทั้งหมด: $total"),
                      Text("จำนวนคงเหลือ: $quantity"),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Show borrow button only when there is available quantity
                          if (quantity > 0)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BorrowFormPage(
                                      productId: item.key,
                                      productData: product,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("ยืม"),
                            ),

                          // If both buttons would be present (borrow + return), add spacing.
                          if (quantity > 0 && borrowedCount > 0) const SizedBox(width: 6),

                          // Show return button only when something has been borrowed
                          if (borrowedCount > 0)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReturnFormPage(
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
    );
  }
}
