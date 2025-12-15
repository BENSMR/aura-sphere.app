import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aura_sphere_pro/providers/mobile_layout_provider.dart';
import 'package:aura_sphere_pro/config/constants.dart';

/// Mobile Dashboard Screen - Renders only enabled features
class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load user's mobile layout preferences on screen init
    Future.microtask(() {
      context.read<MobileLayoutProvider>().loadMobileLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileLayoutProvider>(
      builder: (context, layoutProvider, child) {
        // Show loading state
        if (layoutProvider.isLoading && layoutProvider.enabledFeatures.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              backgroundColor: Colors.black,
              elevation: 0,
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00E0FF),
              ),
            ),
          );
        }

        // Show error state
        if (layoutProvider.error != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              backgroundColor: Colors.black,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFF00E0FF),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    layoutProvider.error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      layoutProvider.loadMobileLayout();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // No enabled features
        if (layoutProvider.enabledFeatures.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              backgroundColor: Colors.black,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Navigate to customize page
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => const CustomizeDashboardScreen(),
                    //   ),
                    // );
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dashboard_customize,
                    color: Color(0xFF00E0FF),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Features Enabled',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visit settings to enable features for your mobile dashboard',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to customize dashboard
                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //     builder: (context) => const CustomizeDashboardScreen(),
                      //   ),
                      // );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Customize'),
                  ),
                ],
              ),
            ),
          );
        }

        // Render enabled features (max 8)
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to customize page
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => const CustomizeDashboardScreen(),
                  //   ),
                  // );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => layoutProvider.loadMobileLayout(),
            color: const Color(0xFF00E0FF),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: layoutProvider.enabledFeatures.length,
              itemBuilder: (context, index) {
                final feature = layoutProvider.enabledFeatures[index];
                return _buildFeatureCard(context, feature);
              },
            ),
          ),
        );
      },
    );
  }

  /// Build individual feature card based on feature type
  Widget _buildFeatureCard(BuildContext context, String feature) {
    final featureData = _getFeatureData(feature);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      child: InkWell(
        onTap: featureData['onTap'] as Function(BuildContext)?,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    featureData['icon'] as String? ?? '📱',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featureData['title'] as String? ?? feature,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF00E0FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          featureData['description'] as String? ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF00E0FF),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Map feature names to display data
  Map<String, dynamic> _getFeatureData(String feature) {
    final featureMap = {
      'scanReceipts': {
        'icon': '📸',
        'title': 'Scan Receipts',
        'description': 'Quick receipt capture & OCR processing',
        'onTap': (BuildContext context) {
          // Navigate to receipt scanner
        },
      },
      'quickContacts': {
        'icon': '👥',
        'title': 'Quick Contacts',
        'description': 'Fast access to your clients',
        'onTap': (BuildContext context) {
          // Navigate to contacts
        },
      },
      'sendInvoices': {
        'icon': '📧',
        'title': 'Send Invoices',
        'description': 'Create and send invoices instantly',
        'onTap': (BuildContext context) {
          // Navigate to invoices
        },
      },
      'inventoryStock': {
        'icon': '📦',
        'title': 'Inventory Stock',
        'description': 'Track stock levels in real-time',
        'onTap': (BuildContext context) {
          // Navigate to inventory
        },
      },
      'taskBoard': {
        'icon': '✅',
        'title': 'Task Board',
        'description': 'Manage tasks and to-dos',
        'onTap': (BuildContext context) {
          // Navigate to tasks
        },
      },
      'loyaltyPoints': {
        'icon': '⭐',
        'title': 'Loyalty Points',
        'description': 'Earn and redeem rewards',
        'onTap': (BuildContext context) {
          // Navigate to loyalty
        },
      },
      'walletBalance': {
        'icon': '💰',
        'title': 'Wallet Balance',
        'description': 'Check AuraToken balance',
        'onTap': (BuildContext context) {
          // Navigate to wallet
        },
      },
      'aiAlerts': {
        'icon': '🤖',
        'title': 'AI Alerts',
        'description': 'Smart notifications & insights',
        'onTap': (BuildContext context) {
          // Navigate to alerts
        },
      },
    };

    return featureMap[feature] ?? {
      'icon': '📱',
      'title': feature,
      'description': 'Feature',
      'onTap': null,
    };
  }
}
