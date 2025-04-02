// DateTimeSelectionScreen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'date_time_selection_helper.dart'; // Import the helper file

class DateTimeSelectionScreen extends StatefulWidget {
  final DateTime? initialPickupDate;
  final DateTime? initialReturnDate;
  final String carRegNum;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String carStartDate;
  final String carStartTime;

  const DateTimeSelectionScreen({
    Key? key,
    this.initialPickupDate,
    this.initialReturnDate,
    required this.carRegNum,
    this.minDate,
    this.maxDate,
    required this.carStartDate,
    required this.carStartTime,
  }) : super(key: key);

  @override
  DateTimeSelectionScreenState createState() => DateTimeSelectionScreenState();
}

class DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  late DateTime _minDate;
  late DateTime _maxDate;

  @override
  void initState() {
    super.initState();
    _calculateMinMaxDates();
    _initializeTimes(); //Initialize Times from start values

    // Initialize pickup and return dates. Set pickup to minDate and return to one day after.
    _pickupDate = _minDate;
    //_pickupTime = TimeOfDay.fromDateTime(_minDate);
    _returnDate = _minDate.add(const Duration(days: 1));
    //_returnTime = TimeOfDay.fromDateTime(_minDate);
  }

  void _initializeTimes() {
    try {
      DateFormat timeFormat = DateFormat("h:mm a");
      DateTime parsedTime = timeFormat.parse(widget.carStartTime);
      _pickupTime = TimeOfDay.fromDateTime(parsedTime);
      _returnTime = TimeOfDay.fromDateTime(parsedTime);
    } catch (e) {
      print("Error parsing carStartTime: $e");
      _pickupTime = const TimeOfDay(hour: 12, minute: 0);
      _returnTime = const TimeOfDay(hour: 12, minute: 0);
    }
  }

  void _calculateMinMaxDates() {
    DateTime carStartDateTime = DateTime(2100); // Far Future

    // Parse to DateTime
    try {
      String datestr = widget.carStartDate;
      String timestr = widget.carStartTime;

      DateTime carStartDate = DateTime.parse(datestr);
      DateFormat timeFormat = DateFormat("h:mm a"); // e.g., 10:30 AM
      DateTime parsedTime = timeFormat.parse(timestr);
      TimeOfDay carStartTimeOfDay = TimeOfDay.fromDateTime(parsedTime);

      carStartDateTime = DateTime(
          carStartDate.year,
          carStartDate.month,
          carStartDate.day,
          carStartTimeOfDay.hour,
          carStartTimeOfDay.minute); // Merge Date and Time

      print("CAR start date time DateTime.parse(datestr): $carStartDateTime");
      print("CAR start time: $carStartTimeOfDay");
    } catch (e) {
      print("ERROR parsing start date : $e");
    }

    // Determine the actual minimum date (Today's date or carStartDate)
    if (DateTime.now().isAfter(carStartDateTime)) {
      print(
          "Today is AFTER car start date, Min time is NOW instead of car start date");
      _minDate = DateTime.now(); // setting current date
    } else {
      print("CAR is AFTER today, Min time is car start date");
      _minDate = carStartDateTime; // use car data
    }

    // Ensure max date is NOW or later to fix DartError assertion message!
    if (widget.maxDate != null) {
      if (widget.maxDate!.isBefore(_minDate)) {
        _maxDate = _minDate;
      } else {
        _maxDate = widget.maxDate!;
      }
    } else {
      _maxDate = DateTime(2100); // Use the maxDate or far future!
    }

    print("maxDate is : $_maxDate");
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDateTimeSelectionDialog(
      context,
      initialPickupDate: _pickupDate,
      initialReturnDate: _returnDate,
      minDate: _minDate,
      maxDate: _maxDate,
      initialPickupTime: _pickupTime, //Pass Initials
      initialReturnTime: _returnTime,
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _pickupDate = result['pickupDate'] as DateTime?;
        _pickupTime = result['pickupTime'] as TimeOfDay?;
        _returnDate = result['returnDate'] as DateTime?;
        _returnTime = result['returnTime'] as TimeOfDay?;
        print("_pickupTime after dialog : $_pickupTime");
        print("_returnTime after dialog : $_returnTime");
      });
    }
  }

  bool get _isDateTimeSelected {
    return _pickupDate != null &&
        _pickupTime != null &&
        _returnDate != null &&
        _returnTime != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date & Time'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showDateRangePicker,
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
                          'Start & End Date/Time',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          _pickupDate != null && _returnDate != null
                              ? '${DateFormat('dd MMM yyyy').format(_pickupDate!)} - ${DateFormat('dd MMM yyyy').format(_returnDate!)}'
                              : "Select Date Range",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _pickupTime != null && _returnTime != null
                              ? '${DateFormat('h:mm a').format(DateTime(2023, 1, 1, _pickupTime!.hour, _pickupTime!.minute))} - ${DateFormat('h:mm a').format(DateTime(2023, 1, 1, _returnTime!.hour, _returnTime!.minute))}'
                              : "Select Time",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDateTimeSelected
                    ? () {
                        Navigator.pop(context, {
                          'pickupDate': _pickupDate,
                          'pickupTime': _pickupTime,
                          'returnDate': _returnDate,
                          'returnTime': _returnTime,
                          'startTime': DateTime(
                                  _pickupDate!.year,
                                  _pickupDate!.month,
                                  _pickupDate!.day,
                                  _pickupTime!.hour,
                                  _pickupTime!.minute)
                              .toString(),
                          'endTime': DateTime(
                                  _returnDate!.year,
                                  _returnDate!.month,
                                  _returnDate!.day,
                                  _returnTime!.hour,
                                  _returnTime!.minute)
                              .toString()
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isDateTimeSelected ? Colors.blue : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Set Date & Time',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
