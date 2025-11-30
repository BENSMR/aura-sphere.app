import 'package:flutter/material.dart';
import '../../services/invoice/invoice_template_service.dart';
import '../../services/business/business_profile_service.dart';

class InvoiceTemplateSelectScreen extends StatefulWidget {
  final String userId;
  const InvoiceTemplateSelectScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _InvoiceTemplateSelectScreenState createState() => _InvoiceTemplateSelectScreenState();
}

class _InvoiceTemplateSelectScreenState extends State<InvoiceTemplateSelectScreen> {
  final svc = BusinessProfileService();
  String? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await svc.getBusinessProfile(widget.userId);
    final d = doc.exists ? doc.data() as Map<String, dynamic> : {};
    setState(()=> _selected = d['invoiceTemplate'] ?? InvoiceTemplateService.minimal);
    setState(()=> _loading = false);
  }

  Future<void> _save() async {
    await svc.saveBusinessProfile(widget.userId, {'invoiceTemplate': _selected});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Template saved')));
    Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    final available = InvoiceTemplateService.available;
    return Scaffold(
      appBar: AppBar(title: Text('Choose Invoice Template')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Expanded(child: ListView(
            children: available.entries.map((e) {
              final key = e.key;
              final name = e.value;
              return Card(
                child: ListTile(
                  leading: Radio<String>(value: key, groupValue: _selected, onChanged: (v)=>setState(()=>_selected=v)),
                  title: Text(name),
                  subtitle: Text('Preview of $name'),
                  onTap: ()=>setState(()=>_selected=key),
                ),
              );
            }).toList(),
          )),
          ElevatedButton(onPressed: _save, child: Text('Save Template'))
        ]),
      ),
    );
  }
}
