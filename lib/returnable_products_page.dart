import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'return_form_page.dart';

class ReturnableProductsPage extends StatelessWidget {
  const ReturnableProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DatabaseReference borrowHistoryRef = FirebaseDatabase.instance.ref().child("borrow_history");
    final DatabaseReference productsRef = FirebaseDatabase.instance.ref().child("borrowable_products");

    return Scaffold(
      appBar: AppBar(title: const Text("คืนสินค้า")),
      body: StreamBuilder(
        stream: borrowHistoryRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> borrowHistory = {};
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            borrowHistory = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          }

          if (borrowHistory.isEmpty) {
            return const Center(child: Text("ยังไม่มีสินค้าที่ถูกยืม"));
          }

          // เก็บ productId ล่าสุดที่ถูกยืม
          final items = borrowHistory.entries.toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final borrowItem = items[index];
              final data = Map<String, dynamic>.from(borrowItem.value as Map);
              final productId = data['productId'] ?? '';
              final borrower = data['borrower'] ?? '';
              final productName = data['productName'] ?? '';

              return FutureBuilder(
                future: productsRef.child(productId).get(),
                builder: (context, snapshot2) {
                  if (snapshot2.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text("โหลดข้อมูลสินค้า..."));
                  }
                  if (!snapshot2.hasData || snapshot2.data!.value == null) {
                    return const ListTile(title: Text("ไม่พบข้อมูลสินค้า"));
                  }

                  final product = Map<String, dynamic>.from(snapshot2.data!.value as Map);
                  final quantity = product['quantity'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("ยืมโดย: $borrower\nจำนวนคงเหลือ: $quantity"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReturnFormPage(
                                productId: productId,
                                productData: product,
                              ),
                            ),
                          );
                        },
                        child: const Text("คืน"),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
