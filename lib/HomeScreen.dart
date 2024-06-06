// overflow error


import 'package:company/stats.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'InputData.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isSearching = false;
  bool _recordFound = false;
  List<Map<String, dynamic>>? _recordData;

  Future<void> _deleteRecord(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('Data').doc(documentId).delete();
      print('Record deleted successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record deleted successfully')),
      );

      // Remove the deleted record from the local list and update the state
      setState(() {
        _recordData = _recordData?.where((record) => record['id'] != documentId).toList();

        // If _recordData is empty, set _recordFound to false
        if (_recordData == null || _recordData!.isEmpty) {
          _recordFound = false;
        }
      });
    } catch (error) {
      print('Error deleting record: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete record')),
      );
    }
  }


  Future<void> _editRecord(Map<String, dynamic> record) async {
    TextEditingController totalPriceController = TextEditingController(text: record['total_price'].toString());
    TextEditingController paidAmountController = TextEditingController(text: record['paid_amount'].toString());
    TextEditingController remainingAmountController = TextEditingController(text: record['remaining_amount'].toString());

    // Function to update remaining amount
    void _updateRemainingAmount() {
      double totalPrice = double.tryParse(totalPriceController.text) ?? 0;
      double paidAmount = double.tryParse(paidAmountController.text) ?? 0;
      double remainingAmount = totalPrice - paidAmount;
      remainingAmountController.text = remainingAmount.toStringAsFixed(2); // Keep 2 decimal places
    }

    // Add listeners to update remaining amount
    totalPriceController.addListener(_updateRemainingAmount);
    paidAmountController.addListener(_updateRemainingAmount);

    // Initial calculation of remaining amount
    _updateRemainingAmount();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
          title: Text('Edit Record'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: totalPriceController,
                  decoration: InputDecoration(labelText: 'Total Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: paidAmountController,
                  decoration: InputDecoration(labelText: 'Paid Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: remainingAmountController,
                  decoration: InputDecoration(labelText: 'Unpaid Amount'),
                  keyboardType: TextInputType.number,
                  enabled: false, // Disable editing
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Save',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('Data').doc(record['id']).update({
                    'total_price': totalPriceController.text, // Store as string
                    'paid_amount': paidAmountController.text, // Store as string
                    'remaining_amount': remainingAmountController.text, // Store as string
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Record updated successfully')),
                  );
                  Navigator.of(context).pop();
                  _searchForRecord(); // Refresh the search result
                } catch (error) {
                  print('Error updating record: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update record')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Records'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black54,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: AssetImage('assets/images/character.png'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Company App',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.search, color: Colors.grey[600],),
              title: Text('S E A R C H', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold, color: Colors.grey[600])),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.add,color: Colors.grey[600],),
              title: Text('R E G I S T E R', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold, color: Colors.grey[600])),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => InputData()));
              },
            ),
            ListTile(
              leading: Icon(Icons.addchart_rounded,color: Colors.grey[600],),
              title: Text('S T A T I S T I C S', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold, color: Colors.grey[600])),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen()));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.search, color: Colors.white),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.white),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        _searchForRecord();
                      },
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            // Show search result
        if (_isSearching)
    _recordFound
        ? Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/images/character.png', width: 250, height: 180),
              IconButton(onPressed: (){}, icon: Icon(Icons.add, color: Colors.black, size: 30,)),
            ],
          ),

          Card(
            color: Color.fromRGBO(255, 255, 238, 1.0),
            child: ListTile(
              title: Center(
                child: Text(
                  'Name: ${_recordData![0]['name']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _recordData!.asMap().entries.map((entry) {
                    int index = entry.key;
                    var record = entry.value;
                    bool isPaid = double.parse(record['remaining_amount']) == 0;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child: Text(
                                  '${index + 1}.',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 20),
                                ),
                              ),

                              SizedBox(width: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaid ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      isPaid ? 'Paid' : 'Unpaid',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  IconButton(onPressed: () {
                                    _editRecord(record);
                                  }, icon: Icon(Icons.edit, color: Colors.grey[600], size: 22,)),
                                ],
                              ),

                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Quantity: ${record['quantity']}',style: TextStyle(fontSize: 17),),
                              Row(
                                children: [
                                  IconButton(onPressed: () {
                                    _deleteRecord(record['id']);
                                  }, icon: Icon(Icons.delete_forever_rounded, color: Colors.grey[600], size: 22,)),
                                ],
                              ),
                            ],
                          ),
                          Text('Price: ${record['price']}', style: TextStyle(fontSize: 17)),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text('${record['total_price']}', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                                    Text('Total Amt', style: TextStyle(fontSize: 15,color: Colors.grey[500])),
                                  ],
                                ),
                                SizedBox(width: 40,),
                                Column(
                                  children: [
                                    Text('${record['paid_amount']}', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                                    Text('Paid', style: TextStyle(fontSize: 15,color: Colors.grey[500])),
                                  ],
                                ),
                                const SizedBox(width: 40),
                                Column(
                                  children: [
                                    Text('${record['remaining_amount']}', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                                    Text('Due', style: TextStyle(fontSize: 15,color: Colors.grey[500])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                    Text(
                    'Date: ${DateFormat.yMMMMd().add_jm().format(record['date'].toDate())}',
                    style: TextStyle(fontSize: 17),
                    ),

                    Text('--------------------------------------------------', style: TextStyle(fontSize: 17),),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        : const Text('Record not found'),

    ],
        ),
      ),
    );
  }

  Future<void> _searchForRecord() async {
    setState(() {
      _isSearching = true;
      _recordFound = false;
      _recordData = null;
    });

    // Trim spaces from the search query
    final searchTextTrimmed = _searchText.trim().toLowerCase();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('Data')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      List<Map<String, dynamic>> filteredRecords = [];
      querySnapshot.docs.forEach((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String name = data['name'].toString().toLowerCase().trim(); // Convert to lowercase and trim spaces
        if (name.contains(searchTextTrimmed)) {
          data['id'] = doc.id; // Add document ID to the data map
          filteredRecords.add(data);
        }
      });

      if (filteredRecords.isNotEmpty) {
        setState(() {
          _recordFound = true;
          _recordData = filteredRecords;
        });
      } else {
        setState(() {
          _recordFound = false;
        });
      }
    } else {
      setState(() {
        _recordFound = false;
      });
    }
  }
}
