import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widget/datetime_selection_screen.dart';
import '../payment_screen.dart';
import 'upload_license_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CarDetailsScreen extends StatefulWidget {
  final String carId;
  final String userId; //still need this

  const CarDetailsScreen({
    Key? key,
    required this.carId,
    required this.userId,
  }) : super(key: key);

  @override
  CarDetailsScreenState createState() => CarDetailsScreenState();
}

class CarDetailsScreenState extends State<CarDetailsScreen> {
  bool _isTripProtectionSelected = true;
  bool _isAgreementPolicySelected = true;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  Map<String, dynamic> _carDetails = {};
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Widget> _imageSlides = [];
  Timer? _timer;
  XFile? _frontImageFile;
  XFile? _backImageFile;
  double _averageRating = 0.0; // ADD THIS: Store average rating
  int _reviewCount = 0; // Add this to store review count
  List<dynamic> _reviews = []; // Add this to store reviews

  String _formattedStartDate = "Select Date";
  String _formattedStartTime = "Select Time";
  String _formattedEndDate = "Select Date";
  String _formattedEndTime = "Select Time";

  @override
  void initState() {
    super.initState();
    print("CarDetailsScreen: carId = ${widget.carId}, userId = ${widget.userId}"); // ADD THIS
    _fetchCarDetails();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCarDetails() async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('http://127.0.0.1:5000/get-car-by-id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'carId': widget.carId}),
      );
      print('Response status code: ${response.statusCode}'); // ADDED
      print('Response body: ${response.body}'); // ADDED

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        if (decodedBody is Map<String, dynamic>) {
          setState(() {
            _carDetails = decodedBody;
            _isLoading = false;
            _setInitialDateTimes(); // Set initial dates and times
            _buildImageSlides();
            _startAutoSlide();
            print('Car Details: $_carDetails'); // ADDED
            _fetchAverageRating(); // Fetch the average rating here
            _fetchReviewCount(); // Fetch the review count
            _fetchReviews(); // Fetch reviews
          });
        } else {
          print('Invalid car details format');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('Failed to fetch car details: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching car details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ADD THIS:  Fetch Average Rating
  Future<void> _fetchAverageRating() async {
    try {
      final url = Uri.parse('http://127.0.0.1:5000/get-average-rating');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'carId': widget.carId}),
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        print('Average rating response: $decodedBody'); // ADDED
        setState(() {
          _averageRating = decodedBody['averageRating'].toDouble();
        });
        print('Average Rating is now: $_averageRating'); // ADDED
      } else {
        print('Failed to fetch average rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching average rating: $e');
    }
  }

  // ADD THIS:  Fetch Review Count
  Future<void> _fetchReviewCount() async {
    try {
      final url = Uri.parse('http://127.0.0.1:5000/get-review-count');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'carId': widget.carId}),
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        setState(() {
          _reviewCount = decodedBody['reviewCount'];
        });
      } else {
        print('Failed to fetch review count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching review count: $e');
    }
  }

  // ADD THIS:  Fetch Reviews
  Future<void> _fetchReviews() async {
    try {
      final url = Uri.parse('http://127.0.0.1:5000/get-reviews');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'carId': widget.carId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _reviews = json.decode(response.body);
        });
      } else {
        print('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  void _setInitialDateTimes() {
    if (_carDetails.containsKey('startDate') &&
        _carDetails['startDate'] != null &&
        _carDetails['startDate'].isNotEmpty) {
      try {
        _formattedStartDate =
            DateFormat('dd MMM yyyy').format(DateTime.parse(_carDetails['startDate']));
      } catch (e) {
        print('Error parsing start date : $e');
        _formattedStartDate = "Select Date";
      }
    }
    if (_carDetails.containsKey('startTime') &&
        _carDetails['startTime'] != null &&
        _carDetails['startTime'].isNotEmpty) {
      try {
        _formattedStartTime =
            DateFormat('h:mm a').format(DateTime.parse(_carDetails['startTime']));
      } catch (e) {
        print('Error parsing start time : $e');
        _formattedStartTime = "Select Time";
      }
    }
    if (_carDetails.containsKey('endDate') &&
        _carDetails['endDate'] != null &&
        _carDetails['endDate'].isNotEmpty) {
      try {
        _formattedEndDate =
            DateFormat('dd MMM yyyy').format(DateTime.parse(_carDetails['endDate']));
      } catch (e) {
        print('Error parsing end date : $e');
        _formattedEndDate = "Select Date";
      }
    }
    if (_carDetails.containsKey('endTime') &&
        _carDetails['endTime'] != null &&
        _carDetails['endTime'].isNotEmpty) {
      try {
        _formattedEndTime =
            DateFormat('h:mm a').format(DateTime.parse(_carDetails['endTime']));
      } catch (e) {
        print('Error parsing end time : $e');
        _formattedEndTime = "Select Time";
      }
    }
  }

  int get numberOfDays => (_returnDate != null && _pickupDate != null)
      ? _returnDate!.difference(_pickupDate!).inDays + 1
      : 1;

  int get numberOfHours {
    if (_returnDate == null ||
        _pickupDate == null ||
        _returnTime == null ||
        _pickupTime == null) {
      return 0;
    }

    final startDateTime = DateTime(_pickupDate!.year, _pickupDate!.month,
        _pickupDate!.day, _pickupTime!.hour, _pickupTime!.minute);
    final endDateTime = DateTime(_returnDate!.year, _returnDate!.month,
        _returnDate!.day, _returnTime!.hour, _returnTime!.minute);
    return endDateTime.difference(startDateTime).inHours;
  }

  double get _calculateTotalAmount {
    if (_carDetails.containsKey('pricePerHour') &&
        _carDetails['pricePerHour'] != null) {
      return double.parse(_carDetails['pricePerHour'].toString()) *
          numberOfHours;
    } else {
      return 0.0;
    }
  }

  void _navigateToUploadLicenseScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadLicenseScreen(
          carModel: _carDetails['carModel'] ?? 'N/A',
          rentalCostPerHour: double.parse(_carDetails['pricePerHour'] ?? '0'),
          driverCostPerHour: 0,
          initialPickupDate: _pickupDate,
          initialReturnDate: _returnDate,
          carRegNum: _carDetails['CarRegistrationNumber'] ?? 'N/A',
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _frontImageFile = result['frontImage'];
        _backImageFile = result['backImage'];
      });
      _navigateToPaymentScreen(context);
    }
  }

  void _navigateToDateTimeScreen(BuildContext context) async {
    DateTime? minDate = DateTime.now(); // Set to today

    DateTime? maxDate;

    if (_carDetails.containsKey('endDate') &&
        _carDetails['endDate'] != null &&
        _carDetails['endDate'].isNotEmpty) {
      maxDate = DateTime.parse(_carDetails['endDate']);
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DateTimeSelectionScreen(
          initialPickupDate: _pickupDate,
          initialReturnDate: _returnDate,
          carRegNum: _carDetails['CarRegistrationNumber'] ?? 'N/A',
          minDate: minDate,
          maxDate: maxDate,
          carStartDate: _carDetails['startDate'] ??
              DateTime.now().toString(), // Pass car start date or current date as default
          carStartTime: _carDetails['startTime'] ??
              TimeOfDay.now().format(context), // Pass car start time or current time as default
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickupDate = result['pickupDate'];
        _pickupTime = result['pickupTime'];
        _returnDate = result['returnDate'];
        _returnTime = result['returnTime'];

        _formattedStartDate = _pickupDate != null
            ? DateFormat('dd MMM yyyy').format(_pickupDate!)
            : "Select Date";
        _formattedStartTime = _pickupTime != null
            ? DateFormat('h:mm a').format(DateTime(
                _pickupDate!.year,
                _pickupDate!.month,
                _pickupDate!.day,
                _pickupTime!.hour,
                _pickupTime!.minute))
            : "Select Time";
        _formattedEndDate = _returnDate != null
            ? DateFormat('dd MMM yyyy').format(_returnDate!)
            : "Select Date";
        _formattedEndTime = _returnTime != null
            ? DateFormat('h:mm a').format(DateTime(
                _returnDate!.year,
                _returnDate!.month,
                _returnDate!.day,
                _returnTime!.hour,
                _returnTime!.minute))
            : "Select Time";
      });
      _navigateToUploadLicenseScreen(context);
    }
  }

  Future<void> _navigateToPaymentScreen(BuildContext context) async {
    String? frontImageBase64;
    if (_frontImageFile != null) {
      try {
        List<int> imageBytes = await _frontImageFile!.readAsBytes();
        frontImageBase64 = base64Encode(imageBytes);
      } catch (e) {
        print('Error reading front image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process front image')));
        return;
      }
    }
    String? backImageBase64;
    if (_backImageFile != null) {
      try {
        List<int> imageBytes = await _backImageFile!.readAsBytes();
        backImageBase64 = base64Encode(imageBytes);
      } catch (e) {
        print('Error reading back image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process back image')));
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PaymentScreen(
              carModel: _carDetails['carModel'] ?? 'N/A',
              pickupDate: _pickupDate != null && _pickupTime != null
                  ? DateTime(
                      _pickupDate!.year,
                      _pickupDate!.month,
                      _pickupDate!.day,
                      _pickupTime!.hour,
                      _pickupTime!.minute)
                  : DateTime.now(),
              returnDate: _returnDate != null && _returnTime != null
                  ? DateTime(
                      _returnDate!.year,
                      _returnDate!.month,
                      _returnDate!.day,
                      _returnTime!.hour,
                      _returnTime!.minute)
                  : DateTime.now(),
              rentalCostPerDay: double.parse(_carDetails['pricePerHour']
                          .toString()) *
                      24,
              driverCostPerDay: 0,
              numberOfDays: numberOfDays,
              carRegNum: _carDetails['CarRegistrationNumber'] ?? 'N/A',
              startTime: _pickupDate != null && _pickupTime != null
                  ? DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime(
                      _pickupDate!.year,
                      _pickupDate!.month,
                      _pickupDate!.day,
                      _pickupTime!.hour,
                      _pickupTime!.minute))
                  : DateTime.now().toString(),
              endTime: _returnDate != null && _returnTime != null
                  ? DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime(
                      _returnDate!.year,
                      _returnDate!.month,
                      _returnDate!.day,
                      _returnTime!.hour,
                      _returnTime!.minute))
                  : DateTime.now().toString(),
              amount: double.parse(_carDetails['pricePerHour'] ?? '0'),
              userName: '',
              carId: widget.carId,
              userId: widget.userId,
              frontImage: frontImageBase64, // Pass base64 string
              backImage: backImageBase64,
              userEmail: '')),
    );
  }

  void _buildImageSlides() {
    _imageSlides = [];
    if (_carDetails['coverImageBytes'] != null) {
      _imageSlides.add(_buildImage(_carDetails['coverImageBytes']));
    }
    if (_carDetails['exteriorImageBytes'] != null) {
      _imageSlides.add(_buildImage(_carDetails['exteriorImageBytes']));
    }
    if (_carDetails['interiorImageBytes'] != null) {
      _imageSlides.add(_buildImage(_carDetails['interiorImageBytes']));
    }
  }

  void _startAutoSlide() {
    if (_imageSlides.length <= 1)
      return; // Don't auto slide if there is only one or less image
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _imageSlides.length - 1) {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        } else {
          _pageController.animateToPage(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        }
      }
    });
  }

    @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = 20;
    final double cardWidth = screenWidth * 0.45;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Image Slider
                    SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          PageView(
                            controller: _pageController,
                            children: _imageSlides,
                          ),
                          Positioned(
                            bottom: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _imageSlides.length,
                                (index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentPage == index
                                            ? Colors.blue
                                            : Colors.grey)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Car Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(_carDetails['carModel'] ?? 'N/A',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold))),
                        Text(
                          '${_carDetails['kmDriven'] ?? 'N/A'} kms',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '${_carDetails['yearOfRegistration'] ?? 'N/A'} • ',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${_carDetails['transmissionType'] ?? 'N/A'} • ',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${_carDetails['seatingCapacity'] ?? 'N/A'} Seater',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: _averageRating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 18,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          ignoreGestures: true,
                          onRatingUpdate: (rating) {
                            print(rating);
                          },
                        ),
                        const SizedBox(width: 5),
                        Text(_averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(width: 5),
                        TextButton(
                            onPressed: () {},
                            child: Text('$_reviewCount Reviews >',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.blue))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Booking Time
                    const Text(
                      'Booking Time',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                        onTap: () {
                          _navigateToDateTimeScreen(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start Date & Time',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                        _formattedStartDate,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                      _formattedStartTime,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ]),
                              const Icon(Icons.arrow_forward_outlined,
                                  color: Colors.grey),
                            ],
                          ),
                        )),
                    const SizedBox(height: 5),
                    InkWell(
                        onTap: () {},
                        child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'End Date & Time',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                      Text(
                                        _formattedEndDate,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                      Text(
                                        _formattedEndTime,
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ]),
                                const Icon(Icons.arrow_forward_outlined,
                                    color: Colors.grey),
                              ],
                            ))),
                    const SizedBox(height: 15),
                    // Offers
                    const Text(
                      'Offers',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () {
                        // Handle apply coupon logic
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.discount_outlined,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 5),
                                const Text('Apply Coupon',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_outlined,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Ratings & Reviews
                    const Text(
                      'Ratings & Reviews',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _reviews.length, // Use the actual reviews
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return _buildReviewCard(cardWidth, review);
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Pickup Information
                    const Text(
                      'Pickup Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_carDetails['pickupLocation'] ?? 'N/A'}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                  width: cardWidth * 0.6,
                                  height: 100,
                                  child: Image.asset("assets/images/map.jpeg")),
                            )
                          ]),
                    ),
                    const SizedBox(height: 15),
                    // Trip Protection Package
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Trip Protection Package',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                TextButton(
                                    onPressed: () {
                                      // Handle the text button navigation
                                    },
                                    child: const Text(
                                      'Click to know more',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red),
                                    ))
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text('Standard (Rs 259) Rs 219',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            const Text(
                                'Only pay Rs 999 in case of any incidentals',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isTripProtectionSelected =
                                            !_isTripProtectionSelected;
                                      });
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: _isTripProtectionSelected
                                                ? Colors.blue
                                                : Colors.grey),
                                        color: _isTripProtectionSelected
                                            ? Colors.blue
                                            : Colors.transparent,
                                      ),
                                      child: _isTripProtectionSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    )),
                              ],
                            )
                          ],
                        )),
                    const SizedBox(height: 15),
                    // Policies
                    const Text(
                      'Policies',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cancel_outlined,
                                        color: Colors.red),
                                    const SizedBox(width: 5),
                                    const Text('Free Cancellation',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                                'Change of plans? No problem! Get a full refund on cancellations before',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 5),
                            const Text('04 July 2021 updated',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 5),
                            const Divider(
                              color: Colors.grey,
                              thickness: 0.2,
                            ),
                            const SizedBox(height: 5),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.description_outlined,
                                          color: Colors.grey),
                                      const SizedBox(width: 5),
                                      const Text('Agreement Policy',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isAgreementPolicySelected =
                                              !_isAgreementPolicySelected;
                                        });
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: _isAgreementPolicySelected
                                                  ? Colors.blue
                                                  : Colors.grey),
                                          color: _isAgreementPolicySelected
                                              ? Colors.blue
                                              : Colors.transparent,
                                        ),
                                        child: _isAgreementPolicySelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      )),
                                ]),
                            const SizedBox(height: 5),
                            const Text(
                                'I hereby agree to the terms and conditions of the lease agreement with you',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey))
                          ],
                        )),
                    const SizedBox(height: 15),
                    // Price Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _carDetails.containsKey('pricePerHour')
                              ? '₹ ${_carDetails['pricePerHour']}/hour'
                              : '₹ 0.00',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Price Summary',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToDateTimeScreen(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReviewCard(double width, dynamic review) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
              review['comment'] ?? 'No comment', // Display the actual comment
              style: const TextStyle(fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                for (int i = 0; i < (review['rating'] ?? 0); i++)
                  Icon(Icons.star, size: 14, color: Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imageBytes) {
    if (imageBytes != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(imageBytes),
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        print('Error decoding image: $e');
        return const SizedBox.shrink(); // return an empty widget
      }
    } else {
      return const SizedBox.shrink(); // return an empty widget
    }
  }
}
