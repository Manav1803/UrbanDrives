// date_time_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../daterangepicker.dart';
import 'form_button.dart';

class DateTimeScreen extends StatefulWidget {
  final Function onNext;
  final Function(DateTime?) onStartDateChanged;
  final Function(TimeOfDay?) onStartTimeChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(TimeOfDay?) onEndTimeChanged;
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;

  const DateTimeScreen({
    Key? key,
    required this.onNext,
    required this.onStartDateChanged,
    required this.onStartTimeChanged,
    required this.onEndDateChanged,
    required this.onEndTimeChanged,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
  }) : super(key: key);

  @override
  DateTimeScreenState createState() => DateTimeScreenState();
}

class DateTimeScreenState extends State<DateTimeScreen> {
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.startDate;
    _selectedStartTime = widget.startTime;
    _selectedEndDate = widget.endDate;
    _selectedEndTime = widget.endTime;
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: const DateRangePicker(),
        );
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedStartDate = result['startDate'] as DateTime?;
        _selectedEndDate = result['endDate'] as DateTime?;
        _selectedStartTime = result['pickupTime'] as TimeOfDay?;
        _selectedEndTime = result['dropoffTime'] as TimeOfDay?;

        widget.onStartDateChanged(_selectedStartDate);
        widget.onStartTimeChanged(_selectedStartTime);
        widget.onEndDateChanged(_selectedEndDate);
        widget.onEndTimeChanged(_selectedEndTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(
                width: 8,
              ),
              const Text(
                'Car Sharing Dates & Time',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector( // Added GestureDetector
            onTap: () => _showDateRangePicker(context), //Show DateRangePicker on Tap
            child: Container(
              width: double.infinity, // Take full width
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start Date & Time Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Start Date & Time',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          _selectedStartDate != null && _selectedStartTime != null
                              ? DateFormat('d MMM yyyy h:mm a').format(DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day, _selectedStartTime!.hour, _selectedStartTime!.minute))
                              : 'Not Selected',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    // End Date & Time Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'End Date & Time',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          _selectedEndDate != null && _selectedEndTime != null
                              ? DateFormat('d MMM yyyy h:mm a').format(DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day, _selectedEndTime!.hour, _selectedEndTime!.minute))
                              : 'Not Selected',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Removed Elevated Button

                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          SizedBox(
            width: double.infinity,
            child: FormButton(
              onPressed: () {
                if (_selectedStartDate == null ||
                    _selectedStartTime == null ||
                    _selectedEndDate == null ||
                    _selectedEndTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select Start Date, Start time, End Date and End time',
                      ),
                    ),
                  );
                  return;
                }
                widget.onNext();
              },
              label: 'Continue',
            ),
          ),
        ],
      ),
    );
  }
}