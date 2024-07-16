import 'dart:io';
import 'package:company/stats.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'InputData.dart';
import 'PdfViewerScreen.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Do you really want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('Data')
            .doc(documentId)
            .delete();
        print('Record deleted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record deleted successfully')),
        );

        // Remove the deleted record from the local list and update the state
        setState(() {
          _recordData = _recordData
              ?.where((record) => record['id'] != documentId)
              .toList();

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
  }

  Future<void> _editRecord(Map<String, dynamic> record) async {
    TextEditingController totalPriceController =
        TextEditingController(text: record['total_price'].toString());
    TextEditingController paidAmountController =
        TextEditingController(text: record['paid_amount'].toString());
    TextEditingController remainingAmountController =
        TextEditingController(text: record['remaining_amount'].toString());

    // Function to update remaining amount
    void _updateRemainingAmount() {
      double totalPrice = double.tryParse(totalPriceController.text) ?? 0;
      double paidAmount = double.tryParse(paidAmountController.text) ?? 0;
      double remainingAmount = totalPrice - paidAmount;
      remainingAmountController.text =
          remainingAmount.toStringAsFixed(2); // Keep 2 decimal places
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
                  await FirebaseFirestore.instance
                      .collection('Data')
                      .doc(record['id'])
                      .update({
                    'total_price': totalPriceController.text, // Store as string
                    'paid_amount': paidAmountController.text, // Store as string
                    'remaining_amount':
                        remainingAmountController.text, // Store as string
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

  Future<void> uploadPdfToStorage(String documentId, File pdfFile) async {
    // Create a reference to the Firebase Storage
    final storageRef = FirebaseStorage.instance.ref();

    // Define the path for the PDF file
    final pdfRef = storageRef.child('pdfs/$documentId.pdf');

    // Upload the file
    await pdfRef.putFile(pdfFile);

    // Get the download URL
    String downloadUrl = await pdfRef.getDownloadURL();

    // Update the Firestore document with the PDF URL
    await FirebaseFirestore.instance.collection('Data').doc(documentId).update({
      'pdfUrl': downloadUrl,
    });
  }

  Future<File?> pickPdf() async {
    // Use the file picker to select a PDF
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    // Check if a file was picked
    if (result != null && result.files.isNotEmpty) {
      // Return the picked file
      return File(result.files.single.path!);
    }

    // Return null if no file was picked
    return null;
  }

  Future<String> downloadPdf(String url) async {
    var response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/your_file_name.pdf");
    await file.writeAsBytes(response.data);
    return file.path; // Return the local file path
  }

  Future<void> openPdf(BuildContext context, String documentId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('Data')
        .doc(documentId)
        .get();

    if (snapshot.exists) {
      String? pdfUrl = snapshot['pdfUrl'];

      if (pdfUrl != null) {
        String localPath = await downloadPdf(pdfUrl);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PdfViewerScreen(pdfUrl: localPath)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No PDF found for this record')),
        );
      }
    }
  }

  Future<void> _fetchRecordData(String recordId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Data').doc(recordId).get();
    if (snapshot.exists) {
      setState(() {
        // Find the index of the record to update
        int index = _recordData!.indexWhere((record) => record['id'] == recordId);
        if (index != -1) {
          _recordData![index] = snapshot.data() as Map<String, dynamic>;
        }
      });
    }
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
                    backgroundImage: AssetImage('assets/images/logo.png'),
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
              leading: Icon(
                Icons.search,
                color: Colors.grey[600],
              ),
              title: Text('S E A R C H',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600])),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.add,
                color: Colors.grey[600],
              ),
              title: Text('R E G I S T E R',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600])),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => InputData()));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.addchart_rounded,
                color: Colors.grey[600],
              ),
              title: Text('S T A T I S T I C S',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600])),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StatisticsScreen()));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
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
                              Image.asset('assets/images/character.png',
                                  width: 250, height: 180),
                              IconButton(
                                  onPressed: () {
                                    // want to pass the name to the input data screen
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => InputData(
                                                name: _recordData![0]
                                                    ['name'])));
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    color: Colors.black,
                                    size: 30,
                                  )),
                            ],
                          ),
                          Card(
                            color: Color.fromRGBO(255, 255, 238, 1.0),
                            child: ListTile(
                              title: Center(
                                child: Text(
                                  'Name: ${_recordData![0]['name']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      _recordData!.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var record = entry.value;
                                    bool isPaid = double.parse(
                                            record['remaining_amount']) ==
                                        0;

                                    return SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              // Text number on the left
                                              Container(
                                                child: Text(
                                                  '${index + 1}.',
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20),
                                                ),
                                              ),

                                              // Spacer to push the image to the center
                                              Expanded(
                                                child: Center(
                                                  child: Container(
                                                    width:
                                                        70, // Width of the circular container
                                                    height:
                                                        70, // Height of the circular container
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape
                                                          .circle, // Makes the container circular
                                                      border: Border.all(
                                                          color: Colors.grey,
                                                          width:
                                                              2), // Circular border
                                                    ),
                                                    child: ClipOval(
                                                      // Clips the image to be circular
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12.0),
                                                        child: Image.asset(
                                                          record['category'] ==
                                                                  'Gloves'
                                                              ? 'assets/images/g1.png' // Path to gloves image
                                                              : 'assets/images/c3.png', // Path to cotton image
                                                          width: 40,
                                                          height: 40,
                                                          fit: BoxFit
                                                              .cover, // Ensures the image covers the circular area
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Icons on the rightmost side
                                              SizedBox(width: 10),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isPaid
                                                          ? Colors.green
                                                          : Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              60),
                                                    ),
                                                    child: Icon(
                                                      isPaid
                                                          ? Icons.check
                                                          : Icons
                                                              .close, // Check icon for paid, close icon for unpaid
                                                      color: Colors.white,
                                                      size:
                                                          20, // Adjust size as needed
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // Row(
                                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          //   children: [
                                          //     Text('Quantity: ${record['quantity']}',style: TextStyle(fontSize: 17),),
                                          //     Row(
                                          //       children: [
                                          //         IconButton(
                                          //         padding: EdgeInsets.zero,
                                          //           onPressed: () {
                                          //             _editRecord(record);
                                          //           },
                                          //           icon: Icon(Icons.edit, color: Colors.grey[600], size: 22),
                                          //         ),
                                          //         // IconButton(
                                          //         //   onPressed: () {
                                          //         //     _deleteRecord(record['id']);
                                          //         //   },
                                          //         //   icon: Icon(Icons.delete_forever_rounded, color: Colors.grey[600], size: 22),
                                          //         // ),
                                          //       ],
                                          //     ),
                                          //
                                          //   ],
                                          // ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  'Quantity: ${record['quantity']}',
                                                  style:
                                                      TextStyle(fontSize: 17)),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      _editRecord(record);
                                                    },
                                                    icon: Icon(Icons.edit,
                                                        color: Colors.grey[600],
                                                        size: 22),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      _deleteRecord(
                                                          record['id']);
                                                    },
                                                    icon: Icon(
                                                        Icons
                                                            .delete_forever_rounded,
                                                        color: Colors.grey[600],
                                                        size: 22),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  'Weight: ${record['weight']}',
                                                  style: TextStyle(fontSize: 17)),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () async {
                                                      // Use the current record's ID
                                                      String documentId = record['id'];

                                                      if (record.containsKey('pdfUrl')) {
                                                        // PDF already uploaded, open it
                                                        openPdf(context, documentId);
                                                      } else {
                                                        File? pdfFile = await pickPdf();
                                                        if (pdfFile != null) {
                                                          await uploadPdfToStorage(documentId, pdfFile);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('PDF uploaded successfully')),
                                                          );
                                                          // Fetch the updated data for the specific record
                                                          await _fetchRecordData(documentId);

                                                        }
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.picture_as_pdf,
                                                      color: record.containsKey('pdfUrl') ? Colors.green : Colors.red,
                                                      size: 22,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {},
                                                    icon: Icon(Icons.history,
                                                        color: Colors.grey[600],
                                                        size: 22),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 4),
                                          Text('Price: ${record['price']}',
                                              style: TextStyle(fontSize: 17)),
                                          const SizedBox(height: 6),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Column(
                                                  children: [
                                                    Text(
                                                        '₹${record['total_price']}',
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    Text('Total Amt',
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            color: Colors
                                                                .grey[500])),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                ),
                                                Column(
                                                  children: [
                                                    Text(
                                                        '₹${record['paid_amount']}',
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.green)),
                                                    Text('Paid',
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            color: Colors
                                                                .grey[500])),
                                                  ],
                                                ),
                                                const SizedBox(width: 40),
                                                Column(
                                                  children: [
                                                    Text(
                                                        '₹${record['remaining_amount']}',
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.red)),
                                                    Text('Due',
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            color: Colors
                                                                .grey[500])),
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

                                          Text(
                                            '--------------------------------------------------',
                                            style: TextStyle(fontSize: 17),
                                          ),
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
    // Trim spaces from the search query
    final searchTextTrimmed = _searchText.trim().toLowerCase();

    // Check if the search text is empty
    if (searchTextTrimmed.isEmpty) {
      // Show a message indicating that the name field cannot be empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a name to search.'),
        ),
      );
      return; // Exit the method without performing the search
    }
    setState(() {
      _isSearching = true;
      _recordFound = false;
      _recordData = null;
    });

    final querySnapshot =
        await FirebaseFirestore.instance.collection('Data').get();

    if (querySnapshot.docs.isNotEmpty) {
      List<Map<String, dynamic>> filteredRecords = [];
      querySnapshot.docs.forEach((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String name = data['name']
            .toString()
            .toLowerCase()
            .trim(); // Convert to lowercase and trim spaces
        if (name == searchTextTrimmed) {
          data['id'] = doc.id; // Add document ID to the data map

          // Ensure numeric values for calculations
          data['paid_amount'] =
              double.tryParse(data['paid_amount'])?.toStringAsFixed(2) ?? '0.0';
          data['remaining_amount'] =
              double.tryParse(data['remaining_amount'])?.toStringAsFixed(2) ??
                  '0.0';

          filteredRecords.add(data);
        }
      });

      if (filteredRecords.isNotEmpty) {
        // Sort the filtered records by date
        filteredRecords.sort((a, b) => a['date'].compareTo(b['date']));

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
