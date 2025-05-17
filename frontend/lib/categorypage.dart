import 'dart:async';
import 'dart:convert';
import 'package:frontend/cartpage.dart' as cart;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/login.dart';
import 'package:http/http.dart' as http;

class CategoryPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String categoryName;
  final int categoryId;

  const CategoryPage({
    super.key,
    required this.userData,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List listProductCategory = [];

  @override
  void initState() {
    super.initState();
    getProductCategory();
  }

  Future<void> getProductCategory() async {
    final String urlProductCategory =
        "http://10.0.3.2:8000/products/category/${widget.categoryId}";
    try {
      final response = await http.get(Uri.parse(urlProductCategory));
      if (response.statusCode == 200) {
        setState(() {
          listProductCategory = jsonDecode(response.body);
        });
      } else {
        print("Failed to load products. Status code: ${response.statusCode}");
      }
    } catch (exc) {
      print("Error fetching products: $exc");
    }
  }

  void itemDataTap(int index) {
    final item = listProductCategory[index];
    if (kDebugMode) {
      print("Product Name : ${item['name']}");
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => DetailScreen(
        item: item,
        userData: widget.userData,
        categoryName: widget.categoryName,
        categoryId: widget.categoryId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 104, 169),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => HomePage(userData: widget.userData),
            ));
          },
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
        ),
        title: const Text(
          "ECOMMERCE",
          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.shopping_cart, size: 22, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
               builder: (context) => cart.CartPage(userData: widget.userData),
              ));
            },
          ),
          Builder(
            builder: (context) {
              return GestureDetector(
                onTapDown: (TapDownDetails details) {
                  final position = details.globalPosition;
                  showMenu<PopupMenuEntry>(
                    context: context,
                    position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
                    items: <PopupMenuEntry<PopupMenuItem>>[
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, ${widget.userData['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(widget.userData['email'], style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 10),
                            Text('Alamat: ${widget.userData['address']}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Logout'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
                          });
                        },
                      ),
                    ],
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(CupertinoIcons.profile_circled, size: 22, color: Colors.white),
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Center(
        child: Column(children: [
          const SizedBox(height: 10),
          Text(
            widget.categoryName,
            style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: listProductCategory.length,
              itemBuilder: (context, index) {
                final item = listProductCategory[index];
                return GestureDetector(
                  onTap: () {
                    itemDataTap(index);
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Image.network(
                          item['image_url'],
                          height: 100,
                          width: 125,
                          fit: BoxFit.fill,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Text("Error Loading Product Image", textAlign: TextAlign.justify);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Text(
                            item['name'] ?? '',
                            style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                'Rp. ${item['price']}',
                                style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.inventory_2, color: Colors.green, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  'Stock: ${item['stock'] ?? 0}',
                                  style: const TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final dynamic item;
  final Map<String, dynamic> userData;
  final String categoryName;
  final int categoryId;

  DetailScreen({
    Key? key,
    required this.item,
    required this.userData,
    required this.categoryName,
    required this.categoryId,
  }) : super(key: key);

  final ValueNotifier<int> _quantityNotifier = ValueNotifier<int>(1);

  Future<void> addToCart(int userId, int productId, int quantity) async {
    final url = Uri.parse('http://10.0.3.2:8000/cart');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      print('Produk berhasil ditambahkan ke keranjang');
    } else {
      throw Exception('Gagal menambahkan ke keranjang: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 104, 169),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => CategoryPage(
                categoryName: categoryName,
                categoryId: categoryId,
                userData: userData,
              ),
            ));
          },
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
        ),
        title: const Text(
          "ECOMMERCE",
          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.shopping_cart, size: 22, color: Colors.white),
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
              style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
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
              style: TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
            child: Text(
              item['description'],
              style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ),
          // ... (price and stock display)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 25, 104, 169),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        final quantity = _quantityNotifier.value;
                        await addToCart(userData['id'], item['id'], quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Item ditambahkan ke keranjang")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Gagal: $e")),
                        );
                      }
                    },
                    child: const Text(
                      "ADD TO CART",
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<int>(
                  valueListenable: _quantityNotifier,
                  builder: (context, quantity, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantity > 1) {
                              _quantityNotifier.value = quantity - 1;
                            }
                          },
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            _quantityNotifier.value = quantity + 1;
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}