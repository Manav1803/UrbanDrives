import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';


import 'admin_cars_screen.dart';
import 'admin_user_screen.dart';
import 'admin_trips_screen.dart' as trips;
import 'admin_bookings_screen.dart';
import 'banner_screen.dart';
import 'city_map_screen.dart';

// Model Classes (Outside of any Widget class)
class DashboardData {
  final int totalCars;
  final int totalUsers;
  final int totalTrips;
  final int totalBookings;

  DashboardData({
    required this.totalCars,
    required this.totalUsers,
    required this.totalTrips,
    required this.totalBookings,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalCars: json['total_cars'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      totalTrips: json['total_trips'] ?? 0,
      totalBookings: json['total_bookings'] ?? 0,
    );
  }

  factory DashboardData.empty() {
    return DashboardData(
      totalCars: 0,
      totalUsers: 0,
      totalTrips: 0,
      totalBookings: 0,
    );
  }
}

// CarTripData model class
class CarTripData {
  final String carModel;
  final int totalTrips;
  final double totalAmount;

  CarTripData({
    required this.carModel,
    required this.totalTrips,
    required this.totalAmount,
  });

  factory CarTripData.fromJson(Map<String, dynamic> json) {
    return CarTripData(
      carModel: json['carModel'] ?? '',
      totalTrips: json['totalTrips'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

// Widget Classes (Top-level)
class AdminDashboardScreen extends StatefulWidget {
  final String? selectedMenu;

  AdminDashboardScreen({Key? key, this.selectedMenu = 'Dashboard'})
      : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late String _selectedMenu;
  DashboardData _dashboardData = DashboardData.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMenu = widget.selectedMenu!;
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    final response =
        await http.get(Uri.parse('http://localhost:5000/dashboard-data'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _dashboardData = DashboardData.fromJson(data);
        _isLoading = false;
      });
    } else {
      print('Failed to load dashboard data: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to load dashboard data. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Added: Method to refresh when Users are deleted by this event call
  void refreshDashboard() {
    _fetchDashboardData(); // recall fetch data!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8FF),
      body: Row(
        children: [
          Sidebar(
            selectedMenu: _selectedMenu,
            onMenuSelected: (menu) {
              setState(() {
                _selectedMenu = menu;
              });
            },
          ),
          Expanded(
            flex: 5,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildMainContent(_selectedMenu),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(String selectedMenu) {
    return Builder(builder: (context) {
      //Builder context
      switch (selectedMenu) {
        case 'Dashboard':
          return DashboardMainContent(dashboardData: _dashboardData);
        case 'Cars':
          return CarsMainContent(onCarsChanged: refreshDashboard);
        case 'User':
          return AdminUserScreen(onUsersChanged: refreshDashboard);
        case 'Trip':
          return trips.AdminTripsScreen();
        case 'Bookings':
          return AdminBookingsScreen();
        case 'City':
          return CityMapScreen();
        case 'Banners':
          return Bannerscreen();
        case 'FAQ\'s':
          return Center(child: Text('FAQ\'s Screen Content'));
        case 'Help':
          return Center(child: Text('Help Screen Content'));
        default:
          return Container();
      }
    });
  }
}

class LineChartWidget extends StatelessWidget {
  final List<FlSpot> chartData;
  final bool hasData;
  final int year; // Add year parameter
  final int month; // Add month parameter

  const LineChartWidget(
      {Key? key,
      required this.chartData,
      required this.hasData,
      required this.year,
      required this.month})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return hasData
        ? LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Check if the day is a multiple of 3
                      if (value.toInt() % 3 == 0) {
                        return Text(
                          value.toInt().toString(), // Just the day
                          style: TextStyle(fontSize: 10),
                        );
                      } else {
                        return const Text('');
                      }
                    },
                    reservedSize: 22,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(),
                rightTitles: AxisTitles(),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: 1,
              maxX: _getDaysInMonth(year, month)
                  .toDouble(), // Set maxX to the number of days in the selected month
              minY: 0,
              maxY: 15,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          )
        : Center(child: Text('We do not have the data for this month'));
  }

  // Helper function to get the number of days in a month
  int _getDaysInMonth(int year, int month) {
    if (month == DateTime.february) {
      final bool isLeap =
          (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const List<int> daysInMonth = <int>[
      31,
      -1,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31
    ];
    return daysInMonth[month - 1];
  }
}


// BarChartWidget class
class BarChartWidget extends StatefulWidget {
  final List<CarTripData> carTripData;
  final bool hasData; // Added boolean to check the hasData

  BarChartWidget({required this.carTripData, required this.hasData}); // Modify the parameter

  @override
  State<StatefulWidget> createState() => BarChartWidgetState();
}

// BarChartWidgetState class
class BarChartWidgetState extends State<BarChartWidget> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3.0, // Increased aspect ratio
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(
                'Car Model Trips',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 38,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: widget.hasData
                      ? BarChart(
                          mainBarData(),
                        )
                      : Center(
                          child: Text(
                              'We do not have the data for this month - year')),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            final carModel = widget.carTripData[groupIndex].carModel;
            final totalTrips = widget.carTripData[groupIndex].totalTrips;
            final totalAmount = widget.carTripData[groupIndex].totalAmount;
            return BarTooltipItem(
              '$carModel\nTrips: $totalTrips\nEarnings: ₹${totalAmount.toStringAsFixed(2)}',
              TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: titlesData(),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
      gridData: FlGridData(show: false),
    );
  }

  FlTitlesData titlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40, // Increased reservedSize to 40
          getTitlesWidget: (double value, TitleMeta meta) {
            if (value >= 0 && value < widget.carTripData.length) {
              final carModel = widget.carTripData[value.toInt()].carModel;
              return Transform.rotate(
                angle: -0.5, // Rotate the text by -30 degrees
                child: Text(
                  carModel,
                  style: TextStyle(fontSize: 10),
                ),
              );
            }
            return const Text(''); // Or some default value if out of range
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<BarChartGroupData> showingGroups() {
    return List.generate(widget.carTripData.length, (i) {
      return makeGroupData(i, widget.carTripData[i].totalTrips.toDouble(),
          isTouched: i == touchedIndex);
    });
  }

  BarChartGroupData makeGroupData(int x, double y, {bool isTouched = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.blue.shade800],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 30, // Increased the width of the bars
          borderRadius: BorderRadius.zero, // Removed circular borders
          borderSide: isTouched
              ? const BorderSide(color: Colors.yellow, width: 1)
              : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: Colors.grey.shade200,
          ),
        ),
      ],
      showingTooltipIndicators: isTouched ? [0] : [],
    );
  }
}

class DashboardMainContent extends StatefulWidget {
  final DashboardData dashboardData;

  DashboardMainContent({required this.dashboardData});

  @override
  _DashboardMainContentState createState() => _DashboardMainContentState();
}

class _DashboardMainContentState extends State<DashboardMainContent> {
  String _selectedMonthYear = DateFormat('MMMM-yyyy').format(DateTime.now());
  List<CarTripData> _carTripData = [];
  List<FlSpot> _chartData = [];
  bool _isLoadingChart = false;
  String _currentDataType = 'group';
  String _selectedYear = DateTime.now().year.toString();
  List<Map<String, int>> _monthlyData = [];
  DateTime _firstMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isCurrentMonth = true;
  bool _hasLineData = true;

  // Add the new state variables
  String _chartType = 'Bar Chart'; // Default chart type: bar or line
  List<String> _chartTypeOptions = ['Bar Chart', 'Line Chart'];

  @override
  void initState() {
    super.initState();
    _fetchGroupedData(
        chartType:
            _chartType); // Or fetch grouped line chart data, depending on your API
  }

  // Modify _fetchGroupedData to accept chartType
  Future<void> _fetchGroupedData({String chartType = 'Bar Chart'}) async {
    setState(() {
      _isLoadingChart = true;
      _currentDataType = 'group';
    });

    // Modify the API URL based on the chart type
    String apiUrl = 'http://localhost:5000/monthly-summary';

    if (chartType == 'Line Chart') {
      apiUrl =
          'http://localhost:5000/monthly-summary-line'; // Assuming you have a separate endpoint
    }

    apiUrl += '?year=$_selectedYear';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _isLoadingChart = false;
          _monthlyData = List<Map<String, int>>.from(data.map((item) {
            return {
              'month': (item['month'] as num).toInt(),
              'users': (item['users'] as num).toInt(),
              'cars': (item['cars'] as num).toInt(),
              'trips': (item['trips'] as num).toInt(),
              'bookings': (item['bookings'] as num).toInt()
            };
          }));
        });
      } else {
        print('Failed to load grouped data: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load grouped data.')),
        );
        setState(() {
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      print('Failed to load grouped data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to load grouped data, check your connection.')),
      );
      setState(() {
        _isLoadingChart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          SizedBox(height: 20.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Total Car',
                    value: widget.dashboardData.totalCars.toString(),
                    icon: Icons.car_rental,
                    onTap: () => _handleCardTap('cars'),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: SummaryCard(
                    title: 'User',
                    value: widget.dashboardData.totalUsers.toString(),
                    icon: Icons.person,
                    onTap: () => _handleCardTap('users'),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: SummaryCard(
                    title: 'Trip',
                    value: widget.dashboardData.totalTrips.toString(),
                    icon: Icons.local_taxi,
                    onTap: () => _handleCardTap('trips'),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: SummaryCard(
                    title: 'Bookings',
                    value: widget.dashboardData.totalBookings.toString(),
                    icon: Icons.book_online,
                    onTap: () => _handleCardTap('bookings'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (_currentDataType != 'group')
                _buildStyledDropdown<String>(
                  value: _selectedMonthYear,
                  items: _getMonthYearOptions()
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMonthYear = newValue!;
                      _fetchChartData(_currentDataType);
                    });
                  },
                ),
              if (_currentDataType == 'group')
                _buildStyledDropdown<String>(
                  value: _selectedYear,
                  items: _getYearOptions()
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedYear = newValue!;
                      _fetchGroupedData(
                          chartType:
                              _chartType); // Refetch the data with current chart type.
                    });
                  },
                ),

              // Add the chart type dropdown here
              if (_currentDataType == 'group')
                _buildStyledDropdown<String>(
                  value: _chartType,
                  items: _chartTypeOptions
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _chartType = newValue!;
                      _fetchGroupedData(
                          chartType:
                              _chartType); // Refetch the data with current chart type.
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: 30.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _isLoadingChart
                ? Center(child: CircularProgressIndicator())
                : _currentDataType == 'group'
                    ? _chartType == 'Bar Chart'
                        ? _buildGroupedBarChart()
                        : _buildGroupedLineChart() // Conditionally build the bar or line chart
                    : SizedBox(
                        height: 300, // Adjust height as needed
                        child: _currentDataType == 'cars'
                            ? BarChartWidget(
                                carTripData: _carTripData, hasData: _hasLineData)
                            : LineChartWidget(
                                chartData: _chartData,
                                hasData: _hasLineData,
                                year: int.parse(_selectedMonthYear.split('-')[1]),
                                month: DateFormat('MMMM')
                                    .parse(_selectedMonthYear.split('-')[0])
                                    .month),
                      ),
          ),
          SizedBox(height: 30.0),
        ],
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white, // White background
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2), // subtle shadow
            ),
          ],
        ),
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: Container(), // Remove the underline
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
          isDense: true,
          isExpanded: false,
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGroupedBarChart() {
    if (_selectedYear != DateTime.now().year.toString()) {
      return Center(child: Text('No data available for this year'));
    }

    List<String> monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    List<BarChartGroupData> barGroups = [];

    const Color userColor = Color(0xFF4394E5);
    const Color carsColor = Color(0xFFF5921B);
    const Color tripsColor = Color(0xFF5E40BE);
    const Color bookingsColor = Color(0xFF63993D);

    for (int i = 0; i < 12; i++) {
      int users = _monthlyData.isNotEmpty ? _monthlyData[i]['users'] ?? 0 : 0;
      int trips = _monthlyData.isNotEmpty ? _monthlyData[i]['trips'] ?? 0 : 0;
      int bookings =
          _monthlyData.isNotEmpty ? _monthlyData[i]['bookings'] ?? 0 : 0;
      int cars = _monthlyData.isNotEmpty ? _monthlyData[i]['cars'] ?? 0 : 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: users.toDouble(), color: userColor, width: 8),
            BarChartRodData(toY: cars.toDouble(), color: carsColor, width: 8),
            BarChartRodData(toY: trips.toDouble(), color: tripsColor, width: 8),
            BarChartRodData(
                toY: bookings.toDouble(), color: bookingsColor, width: 8),
          ],
        ),
      );
    }

    return Column(
      // Wrap the chart and legend in a Column
      children: [
        Row(
          // Add a Row for the legend
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem(userColor, 'Users'),
            SizedBox(width: 8), // Add some spacing between legend items
            _buildLegendItem(carsColor, 'Cars'),
            SizedBox(width: 8),
            _buildLegendItem(tripsColor, 'Trips'),
            SizedBox(width: 8),
            _buildLegendItem(bookingsColor, 'Bookings'),
          ],
        ),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(monthLabels[value.toInt()],
                          style: TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: AxisTitles(),
                rightTitles: AxisTitles(),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

// Add a new function to build the grouped line chart
  Widget _buildGroupedLineChart() {
    // Check if any data exists for the selected year
    bool hasAnyData = false;
    if (_monthlyData.isNotEmpty) {
      for (int i = 0; i < 12; i++) {
        if (_monthlyData[i]['users'] != 0 ||
            _monthlyData[i]['cars'] != 0 ||
            _monthlyData[i]['trips'] != 0 ||
            _monthlyData[i]['bookings'] != 0) {
          hasAnyData = true;
          break;
        }
      }
    }

    if (!hasAnyData) {
      return Center(child: Text('No data available for this year'));
    }

    List<FlSpot> userSpots = [];
    List<FlSpot> carSpots = [];
    List<FlSpot> tripSpots = [];
    List<FlSpot> bookingSpots = [];

    for (int i = 0; i < 12; i++) {
      int users = _monthlyData.isNotEmpty ? _monthlyData[i]['users'] ?? 0 : 0;
      int cars = _monthlyData.isNotEmpty ? _monthlyData[i]['cars'] ?? 0 : 0;
      int trips = _monthlyData.isNotEmpty ? _monthlyData[i]['trips'] ?? 0 : 0;
      int bookings =
          _monthlyData.isNotEmpty ? _monthlyData[i]['bookings'] ?? 0 : 0;

      userSpots.add(FlSpot(i.toDouble(), users.toDouble()));
      carSpots.add(FlSpot(i.toDouble(), cars.toDouble()));
      tripSpots.add(FlSpot(i.toDouble(), trips.toDouble()));
      bookingSpots.add(FlSpot(i.toDouble(), bookings.toDouble()));
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const monthLabels = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec'
                  ];
                  return Text(monthLabels[value.toInt()],
                      style: TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: AxisTitles(),
            rightTitles: AxisTitles(),
          ),
          borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1)),
          lineBarsData: [
            _buildLineChartBarData(userSpots, const Color(0xFF4394E5), 'Users'),
            _buildLineChartBarData(carSpots, const Color(0xFFF5921B), 'Cars'),
            _buildLineChartBarData(tripSpots, const Color(0xFF5E40BE), 'Trips'),
            _buildLineChartBarData(
                bookingSpots, const Color(0xFF63993D), 'Bookings'),
          ],
        ),
      ),
    );
  }

  // Helper function to build the LineChartBarData with custom colors
  LineChartBarData _buildLineChartBarData(
      List<FlSpot> spots, Color color, String label) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      // Add label to the line (optional)
      // You can customize the label appearance further
      // label: label,
    );
  }

  // Helper widget for building the legend items
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // Helper funtion to manage the chart by tap the card
  void _handleCardTap(String dataType) {
    // Get the correct formatted date with now current day.
    String currentDate = DateFormat('MMMM-yyyy').format(DateTime.now());
    setState(() {
      _currentDataType = dataType; // set as now datatype
      // After setting up the date, set selected month with correct data.
      // _selectedMonthYear = currentDate;
    });

    _fetchChartData(dataType);
    // Move it here to make sure call get_all_cars!
  }

  Future<void> _fetchChartData(String dataType) async {
    setState(() {
      _isLoadingChart = true;
      _currentDataType = dataType; // Update the current data type
    });

    // Extract year and month from _selectedMonthYear string
    final parts = _selectedMonthYear.split('-');
    final monthName = parts[0];
    final year = int.parse(parts[1]);
    final month = DateFormat('MMMM').parse(monthName).month; // Convert month name to number

    String apiUrl;
    if (dataType == 'cars') {
      // Load data for the bar chart - PASS YEAR AND MONTH
      apiUrl =
          'http://localhost:5000/car-trip-data?year=$year&month=$month'; // Corrected URL
    } else {
      // Line chart data
      apiUrl =
          'http://localhost:5000/line-chart-data?dataType=$dataType&year=$year&month=$month';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        setState(() {
          _isLoadingChart = false;

          if (dataType == 'cars') {
            // Bar chart data
            _carTripData = (data as List)
                .map((item) => CarTripData.fromJson(item))
                .toList();
            _chartData = []; // Clear line chart data
            _hasLineData =
                _carTripData.isNotEmpty; // Set based on carTripData
            _selectedMonthYear = DateFormat('MMMM-yyyy')
                .format(DateTime(year, month)); //Update value when setting the Data to re-render.
          } else {
            // Line chart data
            _carTripData = []; // Clear bar chart data
            _chartData = (data as List)
                .map((item) => FlSpot(
                    item['day'].toDouble(), item['count'].toDouble()))
                .toList();
            _hasLineData = _chartData.isNotEmpty; // Set based on chartData
            _selectedMonthYear = DateFormat('MMMM-yyyy')
                .format(DateTime(year, month)); //Update value when setting the Data to re-render.
          }
        });
      } else {
        print('Failed to load chart data: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chart data.')),
        );
        setState(() {
          _isLoadingChart = false;
          _hasLineData = false;
        });
      }
    } catch (e) {
      print('Failed to load chart data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chart data, check your connection.')),
      );
      setState(() {
        _isLoadingChart = false;
        _hasLineData = false;
      });
    }
  }

  List<String> _getMonthYearOptions() {
    List<String> monthYearOptions = [];
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(now.year, now.month);

    // Generate options from current month to the same month of the previous year
    for (int i = 0; i < 12; i++) {
      DateTime month = DateTime(currentMonth.year, currentMonth.month - i);
      monthYearOptions.add(DateFormat('MMMM-yyyy').format(month));
    }

    // set dropdown's current month/year with formatted value to show first
    _selectedMonthYear = DateFormat('MMMM-yyyy').format(currentMonth);

    return monthYearOptions;
  }

  List<String> _getYearOptions() {
    List<String> years = [];
    int currentYear = DateTime.now().year;
    for (int i = currentYear; i >= 2020; i--) {
      years.add(i.toString());
    }
    return years;
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the content vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center the content horizontally
            children: [
              Container(
                  padding: EdgeInsets.all(16.0), // Add padding around the icon
                  decoration: BoxDecoration(
                    color: Colors.green[50], // Use light green for the background
                    borderRadius: BorderRadius.circular(
                        20.0), // Add rounded corners to the background
                  ),
                  child:
                      Icon(icon, size: 30.0, color: Colors.green)), // Adjust icon size

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
            ],
          ),
        ),
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;

  const Sidebar({Key? key, required this.selectedMenu, required this.onMenuSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 25, left: 15, bottom: 20, right: 15),
            child: Row(
              children: [
                Icon(Icons.settings_outlined,
                    size: 28, color: Colors.black87),
                SizedBox(width: 10),
                Text(
                  'Urban Drives',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SidebarMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard,
            isSelected: selectedMenu == 'Dashboard',
            onTap: () {
              onMenuSelected('Dashboard');
            },
          ),
          SidebarMenuItem(
            title: 'Cars',
            icon: Icons.directions_car,
            isSelected: selectedMenu == 'Cars',
            onTap: () {
              onMenuSelected('Cars');
            },
          ),
          SidebarMenuItem(
            title: 'User',
            icon: Icons.person_outline,
            isSelected: selectedMenu == 'User',
            onTap: () {
              onMenuSelected('User');
            },
          ),
          SidebarMenuItem(
            title: 'Trip',
            icon: Icons.local_taxi_outlined,
            isSelected: selectedMenu == 'Trip',
            onTap: () {
              onMenuSelected('Trip');
            },
          ),
          SidebarMenuItem(
            title: 'Bookings',
            icon: Icons.book_online,
            isSelected: selectedMenu == 'Bookings',
            onTap: () {
              onMenuSelected('Bookings');
            },
          ),
          // Add this new SidebarMenuItem here
          SidebarMenuItem(
            title: 'City',
            icon: Icons.location_city,  // Or a suitable icon
            isSelected: selectedMenu == 'City',
            onTap: () {
              onMenuSelected('City');
            },
          ),
          SidebarMenuItem(
            title: 'Banners',
            icon: Icons.image_aspect_ratio, // Or a suitable icon
            isSelected: selectedMenu == 'Banners',
            onTap: () {
              onMenuSelected('Banners');
            },
          ),
          SidebarMenuItem(
            title: 'FAQ\'s',
            icon: Icons.info_outline,
            isSelected: selectedMenu == 'FAQ\'s',
            onTap: () {
              onMenuSelected('FAQ\'s');
            },
          ),
          SidebarMenuItem(
            title: 'Help',
            icon: Icons.question_answer,
            isSelected: selectedMenu == 'Help',
            onTap: () {
              onMenuSelected('Help');
            },
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                ),
                SizedBox(width: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 14)),
                    Text('Admin',
                        style: TextStyle(
                            color: Color(0xFF757575), fontSize: 12)),
                  ],
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.black54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarMenuItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(10, 0, 10, title == 'Help' ? 0 : 10),
      decoration: isSelected
          ? BoxDecoration(
              color: Color(0xFF3F51B5),
              borderRadius: BorderRadius.circular(8.0),
            )
          : null,
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            color: isSelected ? Colors.white : Color(0xFF757575)),
        title: Text(
          title,
          style: TextStyle(
              color: isSelected ? Colors.white : Color(0xFF757575)),
        ),
        onTap: onTap as void Function()?,
      ),
    );
  }
}