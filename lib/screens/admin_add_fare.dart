import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddFareScreen extends StatefulWidget {
  const AdminAddFareScreen({super.key});

  @override
  State<AdminAddFareScreen> createState() => _AdminAddFareScreenState();
}

class _AdminAddFareScreenState extends State<AdminAddFareScreen> {
  final _formKey = GlobalKey<FormState>();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final fareController = TextEditingController();
  final isStopToStop = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fare'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isStopToStop,
                builder: (_, value, __) => Row(
                  children: [
                    const Text('Fare Type:'),
                    const SizedBox(width: 12),
                    DropdownButton<bool>(
                      value: value,
                      onChanged: (val) => isStopToStop.value = val!,
                      items: const [
                        DropdownMenuItem(value: false, child: Text('Station to Station')),
                        DropdownMenuItem(value: true, child: Text('Stop to Stop')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInput('From ID', fromController),
              _buildInput('To ID', toController),
              _buildInput('Fare', fareController, isNumber: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC32E31),
                ),
                child: const Text('Add Fare'),
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
          if (isNumber && double.tryParse(value.trim()) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final from = fromController.text.trim();
    final to = toController.text.trim();
    final fare = double.parse(fareController.text.trim());
    final fareId = '${from}_${to}';
    final collection = isStopToStop.value ? 'stop_to_stop' : 'station_to_station';

    await FirebaseFirestore.instance
        .collection('fares')
        .doc(collection)
        .set({fareId: fare}, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fare added successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    fareController.dispose();
    super.dispose();
  }
}