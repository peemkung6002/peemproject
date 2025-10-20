import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReturnHistoryPage extends StatefulWidget {
  const ReturnHistoryPage({Key? key}) : super(key: key);

  @override
  State<ReturnHistoryPage> createState() => _ReturnHistoryPageState();
}

class _ReturnHistoryPageState extends State<ReturnHistoryPage> {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('return_history');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ประวัติการคืน")),
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
            return const Center(child: Text("ไม่มีประวัติการคืน"));
          }

          final items = historyData.entries.toList();

          List<Map<String, dynamic>> itemsWithDates = items.map((e) {
            final Map<String, dynamic> record = Map<String, dynamic>.from(e.value as Map);
            DateTime? sortDate;
            if (record.containsKey('returnDate') && record['returnDate'] != null) {
              sortDate = DateTime.tryParse(record['returnDate'].toString());
            }
            if (sortDate == null) {
              int? parseTs(dynamic v) {
                if (v == null) return null;
                if (v is int) return v;
                if (v is double) return v.toInt();
                if (v is num) return v.toInt();
                if (v is String) return int.tryParse(v);
                return null;
              }
              if (record.containsKey('returnTimestamp') && record['returnTimestamp'] != null) {
                final ms = parseTs(record['returnTimestamp']);
                if (ms != null) sortDate = DateTime.fromMillisecondsSinceEpoch(ms);
              }
              if (sortDate == null && record.containsKey('timestamp') && record['timestamp'] != null) {
                final ms = parseTs(record['timestamp']);
                if (ms != null) sortDate = DateTime.fromMillisecondsSinceEpoch(ms);
              }
            }
            return {
              'key': e.key,
              'record': record,
              'sortDate': sortDate,
            };
          }).toList();

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

              String dateString = '';
              if (item['sortDate'] != null) {
                final date = item['sortDate'] as DateTime;
                dateString = "${date.day}/${date.month}/${date.year}";
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(record['productName'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ผู้คืน: ${record['borrowerName'] ?? record['userId'] ?? '-'}"),
                      Text("จำนวน: ${record['quantity'] ?? '-'}"),
                      Text("วันที่คืน: $dateString"),
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
