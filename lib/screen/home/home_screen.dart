// homescreen.dart
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'car_details_screen.dart';
import 'search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_vehicle_screen.dart'; // Import the all vehicle screen
import 'brand_vehiclelist_screen.dart'; // Import the BrandVehicleListScreen
import 'chatbot_screen.dart'; // Import the ChatbotScreen

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _carDetailsList = [];
  bool _isLoading = true;
  String? _userId;
  Map<String, double> _averageRatings = {};
  List<dynamic> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchCars();
    _fetchBanners(); // Make sure this line is present
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  Future<void> _fetchCars() async {
    setState(() {
      _isLoading = true;
      _averageRatings = {};
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); // Retrieve user ID

    final url = Uri.parse('http://127.0.0.1:5000/get-all-cars');

    try {
      print('Sending data to get-all-cars: ${json.encode({'email': widget.userEmail, 'userId': userId})}'); // Log included userId

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': widget.userEmail, 'userId': userId}), // Include userId in request
      );

      print('get-all-cars response status: ${response.statusCode}');
      print('get-all-cars response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _carDetailsList = data.cast<Map<String, dynamic>>();
          _isLoading = false;
          _fetchAverageRatings(); // Fetch ratings after getting cars
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Failed to fetch cars: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching cars: $e');
    }
  }

  Future<void> _fetchAverageRatings() async {
    Map<String, double> fetchedRatings = {};
    for (var car in _carDetailsList) {
      final carId = car['_id'];
      try {
        final url = Uri.parse('http://127.0.0.1:5000/get-average-rating');
        print('Fetching average rating for carId: $carId');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'carId': carId}),
        );

        if (response.statusCode == 200) {
          final decodedBody = json.decode(response.body);
          print('Average rating response for carId $carId: $decodedBody');
          fetchedRatings[carId] = decodedBody['averageRating'].toDouble();
        } else {
          print(
              'Failed to fetch average rating for car $carId: ${response.statusCode}');
           fetchedRatings[carId] = 0.0; // Default rating if fetch fails
        }
      } catch (e) {
        print('Error fetching average rating for car $carId: $e');
         fetchedRatings[carId] = 0.0; // Default rating if fetch fails
      }
    }
    setState(() {
      _averageRatings = fetchedRatings;
    });
  }

