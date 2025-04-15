import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddRouteScreen extends StatefulWidget {
  const AdminAddRouteScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddRouteScreen> createState() => _AdminAddRouteScreenState();
}

class _AdminAddRouteScreenState extends State<AdminAddRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _stopsController = TextEditingController();
  final _fareController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Route'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput('Route Name', _routeNameController),
              _buildInput('Origin', _originController),
              _buildInput('Destination', _destinationController),
              _buildInput('Stops (comma-separated)', _stopsController),
              _buildInput('Fare (optional)', _fareController, isNumber: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC32E31),
                ),
                child: const Text('Add Route'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }
          if (isNumber && value.trim().isNotEmpty && double.tryParse(value.trim()) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final stopsList = _stopsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (stopsList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least 2 stops.')),
      );
      return;
    }

    final routeData = {
      'id': _routeNameController.text.trim().toLowerCase().replaceAll(' ', '_'),
      'routeName': _routeNameController.text.trim(),
      'origin': _originController.text.trim(),
      'destination': _destinationController.text.trim(),
      'fare': _fareController.text.trim().isEmpty
          ? null
          : double.tryParse(_fareController.text.trim()),
      'stops': stopsList,
    };

    await FirebaseFirestore.instance
        .collection('routes')
        .doc(routeData['id'] as String?)
        .set(routeData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route added successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _stopsController.dispose();
    _fareController.dispose();
    super.dispose();
  }
}
