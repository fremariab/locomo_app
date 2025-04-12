import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';

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
    _fetchFAQs();
    _searchController.addListener(_filterFaqs);
  }

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
              _buildShortcuts(),
              _buildSearchBar(),
              ..._filteredFaqs.map((faq) => _buildFaqItem(faq)).toList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      color: const Color(0xFFFFBD3A37),
      child: const Text(
        'FAQs',
        style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildShortcuts() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Shortcuts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildShortcut(
                  icon: Icons.money_off,
                  text: 'Cancel trip and refund tickets'),
              const SizedBox(width: 16),
              _buildShortcut(icon: Icons.swap_horiz, text: 'Exchange Tickets'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Frequently Asked Questions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

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

  Widget _buildFaqItem(Map<String, String> faq) {
    return ExpansionTile(
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child:
            Text(faq['question'] ?? '', style: const TextStyle(fontSize: 16)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(faq['answer'] ?? '',
              style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildShortcut({required IconData icon, required String text}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFBD3A37),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 16),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
