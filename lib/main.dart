import 'package:flutter/material.dart';

import 'screen/admin/admin_dashboard_screen.dart';
import 'screen/auth/auth_Screen.dart';

void main() {
  runApp(const UrbanDrivesApp());
}

class UrbanDrivesApp extends StatelessWidget {
  const UrbanDrivesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Drives',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Adjust to your desired theme
        // Add more theme configurations here like font, appbar etc.
      ),
      // Use initialRoute for the first screen to display or home property
      home: const AuthScreen(), // Example: Start with login screen
    );
  }
}
