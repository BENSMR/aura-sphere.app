import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/loyalty_config_model.dart';
import '../models/reward_config_model.dart';
import '../models/event_reward_model.dart';
import '../models/loyalty_campaign_model.dart';
import '../services/loyalty_service.dart';

class LoyaltyAdminScreen extends StatefulWidget {
  const LoyaltyAdminScreen({super.key});

  @override
  State<LoyaltyAdminScreen> createState() => _LoyaltyAdminScreenState();
}

class _LoyaltyAdminScreenState extends State<LoyaltyAdminScreen> {
  final _loyaltyService = LoyaltyService();
  final _functions = FirebaseFunctions.instance;
  bool _isLoading = false;
  int _selectedTab = 0;

  // Loyalty Config Controllers
  late TextEditingController _dailyBaseCtrl;
  late TextEditingController _dailyStreakCtrl;
  late TextEditingController _dailyMaxCtrl;
  late TextEditingController _weeklyThresholdCtrl;
  late TextEditingController _weeklyBonusCtrl;

  // Reward Config Controllers
  late TextEditingController _rewardDailyCtrl;
  late TextEditingController _rewardMultiplierCtrl;
  late TextEditingController _rewardWeeklyCtrl;
  late TextEditingController _rewardMonthlyCtrl;
  late TextEditingController _rewardSignupCtrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _dailyBaseCtrl = TextEditingController(text: '50');
    _dailyStreakCtrl = TextEditingController(text: '10');
    _dailyMaxCtrl = TextEditingController(text: '500');
    _weeklyThresholdCtrl = TextEditingController(text: '7');
    _weeklyBonusCtrl = TextEditingController(text: '500');