// banners
  Future<void> _fetchBanners() async {
  try {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/banners'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _banners = data.where((banner) => banner['isActive'] == true).toList();
        print('Banners fetched successfully: $_banners'); // Add this line
      });
    } else {
      print('Failed to fetch banners: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching banners: $e');
  }
}


  List<Map<String, dynamic>> getSortedCarList() {
    List<Map<String, dynamic>> sortedList = List.from(_carDetailsList); // Create a copy
    sortedList.sort((a, b) {
      double ratingA = _averageRatings[a['_id']] ?? 0.0;
      double ratingB = _averageRatings[b['_id']] ?? 0.0;
      return ratingB.compareTo(ratingA); // Sort in descending order
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.45;
    final double horizontalPadding = 20;

    List<Map<String, dynamic>> sortedCarList = getSortedCarList();
    List<Map<String, dynamic>> top4Cars = sortedCarList.take(4).toList();


    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Ahmedabad',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),  // Changed Icon
                          onPressed: () {  // Added onPressed navigation
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatbotScreen(),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                     InkWell(
                        onTap: () {
                          // Extract car IDs from the _carDetailsList
                          List<String> availableCarIds = _carDetailsList.map((car) => car['_id'] as String).toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(
                                userEmail: _userId!,
                                availableCarIds: availableCarIds, // Pass the list of car IDs
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_outlined),
                              const SizedBox(width: 5),
                              Expanded(
                                child: const Text('Search by City & Hub', style: TextStyle(color: Colors.grey)),
                              ),
                              const Icon(Icons.tune_outlined)
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 15),
                     // Banner
                    _buildBannerSection(),
                    const SizedBox(height: 20),
                    // Top Category
                   Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
        const Text(
            'Top Category',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
        ),
    ],
),
const SizedBox(height: 10),
SizedBox(
    height: 100,
    child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
            InkWell(
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                BrandVehicleListScreen(
                                    brandName: 'Audi',
                                    userId: _userId!,
                                ),
                        ),
                    );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final categoryCardWidth = screenWidth * 0.2; // Adjust 0.2 as needed
                      return _buildCategoryCard(
                        'assets/images/audi logo.jpg',
                        'Audi',
                        categoryCardWidth,
                    );
                  }
                )
            ),
            InkWell(
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                BrandVehicleListScreen(
                                    brandName: 'BMW',
                                    userId: _userId!,
                                ),
                        ),
                    );
                },
                 child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final categoryCardWidth = screenWidth * 0.2; // Adjust 0.2 as needed
                    return _buildCategoryCard(
                        'assets/images/bmw logo.jpg',
                        'BMW',
                         categoryCardWidth,
                    );
                  }
                )
            ),
            InkWell(
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                BrandVehicleListScreen(
                                    brandName: 'Tata',
                                    userId: _userId!,
                                ),
                        ),
                    );
                },
                 child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final categoryCardWidth = screenWidth * 0.2; // Adjust 0.2 as needed
                    return _buildCategoryCard(
                        'assets/images/tata_logo.jpg',
                        'Tata',
                         categoryCardWidth,
                    );
                  }
                )
            ),
            InkWell(
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                BrandVehicleListScreen(
                                    brandName: 'Toyota',
                                    userId: _userId!,
                                ),
                        ),
                    );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final categoryCardWidth = screenWidth * 0.2; // Adjust 0.2 as needed
                    return _buildCategoryCard(
                        'assets/images/toyota logo.png',
                        'Toyota',
                         categoryCardWidth,
                    );
                  }
                )
            ),
        ],
    ),
),
                    const SizedBox(height: 20),
                    // Top Rated Cars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Rated Cars',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => AllVehicleScreen(
                                   carDetailsList: _carDetailsList,
                                   averageRatings: _averageRatings,
                                   userId: _userId!, // Pass the userId here
                                 ),
                               ),
                             );
                          },
                          child: const Text('See All >',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.blue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: top4Cars.length,  // Display only 4 cars
                        itemBuilder: (context, index) {
                          final carDetails = top4Cars[index];
                          final carId = carDetails['_id'];
                          final averageRating = _averageRatings[carId] ?? 0.0; // Get average rating, default to 0.0
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _buildCarCard(
                              context,
                              carDetails,
                              cardWidth,
                              averageRating, // Pass the average rating
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCarCard(
    BuildContext context,
    Map<String, dynamic> carDetails,
    double width,
    double rating,
  ) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹'); // Added formatter
    print('BuildCarCard - Retrieved UserEmail: ${widget.userEmail}');
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarDetailsScreen(
              carId: carDetails['_id'],
              userId: _userId!, //USE THE STORED userId
            ),
          ),
        );
      },
      child: SizedBox(
        width: width,
        child: LayoutBuilder(builder: (context, constraints) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: carDetails['coverImageBytes'] != null
                        ? Image.memory(
                            base64Decode(carDetails['coverImageBytes']),
                            height: 140,
                            width: width,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/cars.jpeg',
                            height: 140,
                            width: width,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 5),
                  Flexible(
                    child: Text(
                      carDetails['carModel'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: RatingBar.builder(
                          initialRating: rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 12,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          ignoreGestures: true,
                          onRatingUpdate: (rating) {
                            print(rating);
                          },
                        ),
                      ),
                      Flexible(
                        child: Text(
                          currencyFormat.format(
                              int.parse(carDetails['pricePerHour'] ?? '0')),
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // banner widget

  Widget _buildBannerSection() {
    if (_banners.isEmpty) {
      return Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: const DecorationImage(
            image: AssetImage('assets/images/50% disc.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(child: Text('No banners available')),
      );
    } else if (_banners.length == 1) {
      // Display single banner if only one is available
      return Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: NetworkImage('http://127.0.0.1:5000/uploads/${_banners[0]['imagePath']}'),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Use CarouselSlider for multiple banners
      return CarouselSlider(
        options: CarouselOptions(
          height: 200.0,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.8,
        ),
        items: _banners.map((banner) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image:
                        NetworkImage('http://127.0.0.1:5000/uploads/${banner['imagePath']}'),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        }).toList(),
      );
    }
  }

  Widget _buildCategoryCard(String image, String label, double width) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}