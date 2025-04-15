import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddStationScreen extends StatefulWidget {
  const AdminAddStationScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddStationScreen> createState() => _AdminAddStationScreenState();
}

class _AdminAddStationScreenState extends State<AdminAddStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  String? _selectedRegion;

  final List<String> _regions = [
    'Greater Accra',
    'Eastern Region',
    'Ashanti Region',
    'Volta Region',
    'Central Region',
    'Northern Region'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Station'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput('Station Name', _nameController),
              _buildInput('Latitude', _latController, isNumber: true),
              _buildInput('Longitude', _lngController, isNumber: true),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                items: _regions
                    .map((region) => DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedRegion = val),
                decoration: const InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Please select a region' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC32E31),
                ),
                child: const Text('Add Station'),
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
          if (isNumber && double.tryParse(value) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final stationData = {
      'id': _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
      'name': _nameController.text.trim(),
      'coordinates': {
        'lat': double.parse(_latController.text.trim()),
        'lng': double.parse(_lngController.text.trim()),
      },
      'region': _selectedRegion,
      'type': 'station',
      'connections': [],
    };

    await FirebaseFirestore.instance
        .collection('stations')
        .doc(stationData['id'] as String?)
        .set(stationData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station added successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }
}