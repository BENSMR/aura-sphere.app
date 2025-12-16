import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mobile_layout_provider.dart';

/// Mobile Feature Customization Screen
/// Users can enable/disable and reorder features (max 8)
class CustomizeMobileDashboardScreen extends StatefulWidget {
  const CustomizeMobileDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CustomizeMobileDashboardScreen> createState() =>
      _CustomizeMobileDashboardScreenState();
}

class _CustomizeMobileDashboardScreenState
    extends State<CustomizeMobileDashboardScreen> {
  late List<MapEntry<String, bool>> _featuresList;
  bool _isReordering = false;

  // Feature metadata: name, description, icon
  static const Map<String, Map<String, String>> featureMetadata = {
    'scanReceipts': {
      'title': '📸 Scan Receipts',
      'description': 'OCR receipt scanning for expenses'
    },
    'quickContacts': {
      'title': '👥 Quick Contacts',
      'description': 'Fast access to your contacts'
    },
    'sendInvoices': {
      'title': '📧 Send Invoices',
      'description': 'Create and send invoices on mobile'
    },
    'inventoryStock': {
      'title': '📦 Inventory Stock',
      'description': 'Track inventory and stock levels'
    },
    'taskBoard': {
      'title': '✅ Task Board',
      'description': 'Manage your tasks and to-dos'
    },
    'loyaltyPoints': {
      'title': '⭐ Loyalty Points',
      'description': 'View and manage loyalty rewards'
    },
    'walletBalance': {
      'title': '💰 Wallet Balance',
      'description': 'Check your digital wallet'
    },
    'aiAlerts': {
      'title': '🤖 AI Alerts',
      'description': 'AI-powered notifications and alerts'
    },
    'fullReports': {
      'title': '📊 Full Reports',
      'description': 'Detailed business analytics'
    },
    'teamManagement': {
      'title': '👔 Team Management',
      'description': 'Manage your team members'
    },
    'advancedSettings': {
      'title': '⚙️ Advanced Settings',
      'description': 'System and integration settings'
    },
    'dashboard': {
      'title': '📈 Dashboard',
      'description': 'Business overview and KPIs'
    },
  };

  @override
  void initState() {
    super.initState();
    _featuresList = [];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileLayoutProvider>(
      builder: (context, layoutProvider, child) {
        if (layoutProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Customize Mobile Dashboard'),
              backgroundColor: const Color(0xFF050A1F),
              elevation: 0,
            ),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E0FF)),
              ),
            ),
          );
        }

        // Initialize features list from provider
        if (_featuresList.isEmpty) {
          _featuresList = layoutProvider.mobileModules.entries.toList();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customize Mobile Dashboard'),
            backgroundColor: const Color(0xFF050A1F),
            elevation: 0,
            actions: [
              if (_isReordering)
                TextButton(
                  onPressed: () {
                    setState(() => _isReordering = false);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFF00E0FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.reorder, color: Color(0xFF00E0FF)),
                  onPressed: () {
                    setState(() => _isReordering = true);
                  },
                  tooltip: 'Reorder features',
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose up to ${layoutProvider.maxFeatures} features',
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enabled: ${layoutProvider.enabledFeatureCount} / ${layoutProvider.maxFeatures}',
                        style: const TextStyle(
                          color: Color(0xFFA0A0C0),
                          fontSize: 14,
                        ),
                      ),
                      if (layoutProvider.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5588).withOpacity(0.1),
                              border: Border.all(
                                color: const Color(0xFFFF5588),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              layoutProvider.error ?? '',
                              style: const TextStyle(
                                color: Color(0xFFFF5588),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(
                  color: Color(0xFF1A1A3E),
                  height: 1,
                ),
                // Features list
                if (_isReordering)
                  _buildReorderableList(context, layoutProvider)
                else
                  _buildToggleList(context, layoutProvider),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _resetToDefault(context, layoutProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset to Default'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF000000),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.done),
                        label: const Text('Save & Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E0FF),
                          foregroundColor: const Color(0xFF000000),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build toggle list (normal view)
  Widget _buildToggleList(
      BuildContext context, MobileLayoutProvider layoutProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _featuresList.length,
      itemBuilder: (context, index) {
        final feature = _featuresList[index].key;
        final isEnabled = _featuresList[index].value;
        final metadata = featureMetadata[feature] ?? {};

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF00E0FF).withOpacity(0.1)
                : const Color(0xFF0C0C1C).withOpacity(0.65),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFF00E0FF)
                  : const Color(0xFFFFFFFF).withOpacity(0.08),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              metadata['title'] ?? feature,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              metadata['description'] ?? '',
              style: const TextStyle(
                color: Color(0xFFA0A0C0),
                fontSize: 12,
              ),
            ),
            trailing: Switch(
              value: isEnabled,
              onChanged: (value) async {
                if (!value ||
                    layoutProvider.enabledFeatureCount < layoutProvider.maxFeatures) {
                  await layoutProvider.toggleFeature(feature);
                  _featuresList[index] =
                      MapEntry(feature, layoutProvider.mobileModules[feature] ?? false);
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum ${layoutProvider.maxFeatures} features allowed',
                      ),
                      backgroundColor: const Color(0xFFFF5588),
                    ),
                  );
                }
              },
              activeColor: const Color(0xFF00E0FF),
            ),
          ),
        );
      },
    );
  }

  /// Build reorderable list (drag-to-reorder view)
  Widget _buildReorderableList(
      BuildContext context, MobileLayoutProvider layoutProvider) {
    final enabledFeatures = _featuresList
        .where((e) => e.value)
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0A0A12),
          child: const Text(
            'Drag to reorder enabled features',
            style: TextStyle(
              color: Color(0xFFA0A0C0),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = enabledFeatures.removeAt(oldIndex);
              enabledFeatures.insert(newIndex, item);

              // Update the main list
              _featuresList = [
                ...enabledFeatures,
                ..._featuresList.where((e) => !e.value),
              ];
            });
          },
          children: [
            for (int i = 0; i < enabledFeatures.length; i++)
              _buildDraggableFeatureTile(
                key: ValueKey(enabledFeatures[i].key),
                feature: enabledFeatures[i].key,
                index: i,
              ),
          ],
        ),
      ],
    );
  }

  /// Build draggable feature tile
  Widget _buildDraggableFeatureTile({
    required Key key,
    required String feature,
    required int index,
  }) {
    final metadata = featureMetadata[feature] ?? {};
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00E0FF).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF00E0FF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.drag_handle,
          color: const Color(0xFF00E0FF),
        ),
        title: Text(
          metadata['title'] ?? feature,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Position: ${index + 1}',
          style: const TextStyle(
            color: Color(0xFFA0A0C0),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Reset to default features
  Future<void> _resetToDefault(
      BuildContext context, MobileLayoutProvider layoutProvider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050A1F),
        title: const Text(
          'Reset to Default?',
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
        content: const Text(
          'This will enable the 8 default features and disable all others.',
          style: TextStyle(color: Color(0xFFA0A0C0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFA0A0C0)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await layoutProvider.resetToDefault();
              _featuresList = layoutProvider.mobileModules.entries.toList();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to default features'),
                  backgroundColor: Color(0xFF00FFaa),
                ),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFFF5588)),
            ),
          ),
        ],
      ),
    );
  }
}
