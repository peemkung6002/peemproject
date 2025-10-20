
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'edit_page.dart';
  String searchText = "";
  final TextEditingController searchController = TextEditingController();

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final DatabaseReference productRef = FirebaseDatabase.instance.ref().child("products");
  final DatabaseReference licenseRef = FirebaseDatabase.instance.ref().child("licenses");

  // Keys that have been requested for deletion but waiting for realtime update.
  // We keep them here to optimistically hide items immediately from the UI so
  // the user doesn't have to manually refresh.
  final Set<String> _pendingDeleted = {};

  // Local cached copies of data from realtime DB. We subscribe to onValue and
  // keep these maps up-to-date so we can mutate local state immediately when
  // the user deletes an item (optimistic update) without waiting for the
  // snapshot builder to fire.
  Map<String, dynamic> _productData = {};
  Map<String, dynamic> _licenseData = {};
  StreamSubscription<DatabaseEvent>? _productSub;
  StreamSubscription<DatabaseEvent>? _licenseSub;

  bool _showedExpiryAlert = false;

  String selectedFilter = "ทั้งหมด";

  @override
  void initState() {
    super.initState();
    // Subscribe to realtime updates and keep local maps in sync.
    _productSub = productRef.onValue.listen((event) {
      Map<String, dynamic> pd = {};
      if (event.snapshot.value != null) {
        pd = Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      setState(() {
        _productData = pd;
        // Clean up pendingDeleted keys that no longer exist
        final existingKeys = {
          ..._productData.keys.map((k) => k.toString()),
          ..._licenseData.keys.map((k) => k.toString())
        };
        _pendingDeleted.removeWhere((k) => !existingKeys.contains(k));
      });
    }, onError: (e, st) => debugPrint('ProductPage: productSub error $e\n$st'));

    _licenseSub = licenseRef.onValue.listen((event) {
      Map<String, dynamic> ld = {};
      if (event.snapshot.value != null) {
        ld = Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      setState(() {
        _licenseData = ld;
        final existingKeys = {
          ..._productData.keys.map((k) => k.toString()),
          ..._licenseData.keys.map((k) => k.toString())
        };
        _pendingDeleted.removeWhere((k) => !existingKeys.contains(k));
      });
    }, onError: (e, st) => debugPrint('ProductPage: licenseSub error $e\n$st'));
  }

  @override
  void dispose() {
    _productSub?.cancel();
    _licenseSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการสินค้า"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "ตัวกรอง:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: [
                    const DropdownMenuItem(value: "ทั้งหมด", child: Text("ทั้งหมด")),
                    const DropdownMenuItem(value: "สินค้า", child: Text("สินค้า")),
                    const DropdownMenuItem(value: "License", child: Text("License")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "ค้นหา...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.trim();
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Builder(builder: (context) {
                // Use local cached maps maintained by the subscriptions.
                final Map<String, dynamic> productData = Map<String, dynamic>.from(_productData);
                final Map<String, dynamic> licenseData = Map<String, dynamic>.from(_licenseData);
                      // helper to parse dd/MM/yyyy (returns null if not parseable)
                      DateTime? parseDate(String? s) {
                        if (s == null) return null;
                        final trimmed = s.trim();
                        if (trimmed.isEmpty) return null;
                        // Accept formats like d/M/yyyy or dd/MM/yyyy
                        try {
                          final parts = trimmed.split('/');
                          if (parts.length != 3) return DateTime.tryParse(trimmed);
                          final day = int.tryParse(parts[0]);
                          final month = int.tryParse(parts[1]);
                          final year = int.tryParse(parts[2]);
                          if (day == null || month == null || year == null) return null;
                          return DateTime(year, month, day);
                        } catch (_) {
                          return DateTime.tryParse(trimmed);
                        }
                      }

                      final allItems = [
                        ...productData.entries.map((e) => {
                              "key": e.key,
                              "type": "สินค้า",
                              "data": e.value,
                            }),
                        ...licenseData.entries.map((e) => {
                              "key": e.key,
                              "type": "License",
                              "data": e.value,
                            }),
                      ];
                      // Remove any keys from _pendingDeleted that are already gone
                      // from the database (so the set doesn't grow forever).
                      final existingKeys = allItems.map((e) => e["key"].toString()).toSet();
                      _pendingDeleted.removeWhere((k) => !existingKeys.contains(k));
                      // Debug info to help trace why deleted items may still appear
                      debugPrint('ProductPage: local keys=${existingKeys.toList()} pending=${_pendingDeleted.toList()}');
                      // If filtering by type, apply filter first
                      var filteredItems = selectedFilter == "ทั้งหมด"
                          ? allItems
                          : allItems.where((item) => item["type"] == selectedFilter).toList();

                      // Sort License items by endDate ascending (nearest expiry first)
                      final licenseItems = filteredItems.where((item) => item["type"] == "License").toList();
                      licenseItems.sort((a, b) {
                        final Map<String, dynamic> da = Map<String, dynamic>.from(a['data'] ?? {});
                        final Map<String, dynamic> db = Map<String, dynamic>.from(b['data'] ?? {});
                        final DateTime? ea = parseDate(da['endDate']?.toString());
                        final DateTime? eb = parseDate(db['endDate']?.toString());
                        if (ea == null && eb == null) return 0;
                        if (ea == null) return 1;
                        if (eb == null) return -1;
                        return ea.compareTo(eb);
                      });
                      final otherItems = filteredItems.where((item) => item["type"] != "License").toList();
                      filteredItems = [...licenseItems, ...otherItems];
                      // กรองด้วย searchText
                      // Exclude items that are pending deletion so they disappear
                      // from the UI immediately (optimistic update).
                      final visibleAfterPending = filteredItems.where((item) => !_pendingDeleted.contains(item["key"].toString())).toList();

                      final searchedItems = searchText.isEmpty
                          ? visibleAfterPending
                          : visibleAfterPending.where((item) {
                              final rawData = item["data"];
                              Map<String, dynamic> data;
                              if (rawData is Map<String, dynamic>) {
                                data = rawData;
                              } else if (rawData is Map) {
                                data = Map<String, dynamic>.from(rawData);
                              } else {
                                return false;
                              }
                              final values = data.values.map((v) => v?.toString().toLowerCase() ?? "").join(" ");
                              return values.contains(searchText.toLowerCase());
                            }).toList();

                      // Check for licenses expiring within 30 days and show popup once
                      if (!_showedExpiryAlert) {
                        final now = DateTime.now();
                        final expiring = <Map<String, dynamic>>[];
                        licenseData.forEach((key, raw) {
                          Map<String, dynamic> ld;
                          if (raw is Map<String, dynamic>) {
                            ld = raw;
                          } else if (raw is Map) {
                            ld = Map<String, dynamic>.from(raw);
                          } else {
                            return;
                          }
                          final end = parseDate(ld['endDate']?.toString());
                          if (end != null) {
                            final diff = end.difference(now).inDays;
                            if (diff >= 0 && diff <= 30) {
                              expiring.add({
                                'key': key,
                                'licenseName': ld['licenseName'] ?? '',
                                'endDate': end,
                                'daysLeft': diff,
                              });
                            }
                          }
                        });
                        if (expiring.isNotEmpty) {
                          // sort ascending by daysLeft just in case
                          expiring.sort((a, b) => (a['endDate'] as DateTime).compareTo(b['endDate'] as DateTime));
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('แจ้งเตือน License ใกล้หมดอายุ'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: expiring.length,
                                      itemBuilder: (c, i) {
                                        final e = expiring[i];
                                        final name = e['licenseName'] ?? '';
                                        final endDate = e['endDate'] as DateTime;
                                        final daysLeft = e['daysLeft'];
                                        return ListTile(
                                          dense: true,
                                          title: Text(name),
                                          subtitle: Text('หมดอายุ: ${endDate.day}/${endDate.month}/${endDate.year} — เหลือ $daysLeft วัน'),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
                                  ],
                                ),
                              );
                              _showedExpiryAlert = true;
                            }
                          });
                        }
                      }
                      // counts are derived from maps when needed below
                      // If both maps are empty, show no-data state
                      if (productData.isEmpty && licenseData.isEmpty) {
                        return const Center(child: Text("ไม่มีข้อมูลในระบบ"));
                      }
                
                // Reuse the existing rendering logic below by returning the
                // Column built from searchedItems (same as before).
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        selectedFilter == "ทั้งหมด"
                            ? "จำนวนทั้งหมด: ${productData.length + licenseData.length} รายการ"
                            : selectedFilter == "สินค้า"
                                ? "จำนวนสินค้า: ${productData.length} รายการ"
                                : "จำนวน License: ${licenseData.length} รายการ",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: searchedItems.isEmpty
                          ? const Center(child: Text("ไม่พบข้อมูลที่ค้นหา"))
                          : ListView.builder(
                              itemCount: searchedItems.length,
                              itemBuilder: (context, index) {
                                final item = searchedItems[index];
                                final Map<String, dynamic> product =
                                    Map<String, dynamic>.from(item["data"] as Map);
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    title: () {
                                      if (item["type"] == "License") {
                                        // determine if this license is expiring within 30 days
                                        final endDate = parseDate(product['endDate']?.toString());
                                        bool isExpiring = false;
                                        if (endDate != null) {
                                          final diff = endDate.difference(DateTime.now()).inDays;
                                          if (diff >= 0 && diff <= 30) isExpiring = true;
                                        }
                                        return Text(
                                          "🔑 License: " + (product['licenseName'] ?? ''),
                                          style: TextStyle(fontWeight: FontWeight.bold, color: isExpiring ? Colors.red : null),
                                        );
                                      }
                                      return Text("🖥️ " + (product['name'] ?? ''), style: const TextStyle(fontWeight: FontWeight.bold));
                                    }(),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (item["type"] != "License" && (product['imageUrl'] ?? '').isNotEmpty) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: SizedBox(
                                              height: 120,
                                              child: Image.network(
                                                product['imageUrl'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Text("ไม่พบรูปภาพ"),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (item["type"] == "License") ...[
                                          Text("เริ่มใช้: ${product['startDate'] ?? '-'}"),
                                          Text("หมดอายุ: ${product['endDate'] ?? '-'}"),
                                          Text("รายละเอียด: ${product['description'] ?? '-'}"),
                                          Text("Key: ${product['key'] ?? '-'}"),
                                        ] else ...[
                                          Text("ประเภท: ${product['type'] ?? '-'}"),
                                          Text("ยี่ห้อ: ${product['brand'] ?? '-'}"),
                                          Text("รุ่น: ${product['model'] ?? '-'}"),
                                          Text("Serial: ${product['serialNumber'] ?? '-'}"),
                                          Text("ราคา: ${product['price'] ?? '-'}"),
                                          Text("วันมาถึง: ${product['arriveDate'] ?? '-'}"),
                                          Text("วันหมดอายุ: ${product['endDate'] ?? '-'}")
                                        ]
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditPage(
                                                  itemKey: item["key"],
                                                  itemType: item["type"],
                                                  itemData: Map<String, dynamic>.from(item["data"] ?? {}),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () async {
                                            bool? confirm = await showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text("ยืนยันการลบ"),
                                                content: const Text("แน่ใจว่าต้องการลบรายการนี้?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text("ยกเลิก"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text("ลบ"),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              final String delKey = item["key"].toString();
                                              debugPrint('ProductPage: request delete key=$delKey type=${item["type"]}');
                                              // Optimistic UI: hide the item immediately
                                              setState(() {
                                                _pendingDeleted.add(delKey);
                                                // Also remove from local map immediately for snappier UI
                                                if (item["type"] == "License") {
                                                  _licenseData.remove(delKey);
                                                } else {
                                                  _productData.remove(delKey);
                                                }
                                              });
                                              try {
                                                if (item["type"] == "License") {
                                                  await licenseRef.child(item["key"]).remove();
                                                } else {
                                                  await productRef.child(item["key"]).remove();
                                                }
                                                if (!mounted) return;
                                                setState(() {});
                                                debugPrint('ProductPage: delete succeeded key=$delKey');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("ลบข้อมูลเรียบร้อย ✅")),
                                                );
                                              } catch (e, st) {
                                                debugPrint('ProductPage: delete failed key=$delKey error=$e\n$st');
                                                setState(() {
                                                  _pendingDeleted.remove(delKey);
                                                  // If delete failed, we won't have the original data here; trigger a reload via listeners (they should bring item back)
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("ไม่สามารถลบได้: $e")),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}