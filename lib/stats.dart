import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Statistics'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Data').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available'));
          }

          double totalAmount = 0.0;
          double paidAmount = 0.0;
          double remainingAmount = 0.0;

          // Iterate through each document in the collection
          snapshot.data!.docs.forEach((doc) {
            var data = doc.data() as Map<String, dynamic>;
            totalAmount += double.parse(data['total_price']);
            paidAmount += double.parse(data['paid_amount']);
            remainingAmount += double.parse(data['remaining_amount']);
          });

          return Padding(
            padding: EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pie chart
                AspectRatio(
                  aspectRatio: 1,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Color(0xFF474747),
                          value: totalAmount,
                          title: '\$$totalAmount',
                          radius: 70,
                          showTitle: true,
                          titleStyle: TextStyle(color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Color(0xFF787878),
                          value: paidAmount,
                          title: '\$$paidAmount',
                          radius: 70,
                          showTitle: true,
                          titleStyle: TextStyle(color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Color(0xFFadadad),
                          value: remainingAmount,
                          title: '\$$remainingAmount',
                          radius: 70,
                          showTitle: true,
                          titleStyle: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                // Text format
                SizedBox(height: 46),
            Table(
              border: TableBorder.all(), // Add border for the table
              columnWidths: {
                0: FlexColumnWidth(1), // Adjust column width as needed
                1: FlexColumnWidth(1), // Adjust column width as needed
              },
              children: [
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                        child: Text(
                          'Total Amount:',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
                        child: Text(
                          '\$$totalAmount',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                        child: Text(
                          'Paid Amount:',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
                        child: Text(
                          '\$$paidAmount',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                        child: Text(
                          'Remaining Amount:',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
                        child: Text(
                          '\$$remainingAmount',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
              ],
            ),
          );
        },
      ),
    );
  }
}
