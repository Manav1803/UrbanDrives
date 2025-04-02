import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class DateOfBirthPicker extends StatefulWidget {
  const DateOfBirthPicker({
    Key? key,
    this.initialDate,
    this.minDate,
    this.maxDate,
  }) : super(key: key);


  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;


  @override
  State<DateOfBirthPicker> createState() => _DateOfBirthPickerState();
}


class _DateOfBirthPickerState extends State<DateOfBirthPicker> {
   DateTime? _dateOfBirth;  // Make this public by removing "_"


  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _dateOfBirth = widget.initialDate ?? DateTime.now();
    _selectedYear = _dateOfBirth?.year;
    _selectedMonth = _dateOfBirth?.month;
  }


  void _sendDataBack() {
    Navigator.of(context).pop({
      'dateOfBirth': _dateOfBirth,
    });
  }


  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;
    final years = List.generate(
        currentYear - 1900 + 1, (index) => 1900 + index); // Years 1900 to now
    final months = List.generate(12, (index) => index + 1); // Months 1 to 12


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Select Date of Birth',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _dateOfBirth = null;
                _selectedYear = null;
                _selectedMonth = null;
              });
            },
            child: const Text(
              'CLEAR',
              style: TextStyle(color: Colors.blue),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(_dateOfBirth != null
                ? 'Date of Birth: ${DateFormat('EEE, dd MMM, yyyy').format(_dateOfBirth!)}'
                : 'Select Date of Birth'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<int>(
                hint: const Text('Year'),
                value: _selectedYear,
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                    _updateDateOfBirth();
                  });
                },
              ),
              DropdownButton<int>(
                hint: const Text('Month'),
                value: _selectedMonth,
                items: months.map((month) {
                  // Disable months after the current month in the current year
                  bool isDisabled =
                      _selectedYear == currentYear && month > currentMonth;


                  return DropdownMenuItem(
                    value: month,
                    enabled: !isDisabled, // Disable future months
                    child: Text(
                      DateFormat('MMMM').format(DateTime(2023, month)),
                      style: TextStyle(
                        color: isDisabled
                            ? Colors.grey
                            : null, // Style disabled months
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value;
                    _updateDateOfBirth();
                  });
                },
              ),
            ],
          ),
          Expanded(
            // Use Expanded to fill the remaining space
            child: _buildCalendar(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_dateOfBirth != null) {
                  _sendDataBack();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please select Date of Birth')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 162, 236),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Date of Birth',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCalendar(BuildContext context) {
    if (_selectedYear == null || _selectedMonth == null) {
      return const Center(child: Text('Select year and month'));
    }


    DateTime firstDayOfMonth = DateTime(_selectedYear!, _selectedMonth!, 1);
    int daysInMonth = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
    int firstWeekdayOfMonth = firstDayOfMonth.weekday;


    List<DateTime> daysList = [];
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final currentDay = now.day;


    // Add empty days from the previous month
    for (int i = 1; i < firstWeekdayOfMonth; i++) {
      daysList.add(firstDayOfMonth.subtract(Duration(
          days: firstWeekdayOfMonth - i))); // Dates from the previous month
    }


    // Add all the dates of the current month
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime date = DateTime(_selectedYear!, _selectedMonth!, i);
      daysList.add(date);
    }


    // Add dates from the next month to fill out the last week, if needed
    int daysAfterMonth = (daysList.length) % 7;
    if (daysAfterMonth != 0) {
      int nextMonthDaysToAdd = 7 - daysAfterMonth;
      for (int i = 1; i <= nextMonthDaysToAdd; i++) {
        daysList.add(DateTime(_selectedYear!, _selectedMonth! + 1, i));
      }
    }


    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: daysList.length,
      itemBuilder: (context, index) {
        final date = daysList[index];
        return _buildCalendarDay(date);
      },
    );
  }


  Widget _buildCalendarDay(DateTime date) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final currentDay = now.day;


    bool isSelected = _dateOfBirth != null &&
        date.year == _dateOfBirth!.year &&
        date.month == _dateOfBirth!.month &&
        date.day == _dateOfBirth!.day;


    // Disable dates after the current day in the current month and year
    bool isDisabled = date.year > currentYear ||
        (date.year == currentYear && date.month > currentMonth) ||
        (date.year == currentYear &&
            date.month == currentMonth &&
            date.day > currentDay);


    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              //Disable on tap if it is disabled
              setState(() {
                _dateOfBirth = date;
              });
            },
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[200] : null,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          date.day.toString(),
          style: TextStyle(
            color: isDisabled
                ? Colors.grey
                : isSelected
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      ),
    );
  }


  void _updateDateOfBirth() {
    if (_selectedYear != null && _selectedMonth != null) {
      // Update _dateOfBirth with the selected year and month, keeping the day as 1
      // This is a placeholder until the user selects a specific day in the calendar
      setState(() {
        _dateOfBirth = DateTime(_selectedYear!, _selectedMonth!, 1);
      });
    }
  }
}