    _rewardDailyCtrl = TextEditingController(text: '5');
    _rewardMultiplierCtrl = TextEditingController(text: '1.2');
    _rewardWeeklyCtrl = TextEditingController(text: '25');
    _rewardMonthlyCtrl = TextEditingController(text: '100');
    _rewardSignupCtrl = TextEditingController(text: '200');
  }

  Future<void> _saveLoyaltyConfig() async {
    setState(() => _isLoading = true);
    try {
      final callable = _functions.httpsCallable('setLoyaltyConfig');
      await callable.call({
        'daily': {
          'baseReward': int.parse(_dailyBaseCtrl.text),
          'streakBonus': int.parse(_dailyStreakCtrl.text),
          'maxStreakBonus': int.parse(_dailyMaxCtrl.text),
        },
        'weekly': {
          'thresholdDays': int.parse(_weeklyThresholdCtrl.text),
          'bonus': int.parse(_weeklyBonusCtrl.text),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Loyalty config saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRewardConfig() async {
    setState(() => _isLoading = true);
    try {
      final callable = _functions.httpsCallable('setRewardConfig');
      await callable.call({
        'dailyReward': double.parse(_rewardDailyCtrl.text),
        'streakMultiplier': double.parse(_rewardMultiplierCtrl.text),
        'weeklyBonus': double.parse(_rewardWeeklyCtrl.text),
        'monthlyBonus': double.parse(_rewardMonthlyCtrl.text),
        'signupBonus': double.parse(_rewardSignupCtrl.text),
        'enabled': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reward config saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('💎 Loyalty Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Loyalty Config'),
              Tab(text: 'Reward Config'),
              Tab(text: 'Event Rewards'),
              Tab(text: 'Campaigns'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLoyaltyConfigTab(),
            _buildRewardConfigTab(),
            _buildEventRewardsTab(),
            _buildCampaignsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Bonus Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTextField(_dailyBaseCtrl, 'Base Daily Reward', 'tokens'),
          _buildTextField(_dailyStreakCtrl, 'Streak Bonus (per day)', 'tokens'),
          _buildTextField(_dailyMaxCtrl, 'Max Streak Bonus Cap', 'tokens'),
          const SizedBox(height: 24),
          const Text(
            'Weekly Bonus Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTextField(_weeklyThresholdCtrl, 'Threshold Days', 'days'),
          _buildTextField(_weeklyBonusCtrl, 'Weekly Bonus', 'tokens'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveLoyaltyConfig,
            icon: const Icon(Icons.save),
            label: const Text('Save Loyalty Config'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Simplified Reward Config',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTextField(_rewardDailyCtrl, 'Daily Reward', 'tokens'),
          _buildTextField(_rewardMultiplierCtrl, 'Streak Multiplier', 'x'),
          _buildTextField(_rewardWeeklyCtrl, 'Weekly Bonus', 'tokens'),
          _buildTextField(_rewardMonthlyCtrl, 'Monthly Bonus', 'tokens'),
          _buildTextField(_rewardSignupCtrl, 'Signup Bonus', 'tokens'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveRewardConfig,
            icon: const Icon(Icons.save),
            label: const Text('Save Reward Config'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRewardsTab() {
    return StreamBuilder<List<EventReward>>(
      stream: _loyaltyService.streamEventRewards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rewards = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              onPressed: () => _showEventRewardDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Event Reward'),
            ),
            const SizedBox(height: 16),
            ...rewards.map((reward) => Card(
              child: ListTile(
                title: Text(reward.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Condition: ${reward.condition}'),
                    Text('Reward: ${reward.reward} tokens'),
                    Text('Active: ${reward.active ? '✅' : '❌'}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEventRewardDialog(reward: reward),
                ),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildCampaignsTab() {
    return StreamBuilder<List<LoyaltyCampaign>>(
      stream: _loyaltyService.streamCampaigns(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final campaigns = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              onPressed: () => _showCampaignDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Campaign'),
            ),
            const SizedBox(height: 16),
            ...campaigns.map((campaign) => Card(
              child: ListTile(
                title: Text(campaign.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Multiplier: ${campaign.multiplier}x'),
                    Text('Date: ${campaign.campaignDate.toString().split(' ')[0]}'),
                    Text('Active: ${campaign.active ? '✅' : '❌'}'),
                    Text('Date Active: ${campaign.isDateActive() ? '🟢' : '⚪'}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showCampaignDialog(campaign: campaign),
                ),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _showEventRewardDialog({EventReward? reward}) {
    final titleCtrl = TextEditingController(text: reward?.title ?? '');
    final conditionCtrl =
        TextEditingController(text: reward?.condition ?? '');
    final rewardCtrl = TextEditingController(
      text: reward?.reward.toString() ?? '',
    );
    final descCtrl =
        TextEditingController(text: reward?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reward == null ? 'Add Event Reward' : 'Edit Event Reward'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conditionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  hintText: 'e.g., invoice_created',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rewardCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reward (tokens)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final callable =
                    _functions.httpsCallable('setEventReward');
                await callable.call({
                  'id': reward?.id,
                  'title': titleCtrl.text,
                  'condition': conditionCtrl.text,
                  'reward': int.parse(rewardCtrl.text),
                  'description': descCtrl.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Event reward saved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCampaignDialog({LoyaltyCampaign? campaign}) {
    final nameCtrl = TextEditingController(text: campaign?.name ?? '');
    final multiplierCtrl = TextEditingController(
      text: campaign?.multiplier.toString() ?? '2.0',
    );
    final dateCtrl = TextEditingController(
      text: campaign?.campaignDate.toString().split(' ')[0] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(campaign == null ? 'Add Campaign' : 'Edit Campaign'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Campaign Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: multiplierCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Multiplier (e.g., 2.0)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final callable =
                    _functions.httpsCallable('setLoyaltyCampaign');
                await callable.call({
                  'id': campaign?.id,
                  'name': nameCtrl.text,
                  'campaignDate': dateCtrl.text,
                  'multiplier': double.parse(multiplierCtrl.text),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Campaign saved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dailyBaseCtrl.dispose();
    _dailyStreakCtrl.dispose();
    _dailyMaxCtrl.dispose();
    _weeklyThresholdCtrl.dispose();
    _weeklyBonusCtrl.dispose();
    _rewardDailyCtrl.dispose();
    _rewardMultiplierCtrl.dispose();
    _rewardWeeklyCtrl.dispose();
    _rewardMonthlyCtrl.dispose();
    _rewardSignupCtrl.dispose();
    super.dispose();
  }
}
