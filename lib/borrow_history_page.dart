import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({Key? key}) : super(key: key);

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('borrow_history');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ประวัติการยืม")),
      body: StreamBuilder(
        stream: _historyRef.onValue,
        builder: (context, snapshot) {
          Map<String, dynamic> historyData = {};

          if (snapshot.hasData && snapshot.data is DatabaseEvent) {
            final event = snapshot.data as DatabaseEvent;
            if (event.snapshot.value != null) {
              historyData = Map<String, dynamic>.from(event.snapshot.value as Map);
            }
          }

          if (snapshot.hasError) {
            return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (historyData.isEmpty) {
            return const Center(child: Text("ไม่มีประวัติการยืม"));
          }

          final items = historyData.entries.toList();

          // Map entries to include a parsed sort date (prefer borrowDate, then timestamps)
          List<Map<String, dynamic>> itemsWithDates = items.map((e) {
            final Map<String, dynamic> record = Map<String, dynamic>.from(e.value as Map);
            DateTime? sortDate;
            if (record.containsKey('borrowDate') && record['borrowDate'] != null) {
              sortDate = DateTime.tryParse(record['borrowDate'].toString());
            }
            if (sortDate == null) {
              // helper to parse numeric-ish timestamp values robustly
              int? parseTs(dynamic v) {
                if (v == null) return null;
                if (v is int) return v;
                if (v is double) return v.toInt();
                if (v is num) return v.toInt();
                if (v is String) return int.tryParse(v);
                return null;
              }

              if (record.containsKey('borrowTimestamp') && record['borrowTimestamp'] != null) {
                final ms = parseTs(record['borrowTimestamp']);
                if (ms != null) {
                  sortDate = DateTime.fromMillisecondsSinceEpoch(ms);
                }
              }
              if (sortDate == null && record.containsKey('timestamp') && record['timestamp'] != null) {
                final ms = parseTs(record['timestamp']);
                if (ms != null) {
                  sortDate = DateTime.fromMillisecondsSinceEpoch(ms);
                }
              }
            }
            return {
              'key': e.key,
              'record': record,
              'sortDate': sortDate,
            };
          }).toList();

          // Sort descending (most recent first). Null dates go to the end.
          itemsWithDates.sort((a, b) {
            final DateTime? da = a['sortDate'] as DateTime?;
            final DateTime? db = b['sortDate'] as DateTime?;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });

          return ListView.builder(
            itemCount: itemsWithDates.length,
            itemBuilder: (context, index) {
              final item = itemsWithDates[index];
              final Map<String, dynamic> record = Map<String, dynamic>.from(item['record'] as Map);

              // Determine borrow date: prefer explicit 'borrowDate' (ISO string) saved by the form,
              // otherwise fall back to server 'timestamp' (ms since epoch).
              String dateString = '-';
              if (record.containsKey('borrowDate') && record['borrowDate'] != null) {
                final raw = record['borrowDate'].toString();
                final parsed = DateTime.tryParse(raw);
                if (parsed != null) {
                  dateString = "${parsed.day}/${parsed.month}/${parsed.year}";
                } else {
                  dateString = raw;
                }
              } else if (record.containsKey('borrowTimestamp') && record['borrowTimestamp'] != null) {
                try {
                  final d = DateTime.fromMillisecondsSinceEpoch(record['borrowTimestamp'] as int);
                  dateString = "${d.day}/${d.month}/${d.year}";
                } catch (_) {}
              } else if (record.containsKey('timestamp') && record['timestamp'] != null) {
                try {
                  final date = DateTime.fromMillisecondsSinceEpoch(record['timestamp'] as int);
                  dateString = "${date.day}/${date.month}/${date.year}";
                } catch (_) {}
              }

              // determine due/return date (support different field names/formats)
              String dueDateString = '-';
              // 1) expectedReturnDate (ISO string) from borrow form
              if (record.containsKey('expectedReturnDate') && record['expectedReturnDate'] != null) {
                final raw = record['expectedReturnDate'].toString();
                final parsed = DateTime.tryParse(raw);
                if (parsed != null) {
                  dueDateString = "${parsed.day}/${parsed.month}/${parsed.year}";
                } else {
                  dueDateString = raw;
                }
              }
              // 2) expectedReturnTimestamp (ms since epoch)
              else if (record.containsKey('expectedReturnTimestamp') && record['expectedReturnTimestamp'] != null) {
                try {
                  final d = DateTime.fromMillisecondsSinceEpoch(record['expectedReturnTimestamp'] as int);
                  dueDateString = "${d.day}/${d.month}/${d.year}";
                } catch (_) {}
              }
              // 3) legacy names: dueTimestamp or dueDate
              else if (record.containsKey('dueTimestamp') && record['dueTimestamp'] != null) {
                try {
                  final d = DateTime.fromMillisecondsSinceEpoch(record['dueTimestamp'] as int);
                  dueDateString = "${d.day}/${d.month}/${d.year}";
                } catch (_) {}
              } else if (record.containsKey('dueDate') && record['dueDate'] != null) {
                final raw = record['dueDate'].toString();
                if (raw.contains('/')) {
                  dueDateString = raw;
                } else {
                  final d = DateTime.tryParse(raw);
                  if (d != null) dueDateString = "${d.day}/${d.month}/${d.year}";
                  else dueDateString = raw;
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(record['productName'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ผู้ยืม: ${record['borrowerName'] ?? record['userId'] ?? '-'}"),
                      Text("จำนวน: ${record['quantity'] ?? '-'}"),
                      Text("วันที่ยืม: $dateString"),
                      Text("วันที่จะคืน: $dueDateString"),
                      if (record.containsKey('details') && (record['details']?.toString().trim().isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text("รายละเอียด: ${record['details']}", style: const TextStyle(fontStyle: FontStyle.italic)),
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
