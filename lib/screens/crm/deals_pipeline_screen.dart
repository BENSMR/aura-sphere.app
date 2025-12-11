// lib/screens/crm/deals_pipeline_screen.dart

import 'package:flutter/material.dart';
import '../../models/deal_model.dart';
import '../../services/deal_service.dart';

class DealsPipelineScreen extends StatelessWidget {
  const DealsPipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = [
      'lead',
      'contacted',
      'proposal',
      'negotiation',
      'won',
      'lost',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Pipeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create deal screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create deal coming soon')),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: stages
            .map(
              (stage) => Expanded(
                child: _DealsColumn(stage: stage),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DealsColumn extends StatelessWidget {
  final String stage;
  final DealService _service = DealService();

  _DealsColumn({required this.stage});

  String getStageLabel(String stage) {
    switch (stage) {
      case 'lead':
        return 'Lead';
      case 'contacted':
        return 'Contacted';
      case 'proposal':
        return 'Proposal';
      case 'negotiation':
        return 'Negotiation';
      case 'won':
        return 'Won';
      case 'lost':
        return 'Lost';
      default:
        return stage;
    }
  }

  Color getStageColor(BuildContext context) {
    switch (stage) {
      case 'lead':
        return Colors.grey.shade200;
      case 'contacted':
        return Colors.blue.shade50;
      case 'proposal':
        return Colors.orange.shade50;
      case 'negotiation':
        return Colors.purple.shade50;
      case 'won':
        return Colors.green.shade50;
      case 'lost':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: getStageColor(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              getStageLabel(stage),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DealModel>>(
              stream: _service.streamDealsByStage(stage),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                
                final deals = snapshot.data ?? [];
                if (deals.isEmpty) {
                  return const Center(
                    child: Text(
                      'No deals',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: deals.length,
                  itemBuilder: (_, index) {
                    final deal = deals[index];
                    return _DealCard(
                      deal: deal,
                      onChangeStage: (newStage) =>
                          _service.updateDealStage(deal.id, newStage),
                      onMarkWon: () => _service.markDealWon(deal.id),
                      onMarkLost: () => _service.markDealLost(deal.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final DealModel deal;
  final ValueChanged<String> onChangeStage;
  final VoidCallback onMarkWon;
  final VoidCallback onMarkLost;

  const _DealCard({
    required this.deal,
    required this.onChangeStage,
    required this.onMarkWon,
    required this.onMarkLost,
  });

  @override
  Widget build(BuildContext context) {
    final prob = deal.winProbability.toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          _showDealActions(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deal.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "${deal.currency}${deal.amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.bolt, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    "$prob%",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (deal.expectedCloseDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(deal.expectedCloseDate!),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
              if (deal.ai != null && deal.ai!['nextStep'] != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Next Step:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deal.ai?['nextStep'] ?? '',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    
    if (diff < 0) {
      return 'Overdue';
    } else if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Tomorrow';
    } else if (diff < 7) {
      return 'In $diff days';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _showDealActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text("Mark as WON"),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onMarkWon();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deal marked as won! 🎉')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text("Mark as LOST"),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onMarkLost();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deal marked as lost')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.compare_arrows),
                title: const Text("Move to stage..."),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final chosen = await _pickStage(context);
                  if (chosen != null) {
                    onChangeStage(chosen);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Moved to $chosen')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("View details"),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // TODO: Navigate to deal details screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deal details coming soon')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickStage(BuildContext context) async {
    const stages = [
      'lead',
      'contacted',
      'proposal',
      'negotiation',
      'won',
      'lost',
    ];
    
    final stageLabels = {
      'lead': 'Lead',
      'contacted': 'Contacted',
      'proposal': 'Proposal',
      'negotiation': 'Negotiation',
      'won': 'Won',
      'lost': 'Lost',
    };
    
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Move to stage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...stages
                  .map(
                    (s) => ListTile(
                      title: Text(stageLabels[s] ?? s),
                      onTap: () => Navigator.of(ctx).pop(s),
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }
}
