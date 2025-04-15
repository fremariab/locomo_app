import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';

// This screen shows the FAQs page with search and shortcut features
class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<Map<String, String>> _allFaqs = [];
  List<Map<String, String>> _filteredFaqs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFAQs(); // Load FAQs from Firestore
    _searchController.addListener(_filterFaqs); // Filter as user types
  }

  // Get FAQs from Firestore and save them to memory
  Future<void> _fetchFAQs() async {
    final snapshot = await FirebaseFirestore.instance.collection('faqs').get();

    final data = snapshot.docs.map((doc) {
      final docData = doc.data();
      return {
        'question': docData['question']?.toString() ?? '',
        'answer': docData['answer']?.toString() ?? '',
      };
    }).toList();

    setState(() {
      _allFaqs = data;
      _filteredFaqs = data;
    });
  }

  // Filter the list of FAQs based on search input
  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqs = _allFaqs
          .where((faq) => faq['question']!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSearchBar(),
              const SizedBox(height: 22),
              ..._filteredFaqs.map((faq) => _buildFaqItem(faq)).toList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Top header bar with title
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      color: const Color(0xFFC32E31),
      child: const Text(
        'FAQs',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Input field for searching questions
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search FAQs...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Each FAQ question with its expandable answer
  Widget _buildFaqItem(Map<String, String> faq) {
    return ExpansionTile(
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          faq['question'] ?? '',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            faq['answer'] ?? '',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
