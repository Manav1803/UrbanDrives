// date_time_selection_helper.dart
import 'package:flutter/material.dart';
import 'daterangepicker.dart'; // Adjust the import path if needed

Future<dynamic> showDateTimeSelectionDialog(
  BuildContext context, {
  DateTime? initialPickupDate,
  DateTime? initialReturnDate,
  DateTime? minDate,
  DateTime? maxDate,
  TimeOfDay? initialPickupTime,
  TimeOfDay? initialReturnTime,
}) async {
  DateTime? pickupDate = initialPickupDate;
  TimeOfDay? pickupTime = initialPickupTime;
  DateTime? returnDate = initialReturnDate;
  TimeOfDay? returnTime = initialReturnTime;

  final result = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        // Changed to Dialog
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Expanded(
                child: DateRangePicker(
                  startDate: pickupDate,
                  endDate: returnDate,
                  minDate: minDate,
                  maxDate: maxDate,
                  initialPickupTime: pickupTime,
                  initialReturnTime: returnTime,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  print("Result from showDialog: $result");  // DEBUG: Check the result

  if (result != null && result is Map<String, dynamic>) {
    pickupDate = result['startDate'] as DateTime?;
    returnDate = result['endDate'] as DateTime?;
    pickupTime = result['pickupTime'] as TimeOfDay?;
    returnTime = result['dropoffTime'] as TimeOfDay?; // Corrected key!

    print("pickupTime from dialog: $pickupTime");
    print("returnTime from dialog: $returnTime");
  }

  return {
    'pickupDate': pickupDate,
    'pickupTime': pickupTime,
    'returnDate': returnDate,
    'returnTime': returnTime
  };
}

