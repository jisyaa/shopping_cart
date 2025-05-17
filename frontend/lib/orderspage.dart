import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/cartpage.dart' as cart;
import 'package:flutter/cupertino.dart';
import 'dart:convert';

class OrdersPage extends StatefulWidget {
  final dynamic userData;

  const OrdersPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List listOrders = [];

  @override
  void initState() {
    super.initState();
    getOrders();
  }

  Future<void> getOrders() async {
    final String urlOrders =
        "http://10.0.3.2:8000/orders?user_id=${widget.userData['id']}";
    try {
      final response = await http.get(Uri.parse(urlOrders));
      if (response.statusCode == 200) {
        setState(() {
          listOrders = jsonDecode(response.body);
        });
      } else {
        print("Failed to load orders. Status code: ${response.statusCode}");
      }
    } catch (exc) {
      print("Error fetching orders: $exc");
    }
  }

  void itemDataTap(int index) {
    final item = listOrders[index];
    print("Pesanan ID : ${item['order_id']}");
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) =>
          DetailOrders(item: item, userData: widget.userData),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => cart.CartPage(userData: widget.userData),
            ));
          },
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
        ),
        title: const Text('Pesanan Saya'),
        backgroundColor: const Color.fromARGB(255, 25, 104, 169),
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: listOrders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: listOrders.length,
              itemBuilder: (context, index) {
                final order = listOrders[index];
                final items = order['items'] as List<dynamic>;
                final firstItem = items.isNotEmpty ? items.first : null;

                return GestureDetector(
                  onTap: () => itemDataTap(index),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (firstItem != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                firstItem['image_url'] ??
                                    'https://via.placeholder.com/100',
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Flexible(
                            // pakai Flexible bukan Expanded agar tidak error di scrollable
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min, // supaya sesuai isi
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstItem?['product_name'] ?? 'Produk',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 6), // ganti Spacer
                                Text('x${firstItem?['quantity'] ?? 0}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${items.length} produk',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      'Total: Rp${NumberFormat("#,##0", "id_ID").format(order['total_price'])}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DetailOrders extends StatelessWidget {
  final dynamic item;
  final Map<String, dynamic> userData;

  const DetailOrders({
    Key? key,
    required this.item,
    required this.userData,
  }) : super(key: key);

  Future<Map<String, dynamic>> fetchOrderDetail(int orderId) async {
    final String url = "http://10.0.3.2:8000/orders/$orderId";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load order detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = item['order_id'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 104, 169),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => OrdersPage(userData: userData)
            ));
          },
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
        ),
        title: const Text(
          "Rincian Pesanan",
          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchOrderDetail(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          final items = snapshot.data!['items'];

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Alamat Pengiriman
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(userData['full_name'] ?? '-'),
                    subtitle: Text(
                        "${userData['address'] ?? '-'}\n${userData['phone'] ?? '-'}"),
                  ),
                ),
                const SizedBox(height: 12),
                // Daftar Produk
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Image.network(
                              item['image_url'] ??
                                  'https://via.placeholder.com/100',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['product_name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text("Jumlah: x${item['quantity']}"),
                                  Text(
                                      "Subtotal: Rp${NumberFormat("#,##0", "id_ID").format(item['subtotal'])}"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Total
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Pesanan",
                          style: TextStyle(fontSize: 16)),
                      Text(
                        "Rp${NumberFormat("#,##0", "id_ID").format(item['total_price'])}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
