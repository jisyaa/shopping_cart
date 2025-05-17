// import yang dibutuhkan
import 'dart:async';
import 'dart:convert';
// Tambahkan alias di sini:
import 'package:frontend/cartpage.dart' as cart;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'categorypage.dart';
import 'package:flutter/foundation.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List listAllProduct = [];
  PageController bannerController = PageController();
  int indexBanner = 0;
  Timer? timer;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    bannerController.addListener(() {
      if (mounted) {
        setState(() {
          indexBanner = bannerController.page?.round() ?? 0;
        });
      }
    });
    bannerOnBoarding();
    getAllProducts();
  }

  void bannerOnBoarding() {
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          indexBanner = (indexBanner + 1) % 3;
          bannerController.animateToPage(
            indexBanner,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  Future<void> getAllProducts() async {
    const String urlAllProduct = "http://10.0.3.2:8000/products";
    try {
      final response = await http.get(Uri.parse(urlAllProduct));
      if (response.statusCode == 200) {
        setState(() {
          listAllProduct = jsonDecode(response.body);
        });
      } else {
        print("Failed to load products. Status code: ${response.statusCode}");
      }
    } catch (exc) {
      print("Error fetching products: $exc");
    }
  }

  void itemDataTap(int index) {
    final item = listAllProduct[index];
    if (kDebugMode) {
      print("Product Name : ${item['name']}");
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => Detail(
        item: item,
        userData: widget.userData,
      ),
    ));
  }

  void searchProductItem() async {
    final search = searchController.text;
    if (search.isEmpty) {
      getAllProducts();
      return;
    }

    try {
      final url = Uri.parse('http://10.0.3.2:8000/search?q=$search');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List listSearch = jsonDecode(response.body);
        setState(() {
          listAllProduct = listSearch;
        });
      } else {
        print("Search failed with status: ${response.statusCode}");
      }
    } catch (exc) {
      print("Search error: $exc");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> bannerList = [
      './lib/assets/banner1.jpg',
      './lib/assets/banner2.jpg',
      './lib/assets/banner3.jpg'
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 104, 169),
        leading: Builder(
          builder: (context) {
            return GestureDetector(
              onTapDown: (TapDownDetails details) {
                final position = details.globalPosition;
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy,
                    position.dx,
                    position.dy,
                  ),
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${widget.userData['username']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.userData['email'],
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Alamat: ${widget.userData['address']}',
                            style: const TextStyle(fontSize: 12),
                          ),
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
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        });
                      },
                    ),
                  ],
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(CupertinoIcons.profile_circled,
                    size: 22, color: Colors.white),
              ),
            );
          },
        ),
        title: const Text(
          "ECOMMERCE",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.shopping_cart,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      cart.CartPage(userData: widget.userData),
                ),
              );
            },
          )
        ],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: TextField(
                controller: searchController,
                onSubmitted: (_) => searchProductItem(),
                onChanged: (_) => searchProductItem(),
                decoration: InputDecoration(
                  hintText: 'Apa yang anda butuhkan?',
                  prefixIcon:
                      const Icon(Icons.search, size: 20, color: Colors.black),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: bannerController,
                itemCount: bannerList.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    bannerList[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildCategoryCard('Laptop', 'laptop.png', 2),
                    buildCategoryCard('Handphone', 'handphone.png', 1),
                    buildCategoryCard('Keyboard', 'keyboard.png', 4),
                    buildCategoryCard('Mouse', 'mouse.png', 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "All Product",
              style: TextStyle(
                fontSize: 22,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: listAllProduct.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                      ),
                      itemCount: listAllProduct.length,
                      itemBuilder: (context, index) {
                        final item = listAllProduct[index];
                        return GestureDetector(
                          onTap: () { itemDataTap(index);
                            
                          },
                          child: Card(
                            elevation: 3,
                            child: Column(
                              children: [
                                Image.network(
                                  item['image_url'] ?? '',
                                  height: 105,
                                  width: 130,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image,
                                        size: 50);
                                  },
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Rp. ${item['price']}',
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.inventory_2,
                                            color: Colors.green, size: 12),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Stock: ${item['stock']}',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildCategoryCard(String title, String image, int categoryId) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryPage(
                categoryName: title,
                categoryId: categoryId,
                userData: widget.userData,
              ),
            ),
          );
        },
        child: SizedBox(
          width: 70,
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                './lib/assets/$image',
                width: 45,
                height: 45,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Detail extends StatelessWidget {
  final dynamic item;
  final Map<String, dynamic> userData;

  Detail({
    Key? key,
    required this.item,
    required this.userData,
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
              builder: (BuildContext context) => HomePage(userData: userData)
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