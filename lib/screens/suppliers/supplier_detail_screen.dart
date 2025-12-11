import 'package:flutter/material.dart';
import '../../models/supplier.dart';
import 'supplier_form_screen.dart';

class SupplierDetailScreen extends StatelessWidget {
  final Supplier supplier;
  const SupplierDetailScreen({Key? key, required this.supplier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SupplierFormScreen(editing: supplier),
                ),
              );
              if (changed == true) {
                Navigator.pop(context, true);
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.contact != null)
              Text(
                'Contact: ${supplier.contact}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 6),
            if (supplier.email != null) Text('Email: ${supplier.email}'),
            if (supplier.phone != null) Text('Phone: ${supplier.phone}'),
            const SizedBox(height: 12),
            if (supplier.address != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(supplier.address!),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (supplier.currency != null)
                  Chip(label: Text('Currency: ${supplier.currency}')),
                const SizedBox(width: 8),
                if (supplier.paymentTerms != null)
                  Chip(label: Text('Terms: ${supplier.paymentTerms}')),
                const SizedBox(width: 8),
                Chip(label: Text('Lead: ${supplier.leadTimeDays ?? '-'} days'))
              ],
            ),
            const SizedBox(height: 12),
            if (supplier.notes != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(supplier.notes!),
                ],
              ),
            const SizedBox(height: 12),
            if (supplier.preferred)
              const Chip(
                label: Text('★ Preferred Supplier'),
                avatar: Icon(Icons.star, color: Colors.amber),
                backgroundColor: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }
}
