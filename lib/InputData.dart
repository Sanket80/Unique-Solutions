import 'package:company/Widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InputData extends StatefulWidget {
  final String? name;
  const InputData({Key? key , this.name}) : super(key: key);

  @override
  State<InputData> createState() => _InputDataState();
}

class _InputDataState extends State<InputData> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _totalPriceController = TextEditingController();
  TextEditingController paidController = TextEditingController();
  TextEditingController remainingController = TextEditingController();
  TextEditingController _cottonWeightController = TextEditingController();

  // void handlePaid(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //
  //       paidController.addListener(() {
  //         final paidAmount = double.tryParse(paidController.text) ?? 0.0;
  //         final totalAmount = double.tryParse(_totalPriceController.text) ?? 0.0;
  //         final remainingAmount = totalAmount - paidAmount;
  //         remainingController.text = remainingAmount.toStringAsFixed(2);
  //       });
  //
  //       return AlertDialog(
  //         title: Text('Paid Amount'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: paidController,
  //               decoration: InputDecoration(labelText: 'Paid Amount'),
  //               keyboardType: TextInputType.number,
  //             ),
  //             TextField(
  //               controller: remainingController,
  //               decoration: InputDecoration(labelText: 'Remaining Amount'),
  //               keyboardType: TextInputType.number,
  //               enabled: false,
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               // Implement your submit logic here
  //               print('Paid Amount: ${paidController.text}');
  //               print('Remaining Amount: ${remainingController.text}');
  //             },
  //             child: Text('Submit'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  // void handleUnpaid() {
  //   // mark paid amount as 0 and remaining amount as total amount
  //   paidController.text = '0.0';
  //   remainingController.text = _totalPriceController.text;
  //
  //   // show snackbar
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Marked as unpaid'),
  //     ),
  //   );
  // }

  String? selectedCategory;
  String? selectedWeight;
  List<String> categories = ['Gloves', 'Cotton'];
  List<int> gloveWeights = [40, 50, 60, 70, 80, 90];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name ?? '';
    _quantityController.addListener(_calculateTotalPrice);
    _priceController.addListener(_calculateTotalPrice);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculateTotalPrice() {
    if (_quantityController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final quantity = double.tryParse(_quantityController.text) ?? 0.0;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final totalPrice = quantity * price;
      _totalPriceController.text = totalPrice.toStringAsFixed(2);
    } else {
      _totalPriceController.text = '';
    }
  }

  Future<void> _addDataToFirestore(BuildContext context) async {
    final name = _nameController.text;
    final quantity = _quantityController.text;
    final price = _priceController.text;
    final totalPrice = _totalPriceController.text;
    final paidAmount = '0.0';
    final remainingAmount = totalPrice;
    final category = selectedCategory;
    final weight = selectedCategory == 'Cotton' ? '${_cottonWeightController.text} kg' : '$selectedWeight gms';

    // Generate a new document ID
    final newDoc = FirebaseFirestore.instance.collection('Data').doc();
    final docId = newDoc.id;

    try {
      await newDoc.set({
        'id': docId,  // Add the generated ID to the document data
        'name': name,
        'category': category,
        'quantity': quantity,
        'weight': weight,
        'price': price,
        'total_price': totalPrice,
        'paid_amount': paidAmount,
        'remaining_amount': remainingAmount,
        'date': DateTime.now(),
      });

      print('Data added to Firestore with ID: $docId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record added successfully'),
        ),
      );

      // Clear text fields after adding the record
      _nameController.clear();
      selectedCategory = null;
      _quantityController.clear();
      selectedWeight = null;
      _priceController.clear();
      _totalPriceController.clear();
      paidController.clear();
      remainingController.clear();
    } catch (error) {
      print('Error adding data to Firestore: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company App'),
        // back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset('assets/dummylogo.png', width: 150, height: 150),
              const SizedBox(height: 20),
              const Text(
                'Fill a new Entry',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // text field for category
              // Category Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54), // Match the TextField border color
                    borderRadius: BorderRadius.circular(4.0), // Match the TextField border radius
                  ),
                  child: DropdownButtonHideUnderline( // Hide the default underline of DropdownButton
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12),
                        child: Text('Select Category',style: TextStyle(color: Colors.grey[700])),
                      ),
                      isExpanded: true,
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12), // Increase vertical padding
                            child: Text(category,style: TextStyle(color: Colors.grey[700]),),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                          selectedWeight = null; // Reset weight when category changes
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    hintText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 8),
              // want to add dropdown for weight, if category is gloves, then i want dropdown and if categeory is cotton, i wnat textfield
              if(selectedCategory == 'Gloves')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54), // Match the TextField border color
                      borderRadius: BorderRadius.circular(4.0), // Match the TextField border radius
                    ),
                    child: DropdownButtonHideUnderline( // Hide the default underline of DropdownButton
                      child: DropdownButton<String>(
                        value: selectedWeight,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12), // Increase vertical padding
                          child: const Text('Select Weight'),
                        ),
                        isExpanded: true,
                        items: gloveWeights.map((int weight) {
                          return DropdownMenuItem<String>(
                            value: weight.toString(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12), // Increase vertical padding
                              // in gms
                              child: Text('$weight gms',style: TextStyle(color: Colors.grey[700]),),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedWeight = value;
                          });
                        },
                      ),
                    ),
                  ),
                )
              else if (selectedCategory == 'Cotton')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: TextField(
                    controller: _cottonWeightController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Weight (kgs)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    hintText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: TextField(
                  controller: _totalPriceController,
                  decoration: const InputDecoration(
                    hintText: 'Total Amount',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _addDataToFirestore(context),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text('Submit'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
