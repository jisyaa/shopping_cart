import 'package:flutter/material.dart';
import 'package:frontend/cartpage.dart' as cart;
import 'package:frontend/orderspage.dart';
import 'package:frontend/homepage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class CartPage extends StatefulWidget {
  final dynamic userData;

  const CartPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  Set<int> selectedProductIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final userId = widget.userData['id'].toString();
    final url = Uri.parse('http://10.0.3.2:8000/cart?user_id=$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          List<Map<String, dynamic>> items = [];

          for (var entry in data.entries) {
            final productId = entry.key.toString();
            final quantity = entry.value;

            final productUrl =
                Uri.parse('http://10.0.3.2:8000/products/$productId');
            final productResponse = await http.get(productUrl);

            if (productResponse.statusCode == 200) {
              final product = jsonDecode(productResponse.body);
              product['quantity'] = quantity;
              product['id'] = int.parse(productId);
              items.add(product);
            }
          }

          setState(() {
            cartItems = items;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          print('Format data cart tidak sesuai');
        }
      } else {
        setState(() => isLoading = false);
        print('Gagal memuat keranjang');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error: $e');
    }
  }

  double calculateTotalSelectedPrice() {
    return cartItems
        .where((item) => selectedProductIds.contains(item['id']))
        .fold(0.0, (sum, item) {
      final qty = double.tryParse(item['quantity'].toString()) ?? 1.0;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      return sum + (qty * price);
    });
  }

  void toggleSelection(int productId) {
    setState(() {
      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
      } else {
        selectedProductIds.add(productId);
      }
    });
  }

  Future<void> removeItemFromCart(int productId) async {
    final url = Uri.parse(
        'http://10.0.3.2:8000/cart/$productId?user_id=${widget.userData['id']}');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          cartItems.removeWhere((item) => item['id'] == productId);
          selectedProductIds.remove(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item berhasil dihapus')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus item: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menghapus item')),
      );
    }
  }

  void itemDataTap(int index) {
    final item = cartItems[index];
    if (kDebugMode) {
      print("Product Name : ${item['name']}");
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) =>
          DetailProduct(item: item, userData: widget.userData),
    ));
  }

  Future<void> checkoutCart() async {
    final userId = widget.userData['id'];
    final selectedIds = selectedProductIds.toList();

    final url = Uri.parse('http://10.0.3.2:8000/checkout');
    final body = jsonEncode({
      'user_id': userId,
      'product_ids': selectedIds,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Checkout berhasil')),
        );

        // Hapus item yang telah di-checkout dari cart lokal
        setState(() {
          cartItems
              .removeWhere((item) => selectedProductIds.contains(item['id']));
          selectedProductIds.clear();
        });
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Gagal: ${error['detail'] ?? 'Terjadi kesalahan'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saat checkout: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) =>
                  HomePage(userData: widget.userData),
            ));
          },
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
        ),
        title: const Text('Keranjang Belanja'),
        backgroundColor: const Color.fromARGB(255, 25, 104, 169),
        foregroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              fetchCartItems();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_checkout,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OrdersPage(userData: widget.userData),
                ),
              );
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text('Keranjang kosong'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Keranjang Saya (${cartItems.length})',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final isSelected =
                              selectedProductIds.contains(item['id']);

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => toggleSelection(item['id']),
                                  activeColor: Colors.orange,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['image_url'] ?? '',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      itemDataTap(index);
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Produk',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Rp ${item['price']}',
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Jumlah: ${item['quantity']}'),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      removeItemFromCart(item['id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            top: BorderSide(
                                color: Colors.grey.shade300, width: 1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Total: Rp ${calculateTotalSelectedPrice().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 25, 104, 169),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: selectedProductIds.isEmpty
                                ? null
                                : () async {
                                    await checkoutCart();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 13, 61, 151),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class DetailProduct extends StatelessWidget {
  final dynamic item;
  final Map<String, dynamic> userData;

  DetailProduct({Key? key, required this.item, required this.userData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 104, 169),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) =>
                    CartPage(userData: userData)));
          },
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
        ),
        title: const Text(
          "ECOMMERCE",
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.shopping_cart,
                size: 22, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => cart.CartPage(userData: userData),
              ));
            },
          ),
          // ... (existing user profile code)
        ],
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Center(
            child: Text(
              item['name'],
              style: const TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Image.network(
              item['image_url'],
              height: 350,
              width: 400,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
            child: Text(
              "Product Description",
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
            child: Text(
              item['description'],
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
