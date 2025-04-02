import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CarsMainContent extends StatefulWidget {

  final VoidCallback? onCarsChanged;  // ADD:  Callback function to update Dashboard

  CarsMainContent({Key? key, this.onCarsChanged}) : super(key: key);  // ADD onCarsChanged constructor
  
  @override
  _CarsMainContentState createState() => _CarsMainContentState();
}

class _CarsMainContentState extends State<CarsMainContent> {
  List<Car> _cars = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _carsPerPage = 15;
  String _searchQuery = '';
  String _sortBy = 'Newest';
  String? _selectedAvailability; // Null means "all"
  int _availableCarsCount = 0;
  int _ongoingCarsCount = 0;

  static const double imageWidth = 200.0;
  static const double imageHeight = 180.0;
  static const double interItemSpacing = 5.0;
  static const String defaultCarImage = 'assets/default_car.png';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedAvailability = null; // Initialize to null for total cars on load
    _fetchCars();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCars() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http
          .get(Uri.parse('http://localhost:5000/get-average-admin-car-rating'));

      if (response.statusCode == 200) {
        List<dynamic> decodedJson = jsonDecode(response.body);
        _cars = decodedJson.map((json) => Car.fromJson(json)).toList();

        // Calculate available and Ongoing Cars Count
        _availableCarsCount =
            _cars.where((car) => car.isAvailable == true).length;
        _ongoingCarsCount =
            _cars.where((car) => car.isAvailable == false).length;

        _sortCars();
        setState(() {
          _isLoading = false;
        });
      } else {
        print('Failed to load cars: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load cars. Status code: ${response.statusCode}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cars: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching cars.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCar(String carId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this car?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:5000/delete-car-by-admin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'carId': carId}),
        );

        if (response.statusCode == 200) {
          print('Car deleted successfully');
          _fetchCars();
        } else {
          print('Failed to delete car: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to delete car. Please try again later.')),
          );
        }
      } catch (e) {
        print('Error deleting car: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while deleting the car.')),
        );
      }
    } else {
      print('Delete operation cancelled');
    }
  }

  List<Car> _filterCars(List<Car> cars) {
    if (_searchQuery.isEmpty) {
      return cars;
    }
    return cars
        .where((car) =>
            car.carBrand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            car.carModel.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            car.CarRegistrationNumber.toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _sortCars() {
    setState(() {
      if (_sortBy == 'Newest') {
        _cars.sort((a, b) => b.id.compareTo(a.id));
      } else {
        _cars.sort((a, b) => a.id.compareTo(b.id));
      }
    });
  }

  List<Car> getPaginatedCars() {
    List<Car> filteredCars = _cars;

    if (_selectedAvailability == 'Available') {
      filteredCars =
          filteredCars.where((car) => car.isAvailable == true).toList();
    } else if (_selectedAvailability == 'Ongoing') {
      filteredCars =
          filteredCars.where((car) => car.isAvailable == false).toList();
    }

    filteredCars = _filterCars(filteredCars); // Apply search query
    return filteredCars;
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  void _setAvailabilityFilter(String? availability) {
    setState(() {
      _selectedAvailability = availability;
      _currentPage = 1; // Reset to the first page
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Car> filteredCars = getPaginatedCars();
    final totalPages = (filteredCars.length / _carsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _carsPerPage;
    final endIndex = (startIndex + _carsPerPage).clamp(0, filteredCars.length);
    final paginatedCars = filteredCars.sublist(startIndex, endIndex);
    final bool showPagination = filteredCars.length > _carsPerPage;

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 600;
      final crossAxisCount = 3;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cars',
              style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setAvailabilityFilter(null), // Total Cars
                      child: CarSummaryCard(
                        title: 'All Cars',
                        value: _cars.length.toString(),
                        percentageChange: '',
                        icon: Icons.car_rental,
                        isSelected: _selectedAvailability == null,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setAvailabilityFilter('Available'),
                      child: CarSummaryCard(
                        title: 'Available Cars',
                        value: _availableCarsCount.toString(),
                        percentageChange: '',
                        icon: Icons.check_circle,
                        isSelected: _selectedAvailability == 'Available',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setAvailabilityFilter('Ongoing'),
                      child: CarSummaryCard(
                        title: 'Ongoing Cars',
                        value: _ongoingCarsCount.toString(),
                        percentageChange: '',
                        icon: Icons.time_to_leave,
                        isSelected: _selectedAvailability == 'Ongoing',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.0),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : (_cars.isEmpty
                      ? Center(child: Text('No cars found.'))
                      : Scrollbar(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Column(
                                children: [
                                  AllCarsSection(
                                    isDesktop: isDesktop,
                                    cars: paginatedCars,
                                    onDelete: _deleteCar,
                                    imageHeight: imageHeight,
                                    imageWidth: imageWidth,
                                    searchQuery: _searchQuery,
                                    sortBy: _sortBy,
                                    onSearchChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                        _currentPage = 1;
                                      });
                                    },
                                    onSortChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                        _sortCars();
                                      });
                                    },
                                    crossAxisCount: crossAxisCount,
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        )),
            ),
            if (showPagination)
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
                child: Pagination(
                  currentPage: _currentPage,
                  totalPages: totalPages,
                  onPageChanged: _goToPage,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class AllCarsSection extends StatelessWidget {
  final bool isDesktop;
  final List<Car> cars;
  final Function(String) onDelete;
  final double imageWidth;
  final double imageHeight;
  final String searchQuery;
  final String sortBy;
  final Function(String) onSearchChanged;
  final Function(String?) onSortChanged;
  final int crossAxisCount;

  AllCarsSection({
    required this.isDesktop,
    required this.cars,
    required this.onDelete,
    required this.imageHeight,
    required this.imageWidth,
    required this.searchQuery,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Cars',
          style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        SizedBox(height: 10.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: onSearchChanged,
              ),
            ),
            SizedBox(width: 10.0),
            DropdownButton<String>(
              value: sortBy,
              items: <String>['Newest', 'Oldest']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('Sort by: $value',
                      style: TextStyle(color: Colors.black87)),
                );
              }).toList(),
              onChanged: onSortChanged,
              underline: Container(),
            ),
          ],
        ),
        SizedBox(height: 20.0),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: _CarsMainContentState.interItemSpacing,
            mainAxisSpacing: _CarsMainContentState.interItemSpacing,
            childAspectRatio: 2.5,
          ),
          itemCount: cars.length,
          itemBuilder: (BuildContext ctx, index) {
            return CarCard(
                car: cars[index],
                onDelete: onDelete,
                imageHeight: imageHeight,
                imageWidth: imageWidth);
          },
        ),
      ],
    );
  }
}

