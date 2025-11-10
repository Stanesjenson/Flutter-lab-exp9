import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UpdateProductApp());
}

class UpdateProductApp extends StatelessWidget {
  const UpdateProductApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Update Product Details',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const UpdateProductScreen(),
    );
  }
}

class UpdateProductScreen extends StatefulWidget {
  const UpdateProductScreen({super.key});

  @override
  State<UpdateProductScreen> createState() => _UpdateProductScreenState();
}

class _UpdateProductScreenState extends State<UpdateProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  DocumentSnapshot? _currentProduct;
  String _statusMessage = "";

  /// 🔍 Search product by name
  Future<void> searchProduct() async {
    final searchName = nameController.text.trim();

    if (searchName.isEmpty) {
      setState(() {
        _statusMessage = "Please enter a product name to search.";
        _currentProduct = null;
      });
      return;
    }

    try {
      final query =
          await products.where('name', isEqualTo: searchName).limit(1).get();

      if (query.docs.isEmpty) {
        setState(() {
          _statusMessage = "Product not found.";
          _currentProduct = null;
        });
      } else {
        final doc = query.docs.first;
        setState(() {
          _currentProduct = doc;
          _statusMessage = "Product found!";
          quantityController.text = doc['quantity'].toString();
          priceController.text = doc['price'].toString();
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error fetching product: $e";
        _currentProduct = null;
      });
    }
  }

  /// 🔁 Update product details
  Future<void> updateProduct() async {
    if (_currentProduct == null) {
      setState(() {
        _statusMessage = "Please search for a product first.";
      });
      return;
    }

    final newQuantity = int.tryParse(quantityController.text.trim());
    final newPrice = double.tryParse(priceController.text.trim());

    if (newQuantity == null || newPrice == null) {
      setState(() {
        _statusMessage = "Enter valid numeric values for quantity and price.";
      });
      return;
    }

    try {
      await products.doc(_currentProduct!.id).update({
        'quantity': newQuantity,
        'price': newPrice,
      });

      // Fetch updated product to show changes immediately
      final updatedDoc = await products.doc(_currentProduct!.id).get();

      setState(() {
        _currentProduct = updatedDoc;
        _statusMessage = "Product updated successfully!";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error updating product: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Product Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// 🔍 Search by Product Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Enter Product Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: searchProduct,
                child: const Text("Search"),
              ),
              const SizedBox(height: 10),

              if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains("Error")
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 10),

              /// 📦 Show and Update Product Details
              if (_currentProduct != null)
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Product: ${_currentProduct!['name']}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Quantity",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Price",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: updateProduct,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo),
                          child: const Text("Update"),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Updated Details:\n"
                          "Name: ${_currentProduct!['name']}\n"
                          "Quantity: ${_currentProduct!['quantity']}\n"
                          "Price: ₹${_currentProduct!['price']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
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
