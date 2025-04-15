import 'package:flutter/material.dart';

// This is the main screen the admin sees after logging in
class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Center(
        child: Text('Welcome Admin!'),
      ),
    );
  }
}
