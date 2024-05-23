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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Records'),
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
                        // Rounded button to add new record for the searched name
                        ElevatedButton(
                          onPressed: () {
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => InputData(name: _searchText)));
                          },
                          child: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
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
                            children: _recordData!.map((record) {
                              return SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Quantity: ${record['quantity']}',style: TextStyle(fontSize: 17),),
                                    Text('Price: ${record['price']}', style: TextStyle(fontSize: 17)),
                                    Text('Total Price: ${record['total_price']}', style: TextStyle(fontSize: 17)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Paid: ${record['paid_amount']}', style: TextStyle(fontSize: 17)),
                                        const SizedBox(width: 40),
                                        Text('Due: ${record['remaining_amount']}', style: TextStyle(fontSize: 17)),
                                      ],
                                    ),
                                    Text(
                                      'Date: ${DateFormat.yMMMMd().format(record['date'].toDate())}', style: TextStyle(fontSize: 17),
                                    ),
                                    Divider(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => InputData()));
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Adjust the radius as needed
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

    final querySnapshot = await FirebaseFirestore.instance
        .collection('Data')
        .where('name', isEqualTo: _searchText)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _recordFound = true;
        _recordData = querySnapshot.docs.map((doc) => doc.data()).toList();
      });
    } else {
      setState(() {
        _recordFound = false;
      });
    }
  }
}
