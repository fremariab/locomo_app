import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddStopScreen extends StatefulWidget {
  const AdminAddStopScreen({super.key});

  @override
  State<AdminAddStopScreen> createState() => _AdminAddStopScreenState();
}

class _AdminAddStopScreenState extends State<AdminAddStopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  String? _selectedStationId;

  List<String> _stationIds = [];

  @override
  void initState() {
    super.initState();
    _fetchStationIds();
  }

  Future<void> _fetchStationIds() async {
    final snapshot = await FirebaseFirestore.instance.collection('stations').get();
    setState(() {
      _stationIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Stop'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput('Stop Name', _nameController),
              _buildInput('Latitude', _latController, isNumber: true),
              _buildInput('Longitude', _lngController, isNumber: true),
              DropdownButtonFormField<String>(
                value: _selectedStationId,
                items: _stationIds
                    .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStationId = val),
                decoration: const InputDecoration(
                  labelText: 'Nearby Station ID',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Please select a station ID' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC32E31),
                ),
                child: const Text('Add Stop'),
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

    final stopData = {
      'id': _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
      'name': _nameController.text.trim(),
      'coordinates': {
        'lat': double.parse(_latController.text.trim()),
        'lng': double.parse(_lngController.text.trim()),
      },
      'type': 'stop',
      'nearbyStationId': _selectedStationId,
    };

    await FirebaseFirestore.instance
        .collection('stops')
        .doc(stopData['id'] as String?)
        .set(stopData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stop added successfully!')),
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
