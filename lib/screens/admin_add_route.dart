import 'package:flutter/material.dart';

// This screen lets an admin add a new trotro route
class AdminAddRoutePage extends StatefulWidget {
  const AdminAddRoutePage({Key? key}) : super(key: key);

  @override
  State<AdminAddRoutePage> createState() => _AdminAddRoutePageState();
}

class _AdminAddRoutePageState extends State<AdminAddRoutePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all input fields
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController fareController = TextEditingController();
  final TextEditingController transferController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  // When user hits "submit", collect all the data
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newRoute = {
        "origin": originController.text.trim(),
        "destination": destinationController.text.trim(),
        "time": int.tryParse(timeController.text.trim()) ?? 0,
        "fare": double.tryParse(fareController.text.trim()) ?? 0.0,
        "transfers": int.tryParse(transferController.text.trim()) ?? 0,
        "details": detailsController.text.trim(),
        "departure_time": "6:15 AM",
        "arrival_time": "7:00 AM",
      };

      // Placeholder debugPrint — later this should upload to Firebase
      debugPrint("Route Submitted: $newRoute");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Route successfully added!")),
      );

      // Reset all fields
      originController.clear();
      destinationController.clear();
      timeController.clear();
      fareController.clear();
      transferController.clear();
      detailsController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Route"),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(originController, "Origin"),
              _buildTextField(destinationController, "Destination"),
              _buildTextField(timeController, "Estimated Time (minutes)", isNumber: true),
              _buildTextField(fareController, "Fare (GHS)", isNumber: true),
              _buildTextField(transferController, "Transfer Count", isNumber: true),
              _buildTextField(detailsController, "Route Details", maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC32E31),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // This builds each input field with consistent styling
  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }
}
