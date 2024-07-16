import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final String recordId;

  TransactionHistoryScreen({required this.recordId});

  Future<Map<String, dynamic>> _fetchRecordDetails() async {
    var doc = await FirebaseFirestore.instance.collection('Data').doc(recordId).get();
    return doc.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    var doc = await FirebaseFirestore.instance.collection('Data').doc(recordId).get();
    return List<Map<String, dynamic>>.from(doc['transactions'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchRecordDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var record = snapshot.data!;
          String totalAmount = record['total_price'] ?? '0.00';
          String remainingAmount = record['remaining_amount'] ?? '0.00';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Amount: $totalAmount', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Remaining Amount: $remainingAmount', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchTransactions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.data!.isEmpty) {
                      return Center(child: Text('No transactions found.'));
                    }

                    var transactions = snapshot.data!;

                    return ListView.separated(
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        var transaction = transactions[index];
                        String description = transaction['description'].isNotEmpty
                            ? transaction['description']
                            : '  -';
                        DateTime timestamp = (transaction['timestamp'] as Timestamp).toDate();
                        String formattedDateTime = '${timestamp.toLocal().toString().split(' ')[0]}  ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                        return ListTile(
                          title: Text('Amount: ${transaction['amount']}'),
                          subtitle: Text('Date: $formattedDateTime\nDescription: $description'),
                          trailing: Icon(Icons.arrow_forward_ios),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
