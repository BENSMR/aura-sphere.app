import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Template metadata used by the UI (thumbnails come from assets/templates)
final List<Map<String, dynamic>> _templateCatalog = [
  {
    'id': 'TEMPLATE_CLASSIC',
    'name': 'Classic',
    'desc': 'Clean & professional',
    'thumb': 'assets/templates/classic_thumb.png',
    'premium': false
  },
  {
    'id': 'TEMPLATE_MODERN',
    'name': 'Modern',
    'desc': 'Bold headings, strong layout',
    'thumb': 'assets/templates/modern_thumb.png',
    'premium': false
  },
  {
    'id': 'TEMPLATE_MINIMAL',
    'name': 'Minimal',
    'desc': 'Lots of white space',
    'thumb': 'assets/templates/minimal_thumb.png',
    'premium': false
  },
  {
    'id': 'TEMPLATE_ELEGANT',
    'name': 'Elegant',
    'desc': 'Serif style, premium feel',
    'thumb': 'assets/templates/elegant_thumb.png',
    'premium': true
  },
  {
    'id': 'TEMPLATE_BUSINESS',
    'name': 'Business',
    'desc': 'Accounting friendly layout',
    'thumb': 'assets/templates/business_thumb.png',
    'premium': true
  },
];

class TemplateGalleryScreen extends StatefulWidget {
  const TemplateGalleryScreen({Key? key}) : super(key: key);

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> {
  String? _selected;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('branding').doc('settings').get();
    setState(() {
      _selected = doc.exists ? (doc.data()?['templateId'] as String?) : null;
    });
  }

  Future<void> _selectTemplate(String id) async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('branding').doc('settings').set({'templateId': id}, SetOptions(merge: true));
    setState(() {
      _selected = id;
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Template saved: $id')));
  }

  Widget _buildTemplateCard(Map tpl) {
    final id = tpl['id'] as String;
    final name = tpl['name'] as String;
    final desc = tpl['desc'] as String;
    final thumb = tpl['thumb'] as String;
    final premium = tpl['premium'] as bool;
    final selected = id == _selected;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _selectTemplate(id),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(thumb, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (premium)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Premium', style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
                          )
                      ]),
                      const SizedBox(height: 6),
                      Text(desc, style: TextStyle(color: Colors.grey[700])),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  selected
                      ? Column(
                          children: [
                            Chip(label: const Text('Selected'), backgroundColor: Colors.green.shade100),
                          ],
                        )
                      : ElevatedButton(onPressed: () => _selectTemplate(id), child: const Text('Choose'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Templates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: _templateCatalog.map((t) => _buildTemplateCard(t)).toList(),
            ),
    );
  }
}
