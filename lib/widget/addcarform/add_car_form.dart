import 'package:flutter/material.dart';
import 'package:zoomwheels/widget/host_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'additional_details_screen.dart';
import 'congratulations_screen.dart';
import 'date_time_screen.dart';
import 'eligibility_screen.dart';
import 'pickup_location_screen.dart';
import 'upload_images_screen.dart';

class AddCarForm extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userId;

  const AddCarForm({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.userId,
  }) : super(key: key);

  @override
  AddCarFormState createState() => AddCarFormState();
}

class AddCarFormState extends State<AddCarForm> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  // Form Keys for validation
  final _formKeyEligibility = GlobalKey<FormState>();
  final _formKeyAdditional = GlobalKey<FormState>();
  final _formKeyLocation = GlobalKey<FormState>();

  // Form Variables
  String? _CarRegistrationNumber;
  String? _carBrand;
  String? _carModel;
  String? _yearOfRegistration;
  String? _city;
  String? _kmDriven;
  String? _chassisNumber;
  String? _fuelType;
  String? _transmissionType;
  String? _pricePerHour;
  String? _pickupLocation;
  String? _seatingCapacity;
  String? _bodyType;


//Date and Time Variables
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  Map<String, dynamic> _carDetails = {}; // Store car details
  Map<String, dynamic> _imageDetails = {}; // Store car details

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    setState(() {
      _currentPage++;
    });
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    setState(() {
      _currentPage--;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _uploadCarDetailsToBackend(Map<String, dynamic> carData) async {
    final url = Uri.parse('http://127.0.0.1:5000/add-car');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(carData),
      );
          print("Response from server: ${response.statusCode}, ${response.body}");


      if (response.statusCode == 201) {
        _showSnackBar('Car details added successfully!');
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => CongratulationsScreen(
                      continueAction: () {
                         Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HostNavBar(
                                userName: widget.userName,
                                carDetails: _carDetails,
                                userEmail: widget.userEmail,
                                userId: widget.userId,
                            ),
                          ),
                        );
                        },
                      carDetails: _carDetails,
                    )),
          );
      } else {
        _showSnackBar('Failed to add car details: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error communicating with server: $e');
           print("Error communicating with server: $e");

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
        title: const Text('Host App'),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          EligibilityScreen(
            formKey: _formKeyEligibility,
            onNext: _nextPage,
            onCarRegistrationNumberChanged: (value) => _CarRegistrationNumber = value,
            onCarBrandChanged: (value) => _carBrand = value,
            onCarModelChanged: (value) => _carModel = value,
            onYearOfRegistrationChanged: (value) => _yearOfRegistration = value,
            onCityChanged: (value) => _city = value,
            onKmDrivenChanged: (value) => _kmDriven = value,
            onSeatingCapacityChanged: (value) => _seatingCapacity = value,
            onBodyTypeChanged: (value) => _bodyType = value,
            kmDriven: _kmDriven,
            seatingCapacity: _seatingCapacity,
            bodyType: _bodyType,
            enabled: true, // Add the required 'enabled' parameter
          ),
          AdditionalDetailsScreen(
            formKey: _formKeyAdditional,
            onNext: _nextPage,
            onChassisNumberChanged: (value) => _chassisNumber = value,
            onFuelTypeChanged: (value) => _fuelType = value,
            onTransmissionTypeChanged: (value) => _transmissionType = value,
            onPricePerHourChanged: (value) => _pricePerHour = value,
            fuelType: _fuelType,
            transmissionType: _transmissionType,
            enabled: true, // Add the required 'enabled' parameter
          ),
          PickupLocationScreen(
            formKey: _formKeyLocation,
            onNext: _nextPage,
            onPickupLocationChanged: (value) {
              _pickupLocation = value;
            },
          ),
          DateTimeScreen(
            onNext: _nextPage,
            onStartDateChanged: (value) => _startDate = value,
            onStartTimeChanged: (value) => _startTime = value,
            onEndDateChanged: (value) => _endDate = value,
            onEndTimeChanged: (value) => _endTime = value,
            startDate: _startDate,
            startTime: _startTime,
            endDate: _endDate,
            endTime: _endTime,
          ),
          UploadImagesScreen(
              onNext: () async {
                  try{
                    // Combine all car data
                  _carDetails = {
                      'userId': widget.userId,
                      'CarRegistrationNumber': _CarRegistrationNumber,
                      'carBrand': _carBrand,
                      'carModel': _carModel,
                      'yearOfRegistration': _yearOfRegistration,
                      'city': _city,
                      'kmDriven': _kmDriven,
                      'chassisNumber': _chassisNumber,
                      'fuelType': _fuelType,
                      'transmissionType': _transmissionType,
                      'pricePerHour': _pricePerHour,
                      'pickupLocation': _pickupLocation,
                      'seatingCapacity': _seatingCapacity,
                      'bodyType': _bodyType,
                      'startDate': _startDate?.toIso8601String(),
                      'startTime': _startTime?.format(context),
                      'endDate': _endDate?.toIso8601String(),
                      'endTime': _endTime?.format(context),
                      ..._imageDetails,
                    };
                 await _uploadCarDetailsToBackend(_carDetails);
                }
                catch (e) {
                      print('Error during onNext callback: $e');
                      _showSnackBar('Error: $e');
                  }
              },
              uploadCarDetails: (imageDetails) {
                  _imageDetails = imageDetails;
              }),
        ],
      ),
    );
  }
}