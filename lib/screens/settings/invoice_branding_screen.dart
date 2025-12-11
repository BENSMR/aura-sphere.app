import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/branding_provider.dart';
import '../../services/branding_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher_string.dart';

class InvoiceBrandingScreen extends StatefulWidget {
  const InvoiceBrandingScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceBrandingScreen> createState() => _InvoiceBrandingScreenState();
}

class _InvoiceBrandingScreenState extends State<InvoiceBrandingScreen> {
  final _primaryController = TextEditingController();
  final _accentController = TextEditingController();
  final _textController = TextEditingController();
  final _footerController = TextEditingController();
  final _watermarkController = TextEditingController();
  bool _saving = false;
  String? _logoUrl;
  String? _signatureUrl;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final provider = Provider.of<BrandingProvider>(context, listen: false);
      provider.load(uid).then((_) {
        final s = provider.settings ?? {};
        _primaryController.text = s['primaryColor'] ?? '#0A84FF';
        _accentController.text = s['accentColor'] ?? '#00FFC8';
        _textController.text = s['textColor'] ?? '#0D0D12';
        _footerController.text = s['footerNote'] ?? '';
        _watermarkController.text = s['watermarkText'] ?? 'PAID';
        setState(() {
          _logoUrl = s['logoUrl'];
          _signatureUrl = s['signatureUrl'];
        });
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final file = File(picked.path);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _saving = true);
    final svc = BrandingService();
    final url = await svc.uploadFile(uid, file, 'branding/logo');
    setState(() {
      _logoUrl = url;
      _saving = false;
    });
  }

  Future<void> _pickSignature() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final file = File(picked.path);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _saving = true);
    final svc = BrandingService();
    final url = await svc.uploadFile(uid, file, 'branding/signature');
    setState(() {
      _signatureUrl = url;
      _saving = false;
    });
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _saving = true);
    final svc = BrandingService();
    final settings = {
      'logoUrl': _logoUrl,
      'signatureUrl': _signatureUrl,
      'primaryColor': _primaryController.text.trim(),
      'accentColor': _accentController.text.trim(),
      'textColor': _textController.text.trim(),
      'footerNote': _footerController.text.trim(),
      'watermarkText': _watermarkController.text.trim(),
      // templateId is left unchanged here unless the user selected from gallery
    };
    await svc.saveBranding(uid, settings);
    final provider = Provider.of<BrandingProvider>(context, listen: false);
    await provider.load(uid);
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Branding saved')));
  }

  Future<void> _preview() async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('generateInvoicePreview');
    final sample = {
      'companyName': 'Preview Company',
      'invoiceNumber': 'AURA-PREVIEW-1'
    };
    final res = await callable.call({'sampleInvoice': sample});
    final url = (res.data as Map)['url'] as String?;
    if (url != null) await launchUrlString(url);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branding & Templates')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Logo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _logoUrl != null
              ? Image.network(_logoUrl!, width: 160, height: 80, fit: BoxFit.contain)
              : Container(height: 80, color: Colors.grey[200], width: 160),
          TextButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.upload_file), label: const Text('Upload Logo')),
          const SizedBox(height: 12),
          const Text('Signature (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _signatureUrl != null
              ? Image.network(_signatureUrl!, width: 160, height: 80, fit: BoxFit.contain)
              : Container(height: 80, color: Colors.grey[200], width: 160),
          TextButton.icon(onPressed: _pickSignature, icon: const Icon(Icons.upload_file), label: const Text('Upload Signature')),
          const SizedBox(height: 12),
          const Text('Colors (hex)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _primaryController, decoration: InputDecoration(labelText: 'Primary Color (#hex)')),
          TextField(controller: _accentController, decoration: InputDecoration(labelText: 'Accent Color')),
          TextField(controller: _textController, decoration: InputDecoration(labelText: 'Text Color')),
          const SizedBox(height: 12),
          TextField(controller: _footerController, decoration: InputDecoration(labelText: 'Footer note')),
          TextField(controller: _watermarkController, decoration: InputDecoration(labelText: 'Watermark text')),
          const SizedBox(height: 16),
          Row(children: [
            ElevatedButton(onPressed: _save, child: _saving ? CircularProgressIndicator(color: Colors.white) : Text('Save Branding')),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: _preview, child: const Text('Preview Sample')),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/settings/templates');
              },
              icon: Icon(Icons.photo_library_outlined),
              label: Text('Choose Template'),
            ),
          ]),
          const SizedBox(height: 18),
          const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (_logoUrl != null) Image.network(_logoUrl!, width: 100, height: 50),
                  const SizedBox(width: 12),
                  Text(_primaryController.text.isEmpty ? 'Your Company' : 'Your Company', style: TextStyle(fontSize: 18, color: Color(int.parse((_primaryController.text.replaceAll('#','0xFF')).replaceAll('0xFFFF', '0xFF'))),))
                ]),
                const SizedBox(height: 8),
                Text('Invoice • AURA-0001', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Customer: John Doe'),
                const SizedBox(height: 8),
                Text('Total: 100.00 EUR', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          )
        ]),
      ),
    );
  }
}
