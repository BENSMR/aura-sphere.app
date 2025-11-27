import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crm_provider.dart';
import '../../data/models/crm_model.dart';

class CrmPipelineScreen extends StatelessWidget {
  const CrmPipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CrmProvider>();
    final contacts = provider.contacts;

    final stages = {
      'lead': <Contact>[],
      'prospect': <Contact>[],
      'active': <Contact>[],
      'negotiation': <Contact>[],
      'won': <Contact>[],
      'lost': <Contact>[],
    };

    for (var c in contacts) {
      stages[c.status]?.add(c);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("CRM Pipeline")),
      body: ListView(
        children: stages.entries.map((e) {
          final stage = e.key;
          final list = e.value;
          return ExpansionTile(
            title: Text("$stage (${list.length})".toUpperCase()),
            children: list
                .map(
                  (c) => ListTile(
                    title: Text(c.name),
                    subtitle: Text(c.company),
                  ),
                )
                .toList(),
          );
        }).toList(),
      ),
    );
  }
}