class CarCard extends StatelessWidget {
  final Car car;
  final Function(String) onDelete;
  final double imageWidth;
  final double imageHeight;

  CarCard({
    required this.car,
    required this.onDelete,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
            child: SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: car.coverImageBytes.isNotEmpty
                  ? (car.coverImageBytes.startsWith('http'))
                      ? Image.network(
                          car.coverImageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            print('Error loading image from URL: $exception');
                            return Image.asset(
                                _CarsMainContentState.defaultCarImage,
                                fit: BoxFit.cover);
                          },
                        )
                      : (car.coverImageBytes.length > 0)
                          ? Image.memory(
                              base64Decode(car.coverImageBytes),
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context, Object exception,
                                  StackTrace? stackTrace) {
                                print('Error decoding image: $exception');
                                return Image.asset(
                                    _CarsMainContentState.defaultCarImage,
                                    fit: BoxFit.cover);
                              },
                            )
                          : Image.asset(_CarsMainContentState.defaultCarImage,
                              fit: BoxFit.cover)
                  : Image.asset(_CarsMainContentState.defaultCarImage,
                      fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${car.carBrand} ${car.carModel}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    car.CarRegistrationNumber,
                    style: TextStyle(
                        fontSize: 10,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${car.transmissionType} • ${car.seatingCapacity} Seater • ${car.fuelType}',
                    style: TextStyle(
                        fontSize: 10,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'City: ${car.city}',
                    style: TextStyle(
                        fontSize: 10,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Host: ${car.hostName}',
                    style: TextStyle(
                        fontSize: 10,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Contact: ${car.hostMobileNumber}',
                    style: TextStyle(
                        fontSize: 10,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < car.averageRating.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ),
                      ),
                      IconButton(
                        alignment: Alignment.bottomRight,
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          onDelete(car.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CarSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String percentageChange;
  final IconData icon;
  final bool isSelected;

  CarSummaryCard({
    required this.title,
    required this.value,
    required this.percentageChange,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: isSelected
              ? BorderSide(color: Colors.blue, width: 2.0)
              : BorderSide.none,
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Icon(icon, size: 30.0, color: Colors.green),
                ),
                SizedBox(height: 10.0),
                Text(title,
                    style: TextStyle(fontSize: 14.0, color: Colors.black54)),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                if (percentageChange.isNotEmpty)
                  Text(percentageChange,
                      style: TextStyle(color: Colors.green[700], fontSize: 12)),
              ],
            ),
          ),
        ));
  }
}

class Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed:
              currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),
        for (int i = 1; i <= totalPages; i++)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onPageChanged(i),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      currentPage == i ? Color(0xFF3F51B5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$i',
                  style: TextStyle(
                      color: currentPage == i ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

class Car {
  final String id;
  final String carBrand;
  final String carModel;
  final String CarRegistrationNumber;
  final String transmissionType;
  final int seatingCapacity;
  final String fuelType;
  final String city;
  final double averageRating;
  final String coverImageBytes;
  final String hostName;
  final String hostMobileNumber;
  final bool isAvailable;

  Car({
    required this.id,
    required this.carBrand,
    required this.carModel,
    required this.CarRegistrationNumber,
    required this.transmissionType,
    required this.seatingCapacity,
    required this.fuelType,
    required this.city,
    required this.averageRating,
    required this.coverImageBytes,
    required this.hostName,
    required this.hostMobileNumber,
    required this.isAvailable,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['_id'] ?? '',
      carBrand: json['carBrand'] ?? '',
      carModel: json['carModel'] ?? '',
      CarRegistrationNumber: json['CarRegistrationNumber'] ?? '',
      transmissionType: json['transmissionType'] ?? '',
      seatingCapacity: (json['seatingCapacity'] is String)
          ? int.tryParse(json['seatingCapacity'] ?? '0') ?? 0
          : json['seatingCapacity'] ?? 0,
      fuelType: json['fuelType'] ?? '',
      city: json['city'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      coverImageBytes: json['coverImageBytes'] ?? '',
      hostName: json['hostName'] ?? 'N/A',
      hostMobileNumber: json['hostMobileNumber'] ?? 'N/A',
      isAvailable: json['is_available'] ?? true, // Default to true if null
    );
  }
}